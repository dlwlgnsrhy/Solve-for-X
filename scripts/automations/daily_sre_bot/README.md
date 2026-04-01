# SRE Daily Auto-Blogger (Git-to-Blog Cron Batch)

이 파이썬 스크립트는 이지훈 아키텍트의 SRE 철학(Absolute Automation)을 구현하기 위한 백그라운드 파이프라인입니다.
매일 자정에 구동되어 오늘 수행한 내역(`git diff`)을 긁어모아, 로컬에 켜진 LM Studio(Qwen3)에게 전송한 후,
통찰력 있는 SRE 기술 블로그 포스트를 Next.js(`Brand Website`)에 자동 배포하고 텔레그램으로 알림을 보냅니다.

## 준비 사항
1. Python 3.9+ 및 `requests` 라이브러리 설치 (`pip install -r requirements.txt`)
2. Local LM Studio 앱을 켜두고 **Local Inference Server** 모드를 On 해두어야 합니다. (`http://localhost:1234/v1`)
3. Telegram 연동 알림을 받으려면 `main.py` 상단 환경 변수 혹은 코드에 `TELEGRAM_BOT_TOKEN` 및 `TELEGRAM_CHAT_ID`를 기입합니다.

## macOS 자동 기상(Cron) 셋업 가이드

단 한 번의 세팅으로 평생 자정마다 이 스크립트가 스스로 동작하게 만들 수 있습니다.

### 방법: crontab 사용
1. 터미널을 열고 `crontab -e` 를 입력합니다.
2. `[ i ]` 버튼을 눌러 입력 모드로 진입한 후, 아래의 구문을 추가합니다 (경로는 사용자 로컬 경로에 맞게 절대 경로로 작성).
   ```bash
   # 매일 23:50 에 파이썬 스크립트 실행 후 로그를 파일로 남김
   50 23 * * * /usr/bin/python3 /Users/apple/Desktop/soluni/Solve-for-X/scripts/automations/daily_sre_bot/main.py >> /tmp/daily_sre_bot.log 2>&1
   ```
3. `[ esc ]` 를 누르고 `:wq` 를 입력해 저장하고 나옵니다.
4. 이제 매일 밤 11시 50분, 텔레그램으로 `[🟢 Daily Blog Auto-Published]` 뱃지가 날아오는지 확인하시면 됩니다. 수고하셨습니다.
