# Project_A Voice-Only UI 전환 워크플로우 계획서

작성일: 2026-02-17  
대상 프로젝트: `Project_A`  
목적: Project_A UI를 음성대화 전용 앱 의도로 재정렬하고, 불필요한 텍스트/세션 중심 화면을 정리하는 실행 계획 확정

---

## 1) 요청 배경 요약

사용자 요구사항:

1. 구현 의도는 "음성대화 앱 전용"
2. 파일 업로드 목적은 "대화에 필요한 파일을 제공해 NotebookLM처럼 대화 grounding"
3. 디자인 포커스:
- 음성 반응형 파티클 구체
- 마이크 아이콘과 상태 UI
- 업로드 전용 페이지 없이 아이콘 클릭 즉시 파일 선택
- 파일 선택 후 유저 확인 UI 추가
4. 설명 페이지는 Project_B와 동일한 구성
5. 현재 Project_A의 불필요 요소 제거:
- 텍스트 대화/세션 저장 화면 노출 축소
- 설정 화면 상단 아이콘/불필요 박스 버튼 정리
- 스크린샷 붉은 영역(상단 브랜드 블록 + 세션/인사이트/설정 칩 네비) 제거

---

## 2) 탐색 기반 현재 상태 진단

확인 파일:

- `app/views/home/index.html.erb`
- `app/views/sessions/show.html.erb`
- `app/views/sessions/index.html.erb`
- `app/views/insights/index.html.erb`
- `app/views/settings/show.html.erb`
- `app/views/shared/_top_nav.html.erb`
- `app/javascript/controllers/mic_button_controller.js`
- `app/javascript/controllers/native_bridge_controller.js`
- `app/javascript/controllers/particle_sphere_controller.js`

진단 결과:

1. Home 로그인 후 메인 화면은 파티클/마이크 중심에 가깝지만 업로드가 `settings#uploads`로 이동되는 구조
2. `sessions/show`는 메시지 목록 + 텍스트 입력폼 + 디버그 패널 중심으로 음성 전용 UX와 불일치
3. `sessions/index/new`, `insights/index/show`는 음성 단일 앱 관점에서 노출 우선순위가 낮음
4. Settings는 기능 밀도가 높고, 상단 및 섹션 구조가 Project_B UI 의도와 다름
5. 업로드는 설정 화면에서 파일 선택 후 submit 형태이며 즉시 대화 반영 UX가 약함

---

## 3) 사용자와 확정한 결정사항

대화 중 확정된 사항:

1. 범위: `UI + 라우트 정리`
2. 설명 페이지 반영 방식: `모달 + 설정 안내 섹션 둘 다`
3. 업로드 확인 UI: `하단 시트`
4. 세션 저장 정책: `내부 저장 유지`
5. 설정 화면 범위: `언어 + 데이터 + 계정 + 구독`
6. 설명 문구 정책: `Project_B 문구 거의 동일`

---

## 4) 적용 워크플로우 스킬

이번 계획은 다음 스킬 원칙을 적용:

1. `sub-plan-skill`
- Phase를 작은 실행 단위로 분리
- 각 단계에 Objective/Scope/TDD/Validation 포함

2. `tdd-workflow`
- Red -> Green -> Refactor 강제
- 구조 변경(Structural)과 동작 변경(Behavioral) 분리

### 4-1) Kent Beck TDD 운영 규칙 (필수)

본 작업의 모든 기능 변경은 아래 순서를 반드시 따른다.

1. Red
- 테스트를 먼저 작성한다.
- "기능 미구현" 때문에 실패하는지 확인한다.
- 환경/문법/설정 오류로 실패하면 Red로 인정하지 않는다.

2. Green
- 테스트를 통과시키는 최소 코드만 작성한다.
- 한 번에 한 동작만 통과시킨다.
- 추가 기능/리팩터링을 끼워 넣지 않는다.

3. Refactor
- 테스트가 green인 상태에서만 구조 개선을 한다.
- 동작 변경 없이 가독성/중복/책임 분리를 수행한다.
- 리팩터링 후 관련 테스트를 다시 실행한다.

### 4-2) 바이브코딩 6대 원칙 적용 매트릭스

| 원칙 | 이번 작업 적용 방식 | 검증 포인트 |
|---|---|---|
| P1 패턴 일관성 | Rails MVC + Service + Stimulus 패턴 유지 | 컨트롤러에 비즈니스 로직 없음 |
| P2 OSOT | 마이크/파티클 상태를 단일 상태 소스로 통합 | 상태 상수 중복 제거 |
| P3 하드코딩 금지 | 파일 제한/상태문구/분기 상수화 | 매직넘버/문자열 제거 |
| P4 에러 처리 | 업로드/브릿지/모달 실패 경로 구현 | 사용자 알림 + 에러 경로 테스트 |
| P5 SRP | `voice_stage`, `quick_upload`, `policy_modal` 책임 분리 | 컨트롤러 단일 책임 유지 |
| P6 공유 자산 | 공용 partial/controller/service 재사용 | 화면별 중복 코드 축소 |

