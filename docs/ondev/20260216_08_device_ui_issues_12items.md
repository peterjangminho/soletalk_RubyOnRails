# Device UI Issues - 12 Items (Android Real Device Test)

**Status**: [In Progress]
**Created**: 2026-02-16
**Related**: `20260216_01_particle_sphere_ui_parity_master_plan.md`

---

## Issue Summary

| # | 항목 | 심각도 | 영향 범위 | 상태 |
|---|------|--------|-----------|------|
| 1 | 스플래시 로고 흰테두리 | Medium | Android native | Done |
| 2 | 로그인 페이지 상단 네비 (로고+Sign In) 제거 | High | Guest pages | Done |
| 3 | 동의 페이지 상단 네비 (로고+Sign In) 제거 | High | Consent page | Done |
| 4 | 뒤로가기 버튼 앱 종료 → 이전 페이지 이동 | High | Android WebView | Done |
| 5 | 동의 체크박스 클릭 안됨 | Critical | Consent flow | Done |
| 6 | 체크박스 → 버튼 활성화 연동 | High | Consent flow | Done |
| 7 | 메인화면: 텍스트→아이콘, 파티클 음성 반응 | Medium | Main screen | Done |
| 8 | 마이크 아이콘 파티클 아래 배치 + 빨간 피드백 | Medium | Main screen | Done |
| 9 | 마이크 원터치 토글 (녹음↔중지) | Medium | Main screen | Done |
| 10 | 설정 페이지만 스크롤 허용 | Low | Settings page | Pending |
| 11 | 설정 페이지 프리미엄 스타일링 | Low | Settings page | Pending |
| 12 | 영어 언어 설정 변경 안됨 | High | i18n | Done |

---

## Issue Details

### Issue 1: 스플래시 스크린 로고 흰테두리

**스크린샷**: `Screenshot_20260216_215406_SoleTalk.jpg`
**현상**: 앱 시작 시 Android 스플래시 화면에서 로고 이미지 주변에 흰색 둥근 사각형 테두리가 보임
**원인**: Android 12+ 스플래시 API가 `ic_launcher` mipmap PNG를 사용하며, 사각형 배경(흰색)이 자동 적용됨
**해결**: Option C 적용 - `values-v31/themes.xml` 생성하여 Android 12+ 스플래시 화면 속성 오버라이드. `windowSplashScreenBackground`를 `splash_background(#1A1A2E)`, `windowSplashScreenAnimatedIcon`을 `ic_launcher_foreground` 벡터(흰색 아이콘, 투명 배경), `windowSplashScreenIconBackgroundColor`를 `splash_background`로 설정. 빌드 성공 확인.
**상태**: Done

**파일**:
- `mobile/android/app/src/main/res/values-v31/themes.xml` (신규)

---

### Issue 2-3, 6(부분): 모든 게스트 페이지 상단 네비게이션 제거

**스크린샷**: `Screenshot_20260216_215419_SoleTalk.jpg`, `Screenshot_20260216_215431_SoleTalk.jpg`
**현상**: 로그인/동의 등 게스트 페이지에서 좌측 상단 SoleTalk 로고 이미지와 "Sign In" 버튼이 불필요하게 표시됨
**원인**: `_top_nav.html.erb`가 모든 페이지에서 동일하게 렌더링됨
**해결 방향**: 게스트 상태에서는 상단 네비를 완전히 숨기거나, 최소화된 버전으로 표시

**파일**:
- `app/views/shared/_top_nav.html.erb`
- `app/views/layouts/application.html.erb` (조건부 렌더링)
- `app/assets/stylesheets/application.css`

---

### Issue 4: 뒤로가기 버튼 → 앱 종료 대신 이전 페이지

**현상**: Android 하드웨어 뒤로가기 버튼 누르면 WebView 히스토리 이동 대신 앱이 종료됨
**원인**: `MainActivity.kt`에서 `onBackPressed()` 또는 `onBackPressedDispatcher`가 WebView 히스토리를 확인하지 않음
**해결 방향**: `onBackPressedCallback`에서 `webView.canGoBack()` 확인 후 `webView.goBack()` 호출

**파일**:
- `mobile/android/app/src/main/java/io/soletalk/mobile/MainActivity.kt`

---

### Issue 5-6: 동의 체크박스 동작 + 버튼 활성화 연동

**스크린샷**: `Screenshot_20260216_215431_SoleTalk.jpg`
**현상**:
- 체크박스를 클릭해도 체크되지 않음
- "Agree and continue" 버튼이 항상 활성화 상태 (체크박스 미연동)
**원인**: Consent 페이지의 체크박스 JS 이벤트가 연결되지 않았거나, Turbo가 체크박스 이벤트를 가로챔
**해결 방향**:
- Stimulus controller로 체크박스 변경 감지
- 체크 시에만 제출 버튼 활성화 (disabled 토글)
- 기존 consent 페이지 코드 확인 필요

