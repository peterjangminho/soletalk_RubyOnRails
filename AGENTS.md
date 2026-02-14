# AGENTS.md - Project_A 작업 가이드

이 문서는 `/Users/peter/Project/Project_A`에서 작업하는 에이전트를 위한 실행 규칙이다.  
상세 배경과 원문 기준은 `CLAUDE.md`를 따른다.

## 1) 프로젝트 정체성

- 프로젝트명: SoleTalk (Project_A)
- 성격: **Informed Fresh Build**
- 스택: Ruby on Rails 8, Hotwire(Turbo/Stimulus), Hotwire Native(Android/iOS), SQLite
- 핵심 목적: 운전 중 대화 기반으로 일상을 기록하고, LLM 기반 개인화 인사이트/기억을 생성하는 동반 앱

핵심 원칙:
- **마이그레이션이 아니라 신규 Rails 구현**이다.
- Project_B/C는 비즈니스 로직/패턴 참조용이며, 코드를 줄단위로 이식하지 않는다.
- Rails 관례(Convention over Configuration)를 기본으로 한다.

## 2) 범위와 경계

허용:
- Project_E(OntologyRAG) API 소비
- Rails 네이티브 인증/인가(OmniAuth + Rails 정책)
- Rails/Hotwire/Action Cable/Solid Queue 중심 구현

비허용:
- Project_E 백엔드 자체 수정
- Project_E의 DB(Neo4j) 직접 접근
- Project_C의 SpiceDB/Container 모델 도입
- Project_C DSS 구조 직접 재사용

## 3) 참조 전략 (Project_B/C)

그대로 참조 가능:
- 시스템 프롬프트, phase threshold, emotion keyword, API 상수 등 도메인 상수
- E/N/G/C 데이터 구조 및 그래프 관계 타입

Rails로 재작성:
- 5-Phase 전이 규칙
- 감정/에너지 추적
- Narrowing 로직
- DEPTH Q1~Q4
- Insight 생성 로직
- OntologyRAG 클라이언트 구현(패턴은 Project_C 기준)

## 4) 아키텍처 핵심

- 3-Layer 엔진:
1. Surface: 5-Phase VoiceChat
2. Depth: Q1 WHY / Q2 DECISION / Q3 IMPACT / Q4 DATA
3. Insight: 실행 가능한 가이드 문장 생성

- 컨텍스트 레이어:
1. Profile
2. Past Memory (RAG)
3. Current Session
4. Additional Info (외부 정보)
5. AI Persona

## 5) OntologyRAG 연동 규칙

기본:
- Base URL: `ENV['ONTOLOGY_RAG_BASE_URL']`
- API Key: `ENV['ONTOLOGY_RAG_API_KEY']`
- Header: `X-Source-App: soletalk-rails`, 고유 `X-Request-ID` 사용

우선 엔드포인트:
- `POST /engine/users/identify`
- `GET /engine/prompts/{google_sub}`
- `POST /engine/query`
- `POST /incar/events/batch`
- `POST /incar/conversations/{session_id}/save`

공통 식별자:
- Google OAuth의 `google_sub`를 시스템 전반의 사용자 식별 키로 사용

모델 정확성 주의:
- EngcProfile 필드명은 단수형 기준
- `emotion`, `need`, `goal`, `constraint`, `keywords`

## 6) 도메인 모델 주의사항

`DepthExploration`:
- `signal_emotion_level` (0.0~1.0)
- `signal_keywords` (배열, 복수 키워드)
- `signal_repetition_count`
- `q1_answer` ~ `q4_answer`
- `impacts`, `information_needs` (JSON)

`Insight`:
- `situation` <- Q1
- `decision` <- Q2
- `action_guide` <- Q3
- `data_info` <- Q4
- `engc_profile` (optional JSON)

## 7) 코드 작성 원칙

- Controller: 요청/응답만 담당
- Service Object: 비즈니스 로직 담당
- Model: 검증/관계/영속성 담당
- 하드코딩 금지: 매직넘버/문자열은 상수화
- 상태값은 enum/상수 모듈로 관리
- API 경로는 전용 상수 모듈로 관리
- 공통 로직은 `app/services` 또는 `concerns`로 분리

오류 처리:
- Happy path + Error path 모두 구현
- OntologyRAG 호출 시 timeout/retry/fallback 포함
- `rescue_from` 기반 전역 오류 처리 전략 고려

## 8) VoiceChat/DEPTH 실행 원칙

5-Phase:
1. Opener
2. Emotion Expansion
3. Free Speech
4. Calm
5. Re-stimulus

Narrowing:
- 열린 질문 -> 점진적 초점 질문으로 전환

Depth 진입 조건(예):
- 높은 감정 강도
- 결정 회피/불확실 키워드
- 동일 주제 반복
- 회피 패턴 감지

세션 종료 시:
- 대화/맥락 데이터 생성 후
- `/incar/conversations/{session_id}/save` 호출

## 9) 개발 워크플로우 (필수)

1. PRD/LLD/PLAN 문서를 기반으로 작업한다.
2. TDD를 기본 사이클로 따른다.
3. **사용자가 "go"라고 하면**:
   - `plan.md`에서 다음 미체크 테스트를 찾는다.
   - 테스트를 먼저 작성한다.
   - 해당 테스트를 통과시키는 최소 코드만 구현한다.

TDD 사이클:
- Red -> Green -> Refactor

Tidy First:
- 구조 변경(동작 불변)과 동작 변경(기능 변경)을 분리한다.
- 같은 커밋에 혼합하지 않는다.

커밋 규율:
- 테스트 통과 상태에서만 커밋
- 린트 경고 해소
- 작은 논리 단위 커밋
- 구조/동작 변경 라벨을 명확히

## 10) 문서 관리 규칙

파일명 (`docs/ondev/`):
- `YYYYMMDD_NN_description.md`

디렉토리 역할:
- `docs/ref/`: 외부 참조/연구 문서
- `docs/ondev/`: 현재 진행 문서
- `docs/ondev/old/`: 완료 문서 보관

## 11) GitHub/보안 운영

저장소:
- `https://github.com/peterjangminho/soletalk_RubyOnRails`

푸시 규칙:
- 작은 단위로 자주 푸시
- 실패 시 더 작은 변경으로 재시도

푸시 제외:
- `CLAUDE.md`
- 1GB 이상 대용량 파일
- `.env`, credentials, 기타 시크릿

## 12) 환경 변수 체크

필수:
- `ONTOLOGY_RAG_BASE_URL`
- `ONTOLOGY_RAG_API_KEY`
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `RAILS_ENV`
- `SECRET_KEY_BASE`

## 13) 참고 우선순위 문서

작업 전 아래 문서를 우선 확인:
- `docs/ondev/20260212_04_comprehensive_migration_assessment.md`
- `docs/ondev/20260212_01_project_b_analysis.md`
- `docs/ondev/20260212_02_project_c_analysis.md`
- `docs/ondev/20260212_03_project_e_api_analysis.md`

## 14) 에이전트 최종 체크리스트

- Fresh Build 원칙을 지켰는가?
- Rails 관례 + Service 분리를 지켰는가?
- OntologyRAG 모델/필드명을 정확히 확인했는가?
- 테스트를 먼저 작성하고 최소 구현을 했는가?
- 구조 변경과 동작 변경을 분리했는가?
- 시크릿/금지 파일을 커밋 대상에서 제외했는가?
