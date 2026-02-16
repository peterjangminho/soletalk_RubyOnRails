# Phase 3: Microphone Button Parity

**Status**: [Not Started]
**Created**: 2026-02-16
**Master Plan**: `20260216_01_particle_sphere_ui_parity_master_plan.md`

---

## 목표

이모지(🎤) 기반 마이크 버튼을 Project_B와 동일한 SVG 아이콘 + 상태별 스타일 + long-press 지원 버튼으로 교체한다.

## 바이브코딩 원칙 체크리스트

- [ ] 원칙1 (일관된 패턴): Stimulus Controller + CSS 패턴 유지
- [ ] 원칙2 (One Source of Truth): 버튼 상태/스타일 단일 관리
- [ ] 원칙3 (하드코딩 금지): 색상/크기/타이밍 → CSS 변수 또는 상수
- [ ] 원칙4 (에러/예외): disabled 상태, 접근성(ARIA), long-press 힌트
- [ ] 원칙5 (SRP): 버튼 Stimulus Controller 단일 책임
- [ ] 원칙6 (공유 모듈): SVG 아이콘 인라인 재사용

## Kent Beck TDD Plan

### Test 1: SVG 마이크 아이콘 렌더링
```
RED:  mic 버튼 내부에 SVG path 렌더링 확인
GREEN: 인라인 SVG (Lucide Mic icon path) 삽입
REFACTOR: SVG를 partial로 분리
```

### Test 2: 상태별 스타일 전환
```
RED:  data-state 값에 따라 CSS 클래스 변경 (idle/active/muted/disabled)
GREEN: Stimulus controller stateValueChanged callback
REFACTOR: CSS 변수로 색상 관리
```

### Test 3: Long-Press 감지 (1초)
```
RED:  mousedown 1초 유지 → stop 이벤트 발생
GREEN: setTimeout(1000) + mousedown/mouseup handler
REFACTOR: touch 이벤트 동시 지원
```

### Test 4: Click vs Long-Press 구분
```
RED:  짧은 클릭 → toggle (start/pause/resume), 긴 클릭 → stop
GREEN: pressTimer 기반 분기
REFACTOR: N/A
```

### Test 5: Pulse 애니메이션
```
RED:  active/speaking 상태 → pulse 클래스 적용
GREEN: CSS @keyframes pulse + Stimulus toggle
REFACTOR: 기존 animate-pulse와 통합
```

### Test 6: 접근성 (ARIA)
```
RED:  aria-label이 상태에 따라 변경
GREEN: stateValueChanged 시 aria-label 업데이트
REFACTOR: long-press hint 추가
```

## 파일 변경 계획

| 파일 | 변경 내용 |
|------|-----------|
| `app/javascript/controllers/mic_button_controller.js` | 신규: Mic Button Stimulus Controller |
| `app/views/shared/_mic_button.html.erb` | 신규: SVG 마이크 버튼 partial |
| `app/views/home/index.html.erb` | 🎤 이모지 → partial 교체 |
| `app/views/sessions/show.html.erb` | 세션 내 마이크 버튼 통합 |
| `app/assets/stylesheets/application.css` | 마이크 버튼 CSS 업데이트 |
| `test/javascript/controllers/mic_button_controller_test.mjs` | 신규 |

## 버튼 상태 매핑 (Project_B 참조)

| 상태 | 배경색 | 아이콘 | ARIA Label |
|------|--------|--------|-----------|
| idle (미연결) | gray-700/50 | Mic (white) | "Start Conversation" |
| active (연결) | teal-500/30 | Mic (teal) | "Pause Conversation" |
| muted (일시정지) | yellow-500/30 | MicOff (yellow) | "Resume Conversation" |
| disabled (분석중) | opacity 50% | Mic | "Processing..." |

## 완료 기준

- [ ] 모든 TDD 테스트 통과 (6개)
- [ ] 이모지 대신 SVG 마이크 아이콘 표시
- [ ] 상태별 색상 변화 작동
- [ ] Long-press 1초로 세션 종료 가능
- [ ] ARIA label 동적 업데이트
- [ ] Pulse 애니메이션 작동
