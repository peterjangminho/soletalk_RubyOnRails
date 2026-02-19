# Status: [Done]

# UI/UX Inventory + GAP Analysis (2026-02-15)

## Scope
- 대상: Rails Web UI (Home, Sessions, Insights, Settings, Subscription, Native Bridge Debug)
- 기준 문서:
  - `plan.md`
  - `docs/ondev/20260214_15_ui_phase_progress.md`
  - `docs/ondev/20260214_35_android_audio_bridge_component_progress.md`
  - `docs/ondev/20260214_37_phase13_android_bridge_gap_analysis.md`
- 기준 코드:
  - `app/views/**/*`
  - `app/javascript/controllers/*`
  - `app/controllers/*`

## UI/UX Inventory (Consumer-Facing)

| Screen | Consumer 안내 문구 | 버튼/링크 | 클릭/입력 효과 | 언어 상태 |
|---|---|---|---|---|
| Global Top Nav | 브랜드명 `SoleTalk` | `SoleTalk`, `Sessions`, `Insights`, `Subscription`, `Settings`, (게스트) `Sign In` | 각 링크로 화면 이동 | English |
| Flash Feedback | 성공/실패 메시지 노출 | 없음 | redirect 후 `notice`/`alert` 표시 | English |
| Home (Guest) | 서비스 설명 + Google OAuth 안내 + privacy 문구 | `Continue with Google` | OAuth 시작 (`/auth/google_oauth2`) | English |
| Home (Signed-in) | 환영 문구 + 최근 사용 안내 | `Start New Session`, `Open Sessions`, `Open Insights`, `Settings` | 각 기능 화면 이동 | English |
| Sessions Index | 세션 히스토리 안내 | `New Session`, `Settings`, `Session #id` | 신규 세션 시작 화면/세션 상세 이동 | English |
| Sessions New | 세션 시작 가이드 | `Start Session` | active session + `voice_chat_data` 생성 후 상세로 이동 | English |
| Session Show (Main) | DEPTH Snapshot/Emotion gauge | `Back to Sessions`, `Settings`, `Send` | 메시지 전송, 제출 중 버튼 `Sending...`, 성공 시 입력창 clear | English |
| Session Show (Debug) | Android bridge 디버그 안내 | `Start Recording`, `Stop Recording`, `Send Transcription`, `Send Location`, `Request Current Location`, `Play Audio` | bridge 메서드 호출 + 상태 텍스트 갱신 (`aria-live`, status state) | English |
| Insights Index | 인사이트 타임라인 | 인사이트 제목 링크, `Back to Sessions` | 상세 화면 이동 | English |
| Insights Show | Q1~Q4 상세 표시 | `Back to Insights` | 목록 이동 | English |
| Settings | 언어/음성속도/JSON 설정 안내 | `Back to Sessions`, `Save Settings` | blur 시 JSON normalize/오류 문구, 저장 시 flash | English |
| Subscription | 구독 상태/검증 안내 | `Back to Sessions`, `Validate Subscription` | RevenueCat ID 검증 후 상태 sync + flash | English |

## GAP Table (Planned vs Implemented vs UX Reality)

| Category | Gap | Priority | Status | Action/Result |
|---|---|---|---|---|
| quality | 홈에서 내부 식별자(`google_sub`) 직접 노출 | High | Closed | 홈 카피에서 식별자 노출 제거 |
| quality | 주요 액션 후 사용자 피드백 부족(저장/전송/검증) | High | Closed | 공통 flash 영역 + redirect notice/alert 적용 |
| feature | 네이티브 브리지 테스트 UI가 소비자 화면과 구분되지 않음 | High | Closed | `details` 기반 Debug Tools 섹션으로 분리 |
| quality | bridge 상태 텍스트의 접근성/시각 피드백 부족 | Medium | Closed | `aria-live="polite"` + status state CSS 추가 |
| quality | 메시지 전송 버튼 클릭 효과(진행중 상태) 부재 | Medium | Closed | `message_form_controller`에 submit start/end 상태 추가 |
| quality | settings JSON 입력 오류 시 사용자 안내 부족 | Medium | Closed | `settings_form_controller`에 normalize/invalid 상태 문구 추가 |
| documentation | 화면별 문구/버튼/효과 인벤토리 부재 | Medium | Closed | 본 문서 신설 |
| feature | 전체 UI 다국어(ko/en) 런타임 전환 미구현 | Medium | Open | i18n 키 기반 전면 치환은 후속 사이클 |
| feature | 소비자용 paywall UX (직접 결제/복원 플로우) 미구현 | High | Open | 현재는 RevenueCat ID 검증형 운영자/테스터 UX |
| test | 프론트엔드 JS 상호작용(unit/system) 자동화 범위 제한 | Low | Open | Stimulus 동작 단위 테스트 도입 검토 |

