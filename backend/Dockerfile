# Fleet Management System - Backend Dockerfile
# Alpine-based build for smaller, faster images

# ============================================================================
# Stage 1: Base - Common dependencies and configuration
# ============================================================================
FROM python:3.11-alpine AS base

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_DEFAULT_TIMEOUT=100

# Create app user with specific UID/GID for security
RUN addgroup -g 1001 appgroup && \
    adduser -D -u 1001 -G appgroup appuser

# Set working directory
WORKDIR /app

# ============================================================================
# Stage 2: Builder - Install dependencies and build artifacts
# ============================================================================
FROM base AS builder

# Install build dependencies (only in builder stage)
RUN apk add --no-cache --virtual .build-deps \
    gcc \
    g++ \
    musl-dev \
    python3-dev \
    postgresql-dev \
    linux-headers

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies globally (not --user)
RUN pip install --no-warn-script-location -r requirements.txt

# Remove build dependencies
RUN apk del .build-deps

# ============================================================================
# Stage 3: Development - Full environment with hot reload
# ============================================================================
FROM base AS development

# Install runtime dependencies + development tools
RUN apk add --no-cache \
    postgresql-client \
    curl \
    bash \
    vim \
    redis \
    netcat-openbsd

# Copy Python packages from builder (now in global site-packages)
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY --chown=appuser:appgroup . .

# Create necessary directories with proper permissions
RUN mkdir -p /app/uploads /app/logs && \
    chown -R appuser:appgroup /app/uploads /app/logs && \
    chmod +x /app/docker-entrypoint.sh

# Expose port
EXPOSE 8000

# Switch to non-root user
USER appuser

# Set entrypoint
ENTRYPOINT ["/app/docker-entrypoint.sh"]

# Development command with hot reload
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

# ============================================================================
# Stage 4: Production - Minimal, secure runtime image
# ============================================================================
FROM base AS production

# Install only runtime dependencies (no build tools)
RUN apk add --no-cache \
    postgresql-client \
    curl \
    bash \
    redis \
    netcat-openbsd

# Copy Python packages from builder (now in global site-packages)
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code with proper ownership
COPY --chown=appuser:appgroup ./app /app/app
COPY --chown=appuser:appgroup ./alembic /app/alembic
COPY --chown=appuser:appgroup ./alembic.ini /app/alembic.ini
COPY --chown=appuser:appgroup ./docker-entrypoint.sh /app/docker-entrypoint.sh
COPY --chown=appuser:appgroup ./init-db.py /app/init-db.py
COPY --chown=appuser:appgroup ./requirements.txt /app/requirements.txt

# Create necessary directories with proper permissions
RUN mkdir -p /app/uploads /app/logs && \
    chown -R appuser:appgroup /app/uploads /app/logs /app && \
    chmod +x /app/docker-entrypoint.sh

# Health check for container orchestration
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || curl -f http://localhost:8000/ || exit 1

# Switch to non-root user for security
USER appuser

# Expose port
EXPOSE 8000

# Set entrypoint
ENTRYPOINT ["/app/docker-entrypoint.sh"]

# Production command with multiple workers
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
