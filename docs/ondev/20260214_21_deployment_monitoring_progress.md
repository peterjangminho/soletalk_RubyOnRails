# Status: In Progress

# Deployment & Monitoring Progress

## Objective
- Phase 16 선행 작업으로 운영 헬스체크/환경 검증 베이스라인 확보

## Completed
1. Health endpoint
- `GET /healthz` 추가
- 응답에 `ok/service/version/timestamp/database` 포함

2. Env validator
- `Ops::EnvValidator` 구현
- 필수 운영 ENV 누락 키 목록 반환

3. API error reporting baseline
- `Ops::ErrorReporter` 구현 (예외/컨텍스트 로깅)
- `ApplicationController` 전역 API 예외 응답 표준화
  - 500: `internal_error` + `request_id`
  - 404: `not_found`

4. CI/CD baseline enhancement
- `.github/workflows/ci.yml`에 `docker-build` job 추가
- `scan/lint/test` 게이트 통과 후 Docker image smoke build 실행
- 워크플로우 YAML 문법 검증 완료

5. Deployment preflight automation
- `Ops::PreflightCheck` 구현(ENV/배포 아티팩트 점검)
- `rake ops:preflight` 태스크 추가(JSON 결과 출력, 실패 시 non-zero exit)

6. Railway baseline adoption
- `railway.json` 추가 및 Dockerfile 기반 배포 설정
- Railway healthcheck를 `/healthz`로 연결
- preflight 아티팩트 점검 목록에 `railway.json` 포함

## Validation
- Health/Env validator 테스트 통과 (`P45-T1`, `P45-T2`, `P45-T3`)
- API 예외처리/리포팅 테스트 통과 (`P46-T1`, `P46-T2`, `P46-T3`)
- Preflight 테스트 통과 (`P48-T1`, `P48-T2`, `P48-T3`)
- Railway baseline 반영 후 테스트 통과 (129 tests, 562 assertions)
- 대상 파일 RuboCop 통과

## Next
- Railway 실제 배포 실행 및 런타임 환경변수 연결
- App store 준비/운영 절차 정리
