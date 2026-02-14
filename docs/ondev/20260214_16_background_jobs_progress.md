# Status: Done

# Background Jobs Progress

## Objective
- Phase 11 기준 OntologyRAG 연동 백그라운드 잡 기본 경로 구축

## Completed
1. `OntologyRag::EngcEventBatchJob`
- `record_events(google_sub, events)` 호출
- retry 정책 3회 적용

2. `OntologyRag::ConversationSaveJob`
- 세션 메시지 transcript 직렬화 후 `save_conversation` 호출
- metadata(`source: session_end`) 포함
- retry 정책 3회 적용

3. `ExternalInfoJob`
- Premium 사용자만 외부 정보 수집 수행
- Type A-D 요청만 허용하여 OntologyRAG `query` 호출
- 요청별 응답 payload 수집 반환
- retry 정책 3회 적용

4. Dead-letter + dashboard baseline
- `Jobs::DeadLetterNotifier`로 discard payload 기록
- `after_discard` 콜백을 주요 잡에 연결 (`ExternalInfoJob`, `EngcEventBatchJob`, `ConversationSaveJob`)
- `/admin/jobs` 대시보드로 Failed Executions/Dead Letters 요약 확인

## Validation
- Job 테스트 통과 (`P29-T1`, `P29-T2`, `P29-T3`)
- Job 테스트 통과 (`P30-T1`, `P30-T2`, `P30-T3`)
- Job/대시보드 테스트 통과 (`P31-T1`, `P31-T2`, `P31-T3`)
- 전체 테스트 통과 (91 tests, 385 assertions)
- 대상 파일 RuboCop 통과

## Next
- Phase 12 (RevenueCat Subscription) 진행
