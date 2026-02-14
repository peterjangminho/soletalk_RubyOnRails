# Project_E (OntologyRAG) API Surface Analysis

**Date**: 2026-02-12
**Purpose**: Comprehensive API analysis for Project_A (Rails) integration
**Source**: `/Users/peter/Project/Project_E/src/ontology_rag/`
**Base URL**: `https://ontologyrag01-production.up.railway.app`

---

## 1. Authentication

### API Key Middleware

All requests (except excluded paths) require authentication via the `X-API-Key` header.

**Header**: `X-API-Key`
**Format**: Prefixed with `sk_` (32 characters)
**Rate Limit**: 1000 requests/hour (per API key)

**Authentication Flow**:
1. Client sends `X-API-Key` header
2. Middleware checks for master API key (env `MASTER_API_KEY`) -- bypasses DB auth
3. Otherwise, validates against Supabase `api_keys` table (hashed comparison)
4. Checks rate limit (1000 req/hour per key)
5. Logs request to `api_audit_log`

**Excluded Paths** (no auth required):
- `/health`, `/health/ready`, `/health/live`, `/health/metrics`, `/health/db`, `/health/spicedb`, `/health/detailed`
- `/docs`, `/openapi.json`, `/redoc`
- `/metrics`
- `/admin/sync`, `/admin/analytics/*`
- `/spicedb/health`

**Error Responses**:
- `401`: `{"detail": "API Key is required. Include X-API-Key header."}`
- `401`: `{"detail": "Invalid or expired API Key"}`
- `429`: `{"detail": "Rate limit exceeded. Try again in {minutes} minutes."}`

### For Rails Client

```ruby
# Required headers for every API call
headers = {
  "X-API-Key" => ENV['ONTOLOGY_RAG_API_KEY'],  # e.g., "sk_master_xxx"
  "X-Source-App" => "soletalk-rails",
  "X-Request-ID" => "soletalk-#{Time.now.to_i}",
  "Content-Type" => "application/json"
}
```

**Note**: `X-Source-App` and `X-Request-ID` are custom headers for tracking -- not enforced by middleware but recommended for audit trail.

---

## 2. API Endpoints -- Complete Reference

### 2.1 User Identification (`/engine/users`)

#### POST `/engine/users/identify`

Identify or register a user. Creates mapping if new, returns existing if found.

**Request**:
```json
{
  "google_sub": "string (required, 1-255 chars)",
  "app_source": "string (required, 1-50 chars)",
  "external_user_id": "string (optional, max 255 chars)"
}
```

**Valid `app_source` values**: `"ontology_rag"`, `"incar_companion"`, `"sook_intel"`

For Project_A (SoleTalk Rails), use `"incar_companion"` to maintain compatibility with Project_B, or define a new source like `"soletalk_rails"`.

**Response** (200):
```json
{
  "id": "uuid-string",
  "google_sub": "string",
  "app_source": "string",
  "external_user_id": "string | null",
  "is_new": true
}
```

**Errors**: `500` on failure

#### GET `/engine/users/{google_sub}/data`

Get cross-app data (objects + events) for a user.

**Query Params**: `limit` (1-1000, default 100), `offset` (0+, default 0)

**Response** (200):
```json
{
  "google_sub": "string",
  "objects": [
    {"id": "string", "domain": "string", "type": "string", "properties": {}, "source_app": "string"}
  ],
  "events": [
    {"id": "string", "event_type": "string", "engc_category": "string", "source_app": "string", "timestamp": "iso8601"}
  ],
  "total_objects": 0,
  "total_events": 0
}
```

#### GET `/engine/users/{google_sub}/apps`

Get connected apps for a user.

**Response** (200):
```json
{
  "google_sub": "string",
  "connected_apps": ["incar_companion", "ontology_rag"]
}
```

---

### 2.2 E/N/G/C Prompts (`/engine/prompts`)

#### GET `/engine/prompts/{google_sub}`

Get aggregated E/N/G/C profile for a user. This is the primary endpoint for the DEPTH Layer's 4 Core Questions context.

**Path Params**: `google_sub` (string)
**Query Params**: `limit` (1-200, default 50) -- max events to process

