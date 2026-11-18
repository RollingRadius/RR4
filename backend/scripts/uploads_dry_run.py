"""Read-only dry run for moving uploads into the document tables.

Run from the backend folder, against the local dev database only:

    python -m scripts.uploads_dry_run [--url URL] [--uploads-dir DIR] [--json FILE]

Writes nothing to the database or the disk. Refuses any database that is not the
local dev database (localhost:5434, fleet_db_dev or fleet_db_prodcopy). Plan:
md/TESTS_NEXT_STEPS_AND_OPEN_FINDINGS.md (decision 19: each document stored once).
"""

import argparse
import json
import os
import sys
from collections import defaultdict
from pathlib import Path

from app.core.document_map import DRIVER, OWNER, TRIP, UPLOAD_COLUMNS, VEHICLE, is_dev_database_url
from scripts.uploads_plan import build_plan, load_sources, urls_in

DEFAULT_URL = "postgresql://fleet_dev:fleet_dev_local@localhost:5434/fleet_db_dev"
DEFAULT_UPLOADS_DIR = Path(__file__).resolve().parent.parent / "uploads"


def analyze(trips, lookups, uploaded_urls, other_urls=None):
    """Pure analysis. `uploaded_urls` is the set of URLs found on disk (None when no
    uploads folder was readable). Returns a JSON-friendly report."""
    other_urls = other_urls or {}
    plan = build_plan(trips, lookups)

    columns, referenced = {}, {u for urls in other_urls.values() for u in urls}
    for col in UPLOAD_COLUMNS:
        holding = missing = 0
        for trip in trips:
            urls = urls_in(trip.get(col.column), col.is_list)
            if urls:
                holding += 1
            referenced.update(urls)
            missing += sum(1 for u in urls if uploaded_urls is not None and u not in uploaded_urls)
        columns[col.column] = {"table": col.table, "doc_type": col.doc_type, "trips_with_file": holding,
                               "files_missing_on_disk": missing if uploaded_urls is not None else None}

    rows = defaultdict(int)
    for doc in plan.docs:
        rows[doc.table] += 1

    other_sources = {name: {"rows": len(urls), "missing_on_disk": (
        None if uploaded_urls is None else len([u for u in urls if u not in uploaded_urls]))}
        for name, urls in other_urls.items()}
    orphans = None if uploaded_urls is None else sorted(uploaded_urls - referenced)

    return {
        "columns": columns,
        "rows_to_create": {t: rows[t] for t in (DRIVER, VEHICLE, OWNER, TRIP)},
        "older_copies_not_imported": len(plan.older_copies),
        "trip_columns_with_file_but_no_owner_key": plan.no_owner,
        "kept_trip_only_because_of_conflict": plan.kept_trip_only_for_conflict,
        "same_file_in_two_columns": plan.same_file_in_two_columns,
        "conflicts": plan.conflicts,
        "other_sources": other_sources,
        "orphan_files_on_disk": None if orphans is None else {"count": len(orphans), "examples": orphans[:10]},
        "trips_total": len(trips),
    }


def read_uploads(uploads_dir):
    """URLs (as stored in the DB) of every file under the uploads folder, or None."""
    root = Path(uploads_dir)
    if not root.is_dir():
        return None
    urls = {"/uploads/" + p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file()}
    return urls if urls else None


def render(report):
    out = [f"Trips read: {report['trips_total']}", "", "Per upload column (trips holding a file):"]
    for name, info in report["columns"].items():
        missing = info["files_missing_on_disk"]
        tail = "" if missing is None else f"   missing on disk: {missing}"
        out.append(f"  {name:32} {info['trips_with_file']:5}  -> {info['table']}/{info['doc_type']}{tail}")
    out += ["", "Rows the move would create:"]
    out += [f"  {table:20} {count}" for table, count in report["rows_to_create"].items()]
    out.append(f"Older per-trip copies not imported (stored once): {report['older_copies_not_imported']}")
    out.append(f"Kept as trip-only documents because the owner has several document numbers: "
               f"{report['kept_trip_only_because_of_conflict']}")
    out.append(f"Same file found in two columns (one row only): {report['same_file_in_two_columns']}")
    if report["trip_columns_with_file_but_no_owner_key"]:
        out += ["", "Files with no owner key (kept as trip-only documents):"]
        out += [f"  {k}: {v}" for k, v in report["trip_columns_with_file_but_no_owner_key"].items()]
    c = report["conflicts"]
    out += ["", f"Conflicts (not merged): {len(c['owner_with_several_numbers'])} owner(s) with "
                f"several document numbers, {len(c['number_under_several_owners'])} number(s) under several owners"]
    for item in c["owner_with_several_numbers"]:
        out.append(f"  {item['owner']} {item['doc_type']}: {', '.join(item['numbers'])} ({item['trips']} trips)")
    for item in c["number_under_several_owners"]:
        out.append(f"  {item['doc_type']} {item['number']} under {', '.join(item['owners'])}")
    out += ["", "Other upload sources (not in the trip columns):"]
    for name, info in report["other_sources"].items():
        missing = info["missing_on_disk"]
        out.append(f"  {name:20} {info['rows']:5} rows" + ("" if missing is None else f"   missing on disk: {missing}"))
    orphans = report["orphan_files_on_disk"]
    if orphans is None:
        out += ["", "Uploads folder: empty or not found, so disk checks were skipped."]
    else:
        out += ["", f"Files on disk that no column points to: {orphans['count']}"]
        out += [f"  {u}" for u in orphans["examples"]]
    return "\n".join(out)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--url", default=os.environ.get("DATABASE_URL", DEFAULT_URL))
    parser.add_argument("--uploads-dir", default=str(DEFAULT_UPLOADS_DIR))
    parser.add_argument("--json", dest="json_path")
    args = parser.parse_args(argv)

    if not is_dev_database_url(args.url):
        print("REFUSED: this dry run only works on the local dev database "
              "(localhost:5434, fleet_db_dev or fleet_db_prodcopy).", file=sys.stderr)
        return 2

    trips, lookups, _users, others = load_sources(args.url)
    other_urls = {name: [url for _id, url in rows] for name, rows in others.items()}
    report = analyze(trips, lookups, read_uploads(args.uploads_dir), other_urls)
    print(render(report))
    if args.json_path:
        Path(args.json_path).write_text(json.dumps(report, indent=2, default=str), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
