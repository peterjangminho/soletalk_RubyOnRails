# SoleTalk 개발 로드맵 (PLAN.md)

> **프로젝트**: SoleTalk (Project_A)
> **기술 스택**: Ruby on Rails 8 + Hotwire Native + SQLite
> **방법론**: Informed Fresh Build + TDD + 바이브코딩 6대원칙
> **작성일**: 2026-02-12
> **상태**: 마스터 로드맵 (각 Phase별 세부 계획은 별도 문서로 작성)

---

## 목차

1. [방법론 요약](#1-방법론-요약)
2. [Phase별 워크플로우](#2-phase별-워크플로우)
3. [Phase 0: 지식 추출 및 환경 설정](#phase-0-지식-추출-및-환경-설정--완료)
4. [Phase 1: Rails 프로젝트 초기화 + 기본 인프라](#phase-1-rails-프로젝트-초기화--기본-인프라)
5. [Phase 2: 인증 시스템](#phase-2-인증-시스템-omniauth-google-oauth)
6. [Phase 3: 핵심 데이터 모델](#phase-3-핵심-데이터-모델)
7. [Phase 4: OntologyRAG 클라이언트](#phase-4-ontologyrag-클라이언트)
8. [Phase 5: VoiceChat 도메인 서비스](#phase-5-voicechat-도메인-서비스)
9. [Phase 6: DEPTH Layer](#phase-6-depth-layer)
10. [Phase 7: Context Orchestrator](#phase-7-context-orchestrator)
11. [Phase 8: Insight 생성](#phase-8-insight-생성)
12. [Phase 9: 실시간 통신 (Action Cable)](#phase-9-실시간-통신-action-cable)
13. [Phase 10: UI 구현 (Turbo + Stimulus)](#phase-10-ui-구현-turbo--stimulus)
14. [Phase 11: 백그라운드 잡](#phase-11-백그라운드-잡)
15. [Phase 12: RevenueCat 구독 모델](#phase-12-revenuecat-구독-모델)
16. [Phase 13: 음성 파이프라인 (Hotwire Native Bridge)](#phase-13-음성-파이프라인-hotwire-native-bridge)
17. [Phase 14: OntologyRAG P1 엔드포인트 통합](#phase-14-ontologyrag-p1-엔드포인트-통합)
18. [Phase 15: 통합 테스트 + 최적화](#phase-15-통합-테스트--최적화)
19. [Phase 16: 배포 + 모니터링](#phase-16-배포--모니터링)
20. [요약 테이블](#요약-테이블)
21. [부록](#부록)

---

## 1. 방법론 요약

### 1.1 Informed Fresh Build (정보 참조형 신규 구축)

Project_B/C의 **코드를 직접 마이그레이션하지 않는다**. 비즈니스 로직과 도메인 지식을 추출하고, Ruby on Rails에 최적화된 설계로 처음부터 구축한다.

| 구분 | 그대로 복사 | Ruby로 재작성 | 새로 설계 |
|------|:----------:|:------------:|:---------:|
| 시스템 프롬프트 | O | - | - |
| Phase 전환 임계값/상수 | O | - | - |
| E/N/G/C 데이터 구조 | O | - | - |
| Phase 전환 엔진 | - | O | - |
| 감정/에너지 추적 | - | O | - |
| DEPTH Q1-Q4 로직 | - | O | - |
| OntologyRAG 클라이언트 | - | O | - |
| Hotwire Native 앱 | - | - | O |
| Action Cable 실시간 통신 | - | - | O |
| 인증 (OmniAuth) | - | - | O |
| 음성 파이프라인 | - | - | O |

### 1.2 바이브코딩 6대원칙

| # | 원칙 | 설명 |
|---|------|------|
| 1 | **일관된 패턴** | CRUD 패턴 분석 및 준수, RESTful 리소스 패턴 일관 적용 |
| 2 | **One Source of Truth** | 단일 진실의 원천, ENV/Rails credentials로 설정값 관리 |
| 3 | **No Hardcoding** | Magic Numbers/Strings 상수화, 상태값 enum/constant 관리 |
| 4 | **Error Handling** | Happy Path + Error Path 모두 커버, rescue_from 글로벌 처리 |
| 5 | **Single Responsibility** | Controller: 요청/응답, Service: 비즈니스 로직, Model: 데이터 검증 |
| 6 | **Shared Module** | 재사용 서비스 app/services/, 공통 모듈 concerns/ |

### 1.3 Kent Beck TDD

```
Red → Green → Refactor

1. 가장 단순한 실패 테스트 작성 (Red)
2. 테스트 통과를 위한 최소한의 코드 구현 (Green)
3. 테스트 통과 후 리팩터링 (Refactor)
4. 반복
```

**Tidy First 원칙**:
- **구조적 변경**: 동작 변경 없는 코드 정리 (리네이밍, 메서드 추출)
- **행동적 변경**: 실제 기능 추가/수정
- 두 유형을 같은 커밋에 **절대 혼합하지 않는다**
- 구조적 변경을 항상 먼저 수행한다

**커밋 규율**:
- 모든 테스트 통과 시에만 커밋
- 린터 경고 해결 후 커밋
- 단일 논리적 작업 단위로 커밋
- 구조적/행동적 변경 라벨 명시

---

## 2. Phase별 워크플로우

모든 Phase는 아래의 워크플로우를 **반드시** 따른다:

```
Phase 세부계획 작성 (docs/ondev/YYYYMMDD_NN_phase_X_plan.md)
  → TDD 구현 (Red → Green → Refactor)
    → 검증 (Verification: 모든 테스트 통과 확인)
      → Gap 분석 (누락된 테스트/기능 식별)
        → 재구현 (Gap 채우기)
          → Phase E2E 테스트
            → 디버깅
              → 재구현
                → E2E 테스트 통과 ✅
```

### Phase 시작 전 체크리스트

- [ ] Phase 세부 계획 문서 작성 완료
- [ ] 이전 Phase의 모든 테스트 통과 확인
- [ ] 참조 소스 코드 사전 분석 완료
- [ ] 예상 테스트 목록 작성

### Phase 완료 체크리스트

- [ ] 모든 단위 테스트 통과
- [ ] E2E 테스트 통과
- [ ] Rubocop 경고 없음
- [ ] Brakeman 보안 이슈 없음
- [ ] 구조적/행동적 변경 분리 커밋 완료
- [ ] Phase 결과 문서 업데이트

---

## Phase 0: 지식 추출 및 환경 설정 ✅ (완료)

**목표**: 기존 프로젝트 분석 및 개발 환경 준비
**상태**: 완료

- [x] Project_B 분석 완료 → `docs/ondev/20260212_01_project_b_analysis.md`
  - VoiceChatManager.kt (1,322줄 God Class) 분석
  - 핵심 비즈니스 파일 ~30개 식별
  - TypeScript 순수 비즈니스 로직 (phaseTransitionService, emotionEnergyService 등) 추출 대상 확정
  - 비즈니스 로직 재사용율 ~95% 확인
- [x] Project_C 분석 완료 → `docs/ondev/20260212_02_project_c_analysis.md`
  - ontology-rag.service.ts (1,545줄) "골드 스탠다드" 확인
  - google_sub 크로스앱 식별 패턴 분석
  - ENGC 이벤트 기록 패턴 매핑
  - Container/SpiceDB/DSS는 Project_A 범위 밖 확인
- [x] Project_E API 분석 완료 → `docs/ondev/20260212_03_project_e_api_analysis.md`
  - 15+ 엔드포인트 그룹 전체 스펙 분석
  - P0/P1/P2 우선순위 분류
  - E/N/G/C 파라미터명 **단수형** 확인 (emotion, need, goal, constraint)
  - 엔드포인트별 타임아웃/리트라이 권장 사항 확인
  - Rate Limit: 1,000 req/hour per key
- [x] 종합 마이그레이션 평가 완료 → `docs/ondev/20260212_04_comprehensive_migration_assessment.md`
  - "정보 참조형 신규 구축" 최종 결정 (가중 평균 8.80/10 vs 직접 마이그레이션 4.25/10)
  - 리스크 분석 완료 (음성 파이프라인: 높음, Context 모델 통합: 중간)
- [x] CLAUDE.md 작성 완료
  - 전체 아키텍처 설계
  - Rails 프로젝트 구조 정의
  - OntologyRAG API 통합 설계
  - 도메인 모델 정의
  - VoiceChat Engine 설계
- [x] 개발 환경 설정
  - Ruby 3.4.8
  - Rails 8.1.2
  - mise (버전 관리)

---

## Phase 1: Rails 프로젝트 초기화 + 기본 인프라

**목표**: 기본 Rails 앱 생성 및 개발 인프라 설정
**난이도**: 낮음
**예상 테스트**: 5-8개
**참조**: CLAUDE.md (프로젝트 구조, Gemfile)
**세부 계획**: `docs/ondev/YYYYMMDD_NN_phase_1_plan.md` (Phase 시작 시 작성)

### 1.1 프로젝트 생성

- [ ] `rails new` 프로젝트 생성 (SQLite3 기본)
- [ ] Ruby 버전 확인 (.ruby-version)
- [ ] 기본 디렉토리 구조 확인

### 1.2 Gemfile 구성

- [ ] 코어 Gem 추가
  - `turbo-rails`, `stimulus-rails` (Hotwire)
  - `solid_cache`, `solid_queue`, `solid_cable` (SQLite 인프라)
  - `jbuilder` (JSON 빌더)
- [ ] 인증 Gem 추가
  - `omniauth`, `omniauth-google-oauth2`
  - `omniauth-rails_csrf_protection`
- [ ] HTTP 클라이언트 Gem 추가
  - `faraday`, `faraday-retry`
- [ ] 개발/테스트 Gem 추가
  - `debug`, `brakeman`, `rubocop-rails-omakase`
  - `webmock`, `vcr`
  - `dotenv-rails`
- [ ] `bundle install` 실행 및 확인

### 1.3 기본 설정

- [ ] `.env` 파일 설정 (dotenv-rails)
  - `ONTOLOGY_RAG_BASE_URL`
  - `ONTOLOGY_RAG_API_KEY`
  - `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`
- [ ] `.env`를 `.gitignore`에 추가
- [ ] 기본 레이아웃 설정 (`app/views/layouts/application.html.erb`)
- [ ] 기본 라우팅 설정 (`config/routes.rb`)
  - root 페이지 설정
  - health check 엔드포인트

### 1.4 코드 품질 도구

- [ ] Rubocop 설정 (`.rubocop.yml`)
  - `rubocop-rails-omakase` 프리셋 기반
- [ ] Brakeman 설정 (보안 스캔)
- [ ] CI 기본 설정 (`.github/workflows/ci.yml`)
  - 테스트 실행
  - Rubocop 체크
  - Brakeman 스캔

### 1.5 테스트 인프라

- [ ] Minitest 기본 설정 확인
- [ ] `test/test_helper.rb` 설정
  - WebMock 설정
  - VCR 설정 (카세트 디렉토리)
- [ ] 헬스 체크 테스트 작성

### Phase 1 검증 기준

- [ ] `rails server` 정상 기동
- [ ] 기본 페이지 렌더링
- [ ] `rails test` 전체 통과
- [ ] `rubocop` 경고 없음
- [ ] `brakeman` 이슈 없음

---

## Phase 2: 인증 시스템 (OmniAuth Google OAuth)

**목표**: Google OAuth 기반 사용자 인증 + google_sub 추출
**난이도**: 낮음
**예상 테스트**: 8-12개
**참조**: Project_C `authService.ts`, `googleSubService.ts`
**세부 계획**: `docs/ondev/YYYYMMDD_NN_phase_2_plan.md` (Phase 시작 시 작성)

### 2.1 User 모델

- [ ] User 마이그레이션 생성
  - `google_sub` (string, unique, not null) - 핵심 식별자
  - `email` (string)
  - `name` (string)
  - `avatar_url` (string, nullable)
  - `provider` (string, default: "google")
  - `timestamps`
- [ ] User 모델 구현
  - 유효성 검증 (google_sub presence, uniqueness)
  - `find_or_create_from_omniauth(auth)` 클래스 메서드
- [ ] User 모델 테스트
  - 유효한 User 생성
  - google_sub 중복 방지
  - OmniAuth 데이터로부터 생성

### 2.2 OmniAuth 설정

- [ ] OmniAuth initializer 설정 (`config/initializers/omniauth.rb`)
  - Google OAuth2 provider 등록
  - CSRF 보호 설정
- [ ] OmniAuth 콜백 라우팅
  - `GET /auth/google_oauth2/callback`
  - `GET /auth/failure`

### 2.3 Auth 서비스

- [ ] `Auth::GoogleSubExtractor` 서비스 구현
  - OmniAuth auth hash에서 google_sub (uid) 추출
  - 유효성 검증 (nil, 빈 문자열 체크)
- [ ] `Auth::GoogleSubExtractor` 테스트
  - 정상 추출 케이스
  - nil auth hash 에러 처리
  - uid 누락 에러 처리

### 2.4 Sessions 컨트롤러

- [ ] `Auth::OmniauthCallbacksController` 구현
  - `#google_oauth2` 액션 (로그인 성공)
  - `#failure` 액션 (로그인 실패)
- [ ] `SessionsController` 구현
  - `#destroy` 액션 (로그아웃)
- [ ] 세션 관리 헬퍼
  - `current_user` 메서드
  - `logged_in?` 메서드
  - `authenticate_user!` before_action

### 2.5 인증 필터

- [ ] `ApplicationController`에 인증 헬퍼 추가
  - `before_action :authenticate_user!` (기본)
  - `skip_before_action` (공개 페이지)
- [ ] 미인증 사용자 리다이렉트 로직
- [ ] 인증 흐름 통합 테스트

### 2.6 OntologyRAG 사용자 등록 연동

- [ ] 로그인 성공 시 OntologyRAG identify_user 호출 (비동기)
  - `POST /engine/users/identify`
  - `google_sub`, `app_source: "incar_companion"`
- [ ] 사용자 등록 실패 시 graceful degradation (로그인은 성공)

### Phase 2 검증 기준

- [ ] Google OAuth 로그인/로그아웃 플로우 동작
- [ ] google_sub 정상 추출 및 저장
- [ ] 미인증 사용자 리다이렉트 동작
- [ ] OntologyRAG 사용자 등록 연동 (에러 시 graceful)
- [ ] 전체 테스트 통과

---

## Phase 3: 핵심 데이터 모델

**목표**: 도메인 핵심 모델 생성 및 관계 설정
**난이도**: 낮음
**예상 테스트**: 10-15개
**참조**: Project_B `domain/model/`, CLAUDE.md 도메인 모델 섹션
**세부 계획**: `docs/ondev/YYYYMMDD_NN_phase_3_plan.md` (Phase 시작 시 작성)

### 3.1 Session 모델 (대화 세션)

- [ ] Session 마이그레이션 생성
  - `user_id` (references, not null)
  - `title` (string, nullable)
  - `status` (string, default: "active") - enum: active, completed, abandoned
  - `started_at` (datetime)
  - `ended_at` (datetime, nullable)
  - `session_type` (string) - 출근/퇴근/기타
  - `metadata` (json, nullable) - 날씨, GPS 등
  - `timestamps`
- [ ] Session 모델 구현
  - belongs_to :user
  - has_many :messages
  - has_one :voice_chat_data
  - status enum 정의
  - 유효성 검증
- [ ] Session 모델 테스트

### 3.2 Message 모델 (개별 메시지)

- [ ] Message 마이그레이션 생성
  - `session_id` (references, not null)
  - `role` (string, not null) - enum: user, assistant, system
  - `content` (text, not null)
  - `message_type` (string, default: "text") - text, voice, system
  - `metadata` (json, nullable) - 감정 분석 결과 등
  - `timestamps`
- [ ] Message 모델 구현
  - belongs_to :session
  - role enum 정의
  - 유효성 검증
  - 스코프: by_role, recent
- [ ] Message 모델 테스트

### 3.3 VoiceChatData 모델 (VoiceChat 세션 데이터)

- [ ] VoiceChatData 마이그레이션 생성
  - `session_id` (references, not null, unique)
  - `current_phase` (string, default: "opener") - 5-Phase enum
  - `emotion_level` (float, default: 0.0) - 0.0 ~ 1.0
  - `energy_level` (float, default: 0.5) - 0.0 ~ 1.0
  - `turn_count` (integer, default: 0)
  - `weather_info` (json, nullable)
  - `gps_info` (json, nullable)
  - `phase_history` (json, default: [])
  - `timestamps`
- [ ] VoiceChatData 모델 구현
  - belongs_to :session
  - has_many :depth_explorations
  - phase enum 정의 (opener, emotion_expansion, free_speech, calm, re_stimulus)
  - 유효성 검증 (emotion_level 0.0..1.0 범위)
- [ ] VoiceChatData 모델 테스트

### 3.4 DepthExploration 모델 (DEPTH Q1-Q4)

- [ ] DepthExploration 마이그레이션 생성
  - `voice_chat_data_id` (references, not null)
  - `signal_emotion_level` (float) - 0.0 ~ 1.0
  - `signal_keywords` (json, default: []) - Array of String (복수형!)
  - `signal_repetition_count` (integer, default: 0)
  - `current_question` (string, nullable) - q1_why, q2_decision, q3_impact, q4_data
  - `q1_answer` (text, nullable) - WHY (진짜 감정)
  - `q2_answer` (text, nullable) - DECISION (의사결정)
  - `q3_answer` (text, nullable) - IMPACT (영향)
  - `q4_answer` (text, nullable) - DATA (필요 정보)
  - `impacts` (json, default: []) - ImpactAnalysis array
  - `information_needs` (json, default: []) - InformationNeed array
  - `status` (string, default: "active") - active, completed, abandoned
  - `timestamps`
- [ ] DepthExploration 모델 구현
  - belongs_to :voice_chat_data
  - has_many :insights
  - current_question enum 정의
  - status enum 정의
  - 유효성 검증
  - `completed?`, `progress_percentage` 헬퍼 메서드
- [ ] DepthExploration 모델 테스트

### 3.5 Insight 모델 (INSIGHT Layer)

- [ ] Insight 마이그레이션 생성
  - `depth_exploration_id` (references, not null)
  - `user_id` (references, not null)
  - `situation` (text) - Q1.WHY 기반 (현재 상황)
  - `decision` (text) - Q2.DECISION 기반 (의사결정)
  - `action_guide` (text) - Q3.IMPACT 기반 (행동 가이드)
  - `data_info` (text) - Q4.DATA 기반 (필요 정보)
  - `natural_text` (text) - 자연어 변환 결과
  - `engc_profile` (json, nullable) - E/N/G/C 프로필
  - `context_snapshot` (json, nullable) - 생성 시점 컨텍스트
  - `timestamps`
- [ ] Insight 모델 구현
  - belongs_to :depth_exploration
  - belongs_to :user
  - 유효성 검증
  - `generated?`, `to_natural_speech` 헬퍼 메서드
- [ ] Insight 모델 테스트

### 3.6 Setting 모델 (사용자 설정)

- [ ] Setting 마이그레이션 생성
  - `user_id` (references, not null, unique)
  - `language` (string, default: "ko")
  - `voice_speed` (float, default: 1.0)
  - `notification_enabled` (boolean, default: true)
  - `preferred_ai_persona` (string, default: "default")
  - `preferences` (json, default: {})
  - `timestamps`
- [ ] Setting 모델 구현
  - belongs_to :user
  - 유효성 검증
- [ ] Setting 모델 테스트

### 3.7 모델 간 관계 통합

- [ ] User 모델에 관계 추가
  - has_many :sessions
  - has_many :insights
  - has_one :setting
- [ ] 관계 무결성 테스트
  - 사용자 삭제 시 연관 데이터 처리 (dependent 설정)
  - 세션 → 메시지 → VoiceChatData 캐스케이드
- [ ] 데이터베이스 인덱스 설정
  - `google_sub` unique index
  - `session_id` foreign key indexes
  - `user_id` foreign key indexes

### Phase 3 검증 기준

- [ ] 모든 마이그레이션 정상 실행 (`rails db:migrate`)
- [ ] 모든 모델 유효성 검증 통과
- [ ] 관계 설정 정상 동작 (has_many, belongs_to)
- [ ] 전체 테스트 통과

---

## Phase 4: OntologyRAG 클라이언트

**목표**: Faraday 기반 HTTP 클라이언트 구현 (P0 엔드포인트)
**난이도**: 중간
**예상 테스트**: 15-20개
**참조**: Project_C `ontology-rag.service.ts` (골드 스탠다드), Project_E API 문서
**세부 계획**: `docs/ondev/YYYYMMDD_NN_phase_4_plan.md` (Phase 시작 시 작성)

### 4.1 상수 정의

- [ ] `app/services/ontology_rag/constants.rb` 구현
  - BASE_URL: `ENV['ONTOLOGY_RAG_BASE_URL']`
  - API_KEY: `ENV['ONTOLOGY_RAG_API_KEY']`
  - SOURCE_APP: `"soletalk-rails"`
  - APP_SOURCE: `"incar_companion"` (Project_B 호환)
  - 엔드포인트 상수
    - IDENTIFY_USER: `/engine/users/identify`
    - GET_PROFILE: `/engine/prompts`
    - QUERY: `/engine/query`
    - BATCH_EVENTS: `/incar/events/batch`
    - SAVE_CONVERSATION: `/incar/conversations`
    - GET_CACHED_PROFILE: `/incar/profile`
  - 타임아웃 상수 (엔드포인트별)
    - DEFAULT_TIMEOUT: 30초
    - IDENTIFY_TIMEOUT: 10초
    - PROFILE_TIMEOUT: 15초
    - QUERY_TIMEOUT: 45초
    - BATCH_TIMEOUT: 20초
    - SAVE_TIMEOUT: 30초
  - 리트라이 설정
    - MAX_RETRIES: 3
    - RETRY_INTERVAL: 0.5초
    - RETRY_BACKOFF_FACTOR: 2
    - RETRYABLE_STATUSES: [408, 429, 500, 502, 503, 504]
- [ ] Constants 테스트 (환경변수 로딩, 기본값)

### 4.2 모델 정의 (요청/응답)

- [ ] `app/services/ontology_rag/models.rb` 구현
  - **요청 모델**
    - `IdentifyUserRequest` (google_sub, app_source, external_user_id)
    - `BatchEventsRequest` (google_sub, events: [])
    - `SaveConversationRequest` (session_id, messages, metadata)
    - `QueryRequest` (question, google_sub, limit)
  - **응답 모델**
    - `IdentifyUserResponse` (id, google_sub, app_source, is_new)
    - `ProfileResponse` (google_sub, emotion_patterns, needs, goals, constraints)
    - `ProfileItem` (id, timestamp, text, description)
    - `EmotionPattern` (emotion_type, count, avg_intensity, recent_occurrence)
    - `QueryResponse` (answer, context, sources)
    - `BatchEventsResponse` (processed_count, errors)
    - `ErrorResponse` (detail, status_code)
  - **E/N/G/C 이벤트 모델**
    - `EngcEvent` (google_sub, event_type, engc_category, data)
    - **주의**: engc_category 값은 **단수형** 사용
      - `"emotion"` (NOT "emotions")
      - `"need"` (NOT "needs")
      - `"goal"` (NOT "goals")
      - `"constraint"` (NOT "constraints")
- [ ] Models 테스트
  - 각 모델의 직렬화/역직렬화
  - 필수 필드 누락 시 에러
  - E/N/G/C 파라미터 단수형 검증

### 4.3 HTTP 클라이언트 기본 구조

- [ ] `app/services/ontology_rag/client.rb` 기본 구조 구현
  - Faraday 연결 설정 (connection pool)
  - 공통 헤더 설정
    - `X-API-Key`: ENV에서 로드
    - `X-Source-App`: "soletalk-rails"
    - `X-Request-ID`: "soletalk-{timestamp}"
    - `Content-Type`: "application/json"
  - 리트라이 미들웨어 설정 (faraday-retry)
  - 타임아웃 설정 (엔드포인트별 분리)
  - 에러 핸들링 기본 구조
    - `OntologyRag::ApiError` 커스텀 에러 클래스
    - `OntologyRag::TimeoutError`
    - `OntologyRag::AuthenticationError`
    - `OntologyRag::RateLimitError`
- [ ] Client 기본 구조 테스트 (연결 설정, 헤더)

### 4.4 P0 엔드포인트 구현

- [ ] `#identify_user(google_sub:, app_source: "incar_companion")` 구현
  - POST `/engine/users/identify`
  - 요청: `{google_sub, app_source}`
  - 응답: `IdentifyUserResponse`
  - 에러 처리: 500 → OntologyRag::ApiError
- [ ] identify_user 테스트 (WebMock)
  - 성공 케이스 (신규 사용자, 기존 사용자)
  - 실패 케이스 (서버 에러, 타임아웃)

- [ ] `#get_profile(google_sub:, limit: 50)` 구현
  - GET `/engine/prompts/{google_sub}?limit={limit}`
  - 응답: `ProfileResponse`
  - 에러 처리: 500 → OntologyRag::ApiError
- [ ] get_profile 테스트 (WebMock)
  - 성공 케이스 (프로필 존재, 빈 프로필)
  - 실패 케이스 (서버 에러, 타임아웃)

- [ ] `#batch_save_events(google_sub:, events:)` 구현
  - POST `/incar/events/batch`
  - 요청: `{google_sub, events: [EngcEvent]}`
  - 응답: `BatchEventsResponse`
  - E/N/G/C 이벤트 형식 검증
- [ ] batch_save_events 테스트 (WebMock)
  - 성공 케이스 (단일/복수 이벤트)
  - 실패 케이스 (잘못된 이벤트 형식, 서버 에러)
  - **단수형 파라미터 검증** (emotion, need, goal, constraint)

- [ ] `#save_conversation(session_id:, messages:, metadata: {})` 구현
  - POST `/incar/conversations/{session_id}/save`
  - 요청: 전체 대화 내용 + 메타데이터
  - 응답: 성공/실패
- [ ] save_conversation 테스트 (WebMock)
  - 성공 케이스
  - 실패 케이스 (서버 에러, 타임아웃)

### 4.5 VCR 카세트 설정

- [ ] VCR 설정 (`test/support/vcr_setup.rb`)
  - API 키 필터링 (민감 정보 마스킹)
  - 카세트 디렉토리: `test/vcr_cassettes/ontology_rag/`
  - 녹화 모드 설정 (:once, :new_episodes)
- [ ] 각 엔드포인트별 VCR 카세트 파일 생성

### Phase 4 검증 기준

- [ ] 모든 P0 엔드포인트 WebMock 테스트 통과
- [ ] 리트라이 로직 동작 확인
- [ ] 타임아웃 처리 확인
- [ ] 에러 클래스 계층 구조 동작
- [ ] E/N/G/C 파라미터 단수형 일관성
- [ ] 전체 테스트 통과

---

## Phase 5: VoiceChat 도메인 서비스

**목표**: VoiceChat 엔진 핵심 서비스 구현 (5-Phase 상태 머신 + 감정 추적)
**난이도**: 중간
**예상 테스트**: 15-20개
**참조**: Project_B `phaseTransitionService.ts`, `emotionEnergyService.ts`, `narrowingService.ts`
**세부 계획**: `docs/ondev/YYYYMMDD_NN_phase_5_plan.md` (Phase 시작 시 작성)

### 5.1 Phase 상수 및 설정

- [ ] `app/services/voice_chat/constants.rb` 구현
  - Phase 정의: OPENER, EMOTION_EXPANSION, FREE_SPEECH, CALM, RE_STIMULUS
  - Phase 전환 임계값 (Project_B `PHASE_TRANSITION_CONFIG`에서 복사)
    - 시간 기반 전환 타이머
    - 감정 강도 임계값
    - 턴 카운트 임계값
  - 감정 키워드 목록 (한국어) - Project_B에서 복사
  - DEPTH 진입 조건 상수
    - DEPTH_EMOTION_THRESHOLD: 0.8
    - DEPTH_REPETITION_THRESHOLD: 3
    - DEPTH_KEYWORDS: ["모르겠어", "고민이야", "어떻게 해야 할지", ...]
- [ ] Constants 테스트

### 5.2 Phase 전환 엔진

- [ ] `app/services/voice_chat/phase_transition_engine.rb` 구현
  - `#initialize(voice_chat_data)` - 현재 상태 로드
  - `#current_phase` - 현재 Phase 반환
  - `#can_transition?(target_phase)` - 전환 가능 여부
  - `#transition!(target_phase)` - Phase 전환 실행
  - `#evaluate_transition(message, emotion_data)` - 메시지 기반 자동 전환 평가
  - Phase 전환 규칙 구현 (Project_B 로직 참조)
    - Opener → Emotion Expansion: 첫 사용자 발화 감지
    - Emotion Expansion → Free Speech: 감정 확장 완료 / 시간 초과
    - Free Speech → Calm: 감정 안정화 신호 / 시간 초과
    - Calm → Re-stimulus: 안정 상태 확인
    - Any Phase → Depth: DEPTH 진입 조건 충족 시
  - Phase 히스토리 기록
- [ ] Phase 전환 엔진 테스트
  - 정상 전환 시나리오
  - 비정상 전환 방지 (잘못된 순서)
  - 시간 기반 전환
  - 감정 기반 전환
  - DEPTH 진입 조건 테스트

### 5.3 감정/에너지 추적

- [ ] `app/services/voice_chat/emotion_tracker.rb` 구현
  - `#initialize(voice_chat_data)` - 현재 상태 로드
  - `#update_emotion(emotion_type:, intensity:, trigger: nil)` - 감정 업데이트
  - `#update_energy(delta:)` - 에너지 레벨 변경
  - `#current_emotion_level` - 현재 감정 강도 반환
  - `#current_energy_level` - 현재 에너지 레벨 반환
  - `#emotion_trend` - 감정 변화 추이 계산
  - `#is_emotion_intense?` - 높은 감정 강도 확인 (> 0.7)
  - 감정 레벨 범위 제한 (0.0 ~ 1.0)
  - 에너지 레벨 감쇠 로직
- [ ] 감정/에너지 추적 테스트
  - 감정 업데이트 및 범위 검증
  - 에너지 변화 계산
  - 감정 추이 분석
  - 경계값 테스트 (0.0, 1.0)

### 5.4 Narrowing 서비스

- [ ] `app/services/voice_chat/narrowing_service.rb` 구현
  - `#initialize(voice_chat_data)` - 현재 상태 로드
  - `#question_type_for(phase:, turn_count:)` - 질문 타입 결정
  - `#narrowing_level` - 현재 좁히기 수준 (0.0 ~ 1.0)
  - Narrowing 원칙 구현 (Project_B 참조)
    - 초기: 개방형 질문 ("오늘 하루 어땠어요?")
    - 중기: 반개방형 질문 ("그 상황에서 어떤 느낌이었어요?")
    - 후기: 구체적 질문 ("~해보시는 건 어떨까요?")
  - Phase별 질문 전략 매핑
- [ ] Narrowing 서비스 테스트
  - 초기/중기/후기 질문 타입 전환
  - Phase별 적절한 질문 타입

### 5.5 DEPTH 신호 감지

- [ ] `app/services/voice_chat/depth_signal_detector.rb` 구현
  - `#initialize(voice_chat_data)` - 현재 상태 로드
  - `#should_enter_depth?(message:, emotion_data:)` - DEPTH 진입 판단
  - `#detect_signals(message)` - 신호 감지 결과 반환
  - DEPTH 진입 조건 구현
    - 감정 강도 > 0.8 (`emotion_level > DEPTH_EMOTION_THRESHOLD`)
    - 키워드 감지: "모르겠어", "고민이야", "어떻게 해야 할지" 등
    - 동일 주제 3회 이상 반복 감지
    - 회피 패턴 감지 (주제 회피, 답변 회피)
  - 신호 가중치 계산 (복합 신호 시 진입 확률 상승)
- [ ] DEPTH 신호 감지 테스트
  - 단일 신호 감지 (감정, 키워드, 반복, 회피)
  - 복합 신호 감지
  - 신호 미감지 (정상 대화)
  - 경계값 테스트 (emotion_level = 0.8 정확히)

### Phase 5 검증 기준

- [ ] 5-Phase 전환 상태 머신 정상 동작
- [ ] 감정/에너지 추적 정확도
- [ ] Narrowing 서비스 질문 타입 적절성
- [ ] DEPTH 신호 감지 정확도
- [ ] Phase 전환 + DEPTH 진입 통합 시나리오 테스트
- [ ] 전체 테스트 통과

---

## Phase 6: DEPTH Layer

**목표**: 4 Core Questions 프레임워크 (Q1-Q4) 구현
**난이도**: 중상
**예상 테스트**: 15-20개
**참조**: Project_B `domain/depth/`, VoiceChat Engine v2 문서 (DEPTH 상세 설계)
**세부 계획**: `docs/ondev/YYYYMMDD_NN_phase_6_plan.md` (Phase 시작 시 작성)

### 6.1 질문 생성기

- [ ] `app/services/voice_chat/question_generator.rb` 구현
  - `#initialize(depth_exploration)` - 현재 탐색 상태 로드
  - `#generate_question(phase:, context: {})` - 질문 생성
  - **Q1.WHY (UNCOVER)** - 진짜 감정 발굴
    - 반영 기법: "~라고 느끼신 거네요... 그 느낌이 어디서 오는 것 같아요?"
    - 신체 감각: "그 생각하면 몸 어디가 반응해요?"
    - 시간 확장: "비슷한 느낌 받았던 적 있어요?"
  - **Q2.DECISION (CRYSTALLIZE)** - 의사결정 결정화
    - "만약 지금 뭔가 하나만 바꿀 수 있다면, 뭘 바꾸고 싶어요?"
    - "그걸 안 하고 있는 이유가 있을까요?"
  - **Q3.IMPACT (MEASURE)** - 영향 측정
    - 차원별 질문: 감정적/관계적/커리어/금전적/심리적
    - 시나리오: Best Case / Worst Case / Most Likely
  - **Q4.DATA (CONNECT)** - 필요 정보 연결
    - 정보 유형: 외부 정보, 과거 경험, 타인 경험, 내면 정보
    - 연결 발견: "이거랑 예전에 말씀하셨던 [X]가 연결되는 것 같은데..."
  - 질문 다양성 (동일 질문 반복 방지)
  - 컨텍스트 기반 질문 개인화
- [ ] 질문 생성기 테스트
  - 각 Q1-Q4 Phase별 질문 생성
  - 질문 다양성 검증
  - 컨텍스트 반영 검증

### 6.2 DEPTH 진입/종료 관리

- [ ] `app/services/voice_chat/depth_manager.rb` 구현
  - `#enter_depth!(signal_data:)` - DEPTH 진입
    - DepthExploration 레코드 생성
    - 신호 데이터 저장 (emotion_level, keywords, repetition_count)
    - 현재 질문을 Q1으로 설정
  - `#advance_question!` - 다음 질문으로 진행
    - Q1 → Q2 → Q3 → Q4 순차 진행
    - 상황에 따른 질문 순서 조정 (Q2가 이미 명확하면 Q1 먼저)
  - `#exit_depth!(reason:)` - DEPTH 종료
    - 완료 (Q4까지 답변)
    - 사용자 요청에 의한 종료
    - 타임아웃
  - `#current_depth_state` - 현재 DEPTH 상태 반환
  - `#should_exit?` - 종료 조건 평가
- [ ] DEPTH 진입/종료 테스트
  - 정상 진입 → Q1~Q4 → 종료 흐름
  - 중간 종료 시나리오
  - 질문 순서 변경 시나리오

### 6.3 DepthExploration 업데이트 서비스

- [ ] `app/services/voice_chat/depth_exploration_service.rb` 구현
  - `#record_answer(question:, answer:)` - Q1-Q4 답변 기록
  - `#update_signal(emotion_level:, keywords: [], repetition_count: 0)` - 신호 업데이트
  - `#calculate_progress` - 진행률 계산 (0~100%)
  - `#is_ready_for_insight?` - 인사이트 생성 가능 여부
- [ ] DepthExploration 업데이트 서비스 테스트

### 6.4 Impact 분석 서비스

- [ ] `app/services/voice_chat/impact_analyzer.rb` 구현
  - `#analyze(depth_exploration:, q3_response:)` - Q3 응답 기반 영향 분석
  - 5차원 영향 매트릭스 구성
    - emotional (감정적), relational (관계적), career (커리어)
    - financial (금전적), psychological (심리적)
  - 각 차원별 Best/Worst/Likely 시나리오 수치화 (-5 ~ +5)
  - impacts JSON 형식으로 DepthExploration에 저장
- [ ] Impact 분석 서비스 테스트

### 6.5 Information Need 관리 서비스

- [ ] `app/services/voice_chat/information_need_manager.rb` 구현
  - `#identify_needs(depth_exploration:, q4_response:)` - Q4 응답 기반 정보 필요 식별
  - 정보 유형 분류
    - external (외부 정보 - 웹 검색)
    - past_experience (과거 경험 - RAG 검색)
    - others_experience (타인 경험)
    - inner_info (내면 정보 - Q1 참조)
    - forgotten_info (잊은 정보 - RAG 검색)
  - information_needs JSON 형식으로 DepthExploration에 저장
  - 정보 수집 우선순위 결정
- [ ] Information Need 관리 서비스 테스트

### Phase 6 검증 기준

- [ ] Q1-Q4 전체 흐름 통합 테스트
- [ ] DEPTH 진입 → 질문 → 답변 → 진행 → 종료 E2E
- [ ] Impact 분석 정확도
- [ ] Information Need 분류 정확도
- [ ] 전체 테스트 통과

---

## Phase 7: Context Orchestrator

**목표**: 5계층 컨텍스트 조합 시스템 구현
**난이도**: 중간
**예상 테스트**: 10-15개
**참조**: Project_B `contextOrchestrator.ts` (통합 설계), CLAUDE.md Context Layering
**세부 계획**: `docs/ondev/YYYYMMDD_NN_phase_7_plan.md` (Phase 시작 시 작성)

### 7.1 Context Orchestrator 코어

- [ ] `app/services/voice_chat/context_orchestrator.rb` 구현
  - `#initialize(user:, session:, voice_chat_data:)` - 초기화
  - `#build_context` - 5계층 컨텍스트 조합
  - `#build_context_for_phase(phase:)` - Phase별 최적 컨텍스트
  - **Layer 1: Profile (10%)** - OntologyRAG 프로필
    - OntologyRag::Client#get_profile 호출
    - E/N/G/C 요약 텍스트 생성
    - 관심사 키워드 추출
  - **Layer 2: Past Memory (20%)** - OntologyRAG hybrid search
    - OntologyRag::Client#query 호출 (Phase 14에서 구현)
    - 관련 과거 대화 검색
    - 유사 상황/감정 패턴 매칭
    - (Phase 14 전까지는 stub 처리)
  - **Layer 3: Current Session (30%)** - 현재 대화
    - 현재 세션의 최근 메시지
    - VoiceChatData 상태 (Phase, 감정, 에너지)
    - DepthExploration 진행 상태
  - **Layer 4: Additional Info (15%)** - 외부 정보
    - 수집된 외부 정보 (Type A-D)
    - (Phase 11/14에서 완전 구현)
  - **Layer 5: AI Persona (15%)** - AI 성격/지침
    - 시스템 프롬프트 (Project_B에서 복사)
    - Phase별 행동 지침
    - Narrowing 수준별 응답 스타일
- [ ] Context Orchestrator 코어 테스트

### 7.2 토큰 예산 관리

- [ ] `app/services/voice_chat/token_budget_manager.rb` 구현
  - `#initialize(total_budget:)` - 총 토큰 예산 설정
  - `#allocate(layer_ratios:)` - 계층별 토큰 할당
  - `#truncate_to_budget(text:, budget:)` - 예산 내 텍스트 자르기
  - `#estimate_tokens(text)` - 토큰 수 추정 (문자 수 기반 간이 계산)
  - 계층별 기본 비율: 10% / 20% / 30% / 15% / 15% (+10% 여유)
  - 동적 비율 조정 (사용 불가 계층의 예산 재분배)
- [ ] 토큰 예산 관리 테스트
  - 기본 할당 계산
  - 동적 재분배
  - 텍스트 트렁케이션

### 7.3 컨텍스트 캐싱

- [ ] 컨텍스트 캐싱 전략 구현
  - Layer 1 (Profile): 세션 시작 시 캐시 → 세션 종료까지 유지
  - Layer 2 (Past Memory): 질문 단위 캐시 → 5분 TTL
  - Layer 3 (Current Session): 캐시 없음 (실시간)
  - Layer 4 (Additional Info): 수집 시 캐시 → 1시간 TTL
  - Layer 5 (AI Persona): 앱 레벨 캐시 (변경 시에만 갱신)
  - Rails.cache (Solid Cache) 활용
- [ ] 컨텍스트 캐싱 테스트
  - 캐시 히트/미스 시나리오
  - TTL 만료 시나리오
  - 캐시 무효화

### Phase 7 검증 기준

- [ ] 5계층 컨텍스트 정상 조합
- [ ] 토큰 예산 내 컨텍스트 생성
- [ ] 캐싱 동작 확인
- [ ] Phase별 컨텍스트 차이 확인
- [ ] 전체 테스트 통과

---

## Phase 8: Insight 생성

**목표**: LLM 기반 인사이트 생성 + 자연어 변환
**난이도**: 중간
**예상 테스트**: 10-15개
**참조**: Project_B `domain/insight/`, VoiceChat Engine v2 (인사이트 생성 예시)
**세부 계획**: `docs/ondev/YYYYMMDD_NN_phase_8_plan.md` (Phase 시작 시 작성)

### 8.1 Insight 생성기

- [ ] `app/services/insight/generator.rb` 구현
  - `#initialize(depth_exploration:, context:)` - 초기화
  - `#generate` - 인사이트 생성
  - 입력 조합
    - Q1 결과 (진짜 감정) → situation 필드
    - Q2 결과 (의사결정) → decision 필드
    - Q3 결과 (영향 분석) → action_guide 필드
    - Q4 결과 (필요 정보) → data_info 필드
    - 수집된 외부 정보
    - 현재 컨텍스트 (시간, 상태)
    - 과거 유사 상황 (OntologyRAG 검색)
  - LLM 프롬프트 구성
    - 시스템 프롬프트 (인사이트 생성 전용)
    - 구조화된 입력 데이터
    - 출력 형식 지정
  - Insight 레코드 생성 및 저장
- [ ] Insight 생성기 테스트
  - 모든 Q1-Q4 입력 완료 시 정상 생성
  - 부분 입력 시 graceful 처리
  - LLM 호출 실패 시 에러 처리

### 8.2 자연어 변환

- [ ] `app/services/insight/natural_speech.rb` 구현
  - `#initialize(insight)` - 초기화
  - `#convert` - 자연어 텍스트 변환
  - 기본 템플릿:
    ```
    "지금은 {situation}이고,
     {data_info} 때문에,
     {decision}을 위해서,
     지금은 {action_guide}가 좋을 것 같아요"
    ```
  - 컨텍스트 기반 변형
    - 출근길: 격려/동기부여 톤
    - 퇴근길: 위로/안정 톤
    - 피곤한 상태: 간결한 메시지
  - 자연스러운 한국어 조사 처리
  - natural_text 필드에 저장
- [ ] 자연어 변환 테스트
  - 정상 변환 케이스
  - 컨텍스트별 톤 차이
  - 누락 필드 처리

### 8.3 InsightsController

- [ ] `app/controllers/insights_controller.rb` 구현
  - `#index` - 사용자의 인사이트 목록
  - `#show` - 인사이트 상세 조회
  - `#create` - 인사이트 수동 생성 트리거 (관리용)
  - 인증 필터 적용
  - Turbo Frame 응답 지원
- [ ] InsightsController 테스트
  - 인사이트 목록 조회
  - 인사이트 상세 조회
  - 미인증 사용자 접근 차단

### Phase 8 검증 기준

- [ ] Q1-Q4 완료 → 인사이트 생성 → 자연어 변환 전체 흐름
- [ ] 다양한 컨텍스트에서의 자연어 출력 품질
- [ ] InsightsController CRUD 동작
- [ ] 전체 테스트 통과

---

## Phase 9: 실시간 통신 (Action Cable)

**목표**: WebSocket 기반 실시간 VoiceChat 통신
**난이도**: 높음
**예상 테스트**: 8-12개
**참조**: 신규 설계 (Rails Action Cable + Solid Cable)
**세부 계획**: `docs/ondev/YYYYMMDD_NN_phase_9_plan.md` (Phase 시작 시 작성)

### 9.1 Action Cable 기본 설정

- [ ] Action Cable 설정 (`config/cable.yml`)
  - Development: solid_cable (SQLite 기반)
  - Test: async
  - Production: solid_cable
- [ ] Solid Cable 마이그레이션 실행
- [ ] Action Cable 라우팅 (`/cable`)

### 9.2 VoiceChat 채널

- [ ] `app/channels/voice_chat_channel.rb` 구현
  - `#subscribed` - 세션 기반 구독 (session_id)
  - `#unsubscribed` - 구독 해제 (세션 종료 처리)
  - `#receive(data)` - 사용자 메시지 수신
    - 메시지 저장
    - VoiceChat 엔진 처리 (Phase 전환, 감정 분석)
    - 응답 브로드캐스트
  - `#speak(data)` - AI 응답 전송
  - 인증 확인 (current_user)
  - 동시 접속 관리
- [ ] VoiceChat 채널 테스트
  - 구독/해제 동작
  - 메시지 수신/응답 흐름
  - 인증 실패 시 거부

### 9.3 실시간 Phase 전환 브로드캐스트

- [ ] Phase 전환 시 Turbo Stream 브로드캐스트
  - Phase 변경 알림
  - 감정 레벨 업데이트
  - DEPTH 진입/종료 알림
  - 인사이트 생성 완료 알림
- [ ] VoiceChatData 모델에 `broadcasts_to` 설정
- [ ] 브로드캐스트 테스트

### 9.4 연결 관리

- [ ] 연결 끊김 처리
  - 자동 재연결 로직
  - 세션 상태 복원
  - 메시지 유실 방지 (마지막 처리 메시지 추적)
- [ ] 동시 세션 제한 (사용자당 1개 활성 세션)
- [ ] 연결 타임아웃 설정

### Phase 9 검증 기준

- [ ] WebSocket 연결/해제 정상 동작
- [ ] 실시간 메시지 송수신
- [ ] Phase 전환 실시간 알림
- [ ] 연결 끊김 후 복원
- [ ] 전체 테스트 통과

---

## Phase 10: UI 구현 (Turbo + Stimulus)

**목표**: 전체 사용자 인터페이스 구현
**난이도**: 중상
**예상 테스트**: 10-15개 (시스템 테스트 포함)
**참조**: 신규 설계
**세부 계획**: `docs/ondev/YYYYMMDD_NN_phase_10_plan.md` (Phase 시작 시 작성)

### 10.1 VoiceChat UI

- [ ] `app/views/voice_chats/` Turbo Frames 구현
  - 대화 인터페이스 (메시지 목록 + 입력)
  - Turbo Frame: `voice_chat_messages` (메시지 스트림)
  - Turbo Frame: `voice_chat_status` (Phase/감정 상태)
  - Phase 상태 표시 바 (현재 Phase 시각화)
  - 감정 레벨 시각화 (게이지/그래프)
  - DEPTH 진입 시 UI 전환 (색상/레이아웃 변경)
  - 인사이트 카드 표시 영역
- [ ] `app/javascript/controllers/voice_chat_controller.js` Stimulus 구현
  - WebSocket 연결 관리
  - 메시지 전송/수신
  - 스크롤 관리 (자동 하단 스크롤)
  - Phase 상태 업데이트 핸들링
- [ ] VoiceChat UI 시스템 테스트 (Capybara)

### 10.2 Session 관리 UI

- [ ] `app/controllers/sessions_controller.rb` 확장
  - `#index` - 세션 목록 (최근 대화 기록)
  - `#show` - 세션 상세 (대화 내용 + 인사이트)
  - `#create` - 새 세션 시작
  - `#update` - 세션 메타데이터 업데이트
- [ ] `app/views/sessions/` 구현
  - 세션 목록 뷰 (날짜별 그룹핑)
  - 세션 상세 뷰 (대화 히스토리)
  - 새 세션 시작 버튼
- [ ] Session UI 테스트

### 10.3 Insight 표시 UI

- [ ] `app/views/insights/` 구현
  - 인사이트 카드 컴포넌트
  - 인사이트 목록 (타임라인 형태)
  - 인사이트 상세 (Q1-Q4 원본 + 자연어 텍스트)
  - DEPTH 탐색 과정 시각화
- [ ] Insight UI 테스트

### 10.4 설정 UI

- [ ] `app/controllers/settings_controller.rb` 구현
  - `#show` - 설정 페이지
  - `#update` - 설정 업데이트
- [ ] `app/views/settings/` 구현
  - 언어 설정
  - 음성 속도 설정
  - 알림 설정
  - AI 페르소나 선택
- [ ] 설정 UI 테스트

### 10.5 공통 Stimulus Controllers

- [ ] `app/javascript/controllers/` 공통 컨트롤러
  - `flash_controller.js` - 플래시 메시지 자동 해제
  - `modal_controller.js` - 모달 다이얼로그
  - `loading_controller.js` - 로딩 상태 관리
  - `form_controller.js` - 폼 유효성 검사
- [ ] 반응형 레이아웃 (모바일 우선)
- [ ] Hotwire Native 호환 마크업

### Phase 10 검증 기준

- [ ] 모든 페이지 정상 렌더링
- [ ] Turbo Frames 동적 업데이트 동작
- [ ] Stimulus 인터랙션 동작
- [ ] 모바일 반응형 레이아웃
- [ ] Capybara 시스템 테스트 통과
- [ ] 전체 테스트 통과

---

## Phase 11: 백그라운드 잡

**목표**: 비동기 작업 처리 시스템 구축
**난이도**: 낮음
**예상 테스트**: 8-10개
**참조**: Project_B/E API 패턴, Solid Queue 문서
**세부 계획**: `docs/ondev/YYYYMMDD_NN_phase_11_plan.md` (Phase 시작 시 작성)

### 11.1 Solid Queue 설정

- [ ] Solid Queue 마이그레이션 실행
- [ ] `config/queue.yml` 설정
  - 큐 우선순위: critical > default > low
  - Worker 설정
- [ ] `config/solid_queue.yml` 설정

### 11.2 E/N/G/C 이벤트 배치 잡

- [ ] `app/jobs/engc_event_batch_job.rb` 구현
  - DEPTH Q1-Q4에서 추출된 E/N/G/C 이벤트를 OntologyRAG로 배치 전송
  - `OntologyRag::Client#batch_save_events` 호출
  - 재시도 로직 (3회, 지수 백오프)
  - 실패 시 Dead Letter Queue 처리
  - 이벤트 형식:
    - Emotion (감정 감지 이벤트)
    - Need (니즈 식별 이벤트)
    - Goal (목표 식별 이벤트)
    - Constraint (제약 식별 이벤트)
- [ ] EngcEventBatchJob 테스트
  - 정상 배치 전송
  - API 실패 시 재시도
  - Dead Letter 처리

### 11.3 대화 저장 잡

- [ ] `app/jobs/conversation_save_job.rb` 구현
  - 세션 종료 시 전체 대화 내용을 OntologyRAG로 저장
  - `OntologyRag::Client#save_conversation` 호출
  - VoiceChat Data 생성 (날씨 + GPS + 대화 텍스트)
  - 재시도 로직
  - 실패 시 로컬 백업 (SQLite에 unsaved 플래그)
- [ ] ConversationSaveJob 테스트
  - 정상 저장
  - API 실패 시 로컬 백업
  - 재시도 후 성공

### 11.4 외부 정보 수집 잡

- [ ] `app/jobs/external_info_job.rb` 구현
  - Type A: 관심사 키워드 기반 뉴스 검색 (주기적)
  - Type B: 상태 기반 정보 검색 (감정/상태 감지 시)
  - Type C: Pending Decision 관련 정보 수집 (결정 업데이트 시)
  - Type D: 과거 대화 기반 후속 정보 (세션 종료 후)
  - 결과를 로컬 DB에 캐시
- [ ] ExternalInfoJob 테스트 (각 Type별)

### 11.5 Mission Control 설정

- [ ] `mission_control-jobs` 대시보드 설정
  - 잡 모니터링
  - 실패 잡 재시도
  - 큐 상태 확인

### Phase 11 검증 기준

- [ ] Solid Queue 정상 동작
- [ ] E/N/G/C 이벤트 배치 전송 성공
- [ ] 대화 저장 + 실패 시 로컬 백업
- [ ] 외부 정보 수집 스케줄링
- [ ] Mission Control 대시보드 접근
- [ ] 전체 테스트 통과

---

## Phase 12: RevenueCat 구독 모델

**목표**: 구독 기반 수익화 (Free / Premium 구분)
**난이도**: 중간
**예상 테스트**: 10-15개
**참조**: RevenueCat Rails SDK 문서
**세부 계획**: `docs/ondev/YYYYMMDD_NN_phase_12_plan.md` (Phase 시작 시 작성)

### 12.1 RevenueCat 기본 연동

- [ ] RevenueCat SDK 설정 (Gem 또는 HTTP 클라이언트)
- [ ] `app/services/subscription/revenue_cat_client.rb` 구현
  - RevenueCat API 연동
  - 구독 상태 조회
  - 고객 정보 관리
- [ ] RevenueCat 클라이언트 테스트

### 12.2 구독 모델 설계

- [ ] User 모델에 구독 관련 필드 추가
  - `subscription_status` (string) - free, premium, expired
  - `subscription_expires_at` (datetime, nullable)
  - `revenue_cat_id` (string, nullable)
- [ ] Subscription 상태 관리 메서드
  - `premium?`, `free?`, `expired?`

### 12.3 Feature Gating (기능 접근 제어)

- [ ] `app/services/subscription/entitlement_checker.rb` 구현
  - **Free Tier**: SURFACE Layer만 사용 가능
    - 5-Phase VoiceChat 기본 기능
    - 기본 대화 기록
  - **Premium Tier**: 전체 기능 사용 가능
    - DEPTH Layer (4 Core Questions)
    - INSIGHT Layer (인사이트 생성)
    - 외부 정보 연동 (Type A-D)
    - 고급 컨텍스트 (Past Memory 검색)
  - `#can_access?(feature)` - 기능별 접근 제어
  - `#require_premium!(feature)` - Premium 필요 시 예외/리다이렉트
- [ ] EntitlementChecker 테스트

### 12.4 Webhook 처리

- [ ] RevenueCat Webhook 엔드포인트 구현
  - 구독 시작 / 갱신 / 만료 / 취소 이벤트 처리
  - User 모델 구독 상태 업데이트
  - Webhook 서명 검증 (보안)
- [ ] Webhook 처리 테스트

### 12.5 Paywall UI

- [ ] Paywall 페이지 구현
  - Free vs Premium 기능 비교 표시
  - 구독 버튼 (Hotwire Native 네이티브 결제 연동)
  - 구독 상태 표시
- [ ] DEPTH/INSIGHT 접근 시 Paywall 리다이렉트
- [ ] 서버사이드 Receipt Validation

### Phase 12 검증 기준

- [ ] RevenueCat 연동 정상 동작
- [ ] Free/Premium 기능 분리 정확
- [ ] Webhook 구독 상태 동기화
- [ ] Paywall 리다이렉트 동작
- [ ] 전체 테스트 통과

---

## Phase 13: 음성 파이프라인 (Hotwire Native Bridge)

**목표**: 네이티브 오디오 입출력 (가장 높은 기술 리스크)
**난이도**: 높음 (최고 리스크 Phase)
**예상 테스트**: 8-12개
**참조**: 신규 설계 (Hotwire Native 네이티브 브릿지)
**세부 계획**: `docs/ondev/YYYYMMDD_NN_phase_13_plan.md` (Phase 시작 시 작성)

### 13.1 Hotwire Native Android 앱 셋업

- [ ] Android 프로젝트 생성 (hotwire-native-android)
- [ ] 기본 WebView 설정 (Rails 서버 연결)
- [ ] Hotwire Native 설정 (Turbo Navigator)
- [ ] 네이티브 앱 빌드 및 기본 동작 확인

### 13.2 네이티브 오디오 브릿지 설계

- [ ] Bridge Component 아키텍처 설계
  - JavaScript ↔ Native 통신 프로토콜
  - 오디오 데이터 전송 형식 (PCM/Opus)
  - 세션 라이프사이클 관리
- [ ] `AudioBridgeComponent` 구현 (JavaScript 측)
  - `startRecording()` - 녹음 시작 요청
  - `stopRecording()` - 녹음 중지 요청
  - `playAudio(data)` - 오디오 재생 요청
  - `onTranscription(callback)` - 음성 인식 결과 수신
- [ ] `AudioBridgeComponent` 구현 (Android Native 측)
  - 마이크 접근 및 오디오 캡처
  - 오디오 재생 (TTS 출력)
  - Bridge 메시지 핸들링

### 13.3 STT (Speech-to-Text) 통합

- [ ] Gemini Live API STT 연동 설계
- [ ] 실시간 음성 → 텍스트 변환 파이프라인
  - 오디오 스트리밍 (WebSocket 또는 HTTP 스트리밍)
  - 부분 인식 결과 표시 (interim results)
  - 최종 인식 결과 처리
- [ ] STT 에러 핸들링 (노이즈, 침묵, 인식 실패)
- [ ] STT 통합 테스트

### 13.4 TTS (Text-to-Speech) 통합

- [ ] TTS API 연동 (Gemini Live API 또는 별도 TTS)
- [ ] 텍스트 → 음성 변환 파이프라인
  - 응답 텍스트 분할 (문장 단위)
  - 스트리밍 오디오 생성
  - 네이티브 오디오 재생
- [ ] TTS 에러 핸들링
- [ ] TTS 통합 테스트

### 13.5 GPS/날씨 데이터 수집

- [ ] `LocationBridgeComponent` 구현
  - GPS 위치 수집 (네이티브 → Bridge → Rails)
  - 날씨 API 연동 (위치 기반)
  - VoiceChatData 메타데이터에 저장
- [ ] 위치/날씨 데이터 수집 테스트

### 13.6 Gemini Live API 스트리밍 통합

- [ ] Gemini Live API 실시간 스트리밍 설계
  - 양방향 오디오 스트리밍
  - 컨텍스트 주입 (Context Orchestrator 연동)
  - 응답 파이프라인 (STT → 처리 → TTS)
- [ ] 스트리밍 세션 관리
  - 시작/종료
  - 에러 복구
  - 타임아웃 처리
- [ ] Gemini Live API 통합 테스트

### Phase 13 검증 기준

- [ ] Android 앱에서 Rails 서버 정상 연결
- [ ] 음성 녹음 → STT → 텍스트 표시 동작
- [ ] 텍스트 → TTS → 음성 재생 동작
- [ ] GPS/날씨 데이터 정상 수집
- [ ] Gemini Live API 스트리밍 동작
- [ ] 전체 테스트 통과

> **리스크 노트**: 이 Phase는 프로젝트에서 가장 높은 기술 리스크를 가진다.
> Hotwire Native 네이티브 브릿지를 통한 오디오 스트리밍은 검증이 필요하며,
> 초기 프로토타이핑으로 기술 검증(Proof of Concept)을 우선 수행할 것을 권장한다.
> PoC 결과에 따라 Phase 계획이 조정될 수 있다.

---

## Phase 14: OntologyRAG P1 엔드포인트 통합

**목표**: 핵심 기능 완성도 향상 (Hybrid Search, 캐시 프로필, VoiceChat 엔드포인트)
**난이도**: 중간
**예상 테스트**: 10-15개
**참조**: Project_E API 문서 (P1 엔드포인트)
**세부 계획**: `docs/ondev/YYYYMMDD_NN_phase_14_plan.md` (Phase 시작 시 작성)

### 14.1 OntologyRag::Client P1 확장

- [ ] `#query(question:, google_sub:, limit: 5)` 구현
  - POST `/engine/query`
  - Hybrid Search (Vector + Graph)
  - 권한 스코핑 (google_sub 기반)
  - 응답 파싱 (answer, context, sources)
- [ ] query 테스트 (WebMock)

- [ ] `#get_cached_profile(google_sub:)` 구현
  - GET `/incar/profile/{google_sub}`
  - 캐시된 프로필 (빠른 응답)
  - 세션 시작 시 사용 (실시간 프로필은 get_profile)
- [ ] get_cached_profile 테스트 (WebMock)

### 14.2 VoiceChat 3계층 엔드포인트 연동

- [ ] `#voicechat_surface(params)` 구현
  - POST `/engine/voicechat/surface`
  - SURFACE Layer LLM 호출 (5-Phase 대화)
- [ ] `#voicechat_depth(params)` 구현
  - POST `/engine/voicechat/depth`
  - DEPTH Layer LLM 호출 (Q1-Q4 질문 생성)
- [ ] `#voicechat_insight(params)` 구현
  - POST `/engine/voicechat/insight`
  - INSIGHT Layer LLM 호출 (인사이트 생성)
- [ ] VoiceChat 엔드포인트 테스트

### 14.3 외부 정보 연동 (Type A-D)

- [ ] Context Orchestrator Layer 4 완전 구현
  - Type A: 관심사 업데이트 → 웹 검색 결과 주입
  - Type B: 상태 기반 정보 → 감정/상태에 맞는 정보 검색
  - Type C: Decision 관련 → Pending Decision 정보 수집
  - Type D: 과거 대화 후속 → RAG 검색 기반 정보
- [ ] Layer 2 (Past Memory) stub 해제
  - OntologyRag::Client#query 호출 연동
  - 과거 대화 검색 → 유사 상황/패턴 매칭
- [ ] 외부 정보 연동 테스트

### 14.4 검색 결과 캐싱

- [ ] Hybrid Search 결과 캐싱 전략
  - 동일 질문 5분 TTL
  - 세션 내 반복 검색 방지
  - Rails.cache 활용
- [ ] 캐싱 테스트

### Phase 14 검증 기준

- [ ] Hybrid Search 정상 동작
- [ ] VoiceChat 3계층 엔드포인트 연동
- [ ] 외부 정보 Type A-D 수집 및 주입
- [ ] Past Memory 검색 동작
- [ ] 캐싱 전략 동작
- [ ] 전체 테스트 통과

---

## Phase 15: 통합 테스트 + 최적화

**목표**: 전체 시스템 통합 검증 및 성능/보안 최적화
**난이도**: 중간
**예상 테스트**: 20-30개 (통합 테스트 포함)
**참조**: 전체 Phase 산출물
**세부 계획**: `docs/ondev/YYYYMMDD_NN_phase_15_plan.md` (Phase 시작 시 작성)

### 15.1 E2E 통합 테스트

- [ ] **전체 플로우 테스트**: SURFACE → DEPTH → INSIGHT
  - 사용자 로그인
  - 세션 시작
  - SURFACE Layer 5-Phase 대화
  - DEPTH 진입 (감정 강도 > 0.8)
  - Q1-Q4 질문/답변
  - 인사이트 생성
  - 세션 종료 → 대화 저장
- [ ] **인증 → 대화 → 인사이트 → 저장 플로우**
  - Google OAuth 로그인
  - OntologyRAG 사용자 등록
  - 대화 세션 전체 수행
  - E/N/G/C 이벤트 배치 저장
  - 대화 히스토리 저장
  - 인사이트 조회
- [ ] **Feature Gating 통합 테스트**
  - Free 사용자: SURFACE만 접근 가능
  - Premium 사용자: 전체 기능 접근
  - 구독 만료 시 기능 제한
- [ ] **에러 시나리오 통합 테스트**
  - OntologyRAG API 장애 시 graceful degradation
  - WebSocket 연결 끊김 후 복원
  - LLM 호출 실패 시 폴백

### 15.2 성능 최적화

- [ ] N+1 쿼리 해소
  - Bullet gem 도입 (개발 환경)
  - eager loading 적용 (`includes`, `preload`)
  - 주요 쿼리 실행 계획 분석
- [ ] 캐싱 전략 최적화
  - Rails.cache / Solid Cache 활용 현황 점검
  - Fragment caching (UI 부분 캐싱)
  - HTTP 캐싱 헤더 설정
  - OntologyRAG 응답 캐싱 TTL 조정
- [ ] API 응답 시간 측정 및 최적화
  - 목표: < 500ms (P95)
  - 병목 지점 식별
  - 비동기 처리 최적화
- [ ] 데이터베이스 인덱스 최적화
  - 느린 쿼리 분석
  - 복합 인덱스 추가
  - SQLite PRAGMA 설정 최적화

### 15.3 보안 감사

- [ ] Brakeman 보안 스캔 실행 및 이슈 해결
  - SQL Injection 검사
  - XSS 검사
  - CSRF 검사
  - Mass Assignment 검사
- [ ] API 키 보안 검증
  - ENV 변수로만 관리 (.env 절대 커밋하지 않음)
  - 로그에 API 키 노출 방지
- [ ] 인증/인가 보안 검증
  - 세션 하이재킹 방지
  - CSRF 토큰 검증
  - 권한 우회 테스트

### 15.4 코드 품질 정리

- [ ] Rubocop 전체 스캔 및 경고 해결
- [ ] 코드 중복 제거
- [ ] 미사용 코드 정리
- [ ] 테스트 커버리지 확인 (목표: 80%+)
- [ ] API 문서 정리 (내부용)

### Phase 15 검증 기준

- [ ] 전체 E2E 시나리오 통과
- [ ] P95 API 응답 시간 < 500ms
- [ ] Brakeman 이슈 제로
- [ ] Rubocop 경고 제로
- [ ] 테스트 커버리지 80%+
- [ ] 전체 테스트 통과

---

## Phase 16: 배포 + 모니터링

**목표**: 프로덕션 환경 배포 및 모니터링 설정
**난이도**: 중간
**예상 테스트**: 5-8개
**참조**: 배포 플랫폼 문서, 모니터링 서비스 문서
**세부 계획**: `docs/ondev/YYYYMMDD_NN_phase_16_plan.md` (Phase 시작 시 작성)

### 16.1 배포 환경 설정

- [ ] 배포 플랫폼 선택 및 설정 (Railway / Fly.io / Render)
- [ ] 프로덕션 Dockerfile 작성
- [ ] 프로덕션 데이터베이스 설정 (SQLite 프로덕션 최적화)
- [ ] 환경별 설정 분리 (development / test / production)

### 16.2 프로덕션 환경 변수

- [ ] 프로덕션 환경 변수 설정
  - `ONTOLOGY_RAG_BASE_URL` (프로덕션 URL)
  - `ONTOLOGY_RAG_API_KEY` (프로덕션 키)
  - `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` (프로덕션 OAuth)
  - `SECRET_KEY_BASE` (프로덕션 시크릿)
  - `RAILS_ENV=production`
  - `REVENUECAT_API_KEY` (프로덕션 키)
- [ ] 시크릿 관리 전략 (Rails credentials 또는 플랫폼 시크릿)

### 16.3 모니터링 설정

- [ ] 에러 트래킹 설정 (Sentry / Honeybadger)
  - 에러 알림 설정
  - 에러 그룹핑
  - 소스맵 연동
- [ ] 성능 모니터링 (APM)
  - 요청 추적
  - 데이터베이스 쿼리 모니터링
  - 외부 API 호출 모니터링
- [ ] 로그 관리
  - 구조화된 로깅 (JSON 포맷)
  - 로그 레벨 설정
  - 로그 보존 정책

### 16.4 CI/CD 파이프라인 완성

- [ ] GitHub Actions 프로덕션 배포 워크플로우
  - 테스트 → 빌드 → 배포 파이프라인
  - 자동 배포 (main 브랜치 push 시)
  - 롤백 전략
- [ ] 배포 전 체크리스트 자동화
  - 테스트 전체 통과
  - Brakeman 스캔 통과
  - Rubocop 통과

### 16.5 앱 스토어 준비

- [ ] Google Play 스토어 등록 준비
  - APK/AAB 빌드
  - 스토어 메타데이터 (설명, 스크린샷)
  - 개인정보처리방침
- [ ] Apple App Store 등록 준비 (iOS 지원 시)
  - IPA 빌드
  - App Store Connect 설정
  - 심사 가이드라인 준수

### Phase 16 검증 기준

- [ ] 프로덕션 배포 성공
- [ ] 프로덕션 환경 정상 동작
- [ ] 모니터링/알림 정상 수신
- [ ] CI/CD 파이프라인 동작
- [ ] 전체 테스트 통과

---

## 요약 테이블

| Phase | 이름 | 난이도 | 예상 테스트 | 핵심 참조 | 의존성 |
|:-----:|------|:------:|:----------:|----------|--------|
| 0 | 지식 추출 + 환경 설정 ✅ | - | - | docs/ondev/ | 없음 |
| 1 | Rails 프로젝트 초기화 | 낮음 | 5-8 | CLAUDE.md | Phase 0 |
| 2 | 인증 시스템 (OmniAuth) | 낮음 | 8-12 | Project_C authService | Phase 1 |
| 3 | 핵심 데이터 모델 | 낮음 | 10-15 | Project_B domain/model | Phase 1 |
| 4 | OntologyRAG 클라이언트 | 중간 | 15-20 | Project_C ontology-rag.service.ts, Project_E API | Phase 1 |
| 5 | VoiceChat 도메인 서비스 | 중간 | 15-20 | Project_B phaseTransition/emotionEnergy | Phase 3 |
| 6 | DEPTH Layer | 중상 | 15-20 | Project_B domain/depth, VoiceChat v2 | Phase 5 |
| 7 | Context Orchestrator | 중간 | 10-15 | Project_B contextOrchestrator | Phase 4, 5 |
| 8 | Insight 생성 | 중간 | 10-15 | Project_B domain/insight | Phase 6, 7 |
| 9 | 실시간 통신 (Action Cable) | 높음 | 8-12 | 신규 설계 | Phase 5 |
| 10 | UI 구현 (Turbo + Stimulus) | 중상 | 10-15 | 신규 설계 | Phase 2, 8, 9 |
| 11 | 백그라운드 잡 | 낮음 | 8-10 | Project_B/E API 패턴 | Phase 4 |
| 12 | RevenueCat 구독 모델 | 중간 | 10-15 | RevenueCat SDK | Phase 2, 10 |
| 13 | 음성 파이프라인 (Native Bridge) | 높음 | 8-12 | 신규 설계 (최고 리스크) | Phase 9, 10 |
| 14 | OntologyRAG P1 엔드포인트 | 중간 | 10-15 | Project_E API 문서 | Phase 4, 7 |
| 15 | 통합 테스트 + 최적화 | 중간 | 20-30 | 전체 산출물 | Phase 1-14 |
| 16 | 배포 + 모니터링 | 중간 | 5-8 | 배포 플랫폼 문서 | Phase 15 |

### 테스트 총계

| 구분 | 테스트 수 |
|------|:---------:|
| Phase 1-4 (기반) | 38-55 |
| Phase 5-8 (핵심 비즈니스) | 50-70 |
| Phase 9-11 (통신/UI/잡) | 26-37 |
| Phase 12-14 (확장) | 28-42 |
| Phase 15-16 (통합/배포) | 25-38 |
| **총계** | **167-242** |

### Phase 의존성 다이어그램

```
Phase 0 ✅
    │
    v
Phase 1 (Rails 초기화)
    │
    ├──────────┬──────────┐
    v          v          v
Phase 2    Phase 3    Phase 4
(인증)     (모델)     (API 클라이언트)
    │          │          │
    │          v          │
    │      Phase 5 ◄──────┘ (일부)
    │      (VoiceChat)
    │          │
    │          v
    │      Phase 6
    │      (DEPTH)
    │          │
    │      ┌───┴───┐
    │      v       v
    │  Phase 7  Phase 9
    │  (Context) (Cable)
    │      │       │
    │      v       │
    │  Phase 8     │
    │  (Insight)   │
    │      │       │
    v      v       v
Phase 10 (UI) ◄────┘
    │
    ├──────────┐
    v          v
Phase 11   Phase 12
(잡)       (구독)
    │          │
    v          v
Phase 13 (음성 파이프라인)
    │
    v
Phase 14 (P1 엔드포인트)
    │
    v
Phase 15 (통합 테스트)
    │
    v
Phase 16 (배포)
```

---

## 부록

### A. 참조 문서 목록

| 문서 | 경로 | 역할 |
|------|------|------|
| **CLAUDE.md** | `CLAUDE.md` | 프로젝트 마스터 설계 가이드 |
| Project_B 분석 | `docs/ondev/20260212_01_project_b_analysis.md` | VoiceChat 엔진, 도메인 모델, 재사용성 평가 |
| Project_C 분석 | `docs/ondev/20260212_02_project_c_analysis.md` | OntologyRAG 통합 패턴, ENGC 이벤트 |
| Project_E API 분석 | `docs/ondev/20260212_03_project_e_api_analysis.md` | API 스펙, 타임아웃/리트라이 설정 |
| 종합 마이그레이션 평가 | `docs/ondev/20260212_04_comprehensive_migration_assessment.md` | 신규 구축 결정 근거 |
| VoiceChat Engine v2 | `docs/ref/20251206_VoiceChat_Engine_Ideation_v2.md` | 3계층 아키텍처, DEPTH 상세 설계 |
| 3-Project 통합 계획 | `docs/ref/20251212_07_3project_integrated_development_plan.md` | 통합 아키텍처/API |
| Architecture Insights | `docs/ref/20251222_Architecture_Integration_Insights.md` | 도메인 모델/E2E 패턴 |
| TDD 방법론 | `docs/ref/251115_KentBeck_TDD.md` | Kent Beck TDD 워크플로우 |
| 바이브코딩 원칙 | `docs/ref/251115_바이브코딩원칙.md` | 6대 코드 품질 원칙 |

### B. 바이브코딩 6대원칙 체크리스트

각 Phase 완료 시 아래 항목을 점검한다:

- [ ] **일관된 패턴**: 새로 작성한 코드가 기존 CRUD/서비스 패턴과 일관적인가?
- [ ] **One Source of Truth**: 중복 정의된 설정값이나 상수가 없는가?
- [ ] **No Hardcoding**: 코드에 직접 박아넣은 매직 넘버/스트링이 없는가?
  - 상태값 → enum/constant
  - API 엔드포인트 → `OntologyRag::Constants`
  - 임계값 → `VoiceChat::Constants`
- [ ] **Error Handling**: Happy Path와 Error Path 모두 처리했는가?
  - API 호출: 타임아웃, 리트라이, fallback
  - 모델: 유효성 검증 에러
  - 컨트롤러: rescue_from
- [ ] **Single Responsibility**: 함수/모듈이 단일 책임만 수행하는가?
  - Controller: 요청/응답만
  - Service: 비즈니스 로직만
  - Model: 데이터 검증/관계만
- [ ] **Shared Module**: 재사용 가능한 로직이 적절히 추출되었는가?
  - `app/services/` 디렉토리 구조 정리
  - `concerns/` 공통 모듈

### C. TDD 워크플로우 체크리스트

각 테스트 사이클 시 아래 항목을 점검한다:

- [ ] **Red**: 실패하는 테스트를 먼저 작성했는가?
- [ ] **Green**: 테스트 통과를 위한 **최소한의** 코드만 작성했는가?
- [ ] **Refactor**: 테스트 통과 후 구조 개선이 필요한가?
- [ ] **Tidy First**: 구조적 변경과 행동적 변경을 분리 커밋했는가?
- [ ] **Commit**: 모든 테스트 통과 + 린터 경고 없음 상태에서 커밋했는가?
- [ ] **단일 책임**: 이번 커밋이 단일 논리적 작업 단위인가?

### D. Phase별 워크플로우 다이어그램

```
┌──────────────────────────────────────────────────────────────────────┐
│                     Phase N 실행 워크플로우                            │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. Phase 세부계획 작성                                               │
│     docs/ondev/YYYYMMDD_NN_phase_N_plan.md                          │
│     ├── 테스트 목록 (체크박스)                                        │
│     ├── 참조 소스 코드 분석                                           │
│     └── 예상 구현 순서                                                │
│                     │                                                │
│                     v                                                │
│  2. TDD 구현 사이클 반복                                              │
│     ┌──────────────────────────────┐                                 │
│     │  Red: 실패 테스트 작성         │                                │
│     │         │                      │                                │
│     │         v                      │                                │
│     │  Green: 최소 코드 구현          │                                │
│     │         │                      │                                │
│     │         v                      │                                │
│     │  Refactor: 구조 개선           │                                │
│     │         │                      │                                │
│     │         v                      │                                │
│     │  Commit: 통과 확인 후 커밋     │                                │
│     └──────────┬───────────────────┘                                 │
│                │ 모든 테스트 완료?                                     │
│                v                                                     │
│  3. 검증 (Verification)                                              │
│     ├── rails test (전체 테스트 실행)                                  │
│     ├── rubocop (린트 체크)                                           │
│     └── brakeman (보안 스캔)                                          │
│                │                                                     │
│                v                                                     │
│  4. Gap 분석                                                         │
│     ├── 누락된 테스트 식별                                            │
│     ├── 엣지 케이스 확인                                              │
│     └── 바이브코딩 원칙 점검                                          │
│                │                                                     │
│                v                                                     │
│  5. Gap 재구현 (필요 시 2-4 반복)                                     │
│                │                                                     │
│                v                                                     │
│  6. Phase E2E 테스트                                                 │
│     ├── 해당 Phase 전체 기능 통합 테스트                              │
│     └── 이전 Phase 회귀 테스트                                       │
│                │                                                     │
│                v                                                     │
│  7. E2E 통과? ─── No ──→ 디버깅 → 재구현 → E2E 재실행              │
│         │                                                            │
│         v Yes                                                        │
│  8. Phase 완료 ✅                                                     │
│     ├── Phase 결과 문서 업데이트                                      │
│     └── 다음 Phase 준비                                              │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### E. 주요 기술 결정 사항 요약

| 결정 사항 | 선택 | 근거 |
|-----------|------|------|
| 빌드 방식 | 정보 참조형 신규 구축 | 아키텍처 패러다임 불일치, 기술 부채 제로 출발 |
| Context 모델 | 5계층 통합 | CLAUDE.md 명세 기준, TS/Kotlin 불일치 해소 |
| app_source | `"incar_companion"` | Project_B 호환, 기존 사용자 데이터 연결 |
| E/N/G/C 파라미터 | **단수형** (emotion, need, goal, constraint) | Project_E 소스코드 확인 |
| 인증 | OmniAuth google_oauth2 | 3단계 폴백 불필요, google_sub 직접 매핑 |
| 캐시 | Rails.cache (Solid Cache) | Rails 표준, SQLite 기반 |
| VoiceChatManager | 6-8개 Service Object로 분리 | God Class 해소, Single Responsibility |
| 프로파일 전략 | 세션 시작: `/incar/profile`, DEPTH: `/engine/prompts` | 속도 vs 정확성 밸런스 |
| 테스트 프레임워크 | Minitest + WebMock + VCR | Rails 기본, API 모킹 |
| 백그라운드 잡 | Solid Queue | Rails 8 기본, SQLite 기반 |
| 실시간 통신 | Action Cable + Solid Cable | Rails 기본, WebSocket |
| 구독 | RevenueCat | 크로스 플랫폼 구독 관리 |

### F. 리스크 매트릭스

| 리스크 | 영향도 | 발생 확률 | Phase | 완화 방안 |
|--------|:------:|:---------:|:-----:|----------|
| 음성 파이프라인 기술 검증 | 높음 | 중간 | 13 | PoC 우선 수행, 대안 기술 조사 |
| Gemini Live API 스트리밍 | 높음 | 중간 | 13 | API 안정성 모니터링, 폴백 설계 |
| Context 모델 통합 복잡성 | 중간 | 중간 | 7 | 단계적 구현, stub 활용 |
| OntologyRAG API 장애 | 중간 | 낮음 | 4, 14 | Graceful degradation, 로컬 캐시 |
| 엣지 케이스 누락 | 중간 | 중간 | 5, 6 | TDD, Project_B 코드 참조 |
| LLM 프롬프트 품질 | 중간 | 낮음 | 8 | 반복 개선, A/B 테스트 |
| SQLite 프로덕션 성능 | 낮음 | 낮음 | 15, 16 | PRAGMA 최적화, 인덱스 튜닝 |
| RevenueCat 연동 | 낮음 | 낮음 | 12 | SDK 문서 기반 구현, 테스트 샌드박스 |

---

*이 문서는 SoleTalk 프로젝트의 마스터 개발 로드맵입니다.*
*각 Phase의 세부 구현 계획은 해당 Phase 시작 시 별도 문서로 작성됩니다.*
*진행 상황에 따라 Phase 순서 및 내용이 조정될 수 있습니다.*

*Last Updated: 2026-02-12*
