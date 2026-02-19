# Status: Done

# OntologyRAG P1 Progress

## Objective
- Phase 14의 P1 엔드포인트 중 `get_cached_profile` 클라이언트 경로를 선행 구현

## Completed
1. `OntologyRag::Constants`
- `ENDPOINTS[:get_cached_profile] = "/incar/profile/%{google_sub}"` 추가

2. `OntologyRag::Client#get_cached_profile`
- `GET /incar/profile/{google_sub}` 호출
- 응답을 `{ google_sub:, profile: {} }` 형태로 정규화 반환

3. VoiceChat 3-layer API baseline
- `POST /api/voice_chat/surface` (phase transition 계산/반영)
- `POST /api/voice_chat/depth` (DepthExploration 저장)
- `POST /api/voice_chat/insight` (Insight 생성)

4. Query cache baseline
- `OntologyRag::Client#query`에 TTL 캐시 적용
- 캐시 키에 `google_sub`, `question`, `limit`, `container_id` 포함
- 동일 요청은 캐시 히트, TTL 경과 시 재조회

5. OntologyRAG query API baseline
- `POST /api/ontology_rag/query` 엔드포인트 추가
- question 필수 검증(422), 정상 응답 정규화(200), 업스트림 에러 변환(502)

6. Context Orchestrator L2/L4 baseline
- `ContextOrchestrator#build_dynamic` 추가
- L1 profile: `get_cached_profile` 연동
- L2 past_memory: `query("recent memory context")` 연동
- L4 additional_info: 사용자 질의 기반 query 연동

## Validation
- OntologyRAG constants/client 테스트 통과 (`P37-T1`, `P37-T2`, `P37-T3`)
- VoiceChat 3-layer API 테스트 통과 (`P38-T1`, `P38-T2`, `P38-T3`)
- Query cache 테스트 통과 (`P39-T1`, `P39-T2`, `P39-T3`)
- Query API 테스트 통과 (`P40-T1`, `P40-T2`, `P40-T3`)
- Context Orchestrator 동적소스 테스트 통과 (`P41-T1`, `P41-T2`, `P41-T3`)
- 전체 테스트 통과 (115 tests, 477 assertions)
- 대상 파일 RuboCop 통과

## Next
- Phase 15 (Integration Tests + Optimization) 진행
