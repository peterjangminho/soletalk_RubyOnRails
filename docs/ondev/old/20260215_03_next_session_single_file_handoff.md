# Status: [Ready]

# Next Session Single-File Handoff (2026-02-15)

## 언제 새 세션 시작하면 되나?
- **지금 바로 시작 가능**.
- 권장 타이밍:
  1. 현재 변경사항 리뷰
  2. 커밋/푸시(원하면)
  3. 이 문서 기준으로 새 세션 시작
- 즉, **이 문서 작성 시점(2026-02-15) 기준으로 즉시 세션 전환해도 컨텍스트 손실 없음**.

## 이 문서만 읽고 시작하는 방법
1. 현재 브랜치/변경 확인:
```bash
git status --short --branch
```
2. 핵심 회귀 확인:
```bash
PARALLEL_WORKERS=1 bundle exec rails test test/integration
```
3. 다음 우선순위 작업 선택:
- A. Android 실기기 로그 증적 게이트 마무리
- B. UI i18n 전면화
- C. 소비자용 Subscription UX 고도화

## 현재 상태 요약
- 브랜치: `main`
- `plan.md` 체크박스: **미체크 항목 0개**
- 최신 완료:
  - `P57-T3` Android bridge 계약 E2E 테스트 고정
  - `P58-T1/T2` iOS deferred + 대체 검증 계획 문서화
  - `P62-T1/T2/T3` UI/UX 하드닝(내비, 플래시, 디버그 분리, 폼 상태 피드백)
- 현재 남은 성격:
  - 저장소 내부 기능 체크리스트는 완료
  - 외부 게이트(실기기 로그 증적, 앱스토어/모바일 트랙) 중심

## 방금 반영된 변경(핵심)
- UX/UI:
  - 공통 내비/플래시: `app/views/shared/_top_nav.html.erb`, `app/views/shared/_flash.html.erb`
  - 레이아웃/브랜딩: `app/views/layouts/application.html.erb`
  - 홈/세션/인사이트/설정/구독 화면 문구·버튼·피드백 개선
  - 스타일 통일: `app/assets/stylesheets/application.css`
  - Stimulus 상호작용 개선:
    - `app/javascript/controllers/message_form_controller.js`
    - `app/javascript/controllers/settings_form_controller.js`
    - `app/javascript/controllers/native_bridge_controller.js`
- 컨트롤러 flash 피드백:
  - `app/controllers/sessions_controller.rb`
  - `app/controllers/messages_controller.rb`
  - `app/controllers/settings_controller.rb`
  - `app/controllers/subscription_controller.rb`
  - `app/controllers/auth/omniauth_callbacks_controller.rb`
- 테스트 추가:
  - `test/integration/home_flow_test.rb` (`UX-T1`)
  - `test/integration/sessions_flow_test.rb` (`UX-T2`)

## 검증 스냅샷
- 통합 테스트:
```bash
PARALLEL_WORKERS=1 bundle exec rails test test/integration
```
- 결과: `51 runs, 306 assertions, 0 failures, 0 errors, 0 skips`
- RuboCop(변경 Ruby 파일):
```bash
RUBOCOP_CACHE_ROOT=/tmp/rubocop_cache bundle exec rubocop app/controllers/auth/omniauth_callbacks_controller.rb app/controllers/messages_controller.rb app/controllers/sessions_controller.rb app/controllers/settings_controller.rb app/controllers/subscription_controller.rb test/integration/home_flow_test.rb test/integration/sessions_flow_test.rb
```
- 결과: no offenses

## 다음 세션 우선순위 (권장 순서)
1. **Android 실기기 증적 게이트 닫기 (외부 게이트)**
- 목표: `start_recording/transcription/stop_recording/location_update` 4종 2xx 로그 캡처
- 실행 체크리스트: `docs/ondev/20260214_38_phase13_p57_t3_device_e2e_checklist.md`
- 완료 기준: 증적 포맷(실행 시각, 디바이스/OS, 4종 response code, 실패 시 body/log) 채움

2. **i18n 전면화 (UI 문자열 ko/en 키화)**
- 기준 갭 문서: `docs/ondev/20260215_02_uiux_inventory_gap_analysis.md`
- 완료 기준: 핵심 화면(Home/Sessions/Insights/Settings/Subscription) 문자열 locale 키로 대체

3. **소비자용 구독 UX 고도화**
- 현재는 RevenueCat ID 검증 중심(운영자/테스터 UX)
- 목표: 소비자 결제/복원 흐름과 안내 문구 강화

## 현재 참조 문서 (우선순위)
1. 마스터 체크리스트: `plan.md`
2. UI/UX 인벤토리+갭: `docs/ondev/20260215_02_uiux_inventory_gap_analysis.md`
3. iOS deferred 계획: `docs/ondev/20260215_01_ios_deferred_validation_plan.md`
4. Android 실기기 체크리스트: `docs/ondev/20260214_38_phase13_p57_t3_device_e2e_checklist.md`
5. Android bridge 갭 분석: `docs/ondev/20260214_37_phase13_android_bridge_gap_analysis.md`
6. Android-first 실행계획: `docs/ondev/20260214_32_phase13_android_first_execution_plan.md`
7. UI 진행 문서: `docs/ondev/20260214_15_ui_phase_progress.md`
8. 필수 배경 문서:
   - `docs/ondev/20260212_04_comprehensive_migration_assessment.md`
   - `docs/ondev/20260212_01_project_b_analysis.md`
   - `docs/ondev/20260212_02_project_c_analysis.md`
   - `docs/ondev/20260212_03_project_e_api_analysis.md`

## 주의사항
- 기존 변경사항이 많은 상태이므로 새 세션 시작 후 **절대 reset/checkout으로 일괄 되돌리지 말 것**.
- 외부 게이트(실기기 증적, 앱스토어)는 저장소 테스트 완료와 별개로 추적한다.
- TDD 원칙 유지: Red -> Green -> Refactor.
