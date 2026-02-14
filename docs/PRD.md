# SoleTalk PRD (Product Requirements Document)

**버전**: 1.0
**작성일**: 2026-02-12
**프로젝트**: SoleTalk (Project_A) - Ruby on Rails 8 + Hotwire Native
**상태**: Draft

---

## 1. 프로젝트 개요 (Project Overview)

### 1.1 비전 (Vision)

**핵심 미션**: 일상을 중심으로 사용자의 일과를 자동으로 메모하고, LLM 기반의 자연스러운 추론 능력을 통해 대화를 통한 개인화된 메모리를 생성하는 앱 컴패니언.

**타겟 사용자**: 차량에서 최대한 많은 시간 동안 대화하며 시간을 보내는 사용자 (출퇴근 등)

**SoleTalk = Solo + Talk**: 혼자 있는 공간에서의 솔직한 대화

| 핵심 요소 | 설명 | 제품 활용 |
|----------|------|----------|
| **Privacy** (프라이버시) | 차 안이라는 완전히 혼자인 공간 | 솔직한 감정 표현 유도, 판단 없는 안전한 환경 |
| **Time** (시간) | 고정된 출퇴근 시간 (평균 30분~1시간) | 예측 가능한 세션 길이, 습관 형성 가능 |
| **State** (상태) | 출근 = 계획 모드, 퇴근 = 회고 모드 | 시간대별 대화 전략 최적화 |

**제품 차별점**:
- 단순 음성 비서가 아닌 "대화를 통한 자기 이해" 도구
- 시간이 지날수록 개인화되는 Personal Ontology 기반 메모리
- 표면적 대화에서 깊은 자기 성찰까지 자연스럽게 유도하는 3-Layer 구조
- 과거 대화를 기억하고 자연스럽게 후속 질문을 던지는 관계적 대화

### 1.2 기술 스택 (Technology Stack)

| 카테고리 | 기술 | 비고 |
|----------|------|------|
| **Backend** | Ruby on Rails 8 | Convention over Configuration |
| **Frontend** | Hotwire (Turbo Frames/Streams + Stimulus) | SPA-like 경험 |
| **Mobile** | Hotwire Native (Android/iOS) | 네이티브 브릿지 활용 |
| **Database** | SQLite | Rails 8 기본 DB |
| **Real-time** | Action Cable (Solid Cable) | WebSocket 기반 실시간 통신 |
| **Background Jobs** | Solid Queue | Rails 8 내장 큐 시스템 |
| **Cache** | Solid Cache | Rails 8 내장 캐시 |
| **External API** | OntologyRAG (Project_E) | Faraday HTTP 클라이언트 |
| **Auth** | OmniAuth Google OAuth2 | google_sub 기반 식별 |
| **Subscription** | RevenueCat | 인앱 구독 관리 |
| **Web Server** | Puma | Rails 기본 웹서버 |

### 1.3 빌드 접근 방식 (Build Approach)

**"정보 참조형 신규 구축 (Informed Fresh Build)"**

기존 Project_B(Kotlin/Android), Project_C(React Native)의 비즈니스 로직과 도메인 지식을 **참조**하되, Rails 생태계에 맞게 완전히 새로 설계하고 구축한다. 코드 마이그레이션이 아닌, 도메인 지식 마이그레이션이다.

**Project_B에서 가져오는 것**:
- 그대로 복사: 시스템 프롬프트, Phase 전환 임계값, 감정 키워드, API 상수, 프롬프트 텍스트
- Ruby로 재작성: Phase 전환 규칙, 감정/에너지 추적, Narrowing 서비스, DEPTH Q1-Q4, Insight 생성

**Project_C에서 가져오는 것**:
- OntologyRAG 통합 패턴 (ontology-rag.service.ts를 "골드 스탠다드"로 참조)
- google_sub 식별 패턴
- ENGC 이벤트 패턴

**Project_E에서 가져오는 것**:
- API 스펙 및 엔드포인트 우선순위
- 타임아웃/리트라이 설정

**새로 설계하는 영역 (Rails-Native)**:
- Hotwire Native 모바일 앱 구조
- Rails 컨트롤러/뷰 (Turbo Frames/Streams + Stimulus)
- Action Cable 실시간 통신
- 인증 (OmniAuth Google OAuth)
- DB 스키마 (ActiveRecord / SQLite)
- 음성 파이프라인 (Hotwire Native 네이티브 브릿지)
- Background Jobs (Solid Queue)

---

## 2. 핵심 아키텍처 (Core Architecture)

### 2.1 3-Layer Personal Ontology Engine

