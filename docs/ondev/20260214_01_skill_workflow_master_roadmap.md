# Status: Done

# Skill Workflow Master Roadmap

## 목표
- 글로벌 재사용 가능한 6개 스킬 구축
- 대상 스킬: `roadmap`, `sub-plan`, `execute`, `code-review`, `gap-analysis`, `debugging`
- 기준 원칙: 바이브코딩 6대 원칙 + Kent Beck TDD/Tidy First

## 원칙 매핑
- 일관 패턴/One Source of Truth: 공통 템플릿과 상태 모델 통일
- 하드코딩 배제: 상태/체크리스트/단계명을 상수화된 문서 패턴으로 유지
- 해피패스+예외 처리: 각 스킬에 실패 복구/검증 루틴 명시
- SRP: 스킬별 단일 책임 분리
- Shared 관리: 공통 규칙은 참조 문서로 분리, 스킬 본문은 최소화
- TDD: Red -> Green -> Refactor, 구조/동작 커밋 분리

## Phase 구성
1. Phase 1: `roadmap` 스킬 제작 (Done)
2. Phase 2: `sub-plan` 스킬 제작 (Done)
3. Phase 3: `execute` 스킬 제작 (Done)
4. Phase 4: `code-review` 스킬 제작 (Done)
5. Phase 5: `gap-analysis` 스킬 제작 (Done)
6. Phase 6: `debugging` 스킬 제작 (Done)

## 공통 워크플로우
1. 세부계획 문서를 `In Progress`로 전환
2. 테스트/검증 항목 정의(스킬 유효성 검사 포함)
3. 최소 구현(스킬 템플릿 + 참조 파일)
4. 검증 실행(`quick_validate.py`)
5. 세부계획 상태 `Done` 업데이트
6. phase 단위 커밋 후 다음 phase 진행

## 산출물
- 글로벌 스킬 폴더 6개
- `docs/ondev/20260214_02`~`06` 세부계획 문서 + 디버깅 스킬 보강 이력
- phase 완료 이력

## 완료 결과
- 생성 완료:
  - `/Users/peter/.codex/skills/roadmap-skill`
  - `/Users/peter/.codex/skills/sub-plan-skill`
  - `/Users/peter/.codex/skills/execute-skill`
  - `/Users/peter/.codex/skills/code-review-skill`
  - `/Users/peter/.codex/skills/gap-analysis-skill`
  - `/Users/peter/.codex/skills/debugging-skill`
- 모든 세부계획 문서 상태 `Done`
- 현재 작업 경로가 Git 저장소가 아니어서 phase 커밋은 미수행

## 완료 조건
- 6개 스킬 모두 구조 생성 완료
- 모든 세부계획 문서 상태 `Done`
- 마스터 로드맵 상태 `Done` 및 최종 결과 반영 완료
