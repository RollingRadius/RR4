"""Copy uploaded files from the disk into the document tables (dev database only).

Run from the backend folder:

    python -m scripts.copy_uploads_to_db              show the plan, write nothing
    python -m scripts.copy_uploads_to_db --apply      insert the rows and fill the byte columns
    python -m scripts.copy_uploads_to_db --verify     compare the database with the disk and the plan
    python -m scripts.copy_uploads_to_db --wipe       empty the document tables and byte columns again

Safe to re-run: rows that already exist are skipped. It never deletes or changes a
file on the disk and never changes the trips table (older trips are repointed in a
later, separate step). Refuses any database but the local dev one
(localhost:5434, fleet_db_dev or fleet_db_prodcopy). Plan: md/TESTS_NEXT_STEPS_AND_OPEN_FINDINGS.md.
"""

import argparse
import hashlib
import mimetypes
import os
import sys
import uuid
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

import psycopg2

from app.core.document_map import DRIVER, OWNER, TRIP, VEHICLE, is_dev_database_url
from scripts.uploads_dry_run import DEFAULT_UPLOADS_DIR, DEFAULT_URL
from scripts.uploads_plan import build_plan, load_sources

BATCH = 25
DOCUMENT_TABLES = (DRIVER, VEHICLE, OWNER, TRIP)
OWNER_COLUMN = {
    "driver": "driver_id", "rr_driver": "rr_driver_id",
    "vehicle": "vehicle_id", "rr_vehicle": "rr_vehicle_id",
    "org": "organization_id", "rr_company": "rr_company_id",
}
# name -> (table, url column, SQL SET clause, columns the clause fills)
OTHER_FILL = {
    "profile_pictures": ("users", "profile_picture_url",
                         "profile_picture_content=%s, profile_picture_content_type=%s, profile_picture_sha256=%s",
                         "profile_picture_content"),
    "receiving_documents": ("receiving_documents", "file_url",
                            "content=%s, content_type=%s, sha256=%s, size_bytes=%s", "content"),
    "logos": ("organization_branding", "logo_url",
              "logo_content=%s, logo_content_type=%s, logo_sha256=%s", "logo_content"),
}


def disk_path(uploads_dir, url):
    return Path(uploads_dir) / url[len("/uploads/"):]


def read_file(path):
    data = path.read_bytes()
    return data, hashlib.sha256(data).hexdigest(), mimetypes.guess_type(path.name)[0] or "application/octet-stream"


def uploader_hints(doc, users, user_ids_by_name):
    """Best guess of who uploaded a backfilled file. Never presented as fact (uploaded_via = backfill)."""
    if doc.attributed_username:
        return user_ids_by_name.get(doc.attributed_username), doc.attributed_username, "backfill: field_attributions"
    if doc.submitted_by and doc.submitted_by in users:
        return doc.submitted_by, users[doc.submitted_by], "backfill: stage submitter"
    return None, None, "backfill: uploader unknown"


def row_for(doc, path, users, user_ids_by_name):
    data, sha, content_type = read_file(path)
    uploaded_by, username, ref = uploader_hints(doc, users, user_ids_by_name)
    stamp = doc.stamp if doc.stamp != datetime.min else datetime.now(timezone.utc)
    row = {
        "id": str(uuid.uuid4()), "url_path": doc.url, "content": psycopg2.Binary(data),
        "content_type": content_type, "size_bytes": len(data), "sha256": sha, "file_name": path.name,
        "uploaded_by": uploaded_by, "uploader_username": username, "uploaded_via": "backfill",
        "uploader_ref": ref, "uploaded_at": stamp,
    }
    if doc.table == TRIP:
        row.update(trip_id=doc.trip_id, doc_type=doc.doc_type, slot=doc.slot, stage=doc.stage)
    else:
        row.update({OWNER_COLUMN[doc.owner[0]]: doc.owner[1], "doc_type": doc.doc_type, "side": doc.side,
                    "number": doc.number or None})
    return row


def apply_plan(conn, plan, uploads_dir, users):
    user_ids_by_name = {name: uid for uid, name in users.items()}
    stats, cur = Counter(), conn.cursor()
    for i, doc in enumerate(plan.docs, 1):
        path = disk_path(uploads_dir, doc.url)
        if not path.is_file():
            stats[f"{doc.table}: file missing on disk"] += 1
            continue
        row = row_for(doc, path, users, user_ids_by_name)
        columns = list(row)
        cur.execute(f"INSERT INTO {doc.table} ({', '.join(columns)}) "
                    f"VALUES ({', '.join(['%s'] * len(columns))}) ON CONFLICT DO NOTHING",
                    [row[c] for c in columns])
        stats[f"{doc.table}: {'inserted' if cur.rowcount == 1 else 'already there or slot taken'}"] += 1
        if i % BATCH == 0:
            conn.commit()
    conn.commit()
    return stats


