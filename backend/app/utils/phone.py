"""Phone number normalization for cross-system (RR web <-> RR4) matching.

Mirrors the normalization already duplicated inline in rr_sync.py (around
lines 426-428, 1593-1594, 1618-1619) — kept as a separate new helper rather
than refactoring those existing call sites, to keep this change minimal.
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
