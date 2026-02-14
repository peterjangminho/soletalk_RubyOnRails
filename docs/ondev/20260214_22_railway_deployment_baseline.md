# Status: Done

# Railway Deployment Baseline

## Objective
- 배포 플랫폼을 Railway로 고정하고, 프로젝트 내 배포 설정 기준선을 명시

## Completed
1. Platform decision
- Phase 16 배포 플랫폼을 Railway로 확정

2. Railway config
- `railway.json` 추가
  - Dockerfile 빌드 사용
  - `/healthz` 헬스체크
  - 실패 시 재시작 정책 설정

3. Operational alignment
- 기존 `/healthz` 엔드포인트를 Railway 헬스체크 경로로 사용
- `ops:preflight`에 Railway 아티팩트 검증 항목 반영

## Next
- Railway 환경변수 실값(`ONTOLOGY_RAG_*`, `GOOGLE_*`) 주입
- 롤백 절차(runbook) 문서화
