#!/usr/bin/env bash
set -euo pipefail

base_url="${REVENUECAT_BASE_URL:-https://api.revenuecat.com}"
api_key="${REVENUECAT_API_KEY:-}"

if [[ -z "$api_key" ]]; then
  echo "Missing required env value: REVENUECAT_API_KEY"
  echo ""
  echo "Export and rerun:"
  echo "  export REVENUECAT_API_KEY='...'"
  echo "  export REVENUECAT_BASE_URL='https://api.revenuecat.com'   # optional override"
  echo "  bash script/railway/set_revenuecat_env.sh"
  exit 1
fi

railway variables \
  --set "REVENUECAT_BASE_URL=${base_url}" \
  --set "REVENUECAT_API_KEY=${api_key}"

echo "Railway RevenueCat envs updated."
