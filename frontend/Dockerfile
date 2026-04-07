# Pre-built: Flutter web is built locally and committed to build/web.
# The server only runs nginx — no Flutter SDK needed on the server.

FROM nginx:alpine

COPY build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
