#!/usr/bin/env bash
set -euo pipefail

DEVICE="${1:-}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-180}"
TMP_LOG="/tmp/voicebridge_evidence_$(date +%Y%m%d_%H%M%S).log"

ADB=(adb)
if [[ -n "$DEVICE" ]]; then
  ADB+=( -s "$DEVICE" )
fi

actions=(start_recording transcription stop_recording location_update)

echo "[voicebridge-evidence] device: ${DEVICE:-default}"
echo "[voicebridge-evidence] timeout: ${TIMEOUT_SECONDS}s"
echo "[voicebridge-evidence] log file: ${TMP_LOG}"

echo "[voicebridge-evidence] checking adb connectivity..."
"${ADB[@]}" devices -l >/dev/null

echo "[voicebridge-evidence] clearing logcat..."
"${ADB[@]}" logcat -c

echo "[voicebridge-evidence] start app if needed and run 4 actions on Session Debug Tools:"
echo "  1) Start Recording"
echo "  2) Send Transcription"
echo "  3) Stop Recording"
echo "  4) Send Location or Request Current Location"
echo

echo "[voicebridge-evidence] capturing VoiceBridge logs..."
"${ADB[@]}" logcat -v time -s VoiceBridge >"$TMP_LOG" 2>/dev/null &
LOGCAT_PID=$!
trap 'kill "$LOGCAT_PID" >/dev/null 2>&1 || true; wait "$LOGCAT_PID" 2>/dev/null || true' EXIT

start_recording_code=""
transcription_code=""
stop_recording_code=""
location_update_code=""

get_code() {
  case "$1" in
    start_recording) echo "$start_recording_code" ;;
    transcription) echo "$transcription_code" ;;
    stop_recording) echo "$stop_recording_code" ;;
    location_update) echo "$location_update_code" ;;
    *) echo "" ;;
  esac
}

set_code() {
  case "$1" in
    start_recording) start_recording_code="$2" ;;
    transcription) transcription_code="$2" ;;
    stop_recording) stop_recording_code="$2" ;;
    location_update) location_update_code="$2" ;;
  esac
}

start_ts=$(date +%s)
while true; do
  now_ts=$(date +%s)
  elapsed=$((now_ts - start_ts))
  if (( elapsed >= TIMEOUT_SECONDS )); then
    break
  fi

  for action in "${actions[@]}"; do
    if [[ -n "$(get_code "$action")" ]]; then
      continue
    fi

    latest_line=$(rg "postVoiceEvent action=${action} code=" "$TMP_LOG" | tail -n 1 || true)
    if [[ -n "$latest_line" ]]; then
      code=$(sed -E 's/.*code=([0-9]{3}).*/\1/' <<<"$latest_line")
      set_code "$action" "$code"
      echo "[voicebridge-evidence] ${action}: code=${code}"
    fi
  done

  all_found=true
  for action in "${actions[@]}"; do
    if [[ -z "$(get_code "$action")" ]]; then
      all_found=false
      break
    fi
  done

  if [[ "$all_found" == true ]]; then
    break
  fi

  sleep 1
done

kill "$LOGCAT_PID" >/dev/null 2>&1 || true
wait "$LOGCAT_PID" 2>/dev/null || true
trap - EXIT

echo
echo "=== VoiceBridge Evidence Summary ==="
printf "%-18s | %-6s\n" "action" "code"
printf '%s\n' '-------------------+-------'

all_2xx=true
for action in "${actions[@]}"; do
  code="$(get_code "$action")"
  if [[ -z "$code" ]]; then
    code="missing"
  fi
  printf "%-18s | %-6s\n" "$action" "$code"
  if [[ "$code" == missing ]] || [[ ! "$code" =~ ^2 ]]; then
    all_2xx=false
  fi
done

echo
echo "[voicebridge-evidence] recent failures/skips:"
rg "postVoiceEvent skipped|postVoiceEvent failed|bridge method unavailable|text is empty|invalid location values" "$TMP_LOG" | tail -n 20 || true

echo
echo "[voicebridge-evidence] raw log saved at: $TMP_LOG"

if [[ "$all_2xx" == true ]]; then
  echo "[voicebridge-evidence] PASS: all 4 actions returned 2xx"
  exit 0
fi

echo "[voicebridge-evidence] FAIL: missing action or non-2xx response"
exit 1
