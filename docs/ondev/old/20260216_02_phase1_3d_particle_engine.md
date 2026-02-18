# Phase 1: 3D Particle Sphere Core Engine

**Status**: [Done]
**Created**: 2026-02-16
**Master Plan**: `20260216_01_particle_sphere_ui_parity_master_plan.md`

---

## 목표

기존 `particle_orb_controller.js`의 2D orbital 애니메이션을 Project_B의 Golden Spiral + FOV 기반 3D perspective 구형 파티클로 교체한다.

## 바이브코딩 원칙 체크리스트

- [ ] 원칙1 (일관된 패턴): Stimulus Controller export 패턴 유지
- [ ] 원칙2 (One Source of Truth): 3D 설정값 단일 상수 모듈
- [ ] 원칙3 (하드코딩 금지): FOV=250, particleCount=1000, radiusRatio=0.35 → 상수
- [ ] 원칙4 (에러/예외): Canvas 미지원, DPR 감지, reduced motion 대응
- [ ] 원칙5 (SRP): 파티클 생성, 3D 투영, 렌더링 함수 분리
- [ ] 원칙6 (공유 모듈): golden spiral, perspective projection export

## Kent Beck TDD Plan

### Test 1: Golden Spiral 파티클 분포 생성
```
RED:  buildGoldenSpiralParticles(count, radius) → count개 파티클, 각 x/y/z 좌표
GREEN: Golden angle(π(3-√5)) 기반 분포 알고리즘 구현
REFACTOR: 상수 추출
```

### Test 2: 3D Perspective 투영
```
RED:  projectParticle3D(particle, fov, centerX, centerY, rotationY) → {px, py, scale}
GREEN: FOV 기반 perspective math + Y축 회전
REFACTOR: rotation matrix를 별도 함수로 분리
```

### Test 3: Depth Sorting
```
RED:  sortByDepth(particles) → z값 기준 정렬된 배열
GREEN: Array.sort by z coordinate
REFACTOR: N/A (단순)
```

### Test 4: 상수 모듈
```
RED:  SPHERE_CONFIG import → FOV, PARTICLE_COUNT, RADIUS_RATIO 포함
GREEN: 상수 객체 생성
REFACTOR: 기존 magic numbers를 상수로 대체
```

### Test 5: Stimulus Controller 통합
```
RED:  particle-sphere controller connect → canvas에 3D 구형 렌더링
GREEN: 기존 controller를 새 3D 엔진으로 교체
REFACTOR: 미사용 2D 코드 제거
```

### Test 6: 회전 애니메이션
```
RED:  requestAnimationFrame loop → rotationY 증가 + 재렌더링
GREEN: render loop 구현
REFACTOR: frame interval 기반 throttling
```

### Test 7: Device Pixel Ratio 대응
```
RED:  canvas resize → DPR 기반 크기 조정
GREEN: ResizeObserver + DPR 감지
REFACTOR: 기존 resize 함수와 통합
```

### Test 8: Reduced Motion 대응
```
RED:  prefers-reduced-motion → 회전 정지, 정적 구형 렌더링
GREEN: matchMedia 감지 → animate: false
REFACTOR: motionProfile 함수 업데이트
```

## 파일 변경 계획

| 파일 | 변경 내용 |
|------|-----------|
| `app/javascript/controllers/particle_sphere_controller.js` | 신규: 3D Sphere Stimulus Controller |
| `app/javascript/lib/particle_sphere_engine.js` | 신규: 순수 함수 모듈 (golden spiral, projection, constants) |
| `app/views/home/index.html.erb` | data-controller 변경 |
| `app/views/sessions/show.html.erb` | data-controller 변경 |
| `test/javascript/lib/particle_sphere_engine_test.mjs` | 신규: 엔진 유닛 테스트 |
| `test/javascript/controllers/particle_sphere_controller_test.mjs` | 신규: 컨트롤러 테스트 |

## 핵심 알고리즘 (Project_B 참조)

```javascript
// Golden Spiral Distribution
const phi = Math.PI * (3 - Math.sqrt(5))
for (let i = 0; i < count; i++) {
  const y = 1 - (i / (count - 1)) * 2
  const r = Math.sqrt(1 - y * y)
  const theta = phi * i
  const x = Math.cos(theta) * r
  const z = Math.sin(theta) * r
  // particle at (x * radius, y * radius, z * radius)
}

// 3D Perspective Projection
const rotatedX = x * cosY - z * sinY
const rotatedZ = x * sinY + z * cosY
const scale = fov / (fov + rotatedZ)
const screenX = rotatedX * scale + centerX
const screenY = y * scale + centerY
```

## 완료 기준

- [ ] 모든 TDD 테스트 통과 (8개)
- [ ] 1000개 파티클이 Golden Spiral로 구형 배치
- [ ] Y축 회전 시 3D 깊이감 표현
- [ ] 기존 particle_orb_controller 테스트 영향 없음
- [ ] Reduced motion 사용자 대응 완료
