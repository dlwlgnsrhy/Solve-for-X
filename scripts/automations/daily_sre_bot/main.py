import os
import subprocess
import datetime
import requests
import json
import logging
import re
from dotenv import load_dotenv

# ==========================================
# 0. CONFIGURATION (환경 및 설정)
# ==========================================
REPO_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../"))
BLOG_DIR = os.path.join(REPO_PATH, "apps/brand-web/src/app/blog/drafts") 

# 보안 최적화: 비밀 키는 하드코딩하지 않고 .env 파일에서 조용히 불러옵니다.
env_path = os.path.join(os.path.dirname(__file__), ".env")
load_dotenv(dotenv_path=env_path)

LM_STUDIO_URL = "http://localhost:1234/v1/chat/completions"

TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")
DEV_TO_API_KEY = os.getenv("DEV_TO_API_KEY")

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

# ==========================================
# 1. CORE LOGIC (Git 수집)
# ==========================================
def get_target_date():
    # 이제 스크립트 실행 시각의 날짜를 타이틀로 사용합니다.
    return datetime.datetime.now().strftime('%Y-%m-%d')

def get_todays_commits(target_date):
    if os.getenv("FORCE_TEST") == "1":
        cmd = ["git", "-C", REPO_PATH, "log", "-n", "3", "--format=%H %B", "--", ".", ":!apps/brand-web/src/app/blog"]
    else:
        # 야간 작업과 새벽/아침 작업을 모두 커버하며, '블로그 폴더' 내의 수정사항은 무시(루프 방지)합니다.
        cmd = ["git", "-C", REPO_PATH, "log", "--since=24 hours ago", "--format=%H %B", "--", ".", ":!apps/brand-web/src/app/blog"]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    commits = result.stdout.strip().split('\n')
    if commits == [''] or not commits:
        return []
    return commits

def get_git_diff(target_date):
    if os.getenv("FORCE_TEST") == "1":
        cmd = ["git", "-C", REPO_PATH, "log", "-n", "2", "-p", "--", ".", ":!apps/brand-web/src/app/blog"]
    else:
        # 직전 24시간의 코드 변경점을 긁어오되, 블로그 마크다운 파일의 Diff는 AI 추론에서 제외시킵니다.
        cmd = ["git", "-C", REPO_PATH, "log", "--since=24 hours ago", "-p", "--", ".", ":!apps/brand-web/src/app/blog"]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout

def get_roadmap_context():
    # 1순위: 메인 ROADMAP.md (현재 진행 상태 파악용)
    main_roadmap_path = os.path.join(REPO_PATH, "ROADMAP.md")
    # 2순위: 상세 로드맵 (거시적 설계 파악용)
    macro_roadmap_path = os.path.join(REPO_PATH, "docs/roadmap/01-macro-blueprint.md")
    
    context = "### Current Project Progress (ROADMAP.md) ###\n"
    if os.path.exists(main_roadmap_path):
        with open(main_roadmap_path, "r", encoding="utf-8") as f:
            context += f.read()[:2000]
            
    context += "\n\n### Macroscopic Blueprint ###\n"
    if os.path.exists(macro_roadmap_path):
        with open(macro_roadmap_path, "r", encoding="utf-8") as f:
            context += f.read()[:1500]
            
    return context if len(context) > 100 else "(로드맵 정보를 읽을 수 없습니다.)"

