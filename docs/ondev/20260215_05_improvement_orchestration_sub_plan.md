# Status: [In Progress]

# Improvement Orchestration Sub-Plan (2026-02-15)

## Objective
- 코드리뷰 결과를 기반으로 고위험/중위험 개선을 TDD로 실행하고, 남은 개선을 phase 단위로 오케스트레이션한다.

## Scope
- Phase A (Completed): Reliability hardening (`P63-T1~T3`)
- Phase B (Completed): Insight ownership isolation (`P64-T1`)
- Phase C (Completed): UI i18n baseline rollout (`P65-T1~T3`)
- Phase D (Completed): Stimulus unit test expansion (`P66-T1~T3`)
- Phase E (Completed): Android external-gate evidence collector bootstrap (`P67-T1~T3`)
- Phase F (Completed): Core UX Motion - Project_B 스타일 별 입자 집합/확산/구형 재집합 (`P69-T1~T3`)
- Phase G (Completed): Core UX Motion/Android OAuth stabilization (`P70-T1~T3`)
- Phase H (Completed): Subscription consumer UX + validate error-path hardening (`P71-T1~T3`)
- Phase I (Completed): InCar frontend design overhaul (`P72-T1~T3`)
- Phase J (Completed): Local-first Hotwire Native workflow enablement (`P73-T1~T3`)
- Phase K (Completed): Production hardening follow-up (`P74-T3~T4`)
- Phase L (In Progress): RevenueCat production validation follow-up (`P76-T1~T3`)

## Active Phase Pointer
- Current In Progress phase: `Phase L`
- Current next unchecked test item: `P76-T3b`

## TDD Checkpoints
- Red
  - 각 phase의 실패 테스트를 먼저 추가
- Green
  - 최소 코드로 테스트 통과
- Refactor
  - 구조 정리(동작 불변) 후 회귀 확인

## Implementation Steps
1. Phase A - Reliability hardening (Done)
- `test/integration/session_creation_flow_test.rb`: VoiceChatData 초기화 실패 시 세션 롤백 테스트 추가
- `app/controllers/sessions_controller.rb`: create 트랜잭션 + 실패 시 alert redirect
- `test/integration/settings_flow_test.rb`: invalid JSON 입력 보존 테스트 추가
- `app/controllers/settings_controller.rb`: invalid JSON 저장 중단 + alert 처리
- `test/integration/sessions_flow_test.rb`: message submit default label metadata 테스트 추가
- `app/javascript/controllers/message_form_controller.js`: 복구 라벨 메타데이터 기반 처리
- `app/views/sessions/show.html.erb`: `data-default-label` 추가

2. Phase B - Insight ownership isolation (Done)
- `Insight` 소유키 설계 (`user_id` 또는 `session_id`) 및 마이그레이션
- `InsightsController#index/show` 사용자 소유 스코프 강제
- 세션 화면 최근 인사이트도 사용자 스코프로 제한
- cross-user 접근 차단 통합 테스트 추가

3. Phase C - i18n baseline rollout (Done)
- `config/locales/ko.yml`, `config/locales/en.yml` 키 구조 정의
- Home/Sessions/Insights/Settings/Subscription + 공통 네비 주요 문자열 `t()` 치환
- flash/controller 메시지 키 기반 전환
- locale 회귀 테스트 추가

4. Phase D - Stimulus unit test expansion (Done)
- Node built-in test runner 경로(`npm run test:js`) 추가
- importmap 환경 대응을 위한 `@hotwired/stimulus` loader/mock 구성
- `message_form`, `settings_form`, `native_bridge` 단위 테스트 추가 (총 10 tests)

5. Phase E - Android external-gate evidence collector bootstrap (Done)
- 실기기 로그 자동집계 스크립트 추가: `script/mobile/collect_voicebridge_evidence.sh`
- 체크리스트 문서에 자동집계 스크립트 실행 경로/출력 포맷 연동
- 스모크 실행으로 스크립트 동작 확인(액션 미수행 상태에서 expected fail)

