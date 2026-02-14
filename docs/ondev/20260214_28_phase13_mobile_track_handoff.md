# Status: In Progress

# Phase 13 Mobile Track Handoff Plan

## Objective
- Rails 저장소 범위를 넘어서는 Phase 13 잔여 항목을 모바일 트랙으로 분리
- Android/iOS 담당이 바로 실행할 수 있는 최소 계획과 검증 기준 제공

## Scope
- Android Hotwire Native 프로젝트 구성
- iOS Hotwire Native 프로젝트 구성
- AudioBridge/LocationBridge 컴포넌트
- STT/TTS 및 오디오 스트리밍 연동

## Work Breakdown
1. Bridge Contract Alignment
- Rails `POST /api/voice/events` 액션 규약(`start_recording`, `stop_recording`, `transcription`, `location_update`) 재확인
- 모바일 측 이벤트 payload 스키마 고정

2. Android Track
- Hotwire Native Android shell + WebView bridge 구현
- 마이크 권한/녹음 세션 lifecycle 구현
- transcription 이벤트를 Rails API로 전송

3. iOS Track
- Hotwire Native iOS shell + bridge 구현
- 오디오 캡처/재생, 위치 권한 처리
- Android와 동일한 이벤트 규약 보장

4. STT/TTS Integration
- STT provider 결정 및 latency 기준 측정
- TTS playback 경로와 interruption 처리

## Validation Gate (E2E)
1. 실기기에서 녹음 시작/종료 이벤트 전송 성공
2. transcription 이벤트가 Rails 세션 메시지로 저장됨
3. 위치 업데이트 이벤트 수신/저장 확인
4. 중단/재시작/네트워크 불안정 시 복구 동작 확인

## Dependencies
- Google OAuth 프로덕션 승인 상태
- OntologyRAG 운영 키/레이트리밋 검증
- 모바일 스토어 제출용 서명/번들 준비

## Next
- 모바일 담당 리포/보드에 본 문서를 이관
- 각 플랫폼 PoC 결과를 기준으로 상태를 `Done`으로 전환
