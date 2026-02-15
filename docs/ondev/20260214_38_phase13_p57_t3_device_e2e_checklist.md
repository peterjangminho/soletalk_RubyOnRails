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
