# 3-Project 통합 개발 계획서

> **작성일**: 2025-12-12
> **작성자**: Claude Opus 4.5
> **범위**: Project_E (OntologyRAG), Project_B (SoleTalk), Project_C (SookIntel)
> **목적**: 3개 프로젝트 현황 분석 및 향후 개발 방향 수립

---

## 1. Executive Summary

### 1.1 프로젝트 개요

| 프로젝트 | 역할 | 기술 스택 | 현재 상태 |
|----------|------|-----------|-----------|
| **Project_E** | 중앙 백엔드 허브 | FastAPI + Neo4j + pgvector + SpiceDB | Phase 27.2 완료 ✅ |
| **Project_B** | 차량 내 AI 컴패니언 | Kotlin/Android + React WebView | Phase 7 대기 (Pre-7 완료) |
| **Project_C** | 크로스플랫폼 채팅 앱 | React Native (Expo) + Supabase | Phase B-4b 진행중 |

### 1.2 통합 아키텍처

```
┌─────────────────────────────────────────────────────────────────────┐
│                        3-Project Integration                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐      │
│  │  Project_B   │      │  Project_C   │      │   (Future)   │      │
│  │  SoleTalk    │      │  SookIntel   │      │  Other Apps  │      │
│  │  (Android)   │      │ (RN/Expo)    │      │              │      │
│  └──────┬───────┘      └──────┬───────┘      └──────┬───────┘      │
│         │                     │                     │              │
│         │  OntologyRAGClient  │  Edge Functions     │              │
│         │  (Kotlin HTTP)      │  (Supabase Proxy)   │              │
│         │                     │                     │              │
│         └──────────┬──────────┴──────────┬──────────┘              │
│                    │                     │                         │
│                    ▼                     ▼                         │
│         ┌─────────────────────────────────────────┐                │
│         │           Project_E (OntologyRAG)        │                │
│         │                                          │                │
│         │  ┌─────────┐ ┌─────────┐ ┌─────────┐   │                │
│         │  │ Neo4j   │ │pgvector │ │ SpiceDB │   │                │
│         │  │ (Graph) │ │(Vector) │ │(Authz)  │   │                │
│         │  └─────────┘ └─────────┘ └─────────┘   │                │
│         │                                          │                │
│         │  API: Railway Production                 │                │
│         │  https://ontologyrag01-production        │                │
│         └─────────────────────────────────────────┘                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.3 공통 식별자: google_sub

```
┌─────────────────────────────────────────────────────────────────────┐
│                   Cross-App User Identification                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  google_sub: "123456789012345678901"                                │
│  ├── Project_B: AuthManager.getGoogleSubWithFallback()              │
│  │   └── JWT sub > user_metadata.sub > identities[google].id        │
│  │                                                                  │
│  ├── Project_C: googleSubService.getGoogleSub()                     │
│  │   └── Supabase user.identities[google].id (5분 캐시)            │
│  │                                                                  │
│  └── Project_E: identifyUser(google_sub, platform_id, domain)       │
│      └── UserIdentityRepository (Single Source of Truth)            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. 현재 상태 상세 분석

### 2.1 Project_E (OntologyRAG) - 중앙 백엔드

**완료된 주요 기능:**

| Phase | 기능 | 테스트 | 상태 |
|-------|------|--------|------|
| 24.1-24.5 | E/N/G/C Profile, External Info | 99 tests | ✅ 완료 |
| 25.1-25.5 | Neo4j Graph, Document Pipeline, Sync | 89 tests | ✅ 완료 |
| 26.1-26.5 | SpiceDB E2E (User/Container/Permission) | 31 tests | ✅ 완료 |
| 27.1-27.2 | Decision Neo4j Sync, Analytics API | 62 tests | ✅ 완료 |

**핵심 API Endpoints:**

```
/engine/identify              POST  - 사용자 식별
/engine/containers            CRUD  - 컨테이너 관리
/engine/objects               CRUD  - 객체 관리
/engine/events                POST  - 이벤트 기록
/engine/search/hybrid         POST  - 하이브리드 검색
/engine/documents             CRUD  - 문서 관리
/engine/graph/*               CRUD  - Neo4j 그래프 조작
/engine/decisions/*           CRUD  - Decision 관리
/engine/decisions/analytics   GET   - Decision 분석
/permissions/*                CRUD  - SpiceDB 권한
/admin/sync/*                 GET/POST - 동기화 관리
```

**테스트 현황:** 1,500+ tests passing

### 2.2 Project_B (SoleTalk) - Android AI 컴패니언

**코드 분석 결과:**

