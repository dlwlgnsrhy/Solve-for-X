# 3. 자동화 시스템(Notion, Launchd) 예외 및 버그 트러블슈팅

Date: 2026-04-10

## Problem
1. **Launchd 프로세스 실행 오류**: `setup_launchd.sh`를 통해 `python -m daily_planner.main`으로 봇을 실행할 때, WorkingDirectory 경로 및 `sys.path` 인식이 어긋나 파이프라인이 정상 작동하지 않는 현상 발생.
2. **Notion 속성명(Schema) 불일치 오류**: Notion API 클라이언트가 하드코딩된 속성('태스크', '완료' 체크박스)을 찾으려 했으나, 실제 Daily Log DB의 커스텀 구조(Condition 점수, 오늘의 1가지 리치 텍스트 등)와 달라 태스크 파싱에 실패함.
3. **네트워크 단절 시 봇의 조용한 죽음 (Silent Failure)**: 와이파이가 끊기거나 LLM(Gemma 31B)/Notion 서버와 통신 오류가 날 때, 텔레그램 알림조차 발송되지 못해 결국 파이프라인이 고장난 사실을 바로 알 수 없음.

## Cause
- MacOS `launchd` 백그라운드 환경 특성 상 모듈(`-m`) 실행 시 파이썬 가상환경과 절대 경로 검색이 매우 까다로움.
- 템플릿 형태의 코드를 실제 개인화된 Notion 데이터베이스 Schema에 맞추는 정교한 파싱 로직 부재.
- 에러 로그를 콘솔에만 남기도록 되어 있어, 네트워크 전송 수단(Telegram) 자체가 실패하는 "네트워크 오프라인" 예외 케이스에 대한 고려가 빠져 있었음.

## Solution
1. **직접 스크립트 실행으로 전환**: `launchd.plist`의 `ProgramArguments`를 가상환경의 python이 직접 `main.py`의 절대 경로를 바라보고 실행(Direct Execution)하도록 수정.
2. **Notion 실제 DB Schema 로직 매핑**: `notion_client.py`를 전면 수정하여 실제 사용 중인 `Condition(number)`, `오늘의 1가지(rich_text)`, `태그(multi_select)` 및 `Weekly System(relation)` 요소들을 정확히 파싱하도록 구현.
3. **3단계 방어 로직 (Global Exception & Native Fallback)**:
   - 각 API 요청 시 응답 여부와 LLM의 생성 실패 텍스트(`계획 생성 실패`)를 즉시 감지해 즉각 중단하고 텔레그램 발송.
   - `main()` 단위의 최상단 전역 에러 핸들러(`try-except`) 선언.
   - 인터넷 연결 자체가 끊어져 **텔레그램 발송마저 실패할 경우를 대비하여 Mac OS 네이티브 팝업 알림(`osascript -e 'display notification...'`)을 구동**하도록 하여 100% 알림이 도달하도록 백스톱(Backstop) 구축.

## Note
- 자동화 시스템은 구동되는 것만큼 "문제가 생겼을 때 얼마나 빨리 인지할 수 있는가"가 핵심입니다. 이번 MacOS 네이티브 알림 추가 조치를 통해 오프라인 상황을 포함한 어떠한 예외에서도 에러를 포착하고 대응할 수 있게 되었습니다.