# ==========================================
# 2. LM Studio 통신 (Phase Validation & COPE)
# ==========================================
def generate_omnichannel_content(commits, diff_text, target_date):
    roadmap_text = get_roadmap_context()
    
    # AI 사전 검증(Phase Analysis) 및 Chapter+Title 도출 프롬프트
    system_prompt = (
        "당신은 soluni의 설계자인 이지훈 아키텍트의 SRE 회고 봇입니다.\n"
        "아래 제공된 [Macro Blueprint(로드맵)]와 [로그/Diff]를 분석하여 생태계 관점의 글로 영문(English) 작성하십시오.\n\n"
        "작업 지시사항 (반드시 순서대로 작성):\n"
        "1. [PHASE_ANALYSIS]\n"
        "   글을 쓰기 전, 제공된 로드맵을 참고하여 오늘 코드가 어느 단계(Phase)의 어떤 '세부 핵심 작업'을 진척시켰는지 스스로 분석하십시오. (한국어로 작성해도 무방)\n\n"
        "2. [BLOG_TITLE] (MUST BE WRITTEN IN PROFESSIONAL ENGLISH)\n"
        "   Phase와 핵심 작업 키워드를 반영한 매력적이고 직관적인 영문 블로그 제목을 작성하십시오.\n"
        "   예: [Phase 1.5 | SRE Automation] Building the Omnichannel Pipeline\n"
        "   🔥주의: 절대 'Chapter 1', 'Chapter 2' 같은 무의미한 숫자 넘버링을 쓰지 마십시오! 대신 그 자리에 오늘 작업의 '가장 핵심적인 영문 키워드(예: Backend Setup, UI Polish 등)'를 넣어주세요.\n\n"
        "3. [BLOG_CONTENT] (MUST BE WRITTEN IN PROFESSIONAL ENGLISH)\n"
        "   위 Phase Analysis 결과를 유기적으로 녹여낸 아키텍처 중심의 마크다운 블로그 본문을 '영어'로 작성하십시오. 이모지는 절대 금지합니다.\n"
        "   글로벌 엔지니어들이 읽을 수 있도록 명확하고 세련된 미국식 비즈니스 영어를 구사하십시오.\n\n"
        "4. [LINKEDIN_SUMMARY] (MUST BE WRITTEN IN PROFESSIONAL ENGLISH)\n"
        "   트렌디한 비즈니스 이모지가 포함된 3줄짜리 링크드인 요약문을 '영어'로 작성하십시오.\n\n"
        "응답 템플릿 구조 (이 형식에 맞춰서만 대답하세요):\n"
        "===PHASE_ANALYSIS===\n"
        "(분석: Phase X.X, Chapter Y 등 매핑)\n"
        "===BLOG_TITLE===\n"
        "(English Blog Title)\n"
        "===BLOG_CONTENT===\n"
        "(English Blog Body)\n"
        "===LINKEDIN_SUMMARY===\n"
        "(English LinkedIn Summary)"
    )
    
    truncated_diff = diff_text[:12000]
    
    user_prompt = f"### 프로젝트 거시적 로드맵 (Macro Blueprint) ###\n{roadmap_text}\n\n"
    user_prompt += f"### 오늘의 활동 로그 ({target_date}) ###\n\n[Commits]\n"
    for c in commits:
        if c.strip():
            user_prompt += f"- {c}\n"
    user_prompt += f"\n[Code Diff Snapshot]\n{truncated_diff}\n\n위 데이터를 융합 분석하여 4개의 파트를 작성하십시오."
    
    payload = {
        "model": "qwen3-coder-30b-instruct",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
        "temperature": 0.2, 
        "max_tokens": 3000
    }
    
    headers = {"Content-Type": "application/json"}
    
    try:
        response = requests.post(LM_STUDIO_URL, data=json.dumps(payload), headers=headers)
        response.raise_for_status()
        raw_content = response.json()['choices'][0]['message']['content']
        
        # 4중 분할 파싱 구조 (Phase -> Title -> Blog -> LinkedIn)
        if "===PHASE_ANALYSIS===" in raw_content and "===BLOG_TITLE===" in raw_content and "===BLOG_CONTENT===" in raw_content:
            parts1 = raw_content.split("===BLOG_TITLE===")
            phase_analysis = parts1[0].replace("===PHASE_ANALYSIS===", "").strip()
            
            parts2 = parts1[1].split("===BLOG_CONTENT===")
            blog_title = parts2[0].strip().strip('"').strip("'")
            
            parts3 = parts2[1].split("===LINKEDIN_SUMMARY===")
            blog_part = parts3[0].strip()
            linkedin_part = parts3[1].strip() if len(parts3) > 1 else ""
            
            # Phase 추출 정규식
            phase_match = re.search(r"Phase\s*\d+(\.\d+)?", phase_analysis, re.IGNORECASE)
            assigned_phase = phase_match.group(0).capitalize() if phase_match else "Phase General"
            
            # Next.js 전용 Meta Frontmatter 조립
            frontmatter = (
                f"---\n"
                f"title: \"{blog_title}\"\n"
                f"phase: \"{assigned_phase}\"\n"
                f"date: \"{target_date}\"\n"
                f"tags: [\"sre\", \"architecture\"]\n"
                f"---\n\n"
            )
            
            final_blog = f"{frontmatter}# {blog_title}\n\n{blog_part}\n\n---\n> **🤖 Qwen3 Phase & Chapter Reasoning:**\n> {phase_analysis}"
            
            return {
                "title": blog_title,
                "blog": final_blog,
                "linkedin": linkedin_part,
                "phase": assigned_phase
            }
        else:
            return None
            
    except Exception as e:
        logging.error(f"LM Studio 연동 실패: {e}")
        return None

# ==========================================
# 3. Dev.to 글로벌 배포
# ==========================================
def publish_to_devto(markdown_content, title, target_date):
    if not DEV_TO_API_KEY:
        logging.warning("Dev.to API 환경변수를 찾을 수 없습니다.")
        return "Dev.to 연동 없음"

    headers = {
        "api-key": DEV_TO_API_KEY,
        "Content-Type": "application/json"
    }
    
    canonical_url = f"https://soluni.com/blog/posts/{target_date}-daily-sre-log"

    payload = {
        "article": {
            "title": title,
            "body_markdown": markdown_content,
            "published": False, 
            "canonical_url": canonical_url,
            "tags": ["sre", "architecture", "automation"]
        }
    }
    
    try:
        response = requests.post("https://dev.to/api/articles", headers=headers, json=payload)
        response.raise_for_status()
        return response.json().get('url', 'URL 응답 없음')
    except Exception as e:
        return f"배포 에러 ({e})"

