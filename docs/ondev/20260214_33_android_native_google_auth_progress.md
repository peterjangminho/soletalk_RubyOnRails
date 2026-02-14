# Status: Done

# Android Native Google Auth Progress

## Objective
- Supabase 없이 Rails 직접 인증 구조로 Android 네이티브 로그인 경로를 준비
- `google_sub`를 단일 사용자 식별 키로 유지

## Completed
1. Native sign-in API
- `POST /api/auth/google/native_sign_in` 추가
- 요청: `id_token`
- 응답: `success`, `user_id`, `google_sub`

2. Google ID token verifier
- `Auth::GoogleIdTokenVerifier` 추가
- `https://oauth2.googleapis.com/tokeninfo` 기반 검증
- 검증 항목:
  - `aud == ENV['GOOGLE_CLIENT_ID']`
  - `iss` 유효값(`accounts.google.com`, `https://accounts.google.com`)
  - `sub` 존재

3. User/session linkage
- 토큰 검증 성공 시 `google_sub` 기준 사용자 upsert
- `session[:user_id]` 로그인 처리
- `OntologyRag::IdentifyUserJob` enqueue 유지

## Validation
- 컨트롤러 테스트:
  - `test/controllers/api/auth/google_controller_test.rb`
  - `P59-T1`, `P59-T2`, `P59-T3` 통과
- 서비스 테스트:
  - `test/services/auth/google_id_token_verifier_test.rb`
  - `P59-T4`, `P59-T5`, `P59-T6` 통과
- 전체 회귀:
  - `PARALLEL_WORKERS=1 bundle exec rails test` 통과 (145 runs, 625 assertions)

## Next
- Android 리포에서 Google Sign-In ID token을 위 endpoint로 전송하도록 연결
- 외부 모바일 PoC에서 bridge 이벤트 E2E(`P57-T3`) 수행
- 세션 화면 브리지 부트스트랩(`setSession`)과 Android bridge를 연결해 이벤트 전송 전제조건 고정
- signed bridge token 기본 경로를 우선 사용하고, `google_sub` fallback 단계적 제거 계획 수립
