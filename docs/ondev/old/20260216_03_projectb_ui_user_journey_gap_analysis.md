# Status: [Done]

# Project_B 기준 UI User Journey GAP Analysis (2026-02-16)

## Inputs
- Plan docs:
  - `plan.md`
  - `docs/ondev/20260216_02_projectb_playwright_ui_journey_phase_plan.md`
- Implementation:
  - `app/views/**/*`
  - `app/controllers/settings_controller.rb`
  - `app/models/user.rb`
  - `config/locales/en.yml`, `config/locales/ko.yml`
  - `script/playwright/ui_journey_gap_audit.js`
- Evidence:
  - `/tmp/ui-journey-audit/journey_report.json`
  - `/tmp/ui-journey-audit/*.png`

## Gap Table
| Category | Gap | Priority | Status | Action/Result |
|---|---|---|---|---|
| feature | Settings 파일 업로드 사용자 플로우 부재 | High | Closed | ActiveStorage + upload input + attachment list + integration test 추가 |
| quality | Playwright 자동 점검 결과 오탐(DEPTH/bridge selector) | Medium | Closed | 한/영 라벨 동시 매칭 + data-target selector 보강 |
| feature | Subscription standalone page가 Settings 중심 UX와 분리됨 | High | Closed | `/subscription` 리다이렉트 + Settings 섹션 통합 + nav 제거 |
| feature | Project_B의 실제 brand asset이 Project_A UI에 직접 반영되지 않음 | Medium | Closed | Project_B logo/feature graphic을 `public/brand`로 이식 후 nav/home에 반영 |
| quality | session orb 레이어가 debug/details 클릭을 가로채는 상호작용 충돌 | Medium | Closed | orb를 background-only(`pointer-events:none`)로 전환하고 overlay shell로 구조 분리 |
| documentation | Project_B 대비 user journey 검증 절차 문서화 부족 | Medium | Closed | phase plan + 실행 스크립트 + report 경로 고정 |
| external-gate | localhost OAuth consent 성공은 Google Console redirect 설정 의존 | Medium | Open | callback URI 허용 후 동일 script로 재검증 예정 |

## Root Cause
1. 초기 UI 점검이 수동 스크린샷 위주라, 반복 가능한 user journey 자동화가 부족했다.
2. Settings는 JSON 선호도 중심 구현이었고 파일 맥락 업로드 요구사항이 반영되지 않았다.
3. OAuth consent 성공 여부는 앱 코드만으로 닫히지 않고 Google Console 설정까지 필요하다.
4. 기존 정보구조에서 Subscription이 별도 화면으로 분리되어 Project_B의 Settings 중심 관리 패턴과 어긋나 있었다.

## Current Verification Result
- `bin/rails test test/integration/settings_flow_test.rb` -> pass
- `script/playwright/run_ui_journey_gap_audit.sh` -> `GAP_COUNT=0`
- `journey_report.json` -> `projectA.externalGates[0]`에 localhost OAuth consent 미완료 경고 기록
- user journey checks:
  - Guest Home CTA: pass
  - Project_B logo/feature asset 적용: pass
  - OAuth redirect: pass (Google error page 진입 확인)
  - Dev sign-in local fallback: pass
  - Session create/show: pass
  - Debug tools transcription action: pass
  - Settings upload + persistence visible: pass
  - Subscription validation guard(Settings section): pass

## Minimal Next Action Plan
1. `external-gate` - Google Console redirect URI에 `http://127.0.0.1:3000/auth/google_oauth2/callback` 등록
- Owner: Product/OAuth admin
- Verify: Playwright 보고서에서 OAuth step이 Google error 대신 app callback으로 완료

2. `quality` - Project_B 주요 화면 route inventory 확장 수집
- Owner: Frontend
- Verify: Playwright baseline script에 page-map 단계 추가

3. `test` - user journey Playwright 스크립트를 CI 전용 headless 모드로 분기
- Owner: QA
- Verify: headless 실행 시 `journey_report.json` 산출 및 `gapCount` assertion