## Root Causes (Major)
1. 초기 Phase 목표가 “기능 연결 최소 경로” 중심이라, 소비자 카피/피드백/접근성 디테일이 후순위로 밀림
2. Android bridge 검증용 패널이 개발용 요구사항으로 먼저 도입되어, 사용자/디버그 경계가 명확히 분리되지 않음
3. Settings/Subscription은 백엔드 계약 검증 중심으로 구현되어 사용자 안내 문구와 상태 피드백이 부족했음

## Implemented in This Cycle
- 레이아웃/브랜딩 정비:
  - `app/views/layouts/application.html.erb`
  - `app/views/shared/_top_nav.html.erb`
  - `app/views/shared/_flash.html.erb`
- 화면 카피/CTA 개선:
  - `app/views/home/index.html.erb`
  - `app/views/sessions/index.html.erb`
  - `app/views/sessions/new.html.erb`
  - `app/views/insights/index.html.erb`
  - `app/views/insights/show.html.erb`
  - `app/views/settings/show.html.erb`
  - `app/views/subscription/show.html.erb`
- 클릭/상태 효과 개선:
  - `app/views/sessions/show.html.erb`
  - `app/javascript/controllers/message_form_controller.js`
  - `app/javascript/controllers/settings_form_controller.js`
  - `app/javascript/controllers/native_bridge_controller.js`
- 액션 결과 피드백(Flash) 연결:
  - `app/controllers/sessions_controller.rb`
  - `app/controllers/messages_controller.rb`
  - `app/controllers/settings_controller.rb`
  - `app/controllers/subscription_controller.rb`
  - `app/controllers/auth/omniauth_callbacks_controller.rb`
- 스타일 일관성:
  - `app/assets/stylesheets/application.css`

## Verification
- Red/Green:
  - 추가 테스트:
    - `UX-T1` (`test/integration/home_flow_test.rb`)
    - `UX-T2` (`test/integration/sessions_flow_test.rb`)
- 실행:
```bash
bundle exec rails test test/integration/home_flow_test.rb test/integration/sessions_flow_test.rb test/integration/settings_flow_test.rb test/integration/insights_flow_test.rb test/integration/subscription_flow_test.rb
PARALLEL_WORKERS=1 bundle exec rails test test/integration
RUBOCOP_CACHE_ROOT=/tmp/rubocop_cache bundle exec rubocop app/controllers/auth/omniauth_callbacks_controller.rb app/controllers/messages_controller.rb app/controllers/sessions_controller.rb app/controllers/settings_controller.rb app/controllers/subscription_controller.rb test/integration/home_flow_test.rb test/integration/sessions_flow_test.rb
```
- 결과:
  - integration: 51 runs, 306 assertions, 0 failures
  - rubocop(target files): no offenses

## Minimal Next Action Plan
1. `feature` - i18n 전면 치환:
   - Owner: Rails Web
   - Verify: locale 전환 시스템 테스트 + 화면 카피 스냅샷
2. `feature` - 소비자용 paywall UX:
   - Owner: Subscription
   - Verify: 구독/복원 E2E + 안내문구 정책 검토
3. `test` - Stimulus interaction 테스트:
   - Owner: Frontend
   - Verify: message/settings/native-bridge 컨트롤러 단위 테스트