**Response** (200):
```json
{
  "google_sub": "string",
  "emotion_patterns": [
    {
      "emotion_type": "anxiety",
      "count": 5,
      "avg_intensity": 0.72,
      "recent_occurrence": "2026-02-12T10:00:00Z"
    }
  ],
  "needs": {
    "category": "need",
    "items": [
      {"id": "uuid", "timestamp": "iso8601", "text": "string", "description": "string"}
    ],
    "total_count": 3
  },
  "goals": {
    "category": "goal",
    "items": [...],
    "total_count": 2
  },
  "constraints": {
    "category": "constraint",
    "items": [...],
    "total_count": 1
  },
  "recent_events": [
    {"id": "uuid", "event_type": "string", "engc_category": "emotion", "emotion_type": "anxiety", "timestamp": "iso8601"}
  ],
  "generated_at": "2026-02-12T10:00:00Z"
}
```

**Errors**: `500` on failure

**CRITICAL NOTE for Project_A**: The `emotion_patterns` field aggregates emotions by type with counts and average intensities. The `needs`, `goals`, and `constraints` fields each contain `items` arrays extracted from event data.

---

### 2.3 Hybrid Search / RAG Query (`/engine/query`)

#### POST `/engine/query`

Execute RAG query with optional permission-scoped filtering.

**Request**:
```json
{
  "question": "string (required, 1-10000 chars)",
  "query": "string (optional, alias for question -- backward compat)",
  "google_sub": "string (optional, for permission-scoped search)",
  "container_id": "string (optional, filter to specific container)",
  "limit": 5,
  "stream": false
}
```

**Note**: If `query` is provided but not `question`, `query` is used as `question` (backward compatibility).

**Response** (200):
```json
{
  "answer": "string",
  "context": "string",
  "sources": [
    {"id": "string | null", "score": 0.95, "content": "string | null"}
  ],
  "query": "string | null"
}
```

**Streaming**: If `stream: true`, returns `text/event-stream` with SSE format:
```
data: {chunk}\n\n
data: [DONE]\n\n
```

---

### 2.4 InCar Companion Integration (`/incar`)

These are the primary endpoints for Project_A/Project_B integration.

#### POST `/incar/conversations/{session_id}/save`

Save a conversation session to OntologyRAG (transcript processing + entity extraction).

**Path Params**: `session_id` (string)

**Request**:
```json
{
  "google_sub": "string (required)",
  "transcript": "string (required)",
  "metadata": {}
}
```

**Response** (200):
```json
{
  "status": "saved",
  "session_id": "string",
  "object_id": "string | null"
}
```

**Side Effects**:
- Processes transcript into Object + Document entities
- Sets SpiceDB conversation owner permission
- Source app is automatically set to `"incar"`

**Errors**: `500` on failure

#### POST `/incar/events/batch`

Batch store E/N/G/C events and update user profile aggregation.

**Request**:
```json
{
  "google_sub": "string (required, min 1 char)",
  "events": [
    {
      "engc_category": "emotion",
      "emotion_type": "anxiety",
      "emotion_intensity": 0.8,
      "data": {"text": "Feeling anxious about the meeting"}
    },
    {
      "engc_category": "need",
      "data": {"text": "Need for recognition at work"}
    }
  ]
}
```

**Max events per batch**: 100

**Response** (200):
```json
{
  "success": true,
  "events_stored": 2,
  "profile_updated": true,
  "message": "Successfully stored 2 events"
}
```

**Side Effects**:
- Stores events with `google_sub` and `source_app: "incar"` to events table
- Updates `user_profiles` aggregation table (E/N/G/C summaries)

**Errors**: `400` if batch exceeds 100 events, `500` on failure

#### POST `/incar/memories/store`

Store a memory to OntologyRAG (Layer 1-4 memory architecture).

**Request**:
```json
{
  "google_sub": "string (required)",
  "layer": 1,
  "content": "string (required)",
  "memory_type": "preference",
  "metadata": {}
}
```

**Layer values**: 1 (Profile), 2 (Past memory), 3 (Current session -- SKIPPED, local only), 4 (Additional info)

**Response** (200):
```json
{
  "status": "stored",
  "layer": 1,
  "memory_id": "uuid | null"
}
```

Layer 3 returns: `{"status": "skipped", "reason": "Layer 3 is local-only", "layer": 3}`

