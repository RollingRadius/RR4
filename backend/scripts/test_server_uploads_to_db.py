"""Test server (fc11) only: put fc11's uploaded files from its disk into the right places of fc11's RR4 test database.

Runs ONLY inside the fc11 backend container (database host 'postgres' = our RR4 test database, and the backend's
RR_API_BASE = RR web TEST, used only as a "this is the test server" fingerprint - RR web is never called and RR web
test's database (Mongo) is never touched; this script only speaks to Postgres). Anywhere else it refuses.

Two steps, each with a dry run first (nothing is written without --apply):
  1  copy    - every upload file on fc11's disk -> its document table (driver / vehicle / owner / trip documents),
               stored once per driver / vehicle / owner exactly as the app stores new uploads.
               --verify checks the database against the disk.
  2  repoint - trips still pointing at an older copy of a file are pointed at the stored document. An undo file is
               saved to --backup-dir BEFORE any trip changes (required); --undo FILE puts the links back.
               --verify checks that every file link resolves to a stored file.
Files on disk are never deleted and nothing is ever wiped.

  docker exec -it fleet_backend python -m scripts.test_server_uploads_to_db copy             # dry run
  docker exec -it fleet_backend python -m scripts.test_server_uploads_to_db copy --apply
  docker exec -it fleet_backend python -m scripts.test_server_uploads_to_db copy --verify
  docker exec -it fleet_backend python -m scripts.test_server_uploads_to_db repoint          # dry run
  docker exec -it fleet_backend python -m scripts.test_server_uploads_to_db repoint --apply --backup-dir /app/backups
  docker exec -it fleet_backend python -m scripts.test_server_uploads_to_db repoint --verify

The copy / repoint logic is the app's own (scripts/copy_uploads_to_db.py, scripts/repoint_trip_urls.py, shared with
the local rehearsals); only the guard and the steps here are test-server specific.
"""
import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse

import psycopg2

from scripts.copy_uploads_to_db import apply_others, apply_plan, summarize, verify
from scripts.repoint_trip_urls import apply_changes, find_unresolved, plan_changes, referenced_urls, undo_changes
from scripts.uploads_dry_run import DEFAULT_UPLOADS_DIR
from scripts.uploads_plan import build_plan, load_sources

TEST_SERVER_RR_API = "https://35.244.19.78:8042"      # fc11's backend talks to RR web TEST; prod talks to rollingradius.com


def is_test_server(url: str) -> bool:
    """True only inside the fc11 backend container: RR4's Postgres on host 'postgres' and RR web TEST configured."""
    rr = os.environ.get("RR_API_BASE", "").rstrip("/")
    return ((urlparse(url).hostname or "").lower() == "postgres"
            and rr == TEST_SERVER_RR_API
            and "rollingradius.com" not in rr)


def copy_step(url: str, uploads_dir: str, apply: bool, check: bool) -> int:
    trips, lookups, users, others = load_sources(url)
    plan = build_plan(trips, lookups)
    summarize(plan)
    if not (apply or check):
        print("\nNothing written (add --apply to copy, --verify to check).")
        return 0
    conn = psycopg2.connect(url)
    try:
        if apply:
            print("\nCopying...")
            stats = apply_plan(conn, plan, uploads_dir, users)
            stats.update(apply_others(conn, others, uploads_dir))
            for key in sorted(stats):
                print(f"  {key}: {stats[key]}")
            print("Run 'copy --verify' to check the result.")
            return 0
        print("\nVerifying...")
        problems = verify(conn, plan, others, uploads_dir)
        print("\nOK: the database matches the disk and the plan." if not problems else "\nPROBLEMS:")
        for problem in problems:
            print(f"  {problem}")
        return 1 if problems else 0
    finally:
        conn.close()


def repoint_step(url: str, apply: bool, check: bool, backup_dir: str | None, undo: str | None) -> int:
    conn = psycopg2.connect(url)
    try:
        if undo:
            changes = json.loads(Path(undo).read_text(encoding="utf-8"))
            changed, skipped = undo_changes(conn, changes)
            print(f"Undone: {changed} trip links put back, {skipped} skipped (already different).")
            return 0
        trips, lookups, _users, others = load_sources(url)
        changes = plan_changes(build_plan(trips, lookups))
        unresolved = find_unresolved(conn, trips, others)
        print(f"File links held by trips, users, receiving documents and logos: {len(referenced_urls(trips, others))}")
        print(f"  not answered by a stored file yet: {len(unresolved)}")
        print(f"  older-copy links that would be pointed at the stored document: {len(changes)}")
        if check:
            for u in unresolved[:10]:
                print(f"  UNRESOLVED {u}")
            print("\nOK: every file link resolves to a stored file." if not unresolved else
                  f"\nPROBLEM: {len(unresolved)} link(s) do not resolve.")
            return 1 if unresolved else 0
        if not apply:
            print("\nNothing written (add --apply --backup-dir DIR to change the trips, --verify to check the links).")
            return 0
        if not backup_dir:
            print("REFUSED: --backup-dir is required for 'repoint --apply' (the undo file is saved there first).",
                  file=sys.stderr)
            return 2
        path = Path(backup_dir) / f"repoint_fc11_{datetime.now().strftime('%Y-%m-%d_%H%M%S')}.json"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(changes, indent=1), encoding="utf-8")
        print(f"\nUndo file saved: {path}")
        changed, skipped = apply_changes(conn, changes)
        print(f"Changed {changed} trip links, skipped {skipped}. Run 'repoint --verify' to check the links.")
        return 0
    finally:
        conn.close()


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("step", choices=["copy", "repoint"])
    parser.add_argument("--url", default=os.environ.get("DATABASE_URL", ""))
    parser.add_argument("--uploads-dir", default=str(DEFAULT_UPLOADS_DIR))
    parser.add_argument("--backup-dir")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--apply", action="store_true")
    mode.add_argument("--verify", action="store_true")
    mode.add_argument("--undo", metavar="FILE", help="repoint only: put the trip links back from an undo file")
    args = parser.parse_args(argv)

    if not is_test_server(args.url):
        print(f"REFUSED: this script runs only on the test server - inside the fc11 backend container "
              f"(database host 'postgres', RR_API_BASE {TEST_SERVER_RR_API}).", file=sys.stderr)
        return 2
    print("TEST SERVER (fc11): our RR4 test database (Postgres). RR web test is not touched.")
    if args.step == "copy":
        if args.undo:
            print("REFUSED: --undo is for the repoint step.", file=sys.stderr)
            return 2
        return copy_step(args.url, args.uploads_dir, args.apply, args.verify)
    return repoint_step(args.url, args.apply, args.verify, args.backup_dir, args.undo)


if __name__ == "__main__":
    sys.exit(main())
