"""
OpenTelemetry + Prometheus telemetry setup.

Feature-flagged via env vars — zero overhead when disabled.

To disable OTEL:       set OTEL_ENABLED=false  in .env
To disable Prometheus: set PROMETHEUS_ENABLED=false in .env
To fully remove:       delete this file + revert the 6 lines added in main.py
"""

from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource, SERVICE_NAME, SERVICE_VERSION
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from opentelemetry.instrumentation.redis import RedisInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor


def setup_otel(app, engine=None, service_name: str = "fleet-management-api",
               service_version: str = "1.0.0", otlp_endpoint: str = "http://localhost:4317"):
    """
    Initialize OpenTelemetry tracing and send spans to SigNoz via OTLP.

    Instruments:
      - FastAPI  → every HTTP request becomes a span
      - SQLAlchemy → every DB query becomes a child span
      - Redis    → every Redis call becomes a child span
      - Requests → every outbound HTTP call becomes a child span
    """
    resource = Resource.create({
        SERVICE_NAME: service_name,
        SERVICE_VERSION: service_version,
        "deployment.environment": "development",
    })

    provider = TracerProvider(resource=resource)

    exporter = OTLPSpanExporter(
        endpoint=otlp_endpoint,
        insecure=True,  # no TLS for local SigNoz
    )
    provider.add_span_processor(BatchSpanProcessor(exporter))
    trace.set_tracer_provider(provider)

    # Instrument FastAPI — captures every request as a root span
    FastAPIInstrumentor.instrument_app(app)

    # Instrument SQLAlchemy — attaches DB query spans to the active request span
    if engine is not None:
        SQLAlchemyInstrumentor().instrument(engine=engine)

    # Instrument Redis — attaches Redis command spans
    RedisInstrumentor().instrument()

    # Instrument outbound HTTP (requests lib) — attaches external call spans
    RequestsInstrumentor().instrument()

    print(f"[OTEL] Tracing enabled → {otlp_endpoint}  service={service_name}")


def setup_prometheus(app):
    """
    Expose /metrics endpoint for Prometheus to scrape.

    Metrics exposed:
      - http_requests_total          (count by endpoint + status)
      - http_request_duration_seconds (latency histogram p50/p95/p99)
      - http_requests_in_progress    (active concurrent requests)
    """
    from prometheus_fastapi_instrumentator import Instrumentator

    Instrumentator(
        should_group_status_codes=False,   # track 200/201/400/422/500 separately
        should_ignore_untemplated=False,   # track all requests including failed validation
        should_respect_env_var=False,
    ).instrument(app).expose(app, endpoint="/metrics")

    print("[Prometheus] Metrics exposed → /metrics")