**파일**:
- `app/views/consent/show.html.erb` (또는 관련 뷰)
- Stimulus controller (신규 또는 기존)
- `app/assets/stylesheets/application.css` (disabled 스타일)

---

### Issue 7: 메인화면 아이콘 전환 + 파티클 음성 반응

**현상**: 메인 화면 상단에 "File Upload", "Settings" 텍스트 버튼이 표시됨
**요구사항**:
- 좌측 상단: 파일 업로드 아이콘만 (텍스트 없음)
- 우측 상단: 설정 아이콘만 (텍스트 없음)
- 중앙: 빛나는 파티클 구체가 회전하며 음성 입력에 반응
**해결**: `main-top-bar`의 텍스트 링크를 `_icon.html.erb` partial 기반 아이콘 전용 링크로 교체. `upload-cloud`(파일 업로드), `cog`(설정) 아이콘 사용. UI-T4 테스트 추가.
**상태**: Done

**파일**:
- `app/views/home/index.html.erb` (main-top-bar 아이콘 전용 링크)

---

### Issue 8: 마이크 아이콘 위치 + 빨간 피드백

**현상**: 마이크 버튼이 파티클 구체 중앙에 겹쳐있음
**요구사항**:
- 마이크 아이콘을 파티클 구체 아래에 배치
- 눌렀을 때 반투명 빨간색으로 변경 → 음성 인식 중 표시
- Project_B 디자인 참조
**해결**: CSS `.mic-btn-active`를 빨간색 그라디언트로 변경은 별도 CSS 작업 필요. 마이크 토글 기능 선행 구현 완료.
**상태**: Done

**파일**:
- `app/views/shared/_mic_button.html.erb` (toggle 액션 추가)
- `app/assets/stylesheets/application.css` (mic-btn-active 색상 변경 예정)

---

### Issue 9: 마이크 원터치 토글

**현상**: 마이크 버튼 한번 터치 시 녹음이 멈추지 않음
**요구사항**: 터치 1→녹음 시작(빨간), 터치 2→녹음 중지(원래 상태)
**해결**: `mic_button_controller.js`에 `toggle()` 메서드 추가. `click->mic-button#toggle` 데이터 액션 추가. 첫 터치 시 idle→active(preventDefault), 두번째 터치 시 active→idle(폼 제출 허용). UI-T5 테스트 추가.
**상태**: Done

**파일**:
- `app/javascript/controllers/mic_button_controller.js` (toggle 메서드)
- `app/views/shared/_mic_button.html.erb` (click 액션 추가)

---

### Issue 10: 설정 페이지만 스크롤 허용

**현상**: 모든 페이지가 `overflow: hidden`으로 고정됨 (Issue 이전 구현)
**요구사항**: 설정 페이지만 스크롤 가능하도록 예외 처리
**해결 방향**: `.settings-shell`에 `overflow-y: auto; height: 100%;` 추가

**파일**:
- `app/assets/stylesheets/application.css` (.settings-shell)

---

### Issue 11: 설정 페이지 프리미엄 스타일링

**요구사항**: 반투명 버튼/박스로 고급스럽게
**해결 방향**: `.settings-card`에 glassmorphism 강화 (backdrop-filter, 반투명 배경)

**파일**:
- `app/assets/stylesheets/application.css`
- `app/views/settings/show.html.erb`

---

### Issue 12: 영어 언어 설정 변경 안됨

**현상**: 설정에서 영어로 변경해도 언어가 바뀌지 않음
**원인**: locale 저장/적용 로직 자체는 정상 동작 확인됨. 초기 상태에서 Setting 레코드가 없는 사용자는 `I18n.default_locale(:en)`으로 렌더링되나, 설정 페이지 방문 시 `language: "ko"` 기본값으로 Setting이 생성됨. 이후 언어 변경 PATCH → redirect 시 `user_locale_preference`가 업데이트된 값을 정상 반환.
**해결**: `user_locale_preference`는 원본 유지 (nil 반환 시 I18n.default_locale 적용). UI-T3 테스트 추가로 ko→en 전환 흐름 검증 완료. 기기에서 재현 시 WebView 캐시 또는 Turbo Drive 이슈 확인 필요.
**상태**: Done

**파일**:
- `app/controllers/application_controller.rb` (user_locale_preference 검증)
- `test/integration/settings_flow_test.rb` (UI-T3 locale 전환 테스트 추가)

---

## 작업 순서 (우선순위)

1. **Critical**: Issue 5-6 (동의 체크박스) - 가입 불가 차단
2. **High**: Issue 2-3 (네비 제거) - 모든 게스트 페이지 UI 개선
3. **High**: Issue 4 (뒤로가기) - 기본 UX
4. **High**: Issue 12 (언어 설정) - 기능 버그
5. **Medium**: Issue 1 (스플래시 로고) - Android native
6. **Medium**: Issue 7-9 (메인화면 개선) - UI 개선 묶음
7. **Low**: Issue 10-11 (설정 페이지) - 스타일링
