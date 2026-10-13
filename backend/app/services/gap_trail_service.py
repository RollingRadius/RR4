"""
Gap Trail Service
Finds "location was off" gaps in a driver's trail and fills each one with a
road route (last ping before the gap -> first ping after it) from Geoapify.
Routes are cached in trip_trail_gaps, so each gap is routed once.

Time lost is always the difference of the two real ping timestamps; the router
only supplies the road line and the distance. A gap with no route (limit hit,
service down, no key) gets no line -- never a straight one.

Design and decisions: docs/tracking/gap_trail_design_2026-10.md
"""

import logging
import math
from datetime import datetime, timedelta, timezone
from typing import Dict, List, NamedTuple, Optional, Set, Tuple

import httpx
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError

from app.config import settings
from app.database import SessionLocal
from app.models.tracking import DriverLocation
from app.models.trip_trail_gap import TripTrailGap

logger = logging.getLogger(__name__)

PROVIDER = "geoapify"
_REQUEST_TIMEOUT_S = 8.0
_THIN_METERS = 50
_MAX_SPEED_KMH = 100
_RETRY_AFTER_QUOTA = timedelta(hours=1)
_RETRY_AFTER_ERROR = timedelta(minutes=10)

# Per-process breaker: set when the provider says quota/key problem, so later
# requests in the same worker skip the call until it expires.
_breaker_until: Optional[datetime] = None


class TrailPing(NamedTuple):
    id: object
    driver_id: object
    latitude: float
    longitude: float
    timestamp: datetime


class RoutingError(Exception):
    def __init__(self, message: str, quota: bool = False):
        super().__init__(message)
        self.quota = quota


def haversine_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r = 6371000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = p2 - p1
    dl = math.radians(lon2 - lon1)
    h = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(h))


def find_gaps(points) -> List[int]:
    """Indices i where the time from points[i] to points[i+1] exceeds the gap threshold."""
    return [
        i for i in range(len(points) - 1)
        if (points[i + 1].timestamp - points[i].timestamp).total_seconds()
        > settings.GAP_TRAIL_MIN_GAP_SECONDS
    ]


def gaps_tracked_elsewhere(session, points) -> Set[int]:
    """
    Gap indices where the driver has pings between the two trip pings that
    belong to no trip or to another one. The driver's location was then not
    "off": tracking was released for this trip (stop-tracking) or the driver
    moved on to another trip, so this trip's trail must not be joined across it.
    """
    found: Set[int] = set()
    for i in find_gaps(points):
        a, b = points[i], points[i + 1]
        hit = (
            session.query(DriverLocation.id)
            .filter(
                DriverLocation.driver_id == a.driver_id,
                DriverLocation.timestamp > a.timestamp,
                DriverLocation.timestamp < b.timestamp,
            )
            .first()
        )
        if hit is not None:
            found.add(i)
    return found


def classify_gap(a, b, tracked_elsewhere: bool = False) -> Tuple[str, float, float]:
    """Returns (kind, minutes, straight_km). kind: released | near | suspicious | route."""
    seconds = (b.timestamp - a.timestamp).total_seconds()
    straight_m = haversine_m(a.latitude, a.longitude, b.latitude, b.longitude)
    minutes = round(seconds / 60, 1)
    straight_km = round(straight_m / 1000, 2)
    if tracked_elsewhere or a.driver_id != b.driver_id:
        return "released", minutes, straight_km
    if straight_m < settings.GAP_TRAIL_MIN_ROUTE_METERS:
        return "near", minutes, straight_km
    if seconds > 0 and (straight_m / 1000) / (seconds / 3600) > _MAX_SPEED_KMH:
        return "suspicious", minutes, straight_km
    return "route", minutes, straight_km