6. Phase F - Core UX Motion (Done)
- Project_B 스타일 모션 스펙 추출: 별 입자 집합 -> 확산 -> 구형 재집합 루프
- 구현 후보: Canvas 2D 우선(모바일 저전력), 필요시 WebGL fallback
- 상태 연동: `opener`/phase 전이에 맞춰 particle count, speed, radius 감쇠 파라미터 적용
- 수용 기준: 모바일 실기기에서 프레임 저하 없이(체감 stutter 없음) 30초 루프 재생, 접근성/저전력 모드 fallback 제공

7. Phase G - Core UX Motion/Android OAuth stabilization (Done)
- `test/javascript/controllers/particle_orb_controller_test.mjs`
  - 라벨 포함 감정 문자열 파싱(`extractFirstNumber`) Red/Green
  - phase별 시각 팔레트(`phaseVisualStyle`) 가시성 기준 테스트 추가
- `app/javascript/controllers/particle_orb_controller.js`
  - `readPhaseBadge` 파싱 강건화(숫자 추출)
  - phase별 배경/halo/core 팔레트 분기 적용
- `app/assets/stylesheets/application.css`
  - orb fallback texture + mobile safe-area padding + debug panel action layout 정리
- `mobile/android/app/src/main/java/io/soletalk/mobile/MainActivity.kt`
  - deep-link intent 수신 시 `shouldReloadAfterOauth=false` 설정으로 onResume fallback reload 경합 제거
- 검증:
  - `npm run test:js` 통과
  - `PARALLEL_WORKERS=1 bundle exec rails test` 통과
  - `cd mobile/android && GRADLE_USER_HOME=/Users/peter/Project/Project_A/.gradle-home ./gradlew assembleDebug` 통과

8. Phase H - Subscription consumer UX + validate error-path hardening (Done)
- `test/integration/subscription_flow_test.rb`
  - `P71-T1` free paywall 안내/복원 섹션 노출
  - `P71-T2` RevenueCat ID 누락 시 alert 경로
  - `P71-T3` 저장된 ID 재사용 검증 경로
- `app/views/subscription/show.html.erb`
  - free 사용자용 plan value list + restore form 섹션 분리
- `app/controllers/subscription_controller.rb`
  - validate 결과(`success/error`) 기반 notice/alert 분기
- `config/locales/en.yml`, `config/locales/ko.yml`
  - 구독 화면 copy/에러 플래시 키 추가
- `app/assets/stylesheets/application.css`
  - 구독 plan list 스타일 추가
- 검증:
  - `PARALLEL_WORKERS=1 bundle exec rails test test/integration/subscription_flow_test.rb`
  - `PARALLEL_WORKERS=1 bundle exec rails test`
  - `npm run test:js`
  - `bundle exec rubocop app/controllers/subscription_controller.rb test/integration/subscription_flow_test.rb`

9. Phase I - InCar frontend design overhaul (Done)
- 기준 참조: `ref_UI/Project_A_02_InCar.zip` + 기존 Project_B 모션 의도
- Red:
  - `test/integration/home_flow_test.rb`
    - `P72-T1` app shell + glass nav
    - `P72-T2` home orb stage class
  - `test/integration/sessions_flow_test.rb`
    - `P72-T3` session conversation stack class
- Green:
  - `app/views/layouts/application.html.erb`에 `app-shell`, `incar-*` 배경 레이어 추가
  - `app/views/shared/_top_nav.html.erb`에 `glass-nav` 클래스 적용
  - `app/views/home/index.html.erb` orb hero class 확장
  - `app/views/sessions/show.html.erb` messages 영역에 `conversation-stack` 적용
  - `app/assets/stylesheets/application.css`를 InCar dark aurora + glass surface 중심으로 전면 재정의
  - `app/javascript/controllers/particle_orb_controller.js` phase 팔레트 블루/퍼플 계열 정렬
- 검증:
  - `PARALLEL_WORKERS=1 bundle exec rails test test/integration/home_flow_test.rb test/integration/sessions_flow_test.rb`
  - `PARALLEL_WORKERS=1 bundle exec rails test`
  - `npm run test:js`

10. Phase J - Local-first Hotwire Native workflow enablement (Done)
- `test/integration/dev_sign_in_flow_test.rb`
  - `P73-T1` dev sign-in route creates local session
  - `P73-T2` dev sign-out route clears session
- `config/routes.rb`
  - development/test 한정 `POST /dev/sign_in`, `DELETE /dev/sign_out`
