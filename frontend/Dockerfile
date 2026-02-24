# ─── Stage 1: Build Flutter web ───────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copy pubspec first so dependency layer is cached separately
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the rest of the source
COPY . .

# API_BASE_URL is a compile-time constant (String.fromEnvironment).
# Override at build time with: docker build --build-arg API_BASE_URL=...
ARG API_BASE_URL=http://34.127.125.215:8000

RUN flutter build web --release \
      --dart-define=API_BASE_URL=${API_BASE_URL}

# ─── Stage 2: Serve with nginx ─────────────────────────────────────────────────
FROM nginx:alpine

COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