#### GET `/incar/memories/recall`

Recall memories using hybrid (vector + graph) search.

**Query Params**:
- `query` (required): search query
- `google_sub` (required): user identifier
- `layers` (default "1,2,4"): comma-separated layer numbers
- `limit` (default 10, max 50)

**Response** (200):
```json
{
  "memories": [
    {"id": "string", "content": "string", "score": 0.85, "layer": 1, "memory_type": "preference"}
  ],
  "total_count": 3
}
```

#### GET `/incar/profile/{google_sub}`

Get user profile with E/N/G/C summaries (cached aggregation from `user_profiles` table).

**Response** (200):
```json
{
  "google_sub": "string",
  "emotions": ["anxiety", "frustration"],
  "needs": ["recognition"],
  "goals": ["career change"],
  "constraints": ["time", "budget"],
  "emotions_summary": [
    {"value": "anxiety", "intensity": 0.8, "count": 5, "last_seen": "iso8601"}
  ],
  "needs_summary": [...],
  "goals_summary": [...],
  "constraints_summary": [...],
  "total_events_count": 25
}
```

**Note**: The `emotions`, `needs`, `goals`, `constraints` fields are legacy simple string arrays (backward compat). The `*_summary` fields are the new detailed aggregation with intensity/count/last_seen.

---

### 2.5 E/N/G/C Events (`/engine/events/engc`)

#### POST `/engine/events/engc`

Create a single E/N/G/C event.

**Request**:
```json
{
  "google_sub": "string (required, 1-255 chars)",
  "object_id": "string (required, 1-255 chars)",
  "engc_category": "emotion | need | goal | constraint",
  "emotion_type": "string (optional, for EMOTION category)",
  "emotion_intensity": 0.8,
  "source_app": "string (optional, max 50 chars)",
  "data": {}
}
```

**Valid `engc_category` values**: `"emotion"`, `"need"`, `"goal"`, `"constraint"`

**Valid `emotion_type` values** (for category "emotion"):
- Primary: `"joy"`, `"sadness"`, `"anger"`, `"fear"`, `"surprise"`, `"disgust"`
- Secondary: `"excitement"`, `"frustration"`, `"anxiety"`, `"satisfaction"`, `"boredom"`, `"curiosity"`

**Response** (201):
```json
{
  "id": "uuid",
  "google_sub": "string",
  "object_id": "string",
  "engc_category": "emotion",
  "emotion_type": "anxiety",
  "emotion_intensity": 0.8,
  "source_app": "incar",
  "data": {},
  "timestamp": "iso8601"
}
```

**Errors**: `400` for invalid category/emotion_type/data size, `500` on failure

#### GET `/engine/events/engc`

Query E/N/G/C events with filters.

**Query Params**:
- `google_sub` (optional)
- `engc_category` (optional): "emotion", "need", "goal", "constraint"
- `emotion_type` (optional)
- `source_app` (optional)
- `limit` (1-1000, default 100)
- `offset` (0+, default 0)

**Response** (200):
```json
{
  "events": [
    {
      "id": "uuid", "object_id": "uuid", "event_type": "engc_emotion",
      "engc_category": "emotion", "emotion_type": "anxiety",
      "emotion_intensity": 0.8, "source_app": "incar",
      "timestamp": "iso8601"
    }
  ],
  "total": 5,
  "filters": {"engc_category": "emotion", "google_sub": "..."}
}
```

---

### 2.6 Conversations (`/engine/conversations`)

#### POST `/engine/conversations`

Save conversation transcript with entity extraction.

**Request**:
```json
{
  "transcript": "string (required, 1-100000 chars)",
  "google_sub": "string (required, 1-255 chars)",
  "session_id": "string (required, 1-100 chars)",
  "source_app": "string (optional, max 50 chars)",
  "append": false
}
```

**Response** (201):
```json
{
  "session_id": "string",
  "document_id": "uuid | null",
  "entities_extracted": 3,
  "relations_extracted": 1,
  "appended": false,
  "created_at": "iso8601Z"
}
```

#### GET `/engine/conversations/{session_id}`

Get conversation by session ID.

**Response** (200):
```json
{
  "session_id": "string",
  "document_id": "uuid",
  "content": "string",
  "metadata": {},
  "created_at": "iso8601Z"
}
```

