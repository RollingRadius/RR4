"""Shared planning for moving uploads into the document tables (dev only).

`build_plan` decides, without touching anything, which file becomes which row:
each Stage 1 document is stored once per owner (the latest wins, decision 19),
owners with several document numbers are not merged, and files with no owner key
stay as trip-only documents. The dry run reports the plan; the copy script applies it.
Plan: md/TESTS_NEXT_STEPS_AND_OPEN_FINDINGS.md.
"""

import json
from collections import defaultdict
from dataclasses import dataclass, field, replace
from datetime import datetime
from typing import Optional

import psycopg2
import psycopg2.extras

from app.core.document_map import DRIVER, OWNER, TRIP, UPLOAD_COLUMNS, VEHICLE

# Uploads kept outside the trip columns: name -> (query, id column) read as (id, url).
OTHER_SOURCES = {
    "profile_pictures": "SELECT id, profile_picture_url AS url FROM users WHERE profile_picture_url IS NOT NULL",
    "receiving_documents": "SELECT id, file_url AS url FROM receiving_documents WHERE file_url IS NOT NULL",
    "logos": "SELECT id, logo_url AS url FROM organization_branding WHERE logo_url IS NOT NULL",
}


@dataclass
class Lookups:
    driver_by_rr: dict = field(default_factory=dict)    # RR user id -> local driver id
    vehicle_by_rr: dict = field(default_factory=dict)   # RR vehicle id -> local vehicle id
    vehicle_org: dict = field(default_factory=dict)     # local vehicle id -> its organization id


@dataclass
class PlannedDoc:
    table: str
    doc_type: str
    url: str
    trip_id: str
    stage: int
    column: str
    side: Optional[str] = None
    slot: int = 0
    owner: Optional[tuple] = None
    number: str = ""
    stamp: datetime = datetime.min
    submitted_by: Optional[str] = None
    attributed_username: Optional[str] = None
    reason: str = "normal"   # normal | no_owner_key | conflict


@dataclass
class Plan:
    docs: list
    older_copies: list
    repoint: list            # (trip id, column, old url, new url): for the later switch step
    no_owner: dict
    kept_trip_only_for_conflict: int
    same_file_in_two_columns: int
    conflicts: dict


def urls_in(value, is_list):
    """The upload URLs held by one trip column (a JSON list for material docs)."""
    if not value:
        return []
    if is_list:
        try:
            parsed = json.loads(value) if isinstance(value, str) else value
        except ValueError:
            parsed = [value]
        return [u for u in parsed if u] if isinstance(parsed, list) else [value]
    return [value]


def resolve_owner(table, trip, lookups):
    """(kind, id) of the owner a Stage 1 document belongs to, or None."""
    if table == DRIVER:
        if trip.get("driver_id"):
            return ("driver", str(trip["driver_id"]))
        rr = trip.get("rr_driver_id")
        if rr:
            return ("driver", lookups.driver_by_rr[rr]) if rr in lookups.driver_by_rr else ("rr_driver", rr)
    elif table == VEHICLE:
        if trip.get("vehicle_id"):
            return ("vehicle", str(trip["vehicle_id"]))
        rr = trip.get("rr_vehicle_id")
        if rr:
            return ("vehicle", lookups.vehicle_by_rr[rr]) if rr in lookups.vehicle_by_rr else ("rr_vehicle", rr)
    elif table == OWNER:
        if trip.get("transporter_rr_company_id"):
            return ("rr_company", trip["transporter_rr_company_id"])
        vehicle_id = trip.get("vehicle_id") or lookups.vehicle_by_rr.get(trip.get("rr_vehicle_id") or "")
        org = lookups.vehicle_org.get(str(vehicle_id)) if vehicle_id else None
        if org:
            return ("org", org)   # the vehicle's organization, never the trip's own (that is the fleet)
    return None


def _planned(col, trip, url, slot):
    attributions = trip.get("field_attributions") or {}
    return PlannedDoc(
        table=col.table, doc_type=col.doc_type, url=url, trip_id=str(trip["id"]), stage=col.stage,
        column=col.column, side=col.side, slot=slot,
        number=(trip.get(col.number_column) or "").strip().upper() if col.number_column else "",
        stamp=trip.get("s1_submitted_at") or trip.get("created_at") or datetime.min,
        submitted_by=str(trip[f"s{col.stage}_submitted_by"]) if trip.get(f"s{col.stage}_submitted_by") else None,
        attributed_username=attributions.get(col.attr_key) if col.attr_key else None,
    )


def _trip_only(doc, reason):
    doc_type = f"{doc.doc_type}_{doc.side}" if doc.side else doc.doc_type
    return replace(doc, table=TRIP, doc_type=doc_type, owner=None, side=None, slot=0, reason=reason)


