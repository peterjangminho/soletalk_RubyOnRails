# Project_C (SookIntel) - Comprehensive Technical Analysis

**Date**: 2026-02-12
**Purpose**: Migration assessment for Project_A (SoleTalk Ruby on Rails)
**Source**: `/Users/peter/Project/Project_C`

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Project Structure](#2-project-structure)
3. [Tech Stack Details](#3-tech-stack-details)
4. [Architecture Pattern](#4-architecture-pattern)
5. [Key Components](#5-key-components)
6. [OntologyRAG Integration](#6-ontologyrag-integration)
7. [Data Storage](#7-data-storage)
8. [Authentication](#8-authentication)
9. [Business Logic](#9-business-logic)
10. [Code Complexity Assessment](#10-code-complexity-assessment)
11. [Comparison Points for Rails Migration](#11-comparison-points-for-rails-migration)
12. [Summary Assessment](#12-summary-assessment)

---

## 1. Project Overview

**App Name**: SookIntel (SOOQINTEL)
**Package**: `com.projectc.app`
**Version**: 1.0.19 (versionCode 19)
**GitHub**: https://github.com/peterjangmins/sookintel_01

SookIntel is a React Native mobile app that provides AI-powered chat, document management, decision support, and knowledge graph integration via OntologyRAG (Project_E). It is a multi-user collaborative intelligence platform with container-based data organization, real-time messaging, and multi-model AI capabilities (Gemini + OpenAI).

### Key Differentiators from Project_A (SoleTalk)

| Aspect | Project_C (SookIntel) | Project_A (SoleTalk) |
|--------|----------------------|---------------------|
| **Focus** | Multi-user collaborative intelligence | Personal in-car voice companion |
| **Chat Model** | Multi-user rooms (1:1, group, AI) | Voice-based session conversations |
| **AI Usage** | RAG-enhanced chat + Decision Support | VoiceChat Engine (5-phase) + DEPTH |
| **Storage** | Supabase (PostgreSQL + RLS) | SQLite (Rails default) |
| **Auth** | Supabase Auth (Google + Email) | OmniAuth (Google OAuth) |
| **OntologyRAG** | Extensive (CRUD, ENGC, Engine Query, SpiceDB) | API consumption only |
| **Platform** | Android + iOS (Expo) | Hotwire Native (Android/iOS) |

---

## 2. Project Structure

### Directory Tree

```
Project_C/
├── app/                        # Expo Router pages (20 files)
│   ├── _layout.tsx             # Root layout (providers, init)
│   ├── index.tsx               # Entry redirect
│   ├── (auth)/                 # Auth flow screens
│   │   ├── _layout.tsx
│   │   ├── login.tsx
│   │   ├── signup.tsx
│   │   └── consent.tsx         # Privacy consent
│   ├── (main)/                 # Authenticated area
│   │   ├── _layout.tsx
│   │   ├── chat/
│   │   │   ├── index.tsx       # Chat list
│   │   │   └── [id].tsx        # Chat room
│   │   ├── containers/
│   │   │   └── index.tsx       # Container management
│   │   ├── dss/                # Decision Support System
│   │   │   ├── _layout.tsx
│   │   │   ├── index.tsx
│   │   │   └── [sessionId].tsx
│   │   ├── friends/
│   │   │   └── index.tsx
│   │   ├── settings/
│   │   │   ├── index.tsx
│   │   │   └── subscription.tsx
│   │   └── admin/
│   │       ├── index.tsx
│   │       └── knowledge-graph.tsx
│   └── auth/
│       ├── _layout.tsx
│       └── callback.tsx        # OAuth callback
│
├── components/                 # UI Components (53 files)
│   ├── BottomNavigator.tsx
│   ├── MessageBubble.tsx
│   ├── FileMessageBubble.tsx
│   ├── VoiceMessageBubble.tsx
│   ├── chat/                   # Chat-specific components (14 files)
│   │   ├── AISourceBadge.tsx
│   │   ├── AttachmentButton.tsx
│   │   ├── AttachmentMenu.tsx
│   │   ├── ChatParticipantsModal.tsx
│   │   ├── ContainerAccessModal.tsx
│   │   ├── GroupChatModal.tsx
│   │   ├── ImagePreviewModal.tsx
│   │   ├── MemberInviteModal.tsx
│   │   ├── MessageLongPressMenu.tsx
│   │   ├── OwnerTransferModal.tsx
│   │   ├── SearchResultBubble.tsx
│   │   ├── UploadingBubble.tsx
│   │   └── VoiceRecorder.tsx
│   ├── containers/             # Container management (2 files)
│   │   ├── ContainerMembersList.tsx
│   │   └── ShareContainerModal.tsx
│   ├── decision-support/       # DSS components (10 files)
│   │   ├── DSSBottomSheet.tsx
│   │   ├── DSSButton.tsx
│   │   ├── DSSFeedback.tsx
│   │   ├── DSSHistoryCard.tsx
│   │   ├── DSSHistoryPreview.tsx
│   │   ├── DSSRefinementInput.tsx
│   │   ├── DSSResultScreen.tsx
│   │   ├── DSSSaveModal.tsx
│   │   ├── FileUploadZone.tsx
│   │   └── UploadedFileList.tsx
│   ├── subscription/           # Subscription management (6 files)
│   │   ├── BetaCodeInput.tsx
│   │   ├── Paywall.tsx
│   │   ├── SubscriptionBadge.tsx
│   │   ├── SubscriptionCard.tsx
│   │   ├── UsageLimitAlert.tsx
│   │   └── UsageProgressBar.tsx
│   └── ui/                     # Reusable UI primitives (16 files)
│       ├── AnimatedTab.tsx
│       ├── CustomAlert.tsx
│       ├── DangerZone.tsx
│       ├── EmptyState.tsx
│       ├── ErrorBoundary.tsx
│       ├── GradientHeader.tsx
│       ├── LanguageSwitcher.tsx
│       ├── NetworkStatus.tsx
│       ├── NetworkStatusBanner.tsx
│       ├── RetryButton.tsx
│       ├── SplashScreen.tsx
│       ├── SyncIndicator.tsx
│       ├── avatar.tsx
│       ├── badge.tsx
│       ├── button.tsx
│       └── input.tsx
│
├── hooks/                      # Custom React hooks (20 files)
├── services/                   # Business logic services (27 subdirectories/files)
├── constants/                  # Constants & configuration (35 files)
├── lib/                        # Utilities & core libraries (21 files)
├── types/                      # TypeScript type definitions (10 files)
├── supabase/                   # Supabase Edge Functions & config
│   └── functions/              # 19 Edge Functions
├── __tests__/                  # Test files (~160 files)
├── tests/                      # Integration & E2E tests
├── locales/                    # i18n translations (en, ko, ar, etc.)
├── scripts/                    # Utility scripts
└── middleware/                 # Security middleware
```

---

## 3. Tech Stack Details

### Core Framework

| Technology | Version | Purpose |
|-----------|---------|---------|
| React Native | ^0.81.5 | Cross-platform mobile framework |
| Expo | ^54.0.30 (SDK 54) | Build toolchain, native APIs |
| React | 19.1.0 | UI library |
| TypeScript | ~5.9.2 | Type safety |

### Navigation & Styling

| Technology | Version | Purpose |
|-----------|---------|---------|
| Expo Router | ~6.0.18 | File-based routing |
| NativeWind | ^4.0.1 | Tailwind CSS for React Native |
| TailwindCSS | ^3.4.0 | Utility-first CSS (via NativeWind) |
| Lucide React Native | ^0.554.0 | Icon library |

### State Management

| Technology | Version | Purpose |
|-----------|---------|---------|
| TanStack React Query | ^5.90.10 | Server state (queries, mutations, caching) |
| Zustand | ^5.0.8 | Client state (auth, chat) |
| @tanstack/query-persist-client | ^5.90.13 | Query cache persistence to AsyncStorage |

### Backend & Data

| Technology | Version | Purpose |
|-----------|---------|---------|
| Supabase JS | ^2.45.0 | PostgreSQL, Auth, Edge Functions, Storage, Realtime |
| AsyncStorage | ^2.2.0 | Local key-value storage |
| expo-sqlite | ~16.0.10 | Offline message cache |

### AI & ML

| Technology | Version | Purpose |
|-----------|---------|---------|
| @google/generative-ai | ^0.24.1 | Gemini client (direct API for vision/STT) |
| OpenAI (via Edge Functions) | - | Chat completions (fallback provider) |
| react-native-sse | ^1.2.1 | Server-Sent Events for AI streaming |

### Other Key Dependencies

| Technology | Version | Purpose |
|-----------|---------|---------|
| react-native-purchases | ^9.6.14 | RevenueCat subscription management |
| @sentry/react-native | ~7.2.0 | Error tracking & performance monitoring |
| i18next + react-i18next | ^25.6.3 / ^16.3.5 | Internationalization (en, ko, ar) |
| expo-av | ~16.0.8 | Audio recording/playback |
| expo-document-picker | ~14.0.8 | File picking |
| expo-file-system | ~19.0.19 | File system access |
| docx / xlsx / fflate | Various | Document parsing (Word, Excel) |

---

## 4. Architecture Pattern

### Overall Architecture

```
+-------------------------------------------+
|          Expo Router (File-based)          |
|  app/(auth)/ | app/(main)/ | app/auth/    |
+-------------------------------------------+
          |                |
+------------------+  +--------------------+
|   Components     |  |   Hooks (20)       |
|   (53 files)     |  |   - useChatRoom    |
|   - chat/        |  |   - useDecision    |
|   - dss/         |  |   - useRAGSearch   |
|   - subscription |  |   - useSubscription|
|   - ui/          |  |   - useGoogleSub   |
+------------------+  +--------------------+
          |                |
+-------------------------------------------+
|          Services Layer (27+ files)        |
|  - ai-chat.service.ts                     |
|  - ontology-rag.service.ts                |
|  - chat/ (room, message, realtime)        |
|  - decision-support/ (orchestrator, etc.) |
|  - auth/ (authService, googleSub)         |
|  - containers/ (CRUD, sharing)            |
|  - file-parsing/ (Excel, Word)            |
|  - subscription/ (RevenueCat)             |
|  - offline/ (SQLite cache)                |
|  - sync/ (write-through, retry queue)     |
+-------------------------------------------+
          |                |
+------------------+  +--------------------+
|   Supabase       |  | OntologyRAG        |
|   (PostgreSQL)   |  | (Project_E API)    |
|   - Auth         |  | via Edge Functions |
|   - RLS          |  | & Direct fetch()   |
|   - Storage      |  |                    |
|   - Realtime     |  |                    |
|   - Edge Funcs   |  |                    |
+------------------+  +--------------------+
```

### State Management Architecture

```
React Query (Server State)        Zustand (Client State)
+---------------------------+     +---------------------------+
| queryClient               |     | authStore                 |
| - messages (per room)     |     |   user, isLoading,        |
| - rooms list              |     |   login, logout           |
| - friends                 |     +---------------------------+
| - containers              |     | chatStore                 |
| - AI responses            |     |   typing indicators,      |
| - DSS sessions            |     |   draft messages          |
| Persisted to AsyncStorage |     +---------------------------+
+---------------------------+
```

### Key Patterns

1. **Service Object Pattern**: Business logic is fully separated into `services/` directory. Each service handles a single domain (chat, auth, ontology-rag, etc.).

2. **Hook Composition**: Custom hooks (`useChatRoom`, `useDecisionSupport`, etc.) compose services, React Query, and Zustand state.

3. **Edge Function Proxy**: All sensitive API calls (LLM, OntologyRAG) go through Supabase Edge Functions to keep API keys server-side.

4. **Feature Flag System**: Extensive feature flag constants in `constants/FeatureFlags.ts` control behavior (Gemini vs OpenAI, web search, DSS multi-step, etc.).

5. **Container-Based Data Organization**: User data is organized into containers (personal, private, common) with type-based access control.

---

## 5. Key Components

### 5.1 Screens/Pages (20 files)

| Route | File | Purpose |
|-------|------|---------|
| `/` | `app/index.tsx` | Entry point, redirects to auth or main |
| `/(auth)/login` | Login screen (email + Google OAuth) |
| `/(auth)/signup` | Registration |
| `/(auth)/consent` | Privacy consent (required before app use) |
| `/auth/callback` | Google OAuth callback handler |
| `/(main)/chat` | Chat room list |
| `/(main)/chat/[id]` | Individual chat room |
| `/(main)/containers` | Container (data bucket) management |
| `/(main)/friends` | Friends list and management |
| `/(main)/dss` | Decision Support System list |
| `/(main)/dss/[sessionId]` | DSS session detail |
| `/(main)/settings` | User settings |
| `/(main)/settings/subscription` | Subscription management |
| `/(main)/admin` | Admin panel |
| `/(main)/admin/knowledge-graph` | Knowledge graph viewer |

### 5.2 UI Components (53 files)

**Chat Components** (14):
- `MessageBubble.tsx` - Text message display
- `FileMessageBubble.tsx` - File attachment display
- `VoiceMessageBubble.tsx` - Audio message with playback
- `VoiceRecorder.tsx` - Audio recording
- `AttachmentMenu.tsx` / `AttachmentButton.tsx` - File upload UI
- `ChatParticipantsModal.tsx` - Room member management
- `GroupChatModal.tsx` - Group chat creation
- `ImagePreviewModal.tsx` - Full-screen image view
- `MessageLongPressMenu.tsx` - Message context actions
- `AISourceBadge.tsx` - Shows RAG source indicators
- `SearchResultBubble.tsx` - RAG search result display

**Decision Support Components** (10):
- `DSSBottomSheet.tsx` - Query input bottom sheet
- `DSSResultScreen.tsx` - Analysis result display
- `DSSRefinementInput.tsx` - Iterative refinement
- `DSSHistoryCard.tsx` / `DSSHistoryPreview.tsx` - Past decisions
- `FileUploadZone.tsx` / `UploadedFileList.tsx` - File upload for DSS
- `DSSFeedback.tsx` - User satisfaction feedback

**Subscription Components** (6):
- `Paywall.tsx` - Subscription paywall
- `SubscriptionCard.tsx` - Plan display
- `UsageProgressBar.tsx` / `UsageLimitAlert.tsx` - Usage tracking

### 5.3 Hooks (20 files)

| Hook | Purpose |
|------|---------|
| `useChatRoom` | Combines messages, sending, AI, realtime subscriptions |
| `useDecisionSupport` | DSS query flow, results, file upload |
| `useDecisionSessions` | DSS session history management |
| `useDSSRefinement` | Iterative analysis refinement |
| `useAIStreaming` | AI response streaming via SSE |
| `useRAGStreaming` | RAG-enhanced streaming responses |
| `useRAGSearch` | Direct RAG search queries |
| `useGoogleSub` | Google OAuth sub extraction |
| `useProjectEWebSocket` | Project_E WebSocket connection (disabled) |
| `useSubscription` | RevenueCat subscription state |
| `useRevenueCat` | RevenueCat purchase flow |
| `useUsageCheck` | Usage limit enforcement |
| `useNetworkStatus` | Online/offline detection |
| `useNotifications` | Push notification handling |
| `useOwnerTransfer` | Room ownership transfer |
| `useAdmin` | Admin panel state |
| `useFadeAnimation` | UI fade animations |
| `useScaleAnimation` | UI scale animations |
| `useTabAnimation` | Tab switching animations |

### 5.4 Services/API Layers

**Core Services** (in `services/`):

| Service | Files | Purpose |
|---------|-------|---------|
| `ontology-rag.service.ts` | 1 large file (~1545 lines) | Full OntologyRAG API client |
| `ai-chat.service.ts` | 1 large file (~885 lines) | AI chat with RAG, Gemini/OpenAI routing |
| `ai-chat/` | 6 files | RAG strategy, context utils, caching, streaming |
| `auth/` | 2 files | Auth service, google_sub extraction |
| `chat/` | 10 files | Room CRUD, messages, participants, realtime |
| `containers/` | 5 files | Container CRUD, sharing, uploads |
| `decision-support/` | 8 files | DSS orchestrator, prompts, history, quality metrics |
| `ai/` | 4 files | Gemini service, vision, STT, migration adapter |
| `subscription/` | 5 files | RevenueCat, usage tracking, beta codes |
| `file-parsing/` | 3 files | Excel, Word, XML entity decoding |
| `offline/` | 3 files | SQLite schema, offline cache, sync |
| `sync/` | 4 files | Write-through, retry queue, file/container sync |
| `llm/` | 2 files | Generic LLM client abstraction |
| `websocket/` | 2 files | WebSocket service for Project_E |
| `stt/` | 2 files | Speech-to-text via Gemini |
| `vision/` | 1 file | Image analysis via Gemini |

**Supabase Edge Functions** (19 functions):

| Function | Purpose |
|----------|---------|
| `gemini-chat` | Gemini LLM chat |
| `gemini-chat-stream` | Gemini streaming chat |
| `gemini-vision` | Gemini vision (image analysis) |
| `gemini-audio` | Gemini audio (STT) |
| `gemini-embedding` | Gemini embeddings |
| `openai-chat` | OpenAI chat (fallback) |
| `openai-chat-stream` | OpenAI streaming |
| `openai-embedding` | OpenAI embeddings |
| `openai-transcribe` | OpenAI Whisper STT |
| `ontology-rag-proxy` | OntologyRAG generic proxy (createObject, createRelation, etc.) |
| `ontology-rag-analyze` | OntologyRAG document analysis |
| `ontology-rag-engine-query` | OntologyRAG advanced RAG search |
| `embed-message` | Automatic message embedding webhook |
| `sync-to-ontology` | Sync data to OntologyRAG |
| `process-uploaded-file` | OCR/STT/text extraction |
| `rag-query` | RAG query endpoint |
| `rag-query-stream` | RAG streaming query |
| `decision-orchestrator` | DSS server-side pipeline |
| `daily-reconciliation` | Data reconciliation cron |
| `revenuecat-webhook` | Subscription webhook |
| `send-push-notification` | Push notification sender |
| `cleanup-expired-files` | File expiry cleanup |
| `embedding-generator` | Embedding generation |

---

## 6. OntologyRAG Integration

### 6.1 Connection Architecture

All OntologyRAG API calls follow a **two-tier proxy pattern**:

```
React Native App
       |
       | (Supabase JS client)
       v
Supabase Edge Functions (Deno)
       |
       | (fetch with X-API-Key)
       v
Project_E (OntologyRAG FastAPI on Railway)
```

**Why proxy?** API keys (ONTOLOGY_RAG_API_KEY) are stored as Supabase Edge Function secrets, never exposed to the client. The only exception is the web search feature in `ai-chat.service.ts`, which makes a direct `fetch()` call using `EXPO_PUBLIC_ONTOLOGY_RAG_API_URL` and `EXPO_PUBLIC_ONTOLOGY_RAG_API_KEY` environment variables.

### 6.2 API Endpoints Called

From `services/ontology-rag.service.ts` (client-side, via Edge Function proxy):

| Method | Action Param | Project_E Endpoint | Purpose |
|--------|-------------|-------------------|---------|
| `identifyUser()` | `identifyUser` | `POST /engine/users/identify` | Cross-app user registration |
| `getUserData()` | `getUserData` | `GET /engine/users/{google_sub}` | User profile + containers |
| `createContainer()` | `createContainer` | `POST /engine/containers` | Create data container |
| `listContainers()` | `listContainers` | `GET /engine/containers?google_sub=X` | List user containers |
| `deleteContainer()` | `deleteContainer` | `DELETE /engine/containers/{id}` | Delete container + data |
| `createObject()` | `createObject` | `POST /engine/objects` | Create KG node |
| `createRelation()` | `createRelation` | `POST /engine/relations` | Create KG edge |
| `recordEvent()` | `recordEvent` | `POST /engine/events` | Track user actions |
| `hybridQuery()` | `hybridQuery` | `POST /engine/query` (legacy) | Vector + Graph search |
| `engineQuery()` | N/A (dedicated EF) | `POST /engine/query` (advanced) | Advanced RAG search |
| `createDocument()` | `createDocument` | `POST /engine/documents` | Create embedded document |
| `createDocumentFromFile()` | `createDocumentFromFile` | `POST /engine/documents/from-file` | File-based document |
| `listObjects()` | `listObjects` | `GET /engine/objects` | List KG objects |
| `searchSimilar()` | `searchSimilar` | `POST /engine/search/similar` | Vector similarity search |
| `recordENGCEvent()` | `recordENGCEvent` | `POST /engine/events/engc` | ENGC tracking |
| `getENGCProfile()` | `getENGCProfile` | `GET /engine/prompts/{google_sub}` | Aggregated ENGC profile |
| `getENGCEvents()` | `getENGCEvents` | `GET /engine/events/engc` | Query ENGC events |

From `supabase/functions/_shared/ontologyRag.ts` (Edge Function side, direct HTTP):

| Function | Project_E Endpoint | Purpose |
|----------|-------------------|---------|
| `createDocumentFromFile()` | `POST /api/v1/documents/from-file` | File processing |
| `createDocumentWithContent()` | `POST /engine/documents` | Document with content |
| `listDocuments()` | `GET /engine/documents` | List documents |
| `grantContainerPermission()` | `POST /api/v1/spicedb/admin/grant` | SpiceDB access control |
| `createOntologyContainer()` | `POST /engine/containers` | Container creation |
| `embedMessages()` | `POST /sookintel/messages/embed` | Message embedding |
| `syncRoom()` | `POST /sookintel/rooms/{room_id}/sync` | SpiceDB room sync |

From `ai-chat.service.ts` (direct fetch for web search):

| Method | Project_E Endpoint | Purpose |
|--------|-------------------|---------|
| `fetchWebSearchResults()` | `POST /sookintel/search/enhanced` | Brave web search via OntologyRAG |

### 6.3 Request/Response Handling Patterns

**Standard pattern** (client-side via Edge Function proxy):
```typescript
// All calls go through supabase.functions.invoke
const { data, error } = await supabase.functions.invoke<ResponseType>(
  ONTOLOGY_RAG.EDGE_FUNCTIONS.PROXY,  // 'ontology-rag-proxy'
  {
    body: {
      action: 'methodName',  // Routing action for the proxy
      ...request,             // Request payload
    },
  }
);
```

**Edge Function side pattern** (direct HTTP to Railway):
```typescript
const response = await fetch(`${apiUrl}/engine/endpoint`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-API-Key': apiKey,
    ...createDownstreamHeaders(context), // X-Request-ID for tracing
  },
  body: JSON.stringify(payload),
  signal: controller.signal, // Timeout via AbortController
});
```

**Error handling**: Every method returns `{ success: boolean; error?: string; ...data }`. Errors are caught at both Edge Function and client levels, logged via `safeError()`, and returned as structured error objects.

### 6.4 Authentication with OntologyRAG

The cross-app identifier is **google_sub** (Google OAuth unique ID). The flow:

1. User logs in via Google OAuth -> Supabase Auth stores identity data
2. `authService.getGoogleSub()` extracts `sub` from `user.identities[].identity_data`
3. `OntologyRAGService.identifyUser({ google_sub, app_user_id, app_source: 'SookIntel' })` registers in Project_E
4. All subsequent API calls include `google_sub` for user scoping

**SpiceDB Integration**: Project_C also uses SpiceDB (via Project_E) for fine-grained access control on containers and rooms, using `grantContainerPermission()` and `syncRoom()`.

---

## 7. Data Storage

### 7.1 Remote Storage: Supabase (Primary)

**Database**: PostgreSQL with Row Level Security (RLS)

Key tables:
- `users` - User profiles (id, email, name, avatar_url, google_sub)
- `rooms` - Chat rooms (id, name, type, owner_id, container_id)
- `room_members` - Room membership (room_id, user_id, ai_enabled, role)
- `messages` - Chat messages (id, room_id, sender_id, content, type, visibility, metadata)
- `containers` - Data containers (id, owner_id, type, room_id)
- `files` - Uploaded files (id, container_id, file_name, mime_type, storage_path, ontology_document_id)
- `friends` - Friend relationships
- `decision_sessions` - DSS sessions
- `decision_results` - DSS analysis results
- `subscriptions` - User subscription data
- `usage_tracking` - Feature usage limits

**Supabase Storage Buckets**:
- `avatars` - User profile images
- `chat-files` - Chat file attachments
- `voice-messages` - Voice recordings
- `container-files` - Container file uploads

**Supabase Realtime**: Used for real-time message delivery and typing indicators.

### 7.2 Remote Storage: OntologyRAG (Secondary)

**Supabase ID**: `jzmfypcqzxttydwlbsbb` (separate Supabase project for OntologyRAG)

OntologyRAG stores:
- Knowledge graph nodes (Neo4j)
- Vector embeddings (pgvector)
- ENGC events (Emotion/Need/Goal/Constraint)
- SpiceDB permission tuples

### 7.3 Local Storage

**AsyncStorage**:
- Supabase auth session tokens
- React Query cache persistence (via `@tanstack/query-async-storage-persister`)
- User preferences

**SQLite (expo-sqlite)**:
- Offline message cache (read-only mirror of Supabase messages)
- Cached room list for offline viewing
- Pending messages queue (for offline-first sending)
- Schema defined in `services/offline/schema.ts`

### 7.4 Caching Strategy

1. **React Query Cache**: Primary in-memory cache for all server data. Persisted to AsyncStorage for offline access.
2. **RAG Cache** (`services/ai-chat/ragCache.ts`): In-memory cache for RAG search results to avoid redundant OntologyRAG API calls within a session.
3. **Access Cache** (`ontology-rag.service.ts`): In-memory `Map<string, string>` mapping `{googleSub}:{containerId}` to Railway container IDs.
4. **SQLite Offline Cache**: Structured cache for messages and rooms when offline.

---

## 8. Authentication

### 8.1 Auth Flow

**Provider**: Supabase Auth

**Methods**:
1. **Google OAuth** (Primary): `loginWithGoogle()` via `expo-web-browser` OAuth flow
   - Opens browser -> Google consent -> redirect back to app scheme (`projectc://auth/callback`)
   - Extracts `access_token` and `refresh_token` from URL fragments
   - Sets Supabase session with `supabase.auth.setSession()`
   - Upserts user into `public.users` table

2. **Email/Password** (Secondary): Standard Supabase email auth
   - `signInWithPassword()` for login
   - `signUp()` for registration
   - Email confirmation may be required

### 8.2 Post-Auth Flow

```
Login Success
     |
     v
Check consent_data_processing in user_metadata
     |
     ├── undefined (new user) -> Navigate to /consent
     │                              |
     │                              v
     │                        Accept consent
     │                              |
     │                              v
     │                        Navigate to /main
     |
     └── true (existing user) -> Navigate to /main
```

### 8.3 Cross-App Identification

```typescript
interface UserIdentifiers {
  supabaseId: string;     // Supabase UUID
  googleSub: string;      // Google OAuth 'sub' (primary for OntologyRAG)
  email: string;
  primaryIdentifier: string; // googleSub ?? supabaseId
  provider: string;       // 'google' | 'email'
}
```

The `google_sub` is the primary cross-app identifier used by Project_E (OntologyRAG) to link users across SookIntel (Project_C), SoleTalk (Project_A/B).

---

## 9. Business Logic

### 9.1 Core Features

#### Feature 1: AI-Powered Chat
- Multi-user chat rooms (1:1, group, AI-only)
- AI responses via RAG (Retrieval-Augmented Generation)
- Dual LLM support: Gemini (primary) with OpenAI fallback
- Message visibility: public (shared) vs private (user-only AI response)
- Voice messages with STT transcription
- File attachments with automatic analysis
- Web search integration for real-time information

#### Feature 2: Container-Based Data Organization
- **Personal containers**: User-owned data buckets
- **Private containers**: 1:1 chat shared data
- **Common containers**: Group chat shared data
- Files, messages, and AI responses are organized into containers
- Container sharing between users with access control

#### Feature 3: Decision Support System (DSS)
- Multi-framework analysis (General, SWOT, Cost-Benefit, Risk Matrix, Comparison)
- 3-step pipeline: Context Aggregation -> Analysis -> Synthesis
- Iterative refinement with user feedback
- File upload support for document-based decisions
- Web search integration for external data
- Decision history and session management
- Quality metrics and confidence scoring

#### Feature 4: OntologyRAG Knowledge Graph
- Automatic document analysis and entity extraction
- Hybrid search (vector + graph) for contextual answers
- ENGC tracking (Emotion/Need/Goal/Constraint)
- Cross-app user identification
- SpiceDB-based access control

#### Feature 5: Subscription Management
- RevenueCat integration for in-app purchases
- Usage tracking and limits
- Beta code system for early access
- Tiered feature access

#### Feature 6: Offline Support
- SQLite cache for offline message reading
- Pending message queue for offline sending
- Sync service for reconnection

### 9.2 Key Workflows

**Chat Message Flow**:
```
User types message
    |
    v
useChatRoom.sendMessage()
    |
    v
chatService.sendMessage() -> Supabase INSERT
    |
    ├── Realtime broadcasts to other users
    |
    ├── If AI enabled: getAIResponseWithRAG()
    |       |
    |       ├── RAG search (OntologyRAG hybrid or pgvector)
    |       ├── Web search (if enabled)
    |       ├── Build context + system prompt
    |       ├── Call Gemini/OpenAI Edge Function
    |       └── Save AI response to messages table
    |
    └── Embed message in OntologyRAG (async, fire-and-forget)
```

**DSS Workflow**:
```
User asks decision question
    |
    v
useDecisionSupport.analyze()
    |
    v
decision-orchestrator Edge Function
    |
    ├── ContextAggregator: gather RAG, chat history, ENGC, files
    |
    ├── Feature flag check: MVP (single call) or Multi-step
    |
    ├── MVP: Single Gemini/OpenAI call with full context
    |   OR
    ├── Multi-step:
    |   ├── Step 1: Analysis (identify framework, extract options)
    |   ├── Step 2: Generation (evaluate each option)
    |   └── Step 3: Synthesis (final recommendation)
    |
    ├── Quality metrics computation
    |
    └── Save to decision_sessions + decision_results
```

**File Processing Flow**:
```
User uploads file
    |
    v
file-upload.service -> Supabase Storage
    |
    v
process-uploaded-file Edge Function
    |
    ├── Detect file type (image/audio/document)
    ├── Image -> Gemini Vision OCR
    ├── Audio -> Gemini STT
    ├── Document -> Text extraction (PDF, DOCX, XLSX)
    |
    └── createDocumentWithContent() -> OntologyRAG
         |
         └── Auto-embed for vector search
```

### 9.3 ENGC (Emotion/Need/Goal/Constraint) System

Tracks user psychological states via OntologyRAG:
- **Emotion**: joy, sadness, anger, fear, surprise, disgust (with intensity 0.0-1.0)
- **Need**: safety, belonging, esteem, self-actualization
- **Goal**: achieve, maintain, avoid
- **Constraint**: time, resource, ability

ENGC events are recorded and aggregated into user profiles for personalized AI responses.

---

## 10. Code Complexity Assessment

### 10.1 File Counts

| Directory | Source Files | Test Files | Total |
|-----------|-------------|-----------|-------|
| `app/` (screens) | 20 | - | 20 |
| `components/` | 53 | - | 53 |
| `hooks/` | 20 | - | 20 |
| `services/` | ~55 | - | ~55 |
| `constants/` | ~35 | - | ~35 |
| `lib/` | ~21 | - | ~21 |
| `types/` | ~10 | - | ~10 |
| `supabase/functions/` | ~30 | - | ~30 |
| `middleware/` | 2 | - | 2 |
| `scripts/` | ~10 | - | ~10 |
| `__tests__/` | - | ~160 | ~160 |
| `tests/` | - | ~20 | ~20 |
| **Total** | **~256** | **~180** | **~436** |

### 10.2 Key Feature Complexity

| Feature | Files Involved | Complexity | Notes |
|---------|---------------|-----------|-------|
| Chat System | ~30 | High | Real-time, multi-user, AI integration |
| OntologyRAG Integration | ~15 | Very High | 17+ API methods, 7+ Edge Functions |
| Decision Support | ~18 | Very High | Multi-step pipeline, file context, iterative |
| Auth + google_sub | ~8 | Medium | OAuth flow + cross-app identification |
| Subscription | ~10 | Medium | RevenueCat + usage tracking |
| Offline Support | ~6 | Medium | SQLite cache + sync |
| File Processing | ~10 | High | OCR, STT, text extraction |
| i18n | ~8+ | Low-Medium | 3 languages (en, ko, ar) |

### 10.3 Lines of Code (Estimated Key Files)

| File | Lines | Notes |
|------|-------|-------|
| `ontology-rag.service.ts` | ~1545 | Largest service file |
| `ai-chat.service.ts` | ~885 | AI + RAG integration |
| `authService.ts` | ~814 | Full auth + cross-app ID |
| `chatService.ts` + operations | ~800+ | Chat system (split across 10 files) |
| `types/ontology-rag.ts` | ~752 | Comprehensive type definitions |
| `constants/Api.ts` | ~254 | All API configuration |

---

## 11. Comparison Points for Rails Migration

### 11.1 Patterns Adaptable to Rails + Hotwire

| Project_C Pattern | Rails Equivalent |
|-------------------|-----------------|
| Service Object (`services/`) | `app/services/` (same pattern, natural fit) |
| Constants (`constants/Api.ts`) | `app/services/ontology_rag/constants.rb` |
| Type definitions (`types/ontology-rag.ts`) | `app/services/ontology_rag/models.rb` (Ruby structs/classes) |
| Feature Flags (`constants/FeatureFlags.ts`) | Rails `config/feature_flags.yml` or `Flipper` gem |
| Error handling pattern (structured errors) | Ruby service objects with `Result` pattern |
| Edge Function proxy pattern | Rails controller -> Service -> HTTP client |
| React Query caching | Rails.cache (Solid Cache) |
| Zustand auth store | Rails session + `current_user` helper |
| Expo Router file-based routing | Rails routes.rb (more explicit) |
| NativeWind styling | Tailwind CSS (direct, no adapter needed) |

### 11.2 Platform-Specific vs. Reusable Logic

**Platform-Specific (NOT transferable)**:
- Expo-specific APIs (expo-av, expo-file-system, expo-sqlite, etc.)
- React Native UI components (NativeWind, gestures, animations)
- Supabase Edge Functions (Deno runtime) - would become Rails controllers/jobs
- Supabase Realtime subscriptions - would become Action Cable
- AsyncStorage persistence
- RevenueCat integration
- Push notification handling
- SQLite offline cache

**Reusable Business Logic**:
- OntologyRAG API integration patterns (request/response shapes, error handling)
- google_sub extraction and cross-app identification flow
- ENGC event types and recording logic
- Decision Support System pipeline architecture
- RAG search strategy pattern (hybrid, vector, graph)
- Container-based data organization model
- File processing workflow (OCR/STT/extraction routing)
- Chat room types and permission model (personal, private, common)

### 11.3 OntologyRAG Integration Patterns to Preserve

**Critical patterns that Project_A must replicate**:

1. **Cross-App User Identification**:
   ```
   Google OAuth -> google_sub extraction -> identifyUser API
   ```
   Project_A uses OmniAuth -> same pattern, extract `auth.uid` as google_sub.

2. **API Call Pattern**:
   ```
   Headers: X-API-Key, X-Request-ID, Content-Type: application/json
   Base URL from ENV['ONTOLOGY_RAG_BASE_URL']
   ```
   Direct match with Project_A's planned `OntologyRag::Client`.

3. **ENGC Event Recording** (Project_A's DEPTH layer equivalent):
   ```
   recordENGCEvent({ google_sub, container_id, engc_type, engc_value, content, intensity })
   ```
   Project_A's DEPTH Q1-Q4 answers map directly to ENGC events.

4. **Hybrid Search**:
   ```
   engineQuery({ google_sub, query, strategy: 'hybrid', top_k, include_graph })
   ```
   Same endpoint used by Project_A for conversation context retrieval.

5. **Error Handling**:
   All responses follow `{ success: boolean; error?: string; ...data }` pattern.
   Project_A should adopt the same pattern in Ruby.

### 11.4 Key Differences in OntologyRAG Usage

| Aspect | Project_C (SookIntel) | Project_A (SoleTalk) |
|--------|----------------------|---------------------|
| **Scope** | Full CRUD (objects, relations, events, documents, containers) | Read-heavy (query, prompts, events/batch) |
| **SpiceDB** | Used (container permissions, room sync) | Not used (Rails handles auth natively) |
| **Container Model** | Container per room/user, shared across users | Session-based, user-owned |
| **Document Sync** | Real-time (webhook on message insert) | On session end (POST /incar/conversations) |
| **ENGC Recording** | Through proxy Edge Function | Direct from Rails service |
| **Web Search** | Via OntologyRAG Enhanced Search endpoint | Not yet planned |
| **DSS** | Full decision support pipeline | Not applicable |
| **Embedding** | Client triggers via Edge Functions | OntologyRAG auto-embeds on /engine/query |

---

## 12. Summary Assessment

### Overall Complexity: HIGH

Project_C (SookIntel) is a substantial application with approximately 256 source files, 180 test files, and 19 Supabase Edge Functions. The OntologyRAG integration alone is extensive with 17+ API methods, making it the most comprehensive consumer of Project_E among the three projects.

### Key Takeaways for Project_A Migration

1. **OntologyRAG Client Pattern**: Project_C's `ontology-rag.service.ts` is the gold standard for OntologyRAG integration. Project_A's `OntologyRag::Client` should mirror its method signatures, error handling, and response normalization - but with significantly fewer methods (Project_A only needs identify, query, prompts, events/batch, conversations/save).

2. **google_sub is Critical**: The entire cross-app identification system depends on google_sub. Project_A must ensure `OmniAuth -> google_oauth2 -> auth.uid` maps correctly to `identifyUser()`.

3. **ENGC Maps to DEPTH**: Project_C's ENGC types (emotion, need, goal, constraint) are the same as Project_A's DEPTH Q1-Q4 extraction targets. The recording API is the same.

4. **Container Model Differs**: Project_C uses containers for multi-user data compartmentalization. Project_A uses session-based data with user ownership. This is a fundamental architectural difference that does not need to be ported.

5. **Edge Function Pattern Not Needed**: Project_C proxies through Edge Functions for API key security. Project_A (server-rendered Rails) can call OntologyRAG directly from service objects since API keys are server-side by default.

6. **Feature Flag System**: Project_C's extensive feature flag system (Gemini vs OpenAI, web search, DSS steps) is a good practice that Project_A should adopt for phased rollout of VoiceChat Engine features.

7. **Test Coverage**: Project_C has ~180 test files covering services, components, integration, security, and performance. Project_A should aim for similar coverage, especially for OntologyRAG integration tests.

### Migration Priority Recommendations

| Priority | What to Reference from Project_C | Project_A Equivalent |
|----------|--------------------------------|---------------------|
| P0 | google_sub extraction pattern | `Auth::GoogleSubExtractor` |
| P0 | identifyUser API pattern | `OntologyRag::Client#identify_user` |
| P1 | engineQuery/hybridQuery pattern | `OntologyRag::Client#query` |
| P1 | ENGC event recording pattern | VoiceChat DEPTH -> `OntologyRag::Client#record_engc_event` |
| P2 | Error handling (success/error pattern) | `OntologyRag::Models` response classes |
| P2 | Constants organization | `OntologyRag::Constants` |
| P3 | RAG caching strategy | `Rails.cache` with query-based keys |
| P3 | Feature flag pattern | `Rails.configuration` or `Flipper` gem |
