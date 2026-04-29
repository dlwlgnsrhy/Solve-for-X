import sqlite3
import time
import logging
import threading
from pathlib import Path
from _shared.telegram_client import TelegramClient

logger = logging.getLogger(__name__)

HERMES_DB_PATH = Path("/Users/apple/.hermes/state.db")

def start_monitor(telegram_client: TelegramClient):
    """
    백그라운드 데몬 스레드를 실행하여 Hermes의 state.db를 주기적으로 확인합니다.
    """
    t = threading.Thread(target=_monitor_loop, args=(telegram_client,), daemon=True)
    t.start()
    logger.info("[Monitor] Hermes 에이전트 모니터링 데몬 시작됨")

def _monitor_loop(telegram_client: TelegramClient):
    known_sessions = {}
    
    # 시작 시점의 최신 세션 ID들을 캐싱하여, 과거 세션의 알림이 울리는 것을 방지
    try:
        if HERMES_DB_PATH.exists():
            with sqlite3.connect(HERMES_DB_PATH) as conn:
                conn.row_factory = sqlite3.Row
                cursor = conn.cursor()
                cursor.execute("SELECT id, ended_at, message_count FROM sessions ORDER BY started_at DESC LIMIT 10")
                for row in cursor.fetchall():
                    # 재시작 시 과거 세션들이 다시 라이브로 뜨는 것을 방지
                    st = "ended" if row["ended_at"] else "running"
                    # 이미 끝난 것처럼 취급해서 굳이 알림을 띄우지 않되, 만약 진짜 돌고 있다면 나중에 감지됨
                    known_sessions[row["id"]] = {"status": st, "msg_id": None, "last_count": row["message_count"]}
    except Exception as e:
        logger.error(f"[Monitor] 초기 DB 로드 실패: {e}")

    while True:
        try:
            if not HERMES_DB_PATH.exists():
                time.sleep(10)
                continue
                
            with sqlite3.connect(HERMES_DB_PATH, timeout=5) as conn:
                conn.row_factory = sqlite3.Row
                cursor = conn.cursor()
                
                # 최근 5개의 세션 확인
                cursor.execute(
                    "SELECT id, started_at, ended_at, end_reason, message_count "
                    "FROM sessions ORDER BY started_at DESC LIMIT 5"
                )
                rows = cursor.fetchall()
                
                for row in rows:
                    session_id = row["id"]
                    status = "ended" if row["ended_at"] else "running"
                    end_reason = row["end_reason"] or "알 수 없음"
                    msg_count = row["message_count"]
                    
                    if session_id not in known_sessions:
                        # 새로 발견된 세션
                        known_sessions[session_id] = {
                            "status": status, 
                            "msg_id": None, 
                            "last_count": msg_count,
                            "last_updated": time.time(),
                            "start_time": time.time()
                        }
                        
                        if status == "running":
                            # Telegram 초기 진행 메시지 전송
                            msg_id = telegram_client.send(f"🏃‍♂️ **[Hermes 구동]** 에이전트 작업 시작!\n- 세션 ID: `{session_id}`\n⏳ 생각 준비 중...")
                            if msg_id:
                                known_sessions[session_id]["msg_id"] = msg_id
                        elif status == "ended":
                            # 너무 빨리 끝나서 running을 못 거치고 바로 ended로 발견된 경우
                            _notify_end(telegram_client, session_id, end_reason, msg_count)
                    else:
                        session_data = known_sessions[session_id]
                        old_status = session_data["status"]
                        msg_id = session_data["msg_id"]
                        
                        if status == "running":
                            # 실행 중인데 메시지 카운트가 늘었거나 10초마다 한 번씩 경과 시간 업데이트
                            now = time.time()
                            if msg_count > session_data.get("last_count", -1) or (now - session_data.get("last_ui_update", 0) > 10):
                                session_data["last_count"] = msg_count
                                session_data["last_ui_update"] = now
                                if msg_count > session_data.get("last_count", -1):
                                    session_data["last_updated"] = now
                                
                                # 최신 assistant 메시지 가져오기
                                cursor.execute(
                                    "SELECT content, tool_calls FROM messages WHERE session_id = ? AND role = 'assistant' ORDER BY timestamp DESC LIMIT 1",
                                    (session_id,)
                                )
                                last_msg = cursor.fetchone()
                                
                                content = (last_msg["content"] or "").strip() if last_msg else ""
                                tool_calls = last_msg["tool_calls"] if last_msg else None
                                
                                # 요약 생성 (최대 100자)
                                summary = content[:150].replace('\n', ' ') + ("..." if len(content) > 150 else "")
                                if not summary:
                                    summary = "데이터 분석 중..."
                                
                                # 도구 사용 표시
                                action = "🤔 생각 중..."
                                if tool_calls:
                                    import json
                                    try:
                                        tools = json.loads(tool_calls)
                                        tool_names = [t.get("function", {}).get("name") for t in tools if "function" in t]
                                        action = f"🛠 도구 사용 중: {', '.join(filter(None, tool_names))}"
                                    except:
                                        action = "🛠 도구 사용 중..."
                                        
                                elapsed = int(now - session_data.get("start_time", now))
                                live_text = f"🏃‍♂️ **[Hermes 진행 중]** ({elapsed}초 경과)\n- 세션 ID: `{session_id}`\n- 턴 수: {msg_count}\n\n{action}\n> {summary}"
                                
                                if msg_id:
                                    telegram_client.edit_message(msg_id, live_text)
                                else:
                                    new_id = telegram_client.send(live_text)
                                    if new_id:
                                        session_data["msg_id"] = new_id
                        
                        import os
                        is_process_dead = os.system('pgrep -f "hermes chat" > /dev/null') != 0
                        
                        # 프로세스가 죽었으면 즉각 종료 처리 (DB ended_at 누락 방어)
                        if is_process_dead and time.time() - session_data.get("start_time", time.time()) > 5:
                            status = "ended"
                            end_reason = "completed/exited"
                        # 타임아웃(프리즈) 감지: 300초 이상 메시지 증가가 없으면 비정상 종료로 간주
                        elif time.time() - session_data.get("last_updated", time.time()) > 300:
                            status = "ended"
                            end_reason = "timeout"

                        # 상태 변경 (running -> ended)
                        if old_status == "running" and status == "ended":
                            session_data["status"] = "ended"
                            
                            # 기존 Live 메시지는 완료 처리
                            if session_data["msg_id"]:
                                elapsed = int(time.time() - session_data.get("start_time", time.time()))
                                telegram_client.edit_message(session_data["msg_id"], f"✅ **[작업 종료]** ({elapsed}초 소요)\n- 세션 ID: `{session_id}`\n- 마지막 턴 수: {msg_count}\n- 상태: {end_reason}")
                                
                            _notify_end(telegram_client, session_id, end_reason, msg_count)
                            
        except Exception as e:
            logger.error(f"[Monitor] DB 폴링 중 오류: {e}")
            
        time.sleep(5)  # 5초 주기로 확인