SoleTalk의 핵심 대화 엔진은 3개의 계층으로 구성된다. 표면적 대화에서 시작하여, 감정 신호가 감지되면 깊은 탐색으로 전환하고, 최종적으로 실행 가능한 인사이트를 생성한다.

```
+------------------------------------------------------------+
|  SURFACE LAYER - 5-Phase VoiceChat Engine                  |
|  Opener -> Emotion Expansion -> Free Speech                |
|         -> Calm -> Re-stimulus                             |
+------------------------------------------------------------+
                          |
                          v (emotion_level > 0.7)
+------------------------------------------------------------+
|  DEPTH LAYER - 4 Core Questions Framework                  |
|  Q1. WHY     (UNCOVER)     - 진짜 감정 발견               |
|  Q2. DECISION (CRYSTALLIZE) - 의사결정 결정화              |
|  Q3. IMPACT   (MEASURE)     - 영향 측정                   |
|  Q4. DATA     (CONNECT)     - 필요 정보 연결              |
+------------------------------------------------------------+
                          |
                          v
+------------------------------------------------------------+
|  INSIGHT LAYER - Actionable Guidance Generation            |
|  "지금은 [상황]이고, [정보/이유] 때문에,                   |
|   [목적]을 위해서, 지금은 [행동 가이드]가 좋을 것 같아요." |
+------------------------------------------------------------+
```

**SURFACE Layer (5-Phase VoiceChat Engine)**:

| Phase | 이름 | 목적 | 상세 |
|-------|------|------|------|
| 1 | **Opener** (입력기) | 대화 시작 | 최근 KeyInfo + 날씨 기반 LLM 첫 질문. 관심사 업데이트나 과거 대화 후속 질문으로 시작 가능 |
| 2 | **Emotion Expansion** (감정확장) | 감정 파악 | 사용자 첫 발화에서 감정 상태 식별 및 공감적 반응 |
| 3 | **Free Speech** (자유발화) | 자유 표현 | 고민/사건에 대한 자유로운 표현 유도. 적극적 경청과 공감 |
| 4 | **Calm** (정적) | 안정화 | 감정 표출 후 안정화 순간 제공. 침묵 허용, 부드러운 요약 |
| 5 | **Re-stimulus** (재자극) | 새 관점 | 긍정적 방향 또는 새로운 관점 제시. 다음 행동 유도 |

**DEPTH Layer (4 Core Questions - emotion_level > 0.7 시 진입)**:

| Phase | 질문 | 코드명 | 목적 | 기법 |
|-------|------|--------|------|------|
| Q1 | WHY | UNCOVER | 표면 감정 뒤의 진짜 감정/이유 발견 | Reflection ("~라고 느끼신 거네요"), Body Sensation ("몸 어디가 반응해요?"), Time Expansion ("비슷한 느낌 받았던 적?") |
| Q2 | DECISION | CRYSTALLIZE | 막연한 고민을 구체적 의사결정으로 결정화 | "지금 한 가지만 바꿀 수 있다면?", "하지 않은 이유가 있나요?" |
| Q3 | IMPACT | MEASURE | 결정의 다차원 영향 구체화 | 감정/관계/직장/재무/심리 차원별 Best/Worst/Most Likely 시나리오 분석 |
| Q4 | DATA | CONNECT | 의사결정에 필요한 정보 식별 및 연결 | 외부 정보(웹 검색), 과거 경험(RAG), 타인 경험, 내면 정보(Q1 참조) |

**INSIGHT Layer (Actionable Guidance)**:
- Q1-Q4 결과를 종합하여 실행 가능한 행동 가이드 생성
- 출력 형식: "지금은 [상황]이고, [정보/이유] 때문에, [목적]을 위해서, 지금은 [행동 가이드]가 좋을 것 같아요"
- 외부 정보 + 과거 유사 경험 + 현재 컨텍스트(시간, 위치, 사용자 상태)를 모두 반영

### 2.2 Context Layering Architecture

LLM 프롬프트 구성 시 5개 레이어의 컨텍스트를 비율에 따라 조합한다.

| Layer | 비율 | 이름 | 설명 | 데이터 소스 |
|-------|------|------|------|------------|
| 1 | 10% | **Profile** (프로필) | 기본정보 및 관심 키워드 | OntologyRAG ENGC 프로파일 |
| 2 | 20% | **Past Memory** (과거 기억) | 관련 이전 대화 검색 | OntologyRAG hybrid search (Vector + Graph) |
| 3 | 30% | **Current Session** (현재 세션) | 현재 대화 내용 및 업로드 파일 | 로컬 SQLite (실시간) |
| 4 | 15% | **Additional Info** (추가 정보) | 웹 조사 정보 (외부 지식 통합) | 외부 정보 전략 Type A-D |
| 5 | 15% | **AI Persona** (AI 성격) | AI 성격, 행동 지침, 대화 스타일 | 시스템 프롬프트 + 사용자 설정 |

