# Status: [In Progress]

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

7. Railway runtime deployment recovery
- Railway 서비스 변수에 `SECRET_KEY_BASE` 주입
- 컨테이너 시작 커맨드를 Railway 포트/헬스체크 호환 형태로 조정
  - `Dockerfile`: `./bin/rails server -b 0.0.0.0`
  - `bin/docker-entrypoint`: server 옵션 포함 실행에서도 `db:prepare` 동작
- 재배포 성공: `88ef8d09-2fc2-41ce-8eaf-3e406e9c1ab0` (`SUCCESS`)
- 운영 URL 확인: `https://soletalk-rails-production.up.railway.app`

8. Railway payload/runtime hardening
- `railway up -d` 시 `413 Payload Too Large` 재현
- `.railwayignore`/`.dockerignore`에 로컬 대용량 아티팩트(`.gradle-home`, `mobile`) 제외 반영
- `storage` 제외 설정으로 발생한 런타임 권한 오류(`Permission denied @ dir_s_mkdir - /rails/storage`) 복구
- `storage` 제외 항목 제거 후 재배포 성공: `b34ba4fa-9b77-43a3-9a43-69f8c5c3b08a` (`SUCCESS`)

## Validation
- Health/Env validator 테스트 통과 (`P45-T1`, `P45-T2`, `P45-T3`)
- API 예외처리/리포팅 테스트 통과 (`P46-T1`, `P46-T2`, `P46-T3`)
- Preflight 테스트 통과 (`P48-T1`, `P48-T2`, `P48-T3`)
- Railway baseline 반영 후 테스트 통과 (129 tests, 562 assertions)
- 대상 파일 RuboCop 통과
- 배포 수정 테스트 통과 (`test/services/ops/preflight_check_test.rb`, `test/integration/health_flow_test.rb`)
- 실배포 헬스체크 성공: `GET /healthz` -> `{"ok":true,...,"database":"ok"}`
- 실배포 루트 응답 성공: `GET /` -> `200`
- Railway 필수 운영 변수 주입 완료 (`ONTOLOGY_RAG_*`, `GOOGLE_*`)
- 변수 반영 배포 성공: `d64190f8-e37c-4054-80e3-83f2097954e2` (`SUCCESS`)
- payload/runtime 복구 반영 배포 성공: `b34ba4fa-9b77-43a3-9a43-69f8c5c3b08a` (`SUCCESS`)

## Next
- 운영 runbook 기준으로 배포/복구 절차 반복 검증
- App store 준비/운영 절차 정리