**Errors**: `404` if session not found

#### GET `/engine/conversations`

List conversations for a user.

**Query Params**: `google_sub` (required, 1-255), `limit` (1-100, default 20)

**Response** (200):
```json
[
  {
    "session_id": "string",
    "document_id": "uuid",
    "preview": "First 100 chars of transcript...",
    "created_at": "iso8601Z"
  }
]
```

---

### 2.7 VoiceChat (`/engine/voicechat`)

#### POST `/engine/voicechat`

Main VoiceChat endpoint -- routes by phase.

**Request**:
```json
{
  "google_sub": "string (required)",
  "phase": "surface | depth | insight",
  "query": "string (required for surface/depth)",
  "question_type": "Q1_WHY | Q2_WHAT | Q3_WEIGHT | Q4_REALITY (optional, for depth)",
  "q_results": {"q1": "...", "q2": "...", "q3": {}, "q4": {}}
}
```

**Response** (200):
```json
{
  "phase": "surface",
  "context": {
    "emotional_patterns": "string (for surface)",
    "context": "string (for depth)",
    "question_type": "Q1_WHY (for depth)",
    "action_suggestions": "string (for insight)",
    "synthesis": {}
  },
  "sources": [{"id": "string", "score": 0.9, "content": "string"}],
  "query": "string",
  "latency_ms": 123.45
}
```

**Errors**: `422` for missing required fields per phase, `500` on failure

#### POST `/engine/voicechat/surface`

Surface layer (emotional context) endpoint.

**Request**: `{"google_sub": "string", "query": "string"}`

#### POST `/engine/voicechat/depth`

Depth layer (Q1-Q4 exploration) endpoint.

**Request**: `{"google_sub": "string", "query": "string", "question_type": "Q1_WHY"}`

#### POST `/engine/voicechat/insight`

Insight layer (action suggestions) endpoint.

**Request**: `{"google_sub": "string", "q_results": {"q1": "", "q2": "", "q3": {}, "q4": {}}}`

---

### 2.8 Insights (`/engine/insights`)

#### POST `/engine/insights`

Generate insight from E/N/G/C profile.

**Request**:
```json
{
  "google_sub": "string (required)",
  "external_info": {"key": "value"}
}
```

**Response** (201):
```json
{
  "id": "uuid",
  "google_sub": "string",
  "content": "Situation analysis text",
  "action_guide": "Structured action guidance",
  "confidence_score": 0.85,
  "source_questions": ["Q1 answer", "Q2 answer"],
  "external_info": {},
  "status": "active",
  "expires_at": null,
  "created_at": "iso8601",
  "updated_at": null
}
```

#### GET `/engine/insights`

List user insights.

**Query Params**: `google_sub` (required), `limit` (1-200, default 50), `offset` (0+, default 0)

**Response** (200): `{"insights": [InsightResponse], "total": int}`

#### GET `/engine/insights/{insight_id}`

Get insight by ID.

**Errors**: `404` if not found

#### POST `/engine/insights/search`

Search similar insights by vector similarity.

**Request**:
```json
{
  "query": "string (required)",
  "google_sub": "string (optional)",
  "limit": 10,
  "threshold": 0.7
}
```

**Response** (200):
```json
{
  "results": [
    {"insight": {...InsightResponse}, "similarity_score": 0.89}
  ],
  "total": 3
}
```

#### DELETE `/engine/insights/{insight_id}`

Delete an insight.

**Response** (200): `{"message": "Insight deleted", "id": "uuid"}`
**Errors**: `404` if not found

---

### 2.9 Similarity Search (`/engine/search`)

#### POST `/engine/search/similar`

Search for similar content using vector similarity.

**Request**:
```json
{
  "query": "string (required)",
  "limit": 10,
  "filters": {},
  "container_id": "string (optional)",
  "container_ids": ["string (optional, array for multi-container)"],
  "google_sub": "string (optional)"
}
```

**Response** (200):
```json
{
  "results": [
    {"id": "string", "score": 0.95, "metadata": {}, "container_id": "string | null"}
  ],
  "query": "string",
  "total": 5
}
```

---

### 2.10 Objects CRUD (`/engine/objects`)

#### POST `/engine/objects`
Create object. Request: `{domain, type, properties?, id?, google_sub?}`. Response: 201 with `{id, domain, type, properties, google_sub}`.

