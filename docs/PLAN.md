# SoleTalk Development Roadmap (PLAN.md)

> **Project**: SoleTalk (Project_A) — Rails 8 + Hotwire Native + SQLite
> **Approach**: Informed Fresh Build (reference Project_B/C logic, write idiomatic Ruby)
> **Methodology**: TDD (Red→Green→Refactor) + Tidy First + 6 Vibe Coding Principles
> **Full Plan**: `docs/ref/20260212_05_PLAN_full_korean.md`

---

## Methodology

**TDD Cycle**: Red (failing test) → Green (minimum code) → Refactor → Commit
**Tidy First**: Structural changes separate from behavioral changes, never mixed in same commit
**Commit**: Only when all tests pass + linter clean + single logical unit

**6 Vibe Coding Principles**:
1. Consistent Patterns (CRUD uniformity)
2. One Source of Truth (ENV/credentials for config)
3. No Hardcoding (constants/enums for magic values)
4. Error Handling (Happy Path + Error Path)
5. Single Responsibility (Controller=request, Service=logic, Model=validation)
6. Shared Modules (reusable services in app/services/, concerns/)

**Phase Workflow**:
```
Phase plan → TDD implementation → Verification → Gap analysis
  → Re-implementation → Phase E2E test → Debug → Fix → E2E pass ✅
```

---

## Critical Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Build approach | Informed Fresh Build | Architecture paradigm mismatch, zero tech debt |
| Context model | 5-Layer unified | CLAUDE.md spec, resolves TS/Kotlin inconsistency |
| app_source | `"incar_companion"` | Project_B compat, existing user data |
| E/N/G/C params | **Singular** (emotion, need, goal, constraint) | Confirmed in Project_E source |
| Auth | OmniAuth google_oauth2 → google_sub | Direct mapping, no 3-tier fallback |
| Cache | Solid Cache (SQLite-based) | Rails 8 default |
| VoiceChatManager | Split into 6-8 Service Objects | God Class decomposition |
| Profile strategy | Session start: `/incar/profile` (fast), DEPTH: `/engine/prompts` (accurate) | Speed vs accuracy |
| Test stack | Minitest + WebMock + VCR | Rails default + API mocking |
| Background | Solid Queue (SQLite-based) | Rails 8 default |
| Real-time | Action Cable + Solid Cable | Rails default WebSocket |
| Subscription | RevenueCat (Free/Premium) | Cross-platform subscription mgmt |

---

## Phase Overview

| Phase | Name | Difficulty | Tests | Status |
|:-----:|------|:----------:|:-----:|:------:|
| 0 | Knowledge Extraction + Env Setup | — | — | ✅ Done |
| 1 | Rails Project Init + Infrastructure | Low | 5-8 | In Progress |
| 2 | Authentication (OmniAuth Google) | Low | 8-12 | ✅ Done |
| 3 | Core Data Models | Low | 10-15 | ✅ Done |
| 4 | OntologyRAG Client (P0 endpoints) | Med | 15-20 | In Progress |
| 5 | VoiceChat Domain Services | Med | 15-20 | ✅ Done |
| 6 | DEPTH Layer (Q1-Q4) | Med-High | 15-20 | ✅ Done |
| 7 | Context Orchestrator (5-Layer) | Med | 10-15 | ✅ Done |
| 8 | Insight Generation | Med | 10-15 | ✅ Done |
| 9 | Real-time (Action Cable) | High | 8-12 | ✅ Done |
| 10 | UI (Turbo + Stimulus) | Med-High | 10-15 | ✅ Done |
| 11 | Background Jobs (Solid Queue) | Low | 8-10 | ✅ Done |
| 12 | RevenueCat Subscription | Med | 10-15 | ✅ Done |
| 13 | Voice Pipeline (Native Bridge) | High | 8-12 | In Progress (Split Track) |
| 14 | OntologyRAG P1 Endpoints | Med | 10-15 | ✅ Done |
| 15 | Integration Tests + Optimization | Med | 20-30 | ✅ Done |
| 16 | Deployment + Monitoring | Med | 5-8 | In Progress |
| | **Total** | | **167-242** | |

---

## Phase 0: Knowledge Extraction + Env Setup ✅

