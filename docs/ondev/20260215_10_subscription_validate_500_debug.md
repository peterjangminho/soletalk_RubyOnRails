# Status: [Done]

# Subscription Validate 500 Debug Master Note (2026-02-15)

## Bug Report
- Expected: `/subscription/validate` 비정상 요청(CSRF invalid, unauth direct POST)도 500이 아닌 제어된 응답이어야 함.
- Actual: production direct POST smoke에서 `500` 확인.
- Scope: web HTML POST error handling (`ApplicationController` 전역 예외 처리 경계).
- Impact: 운영 신뢰성 저하, 관측 시 내부 오류로 오인될 수 있음.

## Reproduction
```bash
curl -sS -m 15 -o /dev/null -w "%{http_code}\n" -X POST https://soletalk-rails-production.up.railway.app/subscription/validate
```
- Observed: `500`

## Suspicious Areas
- `app/controllers/application_controller.rb`
  - `rescue_from StandardError, with: :render_internal_error`
  - `render_internal_error`가 HTML 요청에서 production 시 무조건 500으로 귀결
- `SubscriptionController#validate`
  - 정상 경로/RevenueCat 설정 누락 경로는 처리되지만 CSRF 단계 예외는 컨트롤러 액션 이전에 발생 가능

## Hypotheses
1. CSRF 예외(`ActionController::InvalidAuthenticityToken`)가 `StandardError`에 포획되어 500으로 승격된다.
2. production middleware/exception 앱 레이어에서 예외 변환이 누락되어 422 대신 500이 된다.
3. `/subscription/validate` 라우팅 경로에서 format/forgery 처리 정책이 기대와 다르게 적용된다.

## Plan (TDD)
1. Red: CSRF invalid 경로를 non-500으로 고정하는 테스트 추가 (`P74-T3`). ✅
2. Green: `InvalidAuthenticityToken` 전용 rescue 추가(422 응답) + 최소 수정. ✅
3. Refactor: 전역 예외 처리 경계 정리 및 테스트 회귀. ✅
4. Production verify (`P74-T4`): Railway smoke + 로그 증적 기록. ✅

## Evidence Log
- 2026-02-15: local regressions green (`rails test`, `npm run test:js`).
- 2026-02-15: Railway deployment `986b8c1d-7152-407a-b83e-19f0ec8a70d9` 확인.
- 2026-02-15: `/subscription/validate` direct POST returns `500`.
- 2026-02-15: `P74-T3` 구현 완료 (`ApplicationController` CSRF 예외 전용 처리 + integration tests green).
- 2026-02-15: Railway deployment `7bf4d706-ac1a-483a-824e-46b4f68e8fae` SUCCESS.
- 2026-02-15: production smoke 재확인 결과 `/subscription/validate` direct POST `422` (`invalid authenticity token`).
- 2026-02-15: Railway runtime log에서 `rescue_from handled ActionController::InvalidAuthenticityToken` 확인.
