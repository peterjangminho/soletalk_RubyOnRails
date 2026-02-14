# SoleTalk LLD (Low-Level Design)

> **프로젝트명**: SoleTalk (Project_A)
> **문서 버전**: 1.0
> **작성일**: 2026-02-12
> **문서 유형**: Low-Level Design Document
> **상태**: Draft
> **선행 문서**: PRD.md, CLAUDE.md

---

## 목차

1. [데이터베이스 스키마 (Database Schema)](#1-데이터베이스-스키마-database-schema)
2. [Rails 라우팅 (Routing Design)](#2-rails-라우팅-routing-design)
3. [Service Object 아키텍처 (Service Architecture)](#3-service-object-아키텍처-service-architecture)
4. [Action Cable 실시간 통신 (Real-time Communication)](#4-action-cable-실시간-통신-real-time-communication)
5. [Background Jobs (Solid Queue)](#5-background-jobs-solid-queue)
6. [RevenueCat 구독 통합 (Subscription Integration)](#6-revenuecat-구독-통합-subscription-integration)
7. [Hotwire Native 통합 (Mobile Integration)](#7-hotwire-native-통합-mobile-integration)
8. [에러 처리 전략 (Error Handling Strategy)](#8-에러-처리-전략-error-handling-strategy)
9. [캐시 전략 (Caching Strategy - Solid Cache)](#9-캐시-전략-caching-strategy---solid-cache)
10. [보안 설계 (Security Design)](#10-보안-설계-security-design)
11. [테스트 전략 (Testing Strategy)](#11-테스트-전략-testing-strategy)
12. [참조 문서 (References)](#12-참조-문서-references)

---

## 1. 데이터베이스 스키마 (Database Schema)

SQLite를 기본 데이터베이스로 사용한다. Rails 8의 SQLite 최적화와 Solid Cache/Queue/Cable의 SQLite 기반 인프라를 그대로 활용한다. 개인 사용자 앱 특성상 동시성 이슈가 낮으므로 SQLite의 단일 쓰기 제한은 문제가 되지 않는다.

### 1.1 users

사용자 테이블. Google OAuth의 `google_sub`를 고유 식별자로 사용한다.

```ruby
create_table :users do |t|
  t.string :google_sub, null: false, index: { unique: true }
  t.string :email
  t.string :name
  t.string :avatar_url
  t.string :ontology_rag_id          # OntologyRAG 내부 UUID (identify 응답)
  t.string :subscription_tier, default: "free"  # free / premium
  t.string :revenue_cat_id           # RevenueCat customer ID
  t.datetime :premium_expires_at     # 구독 만료 시각 (nil = 무료)
  t.timestamps
end

add_index :users, :email
add_index :users, :revenue_cat_id, unique: true
```

**비즈니스 규칙**:
- `google_sub`는 모든 프로젝트(A/B/C/E)에서 사용자를 식별하는 단일 키이다.
- `ontology_rag_id`는 최초 로그인 시 `POST /engine/users/identify` 응답의 `id` 필드를 저장한다.
- `subscription_tier` 변경은 RevenueCat Webhook 또는 앱 시작 시 동기화를 통해 이루어진다.

### 1.2 sessions (대화 세션)

음성 대화 세션 테이블. VoiceChat Engine의 상태를 추적한다.

```ruby
create_table :sessions do |t|
  t.references :user, null: false, foreign_key: true
  t.string :title                          # 자동 생성 또는 사용자 설정
  t.string :status, default: "active"      # active / completed / archived
  t.string :current_phase, default: "opener"
    # opener / emotion_expansion / free_speech / calm / re_stimulus
  t.string :current_layer, default: "surface"
    # surface / depth / insight
  t.float :emotion_level, default: 0.0     # 0.0 ~ 1.0 감정 강도
  t.float :energy_level, default: 0.5      # 0.0 ~ 1.0 에너지 수준
  t.integer :message_count, default: 0     # 총 메시지 수 (카운터 캐시)
  t.json :weather_data                     # { temp, condition, humidity, ... }
  t.json :location_data                    # { lat, lng, address, ... }
  t.json :metadata                         # 확장용 메타데이터
  t.datetime :started_at
  t.datetime :ended_at
  t.timestamps
end

add_index :sessions, [:user_id, :status]
add_index :sessions, [:user_id, :created_at]
```

**상태 전이 규칙**:
- `active` -> `completed`: 사용자가 세션 종료 또는 30분 비활성 시
- `completed` -> `archived`: Free 사용자의 7일 이상 지난 세션 (자동 아카이브)
- `active` 세션은 사용자당 최대 1개만 존재 가능

**Phase 전이 순서** (Surface Layer):
```
opener -> emotion_expansion -> free_speech -> calm -> re_stimulus
                                    |
                                    v (emotion_level > 0.8)
                              [depth layer 진입]
```

### 1.3 messages

개별 메시지 테이블. 사용자/AI/시스템 메시지를 모두 저장한다.

```ruby
create_table :messages do |t|
  t.references :session, null: false, foreign_key: true
  t.string :role, null: false              # user / assistant / system
  t.text :content, null: false
  t.string :message_type, default: "text"  # text / voice / system
  t.float :emotion_score                   # 감정 분석 점수 (0.0 ~ 1.0)
  t.string :detected_emotion               # 감지된 감정 레이블 (joy, anger, fear, ...)
  t.string :phase_at_creation              # 메시지 생성 시점의 phase
  t.json :metadata                         # { voice_duration, stt_confidence, ... }
  t.timestamps
end

add_index :messages, [:session_id, :created_at]
add_index :messages, :role
```

**role 값 설명**:
- `user`: 사용자 발화 (STT 변환 결과 또는 텍스트 입력)
- `assistant`: AI 응답 (LLM 생성 또는 시스템 응답)
- `system`: 시스템 이벤트 메시지 (세션 시작/종료, phase 전환 등)

### 1.4 voice_chat_data

VoiceChat 세션의 종합 데이터. 세션 종료 시 생성되어 OntologyRAG에 전송된다.

```ruby
create_table :voice_chat_data do |t|
  t.references :session, null: false, foreign_key: true, index: { unique: true }
  t.text :full_transcript                  # 전체 대화 트랜스크립트
  t.json :weather_data                     # 세션 시작 시 날씨 스냅샷
  t.json :gps_data                         # 세션 시작 시 GPS 스냅샷
  t.json :phase_history                    # Phase 전환 이력 [{phase, at, trigger}, ...]
  t.boolean :depth_triggered, default: false
  t.boolean :insight_generated, default: false
  t.json :engc_events                      # 추출된 E/N/G/C 이벤트 배열
  t.string :ontology_rag_conversation_id   # OntologyRAG 저장 후 반환된 ID
  t.string :save_status, default: "pending"
    # pending / saving / saved / failed
  t.timestamps
end
```

**생성 시점**: 세션 `status`가 `completed`로 변경될 때 `SessionManager`가 생성한다.

### 1.5 depth_explorations

DEPTH Layer Q1-Q4 탐색 데이터. 세션당 0개 또는 1개 존재한다.

```ruby
create_table :depth_explorations do |t|
  t.references :session, null: false, foreign_key: true, index: { unique: true }
  # 진입 신호 데이터
  t.float :signal_emotion_level            # 0.0 ~ 1.0 (진입 시점 감정 강도)
  t.json :signal_keywords                  # Array<String> (감지된 키워드)
  t.integer :signal_repetition_count, default: 0  # 같은 주제 반복 횟수

  # Q1-Q4 답변 (nullable - 순차 진행)
  t.text :q1_answer                        # WHY - 진짜 감정/이유
  t.text :q2_answer                        # DECISION - 결정화된 의사결정
  t.text :q3_answer                        # IMPACT - 다차원 영향 분석
  t.text :q4_answer                        # DATA - 필요 정보 식별

  # 구조화된 분석 결과
  t.json :impacts                          # Array<ImpactAnalysis>
  # ImpactAnalysis: { dimension, score(-5~+5), description }
  # dimensions: emotional, relational, career, financial, psychological

  t.json :information_needs                # Array<InformationNeed>
  # InformationNeed: { type, description, source, status }
  # types: external, past_experience, others_experience, inner, forgotten

  t.string :current_question, default: "q1"  # q1 / q2 / q3 / q4 / completed
  t.string :status, default: "in_progress"   # in_progress / completed / abandoned
  t.timestamps
end
```

**Q1-Q4 진행 규칙**:
- 기본 순서: Q1 -> Q2 -> Q3 -> Q4
- Q2가 이미 명확하면 Q1 먼저 탐색 가능 (유연한 순서)
- 모든 Q가 반드시 완료될 필요 없음 (대화 흐름에 따라 조정)
- `completed` 시 `EngcEventBatchJob` 트리거

### 1.6 insights

INSIGHT Layer 결과물. DEPTH Q1-Q4 기반으로 생성된 행동 가이드 인사이트.

```ruby
create_table :insights do |t|
  t.references :session, null: false, foreign_key: true
  t.references :depth_exploration, foreign_key: true  # nullable (세션 요약은 DEPTH 없이도 가능)

  # Q1-Q4 매핑 필드
  t.text :situation                        # Q1.WHY 기반 (현재 상황/진짜 감정)
  t.text :decision                         # Q2.DECISION 기반 (결정화된 의사결정)
  t.text :action_guide                     # Q3.IMPACT 기반 (행동 가이드)
  t.text :data_info                        # Q4.DATA 기반 (필요/수집된 정보)

  # 최종 출력
  t.text :natural_speech                   # 자연어 변환된 최종 발화 텍스트
  # "지금은 [상황]이고, [정보/이유] 때문에,
  #  [목적]을 위해서, 지금은 [행동 가이드]가 좋을 것 같아요"

  t.json :engc_profile                     # 생성 시점 E/N/G/C Profile 스냅샷
  t.json :external_info_used               # 활용된 외부 정보 목록
  t.float :confidence_score                # 인사이트 신뢰도 (0.0 ~ 1.0)
  t.string :insight_type, default: "depth" # depth / session_summary
  t.timestamps
end

add_index :insights, [:session_id, :created_at]
add_index :insights, :insight_type
```

**insight_type 구분**:
- `depth`: DEPTH Q1-Q4 완료 후 생성된 심층 인사이트 (Premium 전용)
- `session_summary`: 세션 종료 시 기본 요약 (Free 사용자도 접근 가능)

### 1.7 settings

사용자별 앱 설정. User와 1:1 관계.

```ruby
create_table :settings do |t|
  t.references :user, null: false, foreign_key: true, index: { unique: true }
  t.string :persona_name, default: "SoleTalk"
  t.string :persona_style, default: "warm"   # warm / professional / casual
  t.string :language, default: "ko"          # ko / en
  t.boolean :notifications_enabled, default: true
  t.boolean :auto_start_enabled, default: true  # 차량 연결 시 자동 시작
  t.string :voice_type, default: "female_1"  # TTS 음성 타입
  t.float :voice_speed, default: 1.0        # TTS 속도 (0.5 ~ 2.0)
  t.json :preferences                       # 확장용 설정 JSON
  t.timestamps
end
```

### 1.8 subscription_events (구독 이벤트 로그)

RevenueCat Webhook 이벤트를 기록하는 감사 테이블.

```ruby
create_table :subscription_events do |t|
  t.references :user, null: false, foreign_key: true
  t.string :event_type, null: false        # initial_purchase / renewal / cancellation / expiration / ...
  t.string :product_id                     # soletalk_premium_monthly / soletalk_premium_yearly
  t.string :revenue_cat_event_id           # RevenueCat 이벤트 고유 ID (중복 방지)
  t.json :payload                          # 원본 Webhook payload
  t.datetime :event_at                     # 이벤트 발생 시각
  t.timestamps
end

add_index :subscription_events, :revenue_cat_event_id, unique: true
add_index :subscription_events, [:user_id, :event_at]
```

### 1.9 ER Diagram (관계 요약)

```
users 1---* sessions
users 1---1 settings
users 1---* subscription_events

sessions 1---* messages
sessions 1---0..1 voice_chat_data
sessions 1---0..1 depth_explorations
sessions 1---* insights

depth_explorations 1---0..1 insights (depth type)
```

---

## 2. Rails 라우팅 (Routing Design)

RESTful 리소스 패턴을 따르되, Hotwire Native와 API 접근을 모두 지원하는 이중 라우팅 구조를 설계한다.

```ruby
Rails.application.routes.draw do
  # ============================================
  # 인증 (Authentication)
  # ============================================
  get "/auth/:provider/callback", to: "auth/omniauth_callbacks#create"
  get "/auth/failure", to: "auth/omniauth_callbacks#failure"
  delete "/logout", to: "auth/sessions#destroy"

  # ============================================
  # Root
  # ============================================
  root "home#index"

  # ============================================
  # 헬스 체크 (Health Check)
  # ============================================
  get "/health", to: "health#show"

  # ============================================
  # RevenueCat Webhook
  # ============================================
  post "/webhooks/revenue_cat", to: "webhooks/revenue_cat#create"

  # ============================================
  # API namespace (Hotwire Native & 내부 API)
  # ============================================
  namespace :api do
    namespace :v1 do
      # 세션 관리
      resources :sessions, only: [:index, :show, :create, :update] do
        member do
          post :end_session       # 세션 종료 -> VoiceChatData 생성 -> OntologyRAG 저장
        end
        resources :messages, only: [:index, :create]
      end

      # 사용자 프로필
      resource :profile, only: [:show, :update]

      # 인사이트
      resources :insights, only: [:index, :show]

      # 설정
      resource :settings, only: [:show, :update]

      # 구독
      resource :subscription, only: [:show] do
        post :verify              # 클라이언트 → 서버 구독 상태 검증
        post :restore             # 구독 복원 (재설치, 기기 변경 시)
      end
    end
  end

  # ============================================
  # Turbo Native 네비게이션 (HTML 응답)
  # ============================================
  resources :sessions do
    resources :messages, only: [:index, :create]
  end
  resources :insights, only: [:index, :show]
  resource :settings, only: [:show, :edit, :update]
  resource :profile, only: [:show, :edit, :update]

  # ============================================
  # Action Cable 마운트
  # ============================================
  mount ActionCable.server => "/cable"
end
```

**라우팅 설계 원칙**:
- `/api/v1/*`: JSON 응답. Hotwire Native 클라이언트 및 내부 API 호출용.
- `/sessions/*`, `/insights/*` 등: HTML 응답. Turbo Frames/Streams를 통한 서버 렌더링.
- 동일 컨트롤러에서 `respond_to`로 JSON/HTML을 분기하지 않고, API와 HTML 컨트롤러를 분리하여 관심사를 명확히 한다.

---

## 3. Service Object 아키텍처 (Service Architecture)

비즈니스 로직을 컨트롤러에서 분리하여 Service Object 패턴으로 조직한다. 컨트롤러는 요청/응답 처리만 담당하고, 모델은 데이터 검증과 관계만 담당한다.

### 3.1 OntologyRag 서비스 (외부 API 클라이언트)

```
app/services/ontology_rag/
├── client.rb                # Faraday HTTP 클라이언트 (Base)
├── constants.rb             # API 엔드포인트, 헤더, 타임아웃 상수
├── models.rb                # 요청/응답 Value Object
├── errors.rb                # 커스텀 에러 클래스
├── user_service.rb          # identify_user, get_user_data
├── profile_service.rb       # get_profile (실시간), get_cached_profile (캐시)
├── query_service.rb         # hybrid search, similar search
├── event_service.rb         # ENGC event batch
├── conversation_service.rb  # conversation save
├── memory_service.rb        # store/recall memories
└── voicechat_service.rb     # voicechat surface/depth/insight 라우터
```

#### OntologyRag::Client (Base HTTP 클라이언트)

```ruby
# app/services/ontology_rag/client.rb
module OntologyRag
  class Client
    BASE_URL = ENV.fetch("ONTOLOGY_RAG_BASE_URL")

    # Faraday connection 설정
    # - Retry: max 3회, interval 0.5s, backoff_factor 2
    # - Timeout: 엔드포인트별 차등 적용 (아래 표 참조)
    # - Logger: Rails.logger 연동
    # - 공통 헤더:
    #     X-API-Key: ENV['ONTOLOGY_RAG_API_KEY']
    #     X-Source-App: "soletalk-rails"
    #     X-Request-ID: "soletalk-#{SecureRandom.uuid}"
    #     Content-Type: application/json

    # 에러 핸들링:
    #   401 -> OntologyRag::AuthenticationError
    #   404 -> OntologyRag::NotFoundError
    #   422 -> OntologyRag::ValidationError
    #   429 -> OntologyRag::RateLimitError (+ Retry-After 헤더 파싱)
    #   500 -> OntologyRag::ServerError (재시도 대상)
    #   Timeout -> OntologyRag::TimeoutError (재시도 대상)
  end
end
```

#### 엔드포인트별 타임아웃 설정

| 엔드포인트 | Connect Timeout | Read Timeout | 재시도 | 비고 |
|-----------|:-:|:-:|:-:|------|
| `/engine/users/identify` | 5s | 10s | 3회 | 앱 시작 시 1회 |
| `/engine/prompts/{google_sub}` | 5s | 10s | 3회 | 세션 시작 시 |
| `/incar/profile/{google_sub}` | 5s | 10s | 2회 | 캐시 기반, 빠름 |
| `/engine/query` | 5s | 60s | 2회 | Hybrid Search, 느림 |
| `/engine/voicechat` | 5s | 45s | 1회 | LLM 호출 포함 |
| `/engine/voicechat/surface` | 5s | 45s | 1회 | LLM 호출 포함 |
| `/engine/voicechat/depth` | 5s | 45s | 1회 | LLM 호출 포함 |
| `/engine/voicechat/insight` | 5s | 45s | 1회 | LLM 호출 포함 |
| `/incar/events/batch` | 5s | 15s | 3회 | 비동기 Job에서 호출 |
| `/incar/conversations/{id}/save` | 5s | 30s | 3회 | 비동기 Job에서 호출 |
| `/engine/insights` | 5s | 60s | 2회 | 인사이트 생성/조회 |
| `/incar/memories/store` | 5s | 15s | 3회 | 메모리 저장 |
| `/incar/memories/recall` | 5s | 15s | 2회 | 메모리 recall |

#### OntologyRag::Constants

```ruby
# app/services/ontology_rag/constants.rb
module OntologyRag
  module Constants
    # API Endpoints
    IDENTIFY_USER     = "/engine/users/identify"
    USER_DATA         = "/engine/users/%{google_sub}/data"
    PROMPTS           = "/engine/prompts/%{google_sub}"
    CACHED_PROFILE    = "/incar/profile/%{google_sub}"
    QUERY             = "/engine/query"
    VOICECHAT         = "/engine/voicechat"
    VOICECHAT_SURFACE = "/engine/voicechat/surface"
    VOICECHAT_DEPTH   = "/engine/voicechat/depth"
    VOICECHAT_INSIGHT = "/engine/voicechat/insight"
    EVENTS_BATCH      = "/incar/events/batch"
    CONVERSATION_SAVE = "/incar/conversations/%{session_id}/save"
    INSIGHTS          = "/engine/insights"
    SEARCH_SIMILAR    = "/engine/search/similar"
    MEMORIES_STORE    = "/incar/memories/store"
    MEMORIES_RECALL   = "/incar/memories/recall"

    # App Source (OntologyRAG 사용자 식별용)
    APP_SOURCE = "incar_companion"

    # E/N/G/C 카테고리 (단수형 주의!)
    ENGC_CATEGORIES = %w[emotion need goal constraint].freeze

    # DEPTH 진입 임계값
    DEPTH_EMOTION_THRESHOLD     = 0.8
    DEPTH_REPETITION_THRESHOLD  = 3
    DEPTH_KEYWORDS = [
      "모르겠어", "고민이야", "어떻게 해야 할지", "걱정돼",
      "결정을 못하겠어", "답답해", "힘들어", "불안해"
    ].freeze

    # Phase 목록
    PHASES = %w[opener emotion_expansion free_speech calm re_stimulus].freeze
    LAYERS = %w[surface depth insight].freeze
  end
end
```

#### OntologyRag::Models (Value Objects)

```ruby
# app/services/ontology_rag/models.rb
module OntologyRag
  module Models
    # E/N/G/C Profile (OntologyRAG 응답 구조)
    # 주의: 파라미터명은 단수형 (emotion, need, goal, constraint)
    EngcProfile = Data.define(:emotion, :need, :goal, :constraint, :keywords)
    ProfileItem = Data.define(:category, :content, :intensity, :source, :timestamp)

    # 사용자 식별 응답
    IdentifyResponse = Data.define(:id, :google_sub, :app_source, :is_new)

    # VoiceChat 응답
    VoiceChatResponse = Data.define(:response_text, :phase, :emotion_analysis, :metadata)

    # Hybrid Search 응답
    QueryResult = Data.define(:results, :total_count, :query_metadata)
  end
end
```

### 3.2 VoiceChat 서비스 (대화 엔진 핵심)

```
app/services/voice_chat/
├── phase_transition_engine.rb   # 5-Phase 상태 머신
├── depth_signal_detector.rb     # DEPTH 진입 조건 감지
├── emotion_tracker.rb           # 감정/에너지 실시간 추적
├── narrowing_service.rb         # 질문 범위 좁히기 (개방형 -> 포섭형)
├── context_orchestrator.rb      # 5-Layer 컨텍스트 조합 및 토큰 예산 관리
├── question_generator.rb        # DEPTH Q1-Q4 질문 생성
└── session_manager.rb           # 세션 생성/종료/VoiceChatData 생성
```

#### VoiceChat::PhaseTransitionEngine (5-Phase 상태 머신)

```ruby
# 핵심 책임:
# - 현재 phase에서 다음 phase로의 전환 판단
# - 전환 조건 평가 (메시지 수, 감정 변화, 시간 경과)
# - DEPTH 진입 조건 감지 시 DepthSignalDetector에 위임
# - OntologyRAG /engine/voicechat 호출 조율

# Phase 전환 조건 (Project_B 비즈니스 로직 참조):
#   opener -> emotion_expansion:  사용자 첫 응답 수신 시
#   emotion_expansion -> free_speech:  감정 식별 완료 (2-3 교환 후)
#   free_speech -> calm:  감정 표현 충분 (에너지 수준 안정화 또는 5+ 교환)
#   calm -> re_stimulus:  안정화 확인 (1-2 교환 후)
#   re_stimulus -> [세션 종료]:  긍정적 마무리

# DEPTH 전환 (어느 phase에서든 가능):
#   emotion_level > 0.8  OR
#   DEPTH 키워드 감지  OR
#   같은 주제 3회 이상 반복  OR
#   회피 패턴 감지
```

#### VoiceChat::DepthSignalDetector

```ruby
# 핵심 책임:
# - 메시지 스트림에서 DEPTH 진입 신호 실시간 감지
# - 감정 강도, 키워드, 반복 패턴, 회피 패턴 4가지 신호 모니터링
# - Premium 구독 상태 확인 (Free 사용자는 DEPTH 진입 불가)
# - 신호 감지 시 DepthExploration 레코드 생성

# 감지 알고리즘 (Project_B DepthTriggerDetector 참조):
#   1. emotion_level > DEPTH_EMOTION_THRESHOLD (0.8) -> 즉시 트리거
#   2. DEPTH_KEYWORDS 포함 여부 검사 -> 키워드 매칭 시 트리거
#   3. 주제 유사도 분석 (최근 5개 메시지 비교) -> 반복 3회 이상 시 트리거
#   4. 주제 전환 + 감정 회피 패턴 -> 회피 패턴 감지 시 트리거
```

#### VoiceChat::ContextOrchestrator (5-Layer 컨텍스트 관리)

```ruby
# 핵심 책임:
# - 5계층 컨텍스트를 조합하여 LLM 프롬프트 구성
# - 각 Layer별 토큰 예산 관리 (총 토큰의 비율 배분)
# - 토큰 초과 시 우선순위 기반 트리밍

# 토큰 예산 배분:
#   Layer 1 (Profile):         10%
#   Layer 2 (Past Memory):     20%
#   Layer 3 (Current Session): 30%
#   Layer 4 (Additional Info): 15%
#   Layer 5 (AI Persona):      15%
#   System Overhead:           10%

# 데이터 소스 매핑:
#   Layer 1: OntologyRag::ProfileService#get_cached_profile
#   Layer 2: OntologyRag::QueryService#hybrid_search (관련 과거 대화)
#   Layer 3: Session#messages (현재 세션 메시지)
#   Layer 4: ExternalInfoJob 결과 (Type A-D 수집 정보)
#   Layer 5: Constants (시스템 프롬프트, 페르소나 설정)
```

### 3.3 Insight 서비스

```
app/services/insight/
├── generator.rb          # Q1-Q4 -> Insight 생성 (OntologyRAG LLM 기반)
└── natural_speech.rb     # Insight -> 자연어 발화 변환
```

#### Insight::Generator

```ruby
# 핵심 책임:
# - DepthExploration의 Q1-Q4 결과 + 외부 정보 + 과거 유사 상황을 종합
# - OntologyRag::VoicechatService#insight 호출하여 LLM 기반 인사이트 생성
# - 생성된 인사이트를 Insight 모델에 저장
# - confidence_score 계산 (Q 완료 수, 외부 정보 유무, 과거 데이터 유무 기반)

# 입력 구조:
#   q_results: { q1: String, q2: String, q3: String, q4: String }
#   external_info: Array<ExternalInfo>
#   past_similar: Array<QueryResult>
#   current_context: { time, location, weather, energy_level }
#   engc_profile: EngcProfile

# 출력 구조:
#   Insight 레코드 (situation, decision, action_guide, data_info, natural_speech)
```

### 3.4 Auth 서비스

```
app/services/auth/
├── google_sub_extractor.rb     # OmniAuth -> google_sub 추출
└── subscription_verifier.rb    # RevenueCat 구독 상태 검증
```

#### Auth::GoogleSubExtractor

```ruby
# 핵심 책임:
# - OmniAuth 콜백 데이터에서 google_sub(uid) 추출
# - User 레코드 find_or_create
# - OntologyRAG identify_user 호출 (최초 로그인 시)
# - RevenueCat 고객 생성/연결 (최초 로그인 시)

# OmniAuth 콜백 데이터 구조:
#   auth.uid          -> google_sub
#   auth.info.email   -> email
#   auth.info.name    -> name
#   auth.info.image   -> avatar_url
```

#### Auth::SubscriptionVerifier

```ruby
# 핵심 책임:
# - RevenueCat REST API로 구독 상태 확인
# - user.subscription_tier, user.premium_expires_at 동기화
# - Feature gating 헬퍼 메서드 제공

# 주요 메서드:
#   verify!(user)          -> RevenueCat API 조회 -> user 갱신
#   premium?(user)         -> subscription_tier == "premium" && premium_expires_at > Time.current
#   can_access_depth?(user) -> premium?(user)
#   can_access_insight?(user) -> premium?(user)
#   can_use_external_info?(user) -> premium?(user)
#   daily_session_remaining(user) -> free: 2 - today_count, premium: Float::INFINITY
#   history_accessible?(user, session) -> premium? || session.created_at > 7.days.ago
```

---

## 4. Action Cable 실시간 통신 (Real-time Communication)

### 4.1 Connection 인증

```ruby
# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # 1차: 세션 쿠키 기반 (웹 브라우저 / Turbo Native)
      if (user_id = cookies.encrypted[:user_id])
        User.find_by(id: user_id)
      # 2차: 토큰 기반 (Hotwire Native 앱)
      elsif (token = request.params[:token])
        User.find_by_signed_token(token)
      else
        reject_unauthorized_connection
      end
    end
  end
end
```

### 4.2 VoiceChatChannel

```ruby
# app/channels/voice_chat_channel.rb
class VoiceChatChannel < ApplicationCable::Channel
  # 구독: session_id 기반 스트림
  def subscribed
    @session = current_user.sessions.find(params[:session_id])
    stream_for @session
  end

  # 사용자 메시지 수신 처리
  def send_message(data)
    # 1. 사용자 메시지 저장
    # 2. PhaseTransitionEngine 호출 (phase 전환 판단)
    # 3. EmotionTracker 갱신 (감정/에너지 분석)
    # 4. DepthSignalDetector 확인 (DEPTH 진입 여부)
    # 5. ContextOrchestrator로 프롬프트 구성
    # 6. OntologyRAG VoiceChat API 호출
    # 7. AI 응답 메시지 저장
    # 8. broadcast AI 응답 (Turbo Stream 형태)
  end

  # Phase 수동 전환 (디버그 또는 특수 케이스)
  def update_phase(data)
    # phase 강제 전환 처리
  end

  # 세션 종료
  def end_session(data)
    # 1. Session status -> completed
    # 2. VoiceChatData 생성 (SessionManager)
    # 3. ConversationSaveJob 큐잉
    # 4. EngcEventBatchJob 큐잉 (DEPTH 완료 시)
    # 5. broadcast 세션 종료 알림
  end

  def unsubscribed
    # 비정상 연결 해제 시 세션 상태 보존
  end
end
```

### 4.3 Broadcast 메시지 포맷

```ruby
# AI 응답 broadcast
VoiceChatChannel.broadcast_to(session, {
  type: "message",
  message: {
    id: message.id,
    role: "assistant",
    content: message.content,
    emotion_score: message.emotion_score,
    detected_emotion: message.detected_emotion
  },
  session_state: {
    current_phase: session.current_phase,
    current_layer: session.current_layer,
    emotion_level: session.emotion_level,
    energy_level: session.energy_level
  }
})

# Phase 전환 broadcast
VoiceChatChannel.broadcast_to(session, {
  type: "phase_change",
  from_phase: "emotion_expansion",
  to_phase: "free_speech",
  trigger: "emotion_identified"
})

# DEPTH 진입 broadcast
VoiceChatChannel.broadcast_to(session, {
  type: "layer_change",
  from_layer: "surface",
  to_layer: "depth",
  trigger: "high_emotion",
  current_question: "q1"
})
```

---

## 5. Background Jobs (Solid Queue)

Solid Queue는 SQLite 기반 백그라운드 잡 처리 시스템으로, 별도 Redis 없이 동작한다.

### 5.1 EngcEventBatchJob

```ruby
# app/jobs/engc_event_batch_job.rb
class EngcEventBatchJob < ApplicationJob
  queue_as :default
  retry_on OntologyRag::ServerError, wait: :polynomially_longer, attempts: 3
  retry_on OntologyRag::TimeoutError, wait: :polynomially_longer, attempts: 3
  discard_on OntologyRag::ValidationError  # 잘못된 데이터는 재시도 불필요

  # 트리거: DepthExploration status -> completed 시
  # 동작: Q1-Q4에서 추출된 E/N/G/C 이벤트를 배치 전송
  # API: POST /incar/events/batch
  # 페이로드:
  #   { google_sub, events: [{ engc_category, content, intensity, source }] }
  # 후처리: voice_chat_data.engc_events 갱신
end
```

### 5.2 ConversationSaveJob

```ruby
# app/jobs/conversation_save_job.rb
class ConversationSaveJob < ApplicationJob
  queue_as :default
  retry_on OntologyRag::ServerError, wait: :polynomially_longer, attempts: 3
  retry_on OntologyRag::TimeoutError, wait: :polynomially_longer, attempts: 3

  # 트리거: 세션 종료 시 (Session status -> completed)
  # 동작: 전체 대화 트랜스크립트를 OntologyRAG에 영구 저장
  # API: POST /incar/conversations/{session_id}/save
  # 페이로드:
  #   { google_sub, transcript, weather_data, gps_data, phase_history, metadata }
  # 후처리:
  #   voice_chat_data.ontology_rag_conversation_id = 응답 ID
  #   voice_chat_data.save_status = "saved"
end
```

### 5.3 ProfileSyncJob

```ruby
# app/jobs/profile_sync_job.rb
class ProfileSyncJob < ApplicationJob
  queue_as :low
  retry_on OntologyRag::ServerError, wait: 30.seconds, attempts: 2

  # 트리거: 세션 시작 시 (백그라운드 선행 로드)
  # 동작: OntologyRAG 프로필 조회 -> Solid Cache 갱신
  # API: GET /incar/profile/{google_sub} (캐시 기반, 빠름)
  #       GET /engine/prompts/{google_sub} (실시간, 정확)
  # 후처리: Rails.cache.write("engc_profile:#{google_sub}", profile, expires_in: 1.hour)
end
```

### 5.4 ExternalInfoJob (Premium 전용)

```ruby
# app/jobs/external_info_job.rb
class ExternalInfoJob < ApplicationJob
  queue_as :low
  retry_on StandardError, wait: 1.minute, attempts: 2

  # 트리거: 외부 정보 전략 Type A-D에 따라 다름
  #   Type A: 매일 아침 6시 (cron via Solid Queue recurring)
  #   Type B: EmotionTracker가 특정 상태 감지 시
  #   Type C: Decision 상태가 pending일 때 주기적
  #   Type D: OntologyRAG RAG 검색 기반 (세션 시작 시)
  #
  # 동작: 웹 검색 -> 관련 정보 수집 -> Context Layer 4에 캐시
  # 전제조건: Auth::SubscriptionVerifier.can_use_external_info?(user)
end
```

### 5.5 SubscriptionSyncJob

```ruby
# app/jobs/subscription_sync_job.rb
class SubscriptionSyncJob < ApplicationJob
  queue_as :default
  retry_on Faraday::Error, wait: 30.seconds, attempts: 3

  # 트리거: 앱 시작 시, RevenueCat Webhook 수신 시
  # 동작: RevenueCat API -> user.subscription_tier / premium_expires_at 동기화
  # 후처리: SubscriptionEvent 레코드 생성
end
```

### 5.6 Solid Queue 설정

```yaml
# config/solid_queue.yml
default: &default
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: "default"
      threads: 3
      processes: 1
      polling_interval: 0.1
    - queues: "low"
      threads: 2
      processes: 1
      polling_interval: 1

production:
  <<: *default

development:
  <<: *default
```

---

## 6. RevenueCat 구독 통합 (Subscription Integration)

### 6.1 초기 설정

```ruby
# config/initializers/revenue_cat.rb
module RevenueCat
  BASE_URL = "https://api.revenuecat.com/v1"
  API_KEY = Rails.application.credentials.dig(:revenue_cat, :api_key)

  # Entitlements
  PREMIUM_ENTITLEMENT = "premium_access"

  # Product IDs
  PRODUCTS = {
    monthly: "soletalk_premium_monthly",
    yearly: "soletalk_premium_yearly"
  }.freeze
end
```

### 6.2 Feature Gating (구독 기반 기능 제어)

```ruby
# app/models/concerns/subscription_features.rb
module SubscriptionFeatures
  extend ActiveSupport::Concern

  def premium?
    subscription_tier == "premium" && (premium_expires_at.nil? || premium_expires_at > Time.current)
  end

  def can_access_depth?
    premium?
  end

  def can_access_insight?
    premium?
  end

  def can_use_external_info?
    premium?
  end

  def daily_session_limit
    premium? ? Float::INFINITY : 2
  end

  def daily_sessions_remaining
    return Float::INFINITY if premium?
    2 - sessions.where("created_at >= ?", Time.current.beginning_of_day).count
  end

  def history_retention_days
    premium? ? Float::INFINITY : 7
  end

  def can_access_session?(session)
    premium? || session.created_at > history_retention_days.days.ago
  end
end
```

### 6.3 Webhook 처리

```ruby
# app/controllers/webhooks/revenue_cat_controller.rb
# POST /webhooks/revenue_cat
#
# 처리하는 이벤트 타입:
#   INITIAL_PURCHASE     -> subscription_tier = "premium", premium_expires_at 설정
#   RENEWAL              -> premium_expires_at 갱신
#   CANCELLATION         -> premium_expires_at 유지 (기간 만료까지 사용 가능)
#   EXPIRATION           -> subscription_tier = "free", premium_expires_at = nil
#   BILLING_ISSUE        -> 사용자 알림 (기능은 유지)
#   PRODUCT_CHANGE       -> 플랜 변경 반영
#
# 보안:
#   - RevenueCat Webhook 시크릿으로 서명 검증
#   - revenue_cat_event_id로 중복 처리 방지 (멱등성)
```

### 6.4 구독 상태 확인 흐름

```
앱 시작
  |
  v
Hotwire Native: RevenueCat SDK 초기화
  |
  v
서버: SubscriptionSyncJob 실행
  |
  +-- RevenueCat REST API: GET /subscribers/{app_user_id}
  |
  +-- 응답의 entitlements["premium_access"] 확인
  |
  +-- user.subscription_tier / premium_expires_at 갱신
  |
  v
Feature Gating 적용
  |
  +-- premium? == true  -> 전체 기능 활성화
  +-- premium? == false -> Free Tier 제한 적용
       |
       +-- DEPTH 진입 시도 -> Paywall Turbo Frame 표시
       +-- INSIGHT 접근 시도 -> Paywall Turbo Frame 표시
       +-- 일일 2회 초과 -> Paywall Turbo Frame 표시
```

---

## 7. Hotwire Native 통합 (Mobile Integration)

### 7.1 Native Bridge Components

Hotwire Native는 웹뷰 기반이지만, 네이티브 기능이 필요한 부분은 Bridge Component로 구현한다.

| Bridge Component | 플랫폼 | 기능 | 호출 방식 |
|-----------------|--------|------|----------|
| `AudioCaptureBridge` | Android/iOS | 마이크 캡처 -> STT 변환 | Stimulus -> Bridge message |
| `AudioPlaybackBridge` | Android/iOS | TTS 텍스트 -> 스피커 출력 | Bridge message -> Native |
| `LocationBridge` | Android/iOS | GPS 좌표 수집 | Stimulus -> Bridge message |
| `WeatherBridge` | Android/iOS | 현재 날씨 정보 조회 | Stimulus -> Bridge message |
| `PushNotificationBridge` | Android/iOS | 푸시 알림 등록/수신 | Native -> Bridge message |
| `RevenueCatBridge` | Android/iOS | 구독 구매/복원 UI | Stimulus -> Native Paywall |
| `CarPlayBridge` | iOS | CarPlay 세션 관리 | Native lifecycle |
| `AndroidAutoBridge` | Android | Android Auto 세션 관리 | Native lifecycle |

### 7.2 Turbo Native Path Configuration

```json
{
  "settings": {
    "screenshots_enabled": true
  },
  "rules": [
    {
      "patterns": ["/sessions/\\d+/messages"],
      "properties": {
        "context": "default",
        "uri": "turbo://fragment/voice_chat",
        "presentation": "replace"
      }
    },
    {
      "patterns": ["/insights"],
      "properties": {
        "context": "default",
        "presentation": "push"
      }
    },
    {
      "patterns": ["/settings"],
      "properties": {
        "context": "modal",
        "presentation": "push"
      }
    },
    {
      "patterns": ["/auth/.*"],
      "properties": {
        "context": "modal",
        "presentation": "replace"
      }
    }
  ]
}
```

### 7.3 Tab 네비게이션 구조

```
+---------------------------------------------+
| Tab 1: VoiceChat  | Tab 2: History | Tab 3: Insights | Tab 4: Settings |
+---------------------------------------------+
| /sessions/current  | /sessions     | /insights       | /settings       |
+---------------------------------------------+
```

### 7.4 음성 파이프라인 아키텍처

```
사용자 발화
  |
  v
[Hotwire Native] AudioCaptureBridge
  |  (마이크 캡처 -> 오디오 스트림)
  v
[Native] STT Engine (Google Speech / Apple Speech)
  |  (오디오 -> 텍스트)
  v
[Stimulus Controller] voice_chat_controller.js
  |  (텍스트 -> Action Cable send_message)
  v
[Action Cable] VoiceChatChannel#send_message
  |  (서버 처리 -> AI 응답 생성)
  v
[Action Cable] broadcast 응답
  |
  v
[Stimulus Controller] AI 응답 텍스트 수신
  |
  v
[Hotwire Native] AudioPlaybackBridge
  |  (텍스트 -> TTS Engine -> 스피커 출력)
  v
사용자에게 음성 출력
```

---

## 8. 에러 처리 전략 (Error Handling Strategy)

### 8.1 OntologyRAG API 에러 처리

| HTTP 상태 | 에러 클래스 | 처리 방법 | 사용자 영향 |
|-----------|-----------|----------|-----------|
| 401 | `AuthenticationError` | API Key 확인 -> 알림 | 세션 종료, 재로그인 유도 |
| 404 | `NotFoundError` | 정상 처리 (리소스 없음) | 기본값 사용 |
| 422 | `ValidationError` | 요청 파라미터 수정 | 재시도 없음, 로그 기록 |
| 429 | `RateLimitError` | Retry-After 헤더 파싱 -> 백오프 대기 | 일시적 지연 |
| 500 | `ServerError` | 재시도 3회 (exponential backoff) -> fallback | graceful degradation |
| 503 | `ServiceUnavailableError` | 재시도 후 fallback | graceful degradation |
| Timeout | `TimeoutError` | 재시도 -> 대화 계속 진행 (API 결과 없이) | 응답 지연 또는 기본 응답 |

### 8.2 Graceful Degradation 전략

OntologyRAG API가 실패해도 핵심 대화 경험은 유지한다.

```ruby
# Fallback 우선순위:
# 1. Solid Cache에서 캐시된 데이터 사용
# 2. 로컬 SQLite 데이터만으로 대화 진행
# 3. 기본 시스템 프롬프트로 LLM 호출 (프로필/기억 없이)
# 4. 사전 정의된 기본 응답 ("네, 더 이야기해 주세요")

# API 실패 시 동작:
#   프로필 로드 실패 -> 캐시 프로필 사용 -> 없으면 기본 프로필
#   Hybrid Search 실패 -> 과거 기억 없이 현재 세션만으로 진행
#   VoiceChat API 실패 -> 로컬 PhaseTransitionEngine만으로 phase 관리
#   Event Batch 실패 -> 로컬 저장 후 다음 세션에서 재시도
#   Conversation Save 실패 -> 로컬 보관 후 백그라운드 재시도
```

### 8.3 Global Error Handling

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::RoutingError, with: :not_found
  rescue_from OntologyRag::AuthenticationError, with: :api_auth_error
  rescue_from OntologyRag::RateLimitError, with: :rate_limited
  rescue_from OntologyRag::ApiError, with: :api_error

  private

  def not_found
    respond_to do |format|
      format.html { render "errors/not_found", status: :not_found }
      format.json { render json: { error: "Not Found" }, status: :not_found }
    end
  end

  def api_auth_error(exception)
    Rails.logger.error("OntologyRAG Auth Error: #{exception.message}")
    # 사용자에게는 일반 에러로 표시, 내부적으로는 API Key 확인 알림
  end

  def rate_limited(exception)
    Rails.logger.warn("OntologyRAG Rate Limited: retry after #{exception.retry_after}s")
    # 429 상태와 Retry-After 전달
  end

  def api_error(exception)
    Rails.logger.error("OntologyRAG API Error: #{exception.class} - #{exception.message}")
    # graceful degradation 적용
  end
end
```

### 8.4 OntologyRag 커스텀 에러 계층

```ruby
# app/services/ontology_rag/errors.rb
module OntologyRag
  class ApiError < StandardError
    attr_reader :status, :body

    def initialize(message = nil, status: nil, body: nil)
      @status = status
      @body = body
      super(message || "OntologyRAG API Error (#{status})")
    end
  end

  class AuthenticationError < ApiError; end   # 401
  class NotFoundError < ApiError; end         # 404
  class ValidationError < ApiError; end       # 422
  class RateLimitError < ApiError              # 429
    attr_reader :retry_after
    def initialize(message = nil, retry_after: 60, **kwargs)
      @retry_after = retry_after
      super(message, **kwargs)
    end
  end
  class ServerError < ApiError; end           # 500
  class ServiceUnavailableError < ApiError; end # 503
  class TimeoutError < ApiError; end          # Timeout
end
```

---

## 9. 캐시 전략 (Caching Strategy - Solid Cache)

Solid Cache는 SQLite 기반 캐시 저장소로, Redis 없이 동작한다.

### 9.1 캐시 대상 및 정책

| 데이터 | 캐시 키 패턴 | TTL | 갱신 시점 | 비고 |
|--------|------------|-----|----------|------|
| E/N/G/C 프로필 (캐시) | `engc_profile:#{google_sub}` | 1 hour | 세션 시작 시 ProfileSyncJob | `/incar/profile` 응답 |
| E/N/G/C 프로필 (실시간) | `engc_realtime:#{google_sub}` | 30 min | DEPTH 진입 시 | `/engine/prompts` 응답 |
| 사용자 프로필 | `user_profile:#{google_sub}` | 30 min | 로그인 시, 세션 시작 시 | 기본 정보 |
| 외부 정보 (Type A) | `ext_info:interest:#{keyword}` | 24 hours | ExternalInfoJob (매일 아침) | 관심사 뉴스 |
| 외부 정보 (Type C) | `ext_info:decision:#{decision_id}` | 6 hours | ExternalInfoJob (주기적) | 의사결정 관련 정보 |
| AI 페르소나 프롬프트 | `persona:#{user_id}` | until_changed | 설정 변경 시 무효화 | 시스템 프롬프트 |
| 세션 일일 카운트 | `daily_sessions:#{user_id}:#{date}` | end_of_day | 세션 생성 시 increment | Free 사용자 제한 |
| 구독 상태 | `subscription:#{user_id}` | 5 min | SubscriptionSyncJob | RevenueCat 상태 |

### 9.2 캐시 무효화 전략

```ruby
# 이벤트 기반 캐시 무효화
# - 세션 종료 -> engc_profile 무효화 (새 이벤트 저장 후 프로필 변경 가능)
# - 설정 변경 -> persona 캐시 무효화
# - 구독 변경 -> subscription 캐시 무효화
# - DEPTH 완료 -> engc_realtime 무효화

# 예시:
Rails.cache.delete("engc_profile:#{user.google_sub}")
Rails.cache.delete("persona:#{user.id}")
```

### 9.3 Solid Cache 설정

```yaml
# config/cache.yml
production:
  database: cache
  max_age: 604800  # 7일 (기본 최대 보관)
  max_size: 268435456  # 256MB

development:
  database: cache
  max_age: 86400  # 1일
  max_size: 67108864  # 64MB
```

---

## 10. 보안 설계 (Security Design)

### 10.1 인증 흐름 (Authentication Flow)

```
1. 사용자가 "Google로 로그인" 버튼 클릭
   |
   v
2. Hotwire Native -> 시스템 브라우저 -> Google OAuth 페이지
   |
   v
3. 사용자가 Google 계정 선택/로그인
   |
   v
4. Google -> 콜백 URL (redirect_uri) 로 authorization code 전달
   |
   v
5. Rails OmniAuth:
   GET /auth/google_oauth2/callback
   -> Auth::GoogleSubExtractor 호출
   -> auth.uid = google_sub 추출
   -> User.find_or_create_by(google_sub: auth.uid)
   |
   v
6. 최초 로그인 시:
   -> OntologyRag::UserService#identify(google_sub, "incar_companion")
   -> user.ontology_rag_id = 응답.id
   -> RevenueCat 고객 생성 (revenue_cat_id 저장)
   |
   v
7. 세션 쿠키 설정 (cookies.encrypted[:user_id] = user.id)
   |
   v
8. Hotwire Native 앱으로 리다이렉트
```

### 10.2 인가 (Authorization)

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :require_authentication

  private

  def require_authentication
    unless current_user
      respond_to do |format|
        format.html { redirect_to root_path, alert: "로그인이 필요합니다." }
        format.json { head :unauthorized }
      end
    end
  end

  def current_user
    @current_user ||= User.find_by(id: cookies.encrypted[:user_id])
  end

  # 리소스 소유권 검증
  def authorize_resource!(resource)
    unless resource.user_id == current_user.id
      raise ActiveRecord::RecordNotFound
    end
  end

  # Premium 기능 접근 검증
  def require_premium!
    unless current_user.premium?
      respond_to do |format|
        format.html { redirect_to subscription_path, alert: "Premium 구독이 필요합니다." }
        format.json { render json: { error: "Premium required" }, status: :payment_required }
      end
    end
  end
end
```

### 10.3 API Key 관리

```ruby
# Rails Credentials (암호화 저장)
# config/credentials.yml.enc (RAILS_MASTER_KEY로 복호화)
#
# ontology_rag:
#   api_key: sk_master_xxxxxxxxxxxxxxxxxxxxxxxxxxxx
#
# revenue_cat:
#   api_key: appl_xxxxxxxxxxxxxxxxxxxxxxxx
#   webhook_secret: whsec_xxxxxxxxxxxxxxxxxxxxxxxx
#
# google_oauth:
#   client_id: xxxxxxxxxxxx.apps.googleusercontent.com
#   client_secret: GOCSPX-xxxxxxxxxxxxxxxxxxxxxxx

# 환경변수 (credentials 대안, 개발 환경용)
# .env 파일 (gitignore 대상)
# ONTOLOGY_RAG_BASE_URL=https://ontologyrag01-production.up.railway.app
# ONTOLOGY_RAG_API_KEY=sk_master_xxx
```

### 10.4 데이터 보호

| 보호 대상 | 보호 방법 | 비고 |
|----------|----------|------|
| 대화 내용 (SQLite) | 디바이스 암호화 의존 | Android: EncryptedSharedPreferences, iOS: Data Protection |
| API 통신 | HTTPS 전용 (TLS 1.2+) | Faraday SSL 설정 |
| API Key | Rails credentials (암호화) | RAILS_MASTER_KEY 별도 관리 |
| 세션 쿠키 | `cookies.encrypted` | AES-256-GCM |
| 사용자 비밀번호 | 없음 (Google OAuth 위임) | 비밀번호 저장 불필요 |
| RevenueCat Webhook | HMAC 서명 검증 | webhook_secret으로 검증 |

### 10.5 OWASP 대응

| 위협 | Rails 기본 대응 | 추가 조치 |
|------|---------------|----------|
| CSRF | `protect_from_forgery` (기본 활성) | API 네임스페이스는 `skip_forgery_protection` + token 인증 |
| XSS | ERB auto-escaping (기본 활성) | `Content-Security-Policy` 헤더 설정 |
| SQL Injection | ActiveRecord parameterized queries | 원시 SQL 금지 원칙 |
| Mass Assignment | Strong Parameters | 모든 컨트롤러에서 permit 명시 |

---

## 11. 테스트 전략 (Testing Strategy)

### 11.1 테스트 스택

| 목적 | 도구 | 비고 |
|------|------|------|
| Unit Test | Minitest | Rails 기본 |
| Integration Test | Minitest + ActionDispatch | 컨트롤러/라우팅 |
| System Test | Capybara + Selenium | E2E (브라우저) |
| API Mocking | WebMock + VCR | OntologyRAG API 모킹 |
| Fixture/Factory | Minitest Fixtures | Rails 기본 |
| Lint | RuboCop (rubocop-rails-omakase) | 코드 스타일 |
| Security | Brakeman | 정적 보안 분석 |

### 11.2 테스트 디렉토리 구조

```
test/
├── controllers/
│   ├── api/v1/
│   │   ├── sessions_controller_test.rb
│   │   ├── messages_controller_test.rb
│   │   ├── insights_controller_test.rb
│   │   ├── subscriptions_controller_test.rb
│   │   └── ...
│   ├── auth/
│   │   └── omniauth_callbacks_controller_test.rb
│   └── webhooks/
│       └── revenue_cat_controller_test.rb
├── models/
│   ├── user_test.rb
│   ├── session_test.rb
│   ├── message_test.rb
│   ├── depth_exploration_test.rb
│   ├── insight_test.rb
│   └── ...
├── services/
│   ├── ontology_rag/
│   │   ├── client_test.rb
│   │   ├── user_service_test.rb
│   │   ├── profile_service_test.rb
│   │   ├── query_service_test.rb
│   │   └── ...
│   ├── voice_chat/
│   │   ├── phase_transition_engine_test.rb
│   │   ├── depth_signal_detector_test.rb
│   │   ├── emotion_tracker_test.rb
│   │   ├── context_orchestrator_test.rb
│   │   └── ...
│   ├── insight/
│   │   ├── generator_test.rb
│   │   └── natural_speech_test.rb
│   └── auth/
│       ├── google_sub_extractor_test.rb
│       └── subscription_verifier_test.rb
├── jobs/
│   ├── engc_event_batch_job_test.rb
│   ├── conversation_save_job_test.rb
│   ├── profile_sync_job_test.rb
│   └── external_info_job_test.rb
├── channels/
│   └── voice_chat_channel_test.rb
├── fixtures/
│   ├── users.yml
│   ├── sessions.yml
│   ├── messages.yml
│   └── ...
├── vcr_cassettes/           # VCR 녹화 파일 (OntologyRAG API 응답)
│   ├── identify_user.yml
│   ├── get_profile.yml
│   ├── hybrid_search.yml
│   └── ...
└── test_helper.rb
```

### 11.3 TDD 워크플로우 (Kent Beck)

PRD 및 CLAUDE.md에 명시된 TDD 원칙을 따른다.

```
1. Red:   실패하는 테스트를 하나 작성한다
2. Green: 테스트를 통과시키는 최소한의 코드를 작성한다
3. Refactor: 테스트가 통과하는 상태에서 코드를 정리한다
```

**Tidy First 접근법**:
- **구조적 변경**: 동작 변화 없이 코드 재배치 (rename, extract method)
- **행동적 변경**: 실제 기능 추가/수정
- 두 유형의 변경을 같은 커밋에 섞지 않는다
- 항상 구조적 변경을 먼저 수행한다

**커밋 규율**:
- 모든 테스트가 통과할 때만 커밋한다
- RuboCop 경고를 해결한 후 커밋한다
- 하나의 논리적 작업 단위로 커밋한다

### 11.4 OntologyRAG API 테스트 전략

```ruby
# test/test_helper.rb
# WebMock: 모든 외부 HTTP 요청 차단
WebMock.disable_net_connect!(allow_localhost: true)

# VCR: OntologyRAG API 응답 녹화/재생
VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data("<ONTOLOGY_RAG_API_KEY>") { ENV["ONTOLOGY_RAG_API_KEY"] }
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body]
  }
end

# 테스트 헬퍼: OntologyRAG API 스텁
module OntologyRagTestHelper
  def stub_identify_user(google_sub:, is_new: false)
    stub_request(:post, "#{OntologyRag::Client::BASE_URL}/engine/users/identify")
      .with(body: hash_including(google_sub: google_sub))
      .to_return(
        status: 200,
        body: { id: SecureRandom.uuid, google_sub: google_sub, is_new: is_new }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_get_profile(google_sub:, profile: default_engc_profile)
    stub_request(:get, "#{OntologyRag::Client::BASE_URL}/incar/profile/#{google_sub}")
      .to_return(
        status: 200,
        body: profile.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  # ... 각 엔드포인트별 스텁 메서드
end
```

---

## 12. 참조 문서 (References)

### 12.1 프로젝트 설계 문서

| 문서 | 경로 | 목적 |
|------|------|------|
| **CLAUDE.md** | `CLAUDE.md` | Project_A 마스터 설계 가이드 |
| **PRD.md** | `docs/PRD.md` | 제품 요구사항 정의서 |

### 12.2 분석 보고서 (`docs/ondev/`)

| 문서 | 경로 | 목적 |
|------|------|------|
| **Project_B 분석** | `docs/ondev/20260212_01_project_b_analysis.md` | VoiceChat 엔진 로직, 도메인 모델 |
| **Project_C 분석** | `docs/ondev/20260212_02_project_c_analysis.md` | OntologyRAG 통합 패턴 |
| **Project_E API 분석** | `docs/ondev/20260212_03_project_e_api_analysis.md` | 전체 API 스펙 |
| **종합 마이그레이션 평가** | `docs/ondev/20260212_04_comprehensive_migration_assessment.md` | Fresh build 의사결정 근거 |

### 12.3 참조 자료 (`docs/ref/`)

| 문서 | 경로 | 목적 |
|------|------|------|
| **VoiceChat Engine v2** | `docs/ref/20251206_VoiceChat_Engine_Ideation_v2.md` | 3-Layer 아키텍처 비전 |
| **3-Project 통합 계획** | `docs/ref/20251212_07_3project_integrated_development_plan.md` | 통합 아키텍처/API |
| **Architecture Insights** | `docs/ref/20251222_Architecture_Integration_Insights.md` | 도메인 모델/E2E 패턴 |
| **TDD Methodology** | `docs/ref/251115_KentBeck_TDD.md` | TDD 워크플로우 |

### 12.4 참조 프로젝트

| 프로젝트 | 경로 | 역할 |
|---------|------|------|
| **Project_A** (본 프로젝트) | `~/Project/Project_A` | Rails + Hotwire Native (신규 구축) |
| **Project_B** (비즈니스 로직 참조) | `~/Project/Project_B` | Kotlin/Android -- VoiceChat 엔진, 도메인 모델 |
| **Project_C** (API 패턴 참조) | `~/Project/Project_C` | React Native -- OntologyRAG "골드 스탠다드" |
| **Project_E** (OntologyRAG) | `~/Project/Project_E` | API 백엔드 (consumption only) |

---

*본 문서는 SoleTalk (Project_A) 프로젝트의 Low-Level Design을 정의하며, 개발 진행에 따라 업데이트될 수 있습니다.*
*최종 수정일: 2026-02-12*
