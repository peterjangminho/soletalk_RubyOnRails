# Status: Done

# Production ENV 설정 가이드 (Google OAuth + OntologyRAG + Railway)

## 목적
- SoleTalk Rails 운영에 필요한 필수 환경변수를 발급/확인하고 Railway에 안전하게 주입한다.
- 주입 후 배포/헬스체크까지 완료해 운영 준비 상태를 검증한다.

## 대상 환경변수
- `ONTOLOGY_RAG_BASE_URL`
- `ONTOLOGY_RAG_API_KEY`
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- (이미 설정됨) `SECRET_KEY_BASE`

---

## 1. ONTOLOGY_RAG_BASE_URL 확인

현재 프로젝트 기준 기본값:
- `https://ontologyrag01-production.up.railway.app`

확인 방법:
1. OntologyRAG(Project_E) 운영 URL이 위 주소와 동일한지 운영 담당자에게 확인
2. 다르면 실제 운영 URL로 확정

---

## 2. ONTOLOGY_RAG_API_KEY 발급/재발급

방법:
1. Project_E(OntologyRAG) 운영 담당자에게 API Key 발급 또는 재발급 요청
2. 권한 범위:
- 최소 `engine/query`, `engine/users/identify`, `incar/*` 호출 가능한 키
3. 전달 형식:
- 평문 전달 대신 보안 채널(비밀관리 툴, 1회성 공유 링크) 사용 권장

체크:
- 키 prefix/포맷이 기존 시스템과 일치하는지 확인
- 만료 정책(회전 주기) 확인

---

## 3. GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET 발급

Google Cloud Console 기준:
1. Google Cloud Console 접속
2. 프로젝트 선택 (SoleTalk 운영 프로젝트)
3. `APIs & Services` -> `Credentials`
4. `Create Credentials` -> `OAuth client ID`
5. Application type: `Web application`
6. Authorized JavaScript origins 추가(권장):
- `https://soletalk-rails-production.up.railway.app`
7. Authorized redirect URI 추가(필수):
- `https://soletalk-rails-production.up.railway.app/auth/google_oauth2/callback`
8. 생성 후 `Client ID`, `Client secret` 복사

주의:
- Redirect URI 오타/슬래시 불일치 시 로그인 실패
- Rails 서버 OAuth만 사용해도 JavaScript origin을 함께 등록해두면 검증 이슈를 줄일 수 있음
- 필요 시 OAuth consent screen의 publishing 상태도 확인

---

## 4. Railway에 환경변수 주입

프로젝트 루트에서 실행:

```bash
railway variables \
  --set "ONTOLOGY_RAG_BASE_URL=https://ontologyrag01-production.up.railway.app" \
  --set "ONTOLOGY_RAG_API_KEY=실제값" \
  --set "GOOGLE_CLIENT_ID=실제값" \
  --set "GOOGLE_CLIENT_SECRET=실제값"
```

또는 준비된 스크립트 사용:

```bash
export ONTOLOGY_RAG_BASE_URL='https://ontologyrag01-production.up.railway.app'
export ONTOLOGY_RAG_API_KEY='실제값'
export GOOGLE_CLIENT_ID='실제값'
export GOOGLE_CLIENT_SECRET='실제값'
bash script/railway/set_required_env.sh
```

확인:

```bash
railway variables --kv
```

---

## 5. 배포/상태 검증

```bash
railway up -d
railway deployment list
```

성공 기준:
- 최신 deployment 상태가 `SUCCESS`

런타임 검증:

```bash
curl -sS -m 15 https://soletalk-rails-production.up.railway.app/healthz
curl -sS -m 15 -o /dev/null -w "%{http_code}\n" https://soletalk-rails-production.up.railway.app/
```

성공 기준:
- `/healthz` -> `ok: true`, `database: "ok"`
- `/` -> `200`

---

## 6. 문제 발생 시 점검 순서

1. 변수 누락 확인
- `railway variables --kv`

2. 배포 로그 확인
- `railway logs --deployment -n 200 <deployment_id>`

3. 앱 부팅 확인
- 포트 바인딩/엔트리포인트(`Dockerfile`, `bin/docker-entrypoint`)

4. 수정 후 재배포
- `railway up -d`

---

## 7. 완료 기준 (Definition of Done)

- 필수 4개 변수 주입 완료
- 배포 `SUCCESS`
- `/healthz` 정상
- 루트 `/` 200
- 문서(`plan.md`, `docs/PLAN.md`, ondev 진행문서) 상태 동기화 완료
