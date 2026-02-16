# Status: [In Progress]

# Project_B Auth/Main UI GAP Analysis (2026-02-16)

## Scope
- 로그인 화면(Project_B `LoginPage`)과 Project_A guest home 비교
- 가입/동의 플로우(Project_B privacy + terms gate)와 Project_A 비교
- 오프닝 애니메이션 + 브랜드 로고 표시
- 메인 화면(3D 구형 파티클 + 마이크 + 좌상단 업로드/우상단 설정)

## GAP Matrix
| Area | Project_B Baseline | Project_A Before | GAP | Action |
|---|---|---|---|---|
| Login shell | 브랜드 타이틀 + 카드형 로그인 + Google CTA | 단순 sign-in 카드 | 중 | guest home에 로그인 카드 구조/CTA 재구성 |
| Signup flow | 로그인 외 별도 온보딩 동선 존재 | 없음 | 큼 | `/sign_up` 화면 신규 추가 |
| Consent flow | 정책 열람/동의 후 진입 | 없음 | 큼 | `/consent` 화면 + 동의 처리(`session[:policy_agreed]`) 추가 |
| Legal content | Privacy/Terms 공개 문서 링크 | 없음 | 큼 | Project_B legal HTML을 `public/legal/en`으로 이식 |
| Opening | 파티클 오프닝 + SoleTalk 로고 | 없음 | 큼 | home fixed overlay 오프닝 추가 |
| Main orb surface | 3D orb 중심 홈 진입 | 일부 카드 중심 | 중 | signed-in home에 `main-orb-stage` 추가 |
| Main top controls | 빠른 상단 액션 | settings 이동만 존재 | 중 | 파일업로드(anchor) + 설정 버튼 배치 |
| Main mic affordance | orb 아래 음성 액션 affordance | 없음 | 중 | 원형 마이크 버튼 추가 |

## Implemented Changes
- Routes / controller
  - `config/routes.rb`: `/sign_up`, `/consent`, `/consent/accept` 추가
  - `app/controllers/onboarding_controller.rb` 추가
  - `POST /guest_sign_in` + `app/controllers/auth/guest_sessions_controller.rb` 추가
  - `app/controllers/auth/oauth_starts_controller.rb`에서 policy 미동의 웹 로그인 차단(`-> /consent`)
- Views
  - `app/views/home/index.html.erb`: guest login parity + opening overlay + signed-in main orb/mic/top actions 반영
  - `app/views/home/index.html.erb`: main mic CTA를 `POST /sessions`로 연결(실제 세션 시작)
  - `app/views/onboarding/signup.html.erb` 추가
  - `app/views/onboarding/consent.html.erb` 추가
  - `app/views/settings/show.html.erb`: 업로드 섹션 anchor(`id="uploads"`) 추가
- Assets
  - `public/legal/en/privacy-policy.html` (from Project_B)
  - `public/legal/en/terms-of-service.html` (from Project_B)
- Styles / motion
  - `app/assets/stylesheets/application.css`: auth shell, consent card, opening overlay, main orb/mic, disabled CTA + login divider 스타일 추가

## Validation
- `bin/rails test test/integration/auth/auth_flow_test.rb` pass
- `bin/rails test test/integration/onboarding_flow_test.rb` pass
- `bin/rails test test/integration/home_flow_test.rb` pass
- `bin/rails test test/integration/settings_flow_test.rb` pass

## Remaining External Gate
- localhost Google OAuth callback mismatch(`P78-T2`)은 Google Console redirect URI 수동 등록 필요

## P87 Follow-up (Main Mic Auto-Start)
- Home main mic form now includes `entrypoint=main_mic` hidden field.
- `SessionsController#create` now redirects to `/sessions/:id?auto_start_recording=1` only for `main_mic` entrypoint.
- Session debug bridge panel now exposes `data-native-bridge-auto-start-value`.
- `native_bridge_controller` auto-starts `startRecording()` on connect when the flag is true and bridge is available.

### P87 Validation
- `bin/rails test test/integration/session_creation_flow_test.rb` pass
- `bin/rails test test/integration/home_flow_test.rb` pass
- `bin/rails test test/integration/sessions_flow_test.rb` pass
- `npm run test:js -- test/javascript/controllers/native_bridge_controller_test.mjs` pass
- `script/playwright/run_ui_journey_gap_audit.sh` -> `GAP_COUNT=0`

## P88 Follow-up (Consent Gate + Auth Visual Polish)
- `consent` 화면에 `consent-gate` Stimulus 컨트롤러를 적용해 정책 열람 액션 전 동의 체크/진행 버튼을 비활성화.
- 정책 링크 클릭 시 동의 체크 활성화, 체크 완료 시 `Agree and continue` 활성화.
- signup/consent 카드에 `auth-card-signup`, `auth-card-consent`, `auth-divider`, `consent-note` 스타일 훅 추가.
- Playwright audit 스크립트를 consent gate 플로우(정책 열람 -> 동의 체크)에 맞춰 갱신.

### P88 Validation
- `bin/rails test test/integration/onboarding_flow_test.rb` pass
- `PARALLEL_WORKERS=1 bin/rails test test/integration/onboarding_flow_test.rb test/integration/home_flow_test.rb test/integration/session_creation_flow_test.rb test/integration/sessions_flow_test.rb test/integration/settings_flow_test.rb test/integration/subscription_flow_test.rb` pass
- `script/playwright/run_ui_journey_gap_audit.sh` -> `GAP_COUNT=0`

## P89 Follow-up (Local OAuth External Gate Readiness)
- Added `script/oauth/collect_local_oauth_redirect_evidence.sh` to extract actual provider redirect payload from:
  - `http://127.0.0.1:3000/auth/google_oauth2`
  - `http://localhost:3000/auth/google_oauth2`
- Captured evidence report:
  - `/tmp/oauth-local-gate/local_oauth_redirect_20260216_122746.txt`
  - Verified redirect URIs:
    - `http://127.0.0.1:3000/auth/google_oauth2/callback`
    - `http://localhost:3000/auth/google_oauth2/callback`
- Hardened Playwright OAuth step to classify `redirect_uri_mismatch` / `access blocked` messages as external-gate diagnostics.
- Added checklist doc:
  - `docs/ondev/20260216_05_local_oauth_external_gate_checklist.md`

### P89 Validation
- `script/oauth/collect_local_oauth_redirect_evidence.sh` pass
- `script/playwright/run_ui_journey_gap_audit.sh` -> `GAP_COUNT=0`
