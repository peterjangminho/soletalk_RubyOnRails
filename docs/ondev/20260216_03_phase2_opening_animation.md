# Phase 2: Opening Animation (Explosion → Reform)

**Status**: [Done]
**Created**: 2026-02-16
**Master Plan**: `20260216_01_particle_sphere_ui_parity_master_plan.md`
**Depends On**: Phase 1

---

## 목표

앱 로딩 시 파티클이 폭발한 뒤 3D 구형으로 재결합되는 오프닝 애니메이션을 구현한다. (Project_B `OpeningAnimation.tsx` 참조)

## 바이브코딩 원칙 체크리스트

- [x] 원칙1 (일관된 패턴): Stimulus Controller + Phase 1 엔진 재사용
- [x] 원칙2 (One Source of Truth): OPENING_CONFIG 단일 상수 객체
- [x] 원칙3 (하드코딩 금지): DURATION=5000, phases 비율 → OPENING_CONFIG
- [x] 원칙4 (에러/예외): Skip 버튼(aria-label), 타임아웃 안전장치(completionTimer)
- [x] 원칙5 (SRP): opening_animation_controller 전용, easing.js 분리
- [x] 원칙6 (공유 모듈): easing.js (easeInOutCubic, easeInCubic, lerp) 재사용 가능

## Kent Beck TDD Plan

### Test 1: 폭발 물리 시뮬레이션
```
RED:  explodeParticles(particles) → 각 파티클에 랜덤 velocity 부여
GREEN: velocity = random * explosionStrength, 매 프레임 *= 0.98 (감속)
REFACTOR: explosionStrength 상수 추출
```

### Test 2: 구형 재결합 (Reform)
```
RED:  reformParticles(particles, progress) → target 좌표로 수렴
GREEN: lerp with easeInOutCubic, progress 0~1
REFACTOR: easing 함수 별도 모듈로 분리
```

### Test 3: 회전 시작 트랜지션
```
RED:  rotationAtProgress(progress, rotationStart=0.7) → 70% 이후 회전 시작
GREEN: progress > rotationStart 시 rotationY 증가
REFACTOR: N/A
```

### Test 4: 페이드아웃 (배경색으로)
```
RED:  fadeOverlay(elapsed, duration, fadeDuration=500) → alpha 값 반환
GREEN: 마지막 500ms 동안 easeInCubic으로 alpha 증가
REFACTOR: N/A
```

### Test 5: Skip 버튼 (WCAG 2.2.2)
```
RED:  Skip 클릭 → onComplete 콜백 즉시 실행
GREEN: button onClick handler
REFACTOR: 접근성 속성 검증
```

### Test 6: 자동 완료 타이머
```
RED:  5초 후 → 오프닝 overlay 제거
GREEN: setTimeout(DURATION) + CSS transition
REFACTOR: 기존 CSS 오프닝과 통합
```

### Test 7: Stimulus Controller 통합
```
RED:  opening-animation controller connect → canvas + overlay 렌더링
GREEN: Phase 1 엔진 + explosion/reform 로직 통합
REFACTOR: 기존 home-opening-overlay CSS와 통합
```

## 파일 변경 계획

| 파일 | 변경 내용 |
|------|-----------|
| `app/javascript/controllers/opening_animation_controller.js` | 신규: 오프닝 애니메이션 Stimulus Controller |
| `app/javascript/lib/easing.js` | 신규: easing 함수 모듈 (easeInOutCubic, easeInCubic) |
| `app/views/home/index.html.erb` | 오프닝 overlay에 새 controller 적용 |
| `app/assets/stylesheets/application.css` | 오프닝 관련 CSS 조정 |
| `test/javascript/controllers/opening_animation_controller_test.mjs` | 신규 |
| `test/javascript/lib/easing_test.mjs` | 신규 |

## 타이밍 구조 (Project_B 참조)

```
0s ─────── 2s ────── 2.5s ───── 3.5s ───── 4.5s ── 5s
│ wait │ explosion │  reform  │ reform+rot │ fade │
│ 0-10%│  10-40%   │  40-70%  │  70-90%    │90-100│
```

## 완료 기준

- [x] 모든 TDD 테스트 통과 (8개 easing + opening animation, 64 total JS)
- [x] 파티클이 중앙에서 폭발 후 구형으로 재결합
- [x] Skip 버튼으로 즉시 건너뛰기 가능
- [x] 5초 후 자동으로 메인 화면 표시 (completionTimer)
- [x] 기존 CSS @keyframes 제거, JS 컨트롤러로 교체 완료
- [x] importmap 핀 설정 (lib/easing, lib/particle_sphere_engine)
- [x] Node.js 테스트 로더 업데이트 (lib/* 경로 해석)
