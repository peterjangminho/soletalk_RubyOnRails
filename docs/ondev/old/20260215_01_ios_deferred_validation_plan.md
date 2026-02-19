# Status: [Done]

# Phase 13 iOS Deferred Validation Plan

## Decision (P58-T1)
- 결정 일시: 2026-02-15
- 결정: iOS track은 실기기 부재로 `Deferred` 유지
- 근거:
  - 현재 세션에서 iOS physical device 접근 불가
  - Android-first track에서 Rails contract + bridge hardening 우선 완료

## Substitute Validation Strategy (P58-T2)
1. Simulator Smoke
- 범위: Hotwire Native iOS shell 진입/웹 렌더링/브리지 메서드 호출 가능 여부
- 기준: 앱 실행, 세션 화면 로드, 브리지 호출 에러 없이 완료

2. API Contract Regression
- 범위: Rails `POST /api/voice/events` 계약 검증
- 기준: `start_recording`, `transcription`, `stop_recording`, `location_update` 4종 이벤트 처리 테스트 통과
- 실행:
```bash
bundle exec rails test test/controllers/api/voice/events_controller_test.rb test/services/voice/event_processor_test.rb test/integration/e2e_voicechat_flow_test.rb
```

3. External Device/Tester Gate
- 범위: iOS 실기기 음성 권한/오디오 인터럽션/백그라운드 시나리오
- 기준: 내부 TestFlight 테스터 또는 device farm 결과 리포트 확보

## Exit Criteria
- iOS 실기기 1대 이상 확보 또는 device farm 계정/예산 준비
- 외부 게이트 결과에서 음성 이벤트 4종 왕복/저장 증적 확보
