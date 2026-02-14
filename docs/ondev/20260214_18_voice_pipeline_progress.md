# Status: In Progress

# Voice Pipeline Progress

## Objective
- Phase 13 선행 작업으로 Rails 측 Native Bridge 이벤트 계약/처리 경로 구축

## Completed
1. Voice bridge contract
- `Voice::BridgeMessage`로 허용 액션 검증
- 허용 액션: `start_recording`, `stop_recording`, `transcription`, `location_update`

2. Voice event ingestion API
- `POST /api/voice/events` 엔드포인트 추가
- `Voice::EventProcessor` 연동
- transcription 이벤트 수신 시 세션 메시지로 저장

3. Session native bridge hook
- session 상세 뷰에 `data-native-bridge="voice"` 속성 추가

## Validation
- Voice bridge/API/session hook 테스트 통과 (`P36-T1`, `P36-T2`, `P36-T3`)
- 전체 테스트 통과 (105 tests, 439 assertions)
- 대상 파일 RuboCop 통과

## Next
- Android/iOS 브리지 컴포넌트 구현
- STT/TTS 연동 및 실시간 오디오 스트리밍 경로 구현
