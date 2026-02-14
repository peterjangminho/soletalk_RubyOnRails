# Status: Done

# OntologyRAG Client & API Integration Phase Plan

## Objective
- OntologyRAG P0 연동을 위한 클라이언트/모델/서비스/컨트롤러 레이어를 Rails에 구현

## Scope
- `OntologyRag::Client` 핵심 API 메서드 구현
- `OntologyRag::Constants`, `OntologyRag::Models` 구현
- `OntologyRag::UserSyncService` 서비스 레이어 구현
- `/api/ontology_rag/users/sync` 컨트롤러 연동
- `DepthExploration`, `Insight` 모델 구현

## TDD Checkpoints
- Red: P1~P6 테스트를 먼저 추가하고 실패 확인
- Green: 최소 구현으로 테스트 통과
- Refactor: RuboCop 기반 포맷/구조 정리 (동작 불변)

## Completed Items
1. `OntologyRag::Client`
   - `default_headers`, `identify_user`, `get_prompts`, `query`, `record_events`, `save_conversation`
   - timeout retry/fallback
2. `OntologyRag::Constants`
   - P0 endpoint 경로, source/app_source, timeout/retry 상수
3. `OntologyRag::Models`
   - `EngcProfile` (emotion/need/goal/constraint 단수 키)
   - `QueryResponse` 정규화
4. `OntologyRag::UserSyncService`
   - 성공/실패 표준 페이로드 변환
5. API Controller
   - `POST /api/ontology_rag/users/sync`
   - 200(success), 422(validation), 502(upstream fail)
6. Domain Models
   - `DepthExploration`, `Insight` + 마이그레이션/검증

## Validation
- `bundle exec rails test` 통과 (21 tests, 98 assertions)
- 대상 파일 RuboCop 통과 (no offenses)

## Session-End Update
- Completed: P1-T1~T5, P2-T1~T3, P3-T1~T3, P4-T1~T2, P5-T1~T3, P6-T1~T3
- Pending: Phase 2 인증, Phase 3 나머지 모델(Session/Message/VoiceChatData/Setting)
- Mismatch: 없음
- Next Test: P7-T1 (User 모델 google_sub unique 검증 테스트)