| 컴포넌트 | 파일 | 라인 | 역할 |
|----------|------|------|------|
| OntologyRAGClient | `OntologyRAGClient.kt` | ~600 | HTTP 클라이언트 (CRUD + 검색) |
| OntologyRAGHttpHelper | `OntologyRAGHttpHelper.kt` | ~200 | HTTP 추상화 (재시도, 타임아웃) |
| OntologyRAGModels | `OntologyRAGModels.kt` | ~300 | 데이터 모델 (Decision, Person, Relation) |
| OntologyRAGConstants | `OntologyRAGConstants.kt` | ~150 | 상수 관리 (하드코딩 금지) |
| AuthManager | `AuthManager.kt` | ~250 | google_sub 추출 (3-tier fallback) |
| VoiceChatManager | `VoiceChatManager.kt` | ~400 | VoiceChat 생명주기 + 그래프 연동 |

**구현된 기능:**
- ✅ OntologyRAGClient HTTP 구현 (24 tests)
- ✅ google_sub 추출 로직 (13 tests)
- ✅ Graph CRUD (Decision, Person, Relation)
- ✅ Graph Traversal + Decision Context
- ✅ VoiceChat 자동 Entity Extraction

**대기 중인 Phase 7 (Depth Layer):**

| Task | 설명 | 예상 테스트 |
|------|------|------------|
| T7.2 | DepthLayer API 클라이언트 | 10 tests |
| T7.3 | DepthLayer UseCase | 12 tests |
| T7.4 | DepthLayer Repository + Cache | 8 tests |
| T7.5 | DepthLayer ViewModel 통합 | 7 tests |

### 2.3 Project_C (SookIntel) - React Native 채팅 앱

**코드 분석 결과:**

| 컴포넌트 | 파일 | 라인 | 역할 |
|----------|------|------|------|
| ontology-rag.service | `ontology-rag.service.ts` | 943 | OntologyRAG API 통합 |
| permissionService | `permissionService.ts` | 250+ | SpiceDB 권한 관리 |
| authService | `authService.ts` | 665 | 인증 + 동의 관리 |
| googleSubService | `googleSubService.ts` | 108 | google_sub 추출 + 캐싱 |
| containerService | `containerService.ts` | 300+ | 컨테이너 CRUD + Shadow Mode |
| containerQueriesProjectE | `containerQueriesProjectE.ts` | 150+ | SpiceDB Primary Mode |

**구현된 기능:**
- ✅ OntologyRAG Edge Function 프록시
- ✅ google_sub 추출 (5분 캐시)
- ✅ SpiceDB Shadow Mode (로깅만)
- ✅ Container 기반 RAG 검색
- ✅ 파일 업로드 + OCR/STT 처리
- 🔄 SpiceDB Primary Mode (진행중)

**권한 관리 아키텍처:**

```typescript
// Phase B-4b: SpiceDB Primary Mode
async getContainerWithProjectE(containerId: string): Promise<ContainerResult> {
  // 1. google_sub 필수 확인
  const googleSub = await googleSubService.getGoogleSub();
  if (!googleSub) throw new Error('Google auth required');

  // 2. SpiceDB 권한 확인 (Primary Mode)
  const hasPermission = await permissionService.checkPermission({
    resourceType: 'container',
    resourceId: containerId,
    permission: 'read',
    subjectId: googleSub
  });

  if (!hasPermission) throw new PermissionDeniedError();

  // 3. Supabase에서 데이터 조회
  return { container, source: 'project_e', permissionSource: 'spicedb' };
}
```

---

## 3. 기술적 통합 분석

### 3.1 API 통합 현황

| API | Project_B | Project_C | Project_E |
|-----|-----------|-----------|-----------|
| `/engine/identify` | ✅ OntologyRAGClient | ✅ identifyCurrentUser() | ✅ 구현 |
| `/engine/containers` | ✅ createContainer() | ✅ containerService | ✅ 구현 |
| `/engine/objects` | ✅ CRUD 전체 | ✅ createObject() | ✅ 구현 |
| `/engine/events` | ✅ recordEvent() | ✅ recordENGCEvent() | ✅ 구현 |
| `/engine/search/hybrid` | ✅ hybridQuery() | ✅ hybridQuery() | ✅ 구현 |
| `/engine/documents` | ✅ createDocument() | ✅ createDocumentFromFile() | ✅ 구현 |
| `/engine/graph/*` | ✅ 전체 CRUD + Traverse | ❌ 미사용 | ✅ 구현 |
| `/engine/decisions/*` | ✅ 전체 CRUD | ❌ 미사용 | ✅ 구현 |
| `/permissions/*` | ❌ 미사용 | ✅ permissionService | ✅ 구현 |

### 3.2 데이터 모델 일관성

