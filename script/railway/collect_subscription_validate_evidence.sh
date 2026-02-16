#!/usr/bin/env bash
set -euo pipefail

lines="${LINES:-400}"
deployment_id="${1:-}"

if [[ -z "$deployment_id" ]]; then
  deployment_id="$(railway deployment list | awk '/\| SUCCESS \|/ {print $1; exit}')"
fi

if [[ -z "$deployment_id" ]]; then
  echo "No SUCCESS deployment found."
  exit 1
fi

echo "Using deployment: $deployment_id"
logs=""
for attempt in 1 2 3 4 5; do
  if logs="$(railway logs --deployment "$deployment_id" -n "$lines" 2>/dev/null)"; then
    break
  fi
  echo "railway logs failed (attempt=$attempt), retrying..."
  sleep 2
done

if [[ -z "$logs" ]]; then
  echo "Failed to fetch railway logs after retries."
  exit 3
fi

request_ids="$(
  printf "%s\n" "$logs" \
    | sed -n 's/^\[\([^]]*\)\] Started POST "\/subscription\/validate".*/\1/p' \
    | sort -u
)"

if [[ -z "$request_ids" ]]; then
  echo "No /subscription/validate POST logs found in last $lines lines."
  exit 2
fi

echo ""
echo "==== subscription/validate request traces ===="
for id in $request_ids; do
  echo "--- request_id=$id ---"
  printf "%s\n" "$logs" | grep "^\[$id\]" || true
done

echo ""
echo "==== summary ===="
for id in $request_ids; do
  status_line="$(printf "%s\n" "$logs" | grep "^\[$id\] Completed " | tail -n 1 || true)"
  if [[ -n "$status_line" ]]; then
    status_code="$(printf "%s\n" "$status_line" | sed -n 's/.*Completed \([0-9][0-9][0-9]\) .*/\1/p')"
    echo "request_id=$id status=$status_code"
  else
    echo "request_id=$id status=unknown"
  fi
done

echo ""
echo "Hints:"
echo "- 302 redirect to /subscription with flash usually means authenticated flow reached controller."
echo "- 422 with InvalidAuthenticityToken means CSRF/auth-less request path."
echo "- 500 or ConfigurationError indicates server-side misconfiguration."
