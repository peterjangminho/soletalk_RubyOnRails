# Project_A (SoleTalk) 종합 마이그레이션 평가 보고서

**작성일**: 2026-02-12
**목적**: Project_B 기반 마이그레이션 vs 신규 Ruby on Rails + Hotwire Native 프로젝트 구축 의사결정
**분석 대상**: Project_B (Kotlin/Android), Project_C (React Native/SookIntel), Project_E (OntologyRAG API)

---

## 목차

1. [요약 (Executive Summary)](#1-요약)
2. [분석 대상 프로젝트 개요](#2-분석-대상-프로젝트-개요)
3. [핵심 비교 분석](#3-핵심-비교-분석)
4. [마이그레이션 vs 신규 구축 비교](#4-마이그레이션-vs-신규-구축-비교)
5. [종합 권고안](#5-종합-권고안)
6. [구현 전략](#6-구현-전략)
7. [리스크 분석](#7-리스크-분석)
8. [참조 문서](#8-참조-문서)

---

## 1. 요약

### 결론: "정보 참조형 신규 구축" 권고

**Project_B의 코드를 직접 마이그레이션하는 것이 아니라, Project_B/C에서 비즈니스 로직과 도메인 지식을 추출하고, Ruby on Rails + Hotwire Native로 처음부터 새로 설계·구축하는 방식을 권고합니다.**

| 평가 항목 | 직접 마이그레이션 | 정보 참조형 신규 구축 |
|-----------|:--:|:--:|
| 기술 부채 해소 | ❌ 그대로 승계 | ✅ 클린 아키텍처 |
| 개발 속도 (초기) | ⚡ 빠름 | 🔄 보통 |
| 개발 속도 (중장기) | 🐌 느려짐 | ⚡ 가속됨 |
| Rails Convention 활용도 | ❌ 낮음 | ✅ 최대 활용 |
| 유지보수성 | ⚠️ 복잡 | ✅ 단순 |
| 코드 품질 | ⚠️ 혼재 | ✅ 일관 |
| **종합 권고** | **비권고** | **✅ 권고** |

### 핵심 근거 3가지

1. **아키텍처 패러다임 불일치**: Project_B는 Kotlin MVVM + React WebView 하이브리드 이중 구조이고, Rails + Hotwire Native는 서버 중심 단일 구조입니다. "마이그레이션"이라 하더라도 실질적으로 모든 코드를 재작성해야 합니다.

2. **기술 부채 승계 위험**: Project_B에는 TypeScript/Kotlin 간 50~90% 코드 중복, Context 모델 불일치(TS 7계층/32K vs Kotlin 5계층/100K), 하드코딩된 한국어 문자열 등의 기술 부채가 존재합니다. 마이그레이션 시 이를 그대로 가져오게 됩니다.

3. **비즈니스 로직 재사용율 95%**: Phase 전환 규칙, 감정/에너지 계산, Narrowing 서비스, DEPTH Q1-Q4 로직, Insight 생성 등 핵심 비즈니스 로직의 ~95%가 프레임워크 독립적인 순수 로직이므로, 코드가 아닌 "로직"을 참조하여 Ruby로 새로 작성하는 것이 효율적입니다.

---

## 2. 분석 대상 프로젝트 개요

### 2.1 Project_B (SoleTalk - Kotlin/Android + React WebView)

| 항목 | 내용 |
|------|------|
| **기술 스택** | Kotlin (Android MVVM) + React (WebView Hooks) |
| **코드 규모** | ~140+ 소스 파일 (Kotlin + TypeScript) |
| **핵심 비즈니스 파일** | ~30개 코어 파일 |
| **아키텍처** | 하이브리드 이중 레이어 (Native + WebView) |
| **핵심 컴포넌트** | VoiceChatManager.kt (~1,322줄) - 전체 VoiceChat 오케스트레이터 |
| **OntologyRAG 연동** | 깊음 - 40+ API 엔드포인트 |
| **기술 부채** | 중상 (레이어 중복, Context 모델 불일치, 하드코딩 한국어) |
| **테스트 성숙도** | 중간 (Kotlin ~60 테스트, TS ~5 테스트) |

**주요 발견 사항**:
- VoiceChatManager.kt가 5-Phase 상태 머신, DEPTH 트리거, Insight 생성, 세션 관리를 모두 담당하는 God Class 패턴
- TypeScript 서비스 레이어(phaseTransitionService, emotionEnergyService 등)에 순수 비즈니스 로직이 잘 분리되어 있음
- Context 모델이 TS(7계층/32K char)와 Kotlin(5계층/100K token)에서 이중 구현되어 불일치 발생
- 인증: Supabase Auth + 3단계 google_sub 폴백 → OmniAuth로 극적으로 단순화 가능

> 상세 분석: `docs/ondev/20260212_01_project_b_analysis.md`

### 2.2 Project_C (SookIntel - React Native/Expo)

| 항목 | 내용 |
|------|------|
| **기술 스택** | React Native (Expo SDK 54) + NativeWind + Supabase |
| **코드 규모** | ~256 소스 파일, ~180 테스트 파일, 19 Edge Functions |
| **핵심 서비스** | ontology-rag.service.ts (~1,545줄) - OntologyRAG 통합의 "골드 스탠다드" |
| **아키텍처** | Feature-based + Service Object 패턴 |
| **제품 성격** | 다중 사용자 협업 인텔리전스 플랫폼 (SoleTalk과 다른 도메인) |
| **OntologyRAG 연동** | 가장 포괄적 - 17+ API 메서드 |
| **복잡도** | 높음 (Container/SpiceDB/DSS/다중 AI 모델) |

**주요 발견 사항**:
- `ontology-rag.service.ts`가 OntologyRAG API 통합의 가장 완성된 레퍼런스
- Container 기반 데이터 구조 및 SpiceDB 권한 제어 → Project_A에서 불필요
- Decision Support System(DSS) → Project_A 범위 밖
- Edge Function 프록시 패턴 → Rails 서버사이드에서 직접 호출로 대체
- google_sub 크로스앱 식별 패턴이 잘 구현되어 있어 참조 가치 높음
- ENGC 이벤트 기록 패턴이 DEPTH Q1-Q4 추출 대상과 정확히 매핑됨

> 상세 분석: `docs/ondev/20260212_02_project_c_analysis.md`

### 2.3 Project_E (OntologyRAG - FastAPI)

| 항목 | 내용 |
|------|------|
| **기술 스택** | FastAPI + Neo4j + pgvector |
| **API 그룹** | 15+ 엔드포인트 그룹 |
| **인증** | X-API-Key 헤더 (sk_ 접두사, 32자) |
| **Rate Limit** | 1,000 req/hour per key |
| **핵심 엔드포인트** | /engine/users/identify, /engine/prompts, /engine/query, /incar/events/batch, /incar/conversations/save, /engine/voicechat |

**주요 발견 사항**:
- E/N/G/C 파라미터명은 **단수형** 확인 (`emotion`, `need`, `goal`, `constraint`)
- 프로파일 엔드포인트 2종: `/engine/prompts` (실시간, 느림) vs `/incar/profile` (캐시, 빠름)
- VoiceChat 3계층 엔드포인트: surface/depth/insight
- `/incar/*` 엔드포인트는 자동으로 `source_app: "incar"` 태깅
- `app_source` 값: `"incar_companion"` (Project_B 호환), `"sook_intel"` (Project_C)
- Faraday 기반 retry 전략 및 엔드포인트별 타임아웃 권장 사항 확인

> 상세 분석: `docs/ondev/20260212_03_project_e_api_analysis.md`

---

## 3. 핵심 비교 분석

### 3.1 아키텍처 비교

```
Project_B (AS-IS):
┌─────────────────────────────────────────┐
│          React WebView (TS)             │ ← UI + 일부 비즈니스 로직
├─────────────────────────────────────────┤
│        WebView Bridge (양방향)           │ ← 복잡한 브릿지 레이어
├─────────────────────────────────────────┤
│        Kotlin Android (MVVM)            │ ← Native 로직 + 중복 로직
├─────────────────────────────────────────┤
│  Supabase (Cloud DB) + OntologyRAG API  │ ← 외부 의존성
└─────────────────────────────────────────┘

Project_A (TO-BE):
┌─────────────────────────────────────────┐
│   Hotwire Native (Android/iOS)          │ ← 네이티브 쉘 (최소 코드)
├─────────────────────────────────────────┤
│   Rails Server (Turbo + Stimulus)       │ ← 모든 비즈니스 로직 (단일 레이어)
├─────────────────────────────────────────┤
│   SQLite + OntologyRAG API              │ ← 로컬 DB + 외부 API
└─────────────────────────────────────────┘
```

**핵심 차이점**: Project_B의 3~4 레이어 구조가 Project_A에서 2 레이어(Native 쉘 + Rails 서버)로 압축됩니다. 이 근본적인 아키텍처 차이 때문에 "코드 마이그레이션"은 사실상 "코드 재작성"과 동의어입니다.

### 3.2 비즈니스 로직 재사용 가능성

| 비즈니스 로직 | 소스 | 재사용율 | 비고 |
|--------------|------|:--------:|------|
| Phase 전환 규칙 | `phaseTransitionService.ts` | **95%** | 순수 로직, 직접 번역 가능 |
| 감정/에너지 계산 | `emotionEnergyService.ts` | **95%** | 순수 수학, 직접 번역 가능 |
| Narrowing 서비스 | `narrowingService.ts` | **90%** | 순수 로직, 한국어 템플릿 추출 필요 |
| Context 레이어 조합 | `contextOrchestrator.ts` | **85%** | 로직 재사용, 통합 모델 설계 필요 |
| 감성분석 프롬프트 | `sentimentAnalysisGemini.ts` | **80%** | 프롬프트 텍스트 100% 재사용 |
| OntologyRAG 상수 | `OntologyRAGConstants.kt` | **100%** | 직접 매핑 |
| E/N/G/C 데이터 모델 | `OntologyRAGModels.kt` | **90%** | 구조 직접 번역 |
| 시스템 프롬프트 | `constants.ts` | **100%** | 텍스트 그대로 복사 |
| Phase 전환 임계값 | `PHASE_TRANSITION_CONFIG` | **100%** | 값 그대로 복사 |

### 3.3 참조 불필요 (재사용 불가) 항목

| 컴포넌트 | 프로젝트 | 이유 |
|----------|---------|------|
| WebRTC 오디오 파이프라인 | Project_B | Android 플랫폼 특화 |
| WebView 브릿지 | Project_B | Hotwire Native로 제거 |
| Koin DI 모듈 | Project_B | Rails 자동 로딩으로 대체 |
| Room 데이터베이스 | Project_B | ActiveRecord로 대체 |
| React/Compose UI | Project_B | Turbo + Stimulus로 대체 |
| Supabase Auth/Client | Project_B/C | OmniAuth + ActiveRecord로 대체 |
| Edge Function 프록시 | Project_C | Rails 서버사이드 직접 호출 |
| Container/SpiceDB | Project_C | Rails 네이티브 권한 관리 |
| DSS (의사결정지원) | Project_C | Project_A 범위 밖 |
| RevenueCat/푸시알림 | Project_C | Expo 특화 기능 |

### 3.4 Project_C에서의 핵심 참조 포인트

Project_C는 도메인이 다르지만(협업 플랫폼 vs 음성 동반자), OntologyRAG 통합 패턴에서 높은 참조 가치를 가집니다:

| 우선순위 | 참조 대상 | Project_A 대응 |
|----------|----------|---------------|
| **P0** | google_sub 추출 패턴 | `Auth::GoogleSubExtractor` |
| **P0** | identifyUser API 패턴 | `OntologyRag::Client#identify_user` |
| **P1** | engineQuery/hybridQuery 패턴 | `OntologyRag::Client#query` |
| **P1** | ENGC 이벤트 기록 패턴 | `OntologyRag::Client#record_engc_event` |
| **P2** | 에러 처리 (success/error 패턴) | `OntologyRag::Models` 응답 클래스 |
| **P2** | Constants 구성 방식 | `OntologyRag::Constants` |
| **P3** | Feature Flag 패턴 | Rails configuration 또는 Flipper gem |

---

## 4. 마이그레이션 vs 신규 구축 비교

### 4.1 옵션 A: 직접 마이그레이션 (코드 포팅)

**접근 방식**: Project_B의 코드를 파일 단위로 Ruby로 변환

**장점**:
- 초기 진입 속도가 빠름 (변환 템플릿 있으면)
- 이미 검증된 비즈니스 로직 유지
- 엣지 케이스 처리가 이미 코드에 반영되어 있음

**단점**:
- ❌ Project_B의 이중 레이어 구조를 Rails에 억지로 맞추는 결과 초래
- ❌ VoiceChatManager.kt (1,322줄 God Class)의 기술 부채를 그대로 승계
- ❌ TS/Kotlin 간 Context 모델 불일치를 해결하지 않고 옮기게 됨
- ❌ Rails Convention over Configuration 철학과 충돌
- ❌ WebView 브릿지, Koin DI 등 제거해야 할 코드가 전체의 ~40%
- ❌ 하드코딩된 한국어 문자열, 환경 의존적 코드 등 기술 부채 승계
- ❌ "마이그레이션"이지만 실제로는 ~70% 이상을 재작성해야 함

**예상 소요**: 마이그레이션이라는 이름의 코드 변환이지만, 플랫폼 불일치로 인해 대부분의 코드를 재작성하게 되어 신규 구축 대비 시간 절감 효과가 미미합니다.

### 4.2 옵션 B: 정보 참조형 신규 구축 (권고안)

**접근 방식**: Project_B/C에서 비즈니스 로직, 도메인 모델, API 패턴, 상수/설정값을 추출하고, Rails + Hotwire Native에 최적화된 설계로 처음부터 구축

**장점**:
- ✅ Rails Convention에 완벽히 부합하는 클린 아키텍처
- ✅ Project_B의 이중 레이어 복잡성을 단일 Ruby 코드베이스로 해소
- ✅ Context 모델을 통합 설계할 수 있는 기회 (7계층/5계층 → 최적 모델)
- ✅ TDD 워크플로우를 처음부터 적용 가능
- ✅ Hotwire (Turbo Frames/Streams + Stimulus + Action Cable) 네이티브 활용
- ✅ Service Object 패턴으로 비즈니스 로직 깔끔하게 분리
- ✅ 기술 부채 제로 출발

**단점**:
- ⚠️ 초기 설계 시간 필요 (1~2주)
- ⚠️ 엣지 케이스를 새로 발견해야 할 수 있음 (Project_B 코드 참조로 완화 가능)
- ⚠️ 이미 해결된 문제를 다시 풀어야 하는 느낌이 들 수 있음

**예상 소요**: 초기 설계에 시간이 더 들지만, 중장기적으로 깨끗한 코드베이스 덕분에 개발 속도가 가속됩니다.

### 4.3 정량적 비교

| 평가 기준 | 가중치 | 직접 마이그레이션 | 신규 구축 |
|-----------|:------:|:-----------------:|:---------:|
| Rails 적합성 | 25% | 3/10 | **10/10** |
| 코드 품질 | 20% | 5/10 | **9/10** |
| 초기 개발 속도 | 15% | **7/10** | 5/10 |
| 중장기 유지보수 | 20% | 4/10 | **9/10** |
| 기술 부채 | 10% | 3/10 | **10/10** |
| 팀 온보딩 용이성 | 10% | 4/10 | **9/10** |
| **가중 평균** | 100% | **4.25/10** | **8.80/10** |

---

## 5. 종합 권고안

### 최종 권고: "정보 참조형 신규 구축 (Informed Fresh Build)"

#### 5.1 구축 방식

```
Phase 0: 지식 추출 (Knowledge Extraction)
├── Project_B → 비즈니스 로직, Phase 전환 규칙, DEPTH/Insight 도메인 모델
├── Project_C → OntologyRAG 통합 패턴, ENGC 이벤트 패턴, 에러 처리
└── Project_E → API 스펙, 엔드포인트 우선순위, 타임아웃/리트라이 설정

Phase 1~N: Rails 네이티브 구현 (TDD)
├── CLAUDE.md의 아키텍처 설계를 기반으로
├── 추출된 비즈니스 로직을 Ruby Service Object로 구현
├── Red → Green → Refactor 사이클 준수
└── 각 Phase별 문서화 및 커밋 규율 유지
```

#### 5.2 "참조"와 "복사"의 명확한 구분

**그대로 복사할 것 (Copy As-Is)**:
- 시스템 프롬프트 텍스트 (`VOICE_CHAT_ENGINE_SYSTEM_PROMPT`)
- 감성분석 프롬프트 텍스트
- Phase 전환 임계값/설정값 (`PHASE_TRANSITION_CONFIG`)
- OntologyRAG API 상수 (엔드포인트, 헤더)
- E/N/G/C 데이터 모델 구조
- 한국어 감정 키워드 목록
- Graph 관계 타입 정의

**로직을 참조하여 Ruby로 재작성할 것 (Reference & Rewrite)**:
- Phase 전환 엔진 (`phaseTransitionService.ts` → `VoiceChat::PhaseTransitionEngine`)
- 감정/에너지 추적 (`emotionEnergyService.ts` → `VoiceChat::EmotionTracker`)
- Narrowing 서비스 (`narrowingService.ts` → `VoiceChat::NarrowingService`)
- Context 오케스트레이터 (통합 설계 후 `VoiceChat::ContextOrchestrator`)
- DEPTH 탐색 (`DepthExploration.kt` → `DepthExploration` model + service)
- Insight 생성 (`Insight.kt` → `Insight::Generator` service)
- OntologyRAG HTTP 클라이언트 (`OntologyRAGClient.kt` → `OntologyRag::Client`)

**완전히 새로 설계할 것 (Design From Scratch)**:
- Hotwire Native 모바일 앱 구조
- Rails 컨트롤러/뷰 레이어 (Turbo Frames/Streams)
- Action Cable 실시간 통신 채널
- 인증 시스템 (OmniAuth)
- 데이터베이스 스키마 (ActiveRecord/SQLite)
- 오디오/음성 입출력 파이프라인 (Hotwire Native 네이티브 브릿지)
- 백그라운드 잡 아키텍처 (Solid Queue)

---

## 6. 구현 전략

### 6.1 추천 Phase 순서

| Phase | 범위 | 난이도 | 참조 소스 |
|-------|------|:------:|----------|
| **1. 기본 Rails 셋업** | 프로젝트 생성, Gemfile, 라우팅 | 낮음 | CLAUDE.md |
| **2. 인증** | OmniAuth Google → google_sub 추출 | 낮음 | Project_C authService.ts |
| **3. 핵심 모델** | User, Session, Message, Setting | 낮음 | Project_B domain/model/ |
| **4. OntologyRAG 클라이언트** | Faraday 기반 HTTP 클라이언트 + P0 엔드포인트 | 중간 | Project_C ontology-rag.service.ts, Project_E API 문서 |
| **5. VoiceChat 도메인 모델** | VoiceChatData, DepthExploration, Insight | 중간 | Project_B domain/depth/, domain/insight/ |
| **6. Phase 전환 엔진** | 5-Phase 상태 머신 + 전환 규칙 | 중간 | Project_B phaseTransitionService.ts |
| **7. 감정/에너지 시스템** | 감정 추적 + 에너지 계산 | 낮음 | Project_B emotionEnergyService.ts |
| **8. Narrowing 서비스** | 질문 타입 선택 + 좁히기 원칙 | 낮음 | Project_B narrowingService.ts |
| **9. Context 오케스트레이터** | 통합 레이어 모델 + 토큰 예산 | 중간 | Project_B contextOrchestrator.ts (통합 설계) |
| **10. DEPTH 레이어** | Q1-Q4 + Signal 감지 + Impact 분석 | 중상 | Project_B domain/depth/ |
| **11. Insight 생성** | LLM 기반 생성 + 자연어 변환 | 중간 | Project_B domain/insight/ |
| **12. 실시간 통신** | Action Cable + VoiceChat WebSocket | 높음 | 신규 설계 필요 |
| **13. UI (Turbo + Stimulus)** | 모든 뷰 + 인터랙티브 컴포넌트 | 중상 | 신규 설계 |
| **14. 백그라운드 잡** | E/N/G/C 배치 + 대화 저장 | 낮음 | Project_B/E API 패턴 |
| **15. 음성 파이프라인** | Hotwire Native 네이티브 브릿지 | 높음 | 신규 설계 (플랫폼별) |

### 6.2 OntologyRAG 통합 우선순위

Project_E 분석을 기반으로 한 엔드포인트 구현 우선순위:

**P0 (필수 - 앱 작동에 필수)**:
| 엔드포인트 | 메서드 | Rails 서비스 |
|-----------|--------|-------------|
| `/engine/users/identify` | POST | `OntologyRag::Client#identify_user` |
| `/engine/prompts/{google_sub}` | GET | `OntologyRag::Client#get_profile` |
| `/incar/events/batch` | POST | `EngcEventBatchJob` |
| `/incar/conversations/{session_id}/save` | POST | `ConversationSaveJob` |

**P1 (핵심 - VoiceChat 핵심 기능)**:
| 엔드포인트 | 메서드 | Rails 서비스 |
|-----------|--------|-------------|
| `/engine/query` | POST | `OntologyRag::Client#query` |
| `/incar/profile/{google_sub}` | GET | `OntologyRag::Client#get_cached_profile` |
| `/engine/voicechat` | POST | `VoiceChat::PhaseTransitionEngine` |
| `/engine/voicechat/surface` | POST | `VoiceChat::PhaseTransitionEngine` |
| `/engine/voicechat/depth` | POST | `VoiceChat::PhaseTransitionEngine` |
| `/engine/voicechat/insight` | POST | `VoiceChat::PhaseTransitionEngine` |

**P2 (확장 - 기능 완성도 향상)**:
| 엔드포인트 | 메서드 | Rails 서비스 |
|-----------|--------|-------------|
| `/engine/insights` | POST/GET | `Insight::Generator` |
| `/engine/search/similar` | POST | `OntologyRag::Client#search_similar` |
| `/incar/memories/store` | POST | `OntologyRag::Client#store_memory` |
| `/incar/memories/recall` | GET | `OntologyRag::Client#recall_memories` |

### 6.3 핵심 기술 결정 사항

| 결정 사항 | 권고 | 근거 |
|-----------|------|------|
| **Context 모델** | 5계층 통합 (CLAUDE.md 명세 기준) | TS 7계층과 Kotlin 5계층의 불일치를 해소하는 기회 |
| **app_source 값** | `"incar_companion"` 유지 | Project_B 호환성 유지, 기존 사용자 데이터 연결 |
| **프로파일 엔드포인트** | 세션 시작: `/incar/profile`, DEPTH 분석: `/engine/prompts` | 속도 vs 정확성 밸런스 |
| **E/N/G/C 파라미터** | 단수형 사용 (`emotion`, `need`, `goal`, `constraint`) | Project_E 소스코드에서 확인됨 |
| **인증 방식** | OmniAuth google_oauth2 → auth.uid = google_sub | 3단계 폴백 불필요, 직접 매핑 |
| **캐시 전략** | Rails.cache (Solid Cache) | Project_B의 Two-Level Cache를 Rails 표준으로 대체 |
| **VoiceChatManager 분할** | Service Object 패턴으로 6~8개 서비스로 분리 | God Class 해소 |

---

## 7. 리스크 분석

### 7.1 높은 리스크

| 리스크 | 영향도 | 완화 방안 |
|--------|:------:|----------|
| **오디오/음성 파이프라인** | 🔴 높음 | Hotwire Native에서 네이티브 브릿지로 구현해야 함. Project_B의 WebRTC는 재사용 불가. 초기 프로토타이핑으로 기술 검증 필요. |
| **실시간 통신 (Gemini Live API)** | 🔴 높음 | Action Cable로 WebSocket 구현 가능하나, Gemini Live API의 스트리밍 오디오 통합은 별도 설계 필요. |

### 7.2 중간 리스크

| 리스크 | 영향도 | 완화 방안 |
|--------|:------:|----------|
| **Context 모델 통합** | 🟡 중간 | 두 모델(7계층/5계층)을 신중하게 분석하고 최적 모델 설계. CLAUDE.md에 명시된 5계층을 기준으로 하되 필요시 조정. |
| **엣지 케이스 누락** | 🟡 중간 | Project_B 코드를 참조하면서 TDD로 점진적으로 커버. 특히 Phase 전환 조건과 DEPTH 진입 조건에 주의. |
| **LLM 통합 (Gemini)** | 🟡 중간 | Rails에서 Gemini API 호출은 단순하지만, 프롬프트 엔지니어링과 응답 파싱에 주의 필요. |

### 7.3 낮은 리스크

| 리스크 | 영향도 | 완화 방안 |
|--------|:------:|----------|
| **DB 마이그레이션** | 🟢 낮음 | SQLite + ActiveRecord는 Rails 기본. 스키마는 Project_B 도메인 모델에서 직접 도출. |
| **인증** | 🟢 낮음 | OmniAuth + Google OAuth2는 성숙한 솔루션. google_sub 추출은 단순 매핑. |
| **OntologyRAG 클라이언트** | 🟢 낮음 | Faraday 기반 HTTP 클라이언트는 표준적. Project_C/E에서 API 스펙 충분히 확보. |

---

## 8. 참조 문서

### 상세 분석 보고서

| 문서 | 경로 | 내용 |
|------|------|------|
| Project_B 분석 | `docs/ondev/20260212_01_project_b_analysis.md` | 1,098줄, 11개 섹션 - 아키텍처, 핵심 컴포넌트, 재사용성 평가 |
| Project_C 분석 | `docs/ondev/20260212_02_project_c_analysis.md` | ~935줄, 12개 섹션 - OntologyRAG 통합 패턴, 마이그레이션 비교 |
| Project_E API 분석 | `docs/ondev/20260212_03_project_e_api_analysis.md` | ~1,177줄, 8개 섹션 - 전체 API 스펙, Rails 통합 패턴 |

### 프로젝트 설계 문서

| 문서 | 경로 | 역할 |
|------|------|------|
| CLAUDE.md | `CLAUDE.md` | Project_A 마스터 설계 가이드 |
| VoiceChat Engine v2 | `docs/ref/20251206_VoiceChat_Engine_Ideation_v2.md` | 3계층 아키텍처 비전 |
| 3-Project 통합 계획 | `docs/ref/20251212_07_3project_integrated_development_plan.md` | 통합 아키텍처/API |
| Architecture Insights | `docs/ref/20251222_Architecture_Integration_Insights.md` | 도메인 모델/E2E 패턴 |

---

## 부록: 의사결정 요약표

| 질문 | 답변 |
|------|------|
| Project_B 코드를 직접 마이그레이션 할 것인가? | **아니오** - 아키텍처 패러다임이 근본적으로 다름 |
| Project_B에서 무엇을 가져올 것인가? | 비즈니스 로직 (Phase 전환, 감정/에너지, DEPTH/Insight), 상수/설정값, 프롬프트 텍스트 |
| Project_C에서 무엇을 가져올 것인가? | OntologyRAG 통합 패턴, google_sub 식별 패턴, ENGC 이벤트 패턴, 에러 처리 패턴 |
| 어떤 방식으로 프로젝트를 진행할 것인가? | Rails + Hotwire Native 네이티브 구축 (정보 참조형) |
| 개발 방법론은? | TDD (Red → Green → Refactor), Tidy First, CLAUDE.md 설계 기준 |
| 가장 큰 리스크는? | 오디오/음성 파이프라인 (Hotwire Native 네이티브 브릿지 필요) |
| app_source 값은? | `"incar_companion"` (Project_B 호환 유지) |

---

*본 보고서는 3개 프로젝트에 대한 상세 분석을 기반으로 작성되었으며, 향후 개발 진행 상황에 따라 업데이트될 수 있습니다.*
