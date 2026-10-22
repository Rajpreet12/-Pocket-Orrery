#!/bin/sh
# Runs inside the container at start (nginx's /docker-entrypoint.d hook).
# Writes config.js from the API_URL environment variable, so one image works
# with or without the AWS backend and in any environment.
set -eu

API_URL="${API_URL:-}"
case "$API_URL" in
  "" | https://* | http://localhost*) ;;
  *) echo "40-orrery-config: API_URL must be empty or start with https://" >&2; exit 1 ;;
esac
case "$API_URL" in
  *\"* | *\\* | *"<"* | *">"*) echo "40-orrery-config: API_URL contains characters that are not allowed" >&2; exit 1 ;;
esac

printf 'window.ORRERY_CONFIG = { apiUrl: "%s" };\n' "$API_URL" > /usr/share/nginx/html/config.js
echo "40-orrery-config: quiz stats API = ${API_URL:-off}"
