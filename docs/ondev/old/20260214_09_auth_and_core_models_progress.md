# Status: In Progress

# Auth & Core Models Progress

## Objective
- 인증 기반(User/google_sub), 핵심 세션 데이터 모델, OntologyRAG 클라이언트 레이어를 운영 가능한 상태로 확정

## Completed (This Session)
1. Auth foundation
- `User` 모델/마이그레이션 (`google_sub` unique)
- `Auth::GoogleSubExtractor` 서비스
- OmniAuth callback/failure 컨트롤러 + 세션 로그인 처리
- `authenticate_user!`/`current_user` + 보호 엔드포인트
- `OntologyRag::IdentifyUserJob` 비동기 등록

2. Core models
- `Session`, `Message`, `VoiceChatData`, `Setting` 모델/마이그레이션
- 관계/기본값/index/enum 검증

3. OntologyRAG infra
- `OntologyRag::Constants`, `OntologyRag::Models`
- `OntologyRag::Client` Faraday 기본 어댑터 + timeout/fallback
- WebMock 기반 HTTP 경로 검증 테스트

4. Infrastructure
- Gemfile 확장: `faraday`, `omniauth`, `omniauth-google-oauth2`, `webmock`, `vcr`, `dotenv-rails`
- Minitest 기준 WebMock/VCR/OmniAuth test mode 기본 설정

## Validation
- `bundle exec rails test` 통과 (36 tests, 138 assertions)
- 대상 파일 RuboCop 통과

## Next
- Phase 5 시작: `VoiceChat::Constants` / phase transition thresholds / DEPTH trigger rules
- Phase 4 잔여: VCR cassette 기반 엔드포인트 재현 테스트

## Notes
- `docs/PLAN.md` 및 루트 `plan.md` 구현 현황 동기화 완료