| 모델 | Project_B (Kotlin) | Project_C (TypeScript) | Project_E (Python) |
|------|-------------------|----------------------|-------------------|
| Decision | DecisionResponse | ❌ 미정의 | Decision (SQLAlchemy) |
| Person | PersonResponse | ❌ 미정의 | Object (type='person') |
| Container | ContainerResponse | Container | Container |
| Object | ObjectResponse | OntologyObject | Object |
| Relation | RelationResponse | OntologyRelation | Relation |
| Event | EventResponse | OntologyEvent | Event |

### 3.3 Vibe Coding 6원칙 준수 현황

| 원칙 | Project_B | Project_C | Project_E |
|------|-----------|-----------|-----------|
| Pattern Consistency | ✅ CRUD 패턴 일관 | ✅ Service 패턴 일관 | ✅ Repository 패턴 |
| Single Source of Truth | ✅ AuthManager | ✅ googleSubService | ✅ UserIdentityRepo |
| No Hardcoding | ✅ Constants 분리 | ✅ Api.ts 상수 | ✅ settings.py |
| Error Handling | ✅ Result<T> | ✅ try-catch + safeLog | ✅ HTTPException |
| Single Responsibility | ✅ 클래스별 분리 | ✅ 서비스별 분리 | ✅ 레이어별 분리 |
| Shared Components | ✅ ontologyrag 패키지 | ✅ services/ 폴더 | ✅ core/ 모듈 |

---

## 4. 우선순위 분석

### 4.1 의존성 그래프

```
┌─────────────────────────────────────────────────────────────────────┐
│                       Dependency Graph                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  [Project_E]  ◄── 없음 (독립적)                                     │
│       │                                                             │
│       ▼                                                             │
│  [Project_B]  ◄── Project_E API (Phase 7 Depth Layer)              │
│       │                                                             │
│       │       ◄── E1: Decision Neo4j Schema ✅ 완료                 │
│       │       ◄── E2: Decision Analytics API ✅ 완료                │
│       │                                                             │
│  [Project_C]  ◄── Project_E API (SpiceDB Primary Mode)             │
│       │                                                             │
│       │       ◄── Phase 26: SpiceDB E2E ✅ 완료                    │
│       │       ◄── Phase 25.4: listDocuments ✅ 완료                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 4.2 우선순위 매트릭스

| 순위 | 프로젝트 | 작업 | 이유 | 예상 시간 |
|------|----------|------|------|----------|
| **1** | Project_E | Phase 25.6 Graph Query 고도화 | B/C 모두 사용 | 8h |
| **2** | Project_C | Phase B-4b SpiceDB Primary 완료 | 보안 필수 | 6h |
| **3** | Project_B | Phase 7 Depth Layer (T7.2-T7.5) | 핵심 기능 | 20h |
| **4** | Project_C | Phase B-5 Write Path Migration | 데이터 일관성 | 12h |
| **5** | Project_E | Phase 28 Insight Layer | B 의존성 | 24h |

### 4.3 우선순위 결정 근거

1. **Project_E 우선**: 중앙 허브로서 B/C 모두의 기반. 안정성과 성능이 모든 앱에 영향.

2. **보안 우선 (Project_C SpiceDB)**: Shadow Mode에서 Primary Mode로 전환 시 실제 권한 검증 필요. 데이터 보안 문제.

3. **핵심 기능 (Project_B Depth Layer)**: 4 Core Questions (WHY/DECISION/IMPACT/DATA)가 제품 차별화 요소.

4. **데이터 일관성 (Project_C Write Path)**: Read는 SpiceDB Primary 완료 후, Write도 일관되게 적용 필요.

---

## 5. 개발 순서 (Sequential Work Order)

### Phase 1: 인프라 안정화 (Week 1)

```
Day 1-2: Project_E Phase 25.6 Graph Query 고도화
├── Cypher 쿼리 최적화
├── 인덱스 추가 (Node properties)
├── 복잡한 Traversal 성능 개선
└── 테스트: 10 unit + 3 E2E

Day 3-4: Project_C Phase B-4b SpiceDB Primary 완료
├── Container Read Path SpiceDB 적용
├── Object Read Path SpiceDB 적용
├── Feature Flag 전환 테스트
└── 테스트: 8 unit + 5 E2E

Day 5: 통합 테스트 및 문서화
├── E2E Cross-Project 테스트
├── 문서 업데이트 (current_state.md)
└── 다음 주 계획 수립
```

### Phase 2: 핵심 기능 구현 (Week 2-3)

```
Day 1-5 (Week 2): Project_B Phase 7 T7.2-T7.3
├── T7.2: DepthLayer API 클라이언트 (10 tests)
│   ├── generateDepthQuestion()
│   ├── saveDepthResponse()
│   ├── getDepthInsights()
│   └── detectDepthSignal()
│
└── T7.3: DepthLayer UseCase (12 tests)
    ├── DetectDepthSignalUseCase
    ├── GenerateQuestionUseCase
    ├── ProcessResponseUseCase
    └── GenerateInsightUseCase