- `app/controllers/dev/sessions_controller.rb`
  - 로컬 테스트용 사용자 세션 생성/해제
- `app/views/home/index.html.erb`
  - guest 화면에 `Quick Dev Sign In` 버튼 추가(dev/test 한정)
- `mobile/android/app/build.gradle.kts`
  - debug/release별 `BuildConfig.WEB_BASE_URL` 분리
  - `SOLETALK_DEBUG_BASE_URL` gradle property 지원
  - `buildFeatures.buildConfig = true`
- `mobile/android/app/src/main/java/io/soletalk/mobile/MainActivity.kt`
  - `BuildConfig.WEB_BASE_URL` 기반 base URL/host 판별로 로컬/운영 공용 처리
  - 로컬(http)에서는 external OAuth 강제 핸드오프 비활성화
- `script/mobile/start_local_ui_workflow.sh`
  - adb reverse + local debug install 자동화
- 검증:
  - `PARALLEL_WORKERS=1 bundle exec rails test test/integration/dev_sign_in_flow_test.rb test/integration/home_flow_test.rb`
  - `PARALLEL_WORKERS=1 bundle exec rails test`
  - `npm run test:js`
  - `cd mobile/android && ./gradlew -PSOLETALK_DEBUG_BASE_URL=http://127.0.0.1:3000/ assembleDebug`

11. Phase K - Production hardening follow-up (Done)
- Red:
  - `test/integration/subscription_flow_test.rb`
    - `P74-T3` CSRF invalid 경로가 500으로 귀결되지 않도록 실패 테스트 추가
- Green:
  - `app/controllers/application_controller.rb`
    - `ActionController::InvalidAuthenticityToken` 별도 처리(422 또는 안전 redirect) 추가
  - 필요 시 `SubscriptionController`/관련 에러 플래시 키 보완
- Refactor:
  - 전역 예외 처리 경계(`StandardError` vs CSRF/권한/레코드 예외) 책임 분리
- Production validation:
  - `P74-T4` Railway smoke로 `/subscription/validate` non-500 확인 + 로그 증적 기록

12. Phase L - RevenueCat production validation follow-up (In Progress)
- `P76-T1` Railway 변수 존재 여부 점검 완료: `REVENUECAT_BASE_URL`, `REVENUECAT_API_KEY` 미설정 확인
- `P76-T2a` Railway `REVENUECAT_BASE_URL=https://api.revenuecat.com` 주입 완료 (deployment `5e42c1ad-a4d9-40e2-8a99-1443f410e2c7`)
- `P76-T2b` Railway `REVENUECAT_API_KEY` 운영값 주입 완료 (deployment `f5384e97-058d-417b-8a15-cdb4c8f41660`)
- `P76-T3a` 운영 서버측 smoke 완료 (`railway run`):
  - `Subscription::RevenueCatClient.new` -> `client_init=ok`
  - `Subscription::SyncService.new.call(user: temp_user)` -> `sync_success=true`, `user_subscription_status=free`
- `P76-T3b` 로그인 사용자 기준 validate/restore 플로우 운영 smoke 증적 확보 (수동 인증 필요)

## Sequential vs Parallel Matrix
| Phase | Depends On | Parallel Feasibility | Decision |
|---|---|---|---|
| A (P63) | 없음 | High | 완료 |
| B (P64) | A 후속 권장 | Medium (파일 충돌 가능) | **순차 실행 완료** |
| C (i18n) | B와 논리 독립 | Medium-High (별도 브랜치면 병렬 가능) | 단일 워크트리 기준 순차 실행 완료 |
| D (Stimulus tests) | C와 논리 독립 | High | 단일 워크트리 기준 순차 실행 완료 |
| E (Android evidence collector) | Rails 코드와 독립 | High | 단일 워크트리 기준 순차 실행 완료 |
| F (Core UX Motion) | E 외부 게이트 후 권장 | Medium | 순차 실행 완료 |
| G (Motion/OAuth stabilization) | F 후속 안정화 | High (JS/Android 병렬 가능) | JS/CSS/Android 순차 실행 완료 |
| H (Subscription UX hardening) | G 후속 UX 연계 | High | 순차 실행 완료 |
| I (InCar frontend overhaul) | H 후속 UI 리뉴얼 | High | 순차 실행 완료 |
| J (Local-first mobile workflow) | I 후속 개발 생산성 | High | 순차 실행 완료 |
| K (Production hardening follow-up) | J 이후 운영 안정화 | Medium (코드 수정은 순차, smoke 검증은 병렬 가능) | 순차 실행 완료 |
| L (RevenueCat production validation) | K 완료 후 운영 구독 검증 | Medium (ENV 확인/사용자 E2E는 부분 병렬 가능) | **진행 중** |
| External Gates (Android evidence/App Store) | Rails 코드와 독립 | High | 병렬 추적 가능 |

