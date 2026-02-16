# Status: [In Progress]

# Project_B Playwright UI Journey Phase Plan (2026-02-16)

## Objective
- Project_B 기준으로 Project_A UI/UX를 Playwright로 전수 점검한다.
- 가입(게스트) -> OAuth 진입 -> 세션 생성/대화 -> 설정 -> 파일 업로드 -> 구독 검증까지 사용자 여정을 자동화한다.
- 발견된 GAP을 phase 단위로 닫고, `plan.md`와 동기화한다.

## Scope
- 대상 앱
  - Project_A: `http://127.0.0.1:3000`
  - Project_B: `http://127.0.0.1:4173`
- 대상 화면/흐름
  - Guest Home + OAuth CTA
  - Google OAuth redirect/consent 진입
  - Signed-in Home
  - Sessions(New/Show)
  - Debug Tools (Android bridge)
  - Settings(파일 업로드 포함)
- Subscription(validate/restore guard)
- Subscription은 standalone page가 아니라 Settings 내부 섹션(`#subscription`)으로 통합

## Skill Orchestration (Sequential)
1. `roadmap-skill`
- `plan.md`에 phase/test 항목 추가 및 상태 동기화
2. `sub-plan-skill`
- 본 문서에 phase scope/TDD/validation/next test 반영
3. `playwright-skill`
- 양 프로젝트 브라우저 자동화 및 스크린샷/JSON 증적 수집
4. `gap-analysis-skill`
- planned vs actual vs evidence 비교 및 gap table 업데이트
5. `execute-skill`
- gap 닫기 구현(TDD Red -> Green -> Refactor)
6. `frontend-design`
- InCar visual direction 유지 조건 검토(비주얼 회귀 방지)

## Phase Matrix (Sequential vs Parallel)
| Phase | 내용 | Depends On | Parallel Feasibility | Decision |
|---|---|---|---|---|
| M1 | Project_A/Project_B baseline 수집 | 없음 | High (서버 기동 병렬 가능) | 완료 |
| M2 | Playwright user journey automation | M1 | Medium (한 브라우저 내 flow는 순차, 앱별 실행은 병렬 가능) | 완료 |
| M3 | GAP remediation (settings upload, locale keys) | M2 | Low (동일 뷰/locale 충돌) | 완료 |
| M4 | 재검증 + 증적 고정(script/report) | M3 | High (Rails test/Playwright 병렬 가능) | 완료 |
| M5 | Subscription in Settings 통합 + nav 정합화 | M4 | Low (settings/subscription controller/test 동시 수정) | 완료 |
| M6 | 실제 Google consent 성공(localhost callback 허용) 외부 게이트 | Google Console 설정 | Low (외부 콘솔 변경 필요) | 진행 중 |

## TDD Checkpoints
- Red
  - `test/integration/settings_flow_test.rb`에 파일 업로드 실패 재현 테스트(`P78-T1`) 추가
- Green
  - ActiveStorage 설치 + `User#uploaded_files` + Settings attach 로직 최소 구현
- Refactor
  - i18n 키(`uploaded_file`, `uploaded_files`) 보강 및 Playwright selector 강건화

## Implementation Steps
1. `P77-T1` Playwright 종합 점검 스크립트 저장소 고정
- `script/playwright/ui_journey_gap_audit.js`
- `script/playwright/run_ui_journey_gap_audit.sh`

2. `P77-T2` Project_B 비교 baseline + Project_A user journey 증적 생성
- 출력: `/tmp/ui-journey-audit/journey_report.json`
- 스크린샷: `/tmp/ui-journey-audit/*.png`

3. `P78-T1` Settings 파일 업로드 사용자 플로우 구현
- `db/migrate/20260216065533_create_active_storage_tables.active_storage.rb`
- `app/models/user.rb`
- `app/controllers/settings_controller.rb`
- `app/views/settings/show.html.erb`
- `test/integration/settings_flow_test.rb`

4. `P78-T3` locale 보강(업로드 라벨/도움말/목록)
- `config/locales/en.yml`
- `config/locales/ko.yml`

5. `P78-T2` 외부 게이트
- Google Cloud Console에 localhost callback 추가 후 real consent success 재검증

6. `P79-T1~T3` Subscription UI 통합
- `app/controllers/subscription_controller.rb` `/subscription -> /setting#subscription` 리다이렉트
- `app/views/settings/show.html.erb` 내 구독 섹션 통합 렌더
- `app/views/shared/_top_nav.html.erb` standalone subscription 탭 제거
- `test/integration/subscription_flow_test.rb`, `test/integration/settings_flow_test.rb`, `test/integration/home_flow_test.rb` 회귀 보강

## Validation
```bash
bin/rails test test/integration/settings_flow_test.rb
script/playwright/run_ui_journey_gap_audit.sh
```
- pass 기준:
  - settings integration tests green
  - `journey_report.json`의 `gapCount=0`
  - 사용자 여정 단계 `A1~A7` 모두 `status=ok`

## Session-End Update
- Completed
  - `P77-T1`, `P77-T2`, `P77-T3` 완료 (script+report 고정, gap 0)
  - `P78-T1` 완료 (settings 파일 업로드 TDD 구현)
  - locale 업로드 키 보강 완료
  - `P79-T1~T3` 완료 (subscription settings 통합 + nav 정합화 + 테스트/Playwright green)
- Pending
  - `P78-T2`: localhost OAuth consent success 외부 게이트
- Mismatch
  - 없음 (현재 갭은 내부 코드 기준 0)
- Next Test
  - `P78-T2`: OAuth callback 허용 후 Playwright에서 Google consent -> app callback 성공 확인
