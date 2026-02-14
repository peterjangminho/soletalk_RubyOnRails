# Status: [In Progress]

# Phase 13 Android-First Execution Plan

## Objective
- 모바일 트랙을 Android Hotwire Native 우선으로 실행한다.
- iOS는 실기기 부재를 감안해 후순위(Deferred)로 관리한다.

## Scope
- Android shell + bridge + voice pipeline PoC
- Rails `POST /api/voice/events` 계약과 Android 이벤트 정합성 확보
- iOS no-device 대응 전략 문서화

## TDD/Verification Checkpoints
- Red:
  - Android에서 `start_recording`/`stop_recording`/`transcription`/`location_update` 이벤트 전송 실패 케이스 정의
  - Rails API 응답 불일치/권한 오류 재현 케이스 정의
- Green:
  - Android 브리지 구현 후 이벤트 4종 전송 성공
  - Rails DB 반영(메시지/metadata) 확인
- Refactor:
  - bridge 인터페이스 정리, 에러코드 매핑 표준화
  - 플랫폼 공통 계약 문서 업데이트

## Android Work Breakdown
1. Hotwire Native Android shell 구성
- WebView + bridge 기본 구조 생성
- 권한(마이크/위치) 요청 lifecycle 구현

2. Audio Bridge
- `startRecording`, `stopRecording`, `onTranscription` 연결
- transcription chunk 처리 및 debounce/throttle 정책 정의

3. Location Bridge
- 위치/날씨 payload 구성 후 `location_update` 전송
- 좌표 포맷/범위 준수 확인

4. API Contract Validation
- Rails `/api/voice/events` 응답 코드/에러코드 매핑
- unauthorized/invalid payload/error path 검증

5. Android E2E Gate
- 실기기에서 start -> transcription -> stop -> location 시나리오 검증
- 네트워크 불안정 복구 시나리오 확인

## iOS Deferred Plan (No Device)
1. 현 상태
- iOS 실기기 부재로 iOS track은 `Deferred`

2. 대체 검증 전략
- Xcode Simulator smoke test로 UI/브리지 기본 동작 검증
- Rails API contract test로 서버 호환성 검증
- 외부 테스터(TestFlight internal) 또는 device farm으로 실기기 검증 대체

3. iOS 착수 조건
- 실기기 최소 1대 확보 또는 device farm 계정/예산 준비
- 오디오 권한/백그라운드/인터럽션 실기기 시나리오 검증 가능 상태

## Validation
- Rails side regression:
  - `PARALLEL_WORKERS=1 bundle exec rails test test/services/voice/event_processor_test.rb test/controllers/api/voice/events_controller_test.rb`
- Mobile side:
  - Android 리포에서 브리지 단위 테스트 + 실기기 E2E 체크리스트 통과

## Session-End Update
- Completed:
  - Android-first / iOS-deferred 전략 문서화
  - Roadmap/plan/handoff 문서 동기화
- Pending:
  - Android 모바일 리포 실제 구현 착수 및 PoC 산출물 확보
- Mismatch:
  - 없음
- Next Test:
  - P57-T2 Android Hotwire Native PoC 착수