> 나머지 10%는 시스템 오버헤드 및 구조화 토큰에 할당

### 2.3 System Architecture Diagram

```
+-------------------------------------------------------------+
|                  SoleTalk (Project_A)                        |
|                Ruby on Rails 8 + Hotwire Native              |
+-------------------------------------------------------------+
|                                                              |
|  +------------------+  +------------------------------+     |
|  |  Hotwire Native  |  |  Rails Server                |     |
|  |  (Android/iOS)   |--|  - Turbo Frames/Streams      |     |
|  |                  |  |  - Stimulus Controllers       |     |
|  |  - 음성 입력     |  |  - Action Cable (WebSocket)   |     |
|  |  - 네이티브 브릿지|  |  - Solid Queue (Background)   |     |
|  +------------------+  +--------------+-----------------+     |
|                                       |                      |
|  +------------------------------------+                      |
|  |                                    |                      |
|  v                                    v                      |
|  +--------------+          +----------------------+          |
|  |   SQLite     |          |  OntologyRAG Client  |          |
|  |  (Local DB)  |          |  (Faraday HTTP)      |          |
|  |              |          |                      |          |
|  | - users      |          |  API Endpoints:      |          |
|  | - sessions   |          |  /engine/identify    |          |
|  | - messages   |          |  /engine/prompts     |          |
|  | - settings   |          |  /engine/query       |          |
|  | - cache      |          |  /incar/events/batch |          |
|  +--------------+          |  /incar/conversations|          |
|                            +-----------+----------+          |
|                                        |                     |
+----------------------------------------+---------------------+
                                         |
                                         v
                              +----------------------+
                              |   Project_E          |
                              |   (OntologyRAG)      |
                              |   FastAPI + Neo4j    |
                              |   + pgvector         |
                              +----------------------+
```

---

## 3. 기능 요구사항 (Functional Requirements)

### 3.1 인증 (Authentication)

**FR-AUTH-001**: Google OAuth2 로그인
- OmniAuth `google_oauth2` 전략 사용
- google_sub (auth.uid) 기반 사용자 식별
- OntologyRAG 크로스앱 식별자로 google_sub 공유

**FR-AUTH-002**: 사용자 등록/식별
- 최초 로그인 시 OntologyRAG `/engine/users/identify` 호출
- `app_source`: "incar_companion" (Project_B 호환)
- `platform_id`: "soletalk-rails"

**FR-AUTH-003**: 세션 관리
- Rails 세션 기반 인증 상태 유지
- 자동 토큰 갱신 (Google OAuth refresh token)
- 비활성 세션 자동 만료

**FR-AUTH-004**: 인가 (Authorization)
- Rails 네이티브 인가 (SpiceDB 미사용)
- `before_action` 기반 접근 제어
- Policy Object 패턴으로 권한 분리

### 3.2 VoiceChat Engine

**FR-VC-001**: 5-Phase 상태 머신
- Phase 전환 엔진 (`PhaseTransitionEngine`)
- 각 Phase별 전환 조건 및 규칙 (Project_B 참조)
- Phase 간 자연스러운 전환 (hard cut 없이 맥락 유지)

**FR-VC-002**: Narrowing Principle
- 대화 초기: 개방형 질문 ("오늘 하루 어떠셨어요?")
- 대화 중기: 탐색적 질문 (감정/주제 구체화)
- 대화 후기: 포섭형 질문 ("그렇다면 ~~해보실래요?")

**FR-VC-003**: DEPTH Signal Detection
- 감정 강도 감지: `emotion_level > 0.8`
- 키워드 감지: "모르겠어", "걱정돼", "어떻게 해야 할지"
- 반복 주제 감지: 동일 주제 3회 이상 반복
- 회피 패턴 감지: 주제 회피 행동 식별

**FR-VC-004**: 4 Core Questions (Q1-Q4)
- Q1 (WHY/UNCOVER): Reflection, Body Sensation, Time Expansion 기법
- Q2 (DECISION/CRYSTALLIZE): 구체적 의사결정 도출
- Q3 (IMPACT/MEASURE): 다차원 영향 분석 (감정/관계/직장/재무/심리)
- Q4 (DATA/CONNECT): 필요 정보 식별 및 외부 정보 연결

**FR-VC-005**: Insight 생성
- Q1-Q4 답변 종합 -> 행동 가이드 생성
- 자연어 변환 (NaturalSpeech 서비스)
- 외부 정보 + 과거 유사 경험 + 현재 컨텍스트 반영