def build_plan(trips, lookups):
    docs, older, repoint = [], [], []
    no_owner = defaultdict(int)
    groups = defaultdict(list)   # (table, owner, doc_type, side) -> [PlannedDoc]

    for col in UPLOAD_COLUMNS:
        for trip in trips:
            for slot, url in enumerate(urls_in(trip.get(col.column), col.is_list)):
                doc = _planned(col, trip, url, slot)
                if col.table == TRIP:
                    docs.append(doc)
                    continue
                owner = resolve_owner(col.table, trip, lookups)
                if owner is None:
                    no_owner[col.column] += 1
                    docs.append(_trip_only(doc, "no_owner_key"))
                    continue
                doc.owner = owner
                groups[(col.table, owner, col.doc_type, col.side)].append(doc)

    owner_numbers = defaultdict(set)   # (table, owner, doc_type) -> numbers, both sides together
    owner_trips = defaultdict(set)
    for (table, owner, doc_type, _side), items in groups.items():
        owner_numbers[(table, owner, doc_type)] |= {d.number for d in items if d.number}
        owner_trips[(table, owner, doc_type)] |= {d.trip_id for d in items}
    conflicted = {key for key, numbers in owner_numbers.items() if len(numbers) > 1}

    conflict_docs = 0
    for (table, owner, doc_type, _side), items in groups.items():
        if (table, owner, doc_type) in conflicted:
            docs.extend(_trip_only(d, "conflict") for d in items)
            conflict_docs += len(items)
            continue
        items.sort(key=lambda d: (d.stamp, d.trip_id))
        current = items[-1]
        docs.append(current)
        for old in items[:-1]:
            older.append(old)
            if old.url != current.url:
                repoint.append((old.trip_id, old.column, old.url, current.url))

    # The same file can sit in two columns (RR sync copies the loading slip into both).
    seen, unique_docs, same_file = set(), [], 0
    for doc in docs:
        key = (doc.table, doc.url)
        if key in seen:
            same_file += 1
            continue
        seen.add(key)
        unique_docs.append(doc)

    conflicts = {"owner_with_several_numbers": [], "number_under_several_owners": []}
    for (table, owner, doc_type), numbers in owner_numbers.items():
        if len(numbers) > 1:
            conflicts["owner_with_several_numbers"].append(
                {"table": table, "owner": ":".join(owner), "doc_type": doc_type,
                 "numbers": sorted(numbers), "trips": len(owner_trips[(table, owner, doc_type)])})
    owners_of = defaultdict(set)
    for (table, owner, doc_type), numbers in owner_numbers.items():
        for number in numbers:
            owners_of[(table, doc_type, number)].add(":".join(owner))
    for (table, doc_type, number), owners in owners_of.items():
        if len(owners) > 1:
            conflicts["number_under_several_owners"].append(
                {"table": table, "doc_type": doc_type, "number": number, "owners": sorted(owners)})

    return Plan(unique_docs, older, repoint, dict(no_owner), conflict_docs, same_file, conflicts)


TRIP_COLUMNS = sorted(
    {"id", "created_at", "s1_submitted_at", "driver_id", "rr_driver_id", "vehicle_id", "rr_vehicle_id",
     "transporter_rr_company_id", "field_attributions",
     "s1_submitted_by", "s2_submitted_by", "s3_submitted_by", "s4_submitted_by", "s5_submitted_by"}
    | {c.column for c in UPLOAD_COLUMNS} | {c.number_column for c in UPLOAD_COLUMNS if c.number_column}
)


def load_sources(url, read_only=True):
    """Everything the plan needs, read from the (dev) database."""
    conn = psycopg2.connect(url)
    try:
        conn.set_session(readonly=read_only, autocommit=True)
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute(f"SELECT {', '.join(TRIP_COLUMNS)} FROM trips")
        trips = cur.fetchall()
        lookups = Lookups()
        cur.execute("SELECT id, rr_user_id FROM drivers WHERE rr_user_id IS NOT NULL")
        lookups.driver_by_rr = {r["rr_user_id"]: str(r["id"]) for r in cur.fetchall()}
        cur.execute("SELECT id, rr_vehicle_id, organization_id FROM vehicles")
        for r in cur.fetchall():
            lookups.vehicle_org[str(r["id"])] = str(r["organization_id"])
            if r["rr_vehicle_id"]:
                lookups.vehicle_by_rr[r["rr_vehicle_id"]] = str(r["id"])
        cur.execute("SELECT id, username FROM users")
        users = {str(r["id"]): r["username"] for r in cur.fetchall()}
        others = {}
        for name, query in OTHER_SOURCES.items():
            cur.execute(query)
            others[name] = [(str(r["id"]), r["url"]) for r in cur.fetchall()]
    finally:
        conn.close()
    return trips, lookups, users, others
