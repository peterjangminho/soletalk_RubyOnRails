#!/usr/bin/env bash
set -euo pipefail

app_url="${APP_URL:-https://soletalk-rails-production.up.railway.app}"
lines="${LINES:-600}"
retry_max="${RETRY_MAX:-5}"

retry_cmd() {
  local output=""
  local attempt
  for attempt in $(seq 1 "$retry_max"); do
    if output="$("$@" 2>/dev/null)"; then
      printf "%s" "$output"
      return 0
    fi
    sleep 2
  done
  return 1
}

curl_status_with_retry() {
  local method="$1"
  local url="$2"
  local attempt
  local code
  for attempt in $(seq 1 "$retry_max"); do
    code="$(curl -sS -m 15 -o /dev/null -w "%{http_code}" -X "$method" "$url" 2>/dev/null || true)"
    if [[ "$code" =~ ^[0-9]{3}$ ]] && [[ "$code" != "000" ]]; then
      printf "%s" "$code"
      return 0
    fi
    sleep 2
  done
  printf "unknown"
  return 1
}

deployments_raw="$(retry_cmd railway deployment list || true)"
deployment_id="${1:-$(printf "%s\n" "$deployments_raw" | awk '/\| SUCCESS \|/ {print $1; exit}')}"

echo "== Release Readiness Evidence =="
echo "timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "app_url: $app_url"
echo "deployment_id: ${deployment_id:-unknown}"
echo ""

echo "== Deployment Head =="
if [[ -n "$deployments_raw" ]]; then
  printf "%s\n" "$deployments_raw" | head -n 6
else
  echo "deployment list: unknown (railway network error)"
fi
echo ""

echo "== Runtime Probes =="
root_code="$(curl_status_with_retry GET "$app_url/")"
health_code="$(curl_status_with_retry GET "$app_url/healthz")"
sub_code="$(curl_status_with_retry POST "$app_url/subscription/validate")"
sub_body="$(curl -sS -m 15 -X POST "$app_url/subscription/validate" 2>/dev/null || true)"
echo "GET / => $root_code"
echo "GET /healthz => $health_code"
echo "POST /subscription/validate (no csrf) => $sub_code"
if [[ -n "$sub_body" ]]; then
  echo "POST /subscription/validate body => $(printf "%s" "$sub_body" | head -c 120)"
fi
echo ""

echo "== RevenueCat ENV Presence =="
vars_kv="$(retry_cmd railway variables --kv || true)"
if [[ -z "$vars_kv" ]]; then
  echo "REVENUECAT_BASE_URL=unknown (railway network error)"
  echo "REVENUECAT_API_KEY=unknown (railway network error)"
else
  printf "%s\n" "$vars_kv" | awk -F= '
    /^REVENUECAT_BASE_URL=/ { print "REVENUECAT_BASE_URL=present"; b=1 }
    /^REVENUECAT_API_KEY=/ { if(length($2)>0) print "REVENUECAT_API_KEY=present"; else print "REVENUECAT_API_KEY=empty"; k=1 }
    END {
      if(!b) print "REVENUECAT_BASE_URL=missing";
      if(!k) print "REVENUECAT_API_KEY=missing";
    }
  '
fi
echo ""

if [[ -n "$deployment_id" ]]; then
  echo "== subscription/validate Logs (last ${lines}) =="
  LINES="$lines" script/railway/collect_subscription_validate_evidence.sh "$deployment_id" || true
else
  echo "Skipping log trace: no SUCCESS deployment id found."
fi
