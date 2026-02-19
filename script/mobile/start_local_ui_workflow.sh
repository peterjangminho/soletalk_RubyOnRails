#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PORT="${PORT:-3000}"
DEBUG_BASE_URL="${SOLETALK_DEBUG_BASE_URL:-http://127.0.0.1:${PORT}/}"
GRADLE_USER_HOME_DIR="${GRADLE_USER_HOME:-${ROOT_DIR}/.gradle-home}"

cd "$ROOT_DIR"

echo "[1/4] Android USB reverse (adb reverse tcp:${PORT} tcp:${PORT})"
adb reverse "tcp:${PORT}" "tcp:${PORT}" || true

echo "[2/4] Ensure Rails server is running on port ${PORT}"
echo "      Example: bin/rails s -b 0.0.0.0 -p ${PORT}"

echo "[3/4] Build/install Android debug with local base URL: ${DEBUG_BASE_URL}"
(
  cd mobile/android
  GRADLE_USER_HOME="${GRADLE_USER_HOME_DIR}" ./gradlew \
    -PSOLETALK_DEBUG_BASE_URL="${DEBUG_BASE_URL}" \
    installDebug
)

echo "[4/4] Local dev sign-in endpoint"
echo "      In app guest home, tap: 'Quick Dev Sign In'"
echo "      (Route: POST /dev/sign_in, enabled only in development/test)"
