"""Phone number normalization for cross-system (RR web <-> RR4) matching.

rr_sync.py's driver/transporter RR-ID lookups (~lines 1592, 1617) now call
this directly — they used to duplicate a stripped-down version inline that
didn't strip embedded non-digit characters (only a leading '+'), so a phone
number like "98765-43210" would silently fail to match. Fixed 2026-09-16.
Must stay in sync with the SQL expression in
alembic/versions/090_add_driver_phone_index.py.
"""


def normalize_phone(raw: str | None) -> str | None:
    """Strip whitespace, drop a leading '+', return the last 10 digits.

    Returns None if the input is empty or doesn't resolve to at least 10
    digits (e.g. garbage data) — callers should treat None as "no match
    possible", not raise.
    """
    if not raw:
        return None
    digits = raw.strip().lstrip("+")
    digits = "".join(ch for ch in digits if ch.isdigit())
    if len(digits) < 10:
        return None
    return digits[-10:]
