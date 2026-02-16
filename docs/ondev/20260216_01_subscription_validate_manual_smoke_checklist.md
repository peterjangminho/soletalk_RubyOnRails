# Status: [In Progress]

# P76-T3b Subscription Validate Manual Smoke Checklist (2026-02-16)

## Objective
- 로그인 사용자 기준 `/subscription/validate` 운영 경로를 실제 UI에서 검증하고 로그 증적을 확보한다.

## Preconditions
- Railway latest deployment: `f5384e97-058d-417b-8a15-cdb4c8f41660`
- `REVENUECAT_BASE_URL`, `REVENUECAT_API_KEY` 주입 완료
- production URL: `https://soletalk-rails-production.up.railway.app`

## Manual Steps
1. 모바일 브라우저에서 production URL 접속 후 Google 로그인 완료.
2. 상단 `Subscription` 메뉴 진입.
3. `RevenueCat Customer ID` 입력:
   - 기존 보유 ID가 있으면 해당 ID
   - 없으면 테스트용 값(예: `soletalk-smoke-nonexistent`)
4. `Validate Subscription` 또는 `Restore Subscription` 버튼 클릭.
5. 기대 결과 확인:
   - 500 페이지가 나오지 않아야 함.
   - `/subscription` 화면으로 복귀하고 flash 안내가 표시되어야 함.

## Evidence Collection
수동 클릭 직후 실행:
```bash
script/railway/collect_subscription_validate_evidence.sh f5384e97-058d-417b-8a15-cdb4c8f41660
```

판정 기준:
- `status=302` 또는 컨트롤러 경로 정상 완료 로그가 확인되면 pass
- `status=422`만 반복이면 인증/CSRF 미완료 경로로 간주
- `status=500` 또는 `ConfigurationError`가 보이면 fail

## Current Result
- 자동화 증적(`P76-T3a`) 완료
- 로그인 사용자 수동 증적(`P76-T3b`) 대기