### 4-3) 세부 실행 지침 (SOP)

각 Phase는 아래 SOP를 반복한다.

1. 다음 미체크 테스트 항목 1개 선택
   - 사용자가 `go`라고 입력하면 반드시 이 단계부터 시작한다.
2. Red 테스트 추가 및 실패 확인
3. Green 최소 구현으로 통과
4. Refactor(구조 변경만) 수행
5. 관련 테스트 재실행
6. 체크리스트/문서 상태 동기화

### 4-4) Structural / Behavioral 분리 지침

1. Structural 커밋
- 리네이밍/추출/파일이동/상수화 등 동작 불변 변경만 포함

2. Behavioral 커밋
- 실제 동작 변경(라우트 정책, 업로드 플로우, UI 상태 전이 등)만 포함

3. 금지
- Structural + Behavioral 혼합 커밋

### 4-5) 공통 테스트 명령 (기준)

```bash
bin/rails test test/integration/home_flow_test.rb
bin/rails test test/integration/settings_flow_test.rb
bin/rails test test/integration/e2e_voicechat_flow_test.rb
bin/rails test test/integration/subscription_flow_test.rb
bin/rails test
npm run test:js
```

### 4-6) Phase 완료 게이트 (공통 DoD)

각 Phase는 아래 조건을 모두 만족할 때 완료 처리한다.

1. Red/Green/Refactor 증적이 남아 있음
2. 해당 Phase 테스트가 green
3. 실패 경로(에러 UX 포함) 검증 완료
4. 다음 Phase 시작 전 문서 체크리스트 동기화 완료

---

## 5) 목표 UX/IA (To-Be)

### 핵심 IA

1. 사용자 진입: `GET /` 단일 진입
2. 메인: 파티클 구체 + 마이크 + 상단 우측 아이콘(업로드/설정)
3. 업로드: 아이콘 클릭 -> 파일 선택 -> 하단 시트 확인 -> 대화 반영
4. 설정: Project_B 스타일 단순 섹션형(언어/데이터/계정/구독)
5. 설명: Project_B 동일 구조의 정책/약관 모달 + 설정 내 안내

### 비노출 대상

1. 텍스트 메시지 입력 중심 화면
2. 세션/인사이트 목록 중심 탐색 동선

주의:

- 내부 세션/메시지 저장은 유지(서비스 품질/문맥 유지용)
- "사용자 노출 UI"만 음성 전용으로 축소

---

## 6) 상세 실행 계획 (Phase별)

## Phase 0. Baseline 고정

Objective:
- 변경 전후 회귀 기준을 고정

작업:

1. 영향 테스트 목록 고정:
- `test/integration/home_flow_test.rb`
- `test/integration/settings_flow_test.rb`
- `test/integration/e2e_voicechat_flow_test.rb`
- `test/integration/subscription_flow_test.rb`
- 기존 세션/인사이트 플로우 테스트는 리디자인 기준으로 갱신 대상 지정

TDD:

- Red: 새 IA 기준 테스트 먼저 추가
- Green: 기존 코드로 실패 확인
- Refactor: 공통 헬퍼 정리

세부 체크리스트:

- [ ] UI 축소 기준 테스트 1개 이상 추가
- [ ] baseline 테스트 실행 결과 기록
- [ ] 실패 원인 분류(기능 미구현/테스트 노후화)

---

## Phase 1. 라우트/노출 화면 축소 (UI+라우트)

Objective:
- 음성 전용 사용자 동선으로 정리

작업 파일:

1. `config/routes.rb`
2. `app/controllers/sessions_controller.rb`
3. `app/controllers/home_controller.rb`
4. `app/views/shared/_top_nav.html.erb`

구현 방향:

1. 세션/인사이트 직접 노출 동선 제거 또는 안전 리다이렉트
2. 상단 내비에서 세션/인사이트 버튼 제거
3. Home에서 음성 메인으로 직접 진입
4. 상단 브랜드 블록/칩 네비 자체를 사용자 화면에서 제거

TDD:

- Red:
  - 인증 사용자 `GET /`에서 음성 메인 요소만 노출 확인
  - `/sessions*`, `/insights*` 접근 시 리다이렉트/차단 확인
- Green:
  - 최소 라우트/컨트롤러 수정으로 통과
- Refactor:
  - 더 이상 쓰지 않는 link/i18n 정리

세부 체크리스트:

