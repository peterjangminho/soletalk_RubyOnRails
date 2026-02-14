#!/usr/bin/env bash
set -euo pipefail

required_keys=(
  "ONTOLOGY_RAG_BASE_URL"
  "ONTOLOGY_RAG_API_KEY"
  "GOOGLE_CLIENT_ID"
  "GOOGLE_CLIENT_SECRET"
)

missing=()
for key in "${required_keys[@]}"; do
  if [[ -z "${!key:-}" ]]; then
    missing+=("$key")
  fi
done

if (( ${#missing[@]} > 0 )); then
  echo "Missing required env values in current shell:"
  for key in "${missing[@]}"; do
    echo "  - $key"
  done
  echo ""
  echo "Export values, then rerun:"
  echo "  export ONTOLOGY_RAG_BASE_URL='...'"
  echo "  export ONTOLOGY_RAG_API_KEY='...'"
  echo "  export GOOGLE_CLIENT_ID='...'"
  echo "  export GOOGLE_CLIENT_SECRET='...'"
  exit 1
fi

railway variables \
  --set "ONTOLOGY_RAG_BASE_URL=${ONTOLOGY_RAG_BASE_URL}" \
  --set "ONTOLOGY_RAG_API_KEY=${ONTOLOGY_RAG_API_KEY}" \
  --set "GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}" \
  --set "GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}"

echo "Railway required app envs updated."
