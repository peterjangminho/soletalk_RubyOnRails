# Status: Done

# Phase 16 Ops Runbook (Railway)

## Objective
- Railway 운영 배포/검증 절차를 고정된 명령으로 표준화
- 실운영 ENV 누락 시 즉시 복구 가능한 루틴 확보

## Preconditions
- `railway` CLI 로그인 완료
- 프로젝트 링크 완료 (`railway status`에서 project/service 확인)

## 1) Required ENV Injection

필수 키:
- `ONTOLOGY_RAG_BASE_URL`
- `ONTOLOGY_RAG_API_KEY`
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `SECRET_KEY_BASE`

주입 명령(권장):
```bash
export ONTOLOGY_RAG_BASE_URL='...'
export ONTOLOGY_RAG_API_KEY='...'
export GOOGLE_CLIENT_ID='...'
export GOOGLE_CLIENT_SECRET='...'

bash script/railway/set_required_env.sh
```

검증:
```bash
railway variables --kv
```

## 2) Deploy

```bash
railway up -d
railway deployment list
```

성공 기준:
- 최신 deployment 상태 `SUCCESS`

## 3) Runtime Health Verify

```bash
curl -sS -m 15 https://soletalk-rails-production.up.railway.app/healthz
curl -sS -m 15 -o /dev/null -w "%{http_code}\n" https://soletalk-rails-production.up.railway.app/
```

성공 기준:
- `/healthz` 응답에 `ok: true`, `database: "ok"`
- `/` 응답 코드 `200`

## 4) Failure Triage

1. `railway logs --deployment -n 200 <deployment_id>`
2. 포트/부팅 확인 (`Dockerfile`, `bin/docker-entrypoint`)
3. ENV 누락 확인 (`railway variables --kv`)
4. 수정 후 재배포 (`railway up -d`)

## 5) Post-Deploy Record

- `docs/ondev/20260214_21_deployment_monitoring_progress.md` 업데이트
- `plan.md`, `docs/PLAN.md` 진행 상태 동기화
- phase 단위 커밋/푸시 수행
