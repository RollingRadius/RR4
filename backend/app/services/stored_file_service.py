"""Find an uploaded file by its /uploads/... URL in the tables that hold the bytes.

The URL prefix tells which tables can hold the file, so a lookup asks at most the four
document tables in one query. The query never reads the bytes; `read_content` does,
and only when the file really has to be sent.
"""

from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import SessionLocal


@dataclass(frozen=True)
class _Source:
    table: str
    url_col: str
    content_col: str
    sha_col: str
    type_col: str
    size_expr: str


def _document_table(table: str) -> _Source:
    return _Source(table, "url_path", "content", "sha256", "content_type", "size_bytes")


DRIVER = _document_table("driver_documents")
VEHICLE = _document_table("vehicle_documents")
OWNER = _document_table("owner_documents")
TRIP = _document_table("trip_documents")
PROFILE_PICTURE = _Source("users", "profile_picture_url", "profile_picture_content",
                          "profile_picture_sha256", "profile_picture_content_type",
                          "octet_length(profile_picture_content)")
RECEIVING = _Source("receiving_documents", "file_url", "content", "sha256", "content_type", "size_bytes")
LOGO = _Source("organization_branding", "logo_url", "logo_content", "logo_sha256",
               "logo_content_type", "octet_length(logo_content)")

SOURCES_BY_PREFIX = {
    "/uploads/trips/": (DRIVER, VEHICLE, OWNER, TRIP),
    "/uploads/profile_pictures/": (PROFILE_PICTURE,),
    "/uploads/receiving_documents/": (RECEIVING,),
    "/uploads/logos/": (LOGO,),
}
SOURCES_BY_TABLE = {s.table: s for sources in SOURCES_BY_PREFIX.values() for s in sources}


@dataclass(frozen=True)
class StoredFile:
    source: _Source
    id: str
    sha256: str
    content_type: str
    size_bytes: int


def sources_for(url_path: str) -> tuple:
    for prefix, sources in SOURCES_BY_PREFIX.items():
        if url_path.startswith(prefix):
            return sources
    return ()


def find_stored_file(db: Session, url_path: str) -> Optional[StoredFile]:
    """The stored file behind `url_path` (metadata only), or None. Rows with no bytes are ignored."""
    sources = sources_for(url_path)
    if not sources:
        return None
    # Table and column names come from the constants above, never from the request.
    query = " UNION ALL ".join(
        f"SELECT '{s.table}' AS source, id::text AS id, {s.sha_col} AS sha256, "
        f"{s.type_col} AS content_type, {s.size_expr} AS size_bytes "
        f"FROM {s.table} WHERE {s.url_col} = :url AND {s.content_col} IS NOT NULL"
        for s in sources
    )
    row = db.execute(text(query + " LIMIT 1"), {"url": url_path}).first()
    if row is None:
        return None
    return StoredFile(SOURCES_BY_TABLE[row.source], row.id, row.sha256, row.content_type, row.size_bytes)


def read_content(db: Session, stored: StoredFile) -> bytes:
    source = stored.source
    row = db.execute(
        text(f"SELECT {source.content_col} FROM {source.table} WHERE id = CAST(:id AS uuid)"),
        {"id": stored.id},
    ).first()
    return bytes(row[0]) if row and row[0] is not None else b""


@dataclass(frozen=True)
class StoredBytes:
    content: bytes
    content_type: str
    file_name: str


def load_stored_file(url_path: str) -> Optional[StoredBytes]:
    """The bytes of a stored file by its /uploads/... URL, on a short session of its own (safe to call from a thread)."""
    with SessionLocal() as db:
        stored = find_stored_file(db, url_path)
        if stored is None:
            return None
        return StoredBytes(read_content(db, stored), stored.content_type, Path(url_path).name)
