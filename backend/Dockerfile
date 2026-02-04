# Fleet Management System - Backend Dockerfile
# Multi-stage build for optimized, secure production image

# ============================================================================
# Stage 1: Base - Common dependencies and configuration
# ============================================================================
FROM python:3.11-slim AS base

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_DEFAULT_TIMEOUT=100

# Create app user with specific UID/GID for security
RUN groupadd -g 1001 -r appgroup && \
    useradd -r -u 1001 -g appgroup -m -d /home/appuser -s /bin/bash appuser

# Set working directory
WORKDIR /app

# ============================================================================
# Stage 2: Builder - Install dependencies and build artifacts
# ============================================================================
FROM base AS builder

# Install build dependencies (only in builder stage)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    python3-dev \
    musl-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies with cache mount for better performance
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --user --no-warn-script-location -r requirements.txt

# ============================================================================
# Stage 3: Development - Full environment with hot reload
# ============================================================================
FROM base AS development

# Install runtime dependencies + development tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    curl \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Copy Python packages from builder
COPY --from=builder /root/.local /root/.local

# Add Python packages to PATH
ENV PATH=/root/.local/bin:$PATH

# Copy application code
COPY --chown=appuser:appgroup . .

# Create necessary directories with proper permissions
RUN mkdir -p /app/uploads /app/logs && \
    chown -R appuser:appgroup /app/uploads /app/logs && \
    chmod +x /app/docker-entrypoint.sh

# Expose port
EXPOSE 8000

# Run as root for development (to avoid permission issues with bind mounts)
# In production, we run as non-root user
USER root

# Set entrypoint
ENTRYPOINT ["/app/docker-entrypoint.sh"]

# Development command with hot reload
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

# ============================================================================
# Stage 4: Production - Minimal, secure runtime image
# ============================================================================
FROM base AS production

# Install only runtime dependencies (no build tools)
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy Python packages from builder (installed to /root/.local)
COPY --from=builder /root/.local /root/.local

# Add Python packages to PATH
ENV PATH=/root/.local/bin:$PATH

# Copy application code with proper ownership
COPY --chown=appuser:appgroup ./app /app/app
COPY --chown=appuser:appgroup ./alembic /app/alembic
COPY --chown=appuser:appgroup ./alembic.ini /app/alembic.ini
COPY --chown=appuser:appgroup ./docker-entrypoint.sh /app/docker-entrypoint.sh
COPY --chown=appuser:appgroup ./init-db.py /app/init-db.py
COPY --chown=appuser:appgroup ./reset-db.py /app/reset-db.py
COPY --chown=appuser:appgroup ./requirements.txt /app/requirements.txt

# Create necessary directories with proper permissions
RUN mkdir -p /app/uploads /app/logs && \
    chown -R appuser:appgroup /app/uploads /app/logs /app && \
    chmod +x /app/docker-entrypoint.sh

# Health check for container orchestration
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health || curl -f http://localhost:8000/ || exit 1

# Switch to non-root user for security
USER appuser

# Expose port
EXPOSE 8000

# Set entrypoint
ENTRYPOINT ["/app/docker-entrypoint.sh"]

# Production command (NO --reload flag)
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
