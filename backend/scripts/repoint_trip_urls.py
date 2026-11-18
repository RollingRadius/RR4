"""The switch step: point the older trips at the stored files (local dev databases only).

Each driver, vehicle and owner document is stored once, on its owner. Older trips still hold the URL of
their own older copy, which was not imported. This script points those trips at the current stored
document, so every file link a trip holds opens from the database.

Run from the backend folder:

    python -m scripts.repoint_trip_urls                       show what would change, write nothing
    python -m scripts.repoint_trip_urls --apply               change the trips (an undo file is saved first)
    python -m scripts.repoint_trip_urls --verify              check that every URL resolves to a stored file
    python -m scripts.repoint_trip_urls --undo FILE           put the URLs back from an undo file

Only the trip's file-link columns change; `updated_at` and every other column stay as they are. No file is
touched. Refuses any database but the local dev ones (localhost:5434, fleet_db_dev or fleet_db_prodcopy).
Plan: md/TESTS_NEXT_STEPS_AND_OPEN_FINDINGS.md.
"""

import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path

import psycopg2

from app.core.document_map import UPLOAD_COLUMN_NAMES, UPLOAD_COLUMNS, is_dev_database_url
from scripts.uploads_dry_run import DEFAULT_URL
from scripts.uploads_plan import build_plan, load_sources, urls_in

BACKUP_DIRS = {"fleet_db_dev": Path("D:/RR4_dev_db"), "fleet_db_prodcopy": Path("D:/RR4_prodcopy")}
STORED_URL_QUERIES = (
    "SELECT url_path FROM driver_documents",
    "SELECT url_path FROM vehicle_documents",
    "SELECT url_path FROM owner_documents",
    "SELECT url_path FROM trip_documents",
    "SELECT profile_picture_url FROM users WHERE profile_picture_content IS NOT NULL",
    "SELECT file_url FROM receiving_documents WHERE content IS NOT NULL",
    "SELECT logo_url FROM organization_branding WHERE logo_content IS NOT NULL",
)


def plan_changes(plan):
    """[{trip_id, column, old, new}] for every older copy that should point at the stored document."""
    return [{"trip_id": t, "column": c, "old": old, "new": new} for t, c, old, new in plan.repoint]


def _check(changes):
    for change in changes:
        if change["column"] not in UPLOAD_COLUMN_NAMES:   # column names are interpolated into SQL below
            raise ValueError(f"not an upload column: {change['column']}")


def apply_changes(conn, changes):
    """Set each trip column to its new URL, only where it still holds the old one. Returns (changed, skipped)."""
    _check(changes)
    changed = skipped = 0
    cur = conn.cursor()
    for c in changes:
        cur.execute(f"UPDATE trips SET {c['column']} = %s, updated_at = updated_at WHERE id = %s AND {c['column']} = %s",
                    (c["new"], c["trip_id"], c["old"]))
        if cur.rowcount == 1:
            changed += 1
        else:
            skipped += 1
    conn.commit()
    return changed, skipped


def undo_changes(conn, changes):
    """The same change in the other direction."""
    return apply_changes(conn, [{**c, "old": c["new"], "new": c["old"]} for c in changes])


def referenced_urls(trips, others):
    urls = set()
    for col in UPLOAD_COLUMNS:
        for trip in trips:
            urls.update(urls_in(trip.get(col.column), col.is_list))
    for rows in others.values():
        urls.update(url for _id, url in rows)
    return urls


def stored_urls(conn):
    cur = conn.cursor()
    urls = set()
    for query in STORED_URL_QUERIES:
        cur.execute(query)
        urls.update(row[0] for row in cur.fetchall() if row[0])
    return urls


def find_unresolved(conn, trips, others):
    """URLs a trip, user, receiving document or logo holds that no stored file answers to."""
    return sorted(referenced_urls(trips, others) - stored_urls(conn))


def backup_path(url, backup_dir=None):
    name = url.rsplit("/", 1)[-1]
    folder = Path(backup_dir) if backup_dir else BACKUP_DIRS.get(name, Path("."))
    return folder / f"repoint_{name}_{datetime.now().strftime('%Y-%m-%d_%H%M%S')}.json"


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--url", default=os.environ.get("DATABASE_URL", DEFAULT_URL))
    parser.add_argument("--backup-dir")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--apply", action="store_true")
    mode.add_argument("--verify", action="store_true")
    mode.add_argument("--undo", metavar="FILE")
    args = parser.parse_args(argv)

    if not is_dev_database_url(args.url):
        print("REFUSED: this script only works on the local dev databases "
              "(localhost:5434, fleet_db_dev or fleet_db_prodcopy).", file=sys.stderr)
        return 2

    conn = psycopg2.connect(args.url)
    try:
        if args.undo:
            changes = json.loads(Path(args.undo).read_text(encoding="utf-8"))
            changed, skipped = undo_changes(conn, changes)
            print(f"Undone: {changed} trip links put back, {skipped} skipped (already different).")
            return 0

        trips, lookups, _users, others = load_sources(args.url)
        changes = plan_changes(build_plan(trips, lookups))
        unresolved = find_unresolved(conn, trips, others)
        print(f"File links held by trips, users, receiving documents and logos: {len(referenced_urls(trips, others))}")
        print(f"  not answered by a stored file yet: {len(unresolved)}")
        print(f"  older-copy links that would be pointed at the stored document: {len(changes)}")

        if args.verify:
            for url in unresolved[:10]:
                print(f"  UNRESOLVED {url}")
            print("\nOK: every file link resolves to a stored file." if not unresolved else
                  f"\nPROBLEM: {len(unresolved)} link(s) do not resolve.")
            return 1 if unresolved else 0

        if not args.apply:
            print("\nNothing written (add --apply to change the trips, --verify to check the links).")
            return 0

        path = backup_path(args.url, args.backup_dir)   # next to the other backups of that database
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(changes, indent=1), encoding="utf-8")
        print(f"\nUndo file saved: {path}")
        changed, skipped = apply_changes(conn, changes)
        print(f"Changed {changed} trip links, skipped {skipped}.")
        print("Run with --verify to check the links.")
        return 0
    finally:
        conn.close()


if __name__ == "__main__":
    sys.exit(main())