#### GET `/engine/objects/{object_id}`
Get object by ID. Response: 200 or 404.

#### GET `/engine/objects`
List objects. Query params: `domain?`, `type?`, `google_sub?`.

#### DELETE `/engine/objects/{object_id}`
Delete object. Response: 204 or 404.

---

### 2.11 Relations CRUD (`/engine/relations`)

#### POST `/engine/relations`
Create relation. Request: `{source_id, target_id, relation_type, properties?}`. Response: 201.

#### GET `/engine/relations`
List relations. Query params: `source_id?`, `target_id?`, `relation_type?`.

---

### 2.12 Events CRUD (`/engine/events`)

#### POST `/engine/events`
Create event. Request: `{object_id, event_type, data?, google_sub?}`. Response: 201.

#### GET `/engine/events`
Get events for object. Query params: `object_id` (required), `event_type?`, `google_sub?`.

---

### 2.13 Documents (`/engine/documents`)

#### POST `/engine/documents`
Create document with automatic embedding and chunking.

**Request**:
```json
{
  "object_id": "string (legacy workflow)",
  "google_sub": "string (container workflow)",
  "container_id": "string (container workflow)",
  "content": "string (required)",
  "metadata": {},
  "auto_chunk": true
}
```

Must provide either `object_id` OR both `google_sub` + `container_id`.

**Response** (201):
```json
{
  "documents": [{"id": "uuid", "object_id": "uuid", "content": "string", "metadata": {}}],
  "vectors": [{"id": "uuid", "document_id": "uuid", "model_name": "string"}],
  "total_chunks": 3
}
```

#### GET `/engine/documents`
List documents. Query params: `google_sub?`, `container_id?`, `page` (default 1), `limit` (1-100, default 20).

---

### 2.14 Health Checks (`/health`)

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Basic health check (`{"status": "healthy", "version": "0.1.0", "service": "ontology-rag"}`) |
| `/health/ready` | GET | Readiness check (all components) |
| `/health/live` | GET | Liveness probe (`{"status": "alive"}`) |
| `/health/metrics` | GET | System metrics (request counts, error rates) |
| `/health/db` | GET | Database connectivity (Postgres, Neo4j) |
| `/health/detailed` | GET | Comprehensive health with all dependencies and uptime |
| `/health/spicedb` | GET | SpiceDB connection health |

---

### 2.15 API Key Management (`/auth`)

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/auth/api-keys` | POST | Create new API key (returns plaintext once) |
| `/auth/api-keys` | GET | List all API keys (without plaintext) |
| `/auth/api-keys/{key_id}` | DELETE | Delete API key |
| `/auth/api-keys/{key_id}/rotate` | POST | Rotate API key |

---

## 3. Core Data Models

### 3.1 UserIdentityMapping

```
id: UUID string
google_sub: string (Google OAuth Subject Identifier)
app_source: string ("ontology_rag" | "incar_companion" | "sook_intel")
external_user_id: string (app-specific user ID)
created_at: datetime
updated_at: datetime | null
```

### 3.2 E/N/G/C Category (ENGCCategory)

```
Values: "emotion", "need", "goal", "constraint"
```

**CRITICAL**: Parameter names are SINGULAR (`emotion`, `need`, `goal`, `constraint`), NOT plural.

### 3.3 EmotionType

Primary: `joy`, `sadness`, `anger`, `fear`, `surprise`, `disgust`
Secondary: `excitement`, `frustration`, `anxiety`, `satisfaction`, `boredom`, `curiosity`

### 3.4 Event Model

```
id: UUID string
object_id: UUID string
event_type: string
data: dict
timestamp: datetime
google_sub: string | null
source_app: string | null
engc_category: string | null ("emotion" | "need" | "goal" | "constraint")
emotion_type: string | null
emotion_intensity: float | null (0.0 - 1.0)
sync_status: "pending" | "synced" | "failed"
```

### 3.5 UserProfile (E/N/G/C Aggregation)

```
id: UUID string
google_sub: string
emotions_summary: [{"value": str, "intensity": float, "count": int, "last_seen": datetime}]
needs_summary: [{"value": str, "intensity": float, "count": int, "last_seen": datetime}]
goals_summary: [{"value": str, "intensity": float, "count": int, "last_seen": datetime}]
constraints_summary: [{"value": str, "intensity": float, "count": int, "last_seen": datetime}]
total_events_count: int
last_event_at: datetime | null
created_at: datetime
updated_at: datetime | null
```

### 3.6 Insight Model

```
id: UUID string
google_sub: string
content: string (situation analysis)
action_guide: string | null
confidence_score: float (0.0-1.0)
source_questions: [string]
external_info: dict
embedding: [float] | null (1536-dim vector)
status: "active" | "archived" | "deleted"
expires_at: datetime | null
created_at: datetime
updated_at: datetime | null
```

### 3.7 Object Model

```
id: UUID string
domain: string
type: string
properties: dict
google_sub: string | null
app_user_id: string | null
container_id: string | null
source_app: string | null
sync_status: "pending" | "synced" | "failed"
created_at: datetime
updated_at: datetime | null
```

### 3.8 VoiceChat Phase Enum

```
Values: "surface", "depth", "insight"
```

### 3.9 QuestionType Enum (Depth Layer)

```
Values: "Q1_WHY", "Q2_WHAT", "Q3_WEIGHT", "Q4_REALITY"
```

---

## 4. Key Business Logic Flows

### 4.1 User Identification Flow

```
Client -> POST /engine/users/identify
  {google_sub, app_source: "incar_companion", external_user_id?}
  |
  v
  Find existing mapping by (google_sub, app_source)
  |
  +-> Found: Return existing mapping (is_new: false)
  |
  +-> Not found: Create new UserIdentityMapping
      external_user_id defaults to google_sub if not provided
      Return new mapping (is_new: true)
