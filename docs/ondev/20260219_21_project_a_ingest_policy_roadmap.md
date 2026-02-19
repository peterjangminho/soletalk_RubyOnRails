# Project_A Ingest Policy Roadmap (workflow-02)

작성일: 2026-02-19  
범위: `Project_A` 업로드 파이프라인 (`Project_E` 무수정)

## Objective
- OCR/파싱 텍스트를 Rails에 저장하고 OntologyRAG는 현행 계약(`POST /engine/documents`)으로 연동한다.

## Phase Plan

| Phase | 목표 | 산출물 | 완료 기준 | 상태 |
|---|---|---|---|---|
| R1 | 계약 정렬 | `OntologyRag::Constants`, `OntologyRag::Client` | `/engine/vectors/upsert` 의존 제거, `/engine/documents` 사용 | Done |
| R2 | 저장 정책 구현 | `ContextDocument` 본문 컬럼 + ingest 서비스 | 파싱 텍스트가 로컬 DB에 저장되고 OntologyRAG 문서 생성 호출 | Done |
| R3 | 파싱 확장 | `ContextTextExtractor`, `GeminiVisionOcrClient` | `.xlsx` -> CSV 텍스트 변환, OCR 입력 타입을 Gemini Vision으로 처리 | Done |
| R4 | 회귀 검증 | Rails/JS 테스트 | 업로드/클라이언트/통합 회귀 green | Done |

## Risks / Blockers
- `GEMINI_API_KEY` 미설정 시 OCR 입력 파일 처리에서 명시적 설정 에러 발생.
- 기존 vector-only 문서/증적은 historical artifact로 남기고 신규 정책 문서로 supersede 처리 필요.

## Immediate Next Action
1. `workflow-03-subplan-builder` 기준으로 TDD 실행 단위 및 테스트 순서 확정.

## State

```text
stage: workflow-02-roadmap-architect
status: PASS
resume_from: workflow-03-subplan-builder
next_skill: workflow-03-subplan-builder
```