- [x] Project_B analysis → `docs/ondev/20260212_01_project_b_analysis.md`
- [x] Project_C analysis → `docs/ondev/20260212_02_project_c_analysis.md`
- [x] Project_E API analysis → `docs/ondev/20260212_03_project_e_api_analysis.md`
- [x] Migration assessment → `docs/ondev/20260212_04_comprehensive_migration_assessment.md`
- [x] CLAUDE.md written
- [x] Dev env: Ruby 3.4.8, Rails 8.1.2, mise

## Phase 1: Rails Project Init + Infrastructure

- [x] `rails new` with SQLite, Turbo, Stimulus
- [x] Gemfile: faraday, omniauth, webmock, vcr, brakeman, rubocop-rails-omakase, dotenv-rails
- [x] Directory structure: app/services/, app/channels/, app/jobs/
- [ ] ENV setup (.env + Rails credentials)
- [x] RuboCop + Brakeman + CI (GitHub Actions)
- [x] Solid Cache / Solid Queue / Solid Cable config
- [x] Test infrastructure (Minitest + WebMock + VCR)

## Phase 2: Authentication (OmniAuth Google)

- [x] User model (google_sub unique, email, name, avatar_url, subscription_tier)
- [x] OmniAuth google_oauth2 setup + CSRF protection
- [x] Auth::GoogleSubExtractor service
- [x] Auth::OmniauthCallbacksController (login/failure)
- [x] Session management (current_user, authenticate_user!)
- [x] OntologyRAG user registration (POST /engine/users/identify, async)

## Phase 3: Core Data Models

- [x] Session model (user_id, status, started_at/ended_at, metadata)
- [x] Message model (session_id, role enum, content, message_type, metadata)
- [x] VoiceChatData model (session_id, current_phase, emotion/energy_level, weather/gps, phase_history)
- [x] DepthExploration model (signal_emotion_level, signal_keywords[], q1-q4_answer, impacts[], information_needs[])
- [x] Insight model (situation, decision, action_guide, data_info, natural_text, engc_profile)
- [x] Setting model (user_id, language, voice_speed, preferences)
- [x] Associations + indexes + cascade delete rules

## Phase 4: OntologyRAG Client (P0)

- [x] OntologyRag::Constants (endpoints, headers, per-endpoint timeouts, retry config)
- [x] OntologyRag::Models (request/response objects, **singular E/N/G/C params**)
- [x] OntologyRag::Client (Faraday + retry middleware + error classes)
- [x] P0: `identify_user` (POST /engine/users/identify)
- [x] P0: `get_profile` (GET /engine/prompts/{google_sub})
- [x] P0: `batch_save_events` (POST /incar/events/batch)
- [x] P0: `save_conversation` (POST /incar/conversations/{session_id}/save)
- [ ] VCR cassettes + WebMock tests for all endpoints

## Phase 5: VoiceChat Domain Services

- [x] VoiceChat::Constants (phase definitions, transition thresholds, emotion keywords, DEPTH conditions)
- [x] VoiceChat::PhaseTransitionEngine (5-Phase state machine, transition rules)
- [x] VoiceChat::EmotionTracker (emotion/energy level tracking, trend analysis)
- [x] VoiceChat::NarrowingService (open→focused question progression)
- [x] VoiceChat::DepthSignalDetector (emotion>0.8, keywords, repetition≥3, avoidance pattern)

## Phase 6: DEPTH Layer (Q1-Q4)

- [x] VoiceChat::QuestionGenerator (Q1.WHY, Q2.DECISION, Q3.IMPACT, Q4.DATA)
- [x] VoiceChat::DepthManager (enter/advance/exit depth)
- [x] VoiceChat::DepthExplorationService (record answers, calculate progress)
- [x] VoiceChat::ImpactAnalyzer (5-dimension: emotional/relational/career/financial/psychological)
- [x] VoiceChat::InformationNeedManager (external/past/others/inner/forgotten info types)

## Phase 7: Context Orchestrator (5-Layer)

- [x] VoiceChat::ContextOrchestrator (build 5-layer context)
  - L1 Profile (10%), L2 Past Memory (20%), L3 Current Session (30%), L4 Additional Info (15%), L5 AI Persona (15%)
- [x] VoiceChat::TokenBudgetManager (allocation, truncation, dynamic rebalancing)
- [x] Caching strategy (L1: session TTL, L2: 5min, L3: none, L4: 1hr, L5: app-level)

## Phase 8: Insight Generation

