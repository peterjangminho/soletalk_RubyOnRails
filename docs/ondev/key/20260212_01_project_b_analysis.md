# Project_B Comprehensive Technical Analysis

## Migration Assessment: Project_B (Kotlin/Android + React WebView) to Project_A (Ruby on Rails + Hotwire Native)

**Date**: 2026-02-12
**Analyst**: AI-assisted migration analysis
**Source Codebase**: `/Users/peter/Project/Project_B`
**Target Codebase**: `/Users/peter/Project/Project_A`

---

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [Architecture Pattern](#2-architecture-pattern)
3. [Key Components](#3-key-components)
4. [OntologyRAG Integration](#4-ontologyrag-integration)
5. [VoiceChat Engine Implementation](#5-voicechat-engine-implementation)
6. [Authentication](#6-authentication)
7. [External Dependencies](#7-external-dependencies)
8. [Code Complexity Assessment](#8-code-complexity-assessment)
9. [Data Flow](#9-data-flow)
10. [What's Reusable](#10-whats-reusable)
11. [Summary Assessment](#11-summary-assessment)

---

## 1. Project Structure

### Overall Layout

Project_B is a **hybrid application** with two distinct layers:

```
Project_B/
├── android/                           # Kotlin/Android native layer
│   └── app/src/main/kotlin/com/example/incarcompanion/
│       ├── context/                   # Context architecture (5-layer, Kotlin)
│       │   ├── allocation/            # Dynamic token allocation
│       │   ├── api/                   # OntologyRAG HTTP client + Tavily
│       │   ├── cache/                 # Two-level cache (Memory + Disk)
│       │   ├── config/               # ContextConfig.kt (centralized config)
│       │   └── layers/               # ContextLayer<T> interface
│       ├── data/                      # Data layer (repositories, clients)
│       │   ├── audio/webrtc/         # WebRTC audio pipeline
│       │   ├── depth/                # DEPTH layer caching
│       │   ├── insight/              # Insight generation + caching
│       │   ├── monitoring/           # Sentry integration
│       │   ├── ontologyrag/          # API models + constants (~1400 lines)
│       │   ├── repository/           # Repository implementations
│       │   └── supabase/             # AuthManager + SupabaseClientProvider
│       └── domain/                    # Domain layer (business logic)
│           ├── audio/                # Barge-in detection
│           ├── depth/                # DepthExploration, Q1-Q4, Signal detection
│           ├── engc/                 # E/N/G/C analyzer
│           ├── insight/              # Insight generation domain
│           ├── model/                # Core domain models
│           │   └── graph/            # Decision/Person/Pattern models
│           ├── models/               # SessionPhase enum
│           ├── permission/           # Permission checker
│           ├── repository/           # Repository interfaces
│           │   └── graph/            # Graph repository interface
│           └── voicechat/            # VoiceChatManager (~1322 lines, core)
│
├── services/                          # TypeScript/React service layer (~30 files)
│   ├── contextOrchestrator.ts        # 7-layer context management
│   ├── phaseTransitionService.ts     # Phase state machine rules
│   ├── emotionEnergyService.ts       # Emotion/energy tracking
│   ├── narrowingService.ts           # Narrowing principle
│   ├── sentimentAnalysisGemini.ts    # Gemini-based sentiment
│   ├── sessionStateService.ts        # Session state persistence
│   ├── conversationSummarizer.ts     # Conversation summary generation
│   ├── conversationKeywordExtractor.ts
│   ├── webSearchService.server.ts    # Web search (Tavily/Brave)
│   ├── providers/                    # Search providers (Brave, Exa)
│   ├── supabaseClient.ts            # Supabase client wrapper
│   └── ...
│
├── components/                        # React UI components
├── hooks/                             # React hooks
├── shared/                            # Shared constants/utilities
├── supabase/                          # Supabase Edge Functions
│   └── functions/voice-session-api/  # BFF (Backend-for-Frontend)
│
├── App.tsx                            # React entry point
├── types.ts                           # Core TypeScript types (~486 lines)
├── constants.ts                       # All constants (~572 lines)
├── config.ts                          # Environment configuration
└── package.json                       # Node dependencies
```

### File Statistics

| Layer | File Type | Approximate Count |
|-------|-----------|-------------------|
| Kotlin Native | `.kt` | ~90+ source files |
| TypeScript/React | `.ts` / `.tsx` | ~50+ source files (excluding node_modules) |
| XML (Android) | `.xml` | ~30+ layout/resource files |
| Tests (Kotlin) | `.kt` in test dirs | ~60+ test files |
| Tests (TypeScript) | `.test.ts` | ~5 test files |

### Key Observation

The codebase exhibits **significant duplication** between the TypeScript and Kotlin layers. Both layers implement overlapping business logic for phase transitions, emotion/energy tracking, narrowing, and context orchestration. This suggests an architectural evolution where the React WebView layer was built first for rapid prototyping, and the Kotlin layer was then built to support native Android capabilities (audio, background services).

---

## 2. Architecture Pattern

### Dual-Layer Hybrid Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Android App Shell                     │
│                  (Kotlin + Compose)                      │
│                                                          │
│  ┌─────────────────────┐  ┌─────────────────────────┐  │
│  │  Native Kotlin       │  │   React WebView          │  │
│  │  (Audio, VoiceChat,  │  │   (UI, Context Orch,     │  │
│  │   OntologyRAG Client,│  │    Phase Transitions,    │  │
│  │   Depth/Insight)     │  │    Sentiment, BFF calls) │  │
│  │                      │  │                          │  │
│  │  MVVM + StateFlow    │  │  React Hooks + State     │  │
│  └──────────┬───────────┘  └───────────┬──────────────┘  │
│             │                          │                  │
│             │   WebView Bridge (JS)    │                  │
│             └──────────────────────────┘                  │
│                          │                                │
│            ┌─────────────┴─────────────┐                 │
│            │                           │                  │
│            v                           v                  │
│     ┌──────────────┐         ┌──────────────────┐        │
│     │  OntologyRAG │         │     Supabase      │       │
│     │  (Project_E) │         │  (Cloud Postgres)  │       │
│     │  FastAPI+Neo4j│         │  Auth + Tables     │       │
│     └──────────────┘         └──────────────────┘        │
└─────────────────────────────────────────────────────────┘
```

### Architecture Patterns Used

| Pattern | Location | Description |
|---------|----------|-------------|
| **MVVM** | Kotlin layer | ViewModel + StateFlow for reactive state management |
| **Repository Pattern** | Kotlin `data/repository/` | Abstract data sources behind interfaces |
| **Service Object** | TypeScript `services/` | Business logic in pure functions/modules |
| **Dependency Injection (Koin)** | Kotlin | Constructor injection, module definitions |
| **Sealed Class / Result** | Kotlin | Error handling with `Result<T>` and sealed classes |
| **State Machine** | Both layers | VoiceChatPhase enum with transition rules |
| **Two-Level Cache** | Kotlin `data/depth/cache/` | Memory + Disk caching strategy |
| **Layer Architecture** | Both layers | 5-7 layer context assembly |
| **BFF Pattern** | Supabase Edge Functions | Backend-for-Frontend in `supabase/functions/` |

### Kotlin Layer Architecture (Clean Architecture)

```
Presentation (ViewModel + Compose)
    ↓
Domain (Use Cases, Business Logic, Repository Interfaces)
    ↓
Data (Repository Implementations, API Clients, Database)
```

### React/TypeScript Layer Architecture

```
Components (UI) + Hooks (State)
    ↓
Services (Business Logic)
    ↓
Supabase Client (Data)
    ↓
Supabase Edge Functions (BFF)
```

### Migration Implication

For Rails migration, the dual-layer architecture should collapse into a single server-side architecture:

- **Kotlin MVVM + React State** -> Stimulus Controllers + Turbo Frames
- **Repository Pattern** -> Rails Service Objects / ActiveRecord
- **Koin DI** -> Rails native (Service Objects, autoloading)
- **WebView Bridge** -> Eliminated (Hotwire Native replaces WebView)
- **BFF Edge Functions** -> Rails controllers directly

---

## 3. Key Components

### 3.1 VoiceChatManager (Core Orchestrator)

**File**: `android/.../domain/voicechat/VoiceChatManager.kt` (~1322 lines)

This is the **central nervous system** of the application. It orchestrates:

- Audio pipeline (WebRTC + VAD + barge-in detection)
- Gemini Live API connection for real-time voice
- Phase transition engine (5-phase state machine)
- Sentiment analysis integration
- Graph entity extraction (debounced, keyword-triggered)
- Session lifecycle management (start -> record -> end -> save)
- OntologyRAG API calls for memory storage

```kotlin
// Key dependencies injected via Koin
class VoiceChatManager(
    private val vadManager: VadManager,
    private val geminiLiveManager: GeminiLiveManager,
    private val webRtcPipeline: WebRtcAudioPipelineManager,
    private val graphExtractor: GraphEntityExtractor,
    private val graphAutoSave: GraphAutoSaveUseCase,
    private val phaseTransitionEngine: PhaseTransitionEngine,
    private val phaseHandlerFactory: PhaseHandlerFactory,
    private val sentimentIntegrator: VoiceChatSentimentIntegrator,
    private val conversationRepo: ConversationRepository
)
```

**Rails Equivalent**: `app/services/voice_chat/manager.rb` (Service Object)

### 3.2 Context Orchestrator

**File (TS)**: `services/contextOrchestrator.ts` (~288 lines)
**File (Kotlin)**: `android/.../context/` (multiple files)

Manages the multi-layer context architecture for LLM prompts:

| Layer | TS Implementation | Kotlin Implementation | Budget |
|-------|-------------------|----------------------|--------|
| 1. Profile | `layer1: string` | `ProfileLayerManager` | 10% |
| 2. Summaries | `layer2: string[]` | `PastMemoryLayerManager` | 15-20% |
| 3. RAG | `layer3: string[]` | (included in Layer 2) | 20% |
| 4. Session | `layer4: string` | `CurrentSessionLayerManager` | 25-50% |
| 5. Web Search | `layer5: string` | `AdditionalInfoLayerManager` | 10% |
| 6. Persona | `layer6: string` | `PersonaLayerManager` | 10-15% |
| 7. Sentiment | `layer7: string` | (integrated) | 5% |

Key functions:
- `calculateContextSize()` - Total character count
- `isContextOverBudget()` - Budget enforcement check (32K char limit)
- `enforceTokenBudget()` - Priority-based pruning (Layer5 first, then reduce Layer3, then Layer2)
- `assembleSystemInstruction()` - Template filling and concatenation
- `loadLayer2Summaries()` - Dynamic keyword-based summary loading from Supabase

**Note**: The Kotlin layer uses a 5-layer model with dynamic token allocation (min/max percentages), while the TS layer uses a simpler 7-layer model with character-based budgets. This discrepancy needs resolution during migration.

**Rails Equivalent**: `app/services/context_orchestrator.rb`

### 3.3 Phase Transition Engine

**File (TS)**: `services/phaseTransitionService.ts` (~298 lines)
**File (Kotlin)**: `android/.../domain/voicechat/VoiceChatPhase.kt` + handlers

The 5-Phase VoiceChat Engine implements a cyclic state machine:

```
INPUT -> EMOTION_EXPAND -> FREE_TALK -> SILENCE -> RE_ENGAGE -> (loop)
                                          |
                                          v (if energy drops)
                                     NARROWING
                                          |
                                          v (depth reached)
                                     STORY_MODE
```

Transition rules evaluated in priority order:
1. **Story Complete** - Story finishes -> RE_ENGAGE
2. **User Choice** - User selects mode -> STORY_MODE or stays
3. **Utterance** - User speaks -> phase-specific routing
4. **Silence** (7 seconds) - No speech detected -> SILENCE
5. **Energy** - Energy drops below threshold -> RE_ENGAGE
6. **Narrowing** - Engagement conditions met -> NARROWING

```typescript
// Core transition function
export function evaluateTransition(
  state: SessionState,
  event: TransitionEvent
): TransitionResult {
  // Priority order evaluation
  const rules = [
    evaluateStoryRule,
    evaluateReStimulationCompleteRule,
    evaluateUtteranceRule,
    evaluateSilenceRule,
    evaluateEnergyRule,
    evaluateNarrowingRule
  ];
  // ...
}
```

**Rails Equivalent**: `app/services/voice_chat/phase_transition_engine.rb`

### 3.4 Emotion/Energy Tracking System

**File**: `services/emotionEnergyService.ts` (~348 lines)

Comprehensive emotion and energy tracking:

- **Emotion Extraction**: Converts SentimentResult -> EmotionExtraction with binary flags and intensity
- **Emotion Level Calculation**: 0.0-1.0 scale based on sentiment label + intensity
- **Energy Level Calculation**: Based on utterance length, frequency, and recency (weighted)
- **Trajectory Tracking**: Linear regression slope analysis over history entries
- **State Evaluation**: Classifies combined state as engaged/fatigued/distressed/neutral/excited
- **Action Recommendation**: continue/re_stimulate/support/explore based on state

```typescript
// Example: Energy calculation factors
const lengthScore = Math.min(text.length / 200, 1.0);  // Longer = more energy
const frequencyScore = Math.min(recentCount / 10, 1.0); // More frequent = more energy
const recencyScore = /* exponential decay */;             // Recent activity = more energy
```

**Rails Equivalent**: `app/services/voice_chat/emotion_energy_tracker.rb`

### 3.5 Narrowing Service

**File**: `services/narrowingService.ts` (~343 lines)

Implements the Narrowing Principle (open -> specific questions):

- **Question Types by Depth**: 0=open, <=2=exploratory, <max=focused, max=specific
- **Topic Detection**: Keyword matching against user utterance
- **Depth Control**: Increment/reset based on engagement signals
- **Strategy Selection**: continue/reset/maintain based on emotion + energy
- **Korean Prompt Generation**: Generates Korean-language prompts with key noun extraction

```typescript
// Question type progression
depth 0: "How was your day?"                    // open
depth 1-2: "Tell me more about your work"       // exploratory
depth 3-4: "What specifically concerns you?"     // focused
depth 5 (max): "Would you like to try ~~?"      // specific
```

**Rails Equivalent**: `app/services/voice_chat/narrowing_service.rb`

### 3.6 Sentiment Analysis (Gemini-based)

**File**: `services/sentimentAnalysisGemini.ts`

Uses Gemini AI to perform multi-dimensional Korean-language sentiment analysis:

- 13 emotion dimensions (joy, sadness, anger, fear, surprise, disgust, ambivalence, resignation, apathy, distress, hurt, suppression, acceptance)
- Korean linguistic signals detection
- Emotional trajectory tracking
- VoiceChat stage-specific response tone recommendations

**Rails Equivalent**: `app/services/sentiment_analysis.rb` (via Gemini API)

### 3.7 3-Layer Personal Ontology (DEPTH Layer)

**File (Kotlin)**: `android/.../domain/depth/DepthExploration.kt`

The DEPTH layer provides deep emotional exploration through 4 Core Questions:

| Question | Purpose | Storage |
|----------|---------|---------|
| Q1. WHY | Uncover true emotions behind surface feelings | EmotionDetected, Pattern |
| Q2. DECISION | Crystallize vague concerns into decision problems | Decision Object |
| Q3. IMPACT | Multi-dimensional impact analysis (5 dimensions) | ImpactAnalysis |
| Q4. DATA | Identify and connect needed information | InformationNeed |

```kotlin
data class DepthExploration(
    val id: String,
    val sessionId: String,
    val googleSub: String,
    val signal: DepthSignal,                    // Trigger signal
    val questions: List<CoreQuestion>,           // Q1-Q4
    val impacts: List<ImpactAnalysis>,          // 5 dimensions
    val informationNeeds: List<InformationNeed>,
    val q1Answer: String? = null,
    val q2Answer: String? = null,
    val q3Answer: String? = null,
    val q4Answer: String? = null
)
```

DEPTH Entry Conditions:
- `emotion_level > 0.8` (high emotion intensity)
- Keywords: "I don't know", "I'm worried", "what should I do"
- Same topic repeated 3+ times
- Avoidance pattern detected

### 3.8 Insight Generation

**File (Kotlin)**: `android/.../domain/insight/Insight.kt`

Maps Q1-Q4 answers to actionable guidance:

```kotlin
data class Insight(
    val situation: String,      // Based on Q1.WHY
    val data: String,           // Based on Q4.DATA
    val decision: String,       // Based on Q2.DECISION
    val actionGuide: String,    // Based on Q3.IMPACT
    val engcProfile: EngcProfile? // E/N/G/C from OntologyRAG
)

// Natural speech conversion template
fun toNaturalSpeech(): String {
    return "${situation}인 상황에서, ${data}이(가) 있으니까, " +
           "${decision}을(를) 위해, ${actionGuide}하는 건 어떨까요?"
}
```

**Rails Equivalent**: `app/services/insight/generator.rb` + `app/services/insight/natural_speech.rb`

---

## 4. OntologyRAG Integration

### HTTP Client Architecture

**Kotlin Client**: `android/.../context/api/OntologyRAGClient.kt` (~298 lines)

```kotlin
class OntologyRAGClient(
    private val baseUrl: String,
    private val apiKey: String,
    private val client: OkHttpClient  // OkHttp with interceptors
) {
    // Exponential backoff retry (max 3 attempts)
    // Result<T> sealed class for error handling

    suspend fun query(request: QueryRequest): Result<QueryResponse>
    suspend fun batchEvents(events: List<InCarEvent>): Result<BatchEventsResponse>
    suspend fun getUserProfile(googleSub: String): Result<ProfileResponse>
}
```

**TypeScript Client**: Business logic in `services/` + BFF in Supabase Edge Functions

### API Endpoints Summary

**Source**: `OntologyRAGConstants.kt` (Kotlin) + `constants.ts` (TypeScript)

| Category | Method | Endpoint | Purpose |
|----------|--------|----------|---------|
| **Core Engine** | | | |
| Health | GET | `/health` | Server status |
| Containers | CRUD | `/engine/containers` | Container management |
| Objects | CRUD | `/engine/objects` | Object management |
| Events | CRUD | `/engine/events` | Event management |
| Query | POST | `/engine/query` | Hybrid search (vector + graph) |
| **InCar Specific** | | | |
| Conversation Save | POST | `/incar/conversations/{session_id}/save` | Full session save |
| Conversation List | GET | `/incar/conversations` | List conversations |
| Conversation Turns | GET | `/incar/conversations/{id}/turns` | Get utterances |
| Memory Store | POST | `/incar/memories/store` | Store memory |
| Memory Recall | GET | `/incar/memories/recall` | Recall memories |
| Profile | GET | `/incar/profile/{google_sub}` | Get E/N/G/C profile |
| **Graph (Neo4j)** | | | |
| Decisions | CRUD | `/incar/graph/decisions` | Decision management |
| Persons | CRUD | `/incar/graph/persons` | Person management |
| Relations | CRUD | `/incar/graph/relations` | Relationship management |
| Traverse | POST | `/incar/graph/traverse` | Graph traversal |
| **Depth Layer** | | | |
| E/N/G/C Profile | GET | `/engine/prompts/{google_sub}` | Profile with patterns |
| E/N/G/C Event | POST | `/engine/events/engc` | Create E/N/G/C event |
| Graph Query | POST | `/engine/graph/query` | Hybrid graph search |
| **VoiceChat** | | | |
| Main Router | POST | `/engine/voicechat` | Auto-dispatch to layers |
| Surface | POST | `/engine/voicechat/surface` | Emotion recognition |
| Depth | POST | `/engine/voicechat/depth` | Q1-Q4 exploration |
| Insight | POST | `/engine/voicechat/insight` | Action suggestion |
| **Document** | | | |
| Upload | POST | `/engine/documents` | Document upload |
| List | GET | `/engine/documents` | List documents |
| Delete | DELETE | `/engine/documents/{id}` | Delete document |

### Common Headers

```
X-API-Key: {ONTOLOGYRAG_API_KEY}
X-Google-Sub: {google_sub}  (optional, for user context)
X-Source-App: "incar"
X-Request-ID: "incar-{timestamp}"
Content-Type: application/json
```

### Key Configuration Values

| Setting | Value | Source |
|---------|-------|--------|
| Production URL | `https://ontologyrag01-production.up.railway.app` | Constants |
| Request Timeout | 30,000ms | OntologyRAGConstants.Timeouts |
| Connect Timeout | 10,000ms | OntologyRAGConstants.Timeouts |
| Max Retries | 2 (excluding original) | OntologyRAGConstants.Retry |
| Retry Delay | 1,000ms (exponential backoff) | OntologyRAGConstants.Retry |
| Retryable Status | 502, 503, 504 | OntologyRAGConstants.Retry |
| Default top_k | 5 | QueryDefaults |
| Min Relevance | 0.5 | QueryDefaults |

### E/N/G/C Data Model (Critical Naming)

```kotlin
// IMPORTANT: Parameter names are SINGULAR (confirmed in E2E testing)
data class EngcProfile(
    val emotion: List<ProfileItem>,        // NOT emotions
    val need: List<ProfileItem>,           // NOT needs
    val goal: List<ProfileItem>,           // NOT goals
    val constraint: List<ProfileItem>,     // NOT constraints
    val keywords: List<String>
)

data class ProfileItem(
    val content: String,
    val engcCategory: String,
    val weight: Float? = null,
    val timestamp: String? = null
)
```

### Graph Relation Types

| Relation | From | To | Meaning |
|----------|------|----|---------|
| `CONSIDERING` | User | Decision | User is considering a decision |
| `MENTIONS` | Utterance | Entity | Utterance references an entity |
| `INVOLVES` | Decision | Person | Person is involved in decision |
| `LIMITED_BY` | Decision | Constraint | Decision is limited by constraint |
| `AIMS_FOR` | Decision | Goal | Decision aims for goal |
| `EXHIBITS` | User | Pattern | User shows behavioral pattern |
| `INFLUENCES` | Pattern | Decision | Pattern influences decision |

### Rails Migration Mapping

```ruby
# app/services/ontology_rag/client.rb
class OntologyRag::Client
  BASE_URL = ENV['ONTOLOGY_RAG_BASE_URL']

  # Use Faraday with retry middleware
  def initialize
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.request :retry, max: 2, interval: 1, backoff_factor: 2
      f.response :json
      f.headers['X-API-Key'] = ENV['ONTOLOGY_RAG_API_KEY']
      f.headers['X-Source-App'] = 'soletalk-rails'
    end
  end
end
```

---

## 5. VoiceChat Engine Implementation

### 5-Phase State Machine

```
┌──────────┐     user speaks     ┌────────────────┐
│  INPUT   │ ──────────────────> │ EMOTION_EXPAND │
│ (Opener) │                     │ (Identify)     │
└──────────┘                     └───────┬────────┘
     ^                                   │ user responds
     │                                   v
     │ (loop)                    ┌──────────────┐
     │                           │  FREE_TALK   │
     │                           │ (Expression) │
     │                           └───────┬──────┘
     │                                   │ 7s silence
     │                                   v
     │                           ┌──────────────┐
     └───────────────────────────│   SILENCE    │
                                 │ (Detection)  │
                                 └───────┬──────┘
                                         │ continued silence
                                         v
                                 ┌──────────────┐
                                 │  RE_ENGAGE   │
                                 │ (Restart)    │
                                 └──────────────┘
                                         │
                              ┌──────────┼──────────┐
                              v          v          v
                         ┌────────┐ ┌────────┐ ┌──────┐
                         │NARROWING│ │ STORY  │ │ Loop │
                         │(Focus) │ │ (Tell) │ │ Back │
                         └────────┘ └────────┘ └──────┘
```

### Phase Details

| Phase | Trigger | Action | Next Phase |
|-------|---------|--------|------------|
| **INPUT** | Session start | Bot asks opening question (uses KeyInfo + weather) | EMOTION_EXPAND |
| **EMOTION_EXPAND** | User's first utterance | Identify emotional state, reflect back | FREE_TALK |
| **FREE_TALK** | User continues | Backchanneling, active listening, sentence counting | SILENCE (7s gap) |
| **SILENCE** | 7 seconds no speech | Wait for re-engagement | RE_ENGAGE (continued) |
| **RE_ENGAGE** | Silence continues | Present new perspective or question | INPUT (loop) |

### Depth Layer Triggering

The DEPTH layer activates when specific conditions are met during the Surface layer conversation:

```
Surface Phase (5 phases)
    │
    ├── emotion_level > 0.8?  ─────────────┐
    ├── "I don't know" / "what should I"? ──┤
    ├── Same topic 3+ times? ───────────────┤
    ├── Avoidance pattern detected? ────────┤
    │                                        v
    │                               ┌────────────────┐
    │                               │   DEPTH LAYER   │
    │                               │  Q1: WHY        │
    │                               │  Q2: DECISION   │
    │                               │  Q3: IMPACT     │
    │                               │  Q4: DATA       │
    │                               └───────┬────────┘
    │                                       v
    │                               ┌────────────────┐
    │                               │ INSIGHT LAYER   │
    │                               │ Action Guide    │
    │                               └────────────────┘
    │
    └── Continue Surface conversation
```

### Audio Pipeline

The Kotlin layer manages a WebRTC-based audio pipeline:

```
Microphone → WebRtcAudioPipelineManager → VAD (Voice Activity Detection)
    │                                           │
    │                                     ┌─────┴─────┐
    │                                     │  Speech?   │
    │                                     └─────┬─────┘
    │                                     Yes   │   No
    │                                           │
    v                                     ┌─────┴─────┐
SoftwareAecManager                        v           v
(Echo Cancellation)              Gemini Live API   Silence Timer
    │                            (STT + Response)   (7 seconds)
    v
BargeInDetector
(Interruption handling
 with cooldown)
```

### Key Configuration Constants

From `constants.ts`:

```typescript
// Audio
SAMPLE_RATE_HZ: 16000
BUFFER_SIZE: 1024

// Timing
SILENCE_THRESHOLD: 7000  // 7 seconds silence triggers phase change
BARGE_IN_COOLDOWN: 2000  // 2 seconds after barge-in detection

// Context Budget
TOTAL_CONTEXT_CHAR_LIMIT: 32000  // 32K character budget for Gemini

// AI Models
LIVE_MODEL_NAME: 'gemini-2.5-flash-native-audio-preview'
ASYNC_MODEL_NAME: 'gemini-3-flash-preview'
```

### Story Mode

When Re-stimulation triggers STORY_MODE:

```typescript
storyMode: {
    isActive: boolean,          // Story is playing
    topic: string | null,       // Story topic
    startTime: number | null,   // Start timestamp
    duration: number            // Target: 120-180 seconds
}
```

### External Information Strategy (4 Types)

| Type | Trigger | Example |
|------|---------|---------|
| **Type A**: Interest Updates | Pre-session, profile keywords | "By the way, there's news about [AI regulation] today" |
| **Type B**: State-based Info | Detected fatigue/stress | "You seem tired, I found something that might help" |
| **Type C**: Decision-related | Pending Decision | "You mentioned job change, here's relevant info" |
| **Type D**: Past Follow-up | RAG search on past topics | "You mentioned a meeting, how did it go?" |

---

## 6. Authentication

### Current Implementation (Project_B)

**Supabase Auth** with Google OAuth, extracting `google_sub` as the cross-application identifier.

**File**: `android/.../data/supabase/AuthManager.kt` (~445 lines)

#### 3-Tier Fallback Strategy

```kotlin
fun getGoogleSubWithFallback(): String? {
    // Priority 1: JWT 'sub' claim (direct from access token)
    val jwtSub = getGoogleSub()
    if (jwtSub != null) return jwtSub

    // Priority 2: user_metadata.sub (Supabase stores Google OAuth sub here)
    val userMetadataSub = extractGoogleSubFromUserMetadata()
    if (userMetadataSub != null) return userMetadataSub

    // Priority 3: identities[google].id (provider identity record)
    return extractGoogleSubFromIdentities()
}
```

#### JWT Handling

- Manual JWT parsing (Base64 decode, regex-based claim extraction)
- Token expiration check (`exp` claim vs current time)
- Automatic refresh token handling
- Caching of `google_sub` to avoid repeated JWT parsing

#### Auth Flow

```
User → Google OAuth → Supabase Auth → JWT (access_token)
    → AuthManager.parseJwtPayload() → google_sub extraction
    → google_sub used for all OntologyRAG API calls
```

### React Layer Auth

```typescript
// App.tsx - Supabase client exposed to Android WebView
window.__SUPABASE_CLIENT__ = supabase;

// Login flow
supabase.auth.signInWithOAuth({ provider: 'google' })
    → session.user.id (Supabase UID)
    → access_token (JWT with google_sub in 'sub' claim)
```

### Rails Migration Mapping

```ruby
# Project_A: OmniAuth Google OAuth2
# Gemfile
gem "omniauth-google-oauth2"

# app/controllers/auth/omniauth_callbacks_controller.rb
class Auth::OmniauthCallbacksController < ApplicationController
  def google_oauth2
    auth = request.env['omniauth.auth']
    google_sub = auth.uid  # This IS the google_sub
    # ...
  end
end
```

**Key Migration Note**: Rails OmniAuth directly provides `auth.uid` which is the `google_sub`. The complex 3-tier fallback strategy in Project_B is unnecessary in Rails - it exists because Supabase stores the identifier in multiple locations.

---

## 7. External Dependencies

### Kotlin/Android Dependencies

| Category | Library | Purpose | Rails Equivalent |
|----------|---------|---------|------------------|
| **HTTP** | OkHttp | HTTP client for OntologyRAG | Faraday |
| **JSON** | Gson / kotlinx.serialization | JSON parsing | built-in JSON / Jbuilder |
| **DI** | Koin | Dependency injection | Rails autoload |
| **State** | Kotlin Coroutines + Flow | Async + reactive | Action Cable / Turbo Streams |
| **DB** | Room (limited use) | Local SQLite | ActiveRecord + SQLite |
| **Auth** | Supabase Kotlin SDK | Authentication | OmniAuth |
| **Audio** | WebRTC | Audio pipeline | N/A (native app concern) |
| **AI** | Google Generative AI SDK | Gemini API | `@google/genai` or REST API |
| **Monitoring** | Sentry | Error tracking | Sentry Ruby / Rails |
| **Firebase** | Firebase Core | Analytics/Crash | N/A or Rails equivalent |

### TypeScript/React Dependencies

From `package.json`:

| Package | Version | Purpose | Rails Equivalent |
|---------|---------|---------|------------------|
| `react` | ^19.2.3 | UI framework | Turbo + Stimulus |
| `@google/genai` | ^1.29.1 | Gemini AI | Direct API / gem |
| `@supabase/supabase-js` | 2 | Database/Auth | ActiveRecord / OmniAuth |
| `@tavily/core` | ^0.5.13 | Web search | Faraday HTTP call |
| `langchain` | ^1.0.6 | LLM orchestration | Direct Gemini API |
| `@langchain/google-genai` | ^1.0.3 | Gemini via LangChain | Direct API |
| `@langchain/textsplitters` | ^1.0.0 | Text chunking | Ruby text processing |
| `@langchain/community` | ^1.0.4 | LangChain plugins | N/A |
| `lucide-react` | ^0.553.0 | Icons | Heroicons / Lucide |
| `focus-trap-react` | ^11.0.6 | Accessibility | Stimulus controller |

### Dev Dependencies

| Package | Version | Purpose | Rails Equivalent |
|---------|---------|---------|------------------|
| `vite` | ^6.2.0 | Build tool | Propshaft / Rails asset pipeline |
| `vitest` | ^4.0.9 | Testing | Minitest / RSpec |
| `@playwright/test` | ^1.56.1 | E2E testing | Capybara + Playwright driver |
| `@testing-library/react` | ^16.3.0 | Component testing | System tests |
| `typescript` | ~5.8.2 | Type checking | N/A (Ruby is dynamic) |
| `happy-dom` | ^20.0.10 | DOM testing | Capybara |

### External Services

| Service | Purpose | Migration Impact |
|---------|---------|-----------------|
| **Supabase** (PostgreSQL) | Cloud database + Auth | Replace with SQLite + OmniAuth |
| **Google Gemini API** | LLM (live voice + async text) | Keep (API calls from Rails) |
| **OntologyRAG (Project_E)** | Memory/Profile/Graph | Keep (API calls from Rails) |
| **Tavily** | Web search | Keep (API calls from Rails) |
| **Brave Search** | Alternative web search | Keep (optional) |
| **Sentry** | Error monitoring | Replace with Sentry Ruby |

---

## 8. Code Complexity Assessment

### Complexity by Component

| Component | Lines | Complexity | Migration Difficulty |
|-----------|-------|------------|---------------------|
| VoiceChatManager.kt | ~1,322 | **Very High** | High - Core orchestrator |
| OntologyRAGModels.kt | ~1,198 | **High** | Medium - Data models |
| contextOrchestrator.ts | ~288 | **Medium** | Medium - Context assembly |
| phaseTransitionService.ts | ~298 | **Medium** | Low - Pure logic |
| emotionEnergyService.ts | ~348 | **Medium** | Low - Pure math/logic |
| narrowingService.ts | ~343 | **Medium** | Low - Pure logic |
| AuthManager.kt | ~445 | **Medium** | Low - OmniAuth simplifies |
| OntologyRAGConstants.kt | ~394 | **Low** | Low - Constants mapping |
| OntologyRAGClient.kt | ~298 | **Medium** | Low - Faraday equivalent |
| types.ts | ~486 | **Low** | Low - Type definitions |
| constants.ts | ~572 | **Low** | Low - Constants mapping |

### Duplication Analysis

**Significant duplication** exists between TypeScript and Kotlin layers:

| Feature | TypeScript File | Kotlin File | Overlap |
|---------|----------------|-------------|---------|
| Phase transitions | phaseTransitionService.ts | VoiceChatPhase.kt + handlers | ~80% |
| Emotion/Energy | emotionEnergyService.ts | VoiceChatSentimentIntegrator | ~70% |
| Context orchestration | contextOrchestrator.ts | context/ package (5+ files) | ~60% |
| Narrowing | narrowingService.ts | (in phase handlers) | ~50% |
| OntologyRAG models | types.ts | OntologyRAGModels.kt | ~90% |
| Constants | constants.ts | OntologyRAGConstants.kt + ContextConfig.kt | ~80% |

**Migration Benefit**: Rails consolidation eliminates this duplication entirely.

### Technical Debt Indicators

1. **Context layer mismatch**: TS uses 7 layers (32K char), Kotlin uses 5 layers (100K tokens) - different models for the same concept
2. **Hardcoded Korean strings**: Many prompt templates contain hardcoded Korean text (should be extracted to locale files)
3. **Manual JWT parsing**: AuthManager.kt uses regex for JWT parsing instead of a proper JWT library
4. **Mixed responsibility**: VoiceChatManager.kt (~1322 lines) handles too many concerns - audio, AI, state, persistence
5. **Test coverage gap**: ~60 Kotlin test files vs ~5 TypeScript test files - TS layer significantly under-tested

### Cyclomatic Complexity Hot Spots

1. `VoiceChatManager.kt` - Multiple coroutine scopes, state flows, callback chains
2. `evaluateTransition()` - 6 rule evaluators with complex condition logic
3. `enforceTokenBudget()` - Multi-step priority-based pruning
4. `getGoogleSubWithFallback()` - 3-tier fallback with nested map access
5. `assembleSystemInstruction()` - 7-layer template assembly with conditional includes

---

## 9. Data Flow

### Session Lifecycle Flow

```
Session Start
│
├── 1. Google OAuth → get google_sub
├── 2. OntologyRAG: GET /incar/profile/{google_sub}
│   └── Returns: E/N/G/C profile, keywords
├── 3. Assemble Context Layers:
│   ├── Layer 1: Profile (from step 2)
│   ├── Layer 2: Summary (keyword search in Supabase)
│   ├── Layer 3: RAG (OntologyRAG hybrid search)
│   ├── Layer 4: Empty (current session)
│   ├── Layer 5: Web search (Tavily, if applicable)
│   ├── Layer 6: AI Persona (system prompt)
│   └── Layer 7: Sentiment (null initially)
├── 4. Start Gemini Live API connection
├── 5. Bot speaks opening question (INPUT phase)
│
During Session (loop)
│
├── User speaks (audio)
│   ├── WebRTC → VAD → Gemini Live API (real-time STT)
│   ├── Sentiment Analysis → update Layer 7
│   ├── Phase Transition Engine → evaluate rules
│   ├── Narrowing Service → question type selection
│   ├── Emotion/Energy Tracker → update state
│   ├── Graph Entity Extraction (debounced 2s)
│   └── Context Budget Enforcement → prune if needed
│
├── Bot responds
│   ├── Gemini generates response (with assembled context)
│   ├── Text-to-Speech → audio output
│   └── Layer 4 updated with conversation turn
│
├── Depth Layer Trigger (if conditions met)
│   ├── Q1: WHY → uncover emotions
│   ├── Q2: DECISION → crystallize problem
│   ├── Q3: IMPACT → multi-dimensional analysis
│   └── Q4: DATA → information needs
│
├── Insight Generation (if DEPTH complete)
│   └── situation + data + decision + actionGuide → natural speech
│
Session End
│
├── 6. Conversation Save:
│   └── POST /incar/conversations/{session_id}/save
│       Body: { transcript, metadata (weather, GPS), sentiment_summary }
│       Returns: auto-extracted E/N/G/C events, keywords
│
├── 7. Graph Entity Batch Save:
│   └── POST /incar/events/batch
│       Body: { events: [{ category: emotion|need|goal|constraint, content }] }
│
├── 8. Summary Generation:
│   └── Gemini async → conversation summary + keywords
│       Stored in Supabase conversation_summaries table
│
└── 9. Cleanup:
    ├── Close Gemini Live API connection
    ├── Stop audio pipeline
    └── Reset phase state
```

### Data Storage Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    Supabase (Cloud)                        │
│                                                            │
│  ┌───────────────────┐  ┌───────────────────────────┐    │
│  │ Auth              │  │ PostgreSQL Tables          │    │
│  │ - Users           │  │ - conversations            │    │
│  │ - Sessions        │  │ - conversation_turns       │    │
│  │ - JWT tokens      │  │ - conversation_summaries   │    │
│  └───────────────────┘  │ - conversation_keywords    │    │
│                          │ - voice_chat_data          │    │
│                          │ - session_states           │    │
│                          │ - web_search_cache         │    │
│                          └───────────────────────────┘    │
└──────────────────────────────────────────────────────────┘
                    │
                    │ (API calls)
                    v
┌──────────────────────────────────────────────────────────┐
│              OntologyRAG / Project_E (Remote)              │
│                                                            │
│  ┌───────────────────┐  ┌───────────────────────────┐    │
│  │ PostgreSQL+pgvector│  │ Neo4j Graph DB            │    │
│  │ - documents       │  │ - User nodes              │    │
│  │ - embeddings      │  │ - Decision nodes          │    │
│  │ - events (E/N/G/C)│  │ - Person nodes            │    │
│  │ - memories        │  │ - Pattern nodes           │    │
│  │ - profiles        │  │ - Relations (7 types)     │    │
│  └───────────────────┘  └───────────────────────────┘    │
└──────────────────────────────────────────────────────────┘
```

### Rails Migration Data Flow Change

```
Current (Project_B):
  Android App → Supabase (cloud PostgreSQL) + OntologyRAG API

Target (Project_A):
  Hotwire Native App → Rails Server → SQLite (local) + OntologyRAG API
```

**Key Change**: Supabase is replaced by SQLite (Rails default). All tables currently in Supabase move to Rails migrations. Authentication moves from Supabase Auth to OmniAuth.

---

## 10. What's Reusable

### Directly Reusable (Logic Portable)

These components contain **pure business logic** with no framework dependency, making them directly translatable to Ruby:

| Component | Source File | Reuse Level | Notes |
|-----------|------------|-------------|-------|
| Phase transition rules | `phaseTransitionService.ts` | **95%** | Pure logic, direct translation |
| Emotion/Energy calculations | `emotionEnergyService.ts` | **95%** | Pure math, direct translation |
| Narrowing service | `narrowingService.ts` | **90%** | Pure logic, Korean text templates need locale extraction |
| Context layer assembly | `contextOrchestrator.ts` | **85%** | Logic reusable, template system changes |
| Sentiment prompt engineering | `sentimentAnalysisGemini.ts` | **80%** | Prompt text reusable, API wrapper changes |
| OntologyRAG API constants | `OntologyRAGConstants.kt` | **100%** | Direct mapping to Ruby constants |
| E/N/G/C data models | `OntologyRAGModels.kt` | **90%** | Data structures translate directly |
| Type definitions | `types.ts` | **85%** | Useful as Ruby model/type reference |
| All constants | `constants.ts` | **100%** | Direct mapping to Ruby constants module |

### Partially Reusable (Needs Adaptation)

| Component | Source File | Reuse Level | Adaptation Needed |
|-----------|------------|-------------|-------------------|
| VoiceChatManager orchestration | `VoiceChatManager.kt` | **50%** | Extract business logic from Android-specific code |
| OntologyRAG HTTP client | `OntologyRAGClient.kt` | **60%** | Replace OkHttp with Faraday, keep retry/timeout logic |
| Context budget enforcement | `enforceTokenBudget()` | **80%** | Unify TS 7-layer and Kotlin 5-layer models |
| Auth google_sub extraction | `AuthManager.kt` | **20%** | OmniAuth replaces most complexity |
| Two-level cache | `data/depth/cache/` | **40%** | Rails.cache replaces custom implementation |
| Insight generation | `Insight.kt` | **70%** | Domain model reusable, generation logic needs LLM integration |
| DEPTH exploration | `DepthExploration.kt` | **75%** | Domain model and rules reusable |

### Not Reusable (Platform-Specific)

| Component | Reason |
|-----------|--------|
| WebRTC audio pipeline | Android-specific; Hotwire Native handles differently |
| WebView bridge | Eliminated by Hotwire Native |
| Koin DI modules | Rails has native autoloading |
| Room database | Replaced by ActiveRecord |
| Compose UI | Replaced by Turbo + Stimulus |
| React components | Replaced by Rails views + Turbo Frames |
| Supabase client | Replaced by ActiveRecord |
| React hooks | Replaced by Stimulus controllers |
| BFF Edge Functions | Rails controllers replace BFF |

### Reusable Artifacts (Non-Code)

| Artifact | Location | Reuse |
|----------|----------|-------|
| System prompt templates | `constants.ts` (VOICE_CHAT_ENGINE_SYSTEM_PROMPT) | **100%** - Copy directly |
| Sentiment analysis prompt | `sentimentAnalysisGemini.ts` | **100%** - Copy prompt text |
| Korean emotion keywords | Throughout services | **100%** - Extract to locale file |
| Phase transition thresholds | `PHASE_TRANSITION_CONFIG` | **100%** - Copy values |
| Session state config | `SESSION_STATE_CONFIG` | **100%** - Copy values |
| OntologyRAG endpoint map | `OntologyRAGConstants.kt` | **100%** - Copy to Ruby constants |
| Graph relation types | `GraphRelationTypes` | **100%** - Copy values |

---

## 11. Summary Assessment

### Project_B Profile

| Metric | Assessment |
|--------|------------|
| **Total Codebase Size** | ~140+ source files (Kotlin + TypeScript) |
| **Business Logic Files** | ~30 core files containing reusable logic |
| **Architecture Complexity** | High - dual-layer hybrid with significant duplication |
| **OntologyRAG Integration Depth** | Deep - 40+ API endpoints across 6 categories |
| **Testing Maturity** | Medium (Kotlin: ~60 test files, TypeScript: ~5 test files) |
| **Technical Debt** | Medium-High (layer duplication, context model mismatch, hardcoded Korean) |
| **Code Quality** | Good (consistent patterns, documented, error handling) |

### Migration Effort Estimate

| Phase | Scope | Estimated Complexity |
|-------|-------|---------------------|
| 1. Core Models | User, Session, Message, VoiceChatData, DepthExploration, Insight | Low |
| 2. OntologyRAG Client | Faraday-based HTTP client + all endpoint methods | Medium |
| 3. Auth | OmniAuth Google OAuth + google_sub | Low |
| 4. Context Orchestrator | Unified layer model + budget enforcement | Medium |
| 5. Phase Transition Engine | State machine + transition rules | Low-Medium |
| 6. Emotion/Energy System | Pure logic translation | Low |
| 7. Narrowing Service | Logic translation + Korean prompt templates | Low |
| 8. Sentiment Analysis | Gemini API integration from Rails | Medium |
| 9. DEPTH Layer | Q1-Q4 + signal detection + impact analysis | Medium-High |
| 10. Insight Generation | LLM-based generation + natural speech | Medium |
| 11. Voice Chat (Action Cable) | WebSocket real-time + Gemini Live API | High |
| 12. UI (Turbo + Stimulus) | All views + interactive components | Medium-High |
| 13. Background Jobs | E/N/G/C batch + conversation save | Low |

### Key Migration Risks

1. **Audio/Voice Pipeline**: The most complex part (WebRTC, VAD, barge-in) is platform-specific. Hotwire Native will need its own audio handling strategy.
2. **Real-time Communication**: VoiceChatManager uses Gemini Live API with streaming audio. Action Cable can handle WebSocket, but the audio pipeline integration needs careful design.
3. **Context Model Unification**: Two different context models (7-layer/32K char vs 5-layer/100K tokens) need consolidation into one Rails model.
4. **Supabase to SQLite**: All Supabase tables need Rails migration scripts. Edge Functions need to become Rails controllers.
5. **Korean Language**: Many prompts and templates contain Korean text that should be properly extracted to i18n locale files.

### Key Migration Advantages

1. **Elimination of Duplication**: The dual TypeScript/Kotlin layer collapses into a single Ruby codebase.
2. **Simplified Auth**: OmniAuth directly provides google_sub, replacing the complex 3-tier fallback.
3. **Convention over Configuration**: Rails conventions replace Koin DI, manual routing, and explicit dependency management.
4. **SQLite Simplification**: No cloud database dependency for core data (Supabase eliminated).
5. **Pure Business Logic Reuse**: ~95% of phase transition, emotion/energy, and narrowing logic is directly translatable.
6. **Unified Context Model**: Opportunity to design a clean, consolidated context layer architecture.

---

*End of Project_B Technical Analysis*
