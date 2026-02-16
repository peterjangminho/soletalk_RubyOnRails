# Phase 5: Typography & Visual Polish

**Status**: [Not Started]
**Created**: 2026-02-16
**Master Plan**: `20260216_01_particle_sphere_ui_parity_master_plan.md`
**Depends On**: Phase 1, 2, 3

---

## 목표

Project_B와 시각적 일관성을 위해 폰트, 색상 팔레트, 버튼/카드 스타일을 조정한다.

## 바이브코딩 원칙 체크리스트

- [ ] 원칙1 (일관된 패턴): CSS 변수 기반 통일된 디자인 시스템
- [ ] 원칙2 (One Source of Truth): 디자인 토큰 CSS 변수 한 곳에서 관리
- [ ] 원칙3 (하드코딩 금지): 색상값 → CSS custom properties
- [ ] 원칙4 (에러/예외): 폰트 로딩 실패 fallback
- [ ] 원칙5 (SRP): 타이포그래피/색상/레이아웃 CSS 섹션 분리
- [ ] 원칙6 (공유 모듈): CSS 변수로 전역 재사용

## Kent Beck TDD Plan

### Test 1: Quicksand 폰트 로딩
```
RED:  document에 Quicksand 폰트 face 선언 확인
GREEN: Google Fonts import 교체 (Space Grotesk → Quicksand)
REFACTOR: font-display: swap 추가
```

### Test 2: 브랜드 색상 CSS 변수 업데이트
```
RED:  --accent 값이 #7DD3E8(Project_B cyan)인지 확인
GREEN: CSS 변수 업데이트
REFACTOR: 기존 accent 사용처 일괄 검증
```

### Test 3: 파티클 색상 통일
```
RED:  파티클 기본 색상 rgba(137,207,240) 확인
GREEN: SPHERE_CONFIG.colors 업데이트
REFACTOR: N/A
```

### Test 4: 버튼 스타일 조정
```
RED:  .btn-link gradient가 teal 계열인지 확인
GREEN: CSS gradient 업데이트 (Project_B teal 계열)
REFACTOR: hover/active 상태 통합
```

### Test 5: 반응형 최적화
```
RED:  모바일 뷰포트에서 파티클 구형 크기 적정
GREEN: 미디어쿼리별 sphere radius 조정
REFACTOR: clamp() 활용
```

## 색상 대조표

| 용도 | Project_B | Project_A (현재) | Project_A (목표) |
|------|-----------|-----------------|-----------------|
| 배경 | #21203A | #21203A | #21203A (유지) |
| 파티클 기본 | rgba(137,207,240) | rgba(102,195,255) | rgba(137,207,240) |
| 브랜드 시안 | #7DD3E8 | #1eb7a4 | #7DD3E8 |
| 브랜드 그린 | #5EECC7 | N/A | #5EECC7 |
| 텍스트 기본 | #FFFFFF | #eef3ff | #eef3ff (유지) |
| 텍스트 보조 | #D1D5DB | #b8c1da | #b8c1da (유지) |

## 폰트 대조표

| 용도 | Project_B | Project_A (현재) | Project_A (목표) |
|------|-----------|-----------------|-----------------|
| 브랜드/제목 | Quicksand | Space Grotesk | Quicksand |
| 한국어 | N/A | Noto Serif KR | Noto Serif KR (유지) |
| weight | 400,500,600,700 | 400,500,600,700 | 동일 |

## 파일 변경 계획

| 파일 | 변경 내용 |
|------|-----------|
| `app/assets/stylesheets/application.css` | 폰트, 색상 변수, 버튼 스타일 업데이트 |
| `app/views/layouts/application.html.erb` | Google Fonts URL 변경 |
| `test/system/home_test.rb` | 비주얼 회귀 테스트 |

## 완료 기준

- [ ] 모든 TDD 테스트 통과 (5개)
- [ ] Quicksand 폰트 적용 확인
- [ ] 파티클 색상이 Project_B와 동일
- [ ] 브랜드 색상 CSS 변수 통일
- [ ] 모바일 반응형 정상 작동