- [x] Insight::Generator (Q1-Q4 → LLM prompt → Insight record)
- [x] Insight::NaturalSpeech (template: "지금은 [situation]이고, [info] 때문에, [purpose]을 위해서, [action_guide]가 좋을 것 같아요")
- [x] InsightsController (index, show + Turbo Frame)

## Phase 9: Real-time Communication (Action Cable)

- [x] Action Cable endpoint config (`/cable` mount)
- [x] VoiceChatChannel (session_id 기반 subscribe/receive/broadcast)
- [x] Real-time Phase transition broadcasts (Turbo Streams)
- [x] Connection management (reconnect, session restore, message loss prevention)

## Phase 10: UI (Turbo + Stimulus)

- [x] VoiceChat UI (message stream, phase status bar)
- [x] VoiceChat UI (DEPTH/Insight display)
- [x] VoiceChat UI (emotion gauge)
- [x] Session management UI (list, detail)
- [x] Session management UI (new session)
- [x] Root dashboard UI (guest sign-in entry + signed-in navigation)
- [x] Insight display UI (cards, timeline, Q1-Q4 detail)
- [x] Settings UI
- [x] common Stimulus controllers
- [x] Responsive mobile-first layout, Hotwire Native compatible (baseline)

## Phase 11: Background Jobs (Solid Queue)

- [x] EngcEventBatchJob (DEPTH complete → POST /incar/events/batch)
- [x] ConversationSaveJob (session end → POST /incar/conversations/save)
- [x] ExternalInfoJob (Type A-D info collection, Premium only)
- [x] Retry: 3x exponential backoff, dead letter on failure (baseline)
- [x] Mission Control dashboard (baseline `/admin/jobs`)

## Phase 12: RevenueCat Subscription

- [x] RevenueCat client (API baseline)
- [x] User subscription fields (subscription_status, expires_at, revenue_cat_id)
- [x] Feature Gating: Free=SURFACE only, 3 sessions/day, 7d history | Premium=full 3-Layer, unlimited (baseline)
- [x] Webhook handler (subscription events → user sync)
- [x] Paywall UI + server-side receipt validation (baseline)

## Phase 13: Voice Pipeline (Hotwire Native Bridge) ⚠️ HIGHEST RISK

### Rails Scope (this repository)
- [x] Rails-side native bridge contract endpoint (`POST /api/voice/events`) baseline
- [x] Bridge action hardening (`start_recording`, `stop_recording`, `location_update`) with persistence + validation
- [x] Voice event auth/ownership guard strategy and enforcement
- [x] Voice event phase-level E2E coverage (success + representative failure)

### Mobile Scope (external repos / mobile track)
- [ ] Android Hotwire Native project setup
- [ ] AudioBridgeComponent (JS ↔ Native: startRecording, stopRecording, playAudio, onTranscription)
- [ ] STT integration (Gemini Live API streaming)
- [ ] TTS integration (text → speech → native playback)
- [ ] LocationBridgeComponent (GPS + weather)
- [ ] Gemini Live API bidirectional audio streaming

관련 문서:
- mobile handoff: `docs/ondev/20260214_28_phase13_mobile_track_handoff.md`
- rails hardening sub-plan: `docs/ondev/20260214_29_phase13_rails_bridge_hardening_plan.md`

> **Risk Note**: PoC first recommended. Plan may adjust based on PoC results.

## Phase 14: OntologyRAG P1 Endpoints

- [x] `query` (POST /engine/query — hybrid search) API baseline
- [x] `get_cached_profile` (GET /incar/profile/{google_sub}) client 지원
- [x] VoiceChat 3-layer endpoints (surface/depth/insight) baseline
- [x] Context Orchestrator L2 (Past Memory) + L4 (External Info) full implementation (baseline)
- [x] Search result caching (query-level baseline)

## Phase 15: Integration Tests + Optimization

- [x] E2E: SURFACE → DEPTH → INSIGHT full flow
- [x] E2E: Auth → Chat → Insight → Save
- [x] E2E: Feature Gating (Free vs Premium)
- [x] E2E: Error scenarios (API failure baseline)
- [x] Performance: P95 baseline smoke check
- [x] Security: Brakeman zero issues
- [x] Quality: RuboCop clean, full test pass

## Phase 16: Deployment + Monitoring

