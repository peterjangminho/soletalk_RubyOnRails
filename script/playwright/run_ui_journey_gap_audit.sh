#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PLAYWRIGHT_SKILL_DIR="${PLAYWRIGHT_SKILL_DIR:-/Users/peter/.codex/skills/playwright-skill}"
PROJECT_A_URL="${PROJECT_A_URL:-http://127.0.0.1:3000}"
PROJECT_B_URL="${PROJECT_B_URL:-http://127.0.0.1:4173}"
REPORT_DIR="${REPORT_DIR:-/tmp/ui-journey-audit}"
UPLOAD_FILE="${UPLOAD_FILE:-$ROOT_DIR/test/fixtures/files/sample_upload.txt}"

if [ ! -d "$PLAYWRIGHT_SKILL_DIR" ]; then
  echo "Playwright skill dir not found: $PLAYWRIGHT_SKILL_DIR" >&2
  exit 1
fi

cd "$PLAYWRIGHT_SKILL_DIR"
PROJECT_A_URL="$PROJECT_A_URL" \
PROJECT_B_URL="$PROJECT_B_URL" \
REPORT_DIR="$REPORT_DIR" \
UPLOAD_FILE="$UPLOAD_FILE" \
node run.js "$ROOT_DIR/script/playwright/ui_journey_gap_audit.js"
