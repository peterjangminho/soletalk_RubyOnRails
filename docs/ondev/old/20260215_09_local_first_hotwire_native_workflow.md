# Status: [Done]

# Local-First Hotwire Native Workflow (2026-02-15)

## Why
- 목적: UI/UX 작업 시 매번 Railway 배포 없이 로컬에서 즉시 확인.
- 기존 문제: Android WebView `BASE_URL`이 프로덕션에 고정되어 배포 의존도가 높았음.

## Implemented
1. Android debug base URL 분리
- `mobile/android/app/build.gradle.kts`
  - `BuildConfig.WEB_BASE_URL` 추가
  - `debug`: `SOLETALK_DEBUG_BASE_URL` (기본 `http://127.0.0.1:3000/`)
  - `release`: production URL 고정
  - `buildFeatures.buildConfig = true`

2. MainActivity base URL 동적화
- `mobile/android/app/src/main/java/io/soletalk/mobile/MainActivity.kt`
  - 하드코딩 `BASE_URL` 제거
  - `BuildConfig.WEB_BASE_URL` 기반 URL 처리
  - local(http)에서는 external OAuth handoff 강제 비활성화

3. dev/test 전용 quick sign-in
- `config/routes.rb`
  - `POST /dev/sign_in`
  - `DELETE /dev/sign_out`
- `app/controllers/dev/sessions_controller.rb`
  - 로컬 테스트용 사용자 세션 생성/해제
- `app/views/home/index.html.erb`
  - 게스트 화면 `Quick Dev Sign In` 버튼(dev/test만 노출)

4. 실행 자동화 스크립트
- `script/mobile/start_local_ui_workflow.sh`
  - `adb reverse tcp:3000 tcp:3000`
  - `installDebug` with `SOLETALK_DEBUG_BASE_URL`

## How To Use
1. Rails 로컬 서버 실행
```bash
bin/rails s -b 0.0.0.0 -p 3000
```

2. Android 로컬 설치/실행 (USB 연결)
```bash
script/mobile/start_local_ui_workflow.sh
```

3. 앱 홈(게스트)에서 `Quick Dev Sign In` 탭
- Google OAuth 없이 로컬 세션으로 즉시 UI 검증 가능

## Optional
- 다른 포트/URL 사용:
```bash
PORT=4000 SOLETALK_DEBUG_BASE_URL=http://127.0.0.1:4000/ script/mobile/start_local_ui_workflow.sh
```

## Verification
- `test/integration/dev_sign_in_flow_test.rb` green
- `bundle exec rails test` green
- `npm run test:js` green
- `./gradlew -PSOLETALK_DEBUG_BASE_URL=http://127.0.0.1:3000/ assembleDebug` green

## Notes
- production에서는 `dev/sign_in` 라우트가 노출되지 않음(development/test only).
- 실운영 `subscription/validate` 500은 별도 이슈(`REVENUECAT_BASE_URL/API_KEY` 미설정).