- [x] Health endpoint + env validator baseline (`/healthz`, `Ops::EnvValidator`)
- [x] Deploy platform (Railway) + Dockerfile
- [x] Production env vars + secrets management baseline (`ops:preflight`)
- [x] Railway required runtime env injection completed (`ONTOLOGY_RAG_*`, `GOOGLE_*`)
- [x] Railway runtime deployment success (`88ef8d09-2fc2-41ce-8eaf-3e406e9c1ab0`)
- [x] Production live check (`/healthz` OK, `/` 200)
- [x] Ops runbook documented (`docs/ondev/20260214_24_phase16_ops_runbook.md`)
- [x] App store prep checklist documented (`docs/ondev/20260214_25_app_store_prep_checklist.md`)
- [x] Error tracking baseline (`Ops::ErrorReporter`, standardized API error payload)
- [x] CI/CD pipeline baseline (security/lint/test + docker build smoke)
- [ ] App store prep (Google Play, Apple App Store)

---

## Immediate Next Execution (Rails Scope)

1. Maintain Rails voice-event contract as stable baseline for mobile handoff.
2. Run phase-level review + E2E gate when additional bridge actions are added.
3. Track non-Rails remaining items in mobile/app-store external gates.

## Open Decisions

- Native voice event auth model: web session-only vs signed mobile token.
- STT/TTS provider lock-in: Gemini Live only vs fallback provider strategy.
- Mobile repo ownership and handoff SLA for Android/iOS tracks.

---

## Dependency Graph

```
Phase 0 ✅
  └→ Phase 1 (Rails init)
       ├→ Phase 2 (Auth)
       ├→ Phase 3 (Models) → Phase 5 (VoiceChat) → Phase 6 (DEPTH)
       └→ Phase 4 (API Client)                        ├→ Phase 7 (Context)
                                                       └→ Phase 9 (Cable)
                                          Phase 7 → Phase 8 (Insight)
       Phase 2 + 8 + 9 → Phase 10 (UI) → Phase 11 (Jobs) + Phase 12 (Subscription)
                          → Phase 13 (Voice) → Phase 14 (P1 API) → Phase 15 (E2E) → Phase 16 (Deploy)
```

## Milestones

| Milestone | Phases | Description |
|-----------|--------|-------------|
| **M1: Core Foundation** | 0-2 | Project base + auth + models |
| **M2: API Integration** | 3-4 | OntologyRAG client + VoiceChat domain |
| **M3: VoiceChat Engine** | 5-8 | Phase transition + emotion + context + insight |
| **M4: Real-time & UI** | 9-10 | Action Cable + Turbo/Stimulus UI |
| **M5: Jobs & Subscription** | 11-12 | Background jobs + RevenueCat |
| **M6: Mobile & Voice** | 13-14 | Hotwire Native + P1 endpoints |
| **M7: Ship** | 15-16 | E2E tests + optimization + deploy |

## Risk Matrix

| Risk | Impact | Phase | Mitigation |
|------|:------:|:-----:|------------|
| Voice pipeline (Native Bridge) | 🔴 High | 13 | PoC first, alternative tech research |
| Gemini Live API streaming | 🔴 High | 13 | Stability monitoring, fallback design |
| Context model integration | 🟡 Med | 7 | Incremental build, stub L2/L4 initially |
| OntologyRAG API outage | 🟡 Med | 4,14 | Graceful degradation, local cache |
| Edge case gaps | 🟡 Med | 5,6 | TDD + Project_B code reference |

---

## References

| Document | Path |
|----------|------|
| CLAUDE.md (master guide) | `CLAUDE.md` |
| Full Korean PLAN | `docs/ref/20260212_05_PLAN_full_korean.md` |
| PRD | `docs/PRD.md` |
| LLD | `docs/LLD.md` |
| VoiceChat Engine v2 | `docs/ref/20251206_VoiceChat_Engine_Ideation_v2.md` |
| Architecture Insights | `docs/ref/20251222_Architecture_Integration_Insights.md` |
| Project_B Analysis | `docs/ondev/20260212_01_project_b_analysis.md` |
| Project_C Analysis | `docs/ondev/20260212_02_project_c_analysis.md` |
| Project_E API Analysis | `docs/ondev/20260212_03_project_e_api_analysis.md` |
| Migration Assessment | `docs/ondev/20260212_04_comprehensive_migration_assessment.md` |

---

*Each Phase's detailed plan is written as a separate doc when starting: `docs/ondev/YYYYMMDD_NN_phase_X_plan.md`*
*All Phases follow TDD (Red→Green→Refactor) cycle.*
*Last Updated: 2026-02-14*