## Validation
- Phase A/B/C/D/E 실행 검증:
```bash
PARALLEL_WORKERS=1 bundle exec rails test test/integration/session_creation_flow_test.rb test/integration/settings_flow_test.rb test/integration/sessions_flow_test.rb
PARALLEL_WORKERS=1 bundle exec rails test test/integration/i18n_flow_test.rb test/integration/insights_flow_test.rb
npm run test:js
TIMEOUT_SECONDS=5 script/mobile/collect_voicebridge_evidence.sh   # 스크립트 동작 smoke (expected fail if no manual actions)
PARALLEL_WORKERS=1 bundle exec rails test
RUBOCOP_CACHE_ROOT=/Users/peter/Project/Project_A/.rubocop-cache bundle exec rubocop app/controllers/application_controller.rb app/controllers/auth/omniauth_callbacks_controller.rb app/controllers/messages_controller.rb app/controllers/settings_controller.rb app/controllers/sessions_controller.rb app/controllers/subscription_controller.rb test/integration/i18n_flow_test.rb config/application.rb
bundle exec brakeman -q -w2
```
- Pass 조건: 신규/회귀 테스트 green, 보안 경고 증가 없음

## Session-End Update
- Completed:
  - `P63-T1`, `P63-T2`, `P63-T3` 구현 및 테스트 통과
  - `P64-T1` Insight ownership hardening + 마이그레이션/스코프/회귀 테스트 통과
  - `P65-T1`, `P65-T2`, `P65-T3` locale baseline + 화면/flash i18n + 회귀 테스트 통과
  - `P66-T1`, `P66-T2`, `P66-T3` Stimulus 단위 테스트 인프라/케이스/게이트 통과
  - `P67-T1`, `P67-T2`, `P67-T3` Android 외부 게이트 증적 자동집계 스크립트/문서/스모크 검증 완료
  - `P68-T1`, `P68-T2`, `P68-T3` OAuth handoff(start endpoint/deep link/mobile_handoff) 구현 및 실기기 검증 완료
  - `P69-T1`, `P69-T2`, `P69-T3` Core UX Motion(별 입자 모션 + 성능 가드레일 + 세션 phase 연동) 완료
  - `P70-T1`, `P70-T2`, `P70-T3` Motion 파싱/가시성 튜닝 + Android OAuth deep-link reload race 수정 완료
  - `P71-T1`, `P71-T2`, `P71-T3` Subscription 소비자 UX + validate 에러/재사용 경로 하드닝 완료
  - `P72-T1`, `P72-T2`, `P72-T3` InCar 레퍼런스 기반 전역 UI 리뉴얼 + 모션 팔레트 정렬 완료
  - `P73-T1`, `P73-T2`, `P73-T3` 로컬-우선 Android/Hotwire Native 워크플로우 완성
  - `P74-T1`, `P74-T2`, `P74-T3`, `P74-T4` 구독 설정 누락/ActionCable adapter/CSRF 500 방어/운영 smoke 반영
  - `plan.md`에 신규 항목/큐 반영
  - GAP 분석 문서 신규 작성 (`20260215_04`)
- Pending:
  - `P76-T3b` 로그인 사용자 기준 validate/restore 운영 smoke 증적
  - App Store/운영 외부 게이트(수동)
- Mismatch:
  - Sub-plan 상태가 `Done`으로 남아있어 현재 운영 하드닝 작업을 반영하지 못했던 문제를 `In Progress`로 교정
- Next Test:
  - `P76-T3b` 로그인 사용자 기준 `/subscription/validate` validate/restore smoke 증적 캡처
