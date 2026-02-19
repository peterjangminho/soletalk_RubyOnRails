# Status: [In Progress]

# Phase 13 P57-T3 Device E2E Checklist

## Goal
- Android 실기기에서 브리지 이벤트 4종(`start_recording`, `transcription`, `stop_recording`, `location_update`)이 서버 응답 2xx로 왕복되는 증적 확보

## Preconditions
1. Android app debug build 설치 완료
2. 앱에서 세션 화면 진입(`data-native-bridge="voice"` 페이지)
3. `setSession(session_id, google_sub, bridge_token)` 주입 확인

## Execution Steps
1. 로그 수집 시작
```bash
adb logcat -s VoiceBridge
```

자동 집계 스크립트(권장):
```bash
script/mobile/collect_voicebridge_evidence.sh
```
- 기본 timeout: 180초 (`TIMEOUT_SECONDS=300 script/mobile/collect_voicebridge_evidence.sh`로 조정 가능)
- 성공 조건: 4개 액션 모두 `code=2xx`
- 결과: action/code 요약표 + 실패/skip 로그 + raw log 파일 경로 출력

2. 세션 화면 Native Bridge 패널에서 순서대로 실행
- `Start Recording`
- 말하기(또는 `Send Transcription`)
- `Stop Recording`
- `Request Current Location` 또는 `Send Location`

3. 로그에서 아래 패턴 확인
- `postVoiceEvent action=start_recording code=2xx`
- `postVoiceEvent action=transcription code=2xx`
- `postVoiceEvent action=stop_recording code=2xx`
- `postVoiceEvent action=location_update code=2xx`

## Evidence Format
- 실행 시각(YYYY-MM-DD HH:MM)
- 디바이스 모델/OS
- 위 4개 action별 response code
- 실패 시 response body/error 로그

## Failure Triage
- `postVoiceEvent skipped`: session_id/google_sub 주입 확인
- `code=403`: bridge_token 만료/세션 소유권 불일치 확인
- `requestCurrentLocation: no location available`: 위치 권한/실내 GPS 수신 상태 확인

## Current Debug Snapshot (2026-02-15)
- `adb logcat -d -s MainActivity VoiceBridge AndroidRuntime` 기준:
  - `runtime permissions already granted`
  - `VoiceBridge: TTS initialized successfully`
  - `MainActivity: webview page finished` 확인
  - `AndroidRuntime: VM exiting with result code 0`는 APK 재설치(`adb install -r`)로 기존 프로세스가 종료된 정상 로그
- 즉시 크래시/예외는 재현되지 않았음

## OAuth Debug Snapshot (2026-02-15)
- 재현 로그:
  - `webview page finished: https://accounts.google.com/signin/oauth/error?...authError=...disallowed_useragent...`
- 원인:
  - Google OAuth는 Android WebView user-agent를 보안 정책으로 차단
- 조치:
  - `MainActivity`에서 `/auth/google_oauth2` 및 `accounts.google.com` 요청을 감지해 Custom Tab(외부 브라우저)로 전환
  - 검증 로그: `open external browser for oauth url=https://soletalk-rails-production.up.railway.app/auth/google_oauth2`

## Contract E2E Snapshot (2026-02-15)
- Rails 통합 테스트로 Android bridge token 경로 계약 고정:
  - 테스트: `test/integration/e2e_voicechat_flow_test.rb`
  - 케이스: `P57-T3 E2E android bridge contract accepts token-authenticated start stop transcription location flow`
  - 검증 포인트:
    - `start_recording`/`transcription`/`stop_recording`/`location_update` 순차 200 응답
    - transcription 메시지 저장
    - recording 상태/last_location metadata 저장
- 실행 명령:
```bash
bundle exec rails test test/controllers/api/voice/events_controller_test.rb test/services/voice/event_processor_test.rb test/integration/e2e_voicechat_flow_test.rb
```
- 결과: `13 runs, 54 assertions, 0 failures`

## Device Snapshot (2026-02-15)
- 확인됨:
  - USB 연결 시 디바이스 식별: `SM-S936B (Android 16)`
  - 앱 부팅 로그 확인:
    - `MainActivity: runtime permissions already granted`
    - `VoiceBridge: TTS initialized successfully`
    - `MainActivity: webview page finished: https://soletalk-rails-production.up.railway.app/`
- 미완:
  - 세션 상세(디버그 패널) 진입 전 단계로, `postVoiceEvent action=... code=2xx` 4종 증적 미채집
- 후속:
  - 세션 상세 화면에서 4개 액션 수행 후 `script/mobile/collect_voicebridge_evidence.sh` 결과를 증적으로 보강

## Evidence Snapshot (2026-02-15 18:10)
- 실행 명령:
```bash
TIMEOUT_SECONDS=45 script/mobile/collect_voicebridge_evidence.sh
```
- 디바이스: `SM-S936B`
- 결과 요약:
  - `start_recording` -> `200`
  - `transcription` -> `200`
  - `stop_recording` -> `200`
  - `location_update` -> `200`
- 스크립트 판정:
  - `PASS: all 4 actions returned 2xx`
- raw log:
  - `/tmp/voicebridge_evidence_20260215_181046.log`
