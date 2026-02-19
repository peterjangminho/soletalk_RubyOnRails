# Project_A Ingest Policy Workflow Orchestrator (workflow-01)

작성일: 2026-02-19  
대상: `Project_A` (`/Users/peter/Project/Project_A`)

## Objective
- `Project_E` 무수정 원칙을 유지한 채 `Project_A` 업로드 파이프라인을 현행 계약(`POST /engine/documents`)에 정렬한다.
- 파일 업로드 후 OCR/파싱 텍스트 처리 정책을 명확히 한다: 로컬 영구 저장 범위(메타만 vs 본문 포함)와 삭제 시점.
- `google_sub` 단일 사용자 식별자를 유지하며, 연동 안정성/회귀 안정성을 우선한다.

## Constraints
1. `Project_E` 코드/DB 스키마/엔드포인트는 수정하지 않는다.
2. `Project_A`는 기존 연동 계약(`/engine/users/identify`, `/engine/objects`, `/engine/documents`, `/engine/query`)만 사용한다.
3. 보안/정책상 원본 파일(binary)은 `Project_A` 로컬 영구 저장 대상에서 제외한다.
4. 현재 dirty worktree 환경에서 선택 커밋 규율을 준수한다.

## Non-Goals
- `Project_E`에 vector-only endpoint(`POST /engine/vectors/upsert`) 추가.
- `Project_E`의 documents/vectors 저장 모델 변경.
- 업로드 기능 외 UI/음성 파이프라인 대규모 리팩터링.

## Stage Plan

| Stage | Owner | Input | Output | Done Check |
|---|---|---|---|---|
| intake | Agent | 사용자 요구 전환, 기존 workflow 문서, 코드 현황 | 목표/제약/비목표/정책 질문 목록 | Entry: 요구 수신. Exit: 핵심 정책 질문(본문 저장 여부, 보존 기간) 명시 |
| roadmap | Agent | intake 결과, `Project_A` ingest/client 코드 | 정책별 구현 경로 로드맵(메타 only/본문 저장 옵션 분리) | Entry: 정책 질문 정리. Exit: 영향 파일/테스트 범위/리스크 확정 |
| sub-plan | Agent | roadmap | phase 단위 실행 태스크 + TDD 체크포인트 | Entry: 로드맵 확정. Exit: 작업 순서와 완료조건 체크리스트화 |
| TDD | Agent | sub-plan, 기존 테스트 | Red→Green→Refactor 증적(업로드/ingest 계약 테스트) | Entry: 테스트 타깃 확정. Exit: 실패/성공 이유가 테스트로 입증 |
| execution | Agent | Green 테스트, 파일 범위 | 최소 코드 변경 적용(`Project_A` only) | Entry: Green 기준 충족. Exit: 계약 정렬 동작 + 회귀 테스트 통과 |
| gap closure | Agent | 구현/테스트 로그 | 잔여 갭/운영 리스크/정책 미결정 항목 | Entry: 구현 완료. Exit: BLOCKER와 후속 액션 우선순위 명시 |
| verification | Agent | 전체 증적 | verify handoff + 최종 판정 | Entry: gap closure 완료. Exit: PASS/FAIL/BLOCKED와 근거 문서화 |

## Risks / Blockers
- Risk: `POST /engine/documents`는 본문(`content`) 계약이므로 "본문 완전 비저장" 요구와 충돌 가능.
- Risk: SQLite/PostgreSQL 둘 다에 본문 저장하면 정책/운영 복잡도가 증가.
- Unresolved Decision (must resolve in roadmap):
  - D1: `Project_A` 로컬 DB에 본문 텍스트를 저장할지 여부 (권장 기본: 저장 안 함, 메타만 저장).
  - D2: 임시 파싱 텍스트 파일의 삭제 시점/보존 시간(권장 기본: 업로드 직후 즉시 삭제).

## Immediate Next Action
1. `workflow-02-roadmap-architect`로 D1/D2를 포함한 정책-구현 매핑 로드맵을 작성한다.
2. `Project_A`의 OntologyRAG 클라이언트/업로드 서비스에서 `vectors/upsert` 의존 여부를 고정 점검한다.
3. `workflow-03-subplan-builder`로 TDD 실행 단위를 확정한다.

## State

```text
stage: workflow-01-design-orchestrator
status: PASS
resume_from: workflow-02-roadmap-architect
next_skill: workflow-02-roadmap-architect
```
