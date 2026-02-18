# Status: Done

# UI Phase Progress

## Objective
- Turbo 기반 Session UI 최소 동작 경로 구성(list/show + 실시간 phase badge 소비)

## Completed
1. `SessionsController`
- `index`: 현재 로그인 사용자 세션 목록 조회
- `show`: 사용자 소유 세션 상세 조회

2. Session views
- `sessions/index`: 세션 목록/상세 링크
- `sessions/index`: New Session 진입 링크
- `sessions/show`: `turbo_stream_from @session` 구독
- `voice_chat_phase_badge` 타겟 포함(실시간 phase replace 수신 지점)
- DEPTH 패널(`depth-panel`) 표시
- 최근 Insight 패널(`recent-insights-panel`) 표시
- 세션 메시지 스트림(시간순 렌더링) 표시
- 세션 메시지 입력 폼 및 전송 동선(`POST /sessions/:session_id/messages`)
- `sessions/new`: 세션 시작 폼

3. Domain relation
- `User`에 `has_many :sessions` 연관 추가

4. Messages controller
- 사용자 소유 세션 범위에서만 메시지 생성 허용
- 타 사용자 세션 접근 시 404 차단

5. Session creation flow
- `POST /sessions`로 active 세션 생성
- 생성 시 `VoiceChatData(current_phase: opener)` 초기화

6. Insight UI enhancement
- `insights/index`: 카드형 타임라인(`insight-timeline`, `insight-card`)
- `insights/show`: Q1~Q4 디테일 카드(`insight-detail-card`)

7. Baseline responsive styling
- `application.css`에 레이아웃/카드/모바일 브레이크포인트 추가

8. Settings UI
- `resource :setting` 라우트 + `SettingsController(show/update)`
- language/voice_speed/preferences(JSON) 수정 폼
- sessions/settings 양방향 네비게이션 링크

9. Emotion gauge
- session 상세에 `meter.emotion-gauge` 추가
- `voice_chat_data` 미존재 시 `0.0` fallback 표시

10. Stimulus bootstrap + common controllers
- `config/importmap.rb` + `app/javascript/application.js` + `app/javascript/controllers/*` 구성
- `message-form` 컨트롤러: submit 성공 시 입력창 clear
- `settings-form` 컨트롤러: preferences JSON normalize
- layout에 `javascript_importmap_tags` 연결

11. Root home dashboard
- `HomeController#index`를 plain 응답에서 대시보드 렌더링으로 전환
- 비로그인 상태: Google OAuth 진입 CTA 표시
- 로그인 상태: 최근 세션/인사이트와 핵심 이동 링크 표시

12. UX hardening pass (2026-02-15)
- 공통 상단 내비게이션 추가(`shared/_top_nav`) 및 레이아웃 브랜드명 `SoleTalk`로 통일
- 사용자 피드백 영역 추가(`shared/_flash`) + 주요 액션 redirect notice/alert 연결
- 홈 로그인 상태에서 내부 식별자(`google_sub`) 직접 노출 문구 제거
- Session 화면 Android bridge 도구를 `details` 기반 Debug 섹션으로 분리
- Native bridge status를 `aria-live="polite"` + 상태별 시각 피드백으로 개선
- 메시지 전송 폼: submit 중 버튼 비활성/라벨 변경(`Sending...`) 후 복구
- Settings JSON blur 검증 결과를 사용자 문구로 표시
- 링크/버튼 스타일과 입력 폼 스타일을 공통 CSS로 정리

## Validation
- Sessions 통합 테스트 통과 (`P22-T1`, `P22-T2`, `P22-T3`)
- Session message 통합 테스트 통과 (`P23-T1`, `P23-T2`, `P23-T3`)
- Session creation 통합 테스트 통과 (`P24-T1`, `P24-T2`, `P24-T3`)
- Insight UI/DEPTH panel 통합 테스트 통과 (`P25-T1`, `P25-T2`, `P25-T3`)
- Settings 통합 테스트 통과 (`P26-T1`, `P26-T2`, `P26-T3`)
- Emotion gauge 통합 테스트 통과 (`P27-T1`, `P27-T2`)
- Stimulus hook/bootstrapping 통합 테스트 통과 (`P28-T1`, `P28-T2`, `P28-T3`)
- 홈 화면 통합 테스트 통과 (`P54-T1`, `P54-T2`)
- UX 하드닝 통합 테스트 통과 (`UX-T1`, `UX-T2`)
- `PARALLEL_WORKERS=1 bundle exec rails test test/integration` 통과 (51 runs, 306 assertions)
- `RUBOCOP_CACHE_ROOT=/tmp/rubocop_cache bundle exec rubocop ...` 통과 (변경 Ruby 파일 no offenses)
- 전체 테스트 통과 (81 tests, 350 assertions)
- 대상 Ruby 파일 RuboCop 통과

## Next
- UI/UX 갭 잔여 항목(다국어 전체 로컬라이징, 소비자용 구독 결제 UX 분리) 후속 진행
