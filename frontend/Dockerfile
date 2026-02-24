# Flutter is built LOCALLY by start.sh before this runs.
# This image only needs nginx (~5 MB) — no Flutter SDK on the server.
#
# Pre-requisite: run  flutter build web --release  first (start.sh does this).

FROM nginx:alpine

COPY build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
