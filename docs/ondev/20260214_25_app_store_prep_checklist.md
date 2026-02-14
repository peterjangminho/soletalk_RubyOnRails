# Status: In Progress

# App Store Prep Checklist (Phase 16 Remaining)

## Objective
- Google Play / Apple App Store 제출 준비를 체크리스트화
- 현재 구현 상태 기준으로 완료/미완료를 분리

## Completed
1. 배포 타깃 URL 확보
- `https://soletalk-rails-production.up.railway.app`

2. 운영 헬스체크 기준 확보
- `/healthz` 성공 기준 정의 및 실검증 완료

3. 기본 운영/배포 runbook 작성
- `docs/ondev/20260214_24_phase16_ops_runbook.md`

## Remaining
1. 앱 메타데이터
- 앱명/설명/카테고리/연락처/개인정보처리방침 URL 확정

2. 정책/법무
- Privacy policy, Terms URL 확정
- 데이터 수집/보관/삭제 정책 문구 확정

3. 인증/연동
- Google OAuth 프로덕션 자격증명 및 승인 상태 확인 (자격증명 주입 완료, 콘솔 승인상태 최종 확인 필요)
- OntologyRAG 실운영 키/레이트리밋 검증 (키 주입 완료, 운영 트래픽 기준 레이트리밋 검증 필요)

4. 모바일 제출 아티팩트
- Android 서명/패키지/스크린샷
- iOS 번들/스크린샷/심사 노트

5. 출시 검증
- 실기기 E2E(로그인, 세션 생성, 대화 저장, 인사이트 열람)
- 장애 대응/롤백 절차 리허설

## Gate
- 위 Remaining이 모두 충족되면 본 문서 상태를 `Done`으로 변경
