"""One copy of a background job across all uvicorn workers (user, 2026-11-26: 2 workers on fc3 and fc11).

Every worker starts the background loops (GPS watchdog, 3-minute RR web check) from main.py's startup. Before each
round a loop asks `is_leader()`: the first worker to take the Postgres advisory lock for that job keeps it (on its own
connection, held open) and runs every round; the other workers skip. If the leading worker stops, its connection
closes, Postgres frees the lock and another worker takes over at its next round.
"""
import logging

from sqlalchemy import create_engine, text
from sqlalchemy.pool import NullPool

from app.config import settings

logger = logging.getLogger(__name__)

# Fixed Postgres advisory lock keys, one per background job.
TRACKING_WATCHDOG_KEY = 7241001
RR_FOLLOW_KEY = 7241002
CONNECT_TIMEOUT_SECONDS = 5

_engine = None


def _lock_engine():
    """Separate engine without a pool: the held lock connection never takes a slot of the app's pool."""
    global _engine
    if _engine is None:
        # connect_timeout: a database that does not answer makes this round skip instead of freezing the worker.
        # keepalives: the held lock connection notices a dead network in about a minute instead of hanging.
        _engine = create_engine(settings.DATABASE_URL, poolclass=NullPool, isolation_level="AUTOCOMMIT",
                                connect_args={"connect_timeout": CONNECT_TIMEOUT_SECONDS, "keepalives": 1,
                                              "keepalives_idle": 30, "keepalives_interval": 10,
                                              "keepalives_count": 3})
    return _engine


class LeaderLock:
    def __init__(self, key: int, name: str):
        self.key = key
        self.name = name
        self._conn = None

    def is_leader(self) -> bool:
        """True when this worker holds the job's lock (taking it now if it is free); never raises."""
        if self._conn is not None:
            try:
                self._conn.execute(text("SELECT 1"))
                return True
            except Exception:
                logger.warning(f"[Leader] {self.name}: lock connection lost - trying to take the lock again")
                self._close()
        conn = None
        try:
            conn = _lock_engine().connect()
            if conn.execute(text("SELECT pg_try_advisory_lock(:k)"), {"k": self.key}).scalar():
                self._conn = conn
                logger.info(f"[Leader] {self.name}: this worker runs the job")
                return True
            conn.close()
        except Exception:
            logger.exception(f"[Leader] {self.name}: could not check the lock - skipping this round")
            if conn is not None:
                conn.close()
        return False

    def release(self) -> None:
        if self._conn is None:
            return
        try:
            self._conn.execute(text("SELECT pg_advisory_unlock(:k)"), {"k": self.key})
        except Exception:
            logger.warning(f"[Leader] {self.name}: unlock failed (freed when the connection closes)")
        self._close()

    def _close(self) -> None:
        try:
            self._conn.close()
        except Exception:
            pass
        self._conn = None
