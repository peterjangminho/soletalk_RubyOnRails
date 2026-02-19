# Project_A Ingest Policy Subplan (workflow-03)

작성일: 2026-02-19  
연계 로드맵: `docs/ondev/20260219_21_project_a_ingest_policy_roadmap.md`

## Task Breakdown (TDD)

| Task | 설명 | 테스트 | 상태 |
|---|---|---|---|
| SP1 | constants/client 계약 전환 | `test/services/ontology_rag/constants_test.rb`, `test/services/ontology_rag/client_test.rb` | Done |
| SP2 | ingest 서비스 전환(`/engine/documents`) | `test/services/voice/context_file_ingest_service_test.rb` | Done |
| SP3 | `.xlsx` CSV 변환 + Gemini Vision OCR 클라이언트 추가 | `test/services/voice/context_text_extractor_test.rb`, `test/services/voice/gemini_vision_ocr_client_test.rb` | Done |
| SP4 | 업로드 UI/정책 회귀 | `test/controllers/voice/context_files_controller_test.rb`, `test/integration/voice_only_ia_test.rb` | Done |
| SP5 | 전체 회귀 | `bin/rails test`, `npm run test:js` | Done |

## Checklist
- [x] Red 테스트 작성/수정
- [x] Green 최소 구현
- [x] Refactor + RuboCop
- [x] 회귀 테스트 완료
- [x] 실행/검증 문서 동기화

## Immediate Next Action
1. `workflow-07-execution-engine` 결과 문서 작성.

## State

```text
stage: workflow-03-subplan-builder
status: PASS
resume_from: workflow-07-execution-engine
next_skill: workflow-07-execution-engine
```