# ==========================================
# 4. 파일 저장 및 텔레그램 분할 배달
# ==========================================
def save_and_commit_blog(blog_markdown, devto_url, linkedin_summary, target_date, assigned_phase):
    filename = f"{target_date}-daily-sre-draft.md"
    
    os.makedirs(BLOG_DIR, exist_ok=True)
    filepath = os.path.join(BLOG_DIR, filename)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(blog_markdown)
    
    send_telegram_notifications(target_date, filepath, devto_url, linkedin_summary, assigned_phase)
    
    subprocess.run(["git", "-C", REPO_PATH, "add", filepath])
    commit_msg = f"docs(blog): track [{assigned_phase}] draft tech log for {target_date}"
    subprocess.run(["git", "-C", REPO_PATH, "commit", "-m", commit_msg])

def send_telegram_notifications(date_str, filepath, devto_url, linkedin_summary, assigned_phase):
    if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID:
        logging.warning("Telegram 환경설정이 빠져있습니다. (.env 파일 확인)")
        return
        
    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    
    msg1 = (
        f"✅ [Daily SRE Draft 1차 대기 완료]\n"
        f"📍 로드맵 타겟 식별: {assigned_phase}\n\n"
        f"1. 안전 격리 구역(Drafts)에 초안 저장 및 커밋 완료.\n"
        f"2. Dev.to 글로벌 (Draft) 업로드 완료.\n\n"
        f"📁 위치: {filepath.split('Solve-for-X/')[1]}\n"
        f"🌐 Dev.to 원본 링크: {devto_url}\n"
        f"🛠️ [Dev.to 대시보드에서 직접 확인 & 발행하기]\n"
        f"👉 https://dev.to/dashboard"
    )
    requests.post(url, json={"chat_id": TELEGRAM_CHAT_ID, "text": msg1})
    
    msg2 = (
        f"🟦 [LinkedIn 전용 복붙 패키지]\n\n"
        f"{linkedin_summary}\n\n"
        f"[블로그 원본 읽기: https://soluni.com/blog/posts/{date_str}-daily-sre-log]"
    )
    requests.post(url, json={"chat_id": TELEGRAM_CHAT_ID, "text": msg2})

def send_telegram_alert(message):
    if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID:
        return
    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    try:
        requests.post(url, json={"chat_id": TELEGRAM_CHAT_ID, "text": message})
    except Exception as e:
        logging.error(f"Telegram Alert 실패: {e}")

# ==========================================
# 실행부 (Entry Point)
# ==========================================
if __name__ == "__main__":
    logging.info("--------------------------------------------------")
    logging.info("🚀 SRE COPE Omnichannel Auto-Blogger 기상...")
    send_telegram_alert("🚀 [SRE Bot] 정기 자동화 스케줄링을 시작합니다.")
    
    target_date = get_target_date()
    try:
        commits = get_todays_commits(target_date)
        if not commits:
            logging.info("오늘 수행된 Git 커밋이 없습니다. 봇을 종료합니다.")
            send_telegram_alert("ℹ️ [SRE Bot] 오늘 수행된 Git 커밋이 없어 작업을 조기 종료합니다.")
            exit(0)
            
        diff_text = get_git_diff(target_date)
        logging.info("LM Studio Qwen3 30B 통신 시작: Phase Validation 2-Step 추론 가동 중...")
        
        content_dict = generate_omnichannel_content(commits, diff_text, target_date)
        
        if content_dict:
            doc_title = content_dict['title']
            logging.info(f"선언된 페이즈({content_dict['phase']})와 챕터를 타겟팅하여 글로벌 배포를 시도합니다...")
            devto_url = publish_to_devto(content_dict["blog"], doc_title, target_date)
            
            logging.info("로컬 안전 구역(Drafts) 저장 및 텔레그램 배달 로직을 가동합니다...")
            save_and_commit_blog(content_dict["blog"], devto_url, content_dict["linkedin"], target_date, content_dict["phase"])
            logging.info("모든 파이프라인 연계 종료. 성공!")
        else:
            raise Exception("AI 초안 및 페이즈 분석 작성 오류 발생.")
            
    except Exception as e:
        error_msg = f"❌ [SRE Bot] 파이프라인 중단 에러: {str(e)}"
        logging.error(error_msg)
        send_telegram_alert(error_msg)
        exit(1)
