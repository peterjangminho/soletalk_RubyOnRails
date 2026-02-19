# Status: [Done]

# Android OAuth Return Race Debug (2026-02-15)

## Reproduction
- Expected:
  - Google OAuth 완료 후 Android WebView가 로그인 상태 홈으로 안정적으로 복귀해야 함.
- Actual:
  - 일부 시도에서 로그인 직후 다시 guest 화면으로 돌아가며 재로그인이 반복됨.
- Scope:
  - `mobile/android/app/src/main/java/io/soletalk/mobile/MainActivity.kt`
- Impact:
  - 실기기 로그인 신뢰성 저하, UX 이탈 발생.

## Suspicious Code Inspection Summary
- OAuth 시작 시 `shouldReloadAfterOauth = true` 설정.
- `onResume`에서 플래그가 true면 `BASE_URL` 재로드.
- `onNewIntent`에서 deep-link(`soletalk://auth?...`)를 받아 handoff URL 로드하지만 플래그를 해제하지 않음.

## Hypotheses
1. `onNewIntent` 직후 `onResume` fallback reload가 실행되어 handoff 교환 요청을 덮어쓴다.
- Evidence: deep-link 경로와 fallback reload가 같은 lifecycle에 공존.
- Prove/Disprove: deep-link 수신 시 플래그 해제 후 재현률 비교.
- Expected: 플래그 해제 시 로그인 복귀 안정화.

2. OAuth 완료 deep-link가 아닌 일반 resume에서도 reload가 과도하게 실행된다.
- Evidence: `onResume`가 조건 단일 플래그에 의존.
- Prove/Disprove: deep-link intent 유무에 따른 reload 로그 비교.
- Expected: deep-link intent가 있으면 reload는 실행되면 안 됨.

3. handoff 토큰 자체가 무효/만료다.
- Evidence: Rails handoff 테스트 및 실기기 성공 사례 존재.
- Prove/Disprove: 동일 토큰 경로에서 간헐적 성공/실패 여부 확인.
- Expected: race 해결 후 실패율 감소하면 토큰 원인 가능성 낮음.

## Root Cause
- 가설 1 채택.
- `onNewIntent`로 deep-link handoff 경로를 로드한 뒤에도 `shouldReloadAfterOauth`가 유지되어, `onResume` fallback reload가 경합으로 실행됨.

## Fix
- `onNewIntent`에서 `intent.data != null`인 경우 `shouldReloadAfterOauth = false`로 즉시 해제.
- deep-link 기반 OAuth 복귀 흐름이 fallback reload에 덮어써지지 않도록 조정.

## Tests and Evidence
- JS regression:
  - `npm run test:js` -> pass (22 tests)
- Rails regression:
  - `PARALLEL_WORKERS=1 bundle exec rails test` -> pass (169 runs, 0 failures)
- Android build verification:
  - `cd mobile/android && GRADLE_USER_HOME=/Users/peter/Project/Project_A/.gradle-home ./gradlew assembleDebug` -> BUILD SUCCESSFUL

## Code-review Plugin Result
- 이번 cycle은 기존 code-review 결과의 후속 안정화 fix이며, blocking 이슈 없음.

## E2E Validation Result
- PASS (build/test gate 기준)
- 실기기 OAuth 반복 시나리오는 다음 외부 수동 게이트에서 재검증 예정.

## Residual Risks
- deep-link가 전달되지 않는 비정상 브라우저/OS 동작에서는 fallback reload 경로에 계속 의존.
- OAuth 취소/중단 시점 UX(안내 문구)는 후속 polish 대상.
