# Status: Done

# Phase 4 - code-review Skill Plan

## 목적
- 구현 완료 코드의 원칙 준수 점검(바이브코딩 6대 + TDD 품질) 스킬 구축

## TDD 계획
- Red: 리뷰 기준 누락(예외처리/SRP/상수화) 상태 정의
- Green: severity 기반 finding 템플릿과 파일 라인 기준 도입
- Refactor: 중복 체크 항목을 공통 매트릭스로 통합

## 구현 범위
- 스킬명: `code-review-skill`
- 포함물: `SKILL.md`, `agents/openai.yaml`, `references/review-matrix.md`

## 검증
- 자동 검증 완료(`quick_validate.py`): 파일 구조/frontmatter/리뷰 매트릭스 존재 확인 완료

## 진행 메모
- 글로벌 경로: `/Users/peter/.codex/skills/code-review-skill`
- finding-first + severity 형식 규칙 반영 완료

## 커밋 단위
- behavioral: code-review-skill 신규 생성
- 현재 작업 경로는 Git 저장소가 아니어서 커밋 미수행
