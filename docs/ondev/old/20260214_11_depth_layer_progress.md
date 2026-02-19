# Status: In Progress

# DEPTH Layer Progress

## Objective
- Q1~Q4 탐색 질문 생성, 진행률 관리, 영향 분석, 정보요구 분류까지 DEPTH 핵심 로직 구현

## Completed
1. `VoiceChat::QuestionGenerator`
- Q1 WHY, Q2 DECISION, Q3 IMPACT, Q4 DATA 질문 템플릿 제공

2. `VoiceChat::DepthManager`
- 답변 기록
- 진행률(progress) 계산
- 완료 여부(completed) 판정

3. `VoiceChat::DepthExplorationService`
- Q1~Q4 답변과 signal/impact/info_need를 `DepthExploration`으로 저장

4. `VoiceChat::ImpactAnalyzer`
- 5차원 영향도(emotional/relational/career/financial/psychological) 키워드 기반 판정

5. `VoiceChat::InformationNeedManager`
- 정보요구 타입(external/past/others/inner/forgotten) 분류

## Validation
- DEPTH 관련 서비스 테스트 통과
- 전체 테스트 통과 (47 tests, 186 assertions)
- 대상 파일 RuboCop 통과

## Next
- Context Orchestrator (5-layer)
- Insight generation service and natural speech formatter
