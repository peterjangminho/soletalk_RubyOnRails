# Status: Done

# Voice Pipeline Progress

## Objective
- Phase 13 중 Rails 저장소 범위의 Native Bridge 이벤트 계약/처리 경로를 운영 기준으로 고도화

## Completed
1. Voice bridge contract
- `Voice::BridgeMessage`로 허용 액션 검증
- 허용 액션: `start_recording`, `stop_recording`, `transcription`, `location_update`

2. Voice event ingestion API
- `POST /api/voice/events` 엔드포인트 추가
- `Voice::EventProcessor` 연동
- transcription 이벤트 수신 시 세션 메시지로 저장

3. Event action hardening
- `start_recording`, `stop_recording`, `location_update` 액션 처리 추가
- `VoiceChatData.metadata`에 녹음 상태/위치 정보 저장
- location payload validation (`invalid_location_payload`) 추가

4. Ownership/auth guard
- `POST /api/voice/events`에 세션 소유권 확인 가드 추가
- 허용 조건: 로그인 `current_user` 소유 세션 또는 `google_sub` 일치
- 불일치 시 `403 forbidden` 반환

5. Session native bridge hook
- session 상세 뷰에 `data-native-bridge="voice"` 속성 추가

## Validation
- Voice bridge/API/session hook 테스트 통과 (`P36-T1`, `P36-T2`, `P36-T3`)
- Voice hardening 테스트 통과 (`P55-T1`, `P55-T2`, `P55-T3`)
- 전체 테스트 통과 (138 tests, 605 assertions, `PARALLEL_WORKERS=1`)
- 대상 파일 RuboCop 통과

## Next
- 모바일 외부 트랙으로 이관:
  - Android/iOS 브리지 컴포넌트 구현
  - STT/TTS 연동 및 실시간 오디오 스트리밍 경로 구현
