# Status: [In Progress]

# Android AudioBridge Component Progress

## Objective
- `AudioBridgeComponent` baseline(JS ↔ Native)을 Android-first 트랙에서 먼저 완료
- 범위: `startRecording`, `stopRecording`, `onTranscription`, `playAudio`, `requestCurrentLocation` 호출 경로 고정

## TDD
1. Red
- 세션 화면에 Native Bridge 컨트롤이 없던 상태에서 통합 테스트(`P60-T1`, `P60-T2`) 추가

2. Green
- `sessions/show`에 Native Bridge 테스트 패널 추가
- `native_bridge_controller`로 브리지 메서드 호출/상태 표시 연결
- Android `VoiceBridge`에 `playAudio`(TTS) 추가, `MainActivity` 권한 요청 추가
- Android `SpeechRecognizer` baseline 연결(start/stop 시 STT 결과를 `transcription` 이벤트로 전송)
- `requestCurrentLocation` 추가(GPS + Open-Meteo 기반 weather 요약으로 `location_update`)

3. Refactor
- 브리지 호출 가드(`ensureBridge`)로 메서드 누락 시 실패 메시지 표준화
- 입력 validation(빈 문자열/잘못된 좌표) 공통 처리

## Validation
- Rails:
  - `mise exec -- bundle exec rails test test/integration/sessions_flow_test.rb` 통과
  - 결과: 8 runs, 52 assertions, 0 failures
- Android:
  - `GRADLE_USER_HOME=/Users/peter/Project/Project_A/.gradle-home ./gradlew assembleDebug` 통과
  - `adb install -r app-debug.apk` 성공
  - `adb shell am start -W -n io.soletalk.mobile/.MainActivity` 실행 확인

## Remaining
- 실기기 로그 증적 수집(외부 게이트): 브리지 이벤트 4종 전송 후 `adb logcat` 2xx 캡처
- Gemini Live STT 스트리밍 연동
- Gemini Live 양방향 오디오 스트리밍 연동