def thin_line(coords: List[List[float]], min_m: float = _THIN_METERS) -> List[List[float]]:
    """Drop points closer than min_m to the last kept point; always keep first and last."""
    if len(coords) <= 2:
        return [[round(c[0], 5), round(c[1], 5)] for c in coords]
    kept = [coords[0]]
    for c in coords[1:-1]:
        if haversine_m(kept[-1][0], kept[-1][1], c[0], c[1]) >= min_m:
            kept.append(c)
    kept.append(coords[-1])
    return [[round(c[0], 5), round(c[1], 5)] for c in kept]


def parse_geoapify_route(data: dict, expected_mode: str) -> Tuple[List[List[float]], float]:
    """Geoapify GeoJSON -> ([[lat, lng], ...], distance_km). Geoapify sends [lon, lat]."""
    try:
        feature = data["features"][0]
        props = feature["properties"]
        if props.get("mode") != expected_mode:
            raise RoutingError(f"unexpected mode {props.get('mode')!r}")
        coords: List[List[float]] = []
        for leg in feature["geometry"]["coordinates"]:
            for lon, lat in leg:
                point = [lat, lon]
                if not coords or coords[-1] != point:
                    coords.append(point)
        distance_km = round(float(props["distance"]) / 1000, 2)
    except (KeyError, IndexError, TypeError, ValueError) as e:
        raise RoutingError(f"unreadable response ({e.__class__.__name__})")
    if len(coords) < 2:
        raise RoutingError("empty route")
    return coords, distance_km


def fetch_route(a, b) -> Tuple[List[List[float]], float]:
    """One Geoapify routing call. Never logs the URL (it carries the key)."""
    params = {
        "waypoints": f"{a.latitude},{a.longitude}|{b.latitude},{b.longitude}",
        "mode": settings.GEOAPIFY_ROUTING_MODE,
        "type": settings.GEOAPIFY_ROUTE_TYPE,
        "apiKey": settings.GEOAPIFY_API_KEY,
    }
    try:
        resp = httpx.get(settings.GEOAPIFY_ROUTING_URL, params=params, timeout=_REQUEST_TIMEOUT_S)
    except httpx.HTTPError as e:
        raise RoutingError(f"request failed ({e.__class__.__name__})")
    if resp.status_code in (401, 402, 403, 429):
        raise RoutingError(f"provider refused (HTTP {resp.status_code})", quota=True)
    if resp.status_code != 200:
        raise RoutingError(f"provider error (HTTP {resp.status_code})")
    try:
        data = resp.json()
    except ValueError:
        raise RoutingError("response was not JSON")
    coords, distance_km = parse_geoapify_route(data, settings.GEOAPIFY_ROUTING_MODE)
    return thin_line(coords), distance_km


def _utc_midnight(now: datetime) -> datetime:
    return now.replace(hour=0, minute=0, second=0, microsecond=0)


