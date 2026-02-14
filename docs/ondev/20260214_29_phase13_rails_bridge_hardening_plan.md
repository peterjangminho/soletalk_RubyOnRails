# Status: [In Progress]

# Phase 13 Rails Bridge Hardening Plan

## Objective
- Hotwire Native 실제 앱 연동 전, Rails 저장소 범위의 Voice Bridge 계약을 운영 안정성 기준으로 강화

## Scope
- `POST /api/voice/events` 액션별 처리 명확화 (`start_recording`, `stop_recording`, `transcription`, `location_update`)
- 액션별 payload validation + error-path 표준화
- 세션 소유권/인증 가드 적용 전략 반영
- 메시지/세션 메타데이터 저장 규칙 고정 및 테스트 보강

## TDD Checkpoints
- Red
  - P55-T1: action별 처리/검증 요구사항 테스트 추가 후 실패 확인
  - P55-T2: 무권한/세션불일치 요청 차단 테스트 추가 후 실패 확인
  - P55-T3: voice 이벤트 E2E(성공 + 실패) 테스트 추가 후 실패 확인
- Green
  - 최소 코드로 각 테스트를 순차 통과
- Refactor
  - 공통 validation/권한 검사/metadata 업데이트 로직을 SRP 기준으로 정리
  - 구조 변경과 동작 변경 커밋 분리(`structural`/`behavioral`)

## Implementation Steps
1. `test/controllers/api/voice/events_controller_test.rb`
- action별 success/failure 케이스 확대
- invalid payload, unknown session, unauthorized access 케이스 추가

2. `test/integration/e2e_voicechat_flow_test.rb` (또는 신규 integration test)
- `start -> transcription -> stop -> location_update` 시나리오 E2E 추가
- 실패 시나리오(`empty_transcription`, invalid action, unauthorized) 추가

3. `app/services/voice/event_processor.rb`
- action별 핸들러 분리 (`process_start_recording`, `process_stop_recording`, `process_location_update`)
- `VoiceChatData.metadata` 업데이트 규칙 추가

4. `app/controllers/api/voice/events_controller.rb` + `app/services/voice/bridge_message.rb`
- 인증/소유권 가드 추가(현재 세션 사용자 기준 또는 서명 토큰 전략)
- validation 실패 시 표준 에러 페이로드 유지

5. 문서 동기화
- `plan.md` P55 상태 업데이트
- `docs/PLAN.md`와 `docs/ondev/20260214_28_phase13_mobile_track_handoff.md` 동기화

## Validation
- `PARALLEL_WORKERS=1 bundle exec rails test test/services/voice test/controllers/api/voice/events_controller_test.rb`
- `PARALLEL_WORKERS=1 bundle exec rails test test/integration/e2e_voicechat_flow_test.rb test/integration/e2e_error_flow_test.rb`
- `PARALLEL_WORKERS=1 bundle exec rails test`
- 성공 조건: 신규/기존 테스트 모두 green, 회귀 없음

## Session-End Update
- Completed: (fill after execution)
- Pending: (fill after execution)
- Mismatch: (fill after execution)
- Next Test: P55-T1
