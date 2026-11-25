"""Repair Stage 1 paper links that point at a file stored nowhere (the RR-pull bug fixed in bfe15c2, 2026-11-25).

When the first RR pull ran on the test server (2026-11-24) and we already held the same file for the trip's
driver / truck / owner, the old code gave the trip a NEW link that was never saved - the app shows a broken photo
(fc11: 377 links). The file itself is stored, on that driver's / truck's / owner's row. This script points each such
trip column at that stored row (found exactly as the app finds it: stage1_document_service.resolve_owner +
_find_row; a trip with no owner key uses its own trip-only document). When RR already holds that stored file, the
trip is also marked "already in RR" with its RR file id (as the pull does), so the next sync does not upload it again.

Run from the backend folder:

    python -m scripts.repair_unstored_stage1_links                 show what would change, write nothing
    python -m scripts.repair_unstored_stage1_links --apply         repair (an undo file is saved first)
    python -m scripts.repair_unstored_stage1_links --verify        every Stage 1 link opens a stored file?
    python -m scripts.repair_unstored_stage1_links --undo FILE     put everything back from an undo file

Only links that are broken NOW change (a link that opens a stored file is never touched); updated_at and every
other column stay. No file is touched. Databases: the local dev ones (localhost:5434 fleet_db_dev /
fleet_db_prodcopy), or with --test-server only inside the fc11 backend container (DB host "postgres", database
fleet_db, RR = RR web TEST). Never prod.
"""

import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

from app.core.document_map import UPLOAD_COLUMNS, is_dev_database_url
import app.models  # noqa: F401  (every model, as the app loads them)
import app.models.organization_branding  # noqa: F401

STORED_TABLES = ("driver_documents", "vehicle_documents", "owner_documents", "trip_documents")
STAGE1 = [c for c in UPLOAD_COLUMNS if c.stage == 1]
TEST_SERVER_RR = "35.244.19.78"


def database_allowed(url: str, test_server: bool) -> bool:
    if is_dev_database_url(url):
        return True
    if not test_server:
        return False
    from app.config import settings
    p = urlparse(url)
    return (p.hostname == "postgres" and (p.path or "").lstrip("/") == "fleet_db"
            and TEST_SERVER_RR in (settings.RR_API_BASE or ""))


def stored_urls(db) -> set:
    urls = set()
    for t in STORED_TABLES:
        urls |= {u for (u,) in db.execute(text(f"SELECT url_path FROM {t}")) if u}
    return urls


def plan(db):
    """(changes, unresolved): every Stage 1 trip link stored nowhere, and the stored link it should show."""
    from app.models.trip import Trip
    from app.models.document import TripDocument
    from app.services.rr_pull_service import stage1_sync_mark
    from app.services.stage1_document_service import _find_row, resolve_owner
    urls = stored_urls(db)
    changes, unresolved = [], []
    for trip in db.query(Trip).order_by(Trip.created_at).all():
        for col in STAGE1:
            link = getattr(trip, col.column)
            if not link or link in urls:
                continue
            owner = resolve_owner(db, trip, col.table)
            if owner:
                row = _find_row(db, col.table, owner, col.doc_type, col.side)
            else:
                row = db.query(TripDocument).filter(TripDocument.trip_id == trip.id,
                                                    TripDocument.doc_type == f"{col.doc_type}_{col.side}").first()
            if row is None or not row.url_path or row.url_path not in urls:
                unresolved.append({"trip": trip.trip_number, "column": col.column, "link": link,
                                   "owner": ":".join(owner) if owner else None})
                continue
            in_rr = bool(row.rr_file_id) and row.rr_synced_sha256 == row.sha256
            mark = stage1_sync_mark(col.column) if in_rr else None
            changes.append({"trip_id": str(trip.id), "trip": trip.trip_number, "column": col.column,
                            "old": link, "new": row.url_path, "owner": ":".join(owner) if owner else "trip",
                            "mark_key": mark[0] if mark else None, "mark_attr": mark[1] if mark else None,
                            "rr_file_id": row.rr_file_id if mark else None})
    return changes, unresolved


def _check_column(name: str):
    if name not in {c.column for c in STAGE1} and not name.startswith("rr_"):
        raise ValueError(f"unexpected column {name}")