def _fill_routes(trip_id, items: List[dict]) -> None:
    """Attach route / status to each routable item. 3 phases: read, call, write."""
    global _breaker_until
    now = datetime.now(timezone.utc)

    # Phase 1 -- short read session.
    session = SessionLocal()
    try:
        rows = session.query(TripTrailGap).filter(TripTrailGap.trip_id == trip_id).all()
        cached: Dict[Tuple[str, str], dict] = {
            (str(r.from_ping_id), str(r.to_ping_id)): {
                "status": r.status,
                "route_points": r.route_points,
                "distance_km": r.distance_km,
                "provider": r.provider,
                "mode": r.mode,
                "next_retry_at": r.next_retry_at,
            }
            for r in rows
        }
        used_today = (
            session.query(func.count(TripTrailGap.id))
            .filter(
                TripTrailGap.provider == PROVIDER,
                TripTrailGap.status == "ok",
                TripTrailGap.created_at >= _utc_midnight(now),
            )
            .scalar()
        ) or 0
    finally:
        session.close()

    to_fetch: List[dict] = []
    for item in items:
        key = (str(item["_a"].id), str(item["_b"].id))
        row = cached.get(key)
        item["status"] = "pending"
        if row and row["status"] == "ok":
            item["status"] = "ok"
            item["route_points"] = row["route_points"]
            item["distance_km"] = row["distance_km"]
            item["provider"] = row["provider"]
            item["mode"] = row["mode"]
        elif not row or row["next_retry_at"] is None or row["next_retry_at"] <= now:
            to_fetch.append(item)

    # Phase 2 -- provider calls, no DB session held.
    results: List[Tuple[dict, Optional[Tuple[List[List[float]], float]], Optional[timedelta]]] = []
    remaining = settings.GEOAPIFY_DAILY_CALL_CAP - used_today
    for item in to_fetch[: settings.GAP_TRAIL_MAX_NEW_PER_REQUEST]:
        if remaining <= 0 or (_breaker_until and _breaker_until > now):
            break
        try:
            route = fetch_route(item["_a"], item["_b"])
            remaining -= 1
            results.append((item, route, None))
        except RoutingError as e:
            logger.warning("Gap route failed (trip %s): %s", trip_id, e)
            if e.quota:
                _breaker_until = now + _RETRY_AFTER_QUOTA
                results.append((item, None, _RETRY_AFTER_QUOTA))
                break
            results.append((item, None, _RETRY_AFTER_ERROR))

    # Phase 3 -- fresh write session.
    if not results:
        return
    session = SessionLocal()
    try:
        for item, route, retry_in in results:
            row = (
                session.query(TripTrailGap)
                .filter(
                    TripTrailGap.trip_id == trip_id,
                    TripTrailGap.from_ping_id == item["_a"].id,
                    TripTrailGap.to_ping_id == item["_b"].id,
                )
                .first()
            )
            if row is None:
                row = TripTrailGap(
                    trip_id=trip_id,
                    from_ping_id=item["_a"].id,
                    to_ping_id=item["_b"].id,
                    provider=PROVIDER,
                    mode=settings.GEOAPIFY_ROUTING_MODE,
                    attempts=0,
                )
                session.add(row)
            row.attempts = (row.attempts or 0) + 1
            if route is not None:
                row.route_points, row.distance_km = route
                row.status = "ok"
                row.next_retry_at = None
                item["status"] = "ok"
                item["route_points"], item["distance_km"] = route
                item["provider"] = PROVIDER
                item["mode"] = settings.GEOAPIFY_ROUTING_MODE
            else:
                row.status = "pending"
                row.next_retry_at = now + retry_in
            try:
                session.commit()
            except IntegrityError:
                session.rollback()
    finally:
        session.close()


def build_trail_gaps(trip_id, points, tracked_elsewhere: Optional[Set[int]] = None) -> List[dict]:
    """
    points: this trip's own pings, ordered, with .id .driver_id .latitude
    .longitude .timestamp. tracked_elsewhere: gap indices from
    gaps_tracked_elsewhere. Returns one entry per gap: index (the gap sits
    between points[index] and points[index + 1]), real minutes, straight-line
    km, status (ok | pending | near | suspicious | released) and, when ok, the
    road line + km. A "released" gap (tracking paused for this trip, or the
    driver changed) is never routed.
    """
    tracked_elsewhere = tracked_elsewhere or set()
    items: List[dict] = []
    for i in find_gaps(points):
        a, b = points[i], points[i + 1]
        kind, minutes, straight_km = classify_gap(a, b, i in tracked_elsewhere)
        items.append({
            "index": i,
            "minutes": minutes,
            "straight_km": straight_km,
            "status": kind if kind != "route" else "pending",
            "route_points": None,
            "distance_km": None,
            "provider": None,
            "mode": None,
            "_kind": kind,
            "_a": a,
            "_b": b,
        })

    routable = [it for it in items if it["_kind"] == "route"]
    if routable and settings.GEOAPIFY_API_KEY:
        _fill_routes(trip_id, routable)

    for it in items:
        for private in ("_kind", "_a", "_b"):
            del it[private]
    return items
