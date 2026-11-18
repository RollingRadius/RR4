"""Serve uploaded files from the database at their /uploads/... URLs.

Only registered when UPLOADS_FROM_DB is on (see app/main.py); until then the old
StaticFiles mount serves the disk. Public by design, exactly like that mount: the
app loads these URLs with a plain Image.network and no login. A file is found by
its URL in the document tables; the disk is never read.
"""

from fastapi import APIRouter, HTTPException, Request, Response

from app.database import SessionLocal
from app.services.stored_file_service import find_stored_file, read_content

router = APIRouter()


def etag_matches(if_none_match: str, sha256: str) -> bool:
    """True when the browser's If-None-Match header already names this file's checksum."""
    if not if_none_match:
        return False
    wanted = f'"{sha256}"'
    candidates = [c.strip().removeprefix("W/") for c in if_none_match.split(",")]
    return "*" in candidates or wanted in candidates


@router.api_route("/uploads/{file_path:path}", methods=["GET", "HEAD"], include_in_schema=False)
def serve_upload(file_path: str, request: Request):
    url_path = f"/uploads/{file_path}"
    # The session is open only for the two quick queries, never while the response is sent.
    with SessionLocal() as db:
        stored = find_stored_file(db, url_path)
        if stored is None:
            raise HTTPException(status_code=404, detail="File not found")

        # ETag from the checksum; no-cache means "ask me again", answered with a 304 and no bytes.
        # A Stage 1 document keeps its URL when its file is replaced, so it must not be cached blindly.
        headers = {"ETag": f'"{stored.sha256}"', "Cache-Control": "no-cache"}
        if etag_matches(request.headers.get("if-none-match", ""), stored.sha256):
            return Response(status_code=304, headers=headers)
        if request.method == "HEAD":
            return Response(media_type=stored.content_type,
                            headers={**headers, "Content-Length": str(stored.size_bytes)})
        content = read_content(db, stored)
    return Response(content=content, media_type=stored.content_type, headers=headers)
