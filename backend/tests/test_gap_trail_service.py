import os
import uuid
from datetime import datetime, timedelta, timezone

os.environ.setdefault("DATABASE_URL", "postgresql://u:p@localhost:5432/x")
os.environ.setdefault("SECRET_KEY", "test")
os.environ.setdefault("ENCRYPTION_MASTER_KEY", "test")

import pytest

from app.services import gap_trail_service as svc
from app.services.gap_trail_service import RoutingError, TrailPing

MODE = svc.settings.GEOAPIFY_ROUTING_MODE
T0 = datetime(2026, 10, 13, 6, 0, tzinfo=timezone.utc)


DRIVER = uuid.uuid4()


def ping(minutes, lat, lon, driver=DRIVER):
    return TrailPing(uuid.uuid4(), driver, lat, lon, T0 + timedelta(minutes=minutes))


def geoapify_body(mode=MODE, legs=None, distance=95000):
    legs = legs if legs is not None else [[[80.35, 26.45], [80.60, 26.60], [80.94, 26.84]]]
    return {"features": [{"properties": {"mode": mode, "distance": distance}, "geometry": {"coordinates": legs}}]}


def test_find_gaps_only_over_threshold():
    pts = [ping(0, 26.45, 80.35), ping(2, 26.46, 80.36), ping(40, 26.84, 80.94)]
    assert svc.find_gaps(pts) == [1]


def test_classify_near_suspicious_route():
    assert svc.classify_gap(ping(0, 26.45, 80.35), ping(30, 26.4505, 80.3505))[0] == "near"
    assert svc.classify_gap(ping(0, 26.45, 80.35), ping(5, 28.6, 77.2))[0] == "suspicious"
    kind, minutes, km = svc.classify_gap(ping(0, 26.45, 80.35), ping(90, 26.84, 80.94))
    assert kind == "route" and minutes == 90.0 and 70 < km < 80


def test_parse_swaps_lon_lat_and_joins_legs():
    body = geoapify_body(legs=[[[80.35, 26.45], [80.60, 26.60]], [[80.60, 26.60], [80.94, 26.84]]])
    coords, km = svc.parse_geoapify_route(body, MODE)
    assert coords == [[26.45, 80.35], [26.60, 80.60], [26.84, 80.94]]
    assert km == 95.0


def test_parse_rejects_wrong_mode_and_bad_shape():
    with pytest.raises(RoutingError):
        svc.parse_geoapify_route(geoapify_body(mode="truck"), MODE)
    with pytest.raises(RoutingError):
        svc.parse_geoapify_route({"features": []}, MODE)
    with pytest.raises(RoutingError):
        svc.parse_geoapify_route(geoapify_body(legs=[[[80.35, 26.45]]]), MODE)


def test_thin_line_keeps_ends_and_drops_close_points():
    coords = [[26.0 + i * 0.00001, 80.0] for i in range(200)]
    thinned = svc.thin_line(coords)
    assert thinned[0] == [26.0, 80.0]
    assert thinned[-1] == [round(coords[-1][0], 5), 80.0]
    assert len(thinned) < 20


def test_build_without_key_returns_gap_but_no_line(monkeypatch):
    monkeypatch.setattr(svc.settings, "GEOAPIFY_API_KEY", "")
    pts = [ping(0, 26.45, 80.35), ping(90, 26.84, 80.94)]
    gaps = svc.build_trail_gaps(uuid.uuid4(), pts)
    assert len(gaps) == 1
    assert gaps[0]["status"] == "pending" and gaps[0]["route_points"] is None
    assert gaps[0]["minutes"] == 90.0
    assert not any(k.startswith("_") for k in gaps[0])


def test_build_near_gap_never_calls_provider(monkeypatch):
    monkeypatch.setattr(svc.settings, "GEOAPIFY_API_KEY", "k")
    monkeypatch.setattr(svc, "_fill_routes", lambda *a, **k: pytest.fail("should not route"))
    pts = [ping(0, 26.45, 80.35), ping(30, 26.4505, 80.3505)]
    assert svc.build_trail_gaps(uuid.uuid4(), pts)[0]["status"] == "near"


class _Resp:
    def __init__(self, status, body=None):
        self.status_code, self._body = status, body

    def json(self):
        return self._body


def test_fetch_route_status_handling(monkeypatch):
    a, b = ping(0, 26.45, 80.35), ping(90, 26.84, 80.94)
    monkeypatch.setattr(svc.settings, "GEOAPIFY_API_KEY", "k")
    monkeypatch.setattr(svc.httpx, "get", lambda *a_, **k: _Resp(429))
    with pytest.raises(RoutingError) as e:
        svc.fetch_route(a, b)
    assert e.value.quota is True
    monkeypatch.setattr(svc.httpx, "get", lambda *a_, **k: _Resp(500))
    with pytest.raises(RoutingError) as e:
        svc.fetch_route(a, b)
    assert e.value.quota is False
    monkeypatch.setattr(svc.httpx, "get", lambda *a_, **k: _Resp(200, geoapify_body()))
    coords, km = svc.fetch_route(a, b)
    assert km == 95.0 and coords[0] == [26.45, 80.35]


def test_error_message_never_contains_key(monkeypatch):
    def boom(*a, **k):
        raise svc.httpx.ConnectError("GET https://x?apiKey=SECRETKEY failed")
    monkeypatch.setattr(svc.settings, "GEOAPIFY_API_KEY", "SECRETKEY")
    monkeypatch.setattr(svc.httpx, "get", boom)
    with pytest.raises(RoutingError) as e:
        svc.fetch_route(ping(0, 26.45, 80.35), ping(90, 26.84, 80.94))
    assert "SECRETKEY" not in str(e.value)


def test_gap_where_driver_was_tracked_elsewhere_is_released_and_never_routed(monkeypatch):
    monkeypatch.setattr(svc.settings, "GEOAPIFY_API_KEY", "k")
    monkeypatch.setattr(svc, "_fill_routes", lambda *a, **k: pytest.fail("should not route"))
    pts = [ping(0, 26.45, 80.35), ping(90, 26.84, 80.94)]
    gap = svc.build_trail_gaps(uuid.uuid4(), pts, {0})[0]
    assert gap["status"] == "released" and gap["route_points"] is None


def test_gap_between_two_different_drivers_is_released(monkeypatch):
    monkeypatch.setattr(svc.settings, "GEOAPIFY_API_KEY", "k")
    monkeypatch.setattr(svc, "_fill_routes", lambda *a, **k: pytest.fail("should not route"))
    pts = [ping(0, 26.45, 80.35), ping(90, 26.84, 80.94, driver=uuid.uuid4())]
    assert svc.build_trail_gaps(uuid.uuid4(), pts)[0]["status"] == "released"


class _FakeQuery:
    def __init__(self, hit):
        self.hit = hit

    def filter(self, *a, **k):
        return self

    def first(self):
        return self.hit


class _FakeSession:
    def __init__(self, hits):
        self.hits = list(hits)

    def query(self, *a, **k):
        return _FakeQuery(self.hits.pop(0))


def test_gaps_tracked_elsewhere_flags_only_gaps_with_other_pings():
    pts = [ping(0, 26.45, 80.35), ping(40, 26.5, 80.4), ping(41, 26.51, 80.41), ping(90, 26.84, 80.94)]
    # gaps at index 0 (0->40 min) and index 2 (41->90 min); first has other pings, second none
    assert svc.gaps_tracked_elsewhere(_FakeSession([("x",), None]), pts) == {0}
