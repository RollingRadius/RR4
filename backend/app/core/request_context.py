"""
Per-request correlation ID, stored in a ContextVar so it stays isolated
across concurrent async requests (unlike a plain module-level variable).

Not propagated automatically into FastAPI BackgroundTasks — those run after
the middleware has already reset the context, so callers that log from a
background task (e.g. rr_sync_service.sync_all_to_rr) must read the ID here
before scheduling the task and pass it through explicitly.
"""

from contextvars import ContextVar

request_id_ctx: ContextVar[str] = ContextVar("request_id", default="-")
