"""Where a new upload's bytes go.

The bytes always go into the database row. While UPLOADS_FROM_DB is off, the old static
mount still serves the disk, so a copy is also written there; once the flag is on the
database serves everything and the disk is not touched at all (old files stay put until
removal is approved).
"""

import hashlib
import mimetypes
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from app.config import settings
from app.models.document import DocumentHistory


@dataclass(frozen=True)
class StoredUpload:
    content: bytes
    content_type: str
    sha256: str
    size_bytes: int


def describe_upload(content: bytes, filename: Optional[str], declared_type: Optional[str]) -> StoredUpload:
    """Checksum, size and content type of an uploaded file (declared type, else guessed from the name)."""
    guessed = mimetypes.guess_type(filename or "")[0]
    content_type = declared_type or guessed or "application/octet-stream"
    return StoredUpload(content, content_type, hashlib.sha256(content).hexdigest(), len(content))


def fill_document_row(row, *, url_path: str, file_name: str, upload: StoredUpload, user, role_key: str, org_id,
                      uploaded_via: str = 'app', rr_file_id=None) -> None:
    """Put an upload's bytes and its uploader on a document-table row (new or being replaced)."""
    row.url_path = url_path
    row.content = upload.content
    row.content_type = upload.content_type
    row.size_bytes = upload.size_bytes
    row.sha256 = upload.sha256
    row.file_name = file_name
    row.uploaded_by = user.id
    row.uploader_username = user.username
    row.uploader_role = role_key
    row.uploader_org_id = org_id
    row.uploader_ref = None
    row.uploaded_via = uploaded_via
    row.uploaded_at = datetime.now(timezone.utc)
    # A new file has not been sent to RR yet, unless the caller just sent it (RR sync upload).
    row.rr_file_id = rr_file_id
    row.rr_synced_sha256 = upload.sha256 if rr_file_id else None


def write_disk_copy(path: Path, content: bytes) -> None:
    """Disk copy for the old static mount. Does nothing once the database serves /uploads."""
    if settings.UPLOADS_FROM_DB:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(content)


def remove_disk_copy(path: Path) -> None:
    """Best-effort delete of a disk copy. Does nothing once the database serves /uploads."""
    if settings.UPLOADS_FROM_DB:
        return
    try:
        path.unlink(missing_ok=True)
    except OSError:
        pass


def replacement_entry(*, kind: str, document_id, owner_ref: Optional[str], doc_type: str,
                      old_sha256: Optional[str], old_size_bytes: Optional[int], old_uploaded_by,
                      old_uploader_username: Optional[str], old_uploaded_at,
                      replaced_by, replaced_by_username: Optional[str], replaced_by_role: Optional[str],
                      reason: Optional[str] = None, reason_note: Optional[str] = None) -> DocumentHistory:
    """One text-and-numbers history entry for a replaced document; the caller adds it to the same transaction."""
    return DocumentHistory(
        kind=kind, document_id=document_id, owner_ref=owner_ref, doc_type=doc_type,
        old_sha256=old_sha256, old_size_bytes=old_size_bytes, old_uploaded_by=old_uploaded_by,
        old_uploader_username=old_uploader_username, old_uploaded_at=old_uploaded_at,
        replaced_by=replaced_by, replaced_by_username=replaced_by_username,
        replaced_by_role=replaced_by_role, reason=reason, reason_note=reason_note,
    )