def _notify_end(telegram: TelegramClient, session_id: str, reason: str, msg_count: int):
    # 최신 assistant 결과 가져오기
    final_content = ""
    try:
        with sqlite3.connect(HERMES_DB_PATH) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute(
                "SELECT content FROM messages WHERE session_id = ? AND role = 'assistant' AND content IS NOT NULL AND content != '' ORDER BY timestamp DESC LIMIT 1",
                (session_id,)
            )
            row = cursor.fetchone()
            if row:
                final_content = row["content"]
    except Exception as e:
        logger.error(f"[Monitor] 결과 추출 실패: {e}")

    # end_reason 분석
    if reason in ["normal", "stop", "completed", "completed/exited"]:
        msg = f"✅ **[에이전트 작업 완료]**\n- 세션 ID: `{session_id}`\n- 교환된 메시지 수: {msg_count}턴"
        if final_content:
            msg += f"\n\n**📄 최종 결과 리포트:**\n\n{final_content}"
        else:
            msg += "\n\n결과가 완료되었습니다. 터미널의 state.db에서 자세한 기록을 확인할 수 있습니다."
    elif reason == "error":
        msg = f"❌ **[작업 실패/에러]**\n- 세션 ID: `{session_id}`\nHermes 에이전트 실행 중 치명적 오류가 발생했습니다."
    elif reason == "interrupted":
        msg = f"⚠️ **[작업 중단]**\n- 세션 ID: `{session_id}`\n작업이 강제로 중단되었습니다 (Ctrl+C 등)."
    elif reason == "timeout":
        msg = f"⏳ **[응답 시간 초과]**\n- 세션 ID: `{session_id}`\n에이전트가 오랫동안 응답이 없어 모니터링을 종료합니다."
    else:
        msg = f"🔔 **[에이전트 종료]**\n- 세션 ID: `{session_id}`\n- 사유: {reason}"
        
    telegram.send(msg)
