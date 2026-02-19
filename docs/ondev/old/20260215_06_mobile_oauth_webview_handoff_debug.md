# Status: [Done]

# Mobile OAuth WebView Handoff Debug Note (2026-02-15)

## Reproduction
- Expected:
  - Android 앱에서 `Continue with Google` 완료 후 WebView가 로그인 상태(`Welcome, ...`)로 복귀한다.
- Actual:
  - Custom Tab에서 Google 로그인 성공 후 앱으로 복귀하면 WebView는 다시 `Sign In` 화면으로 돌아간다.
- Scope:
  - `mobile/android` WebView + Rails OAuth callback (`/auth/google_oauth2/callback`)
- Impact:
  - Android external gate에서 세션 화면 진입이 불안정하여 실기기 4종 이벤트 증적 수집이 차단됨.

## Suspicious Code Inspection Summary
- Android는 OAuth URL을 Custom Tab으로 외부 실행하고, 복귀 시 WebView에 `BASE_URL`을 재로딩한다.
- Rails OAuth callback은 브라우저 쿠키 세션만 설정하고 `root_path`로 redirect한다.
- WebView와 Custom Tab 간 쿠키 저장소 공유가 보장되지 않아 로그인 상태가 전달되지 않는다.

## Hypotheses
1. Cookie store split between Custom Tab and WebView
- Evidence: Custom Tab에서 로그인 성공 화면 확인, WebView는 지속적으로 비로그인.
- Prove/Disprove: OAuth 이후 WebView 재로딩 로그가 있어도 `current_user` 없는 렌더링인지 확인.
- Expected observation: WebView 요청은 200이지만 홈 비로그인 UI 렌더링.

2. OAuth callback 결과를 앱으로 handoff 하는 경로 부재
- Evidence: callback controller는 항상 `redirect_to root_path`.
- Prove/Disprove: callback에 mobile-return 파라미터 전달 후에도 앱 deep link 복귀가 없는지 확인.
- Expected observation: 앱이 callback 결과 토큰을 받지 못해 WebView 세션 설정 불가.

3. Android 딥링크 수신 설정 미비
- Evidence: `AndroidManifest.xml`에 `MAIN/LAUNCHER`만 존재, 앱 스킴 인텐트 필터 없음.
- Prove/Disprove: custom scheme URL 호출 시 앱이 열리지 않거나 intent data 처리 미실행.
- Expected observation: `onNewIntent`에 OAuth handoff data 유입 없음.

## Chosen Root Cause (Working)
- RC-1: OAuth 성공 세션이 Custom Tab 쿠키에만 생성되고 WebView 세션으로 전달되는 handoff 프로토콜이 없다.

## Plan
1. Red: 모바일 OAuth callback handoff + handoff token 교환 테스트 추가
2. Green: Rails handoff token 서비스 + callback 분기 + handoff endpoint 구현
3. Green: Android deep link intent filter + handoff URL 로딩 처리
4. Verify: 관련 테스트 + Android build + 실기기 시나리오 재검증

## Verification Result
- Rails:
  - `test/integration/auth/auth_flow_test.rb`
  - `test/controllers/api/auth/google_controller_test.rb`
  - `test/services/auth/mobile_session_handoff_token_test.rb`
  - 결과: 통과
- Android:
  - `assembleDebug` 통과
  - 실기기 로그:
    - `open external browser for oauth url=.../auth/google_oauth2/start?mobile_return=soletalk://auth`
    - `START ... dat=soletalk://auth/... cmp=io.soletalk.mobile/.MainActivity`
    - `webview request: GET .../api/auth/google/mobile_handoff?...`
  - 실기기 화면: OAuth 후 앱 WebView에서 `Welcome, PETER JANG` 확인

## Risks
- Open redirect 리스크를 막기 위해 mobile return URI allowlist가 필요.
- handoff token은 만료시간이 짧고 서명 검증이 필수.