def apply(db, changes, undo_path: Path):
    """Point each column at the stored link, only where it still holds the broken one; the undo file first."""
    undo = []
    for c in changes:
        _check_column(c["column"])
        row = db.execute(text(f"SELECT rr_synced_doc_urls{', ' + c['mark_attr'] if c['mark_attr'] else ''} "
                              f"FROM trips WHERE id = :id"), {"id": c["trip_id"]}).first()
        undo.append({**c, "old_marks": row[0], "old_attr_value": row[1] if c["mark_attr"] else None})
    undo_path.write_text(json.dumps(undo, indent=1, default=str), encoding="utf-8")
    changed = skipped = 0
    for c in changes:
        res = db.execute(text(f"UPDATE trips SET {c['column']} = :new, updated_at = updated_at "
                              f"WHERE id = :id AND {c['column']} = :old"),
                         {"new": c["new"], "id": c["trip_id"], "old": c["old"]})
        if res.rowcount != 1:
            skipped += 1
            continue
        changed += 1
        if c["mark_key"]:
            db.execute(text("UPDATE trips SET rr_synced_doc_urls = COALESCE(rr_synced_doc_urls, '{}'::jsonb) "
                            "|| jsonb_build_object(:k, :v), updated_at = updated_at WHERE id = :id"),
                       {"k": c["mark_key"], "v": c["new"], "id": c["trip_id"]})
            if c["mark_attr"]:
                _check_column(c["mark_attr"])
                db.execute(text(f"UPDATE trips SET {c['mark_attr']} = :f, updated_at = updated_at WHERE id = :id"),
                           {"f": c["rr_file_id"], "id": c["trip_id"]})
    db.commit()
    return changed, skipped


def undo(db, undo_path: Path):
    items = json.loads(undo_path.read_text(encoding="utf-8"))
    for c in items:
        _check_column(c["column"])
        db.execute(text(f"UPDATE trips SET {c['column']} = :old, updated_at = updated_at "
                        f"WHERE id = :id AND {c['column']} = :new"), {"old": c["old"], "new": c["new"], "id": c["trip_id"]})
        if c["mark_key"]:
            db.execute(text("UPDATE trips SET rr_synced_doc_urls = CAST(:m AS jsonb), updated_at = updated_at "
                            "WHERE id = :id"), {"m": json.dumps(c["old_marks"]) if c["old_marks"] is not None else None,
                                                "id": c["trip_id"]})
            if c["mark_attr"]:
                _check_column(c["mark_attr"])
                db.execute(text(f"UPDATE trips SET {c['mark_attr']} = :v, updated_at = updated_at WHERE id = :id"),
                           {"v": c["old_attr_value"], "id": c["trip_id"]})
    db.commit()
    return len(items)


def broken_count(db) -> int:
    urls = stored_urls(db)
    cols = ", ".join(c.column for c in STAGE1)
    return sum(1 for row in db.execute(text(f"SELECT {cols} FROM trips")) for link in row if link and link not in urls)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--url", default=os.environ.get("DATABASE_URL", ""))
    parser.add_argument("--test-server", action="store_true", help="only inside the fc11 backend container")
    parser.add_argument("--undo-dir", default=".")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--apply", action="store_true")
    mode.add_argument("--verify", action="store_true")
    mode.add_argument("--undo", metavar="FILE")
    args = parser.parse_args(argv)
    if not database_allowed(args.url, args.test_server):
        print("Refused: only the local dev databases, or --test-server inside the fc11 backend container.", file=sys.stderr)
        return 2
    db = sessionmaker(bind=create_engine(args.url))()
    try:
        if args.verify:
            n = broken_count(db)
            print(f"Stage 1 links stored nowhere: {n}")
            return 0 if n == 0 else 1
        if args.undo:
            print(f"put back: {undo(db, Path(args.undo))}")
            return 0
        changes, unresolved = plan(db)
        by_col = {}
        for c in changes:
            by_col[c["column"]] = by_col.get(c["column"], 0) + 1
        print(f"broken Stage 1 links: {len(changes) + len(unresolved)} | can be repaired: {len(changes)} | "
              f"no stored file found: {len(unresolved)}")
        print("by column:", json.dumps(by_col, sort_keys=True))
        print("also marked 'already in RR':", sum(1 for c in changes if c["mark_key"]))
        for c in changes[:5]:
            print(f"  {c['trip']} {c['column']}: ...{c['old'][-40:]} -> ...{c['new'][-40:]} ({c['owner']})")
        for u in unresolved[:10]:
            print(f"  NOT REPAIRABLE {u['trip']} {u['column']} ...{u['link'][-40:]} owner={u['owner']}")
        if not args.apply:
            print("(dry run - nothing written; add --apply)")
            return 0
        name = urlparse(args.url).path.lstrip("/")
        undo_path = Path(args.undo_dir) / f"repair_stage1_links_{name}_{datetime.now():%Y-%m-%d_%H%M%S}.json"
        changed, skipped = apply(db, changes, undo_path)
        print(f"repaired: {changed}, skipped (changed meanwhile): {skipped} | undo file: {undo_path}")
        print(f"Stage 1 links stored nowhere now: {broken_count(db)}")
        return 0
    finally:
        db.close()


if __name__ == "__main__":
    sys.exit(main())