```

### 4.2 E/N/G/C Profile Retrieval Flow

```
Client -> GET /engine/prompts/{google_sub}?limit=50
  |
  v
  PromptsService.get_engc_profile()
  |
  +-> Fetch events by google_sub (up to limit)
  +-> Aggregate emotions by type (count, avg_intensity, recent_occurrence)
  +-> Aggregate needs/goals/constraints by category
  +-> Sort recent events by timestamp desc
  +-> Return ENGCProfileResponse
```

### 4.3 Hybrid Search (RAG Query) Flow

```
Client -> POST /engine/query
  {question, google_sub?, container_id?, limit, stream}
  |
  v
  If google_sub provided:
    SpiceDB lookup -> get accessible_container_ids
    If container_id specified: verify access
  |
  v
  engine.query(question) -> RAG pipeline
    1. Embed question (vector)
    2. Search similar documents (pgvector)
    3. Optionally: Graph traversal (Neo4j)
    4. Merge & rerank context
    5. LLM generates answer with context
  |
  v
  Filter sources by accessible containers
  Return {answer, context, sources}
```

### 4.4 Events Batch Flow

```
Client -> POST /incar/events/batch
  {google_sub, events: [{engc_category, emotion_type?, emotion_intensity?, data}]}
  |
  v
  Validate batch size (<= 100)
  |
  v
  For each event:
    Add google_sub + source_app: "incar"
    Store to events table via event_repo.create_from_dict()
  |
  v
  Update user profile aggregation:
    profile_repo.update_engc_summary(google_sub, events)
  |
  v
  Return {success, events_stored, profile_updated}
```

### 4.5 Conversation Save Flow

```
Client -> POST /incar/conversations/{session_id}/save
  {google_sub, transcript, metadata}
  |
  v
  engine.process_transcript(session_id, transcript, google_sub, metadata)
    1. Create Conversation Object
    2. Create Document with transcript content
    3. Extract entities and relations
    4. Generate embeddings
  |
  v
  SpiceDB: Grant conversation owner permission
  |
  v
  Return {status: "saved", session_id, object_id}
```

### 4.6 VoiceChat 3-Layer Flow

```
SURFACE PHASE:
  POST /engine/voicechat {phase: "surface", query, google_sub}
  -> VoiceChatRAGService.get_surface_context(user_message, google_sub)
  -> Returns: emotional_patterns (past emotion patterns from RAG search)

DEPTH PHASE:
  POST /engine/voicechat {phase: "depth", query, google_sub, question_type: "Q1_WHY"}
  -> VoiceChatRAGService.get_depth_context(question_type, user_message, google_sub)
  -> Returns: context (relevant past conversations/decisions for Q1-Q4)

