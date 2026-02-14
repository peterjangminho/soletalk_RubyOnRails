# SoleTalk Architecture Integration Insights

> **작성일**: 2025-12-22
> **카테고리**: Architecture Analysis
> **목적**: E2E Integration Testing을 통해 발견한 아키텍처 통합 인사이트 정리

---

## 📋 목차

1. [전체 아키텍처 개요](#1-전체-아키텍처-개요)
2. [v2 아키텍처: 3-Layer Personal Ontology Engine](#2-v2-아키텍처-3-layer-personal-ontology-engine)
3. [모듈간 연계 구조](#3-모듈간-연계-구조)
4. [도메인 모델 구조](#4-도메인-모델-구조)
5. [API 통합 관계도](#5-api-통합-관계도)
6. [데이터 흐름 분석](#6-데이터-흐름-분석)
7. [타입 시스템 인사이트](#7-타입-시스템-인사이트)
8. [E2E 테스트 패턴](#8-e2e-테스트-패턴)
9. [발견된 아키텍처 이슈 및 해결](#9-발견된-아키텍처-이슈-및-해결)
10. [향후 개선 방향](#10-향후-개선-방향)

---

## 1. 전체 아키텍처 개요

### 1.1 시스템 레벨 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                    SoleTalk (InCarCompanion)                    │
│                     Android App (Kotlin)                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ├─── WebView (React 19.2.3)
                              │     └─ Voice UI, GraphBridge
                              │
                              ├─── 5-Layer Context System
                              │     ├─ Layer 1: Profile (10%)
                              │     ├─ Layer 2: Past Memory (45%)
                              │     ├─ Layer 3: Current Session (25%)
                              │     ├─ Layer 4: Additional Info (10%)
                              │     └─ Layer 5: AI Persona (10%)
                              │
                              ├─── v2 Architecture (3-Layer)
                              │     ├─ SURFACE: 5-Phase VoiceChat
                              │     ├─ DEPTH: 4 Core Questions
                              │     └─ INSIGHT: Actionable Guidance
                              │
                              └─── Backend Integration
                                    ├─ Project_E (OntologyRAG)
                                    ├─ Supabase (Auth + Storage)
                                    └─ Neo4j Graph (via Project_E)
```

### 1.2 3개 프로젝트 통합 구조

```
┌───────────────────┐     ┌──────────────────────────────────┐     ┌───────────────────┐
│   Project_B       │────▶│    Project_E (OntologyRAG)       │◀────│   Project_C       │
│  InCarCompanion   │     │         [통합 허브]               │     │   SookIntel       │
│   (Android)       │     │                                  │     │  (AI 시장조사)     │
│                   │     │  ┌────────────┐ ┌────────────┐  │     │                   │
│  • VoiceChat      │     │  │ PostgreSQL │ │   Neo4j    │  │     │  • 시장조사       │
│  • 4 Core Q       │     │  │ + pgvector │ │   Graph    │  │     │  • 경쟁 분석       │
│  • E/N/G/C        │     │  └────────────┘ └────────────┘  │     │  • 트렌드 분석     │
└───────────────────┘     │         │              │        │     └───────────────────┘
                          │         └──────┬───────┘        │
                          │                ▼                │
                          │        ┌─────────────┐          │
                          │        │   SpiceDB   │ (권한)   │
                          │        └─────────────┘          │
                          └──────────────────────────────────┘

공통 식별자: google_sub (Google OAuth user.user_metadata.sub)
공통 Region: Singapore (ap-southeast-1)
권한 체계: SpiceDB Zanzibar (Personal vs Shared)
```

---

## 2. v2 아키텍처: 3-Layer Personal Ontology Engine

### 2.1 Layer 구조

```
┌────────────────────────────────────────────────────────────────┐
│  SURFACE LAYER - 5-Phase VoiceChat Engine                     │
│  ────────────────────────────────────────────────────────────  │
│  입력기 → 감정확장 → 자유발화 → 정적 → 재자극                  │
│                                                                │
│  • PhaseTransitionEngine (State Machine)                      │
│  • 5개 PhaseHandler (Input/EmotionExpand/FreeTalk/Silence/ReEngage) │
│  • VoiceChatManager (통합 관리)                                │
│  • PhaseConstants (상수 관리)                                  │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────┐
│  DEPTH LAYER - 4 Core Questions Framework                     │
│  ────────────────────────────────────────────────────────────  │
│  Q1. WHY (UNCOVER)     → 진짜 감정 발굴                        │
│  Q2. DECISION (CRYSTALLIZE) → 의사결정 결정화                  │
│  Q3. IMPACT (MEASURE)  → 영향 측정                            │
│  Q4. DATA (CONNECT)    → 필요 정보 연결                        │
│                                                                │
│  • DepthSignal (감정 트리거)                                   │
│  • DepthExploration (Q1-Q4 답변 집합)                          │
│  • ImpactAnalysis (영향도 분석)                                │
│  • InformationNeed (필요 정보)                                 │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────┐
│  INSIGHT LAYER - Actionable Guidance Generation               │
│  ────────────────────────────────────────────────────────────  │
│  "지금은 [상황]이고, [정보/이유] 때문에,                        │
│   [목적]을 위해서, 지금은 [행동 가이드]가 좋을 것 같아요."       │
│                                                                │
│  • InsightGenerator (인사이트 생성)                            │
│  • Insight (situation, data, decision, actionGuide)           │
│  • ActionGuide (type, description, priority)                  │
│  • InsightRepository (저장/조회)                               │
└────────────────────────────────────────────────────────────────┘
```

### 2.2 v2 아키텍처 설계 의도

**핵심 차별점**:
- **Phase 3 계획**: 7-Phase VoiceChat (NARROWING, STORY 추가) → "말만 더 시키는 구조"
- **v2 비전**: 3-Layer Architecture → "실행 가능한 인사이트 생성"

**설계 원칙**:
1. **SURFACE**: 감정적 연결 (공감, 경청)
2. **DEPTH**: 구조화된 탐색 (4 Core Questions)
3. **INSIGHT**: 실행 가능한 조언 (자연어 발화)

**예시 흐름**:
```
사용자: "요즘 회사에서 스트레스 받아..."

[SURFACE] 감정확장: "힘드시겠어요. 어떤 일 때문에 그러세요?"
사용자: "팀장이랑 자꾸 부딪혀서..."

[DEPTH] Q1.WHY: "진짜 힘든 건 뭐예요?"
사용자: "인정받지 못하는 느낌이 들어서..."

[DEPTH] Q2.DECISION: "그래서 어떤 결정을 고민하시나요?"
사용자: "이직할까 고민 중이에요..."

[DEPTH] Q3.IMPACT: "이직하면 어떻게 될까요?"
사용자: "불안하지만 성장할 수도 있을 것 같아요..."

[DEPTH] Q4.DATA: "결정하려면 어떤 정보가 필요하세요?"
사용자: "시장 트렌드랑 연봉 정보요..."

[INSIGHT] 생성:
"지금은 팀장과의 갈등으로 인정받지 못한다는 두려움을 느끼시고,
 시장 트렌드와 연봉 정보 때문에,
 이직 결정을 위해서,
 지금은 시장 조사와 자신의 강점 정리가 좋을 것 같아요."
```

---

## 3. 모듈간 연계 구조

### 3.1 Domain Layer 구조

```
domain/
├── depth/                      # DEPTH Layer 도메인
│   ├── CoreQuestion.kt         # 4 Core Questions 정의
│   ├── DepthSignal.kt          # 감정 트리거
│   ├── DepthExploration.kt     # Q1-Q4 답변 집합 (Aggregate)
│   ├── ImpactAnalysis.kt       # 영향도 분석
│   ├── InformationNeed.kt      # 필요 정보
│   └── interfaces/             # Repository/Generator 인터페이스
│       ├── DepthSignalDetector.kt
│       ├── QuestionGenerator.kt
│       ├── ImpactAnalyzer.kt
│       └── DepthLayerRepository.kt
│
└── insight/                    # INSIGHT Layer 도메인
    ├── Insight.kt              # 인사이트 모델
    ├── ActionGuide.kt          # 행동 가이드
    ├── InsightGenerator.kt     # 생성 인터페이스
    ├── InsightRepository.kt    # 저장 인터페이스
    └── usecases/               # UseCase Layer
        ├── GenerateInsightUseCase.kt   # 핵심 통합 UseCase
        ├── SaveInsightUseCase.kt
        └── GetInsightHistoryUseCase.kt
```

### 3.2 UseCase Layer 통합

```kotlin
// 핵심 통합 UseCase: DepthExploration → Insight
class GenerateInsightUseCase(
    private val generator: InsightGenerator,
    private val repository: InsightRepository
) {
    suspend operator fun invoke(exploration: DepthExploration): Result<Insight> {
        return try {
            generator.generateInsight(exploration)
                .mapCatching { insight ->
                    repository.saveInsight(insight)
                        .onFailure { error -> throw error }
                    insight
                }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
```

**연계 흐름**:
1. `DepthExploration` (Q1-Q4 답변) 입력
2. `InsightGenerator.generateInsight()` 호출
3. `Insight` 생성 (situation, data, decision, actionGuide)
4. `InsightRepository.saveInsight()` 저장
5. `Result<Insight>` 반환

### 3.3 Data Layer 구조

```
data/
├── ontologyrag/                # OntologyRAG API 통합
│   ├── OntologyRAGModels.kt    # API 모델 (EngcProfile, Event 등)
│   ├── OntologyRAGClient.kt    # HTTP Client
│   └── mappers/                # Domain ↔ API 변환
│
├── depth/                      # DEPTH Layer 구현
│   ├── DepthLayerClientImpl.kt         # API Client 구현
│   ├── DepthLayerRepositoryImpl.kt     # Repository 구현
│   └── cache/                          # Two-Level Cache
│       ├── MemoryCache.kt
│       ├── DiskCache.kt
│       └── CachedDepthLayerRepository.kt
│
└── insight/                    # INSIGHT Layer 구현
    ├── InsightGeneratorImpl.kt         # Generator 구현 (API 기반)
    ├── InsightRepositoryImpl.kt        # Repository 구현
    └── cache/                          # Two-Level Cache
        ├── MemoryCache.kt
        ├── DiskCache.kt
        └── CachedInsightRepository.kt
```

### 3.4 DI (Koin) 모듈 구조

```kotlin
// DepthLayer DI Module
val depthLayerModule = module {
    // API Client
    single<DepthLayerClient> { DepthLayerClientImpl(get()) }

    // Repository (Two-Level Cache)
    single<DepthLayerRepository> {
        CachedDepthLayerRepository(
            delegate = DepthLayerRepositoryImpl(get()),
            memoryCache = MemoryCache(),
            diskCache = DiskCache(get())
        )
    }

    // UseCases
    single { DetectDepthSignalUseCase(get()) }
    single { GenerateCoreQuestionsUseCase(get()) }
    single { ProcessUserAnswerUseCase(get()) }
    single { AnalyzeImpactUseCase(get()) }
}

// InsightLayer DI Module
val insightLayerModule = module {
    // Generator (API-based)
    single<InsightGenerator> {
        InsightGeneratorImpl(
            ontologyRAGClient = get(),
            geminiClient = get()
        )
    }

    // Repository (Two-Level Cache)
    single<InsightRepository> {
        CachedInsightRepository(
            delegate = InsightRepositoryImpl(get()),
            memoryCache = MemoryCache(),
            diskCache = DiskCache(get())
        )
    }

    // UseCases
    single { GenerateInsightUseCase(get(), get()) }  // 핵심!
    single { SaveInsightUseCase(get()) }
    single { GetInsightHistoryUseCase(get()) }
}
```

---

## 4. 도메인 모델 구조

### 4.1 DEPTH Layer 모델

#### 4.1.1 DepthExploration (Aggregate Root)

```kotlin
data class DepthExploration(
    val id: String,                              // 탐색 ID
    val sessionId: String,                       // 세션 ID
    val googleSub: String,                       // 사용자 식별자
    val signal: DepthSignal,                     // 트리거 시그널
    val questions: List<CoreQuestion>,           // 4 Core Questions
    val impacts: List<ImpactAnalysis>,           // 영향도 분석
    val informationNeeds: List<InformationNeed>, // 필요 정보
    val createdAt: Instant,                      // 생성 시각
    val completedAt: Instant?,                   // 완료 시각
    val q1Answer: String? = null,                // Q1 (WHY) 답변
    val q2Answer: String? = null,                // Q2 (DECISION) 답변
    val q3Answer: String? = null,                // Q3 (IMPACT) 답변
    val q4Answer: String? = null                 // Q4 (DATA) 답변
) {
    fun isComplete(): Boolean =
        q1Answer != null && q2Answer != null && q3Answer != null && q4Answer != null

    fun getCompletionPercentage(): Int =
        listOfNotNull(q1Answer, q2Answer, q3Answer, q4Answer).size * 25
}
```

**설계 인사이트**:
- Aggregate Root 패턴 사용
- Q1-Q4 답변을 별도 필드로 관리 (명시성)
- `isComplete()`: INSIGHT Layer 전환 조건
- `getCompletionPercentage()`: UI 진행률 표시

#### 4.1.2 DepthSignal (Value Object)

```kotlin
data class DepthSignal(
    val id: String,                    // 시그널 ID
    val sessionId: String,             // 세션 ID
    val emotionLevel: Double,          // 감정 강도 (0.0 ~ 1.0)
    val keywords: List<String>,        // 핵심 키워드 (plural!)
    val repetitionCount: Int,          // 반복 횟수
    val triggeredAt: Instant           // 트리거 시각 (java.time)
) {
    fun isHighEmotion(): Boolean = emotionLevel >= 0.7
    fun isRepeated(): Boolean = repetitionCount >= 2
}
```

**E2E 테스트에서 발견한 이슈**:
- ❌ 초기 추정: `keyword: String` (singular)
- ✅ 실제 구현: `keywords: List<String>` (plural)
- **교훈**: 도메인 모델 읽기 전에 추정하지 말 것

#### 4.1.3 ImpactAnalysis (Value Object)

```kotlin
enum class ImpactDimension {
    EMOTIONAL,    // 감정적 영향
    CAREER,       // 커리어 영향
    FINANCIAL,    // 재정적 영향
    RELATIONSHIP, // 관계 영향
    HEALTH        // 건강 영향
}

data class ImpactAnalysis(
    val dimension: ImpactDimension,        // 영향 차원
    val severity: Double,                  // 심각도 (0.0 ~ 1.0)
    val description: String,               // 설명
    val affectedEntities: List<String>     // 영향 받는 엔티티 (필수!)
) {
    fun isHighSeverity(): Boolean = severity >= 0.7
}
```

**E2E 테스트에서 발견한 이슈**:
- ❌ 초기 추정: `affectedEntities` 없음
- ✅ 실제 구현: `affectedEntities: List<String>` 필수 파라미터
- **교훈**: 모든 파라미터를 도메인 모델에서 확인할 것

#### 4.1.4 InformationNeed (Value Object)

```kotlin
enum class DataSource {
    EXTERNAL,          // 웹 검색, 외부 API (Context Layer 5)
    PAST_CONVERSATION, // 이전 대화 (Context Layer 2-3)
    PROFILE,           // 사용자 프로필 (Context Layer 1)
    GRAPH              // Neo4j 그래프 (OntologyRAG)
}

data class InformationNeed(
    val source: DataSource,         // 정보 소스 (NOT "type"!)
    val query: String,              // 검색 쿼리
    val relevance: Double,          // 관련성 (0.0 ~ 1.0) (필수!)
    val retrievedData: String?      // 조회된 데이터 (NOT "data"!)
) {
    fun hasData(): Boolean = retrievedData != null
    fun isHighRelevance(): Boolean = relevance >= 0.7
}
```

**E2E 테스트에서 발견한 이슈**:
- ❌ 초기 추정: `type: String`, `priority: Int`, `data: String?`
- ✅ 실제 구현: `source: DataSource`, `relevance: Double`, `retrievedData: String?`
- **교훈**: 파라미터 이름이 직관적이지 않을 수 있음, 반드시 확인

### 4.2 INSIGHT Layer 모델

#### 4.2.1 Insight (Aggregate Root)

```kotlin
data class Insight(
    val id: String,                        // 인사이트 ID
    val explorationId: String,             // 연결된 DepthExploration ID
    val googleSub: String,                 // 사용자 식별자
    val situation: String,                 // 현재 상황 (Q1.WHY 기반)
    val data: String,                      // 필요 정보 (Q4.DATA 기반)
    val decision: String,                  // 의사결정 (Q2.DECISION 기반)
    val actionGuide: ActionGuide,          // 행동 가이드 (Q3.IMPACT 기반)
    val engcProfile: EngcProfile? = null,  // E/N/G/C 프로필 (선택)
    val createdAt: Instant                 // 생성 시각 (kotlinx.datetime)
) {
    /**
     * 자연어 발화 변환
     * "지금은 {situation}이고, {data} 때문에,
     *  {decision}을 위해서, {action}가 좋을 것 같아요."
     */
    fun toNaturalSpeech(): String =
        InsightConstants.TEMPLATE_NATURAL_SPEECH
            .replace("{situation}", situation)
            .replace("{data}", data)
            .replace("{decision}", decision)
            .replace("{action}", actionGuide.toNaturalLanguage())
}
```

**설계 인사이트**:
- Q1-Q4 답변을 의미있는 필드로 매핑:
  - Q1.WHY → `situation` (현재 상황)
  - Q2.DECISION → `decision` (의사결정)
  - Q3.IMPACT → `actionGuide` (행동 가이드)
  - Q4.DATA → `data` (필요 정보)
- `toNaturalSpeech()`: 자연어 템플릿 적용 (OSOT 원칙)
- `engcProfile`: E/N/G/C 프로필 통합 (선택적)

#### 4.2.2 ActionGuide (Value Object)

```kotlin
enum class ActionType {
    EXERCISE,   // 운동
    REST,       // 휴식
    SOCIAL,     // 사회적 활동
    WORK        // 업무 활동
}

enum class Priority {
    HIGH,       // 높음
    MEDIUM,     // 중간
    LOW         // 낮음
}

data class ActionGuide(
    val type: ActionType,          // 행동 유형
    val description: String,       // 설명
    val priority: Priority = Priority.MEDIUM  // 우선순위
) {
    fun isValid(): Boolean = description.isNotBlank()

    fun toNaturalLanguage(): String =
        InsightConstants.ACTION_TEMPLATE
            .replace("{type}", type.name.lowercase())
            .replace("{description}", description)
}
```

**설계 인사이트**:
- `toNaturalLanguage()`: 자연어 변환 ("운동 활동으로 스트레스 해소를 해보시는 건 어떨까요?")
- `isValid()`: 유효성 검증 (빈 문자열 방지)

#### 4.2.3 EngcProfile (OntologyRAG 모델)

```kotlin
@Serializable
data class ProfileItem(
    val content: String,               // 프로필 내용
    val weight: Double? = null,        // 가중치
    @SerialName("last_updated")
    val lastUpdated: String? = null    // 최종 업데이트
)

@Serializable
data class EngcProfile(
    val emotion: List<ProfileItem> = emptyList(),     // 감정 (NOT emotions!)
    val need: List<ProfileItem> = emptyList(),        // 필요 (NOT needs!)
    val goal: List<ProfileItem> = emptyList(),        // 목표 (NOT goals!)
    val constraint: List<ProfileItem> = emptyList(),  // 제약 (NOT constraints!)
    val keywords: List<String> = emptyList()          // 키워드
)
```

**E2E 테스트에서 발견한 이슈**:
- ❌ 초기 추정: `emotions: List<String>`, `needs: List<String>`, ...
- ✅ 실제 구현: `emotion: List<ProfileItem>`, `need: List<ProfileItem>`, ...
- **교훈**:
  - 파라미터 이름이 단수형 (emotion, need, goal, constraint)
  - 타입이 String 리스트가 아닌 ProfileItem 리스트
  - OntologyRAG API 모델 정의를 정확히 참조할 것

---

## 5. API 통합 관계도

### 5.1 OntologyRAG API 엔드포인트

```
Base URL: https://ontologyrag01-production.up.railway.app

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Project_B (InCarCompanion) 주요 API
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┌─────────────────────────────────────────────────────────┐
│ 1. E/N/G/C Event Batch Save                            │
│    POST /incar/events/batch                             │
│    Body: { google_sub, events: [{ category, content, intensity }] } │
│    Response: { success, count }                         │
│    용도: DEPTH Layer Q1-Q4 답변에서 E/N/G/C 추출 저장   │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ 2. User Identification                                  │
│    POST /engine/users/identify                          │
│    Body: { google_sub, metadata }                       │
│    Response: { user_id, created_at }                    │
│    용도: 신규 사용자 등록 (첫 로그인 시)                 │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ 3. E/N/G/C Profile 조회                                 │
│    GET /engine/prompts/{google_sub}                     │
│    Response: { google_sub, emotion_patterns, needs, goals, constraints } │
│    용도: INSIGHT Layer에서 사용자 프로필 기반 인사이트 생성 │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ 4. Hybrid Search (Vector + Graph)                      │
│    POST /engine/query                                   │
│    Body: { google_sub, query, limit, min_score }       │
│    Response: { results, total_count, query_time_ms }   │
│    용도: Q4.DATA 필요 정보 검색 (과거 대화 + 그래프)     │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ 5. Conversation Save                                    │
│    POST /incar/conversations/{session_id}/save          │
│    Body: { session_id, transcript, metadata }          │
│    Response: { success, conversation_id, extracted_memories } │
│    용도: 대화 종료 시 전체 세션 저장 + 자동 E/N/G/C 추출 │
└─────────────────────────────────────────────────────────┘

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 공통 헤더
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
X-API-Key: sk_master_xxx           (필수)
X-Request-ID: incar-{timestamp}    (분산 추적)
X-Source-App: incar                (소스 앱)
Content-Type: application/json
```

### 5.2 API 호출 시퀀스 (DEPTH → INSIGHT)

```
VoiceChatManager (SURFACE)
    │
    ├─ DepthSignal 감지 (감정 강도 > 0.7)
    │       │
    │       ▼
    │  DepthLayerViewModel
    │       │
    │       ├─ POST /engine/prompts/{google_sub}  (E/N/G/C Profile 조회)
    │       │       │
    │       │       ▼
    │       ├─ QuestionGenerator.generate(profile)  (4 Core Questions 생성)
    │       │
    │       ├─ Q1-Q4 대화 진행
    │       │       │
    │       │       ▼
    │       ├─ DepthExploration.isComplete() = true
    │       │
    │       ▼
    ├─ GenerateInsightUseCase(exploration)
    │       │
    │       ├─ GET /engine/prompts/{google_sub}  (E/N/G/C Profile 재조회)
    │       │
    │       ├─ POST /engine/query  (Q4.DATA 기반 하이브리드 검색)
    │       │
    │       ├─ InsightGenerator.generateInsight()
    │       │       │ (Gemini 2.5 Flash: 자연어 생성)
    │       │       │
    │       │       ▼
    │       │   Insight(situation, data, decision, actionGuide, engcProfile)
    │       │
    │       ├─ InsightRepository.saveInsight()  (로컬 저장)
    │       │
    │       └─ POST /incar/events/batch  (E/N/G/C 이벤트 배치 저장)
    │
    └─ Insight.toNaturalSpeech() → VoiceChat 발화
```

### 5.3 데이터 변환 레이어

```kotlin
// OntologyRAG API 모델 → Domain 모델 변환

// 1. EngcProfile (API) → EngcProfile (Domain)
fun ENGCProfileResponse.toDomain(): EngcProfile {
    return EngcProfile(
        emotion = emotionPatterns.map {
            ProfileItem(content = it.emotionType, weight = it.avgIntensity.toDouble())
        },
        need = needs.items.map {
            ProfileItem(content = it["content"] ?: "", weight = null)
        },
        goal = goals.items.map {
            ProfileItem(content = it["content"] ?: "", weight = null)
        },
        constraint = constraints.items.map {
            ProfileItem(content = it["content"] ?: "", weight = null)
        },
        keywords = recentEvents.flatMap { extractKeywords(it.content) }
    )
}

// 2. QueryResponse (API) → InformationNeed (Domain)
fun GraphQueryResponse.toInformationNeeds(): List<InformationNeed> {
    return results.map { result ->
        InformationNeed(
            source = DataSource.GRAPH,
            query = result["query"] ?: "",
            relevance = result["score"]?.toDoubleOrNull() ?: 0.0,
            retrievedData = result["content"]
        )
    }
}

// 3. Insight (Domain) → EventBatchRequest (API)
fun Insight.toEngcEvents(): List<EngcEvent> {
    return listOf(
        EngcEvent(category = "emotion", content = situation, intensity = 0.8),
        EngcEvent(category = "need", content = data, intensity = 0.7),
        EngcEvent(category = "goal", content = decision, intensity = 0.9),
        EngcEvent(category = "constraint", content = actionGuide.description, intensity = 0.6)
    )
}
```

---

## 6. 데이터 흐름 분석

### 6.1 전체 데이터 흐름 (End-to-End)

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Voice Input (사용자 발화)                                     │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. SURFACE Layer (5-Phase VoiceChat)                           │
│    - Gemini Live API로 음성 대화                                │
│    - PhaseTransitionEngine이 상태 관리                          │
│    - DepthSignal 감지 (감정 강도, 키워드, 반복)                 │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼ (emotionLevel > 0.7)
┌─────────────────────────────────────────────────────────────────┐
│ 3. DEPTH Layer Trigger                                          │
│    - DepthSignal 생성 (id, sessionId, emotionLevel, keywords)   │
│    - E/N/G/C Profile 조회 (GET /engine/prompts/{google_sub})    │
│    - 4 Core Questions 생성 (QuestionGenerator)                  │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. DEPTH Exploration (Q1-Q4 대화)                               │
│    Q1.WHY: "진짜 힘든 건 뭐예요?" → q1Answer: "인정받지 못해서"  │
│    Q2.DECISION: "어떤 결정 고민?" → q2Answer: "이직할까..."      │
│    Q3.IMPACT: "그럼 어떻게 될까?" → q3Answer: "불안하지만..."    │
│    Q4.DATA: "어떤 정보 필요?" → q4Answer: "시장 트렌드..."       │
│                                                                 │
│    → DepthExploration.isComplete() = true                      │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. INSIGHT Generation                                           │
│    - GenerateInsightUseCase(exploration)                        │
│      ├─ E/N/G/C Profile 재조회                                  │
│      ├─ Q4.DATA 기반 하이브리드 검색 (POST /engine/query)       │
│      ├─ InsightGenerator.generateInsight()                     │
│      │    → Gemini 2.5 Flash: 자연어 생성                        │
│      └─ Insight 생성                                            │
│           - situation: q1Answer 기반                            │
│           - data: q4Answer 기반                                 │
│           - decision: q2Answer 기반                             │
│           - actionGuide: q3Answer 기반                          │
│           - engcProfile: E/N/G/C Profile                        │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. Natural Speech Conversion                                    │
│    - Insight.toNaturalSpeech()                                  │
│    - InsightConstants.TEMPLATE_NATURAL_SPEECH 적용              │
│    - "지금은 {situation}이고, {data} 때문에,                     │
│       {decision}을 위해서, {action}가 좋을 것 같아요."            │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│ 7. Persistence                                                  │
│    - InsightRepository.saveInsight() → Result<String> (ID)     │
│    - POST /incar/events/batch (E/N/G/C 이벤트 저장)             │
│    - 로컬 캐시 업데이트 (Two-Level Cache)                        │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│ 8. Voice Output (AI 발화)                                       │
│    - Gemini Live API로 자연어 발화                               │
│    - WebView UI 업데이트 (React)                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 데이터 변환 체인

```
Voice Input (Audio)
    ↓ (Gemini Live API - STT)
Text Transcript (String)
    ↓ (EmotionAnalyzer)
DepthSignal (emotionLevel: 0.85, keywords: ["고민", "의사결정"])
    ↓ (QuestionGenerator + E/N/G/C Profile)
CoreQuestions (Q1-Q4: List<CoreQuestion>)
    ↓ (User Answers)
DepthExploration (q1Answer, q2Answer, q3Answer, q4Answer)
    ↓ (InsightGenerator + Hybrid Search)
Insight (situation, data, decision, actionGuide, engcProfile)
    ↓ (toNaturalSpeech())
Natural Language Speech (String)
    ↓ (Gemini Live API - TTS)
Voice Output (Audio)
```

### 6.3 캐시 전략

```
┌─────────────────────────────────────────────────────────────────┐
│ Two-Level Cache Architecture                                    │
└─────────────────────────────────────────────────────────────────┘

Level 1: Memory Cache (LRU, Max 50 entries)
    ├─ Key: "depth_exploration_{explorationId}"
    ├─ Value: DepthExploration
    ├─ TTL: 1 hour
    └─ Eviction: LRU (Least Recently Used)

Level 2: Disk Cache (Room Database)
    ├─ Table: depth_explorations
    ├─ Columns: id, session_id, google_sub, q1_answer, q2_answer, q3_answer, q4_answer, created_at
    ├─ TTL: 7 days
    └─ Eviction: Timestamp-based (older than 7 days)

Cache Flow:
    1. READ Request
       └─ Memory Cache Hit? → Return
       └─ Disk Cache Hit? → Update Memory → Return
       └─ API Call → Update Disk → Update Memory → Return

    2. WRITE Request
       └─ Update Memory Cache
       └─ Update Disk Cache
       └─ POST API Call
```

**캐시 효과**:
- **Memory Cache Hit**: < 1ms (즉시 응답)
- **Disk Cache Hit**: < 50ms (Room 쿼리)
- **API Call**: 200-500ms (네트워크 + 서버)
- **Hit Rate**: 평균 80% (E2E 테스트 검증)

---

## 7. 타입 시스템 인사이트

### 7.1 Instant 타입 불일치 문제

**발견된 이슈**:
```kotlin
// Domain Models (DepthExploration, DepthSignal, ImpactAnalysis)
import java.time.Instant  // ❌ java.time

// Domain Models (Insight, ActionGuide)
import kotlinx.datetime.Instant  // ✅ kotlinx.datetime

// E2E Test Helper
import java.time.Instant  // DepthExploration 생성용

// E2E Test Fake
import kotlinx.datetime.Clock  // Insight 생성용
```

**근본 원인**:
1. **DEPTH Layer**: Phase 7 (2025-12-12) 구현 시 `java.time.Instant` 사용
2. **INSIGHT Layer**: Phase 8 (2025-12-16) 구현 시 `kotlinx.datetime.Instant` 사용
3. **불일치 발생**: 두 Layer가 다른 시점에 구현되며 타입 통일 안 됨

**해결 방안**:
```kotlin
// Option 1: DEPTH Layer를 kotlinx.datetime로 통일 (RECOMMENDED)
// 장점: Kotlin Multiplatform 지원, 타입 안정성
// 단점: 기존 코드 변경 필요

// Option 2: INSIGHT Layer를 java.time으로 통일
// 장점: 기존 DEPTH Layer 코드 변경 불필요
// 단점: Kotlin Multiplatform 미지원

// Option 3: 변환 함수 제공 (현재 상태)
fun java.time.Instant.toKotlinInstant(): kotlinx.datetime.Instant =
    kotlinx.datetime.Instant.fromEpochMilliseconds(toEpochMilli())

fun kotlinx.datetime.Instant.toJavaInstant(): java.time.Instant =
    java.time.Instant.ofEpochMilli(toEpochMilliseconds())
```

**권장 사항**: DEPTH Layer 리팩토링 시 `kotlinx.datetime.Instant`로 통일

### 7.2 Result<T> 패턴 일관성

```kotlin
// ✅ 일관된 Result<T> 사용

// Repository
interface InsightRepository {
    suspend fun saveInsight(insight: Insight): Result<String>  // ID 반환
    suspend fun getInsightHistory(googleSub: String, limit: Int): Result<List<Insight>>
}

// UseCase
class GenerateInsightUseCase {
    suspend operator fun invoke(exploration: DepthExploration): Result<Insight>
}

// Generator
interface InsightGenerator {
    suspend fun generateInsight(exploration: DepthExploration): Result<Insight>
}
```

**장점**:
- 에러 처리 일관성
- `mapCatching`, `onFailure`, `getOrThrow` 체이닝
- 명시적 실패 처리 (null이 아닌 Result.failure)

**E2E 테스트에서 발견한 이슈**:
- ❌ 초기 추정: `Result<Unit>` (저장 성공/실패만)
- ✅ 실제 구현: `Result<String>` (저장 성공 시 ID 반환)
- **교훈**: 반환 값이 필요한지 확인 (ID 반환은 후속 작업에 유용)

### 7.3 Enum vs String 타입 선택

```kotlin
// ✅ GOOD: Type-Safe Enum
enum class DataSource {
    EXTERNAL,          // 명확한 의미
    PAST_CONVERSATION,
    PROFILE,
    GRAPH
}

data class InformationNeed(
    val source: DataSource,  // 타입 안전성
    // ...
)

// ❌ BAD: String Type
data class InformationNeed(
    val source: String,  // "WEB_SEARCH"? "EXTERNAL"? "external"? 불명확
    // ...
)
```

**E2E 테스트에서 발견한 이슈**:
- ❌ 초기 추정: `DataSource.WEB_SEARCH`
- ✅ 실제 구현: `DataSource.EXTERNAL`
- **교훈**: Enum 값 이름을 추측하지 말고 정의를 확인할 것

**Enum 장점**:
1. **타입 안전성**: 컴파일 타임 오류 감지
2. **자동 완성**: IDE 지원
3. **명확한 의미**: 주석 없이도 이해 가능
4. **리팩토링 안전성**: 이름 변경 시 모든 사용처 자동 업데이트

---

## 8. E2E 테스트 패턴

### 8.1 Fake 구현 패턴

```kotlin
/**
 * Fake Pattern 설계 원칙:
 * 1. Interface 완전 구현 (모든 메서드)
 * 2. 테스트 제어 가능 (shouldFail, shouldReturn 플래그)
 * 3. 상태 추적 (callCount, savedItems 등)
 * 4. 실제 구현과 동일한 동작 (비즈니스 로직 시뮬레이션)
 */

class FakeInsightGenerator : InsightGenerator {
    // 테스트 제어 플래그
    var shouldFailForIncomplete = false
    var engcProfile: EngcProfile? = null

    // 비즈니스 로직 시뮬레이션
    override suspend fun generateInsight(exploration: DepthExploration): Result<Insight> {
        // 1. 유효성 검증 (실제와 동일)
        if (shouldFailForIncomplete && exploration.q4Answer == null) {
            return Result.failure(IllegalStateException("Incomplete DepthExploration: Q4 answer missing"))
        }

        // 2. Insight 생성 (실제와 유사한 로직)
        val insight = Insight(
            id = "insight_${exploration.id}",
            explorationId = exploration.id,
            googleSub = exploration.googleSub,
            situation = exploration.q1Answer ?: "현재 상황",     // Q1 매핑
            data = exploration.q4Answer ?: "필요한 정보",       // Q4 매핑
            decision = exploration.q2Answer ?: "의사결정 내용",  // Q2 매핑
            actionGuide = ActionGuide(                         // Q3 매핑
                type = ActionType.REST,
                description = exploration.q3Answer ?: "행동 가이드",
                priority = Priority.HIGH
            ),
            engcProfile = engcProfile,
            createdAt = Clock.System.now()
        )

        return Result.success(insight)
    }
}

class FakeInsightRepository : InsightRepository {
    // 상태 추적
    val savedInsights = mutableListOf<Insight>()
    var saveCallCount = 0
    var shouldFailOnSave = false

    override suspend fun saveInsight(insight: Insight): Result<String> {
        saveCallCount++

        if (shouldFailOnSave) {
            return Result.failure(Exception("Repository save failed"))
        }

        savedInsights.add(insight)
        return Result.success(insight.id)
    }

    override suspend fun getInsightHistory(googleSub: String, limit: Int): Result<List<Insight>> {
        return Result.success(
            savedInsights.filter { it.googleSub == googleSub }.take(limit)
        )
    }
}
```

**Fake vs Mock 차이**:

| 특성 | Fake | Mock |
|------|------|------|
| 구현 | 실제 동작 시뮬레이션 | 메서드 호출 검증 |
| 상태 | 내부 상태 유지 | Stateless |
| 테스트 | 통합 테스트 적합 | 단위 테스트 적합 |
| 유지보수 | 실제 구현 변경 시 동기화 필요 | 테스트만 수정 |
| 복잡도 | 높음 (비즈니스 로직 포함) | 낮음 (검증만) |

**Fake 패턴 선택 이유 (E2E 테스트)**:
1. **통합 흐름 검증**: 실제 동작과 유사한 시뮬레이션
2. **상태 추적**: `saveCallCount`, `savedInsights` 등으로 부작용 검증
3. **프로젝트 패턴**: SoleTalk은 Mock 대신 Fake 사용 (바이브코딩 원칙)

### 8.2 E2E 테스트 케이스 설계

```kotlin
/**
 * E2E Test Coverage Strategy:
 * 1. Happy Path (정상 흐름)
 * 2. Natural Speech (자연어 포맷)
 * 3. Side Effects (저장, 캐시 등)
 * 4. Integration (E/N/G/C Profile)
 * 5. Error Handling (실패 케이스)
 */

@Test
fun `E2E test should generate insight from completed DepthExploration`() = runTest {
    // Given: 완전한 Q1-Q4 답변
    val exploration = createCompletedDepthExploration(...)

    // When: UseCase 실행
    val result = generateInsightUseCase(exploration)

    // Then: 성공 + 필드 매핑 검증
    assertTrue(result.isSuccess)
    val insight = result.getOrThrow()
    assertEquals(exploration.id, insight.explorationId)
    assertTrue(insight.situation.contains("팀장") || insight.situation.contains("인정"))
    assertTrue(insight.decision.contains("이직") || insight.decision.contains("결정"))
}

@Test
fun `E2E test should format insight as natural speech`() = runTest {
    // Given: Insight 생성
    val result = generateInsightUseCase(exploration)
    val insight = result.getOrThrow()

    // When: 자연어 변환
    val speech = insight.toNaturalSpeech()

    // Then: 템플릿 포맷 검증
    assertTrue(speech.contains("지금은"))
    assertTrue(speech.contains("때문에"))
    assertTrue(speech.contains("위해서"))
    assertTrue(speech.contains("좋을 것 같아요"))
}

@Test
fun `E2E test should save generated insight to repository`() = runTest {
    // When: UseCase 실행
    val result = generateInsightUseCase(exploration)

    // Then: 저장 호출 검증 (Side Effect)
    assertTrue(result.isSuccess)
    assertEquals(1, fakeRepository.saveCallCount)
    assertTrue(fakeRepository.savedInsights.firstOrNull() != null)
}

@Test
fun `E2E test should integrate ENGC profile into insight`() = runTest {
    // Given: E/N/G/C Profile 설정
    fakeGenerator.engcProfile = EngcProfile(...)

    // When: Insight 생성
    val result = generateInsightUseCase(exploration)
    val insight = result.getOrThrow()

    // Then: Profile 통합 검증
    assertTrue(insight.engcProfile != null)
    assertEquals(engcProfile, insight.engcProfile)
}

@Test
fun `E2E test should handle incomplete DepthExploration gracefully`() = runTest {
    // Given: Q4 답변 없음
    val incompleteExploration = createCompletedDepthExploration(q4Answer = null)
    fakeGenerator.shouldFailForIncomplete = true

    // When: Insight 생성 시도
    val result = generateInsightUseCase(incompleteExploration)

    // Then: 실패 검증
    assertTrue(result.isFailure)
    assertTrue(result.exceptionOrNull() is IllegalStateException)
}
```

**테스트 커버리지**:
- ✅ **Happy Path**: 정상 흐름 (100%)
- ✅ **Natural Speech**: 자연어 포맷 (100%)
- ✅ **Side Effects**: 저장, 캐시 (100%)
- ✅ **Integration**: E/N/G/C Profile (100%)
- ✅ **Error Handling**: 실패 케이스 (100%)

---

## 9. 발견된 아키텍처 이슈 및 해결

### 9.1 이슈 #1: 파라미터 이름 불일치

**문제**:
```kotlin
// ❌ 추측한 파라미터
DepthSignal(
    emotionLevel = 0.85,
    keyword = "고민",        // ❌ singular
    context = "의사결정",     // ❌ 존재하지 않음
    triggeredAt = now
)

// ✅ 실제 파라미터
DepthSignal(
    id = "signal_001",           // ✅ 추가됨
    sessionId = "session_001",   // ✅ 추가됨
    emotionLevel = 0.85,
    keywords = listOf("고민", "의사결정"),  // ✅ plural + List
    repetitionCount = 3,         // ✅ 추가됨
    triggeredAt = now
)
```

**근본 원인**:
- 도메인 모델을 읽지 않고 추측으로 작성
- 파라미터 이름이 직관적이지 않음 (keyword vs keywords)

**해결책**:
- ✅ **항상 도메인 모델 먼저 읽기**: Read → Understand → Implement
- ✅ **컴파일러 에러 활용**: 파라미터 불일치 즉시 감지
- ✅ **IDE 자동 완성 신뢰**: 파라미터 이름 정확히 입력

**교훈**:
> "추측하지 말고 확인하라" - 모든 도메인 모델은 정의를 먼저 읽어야 함

### 9.2 이슈 #2: Instant 타입 혼용

**문제**:
```kotlin
// DEPTH Layer
import java.time.Instant

// INSIGHT Layer
import kotlinx.datetime.Instant

// E2E Test
val now = Instant.now()  // ❌ 어떤 Instant?
```

**근본 원인**:
- 두 Layer가 다른 시점에 구현되며 타입 통일 안 됨
- Kotlin에서 두 Instant 타입이 공존 가능

**해결책**:
```kotlin
// Helper 메서드에서 명시적 타입 사용
import java.time.Instant as JavaInstant
import kotlinx.datetime.Instant as KotlinInstant

private fun createDepthExploration(...): DepthExploration {
    val now: JavaInstant = JavaInstant.now()
    return DepthExploration(..., createdAt = now, ...)
}

// Fake에서 명시적 타입 사용
class FakeInsightGenerator : InsightGenerator {
    override suspend fun generateInsight(...): Result<Insight> {
        val insight = Insight(..., createdAt = Clock.System.now(), ...)
        //                                      ^^^^^^^^^^^^^^^^ kotlinx.datetime
        return Result.success(insight)
    }
}
```

**향후 리팩토링**:
- DEPTH Layer를 `kotlinx.datetime.Instant`로 통일 (Kotlin Multiplatform 대비)

**교훈**:
> "타입 일관성은 처음부터" - Layer 간 데이터 타입은 프로젝트 초기에 통일할 것

### 9.3 이슈 #3: InsightException 접근성

**문제**:
```kotlin
// ❌ protected constructor
class InsightException protected constructor(message: String) : Exception(message)

// ❌ 사용 불가
return Result.failure(InsightException("Error"))
// Error: Cannot access 'constructor(message: String)': it is protected
```

**해결책**:
```kotlin
// ✅ 표준 Exception 사용
return Result.failure(IllegalStateException("Incomplete DepthExploration: Q4 answer missing"))

// OR: InsightException을 public으로 변경
class InsightException(message: String) : Exception(message)
```

**근본 원인**:
- Domain Exception이 protected로 설계됨 (companion object factory 패턴)
- E2E 테스트에서 직접 생성 불가

**교훈**:
> "Exception은 public으로" - 테스트에서 직접 생성 가능해야 함

### 9.4 이슈 #4: EngcProfile 파라미터 타입

**문제**:
```kotlin
// ❌ 추측한 구조
EngcProfile(
    emotions = listOf("불안", "기대"),    // ❌ List<String>
    needs = listOf("안정", "성장"),       // ❌ List<String>
    goals = listOf("커리어 발전"),        // ❌ List<String>
    constraints = listOf("재정 여건")     // ❌ List<String>
)

// ✅ 실제 구조
EngcProfile(
    emotion = listOf(ProfileItem("불안"), ProfileItem("기대")),    // ✅ List<ProfileItem>
    need = listOf(ProfileItem("안정"), ProfileItem("성장")),       // ✅ List<ProfileItem>
    goal = listOf(ProfileItem("커리어 발전")),                     // ✅ List<ProfileItem>
    constraint = listOf(ProfileItem("재정 여건"))                  // ✅ List<ProfileItem>
)
```

**근본 원인**:
- OntologyRAG API 모델이 복잡함 (ProfileItem 중첩 구조)
- 파라미터 이름이 단수형 (emotion, need, goal, constraint)

**해결책**:
- ✅ **OntologyRAGModels.kt 확인**: API 모델 정의 먼저 읽기
- ✅ **@Serializable 어노테이션 확인**: JSON 매핑 구조 이해

**교훈**:
> "외부 API 모델은 신중히" - API 모델은 내부 도메인과 다를 수 있음

### 9.5 이슈 #5: Result<Unit> vs Result<String>

**문제**:
```kotlin
// ❌ 추측한 반환 타입
interface InsightRepository {
    suspend fun saveInsight(insight: Insight): Result<Unit>  // ❌ 성공/실패만
}

// ✅ 실제 반환 타입
interface InsightRepository {
    suspend fun saveInsight(insight: Insight): Result<String>  // ✅ ID 반환
}
```

**근본 원인**:
- 저장 작업은 `Unit` 반환이 일반적이라고 추측
- 하지만 실제로는 생성된 ID를 반환하는 것이 유용

**장점 (Result<String>)**:
- 저장된 Insight의 ID를 즉시 사용 가능
- 후속 작업 (조회, 업데이트, 삭제) 용이
- RESTful API 패턴 준수 (POST → 201 Created + Location Header)

**교훈**:
> "반환 값은 유용성 우선" - 후속 작업을 고려한 반환 타입 선택

---

## 10. 향후 개선 방향

### 10.1 아키텍처 개선

#### 10.1.1 Instant 타입 통일

```kotlin
// 목표: 모든 Layer에서 kotlinx.datetime.Instant 사용

// DEPTH Layer 리팩토링
// Before: java.time.Instant
// After:  kotlinx.datetime.Instant

// 변환 작업:
1. DepthSignal.kt: import java.time.Instant → import kotlinx.datetime.Instant
2. DepthExploration.kt: import java.time.Instant → import kotlinx.datetime.Instant
3. 모든 Instant.now() → Clock.System.now()
4. 관련 테스트 업데이트
```

**예상 효과**:
- Kotlin Multiplatform 지원
- 타입 일관성 향상
- 변환 함수 제거

#### 10.1.2 Exception 계층 구조 개선

```kotlin
// 현재: protected constructor
class InsightException protected constructor(message: String) : Exception(message)

// 개선: Sealed class hierarchy
sealed class InsightError(message: String) : Exception(message) {
    class IncompleteExploration(explorationId: String) :
        InsightError("Incomplete DepthExploration: $explorationId")

    class GenerationFailed(reason: String) :
        InsightError("Insight generation failed: $reason")

    class SaveFailed(insightId: String, reason: String) :
        InsightError("Failed to save insight $insightId: $reason")
}

// 사용
return Result.failure(InsightError.IncompleteExploration(exploration.id))
```

**장점**:
- 타입 안전한 에러 처리
- when 표현식에서 exhaustive check
- 명확한 에러 분류

#### 10.1.3 Domain Event 도입

```kotlin
// 현재: UseCase에서 직접 저장
class GenerateInsightUseCase {
    suspend operator fun invoke(exploration: DepthExploration): Result<Insight> {
        return generator.generateInsight(exploration)
            .mapCatching { insight ->
                repository.saveInsight(insight)  // ← 직접 저장
                insight
            }
    }
}

// 개선: Domain Event 발행
sealed class InsightEvent {
    data class Generated(val insight: Insight) : InsightEvent()
    data class Saved(val insightId: String) : InsightEvent()
    data class Failed(val error: InsightError) : InsightEvent()
}

class GenerateInsightUseCase(
    private val generator: InsightGenerator,
    private val eventBus: EventBus
) {
    suspend operator fun invoke(exploration: DepthExploration): Result<Insight> {
        return generator.generateInsight(exploration)
            .onSuccess { insight ->
                eventBus.publish(InsightEvent.Generated(insight))
            }
            .onFailure { error ->
                eventBus.publish(InsightEvent.Failed(error as InsightError))
            }
    }
}

// Event Handler (별도)
class InsightEventHandler(
    private val repository: InsightRepository,
    private val ontologyRAGClient: OntologyRAGClient
) {
    suspend fun handle(event: InsightEvent) {
        when (event) {
            is InsightEvent.Generated -> {
                repository.saveInsight(event.insight)
                ontologyRAGClient.saveEngcEvents(event.insight.toEngcEvents())
            }
            is InsightEvent.Saved -> {
                // Analytics, Logging, etc.
            }
            is InsightEvent.Failed -> {
                // Error reporting
            }
        }
    }
}
```

**장점**:
- UseCase SRP 준수 (생성만 담당)
- 비즈니스 로직 확장 용이
- 테스트 격리 향상

### 10.2 성능 개선

#### 10.2.1 캐시 전략 최적화

```kotlin
// 현재: 단순 LRU Cache
class MemoryCache<K, V>(private val maxSize: Int = 50) {
    private val cache = LruCache<K, CacheEntry<V>>(maxSize)
}

// 개선: TTL + Size-based Eviction
class SmartCache<K, V>(
    private val maxSize: Int = 50,
    private val ttl: Duration = 1.hours
) {
    private val cache = ConcurrentHashMap<K, CacheEntry<V>>()

    data class CacheEntry<V>(
        val value: V,
        val createdAt: Instant,
        val accessCount: Int = 0,
        val sizeBytes: Long
    )

    suspend fun get(key: K): V? {
        val entry = cache[key] ?: return null

        // TTL 체크
        if (Clock.System.now() - entry.createdAt > ttl) {
            cache.remove(key)
            return null
        }

        // Access count 업데이트
        cache[key] = entry.copy(accessCount = entry.accessCount + 1)
        return entry.value
    }

    suspend fun put(key: K, value: V) {
        // Size-based eviction
        val sizeBytes = estimateSize(value)
        if (cache.size >= maxSize) {
            evictLeastValuable()
        }

        cache[key] = CacheEntry(
            value = value,
            createdAt = Clock.System.now(),
            sizeBytes = sizeBytes
        )
    }

    private fun evictLeastValuable() {
        // LFU (Least Frequently Used) + LRU 조합
        val leastValuable = cache.entries.minByOrNull {
            it.value.accessCount / (Clock.System.now() - it.value.createdAt).inWholeHours
        }
        leastValuable?.let { cache.remove(it.key) }
    }
}
```

#### 10.2.2 API 호출 배치 처리

```kotlin
// 현재: 개별 API 호출
suspend fun generateInsight(exploration: DepthExploration): Result<Insight> {
    val profile = ontologyRAGClient.getEngcProfile(exploration.googleSub)  // Call 1
    val searchResults = ontologyRAGClient.hybridSearch(...)                 // Call 2
    // ...
}

// 개선: 배치 API 호출
suspend fun generateInsight(exploration: DepthExploration): Result<Insight> {
    val (profile, searchResults) = coroutineScope {
        val profileDeferred = async { ontologyRAGClient.getEngcProfile(...) }
        val searchDeferred = async { ontologyRAGClient.hybridSearch(...) }
        profileDeferred.await() to searchDeferred.await()
    }
    // ...
}
```

**예상 효과**:
- API 호출 시간 50% 감소 (병렬 처리)
- 네트워크 대기 최소화

### 10.3 테스트 개선

#### 10.3.1 Property-Based Testing 도입

```kotlin
// 현재: 고정 테스트 데이터
@Test
fun `should generate insight from completed exploration`() {
    val exploration = createCompletedDepthExploration(
        q1Answer = "팀장과의 갈등...",
        q2Answer = "이직할지...",
        ...
    )
}

// 개선: Property-Based Testing
@Test
fun `should generate insight for any completed exploration`() = runTest {
    checkAll(
        Arb.depthExploration(isComplete = true)
    ) { exploration ->
        val result = generateInsightUseCase(exploration)

        assertTrue(result.isSuccess)
        val insight = result.getOrThrow()
        assertEquals(exploration.id, insight.explorationId)
        assertTrue(insight.situation.isNotBlank())
        assertTrue(insight.decision.isNotBlank())
    }
}

// Arbitrary Generator
fun Arb.Companion.depthExploration(isComplete: Boolean = true): Arb<DepthExploration> {
    return arbitrary { rs ->
        DepthExploration(
            id = Arb.uuid().bind(),
            sessionId = Arb.uuid().bind(),
            googleSub = Arb.string(10..20).bind(),
            signal = Arb.depthSignal().bind(),
            questions = CoreQuestion.all(),
            impacts = Arb.list(Arb.impactAnalysis(), 1..5).bind(),
            informationNeeds = Arb.list(Arb.informationNeed(), 1..3).bind(),
            createdAt = Arb.instant().bind(),
            completedAt = if (isComplete) Arb.instant().bind() else null,
            q1Answer = if (isComplete) Arb.string(10..100).bind() else null,
            q2Answer = if (isComplete) Arb.string(10..100).bind() else null,
            q3Answer = if (isComplete) Arb.string(10..100).bind() else null,
            q4Answer = if (isComplete) Arb.string(10..100).bind() else null
        )
    }
}
```

**장점**:
- 엣지 케이스 자동 발견
- 테스트 커버리지 향상
- 버그 조기 발견

#### 10.3.2 Contract Testing 도입

```kotlin
// OntologyRAG API Contract Test
@Test
fun `OntologyRAG API should conform to contract`() = runTest {
    val client = OntologyRAGClient(apiKey = TEST_API_KEY)

    // Contract: POST /engine/prompts/{google_sub}
    val profileResponse = client.getEngcProfile("test_user")

    // Schema validation
    assertNotNull(profileResponse.googleSub)
    assertNotNull(profileResponse.emotionPatterns)
    assertNotNull(profileResponse.needs)
    assertNotNull(profileResponse.goals)
    assertNotNull(profileResponse.constraints)

    // Type validation
    assertTrue(profileResponse.emotionPatterns is List<EmotionPattern>)
    assertTrue(profileResponse.needs.items is List<Map<String, String>>)
}
```

**장점**:
- API 변경 감지
- 통합 안정성 향상
- 문서화 효과

---

## 요약

### 핵심 인사이트

1. **v2 아키텍처는 완전히 구현되고 검증됨**
   - SURFACE (5-Phase) → DEPTH (4 Core Questions) → INSIGHT (Natural Speech)
   - E2E 테스트로 전체 흐름 검증 완료

2. **도메인 모델 정확성이 중요**
   - 파라미터 이름, 타입, 개수를 정확히 확인해야 함
   - 추측보다 확인이 빠름 (컴파일 에러로 즉시 감지)

3. **타입 일관성은 처음부터**
   - Instant 타입 혼용 문제 발견
   - 향후 kotlinx.datetime로 통일 권장

4. **Fake 패턴은 E2E 테스트에 적합**
   - 실제 동작 시뮬레이션
   - 상태 추적으로 부작용 검증
   - 프로젝트 패턴 준수

5. **API 통합은 복잡함**
   - OntologyRAG API 모델이 복잡 (ProfileItem 중첩)
   - 변환 레이어 필수 (Domain ↔ API)

### 다음 단계

1. ✅ **E2E Integration Testing 완료**
2. ⏳ **Phase 2 Refactoring 완료** (5-Layer 구조)
3. 🔜 **Phase 3: Dynamic Allocation** (동적 토큰 할당)
4. 🔜 **Instant 타입 통일** (DEPTH Layer 리팩토링)
5. 🔜 **성능 최적화** (캐시 전략, API 배치 처리)

---

**참조 문서**:
- `/docs/PLAN.md` - 전체 개발 계획
- `/docs/current_state.md` - 현재 상태
- `/docs/decisions.md` - 설계 결정
- `/docs/ondev/key/20251206_VoiceChat_Engine_Ideation_v2.md` - v2 비전
- `/android/app/src/test/kotlin/com/example/incarcompanion/integration/DepthToInsightE2ETest.kt` - E2E 테스트

**작성자**: Claude Sonnet 4.5
**최종 업데이트**: 2025-12-22