- [ ] 상단 내비에서 sessions/insights 진입 제거
- [ ] `/sessions*`, `/insights*` 접근 정책 구현
- [ ] 관련 i18n 키 정리
- [ ] 라우팅 회귀 테스트 통과
- [ ] 스크린샷 붉은 영역(브랜드 + 칩 네비) 제거 확인

---

## Phase 2. Home Voice Stage 완성

Objective:
- 텍스트 대화 UI 제거, 파티클/마이크 중심화

작업 파일:

1. `app/views/home/index.html.erb`
2. `app/assets/stylesheets/application.css`
3. `app/views/shared/_mic_button.html.erb`
4. `app/javascript/controllers/mic_button_controller.js`
5. 신규 `app/javascript/controllers/voice_stage_controller.js`

구현 방향:

1. 마이크 상태와 파티클 상태를 단일 상태머신으로 동기화
2. 마이크 위치 하단 중앙 고정
3. 상태 텍스트 최소화

TDD:

- Red:
  - 마이크 상태 전환 시 파티클 상태 갱신 테스트
  - 브릿지 미사용 환경 fallback 테스트
- Green:
  - 상태 동기화 최소 구현
- Refactor:
  - 상태 상수/라벨 상수 단일화

세부 체크리스트:

- [ ] Home에서 텍스트 대화 UI 제거
- [ ] 마이크 상태와 파티클 상태 동기화
- [ ] 브릿지 불가 환경 fallback 표시
- [ ] 모바일 뷰포트에서 마이크 위치 확인

---

## Phase 3. 업로드 즉시 선택 + 하단 시트 확인

Objective:
- 업로드 전용 페이지 제거, Home에서 즉시 업로드 UX 완성

작업 파일:

1. `app/views/home/index.html.erb`
2. 신규 `app/javascript/controllers/quick_upload_controller.js`
3. 신규 `app/controllers/voice/context_files_controller.rb`
4. 신규 `app/services/voice/context_file_upload_service.rb`
5. `app/controllers/settings_controller.rb` (중복 업로드 경로 정리)

구현 방향:

1. 업로드 아이콘 클릭 시 hidden file input 트리거
2. 파일 선택 후 하단 시트에서 목록/개수/용량 확인
3. "대화에 반영" 클릭 시 업로드 + context 반영
4. 취소 시 아무 변경 없이 닫힘

TDD:

- Red:
  - 파일 선택 시 하단 시트 렌더 테스트
  - confirm/cancel 분기 테스트
  - 업로드 API 성공/실패 테스트
- Green:
  - 단일 파일 시나리오 우선 통과
- Refactor:
  - 파일 검증/에러 메시지 상수화

세부 체크리스트:

- [ ] 업로드 아이콘 -> 파일 선택기 즉시 오픈
- [ ] 파일 선택 후 하단 시트 렌더
- [ ] 확인 버튼 시 업로드 + 대화 반영 API 호출
- [ ] 취소 버튼 시 상태 원복
- [ ] 실패 시 사용자 오류 메시지 노출

---

## Phase 4. 파일 기반 대화 Grounding 연결

Objective:
- 업로드 파일이 실제 음성 대화 컨텍스트에 포함되도록 연결

작업 파일:

1. `app/services/voice_chat/context_orchestrator.rb`
2. 신규 `app/services/voice_chat/uploaded_file_context_builder.rb`
3. `app/services/voice/event_processor.rb`
4. `app/services/ontology_rag/client.rb` (필요 시 payload 확장)

구현 방향:

1. 텍스트/문서 파일은 요약 또는 메타 추출 후 컨텍스트 레이어 삽입
2. 파일 없는 경우 기존 컨텍스트 흐름 유지
3. 내부 세션 저장은 유지

TDD:

- Red:
  - 파일 존재 시 context layer 반영 검증
  - 파일 없음 fallback 검증
  - unsupported/oversize error path 검증
- Green:
  - 최소 빌더 구현 후 오케스트레이터 연동
- Refactor:
  - 책임 분리 및 cache key 정리

세부 체크리스트:

- [ ] 업로드 파일 컨텍스트 레이어 빌드
- [ ] 파일 없는 경우 기존 로직 유지
- [ ] 파일 타입/크기 오류 처리
- [ ] context cache 정책 검증

---

## Phase 5. 설명 페이지(Project_B 동일) 이중 경로 반영

Objective:
- 정책/설명 접근성을 모달 + 설정 안내 모두에서 제공

작업 파일:

1. 신규 `app/views/shared/_policy_modal.html.erb`
2. 신규 `app/javascript/controllers/policy_modal_controller.js`
3. `app/views/onboarding/consent.html.erb`
4. `app/views/settings/show.html.erb`
5. `config/locales/ko.yml`
6. `config/locales/en.yml`

구현 방향:

1. 섹션 구성/문구/링크는 Project_B와 최대한 동일
2. 설정 화면에서도 동일 정책 접근 링크 제공

