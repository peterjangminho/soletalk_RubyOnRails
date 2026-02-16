# Master Plan: Project_B 3D Particle Sphere UI Parity

**Status**: [In Progress]
**Created**: 2026-02-16
**Last Updated**: 2026-02-16

---

## 목표

Project_B의 3D 구형 파티클 애니메이션과 UI 요소들을 Project_A(Rails + Hotwire Native)에 구현하여 시각적 일관성을 확보한다.

## 현재 상태 분석

### Project_B (Reference - React Native)
- **파티클**: Golden Spiral 분포, 1000개, Canvas 2D + 3D 투영(FOV 250)
- **구형 회전**: Y축 기반 회전, 상태별 속도 변화 (IDLE/THINKING/SPEAKING/LISTENING)
- **볼륨 반응**: LISTENING 시 파티클 displacement (volume × 20)
- **오프닝**: 폭발 → 재결합 → 회전 (5초)
- **마이크 버튼**: 80px 원형, 상태별 색상 (gray/teal/yellow), long-press 지원
- **컬러**: #21203A 배경, rgba(137,207,240) 시안블루 파티클
- **폰트**: Quicksand

### Project_A (Current - Rails + Hotwire)
- **파티클**: Random 분포, 1800개, 3-phase 애니메이션 (gather/spread/orb)
- **구형 아님**: 2D 평면에서의 orbital 움직임, 진정한 3D 투영 없음
- **마이크 버튼**: 76px, 🎤 이모지 기반, 단순 submit
- **컬러**: #21203A 배경 (동일), 블루/시안 계열 (유사하나 다름)
- **폰트**: Space Grotesk + Noto Serif KR

## Gap 분석

| 요소 | Project_B | Project_A | Gap |
|------|-----------|-----------|-----|
| 파티클 분포 | Golden Spiral | Random | 핵심 차이 |
| 3D 투영 | FOV 기반 perspective | 없음 (2D orbital) | 핵심 차이 |
| Y축 회전 | sin/cos 기반 | 없음 | 핵심 차이 |
| 깊이 정렬 | Z-depth sorting | 없음 | 시각적 차이 |
| 볼륨 반응 | displacement + 색상 변화 | 없음 | 기능적 차이 |
| 오프닝 애니메이션 | 폭발/재결합 | CSS fade (다름) | 체감 차이 |
| 마이크 버튼 | SVG 아이콘 + 상태 관리 | 이모지 + 단순 | UX 차이 |
| 폰트 | Quicksand | Space Grotesk | 스타일 차이 |
| 버튼 스타일 | Tailwind (teal/gray/yellow) | Custom CSS (gradient) | 스타일 차이 |

## Phase 구성

### Phase 1: 3D Particle Sphere Core Engine [Done]
- Golden Spiral 분포 알고리즘
- FOV 기반 3D perspective 투영
- Y축 회전 및 depth sorting
- Stimulus Controller 리팩토링
- **세부계획**: `20260216_02_phase1_3d_particle_engine.md`

### Phase 2: Opening Animation (Explosion → Reform) [Done]
- 파티클 폭발 효과
- 구형 재결합 (cubic easing)
- 회전 시작 트랜지션
- 페이드아웃 + Skip 버튼
- **세부계획**: `20260216_03_phase2_opening_animation.md`

### Phase 3: Microphone Button Parity [Done]
- SVG 마이크 아이콘 (🎤 이모지 제거)
- 상태별 스타일 (idle/active/muted/disabled)
- Long-press 지원 (1초)
- Pulse 애니메이션
- **세부계획**: `20260216_04_phase3_mic_button.md`

### Phase 4: Voice-Reactive Particle Behavior [Not Started]
- 볼륨 기반 displacement
- 상태별 회전 속도 변화
- 색상 변화 (LISTENING 모드)
- Action Cable 연동
- **세부계획**: `20260216_05_phase4_voice_reactive.md`

### Phase 5: Typography & Visual Polish [Not Started]
- Quicksand 폰트 적용
- 색상 팔레트 통일 (#7DD3E8, #5EECC7)
- 버튼/카드 스타일 조정
- 반응형 최적화
- **세부계획**: `20260216_06_phase5_typography_visual.md`

## 바이브코딩 6대원칙 적용 계획

1. **일관된 패턴**: Stimulus Controller 패턴 유지, export function 구조 보존
2. **One Source of Truth**: 파티클 설정값을 constants로 분리
3. **하드코딩 금지**: Magic Numbers → 상수 추출 (FOV, particle count, radius ratio 등)
4. **에러/예외 처리**: Canvas 미지원, reduced motion, low-power 대응
5. **Single Responsibility**: 3D 투영, 파티클 생성, 렌더링 분리
6. **공유 모듈 관리**: 재사용 가능한 함수들을 export

## Kent Beck TDD 원칙 적용

- **Red → Green → Refactor** 사이클 엄수
- **Tidy First**: 구조 변경(리팩토링)과 기능 변경(새 기능) 커밋 분리
- **최소 코드**: 테스트 통과에 필요한 최소한의 코드만 작성
- **한 번에 하나의 테스트**: 점진적 기능 추가

## 의존성 그래프

```
Phase 1 (3D Engine) ──→ Phase 2 (Opening)
        │                      │
        └──→ Phase 4 (Voice) ──┘
                               │
Phase 3 (Mic Button) ──────────┘
                               │
                    Phase 5 (Polish) ←──┘
```

## 성공 기준

- [ ] 3D 구형 파티클이 Golden Spiral로 분포
- [ ] FOV 기반 perspective 투영으로 깊이감 표현
- [ ] 오프닝에서 파티클 폭발 후 구형으로 재결합
- [ ] 마이크 버튼이 SVG 아이콘 + 상태별 시각 피드백
- [ ] 볼륨에 반응하여 파티클 크기/위치 변화
- [ ] 폰트/색상이 Project_B와 시각적으로 통일
- [ ] 기존 테스트 전부 통과
- [ ] 새 테스트 추가 (각 Phase별)
