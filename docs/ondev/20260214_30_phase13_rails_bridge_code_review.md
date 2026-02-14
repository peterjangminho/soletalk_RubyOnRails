# Status: Done

# Phase 13 Rails Bridge Hardening - Code Review

## Findings (severity order)

1. Medium - Request-level `google_sub` 인증은 위변조 방어가 약함
- Files: `app/controllers/api/voice/events_controller.rb`
- Detail: 비로그인 요청에서도 `google_sub` 문자열 일치만으로 접근이 허용되어, 서명/토큰 기반 검증 대비 보안 강도가 낮음.
- Impact: 모바일 공개 API로 노출 시 세션 ID 추측 + `google_sub` 스푸핑 조합 리스크가 남음.
- Recommendation: signed token(HMAC/JWT) 또는 app-issued short-lived token으로 대체.

2. Low - (Resolved) `location_update` 좌표 범위 검증 부재
- Files: `app/services/voice/event_processor.rb`
- Detail: 초기 리뷰 시 제기된 좌표 범위 검증 누락은 후속 수정(`P56-T1`)으로 해소됨.
- Result: `latitude(-90..90)`, `longitude(-180..180)` 범위 검증 추가 완료.

## TDD / Principle Check
- Red -> Green -> Refactor 순서 준수:
  - Red: `test/services/voice/event_processor_test.rb` 및 controller/integration 확장 후 실패 확인
  - Green: 액션별 처리/권한가드 최소 구현으로 통과
  - Refactor: 공통 로직을 `EventProcessor` 내부 private 메서드로 정리
- Vibe Coding 6원칙 점검:
  - Pattern consistency: Controller-Service 분리 유지
  - One source of truth: 액션 검증은 `Voice::BridgeMessage::ALLOWED_ACTIONS` 사용
  - No hardcoding: 주요 에러코드/액션은 분기 일관 유지 (단, 상수화 추가 여지는 있음)
  - Happy/Error path: success + forbidden + invalid payload 경로 모두 테스트
  - SRP: 이벤트 처리 로직은 service에서 수행
  - Shared reuse: voice 이벤트 공통 처리 경로 재사용

## Phase E2E Validation
- Command:
  - `PARALLEL_WORKERS=1 bundle exec rails test test/services/voice/event_processor_test.rb test/controllers/api/voice/events_controller_test.rb test/integration/e2e_voicechat_flow_test.rb test/integration/e2e_error_flow_test.rb`
  - `PARALLEL_WORKERS=1 bundle exec rails test`
- Result: PASS
  - Targeted: 14 runs, 51 assertions, 0 failures
  - Full: 138 runs, 605 assertions, 0 failures

## Verdict
- Review Verdict: PASS (non-blocking medium/low residual risks documented)