TDD:

- Red:
  - 모달 열기/닫기/escape/포커스 이동 테스트
  - 정책/약관 링크 유효성 테스트
- Green:
  - 최소 마크업 + 컨트롤러 구현
- Refactor:
  - i18n 키 정규화

세부 체크리스트:

- [ ] 모달 콘텐츠/링크 구조를 Project_B와 정합화
- [ ] 설정 화면에 동일 정책 안내 진입점 추가
- [ ] escape/포커스 이동 접근성 검증
- [ ] ko/en i18n 키 동기화

---

## Phase 6. 설정 화면 Project_B 스타일 정렬 (구독 유지)

Objective:
- 설정 화면의 시각 구조를 Project_B에 맞춤

작업 파일:

1. `app/views/settings/show.html.erb`
2. `app/assets/stylesheets/application.css`
3. 필요 시 `app/views/shared/_top_nav.html.erb`

구현 방향:

1. 불필요 상단 박스 버튼 제거
2. 섹션은 언어/데이터/계정/구독 유지
3. 상호작용 버튼 스타일/배치 단순화
4. 음성 전용 동선 화면에서 legacy top-nav 재노출 방지

TDD:

- Red:
  - 섹션 존재/버튼 구조 회귀 테스트
  - 구독 섹션 보존 테스트
- Green:
  - 뷰 구조 변경 최소 구현
- Refactor:
  - 공용 스타일 정리

세부 체크리스트:

- [ ] 상단 불필요 박스 버튼 제거
- [ ] 언어/데이터/계정/구독 4섹션 유지
- [ ] Project_B 스타일 버튼/카드 톤 정렬
- [ ] settings 회귀 테스트 통과
- [ ] Home/설정/보조 화면에서 top-nav 미노출 검증

---

## 7) 테스트 시나리오 (최종 검증)

1. 메인 음성 UX
- 로그인 후 Home에서 파티클/마이크/업로드/설정만 보임

2. 라우팅
- 사용자 직접 접근으로 세션/인사이트 페이지 진입 불가 또는 리다이렉트

3. 업로드 UX
- 아이콘 클릭 -> 파일 선택 -> 하단 시트 확인 -> 대화 반영 성공
- 취소 시 미반영

4. 파일 grounding
- 업로드 파일이 대화 컨텍스트에 반영됨

5. 설명 페이지
- 모달과 설정 안내 둘 다 접근 가능
- 정책/약관 링크 정상

6. 설정
- Project_B 스타일의 단순 섹션형
- 구독 섹션 유지

---

## 8) 수용 기준 (Acceptance Criteria)

1. 사용자 관점에서 앱이 음성대화 전용 UI로 동작
2. 텍스트 대화/세션 중심 UI 노출 제거
3. 업로드 전용 페이지 없이 즉시 파일 선택 + 하단 시트 확인
4. Project_B 동일 구조 설명 콘텐츠 제공(모달+설정)
5. 내부 세션 저장은 유지되어 백엔드 문맥 품질 보존
6. 관련 통합 테스트 모두 green
7. 스크린샷 기준 상단 브랜드+칩 네비 영역이 사용자 화면에서 제거됨

---

## 9) 리스크 및 대응

1. 라우트 정리로 기존 테스트 대량 실패 가능
- 대응: Phase 0에서 회귀 목록 고정, 단계별 갱신

2. 업로드 즉시 UX와 기존 settings 업로드 경로 충돌
- 대응: 단일 업로드 서비스로 통합

3. 정책 문구 이식 시 i18n 키 충돌
- 대응: 신규 namespace 분리 후 최종 merge

4. 음성 브릿지 환경 차이(웹/안드로이드)
- 대응: bridge unavailable fallback 상태 테스트 우선

---

## 10) 실행 순서

1. Phase 0 (Baseline)
2. Phase 1 (라우트/노출 축소)
3. Phase 2 (Voice stage)
4. Phase 3 (Quick upload + bottom sheet)
5. Phase 4 (Grounding 연결)
6. Phase 5 (설명 페이지 이중 반영)
7. Phase 6 (설정 정렬)

---

## 11) 참고 근거 파일

Project_A:

- `app/views/home/index.html.erb`
- `app/views/sessions/show.html.erb`
- `app/views/settings/show.html.erb`
- `app/views/shared/_top_nav.html.erb`
- `app/javascript/controllers/mic_button_controller.js`
- `app/javascript/controllers/native_bridge_controller.js`
- `app/javascript/controllers/particle_sphere_controller.js`
- `config/routes.rb`

Project_B 기준:

- `components/MainView.tsx`
- `components/ControlPanel.tsx`
- `components/SettingsView.tsx`
- `components/UploadView.tsx`
- `src/components/PrivacyPolicyModal.tsx`