INSIGHT PHASE:
  POST /engine/voicechat {phase: "insight", google_sub, q_results: {q1, q2, q3, q4}}
  -> VoiceChatRAGService.get_insight_context(q1_result, q2_result, q3_result, q4_result, google_sub)
  -> Returns: action_suggestions, synthesis (personalized guidance)
```

---

## 5. Integration Patterns for Rails Client

### 5.1 Recommended Request Headers

```ruby
module OntologyRag
  HEADERS = {
    "X-API-Key" => ENV["ONTOLOGY_RAG_API_KEY"],
    "Content-Type" => "application/json",
    "X-Source-App" => "soletalk-rails",
    "X-Request-ID" => -> { "soletalk-#{Time.now.to_i}" }
  }.freeze
end
```

### 5.2 Typical Session Lifecycle

```
1. App Start / User Login:
   POST /engine/users/identify
   {google_sub: auth.uid, app_source: "incar_companion"}

2. VoiceChat Session Start:
   GET /engine/prompts/{google_sub}  -- Load E/N/G/C context
   GET /incar/profile/{google_sub}   -- Load cached profile
   POST /engine/voicechat {phase: "surface", query: first_message}

3. During Conversation:
   POST /engine/voicechat {phase: "depth", query: message, question_type: "Q1_WHY"}
   POST /engine/query {question: specific_query, google_sub}  -- On-demand search

4. DEPTH Layer (emotion_intensity > 0.7):
   POST /engine/voicechat/depth  -- Q1-Q4 exploration
   POST /incar/events/batch      -- Save E/N/G/C events from Q1-Q4

5. Session End:
   POST /engine/voicechat/insight {q_results: {q1, q2, q3, q4}}  -- Generate insight
   POST /incar/conversations/{session_id}/save {transcript, google_sub}
   POST /engine/insights {google_sub}  -- Persist generated insight
```

### 5.3 Error Handling Pattern

All endpoints follow this error pattern:

```json
// Validation errors (Pydantic)
422: {"detail": [{"loc": ["body", "field"], "msg": "error", "type": "value_error"}]}

// Auth errors
401: {"detail": "API Key is required. Include X-API-Key header."}
401: {"detail": "Invalid or expired API Key"}
429: {"detail": "Rate limit exceeded. Try again in X minutes."}

// Permission errors
403: {"detail": "Permission denied: user X does not have write access to container Y"}

// Not found
404: {"detail": "Session not found: {session_id}"}
404: {"detail": "Object {object_id} not found"}
404: {"detail": "Insight not found"}

// Server errors
500: {"detail": "Failed to identify user: {error}"}
500: {"detail": "Internal server error"}

// Service unavailable
503: {"detail": "Embedding service not configured"}
```

### 5.4 Retry Strategy

```ruby
# Recommended retry configuration for Faraday
Faraday.new do |f|
  f.request :retry, max: 3, interval: 0.5, backoff_factor: 2,
    retry_statuses: [429, 500, 503],
    retry_if: ->(env, _exception) {
      env.status == 429  # Rate limit
    }
