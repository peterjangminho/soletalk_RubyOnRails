# Status: Done

# Phase 6 - debugging Skill Plan

## 목적
- 버그 재현/가설 수립/최소 수정/재검증 워크플로우 스킬 구축

## TDD 계획
- Red: 재현 가능한 실패 테스트 먼저 고정
- Green: 최소 수정으로 테스트 통과
- Refactor: 테스트 그린 이후 구조 개선 및 구조/동작 분리

## 구현 범위
- 스킬명: `debugging-skill`
- 포함물: `SKILL.md`, `agents/openai.yaml`, `references/debugging-checklist.md`

## 검증
- 자동 검증 완료(`quick_validate.py`): 파일 구조/frontmatter/체크리스트 존재 확인 완료

## 진행 메모
- 글로벌 경로: `/Users/peter/.codex/skills/debugging-skill`
- AGENTS 문서규칙 기반 `.md` 선작성, 최소 3가설, code-review plugin, `/clear` 후 최종 점검 규칙 반영 완료

## 커밋 단위
- behavioral: debugging-skill 신규 생성
- 현재 작업 경로는 Git 저장소가 아니어서 커밋 미수행
