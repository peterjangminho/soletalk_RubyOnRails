# Status: [In Progress]

# Codebase Review GAP Analysis (2026-02-15)

## Review Skills Used
- `code-review-skill`: severity-ordered risk review + phase E2E gate
- `code-review-checklist`: 기능/보안/성능/테스트 체크리스트 검증

## Scope
- Target code: UI/UX hardening changes + related controllers/stimulus/integration tests
- Evidence: `git diff`, integration/full test run, RuboCop, Brakeman

## Validation Evidence
- `PARALLEL_WORKERS=1 bundle exec rails test` -> 161 runs, 718 assertions, 0 failures
- `PARALLEL_WORKERS=1 bundle exec rails test test/integration` -> 58 runs, 348 assertions, 0 failures
- `bundle exec brakeman -q -w2` -> 0 warnings
- `RUBOCOP_CACHE_ROOT=/Users/peter/Project/Project_A/.rubocop-cache bundle exec rubocop <changed ruby tests/controllers>` -> no offenses

## GAP Table (Planned vs Actual vs Risk)

| Category | Gap | Status | Priority | Action |
|---|---|---|---|---|
| quality | `POST /sessions` 생성 플로우가 비원자적(Session 성공 + VoiceChatData 실패 가능) | Closed | Medium | 트랜잭션 + 실패 시 롤백/alert 적용 (`P63-T1`) |
| quality | `PATCH /setting` invalid JSON 입력 시 preferences를 `{}`로 덮어쓰는 데이터 손실 경로 | Closed | Medium | invalid 입력 감지 시 저장 중단 + alert + 기존 값 보존 (`P63-T2`) |
| quality | message form submit 라벨 복구값 하드코딩(`Send`) | Closed | Low | `data-default-label` 기반 복구로 하드코딩 제거 (`P63-T3`) |
| feature/security | Insight가 사용자 소유 스코프 없이 전역 조회(`Insight.order`, `Insight.find`) | Closed | High | `P64-T1` 완료: `insights.user_id` 소유 모델 + controller/user scope 강제 + cross-user 접근 차단 테스트 통과 |
| feature | UI 문자열 i18n 키 기반 전면 치환 미완 | Closed | Medium | `P65-T1~T3` 완료: locale 선택 로직 + 핵심 화면/flash 문구 `en/ko` 치환 + i18n 회귀 테스트 통과 |
| test | Stimulus 컨트롤러 단위 테스트 부재 | Closed | Low | `P66-T1~T3` 완료: Node test runner + loader/mock + 3개 컨트롤러 단위 테스트(10 assertions) |
| quality/reliability | 전역 `rescue_from StandardError`가 CSRF 예외를 500으로 처리하여 `/subscription/validate` 외부 POST가 500으로 노출 | Closed | High | `P74-T3` 완료: CSRF 예외 전용 422 처리 + 회귀 테스트 추가 |
| ops | Railway 운영에서 `/subscription/validate` 직접 POST smoke가 500 응답 | Closed | High | `P74-T4` 완료: 배포 후 direct POST `422` + 로그에서 CSRF 전용 처리 확인 |
| ops | 로그인 사용자 기준 운영 validate/restore E2E 증적 미확보 | Open | High | `P76-T2a`, `P76-T2b`, `P76-T3a` 완료(ENV/서버 smoke), `P76-T3b` 수동 인증 smoke만 잔여 |

## Major Root Causes
1. 초기 구현이 기능 연결 중심으로 빠르게 진행되며 error-path 데이터 보존 규칙이 일부 누락됨
2. Insight 도메인 모델이 사용자 소유 관계 없이 시작되어 접근 제어가 controller 레벨에서 강제 불가
3. i18n 전환을 위한 locale/key 체계 작업이 별도 사이클로 밀림
4. 전역 예외 처리 경계가 넓어(CSRF/권한/입력 오류 포함) 웹 요청 오류가 500으로 승격됨

## Minimal Next Action Plan
1. `external-gate` - App Store/운영 트랙 수동 게이트 진행
- Owner: Mobile/Ops
- Verify: `docs/ondev/20260214_25_app_store_prep_checklist.md` Remaining 항목 소거

2. `ux-polish` - Core Motion 시각 튜닝(입자 팔레트/파싱 강건화/fallback texture) 및 Android OAuth 복귀 race 안정화
- Owner: Frontend/Mobile
- Status: Closed (`P70-T1~T3`)
- Verify:
  - `test/javascript/controllers/particle_orb_controller_test.mjs`
  - `mobile/android/.../MainActivity.kt` deep-link intent race fix
  - `npm run test:js`, `bundle exec rails test`, `assembleDebug` green

3. `feature` - 소비자용 Subscription UX 고도화
- Owner: Subscription
- Status: Closed (`P71-T1~T3`)
- Verify:
  - `test/integration/subscription_flow_test.rb` 신규 3건 green
  - `SubscriptionController#validate` success/error 분기
  - paywall UI에서 plan value 요약 + restore 섹션 분리

4. `external-gate` - App Store/운영 수동 트랙 최종 소거
- Owner: Mobile/Ops
- Verify: `docs/ondev/20260214_25_app_store_prep_checklist.md` Remaining 제거

5. `feature` - InCar UI 리뉴얼(Project_A_02_InCar 레퍼런스)
- Owner: Frontend
- Status: Closed (`P72-T1~T3`)
- Verify:
  - `test/integration/home_flow_test.rb`, `test/integration/sessions_flow_test.rb` 신규 UI 계약 테스트 green
  - `application.css` dark aurora/glass shell 테마 반영
  - `particle_orb_controller.js` 파티클 팔레트 블루/퍼플 정렬

6. `reliability` - `/subscription/validate` CSRF invalid 500 제거
- Owner: Backend
- Status: Closed (`P74-T3`)
- Verify:
  - `test/integration/subscription_flow_test.rb` 또는 동등 API/flow test로 non-500 보장
  - `ApplicationController`에서 `InvalidAuthenticityToken`을 전용 처리

7. `ops` - Subscription validate 운영 smoke 및 ENV 정합성 검증
- Owner: Ops/Backend
- Status: Closed (`P74-T4`)
- Verify:
  - 운영 `/subscription/validate` 직접 POST smoke가 `422` (non-500)
  - Railway 로그에서 `InvalidAuthenticityToken` 전용 처리 확인

8. `ops` - RevenueCat 운영 ENV 및 로그인 사용자 restore/validate E2E
- Owner: Ops/Backend
- Status: Open (`P76-T3b`)
- Verify:
  - `P76-T1` 완료: Railway variables에서 `REVENUECAT_*` 미설정 확인
  - `P76-T2a` 완료: `REVENUECAT_BASE_URL=https://api.revenuecat.com` 주입
  - `P76-T2b` 완료: `REVENUECAT_API_KEY` 변수 주입
  - `P76-T3a` 완료: 운영 컨테이너에서 `RevenueCatClient`/`SyncService` smoke 성공
  - 로그인 사용자 기준 `/subscription/validate` restore/validate 흐름 증적 확보 (`P76-T3b`)

9. `workflow` - 로컬-우선 모바일 개발 루프
- Owner: Mobile/Frontend
- Status: Closed (`P73-T1~T3`)
- Verify:
  - dev/test 전용 quick sign-in route + integration test green
  - Android debug base URL 분리(`SOLETALK_DEBUG_BASE_URL`)
  - `script/mobile/start_local_ui_workflow.sh`로 adb reverse + installDebug 자동화