def apply_others(conn, others, uploads_dir):
    stats, cur = Counter(), conn.cursor()
    for name, rows in others.items():
        table, _url_col, set_clause, content_col = OTHER_FILL[name]
        for row_id, url in rows:
            path = disk_path(uploads_dir, url)
            if not path.is_file():
                stats[f"{name}: file missing on disk"] += 1
                continue
            data, sha, content_type = read_file(path)
            values = [psycopg2.Binary(data), content_type, sha] + ([len(data)] if "size_bytes" in set_clause else [])
            cur.execute(f"UPDATE {table} SET {set_clause} WHERE id=%s AND {content_col} IS NULL", values + [row_id])
            stats[f"{name}: {'filled' if cur.rowcount == 1 else 'already filled'}"] += 1
    conn.commit()
    return stats


def verify(conn, plan, others, uploads_dir):
    """Returns a list of problems (empty = the database matches the disk and the plan)."""
    problems, cur = [], conn.cursor()
    expected = Counter(doc.table for doc in plan.docs)
    for table in DOCUMENT_TABLES:
        cur.execute(f"SELECT count(*), count(*) FILTER (WHERE sha256 <> encode(sha256(content), 'hex')), "
                    f"count(*) FILTER (WHERE size_bytes <> octet_length(content)) FROM {table}")
        total, bad_hash, bad_size = cur.fetchone()
        print(f"  {table:20} rows {total:5}  planned {expected[table]:5}  bad checksum {bad_hash}  bad size {bad_size}")
        if total != expected[table]:
            problems.append(f"{table}: {total} rows, plan says {expected[table]}")
        if bad_hash or bad_size:
            problems.append(f"{table}: stored bytes do not match their own checksum or size")
        cur.execute(f"SELECT url_path, sha256 FROM {table}")
        for url, sha in cur.fetchall():
            path = disk_path(uploads_dir, url)
            if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != sha:
                problems.append(f"{table}: {url} differs from the file on disk")
    for name, rows in others.items():
        table, url_col, _set, content_col = OTHER_FILL[name]
        cur.execute(f"SELECT count(*) FROM {table} WHERE {url_col} IS NOT NULL AND {content_col} IS NULL")
        empty = cur.fetchone()[0]
        print(f"  {name:20} rows {len(rows):5}  still without bytes {empty}")
        if empty:
            problems.append(f"{name}: {empty} rows have a URL but no bytes")
    return problems


def wipe(conn):
    cur = conn.cursor()
    cur.execute("TRUNCATE document_history, " + ", ".join(DOCUMENT_TABLES))
    cur.execute("UPDATE users SET profile_picture_content=NULL, profile_picture_content_type=NULL, "
                "profile_picture_sha256=NULL")
    cur.execute("UPDATE receiving_documents SET content=NULL, content_type=NULL, sha256=NULL, size_bytes=NULL")
    cur.execute("UPDATE organization_branding SET logo_content=NULL, logo_content_type=NULL, logo_sha256=NULL")
    conn.commit()


def summarize(plan):
    rows = Counter(doc.table for doc in plan.docs)
    print("Plan:")
    for table in DOCUMENT_TABLES:
        print(f"  {table:20} {rows[table]}")
    print(f"  older copies not imported (stored once): {len(plan.older_copies)}")
    print(f"  trip columns that would be repointed later: {len(plan.repoint)}")
    print(f"  kept trip-only because the owner has several numbers: {plan.kept_trip_only_for_conflict}")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--url", default=os.environ.get("DATABASE_URL", DEFAULT_URL))
    parser.add_argument("--uploads-dir", default=str(DEFAULT_UPLOADS_DIR))
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--apply", action="store_true")
    mode.add_argument("--verify", action="store_true")
    mode.add_argument("--wipe", action="store_true")
    args = parser.parse_args(argv)

    if not is_dev_database_url(args.url):
        print("REFUSED: this script only works on the local dev database "
              "(localhost:5434, fleet_db_dev or fleet_db_prodcopy).", file=sys.stderr)
        return 2

    trips, lookups, users, others = load_sources(args.url)
    plan = build_plan(trips, lookups)

    if args.wipe:
        conn = psycopg2.connect(args.url)
        try:
            wipe(conn)
        finally:
            conn.close()
        print("Document tables emptied and byte columns cleared. Files on disk untouched.")
        return 0

    summarize(plan)
    if not (args.apply or args.verify):
        print("\nNothing written (add --apply to copy, --verify to check).")
        return 0

    conn = psycopg2.connect(args.url)
    try:
        if args.apply:
            print("\nCopying...")
            stats = apply_plan(conn, plan, args.uploads_dir, users)
            stats.update(apply_others(conn, others, args.uploads_dir))
            for key in sorted(stats):
                print(f"  {key}: {stats[key]}")
            print("Run with --verify to check the result.")
            return 0
        print("\nVerifying...")
        problems = verify(conn, plan, others, args.uploads_dir)
        print("\nOK: the database matches the disk and the plan." if not problems else "\nPROBLEMS:")
        for problem in problems:
            print(f"  {problem}")
        return 1 if problems else 0
    finally:
        conn.close()


if __name__ == "__main__":
    sys.exit(main())
