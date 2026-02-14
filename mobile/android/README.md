# SoleTalk Android (Local Bootstrap)

이 폴더는 Project_A 기준 Android Hotwire Native PoC 시작점입니다.

## Included
- Gradle Kotlin DSL 기본 구조
- WebView 기반 `MainActivity`
- JS Bridge `SoleTalkBridge` (`startRecording`, `stopRecording`, `onTranscription`, `onLocation`, `requestCurrentLocation`, `playAudio`)
- Rails voice event endpoint 연동 스켈레톤 (`/api/voice/events`)

## Quick Start
1. Android Studio에서 `mobile/android` 폴더 열기
2. SDK 35 설치
3. Gradle Sync 실행
4. 실행 후 WebView에서 Railway URL 로드 확인

## Bridge Contract (JS -> Android)
```javascript
window.SoleTalkBridge.setSession(sessionId, googleSub)
window.SoleTalkBridge.setSession(sessionId, googleSub, bridgeToken)
window.SoleTalkBridge.startRecording()
window.SoleTalkBridge.onTranscription("text from stt")
window.SoleTalkBridge.stopRecording()
window.SoleTalkBridge.onLocation(37.5, 127.0, "clear")
window.SoleTalkBridge.requestCurrentLocation()
window.SoleTalkBridge.playAudio("안내 음성을 재생합니다.")
```

`requestCurrentLocation()`은 GPS 좌표를 읽고 Open-Meteo에서 현재 weather code를 조회해 `location_update` payload의 `weather`에 반영합니다.

## Next
- Android Google Sign-In SDK 붙여서 `id_token` 발급
- Rails `POST /api/auth/google/native_sign_in` 연동
- 실기기 E2E: start -> transcription -> stop -> location
