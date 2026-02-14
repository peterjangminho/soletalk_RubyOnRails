# Status: Done

# Phase 1 - roadmap Skill Plan

## 목적
- 프로젝트/기능 단위 마스터 로드맵 문서 자동화용 스킬 구축

## TDD 계획
- Red: `SKILL.md` 필수 frontmatter/지시 누락 상태에서 validation 실패 확인
- Green: 최소 필드와 절차를 채워 validation 통과
- Refactor: 지시문을 간결화하고 참조 분리

## 구현 범위
- 스킬명: `roadmap-skill`
- 포함물: `SKILL.md`, `agents/openai.yaml`, `references/roadmap-template.md`

## 검증
- 자동 검증 완료(`quick_validate.py`): 파일 구조/frontmatter/템플릿 존재 확인 완료

## 진행 메모
- 글로벌 경로: `/Users/peter/.codex/skills/roadmap-skill`
- 로드맵 템플릿 참조 파일 포함 완료

## 커밋 단위
- behavioral: roadmap-skill 신규 생성
- 현재 작업 경로는 Git 저장소가 아니어서 커밋 미수행
