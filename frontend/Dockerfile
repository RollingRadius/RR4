# Multi-stage: Flutter builds web, nginx serves it.
# Flutter SDK lives only inside the builder layer — not in the final image.

# ─── Stage 1: Build ────────────────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

ARG API_BASE_URL=http://34.127.125.215:8000
RUN flutter build web --release \
      --dart-define=API_BASE_URL=${API_BASE_URL} && \
    # Remove everything except the web output to free layer space
    find . -maxdepth 1 ! -name 'build' -exec rm -rf {} + 2>/dev/null || true

# ─── Stage 2: Serve ────────────────────────────────────────────────────────────
FROM nginx:alpine

COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