Day 1-3 (Week 3): Project_B Phase 7 T7.4-T7.5
├── T7.4: Repository + Cache (8 tests)
│   ├── DepthRepository 인터페이스
│   ├── 캐시 구현 (TTL, 동시성)
│   └── 오프라인 지원
│
└── T7.5: ViewModel 통합 (7 tests)
    ├── DepthViewModel 상태 관리
    └── VoiceChatManager 연동

Day 4-5 (Week 3): Project_C Phase B-5 Write Path
├── Container Write Path SpiceDB 적용
├── Object Write Path SpiceDB 적용
├── Document Create Path 적용
└── 테스트: 10 unit + 5 E2E
```

### Phase 3: 고급 기능 (Week 4+)

```
Project_E Phase 28: Insight Layer (24h)
├── 인사이트 생성 엔진
├── 외부 정보 통합 (Tavily API)
├── 행동 가이드 템플릿
└── Project_B 연동

Project_C Phase C: 완전 통합
├── 모든 API Primary Mode 전환
├── 레거시 코드 제거
├── 성능 최적화
└── 보안 감사 완료
```

---

## 6. 리스크 관리

### 6.1 기술적 리스크

| 리스크 | 영향 | 확률 | 완화 전략 |
|--------|------|------|----------|
| Neo4j 쿼리 성능 | 높음 | 중간 | 인덱스 최적화, 쿼리 캐싱 |
| SpiceDB Primary 전환 버그 | 높음 | 낮음 | Shadow Mode 병행, 점진적 전환 |
| Cross-App 동기화 지연 | 중간 | 중간 | SyncCoordinator 모니터링 |
| google_sub 추출 실패 | 높음 | 낮음 | 3-tier fallback, 로깅 강화 |

### 6.2 일정 리스크

| 리스크 | 영향 | 확률 | 완화 전략 |
|--------|------|------|----------|
| Project_B Phase 7 지연 | 높음 | 중간 | TDD로 점진적 진행, 모듈화 |
| E2E 테스트 불안정 | 중간 | 중간 | Retry 로직, 테스트 격리 |
| 문서화 지연 | 낮음 | 높음 | 코드와 동시 업데이트 |

---

## 7. 성공 지표 (KPIs)

### 7.1 기술적 지표

| 지표 | 목표 | 현재 |
|------|------|------|
| Project_E 테스트 커버리지 | 85% | ~80% |
| Project_B 테스트 수 | 280 | 230 |
| Project_C 테스트 수 | 50 | 43 (보안 감사) |
| E2E 테스트 성공률 | 100% | 100% |
| API 응답 시간 (P95) | < 500ms | 측정 필요 |

### 7.2 통합 지표

| 지표 | 목표 | 현재 |
|------|------|------|
| Cross-App 식별 성공률 | 99.9% | 측정 필요 |
| SpiceDB 권한 검증 정확도 | 100% | Shadow Mode |
| 동기화 지연 시간 | < 1분 | 측정 필요 |

---

## 8. 결론 및 권장 사항

### 8.1 즉시 실행 항목

1. **Project_E Phase 25.6** 시작 - Graph Query 성능이 모든 앱에 영향
2. **Project_C SpiceDB Primary Mode** 완료 - 보안 필수 요건
3. **Cross-Project E2E 테스트** 구축 - 통합 품질 보장

### 8.2 장기 전략

1. **API 버전 관리** 도입 - 하위 호환성 유지
2. **모니터링 대시보드** 구축 - 3개 프로젝트 통합 현황
3. **문서 자동화** - OpenAPI 스펙 기반 타입 생성

### 8.3 프로젝트별 다음 단계

| 프로젝트 | 다음 작업 | 담당 | 예상 시간 |
|----------|----------|------|----------|
| Project_E | Phase 25.6 Graph Query 고도화 | Sonnet | 8h |
| Project_B | Phase 7 T7.2 DepthLayer API | Sonnet | 10h |
| Project_C | Phase B-4b SpiceDB Primary 완료 | Sonnet | 6h |

---

## 9. 참조 문서

| 문서 | 경로 | 용도 |
|------|------|------|
| 통합 가이드 | `/Project_E/docs/key/20251210_Unified_Permission_DB_Management_Guide.md` | 권한/DB 통합 |
| VoiceChat 비전 | `/Project_E/docs/ref/00.VoiceChat_Engine_Ideation_v2.md` | 4 Core Questions |
| TDD 방법론 | `/Project_E/docs/ref/01.KentBeck_TDD.md` | 개발 워크플로우 |
| Vibe Coding | `/Project_E/docs/ref/01.바이브코딩원칙.md` | 코드 품질 |

---

**문서 버전**: v1.0
**최종 검토**: 2025-12-12
**다음 업데이트**: 주간 (매주 금요일)