**FR-VC-006**: 세션 종료 처리
- VoiceChat Data 생성: 날씨 + GPS + 전체 대화 텍스트
- `POST /incar/conversations/{session_id}/save` 호출
- 자동 E/N/G/C 추출 (OntologyRAG 서버 측)
- Background Job으로 비동기 처리 (Solid Queue)

**FR-VC-007**: 실시간 통신
- Action Cable (WebSocket) 기반 실시간 메시지 교환
- VoiceChatChannel을 통한 양방향 스트리밍
- 음성 -> 텍스트 변환은 Hotwire Native 네이티브 브릿지 담당

### 3.3 외부 정보 전략 (External Information Strategy - 4 Types)

**FR-EI-001**: Type A - Interest Updates (관심사 업데이트)
- Profile Layer 키워드 기반 주기적 뉴스/정보 검색
- 대화 시작 시 자연스럽게 제공
- 예시 발화: "참, 오늘 [AI 규제] 관련 뉴스가 있더라고요"
- 수집 타이밍: Background Job (매일 아침)

**FR-EI-002**: Type B - State-based Info (상태 기반 정보)
- 감지된 상태(피로, 스트레스 등) -> 관련 정보 검색
- 공감 + 정보 제공 조합
- 예시 발화: "피곤해 보이시네요, 도움이 될 만한 정보를 찾았어요"
- 수집 타이밍: 실시간 (상태 감지 시)

**FR-EI-003**: Type C - Decision-related (의사결정 관련)
- Pending Decision -> 관련 정보 자동 수집 (시장 동향, 통계 등)
- 의사결정 지원 목적
- 예시 발화: "이직을 고민하신다고 했는데, 관련 정보를 찾아봤어요"
- 수집 타이밍: Background Job (Pending Decision 존재 시 주기적)

**FR-EI-004**: Type D - Past Conversation Follow-up (과거 대화 후속)
- RAG 검색으로 과거 언급된 이벤트/계획 파악
- 시간 경과 후 자연스러운 후속 질문
- 예시 발화: "지난번에 팀장님과 미팅이 있다고 하셨는데, 어떻게 됐어요?"
- 수집 타이밍: 세션 시작 전 (과거 대화 기반)

**정보 수집 타이밍 요약**:

| 타이밍 | 수집 내용 | 처리 방식 |
|--------|----------|----------|
| **사전 수집 (Background)** | 매일 아침 관심 키워드 뉴스, 세션 전 날씨/교통, Pending Decision 업데이트 | Solid Queue Background Job |
| **실시간 수집 (On-demand)** | 사용자가 특정 주제 언급 시, Q4(DATA) Phase 진입 시 | 동기 또는 비동기 처리 |
| **후속 수집 (Follow-up)** | 세션 종료 후 새 키워드 기반 수집, Decision 업데이트 시 | Solid Queue Scheduled Job |

### 3.4 OntologyRAG 연동 (API Integration)

**API 공통 설정**:

```
Base URL: ENV['ONTOLOGY_RAG_BASE_URL']
  (Production: https://ontologyrag01-production.up.railway.app)

Headers:
  X-API-Key: ENV['ONTOLOGY_RAG_API_KEY']
  X-Source-App: "soletalk-rails"
  X-Request-ID: "soletalk-{timestamp}"
  Content-Type: application/json

Rate Limit: 1,000 requests/hour per API key
```

**P0 (필수 - MVP 블로커)**:

| 엔드포인트 | 메서드 | 용도 | 타임아웃 | Rails 서비스 |
|-----------|--------|------|---------|-------------|
| `/engine/users/identify` | POST | 사용자 등록/식별 | Connect 5s / Read 10s | `OntologyRag::Client#identify_user` |
| `/engine/prompts/{google_sub}` | GET | ENGC 프로파일 조회 (실시간, 정확) | Connect 5s / Read 10s | `OntologyRag::Client#get_profile` |
| `/incar/events/batch` | POST | ENGC 이벤트 배치 저장 | Connect 5s / Read 15s | `EngcEventBatchJob` |
| `/incar/conversations/{session_id}/save` | POST | 대화 저장 | Connect 5s / Read 30s | `ConversationSaveJob` |

**P1 (핵심 - VoiceChat 핵심 기능)**:

| 엔드포인트 | 메서드 | 용도 | 타임아웃 | Rails 서비스 |
|-----------|--------|------|---------|-------------|
| `/engine/query` | POST | 하이브리드 검색 (Vector + Graph) | Connect 5s / Read 60s | `OntologyRag::Client#query` |
| `/incar/profile/{google_sub}` | GET | 캐시된 프로파일 (빠름) | Connect 5s / Read 10s | `OntologyRag::Client#get_cached_profile` |
| `/engine/voicechat` | POST | VoiceChat 3계층 엔드포인트 | Connect 5s / Read 45s | `VoiceChat::PhaseTransitionEngine` |

