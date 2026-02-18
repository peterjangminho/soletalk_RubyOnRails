# Phase 4: Voice-Reactive Particle Behavior

**Status**: [Done]
**Created**: 2026-02-16
**Master Plan**: `20260216_01_particle_sphere_ui_parity_master_plan.md`
**Depends On**: Phase 1

---

## 목표

파티클 구형이 음성 입력 볼륨과 봇 상태에 반응하여 동적으로 변화하도록 구현한다. (Project_B ParticleSphere의 volume-reactive 동작 재현)

## 바이브코딩 원칙 체크리스트

- [x] 원칙1 (일관된 패턴): particle_sphere_engine.js 확장, controller values 활용
- [x] 원칙2 (One Source of Truth): volume/status → Stimulus values
- [x] 원칙3 (하드코딩 금지): DISPLACEMENT_FACTOR=20, alpha multiplier=5 → 상수
- [x] 원칙4 (에러/예외): volume=0 → 원본 좌표 반환, dist=0 방어
- [x] 원칙5 (SRP): displaceParticle 순수 함수로 분리
- [x] 원칙6 (공유 모듈): displaceParticle export, controller에서 재사용

## Kent Beck TDD Plan

### Test 1: 볼륨 기반 파티클 Displacement
```
RED:  displace(particle, volume, time) → radius + volume * DISPLACEMENT_FACTOR
GREEN: displacement = volume * 20 * (0.5 + sin(phi * 3 + time * 0.005) * 0.5)
REFACTOR: DISPLACEMENT_FACTOR 상수 추출
```

### Test 2: 상태별 회전 속도
```
RED:  rotationSpeed(status, time) → status에 따른 회전 속도 반환
GREEN: IDLE=0.002, THINKING=pulsing, SPEAKING=faster rhythmic
REFACTOR: 상태 맵으로 정리
```

### Test 3: LISTENING 모드 색상 변화
```
RED:  particleColor(status, volume) → LISTENING 시 밝기 증가
GREEN: alpha *= min(1, volume * 5), 1% 확률 cyan sparkle
REFACTOR: N/A
```

### Test 4: 볼륨 0일 때 기본 동작
```
RED:  volume=0 → displacement 없음, 정상 구형 유지
GREEN: displacement = 0 when volume = 0
REFACTOR: N/A
```

### Test 5: Stimulus value 연동
```
RED:  data-particle-sphere-volume-value 변경 → 파티클 반응
GREEN: volumeValueChanged callback에서 현재 볼륨 업데이트
REFACTOR: Action Cable subscription과 연동
```

### Test 6: 상태 전환 시 부드러운 트랜지션
```
RED:  status 변경 → 급격한 변화 없이 lerp로 전환
GREEN: 이전 속도 → 새 속도 lerp (0.1 factor)
REFACTOR: N/A
```

## 파일 변경 계획

| 파일 | 변경 내용 |
|------|-----------|
| `app/javascript/lib/particle_sphere_engine.js` | 볼륨/상태 반응 함수 추가 |
| `app/javascript/controllers/particle_sphere_controller.js` | volume/status Stimulus values 추가 |
| `app/views/sessions/show.html.erb` | volume/status data attributes 연결 |
| `test/javascript/lib/particle_sphere_engine_test.mjs` | 볼륨/상태 테스트 추가 |

## Project_B 참조 동작

```javascript
// Volume-reactive displacement (LISTENING mode only)
if (status === 'listening') {
  displacement = volume * 20 * (0.5 + Math.sin(particle.phi * 3 + time * 0.005) * 0.5)
}

// Status-based rotation speed
const speeds = {
  idle: 0.002,
  thinking: 0.001 + Math.sin(time * 0.001) * 0.003,  // pulsing
  speaking: 0.003 + Math.cos(time * 0.002) * 0.002,   // rhythmic
  listening: 0.002                                      // default
}
```

## 완료 기준

- [x] 모든 TDD 테스트 통과 (4개 추가, 17 total engine, 77 total JS)
- [x] 볼륨에 따라 파티클 구형이 팽창/수축 (displaceParticle)
- [x] 상태별로 회전 속도가 자연스럽게 변화 (rotationSpeed - Phase 1에서 구현)
- [x] LISTENING 시 파티클 밝기 증가 + 1% sparkle (particleAlpha + draw loop)
- [x] 볼륨 0일 때 안정적인 구형 유지 (원본 좌표 반환)
