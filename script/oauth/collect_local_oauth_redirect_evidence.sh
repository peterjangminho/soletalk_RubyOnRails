#!/bin/bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:3000}"
ALT_BASE_URL="${ALT_BASE_URL:-http://localhost:3000}"
REPORT_DIR="${REPORT_DIR:-/tmp/oauth-local-gate}"

mkdir -p "$REPORT_DIR"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
REPORT_PATH="$REPORT_DIR/local_oauth_redirect_${TIMESTAMP}.txt"

extract_location() {
  awk 'tolower($1)=="location:"{sub(/\r$/,"",$2); print $2; exit}'
}

extract_query_param() {
  ruby -ruri -e '
    location = ARGV[0].to_s
    key = ARGV[1].to_s
    begin
      uri = URI.parse(location)
      params = URI.decode_www_form(uri.query.to_s).to_h
      puts params[key].to_s
    rescue
      puts ""
    end
  ' "$1" "$2"
}

collect_provider_redirect() {
  local label="$1"
  local url="$2"
  local headers location redirect_uri client_id

  headers="$(curl -sS -D - -o /dev/null "${url%/}/auth/google_oauth2")"
  location="$(printf '%s\n' "$headers" | extract_location)"
  redirect_uri="$(extract_query_param "$location" "redirect_uri")"
  client_id="$(extract_query_param "$location" "client_id")"

  echo "[$label]"
  echo "base_url=${url%/}"
  echo "provider_location=$location"
  echo "redirect_uri=$redirect_uri"
  echo "client_id=$client_id"
  echo
}

collect_start_gate() {
  local url="$1"
  local headers location

  headers="$(curl -sS -D - -o /dev/null "${url%/}/auth/google_oauth2/start")"
  location="$(printf '%s\n' "$headers" | extract_location)"
  echo "[oauth_start_gate]"
  echo "base_url=${url%/}"
  echo "start_location=$location"
  echo
}

{
  echo "generated_at_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "report_purpose=local_google_oauth_redirect_uri_evidence"
  echo
  collect_provider_redirect "host_127" "$BASE_URL"
  collect_provider_redirect "host_localhost" "$ALT_BASE_URL"
  collect_start_gate "$BASE_URL"
  echo "required_google_console_redirect_uris:"
  echo "  - http://127.0.0.1:3000/auth/google_oauth2/callback"
  echo "  - http://localhost:3000/auth/google_oauth2/callback"
  echo "  - https://soletalk-rails-production.up.railway.app/auth/google_oauth2/callback"
} | tee "$REPORT_PATH"

echo "REPORT_PATH=$REPORT_PATH"