**P2 (확장 - 고급 기능)**:

| 엔드포인트 | 메서드 | 용도 | 타임아웃 |
|-----------|--------|------|---------|
| `/engine/insights` | POST/GET | Insight 저장/조회 | Connect 5s / Read 60s |
| `/engine/search/similar` | POST | 유사 문서 검색 | Connect 5s / Read 15s |
| `/incar/memories/store` | POST | 메모리 저장 | Connect 5s / Read 15s |
| `/incar/memories/recall` | GET | 메모리 회상 | Connect 5s / Read 15s |

**프로필 엔드포인트 사용 전략**:

| 용도 | 엔드포인트 | 특성 |
|------|-----------|------|
| 세션 시작 (속도 우선) | `GET /incar/profile/{google_sub}` | 캐시 기반, 빠름, 약간 stale 가능 |
| DEPTH 분석 (정확성 우선) | `GET /engine/prompts/{google_sub}` | 실시간 집계, 느림, 항상 최신 |

**API 에러 처리 전략**:
- Faraday + faraday-retry를 활용한 자동 재시도 (최대 3회, 지수 백오프)
- 타임아웃 시 graceful degradation (캐시된 데이터 활용)
- Rate Limit 초과 시 큐잉 및 지연 재시도

**세션 라이프사이클과 API 호출 순서**:

```
1. 앱 시작 / 사용자 로그인:
   POST /engine/users/identify
     {google_sub: auth.uid, app_source: "incar_companion"}

2. VoiceChat 세션 시작:
   GET /incar/profile/{google_sub}      -- 캐시 프로필 (빠름)
   GET /engine/prompts/{google_sub}     -- 실시간 E/N/G/C (정확)
   POST /engine/voicechat {phase: "surface", query: first_message}

3. 대화 진행 중:
   POST /engine/voicechat {phase: "surface" or "depth", query: message}
   POST /engine/query {question: specific_query}  -- 온디맨드 검색

4. DEPTH Layer 진입 (emotion_level > 0.8):
   POST /engine/voicechat/depth {question_type: "Q1_WHY"}
   POST /incar/events/batch   -- Q1-Q4에서 추출한 E/N/G/C 이벤트 저장

5. 세션 종료:
   POST /engine/voicechat/insight {q_results: {q1, q2, q3, q4}}
   POST /incar/conversations/{session_id}/save {transcript, google_sub}
```

### 3.5 구독 모델 (Subscription Model - RevenueCat)

**Free Tier (무료)**:

| 항목 | 제한 |
|------|------|
| 일일 세션 | 3회 제한 |
| 대화 엔진 | SURFACE Layer만 (5-Phase VoiceChat) |
| 대화 이력 보관 | 7일 |
| Context Layering | Profile + Current Session만 (Layer 1, 3) |
| 외부 정보 전략 | Type D(후속 질문)만 제한적 제공 |
| 광고 | 포함 |

**Premium Tier (월간/연간 구독)**:

| 항목 | 제공 |
|------|------|
| 일일 세션 | 무제한 |
| 대화 엔진 | SURFACE + DEPTH + INSIGHT 전체 3-Layer |
| 대화 이력 보관 | 무제한 |
| Context Layering | 전체 5계층 (Profile + Past Memory + Current + Additional + Persona) |
| 외부 정보 전략 | Type A-D 모두 제공 |
| 광고 | 제거 |
| 우선 응답 | latency 최적화 |
| 감정 패턴 리포트 | E/N/G/C 기반 장기 패턴 분석 |

**가격 전략 (안)**:

| 플랜 | 가격 | 비고 |
|------|------|------|
| 월간 구독 | 9,900원/월 | -- |
| 연간 구독 | 79,000원/년 | ~33% 할인 (6,583원/월 환산) |
| 무료 체험 | 7일 | Premium 전기능 체험 |

**Feature Gating 설계**:

| 기능 | Free | Premium | Gating 시점 |
|------|:----:|:-------:|------------|
| Surface Layer (5-Phase) | O | O | -- |
| 일일 3회 세션 | O | -- | 세션 시작 시 카운트 확인 |
| 무제한 세션 | -- | O | 세션 시작 시 구독 확인 |
| DEPTH Layer 진입 | X | O | 깊이 신호 감지 후 구독 확인 |
| INSIGHT Layer | X | O | DEPTH 완료 후 구독 확인 |
| 외부 정보 (Type A-C) | X | O | 정보 수집 Job 실행 전 확인 |
| 7일 초과 이력 접근 | X | O | 데이터 접근 시 구독 확인 |

