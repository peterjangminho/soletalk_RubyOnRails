# Status: In Progress

# Android Local Bootstrap Progress

## Objective
- 별도 Android 리포 없이 Project_A 내부에서 Android PoC 시작점을 만든다.

## Completed
1. Local project path
- `mobile/android` 생성

2. Android skeleton
- Gradle Kotlin DSL 기본 파일 추가
- `MainActivity` + `WebView` 구성
- `VoiceBridge` JS interface 구성

3. Rails contract wiring
- Bridge 이벤트를 `POST /api/voice/events`로 전송하는 스켈레톤 추가
- 이벤트 액션: `start_recording`, `stop_recording`, `transcription`, `location_update`

4. Developer guide
- `mobile/android/README.md`에 실행/브리지 호출 방법 명시

5. Rails-WebView bridge bootstrap
- `sessions/show`에서 Android 브리지 객체 존재 시 `setSession(session_id, google_sub)` 자동 호출
- 브리지 주입 스크립트 노출 통합 테스트 통과 (`test/integration/sessions_flow_test.rb`)

6. Signed bridge token wiring
- `sessions/show`에서 `setSession(session_id, google_sub, bridge_token)`로 주입 확장
- Android `VoiceBridge`가 `bridge_token`을 `/api/voice/events` 요청에 포함하도록 확장

## Pending
- Android Studio sync/build 확인
- Google Sign-In SDK 연결 후 `id_token` 발급 및 `POST /api/auth/google/native_sign_in` 연동
- 실기기 E2E(`start -> transcription -> stop -> location`) 증적 확보

## Next
- P57-T3 Android Bridge 계약 E2E 검증
