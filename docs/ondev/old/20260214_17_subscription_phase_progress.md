# Status: Done

# Subscription Phase Progress

## Objective
- Phase 12 기준 구독 상태 필드/권한 게이팅/웹훅 동기화 최소 경로 구축

## Completed
1. User subscription fields
- `users`에 `subscription_status`, `subscription_expires_at`, `revenue_cat_id` 추가
- `User#premium?` 판별 로직 추가

2. Entitlement checker
- `Subscription::EntitlementChecker` 구현
- premium 기반 `can_use_external_info?`, `can_access_depth?`, `can_access_insight?` 제공

3. RevenueCat webhook baseline
- `POST /webhooks/revenue_cat` 구현
- `INITIAL_PURCHASE/RENEWAL/EXPIRATION` 이벤트에 따라 사용자 구독 상태 갱신

4. Feature gating baseline
- `Subscription::FeatureGate` 구현 (무료 일일 세션 2회, 무료 7일 히스토리 제한)
- `InsightsController` premium 접근 게이트 적용
- free 사용자는 `/insights` 접근 시 `/sessions` 리다이렉트

5. RevenueCat client + sync service baseline
- `Subscription::RevenueCatClient` 구현 (subscriber entitlements 조회/정규화)
- `Subscription::SyncService` 구현 (사용자 구독 상태 동기화)

6. Paywall + server validation baseline
- `GET /subscription` paywall/관리 화면
- `POST /subscription/validate` 서버 검증(sync service) 경로
- premium 사용자에는 `Manage Subscription` 상태 표시

## Validation
- 구독 모델/서비스/웹훅 테스트 통과 (`P32-T1`, `P32-T2`, `P32-T3`)
- Feature gating/접근제어 테스트 통과 (`P33-T1`, `P33-T2`, `P33-T3`)
- RevenueCat client/sync 테스트 통과 (`P34-T1`, `P34-T2`, `P34-T3`)
- Paywall/validation 통합 테스트 통과 (`P35-T1`, `P35-T2`, `P35-T3`)
- 전체 테스트 통과 (103 tests, 433 assertions)
- 대상 파일 RuboCop 통과

## Next
- Phase 13 (Voice Pipeline) 준비