**RevenueCat 통합 포인트**:
- 앱 시작 시 구독 상태 확인 (RevenueCat SDK)
- Feature Gating: DEPTH/INSIGHT 진입 전 구독 상태 검증
- Paywall UI: Hotwire Native 네이티브 Paywall 표시
- Receipt Validation: 서버사이드 구매 영수증 검증
- Webhook 처리: 구독 상태 변경 알림 수신 (갱신, 만료, 취소)

### 3.6 사용자 설정 (User Settings)

**FR-SET-001**: AI 페르소나 커스터마이징
- 대화 스타일 선택 (친근한/전문적/유머러스)
- 호칭 설정 (이름, 별명 등)
- 관심사 키워드 관리 (OntologyRAG Profile 연동)

**FR-SET-002**: 알림 설정
- 대화 리마인더 (출근/퇴근 시간 알림)
- Insight 생성 알림
- 외부 정보 업데이트 알림

**FR-SET-003**: 데이터 관리
- 대화 이력 내보내기 (JSON/텍스트)
- 특정 세션 또는 전체 데이터 삭제
- OntologyRAG 데이터 삭제 요청

**FR-SET-004**: 구독 관리
- 구독 상태 확인 및 요금제 변경/해지
- 결제 이력 조회

---

## 4. 도메인 모델 (Domain Models)

### 4.1 핵심 모델 (Core Models)

**User** (사용자):
- google_sub 기반, OmniAuth 연동
- 필수 필드: `google_sub` (unique), `email`, `name`
- 연관: `has_many :sessions, :insights` / `has_one :setting, :subscription`

**Session** (대화 세션):
- VoiceChat 단위의 대화 세션
- 필수 필드: `user_id`, `started_at`, `status` (active/completed/cancelled)
- 선택 필드: `ended_at`, `location_data` (JSON), `weather_data` (JSON)
- 연관: `belongs_to :user` / `has_many :messages` / `has_one :voice_chat_data, :depth_exploration`

**Message** (개별 메시지):
- user/assistant/system 역할 구분
- 필수 필드: `session_id`, `role`, `content`
- 선택 필드: `emotion_data` (JSON), `phase`, `timestamp`
- 연관: `belongs_to :session`

**VoiceChatData** (세션 메타데이터):
- 세션 종료 시 생성되는 메타 정보
- 필수 필드: `session_id`, `weather` (JSON), `full_transcript`
- 선택 필드: `gps_data` (JSON), `duration_seconds`, `phase_transitions` (JSON)
- 연관: `belongs_to :session`

**DepthExploration** (DEPTH 탐색):

```ruby
# Aggregate Root: Q1-Q4 답변 관리
# (Project_B DepthExploration.kt 참조, Rails 방식으로 재작성)
#
# 필수 필드:
#   signal_emotion_level: Float (0.0 ~ 1.0)
#   signal_keywords: Array (복수형!)
#   signal_repetition_count: Integer
# 선택 필드:
#   q1_answer ~ q4_answer: String (nullable)
#   impacts: JSON (ImpactAnalysis 배열)
#   information_needs: JSON (InformationNeed 배열)
# 연관: belongs_to :session
```

**Insight** (인사이트):

```ruby
# Q1-Q4 -> 의미 있는 필드 매핑
# (Project_B Insight.kt 참조, Rails 방식으로 재작성)
#
#   situation: Q1.WHY 기반 (현재 상황)
#   decision: Q2.DECISION 기반 (의사결정)
#   action_guide: Q3.IMPACT 기반 (행동 가이드)
#   data_info: Q4.DATA 기반 (필요 정보)
#   engc_profile: JSON (E/N/G/C 프로파일, 선택)
# 연관: belongs_to :session, belongs_to :depth_exploration
```

**Subscription** (구독):
- RevenueCat 연동 구독 상태
- 필수 필드: `user_id`, `plan` (free/premium), `status` (active/expired/cancelled)
- 선택 필드: `revenue_cat_id`, `started_at`, `expires_at`

**Setting** (사용자 설정):
- 필드: `user_id`, `persona_style`, `nickname`, `notification_prefs` (JSON)

### 4.2 OntologyRAG 연동 모델 (API 간접 관리)

이 모델들은 로컬 DB에 저장되지 않으며, OntologyRAG API를 통해 간접 관리된다. Ruby Value Object로 구현한다.

**EngcProfile** (E/N/G/C 프로파일):

