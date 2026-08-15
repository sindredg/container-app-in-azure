FROM nginx:1.29.8-alpine

COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY index.html styles.css app.js /usr/share/nginx/html/

# Restrict envsubst to API_* names. Without this it substitutes every
# environment variable and eats $uri, $status and the whole privacy log format.
ENV NGINX_ENVSUBST_FILTER=^API_ \
    API_UPSTREAM=http://api:8080

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://127.0.0.1:8080/health || exit 1