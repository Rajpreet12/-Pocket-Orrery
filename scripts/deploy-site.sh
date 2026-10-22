#!/usr/bin/env bash
# Uploads site/ to S3 with the live API URL baked into config.js, then refreshes CloudFront.
#
# Locally it reads the values from Terraform outputs. In CI, set SITE_BUCKET,
# DISTRIBUTION_ID and API_URL instead (there is no Terraform state there).
set -euo pipefail

cd "$(dirname "$0")/.."

tf_out() { terraform -chdir=infra output -raw "$1"; }
SITE_BUCKET="${SITE_BUCKET:-$(tf_out site_bucket)}"
DISTRIBUTION_ID="${DISTRIBUTION_ID:-$(tf_out distribution_id)}"
API_URL="${API_URL:-$(tf_out api_url)}"

build="$(mktemp -d)"
trap 'rm -rf "$build"' EXIT
cp -R site/. "$build/"
printf 'window.ORRERY_CONFIG = { apiUrl: "%s" };\n' "$API_URL" > "$build/config.js"

echo "Uploading to s3://$SITE_BUCKET"
# Everything except the page and its config can be cached for a day at the edge.
aws s3 sync "$build/" "s3://$SITE_BUCKET/" --delete \
  --exclude index.html --exclude config.js \
  --cache-control "public, max-age=86400"
aws s3 cp "$build/index.html" "s3://$SITE_BUCKET/index.html" \
  --cache-control "no-cache" --content-type "text/html; charset=utf-8"
aws s3 cp "$build/config.js" "s3://$SITE_BUCKET/config.js" \
  --cache-control "no-cache" --content-type "application/javascript"

echo "Refreshing CloudFront $DISTRIBUTION_ID"
# MSYS_NO_PATHCONV stops Git Bash on Windows from rewriting "/index.html" into a file path.
MSYS_NO_PATHCONV=1 aws cloudfront create-invalidation --distribution-id "$DISTRIBUTION_ID" \
  --paths "/index.html" "/config.js" "/" --query 'Invalidation.Id' --output text

echo "Done. Live at: https://$(aws cloudfront get-distribution --id "$DISTRIBUTION_ID" --query 'Distribution.DomainName' --output text 2>/dev/null || echo "<your CloudFront domain>")"