end
```

### 5.5 Timeout Recommendations

| Endpoint Category | Connect Timeout | Read Timeout |
|-------------------|----------------|--------------|
| User/Profile (fast) | 5s | 10s |
| Events batch | 5s | 15s |
| Conversation save | 5s | 30s |
| RAG query | 5s | 60s |
| VoiceChat | 5s | 45s |
| Insight generation | 5s | 60s |
| Search/similar | 5s | 15s |

---

## 6. Critical Notes for Project_A Migration

### 6.1 E/N/G/C Parameter Name Convention

**SINGULAR names confirmed** (verified in source code):
- `emotion` (NOT `emotions`)
- `need` (NOT `needs`)
- `goal` (NOT `goals`)
- `constraint` (NOT `constraints`)

This applies to `engc_category` values and the ENGCCategory enum.

However, note that the `/incar/profile/{google_sub}` response uses **PLURAL** keys for the legacy fields (`emotions`, `needs`, `goals`, `constraints`) and `*_summary` fields (`emotions_summary`, etc.).

### 6.2 google_sub as Universal Identifier

`google_sub` is the cross-app user identifier used everywhere:
- Obtained from Google OAuth (`auth.uid` in OmniAuth)
- Used in all API requests that are user-scoped
- Links Project_A, Project_B, and Project_C users

### 6.3 app_source Values

For user identification:
- `"ontology_rag"` -- Project_E itself
- `"incar_companion"` -- Project_B (SoleTalk Android/Kotlin)
- `"sook_intel"` -- Project_C (SookIntel React Native)

Project_A should use `"incar_companion"` for continuity with Project_B, unless a new source is registered.

### 6.4 The /incar Endpoints Are Project_B-Specific

The `/incar/*` endpoints automatically tag data with `source_app: "incar"`. These are the primary integration points for the SoleTalk companion app (both Project_B Kotlin and Project_A Rails).

### 6.5 Two Profile Endpoints

There are two ways to get E/N/G/C profile data:

1. **`GET /engine/prompts/{google_sub}`**: Real-time aggregation from events table (slower, always fresh)
2. **`GET /incar/profile/{google_sub}`**: Cached aggregation from user_profiles table (faster, may be stale)

For VoiceChat session start, prefer `/incar/profile/{google_sub}` for speed. For DEPTH layer analysis, use `/engine/prompts/{google_sub}` for accuracy.

### 6.6 Batch Events vs Single Events

- **Single event**: `POST /engine/events/engc` -- requires `object_id`, stores with `event_type: "engc_{category}"`
- **Batch events**: `POST /incar/events/batch` -- simpler API, auto-sets `google_sub` and `source_app`, also updates profile aggregation

For Project_A, prefer `/incar/events/batch` as it handles profile updates automatically.

---

## 7. Endpoints NOT Relevant to Project_A

These endpoints exist but are primarily for admin/internal use or Project_C:

| Endpoint Prefix | Purpose | Relevance |
|----------------|---------|-----------|
| `/sookintel/*` | Project_C (SookIntel) specific | Not needed |
| `/spicedb/*` | SpiceDB admin management | Not needed |
| `/admin/sync/*` | Neo4j sync administration | Not needed |
| `/admin/analytics/*` | Usage analytics | Not needed |
| `/metrics` | Prometheus metrics | Not needed |
| `/engine/analysis/*` | Document analysis | Low |
| `/engine/extract/*` | Entity extraction | Low |
| `/engine/graph/*` | Graph query API | Low |
| `/engine/batch/*` | Batch processing | Low |
| `/engine/containers/*` | Container management | Low |
| `/engine/decisions/*` | Decision objects | Potentially useful |
| `/engine/persons/*` | Person objects | Potentially useful |
| `/engine/patterns/*` | Pattern objects | Potentially useful |
| `/engine/research/*` | Deep research (Brave API) | Low |

---

## 8. Quick Reference: Project_A Priority Endpoints

| Priority | Endpoint | Method | Rails Service |
|----------|----------|--------|---------------|
| P0 | `/engine/users/identify` | POST | `OntologyRag::Client` |
| P0 | `/engine/prompts/{google_sub}` | GET | `OntologyRag::Client` |
| P0 | `/incar/events/batch` | POST | `EngcEventBatchJob` |
| P0 | `/incar/conversations/{session_id}/save` | POST | `ConversationSaveJob` |
| P1 | `/engine/query` | POST | `OntologyRag::Client` |
| P1 | `/incar/profile/{google_sub}` | GET | `OntologyRag::Client` |
| P1 | `/engine/voicechat` | POST | `VoiceChat::PhaseTransitionEngine` |
| P1 | `/engine/voicechat/surface` | POST | `VoiceChat::PhaseTransitionEngine` |
| P1 | `/engine/voicechat/depth` | POST | `VoiceChat::PhaseTransitionEngine` |
| P1 | `/engine/voicechat/insight` | POST | `VoiceChat::PhaseTransitionEngine` |
| P2 | `/engine/insights` | POST/GET | `Insight::Generator` |
| P2 | `/engine/search/similar` | POST | `OntologyRag::Client` |
| P2 | `/incar/memories/store` | POST | `OntologyRag::Client` |
| P2 | `/incar/memories/recall` | GET | `OntologyRag::Client` |
| P3 | `/health` | GET | Health check |
