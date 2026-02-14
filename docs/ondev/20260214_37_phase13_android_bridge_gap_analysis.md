# Status: [In Progress]

# Phase 13 Android Bridge - Gap Analysis

## Scope
- 기준: `docs/ondev/20260214_32_phase13_android_first_execution_plan.md`
- 대상: Android Audio/Location bridge baseline + Rails contract 정합성

## Gap Table

| Category | Gap | Status | Priority | Action |
|---|---|---|---|---|
| e2e | 실기기에서 브리지 이벤트 4종 전송 후 Rails 저장 증적 부재 (`P57-T3`) | Open | High | 디바이스에서 세션 진입 후 패널 액션 실행, 서버측 저장 확인 로그 수집 |
| auth | Android Google Sign-In SDK 연동 미완 | Open | High | `id_token` 발급 후 `POST /api/auth/google/native_sign_in` 연결 |
| stt | Gemini Live STT 미연동 (현재 SpeechRecognizer baseline) | Open | High | Gemini Live websocket/streaming 연결 및 latency 측정 |
| audio | Gemini Live 양방향 오디오 스트리밍 미연동 | Open | High | 오디오 업링크/다운링크 경로 구축 |
| quality | STT partial/final 중복 전송 가능 | Open | Medium | dedupe key(문장+시간창) 적용 |

## Closed Gaps
- Android AudioBridge baseline(JS↔Native start/stop/transcription/playAudio) 구현 완료
- Android LocationBridge baseline(GPS + Open-Meteo weather) 구현 완료
- 세션 화면 Native Bridge 테스트 패널 + Stimulus controller 구축 완료
- `VoiceBridge` action별 응답 로깅 + `P57-T3` 체크리스트 문서(`20260214_38`) 추가 완료

## Next
1. `P57-T3` 실기기 E2E 증적 수집
2. Google Sign-In SDK 연동으로 인증 경로 고정
3. Gemini Live STT/Audio 단계 진입
