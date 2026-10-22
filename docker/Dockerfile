# Pocket Orrery served by nginx on Alpine Linux, running as a non-root user (uid 101) on port 8080.
# Build from the repo root:  docker build -f docker/Dockerfile -t pocket-orrery:local .
FROM nginxinc/nginx-unprivileged:1.27-alpine

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --chmod=0755 docker/40-orrery-config.sh /docker-entrypoint.d/40-orrery-config.sh
# The entrypoint rewrites config.js at start, so the web root belongs to the nginx user.
COPY --chown=101:101 site/ /usr/share/nginx/html/

# Empty = live quiz stats off. Set to the API Gateway URL to turn them on.
ENV API_URL=""

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