```ruby
# 주의: 파라미터명은 단수형 (Project_E 소스코드 확인 완료)
#   emotion (NOT emotions) -> Array of ProfileItem
#   need (NOT needs) -> Array of ProfileItem
#   goal (NOT goals) -> Array of ProfileItem
#   constraint (NOT constraints) -> Array of ProfileItem
#   keywords -> Array of String
```

**EngcEvent** (E/N/G/C 이벤트):
- DEPTH Q1-Q4에서 추출된 이벤트 데이터
- `emotion_type`, `emotion_intensity`, `data` 등
- `POST /incar/events/batch`로 배치 전송

### 4.3 도메인 모델 관계도

```
User (1) ──── (N) Session
  |                  |
  |                  +-- (N) Message
  |                  |
  |                  +-- (1) VoiceChatData
  |                  |
  |                  +-- (0..1) DepthExploration
  |                  |              |
  |                  |              +-- (0..1) Insight
  |                  |
  |                  +-- (N) [OntologyRAG API] EngcEvent
  |
  +-- (1) Setting
  +-- (1) Subscription
  +-- [OntologyRAG API] EngcProfile
```

### 4.3 Critical Notes (반드시 준수)

- E/N/G/C 파라미터명은 **단수형** (`emotion`, `need`, `goal`, `constraint` - 절대 복수형 사용 금지)
- `DepthExploration.signal_keywords`는 **복수형** (Array)
- `ImpactAnalysis`에 `affected_entities` 필드 필수
- `InformationNeed`: `source` (DataSource enum), `relevance` (Float), `retrieved_data` (String, nullable)

---

## 5. Narrowing Principle (대화 설계 원칙)

SoleTalk의 대화는 "넓은 질문에서 좁은 질문으로" 점진적으로 수렴하는 Narrowing Principle을 따른다.

### 5.1 3단계 Narrowing 흐름

```
[초기] 개방형 질문                 [중기] 탐색적 질문                [후기] 포섭형 질문
"오늘 하루 어떠셨어요?"     ->     "그 회의에서 어떤 기분이었어요?"  ->  "이번 주에 팀장님과 1:1을 잡아보실래요?"
넓은 응답 범위                     감정/주제 구체화                     구체적 행동 제안
```

### 5.2 Phase별 Narrowing 적용

| Phase | Narrowing 수준 | 질문 유형 | 예시 |
|-------|----------------|----------|------|
| Opener | 최대 개방 | 일상 질문 | "오늘 하루는 어떠셨어요?" |
| Emotion Expansion | 중간 개방 | 감정 탐색 | "그때 기분이 어땠어요?" |
| Free Speech | 중간 | 주제 심화 | "좀 더 얘기해 주실래요?" |
| Calm | 중간 수렴 | 정리/안정 | "많은 이야기를 해주셨네요" |
| Re-stimulus | 최대 수렴 | 행동 제안 | "이렇게 해보시는 건 어떨까요?" |

### 5.3 DEPTH Layer Narrowing

| Q | Narrowing 수준 | 수렴 대상 | 목표 |
|---|----------------|----------|------|
| Q1 (WHY) | 감정 수렴 | 표면 감정 -> 핵심 감정 | 진짜 감정 발견 |
| Q2 (DECISION) | 주제 수렴 | 막연함 -> 구체적 의사결정 | 결정 문제 정의 |
| Q3 (IMPACT) | 차원 수렴 | 다차원 -> 핵심 영향 | 영향 구체화 |
| Q4 (DATA) | 정보 수렴 | 모든 정보 -> 필요한 정보 | 실행 연결 |

---

## 6. 비기능 요구사항 (Non-Functional Requirements)

### 6.1 성능 (Performance)

| 항목 | 목표 | 비고 |
|------|------|------|
| API 응답 시간 (캐시 히트) | < 500ms | Solid Cache 활용 |
| API 응답 시간 (LLM 호출) | < 3s | 스트리밍 응답 제공 |
| WebSocket 지연 | < 100ms | Action Cable (Solid Cable) |
| 첫 화면 로딩 | < 2s | Turbo 프리로딩 |
| OntologyRAG 타임아웃 | 엔드포인트별 설정 | identify: 5s, prompts: 10s, query: 30s |
| Background Job 처리 | < 30s | Solid Queue |

### 6.2 보안 (Security)

| 항목 | 요구사항 |
|------|---------|
| 전송 암호화 | HTTPS 전용 (TLS 1.2+) |
| API Key 보관 | Rails credentials (encrypted) |
| 사용자 데이터 | 저장 시 암호화 |
| OAuth 토큰 | 서버 측에만 저장, 클라이언트 노출 금지 |
| 세션 보안 | CSRF 보호, SameSite Cookie |
| 입력 검증 | Strong Parameters + 커스텀 검증 |

