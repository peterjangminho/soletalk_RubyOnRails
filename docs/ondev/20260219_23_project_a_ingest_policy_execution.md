# Project_A Ingest Policy Execution (workflow-07)

작성일: 2026-02-19

## Implemented Changes

1. OntologyRAG 계약 경로 전환
- `app/services/ontology_rag/constants.rb`
- `app/services/ontology_rag/client.rb`
- `/engine/vectors/upsert` 제거, `/engine/documents` 사용

2. 업로드 ingest 서비스 전환
- `app/services/voice/context_file_ingest_service.rb`
- 파싱 텍스트를 `ContextDocument`에 저장
- OntologyRAG 전송은 `create_document` 단일 경로로 통합

3. 파싱기 추가
- `app/services/voice/context_text_extractor.rb`
- `app/services/voice/gemini_vision_ocr_client.rb`
- 일반 텍스트 passthrough
- `.xlsx` -> CSV 텍스트 변환
- OCR 입력 타입(`pdf/image`)은 Gemini Vision(`gemini-3-flash-preview`) inline_data 호출로 처리

4. 로컬 저장 스키마 확장
- `db/migrate/20260219203000_add_text_content_to_context_documents.rb`
- `context_documents.text_content`, `context_documents.text_format` 추가
- `app/models/context_document.rb` format validation 추가

5. 업로드 UI 타입 확장
- `app/views/voice/context_files/index.html.erb`
- `app/javascript/controllers/quick_upload_controller.js`
- `config/locales/en.yml`, `config/locales/ko.yml`

## Tests / Commands

```bash
bin/rails db:migrate
bin/rails test test/services/ontology_rag/constants_test.rb test/services/ontology_rag/client_test.rb test/services/voice/gemini_vision_ocr_client_test.rb test/services/voice/context_text_extractor_test.rb test/services/voice/context_file_ingest_service_test.rb test/services/voice_chat/uploaded_file_context_builder_test.rb test/controllers/voice/context_files_controller_test.rb test/integration/voice_only_ia_test.rb
XDG_CACHE_HOME=/Users/peter/Project/Project_A/.rubocop-cache bin/rubocop app/services/voice/gemini_vision_ocr_client.rb app/services/voice/context_text_extractor.rb app/services/voice/context_file_ingest_service.rb app/services/ontology_rag/client.rb app/services/ontology_rag/constants.rb app/models/context_document.rb test/services/voice/gemini_vision_ocr_client_test.rb test/services/voice/context_text_extractor_test.rb test/services/voice/context_file_ingest_service_test.rb test/services/ontology_rag/client_test.rb test/services/ontology_rag/constants_test.rb
bin/rails test
npm run test:js
```

## Result
- Rails tests: PASS (`317 runs, 1455 assertions, 0 failures`)
- JS tests: PASS (`93 tests, 0 failures`)
- RuboCop: PASS

## State

```text
stage: workflow-07-execution-engine
status: PASS
resume_from: workflow-10-verify-handoff
next_skill: workflow-10-verify-handoff
```