### 6.3 확장성 (Scalability)

| 항목 | 현재 | 미래 대비 |
|------|------|----------|
| Database | SQLite | PostgreSQL 마이그레이션 가능한 스키마 설계 |
| 동시 사용자 | 100명 | Puma worker 수 조정으로 확장 |
| API Rate Limit | 1,000 req/hour | 큐잉 + 지수 백오프 |
| 캐시 | Solid Cache | Redis 전환 가능한 인터페이스 |
| Background Jobs | Solid Queue | Sidekiq 전환 가능한 인터페이스 |

### 6.4 가용성 및 접근성

| 항목 | 요구사항 |
|------|---------|
| 서비스 가용성 | 99.5% |
| OntologyRAG 장애 대응 | Graceful Degradation (캐시 데이터로 기본 대화 유지) |
| 데이터 백업 | 일일 SQLite 자동 백업 |
| 음성 우선 설계 | 차량 내 핸즈프리 사용을 최우선 |
| 텍스트 대안 | 음성 불가 시 텍스트 입력 지원 |
| 언어 | 한국어 우선, 영어 지원 예정 |

---

## 7. 성공 지표 (KPI - Key Performance Indicators)

### 7.1 핵심 성과 지표

| 지표 | 정의 | 목표 |
|------|------|------|
| **DAU** | 일간 활성 사용자 | 출시 3개월 후 1,000명 |
| **MAU** | 월간 활성 사용자 | 출시 3개월 후 5,000명 |
| **평균 세션 시간** | 1회 대화 평균 길이 | > 10분 |
| **주간 세션 빈도** | 사용자당 주간 평균 세션 수 | > 5회 |
| **30일 유지율** | 30일 후 재방문율 | > 25% |

### 7.2 제품 품질 지표

| 지표 | 정의 | 목표 |
|------|------|------|
| **DEPTH 진입률** | 전체 세션 대비 DEPTH Layer 진입 비율 | > 30% |
| **Insight 생성률** | DEPTH 진입 세션 대비 Insight 생성 비율 | > 50% |
| **Insight 유용성** | 사용자 피드백 기반 유용도 평가 (1-5) | > 3.5 |
| **NPS** | Net Promoter Score | > 30 |

### 7.3 비즈니스 지표

| 지표 | 정의 | 목표 |
|------|------|------|
| **구독 전환율** | Free -> Premium 전환 비율 | > 5% |
| **구독 유지율** | 월간 구독 갱신율 | > 80% |
| **ARPU** | 사용자당 평균 수익 | 추후 설정 |
| **LTV** | 사용자 생애 가치 | 추후 설정 |

### 7.4 North Star Metric

**"주간 Insight 생성 횟수"**

이 지표가 North Star인 이유:
- 사용자가 충분히 깊은 대화를 했음을 의미 (SURFACE -> DEPTH 완료)
- AI가 의미 있는 행동 가이드를 생성했음을 의미
- 사용자에게 실질적 가치가 전달되었음을 의미
- 구독 전환과 직접적 상관관계가 예상됨

---

## 8. 참조 문서 (Reference Documents)

| 문서 | 경로 | 용도 |
|------|------|------|
| **CLAUDE.md** | `CLAUDE.md` | 프로젝트 전체 설계 가이드 |
| **VoiceChat Engine v2** | `docs/ref/20251206_VoiceChat_Engine_Ideation_v2.md` | 3-Layer 아키텍처 비전, 외부 정보 전략, DEPTH 상세 설계 |
| **Migration Assessment** | `docs/ondev/20260212_04_comprehensive_migration_assessment.md` | Fresh build 결정 근거, 구현 전략, 리스크 분석 |
| **Project_B Analysis** | `docs/ondev/20260212_01_project_b_analysis.md` | VoiceChat 엔진 로직, 도메인 모델, 재사용성 평가 |
| **Project_C Analysis** | `docs/ondev/20260212_02_project_c_analysis.md` | OntologyRAG 통합 패턴, ENGC 이벤트 패턴 |
| **Project_E API Analysis** | `docs/ondev/20260212_03_project_e_api_analysis.md` | 전체 API 스펙, 엔드포인트 우선순위, 타임아웃/리트라이 설정 |
| **Architecture Insights** | `docs/ref/20251222_Architecture_Integration_Insights.md` | 도메인 모델/E2E 패턴 |
| **3-Project Integration** | `docs/ref/20251212_07_3project_integrated_development_plan.md` | 통합 아키텍처/API |

---

*본 문서는 SoleTalk (Project_A) 프로젝트의 제품 요구사항을 정의하며, 개발 진행에 따라 업데이트될 수 있습니다.*
*최종 수정일: 2026-02-12*
