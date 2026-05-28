import streamlit as st
import os
import json
import subprocess
import time
import threading
import socketserver
from http.server import SimpleHTTPRequestHandler
from dotenv import load_dotenv

# Set page configurations
st.set_page_config(
    page_title="Cloud-Native App Factory",
    page_icon="🔮",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Global helper functions for serving Flutter Web Sandbox on port 8502
def start_static_web_server():
    import socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    result = sock.connect_ex(('127.0.0.1', 8502))
    sock.close()
    if result == 0:
        return  # Server is already running on port 8502
    
    preview_dir = "/Users/apple/development/soluni/Solve-for-X/architecture/active_web_preview"
    os.makedirs(preview_dir, exist_ok=True)
    
    # Write a beautiful temporary pre-compilation dashboard page if index.html doesn't exist
    index_fallback = os.path.join(preview_dir, "index.html")
    if not os.path.exists(index_fallback):
        fallback_html = """<!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;700&display=swap" rel="stylesheet">
          <style>
            body {
              margin: 0; padding: 0;
              background: radial-gradient(circle at top, #1e1b4b, #090514);
              color: #a78bfa;
              font-family: 'Outfit', sans-serif;
              display: flex; flex-direction: column;
              justify-content: center; align-items: center;
              height: 100vh; text-align: center;
            }
            .glow-card {
              background: rgba(255, 255, 255, 0.03);
              border: 1px solid rgba(167, 139, 250, 0.2);
              border-radius: 20px;
              padding: 30px;
              box-shadow: 0 0 30px rgba(167, 139, 250, 0.1);
              backdrop-filter: blur(10px);
              max-width: 260px;
            }
            h3 { margin: 0 0 10px 0; color: #f472b6; font-size: 1.2rem; }
            p { margin: 0; font-size: 0.85rem; color: #9ca3af; line-height: 1.45; }
            .pulse {
              width: 12px; height: 12px;
              background: #ec4899; border-radius: 50%;
              margin: 15px auto 0 auto;
              animation: pulse 1.5s infinite;
            }
            @keyframes pulse {
              0% { transform: scale(0.9); opacity: 0.6; }
              50% { transform: scale(1.1); opacity: 1; }
              100% { transform: scale(0.9); opacity: 0.6; }
            }
          </style>
        </head>
        <body>
          <div class="glow-card">
            <h3>🔮 Awaiting Forge</h3>
            <p>AI Forge 빌드를 가동하면 컴파일된 실제 앱이 이 자리에 실시간으로 구동됩니다.</p>
            <div class="pulse"></div>
          </div>
        </body>
        </html>"""
        with open(index_fallback, "w", encoding="utf-8") as f:
            f.write(fallback_html)

    def run_server():
        class QuietHandler(SimpleHTTPRequestHandler):
            def __init__(self, *args, **kwargs):
                super().__init__(*args, directory=preview_dir, **kwargs)
            def log_message(self, format, *args):
                pass  # Suppress request spam logs
        
        try:
            with socketserver.TCPServer(("", 8502), QuietHandler) as httpd:
                httpd.serve_forever()
        except Exception:
            pass

    t = threading.Thread(target=run_server, daemon=True)
    t.start()

def update_web_preview_symlink(app_build_path):
    web_build_dir = os.path.join(app_build_path, "build", "web")
    preview_dir = "/Users/apple/development/soluni/Solve-for-X/architecture/active_web_preview"
    
    if not os.path.exists(web_build_dir):
        return False
        
    try:
        if os.path.exists(preview_dir) or os.path.islink(preview_dir):
            if os.path.islink(preview_dir):
                os.unlink(preview_dir)
            else:
                import shutil
                shutil.rmtree(preview_dir)
        os.symlink(web_build_dir, preview_dir)
        return True
    except Exception:
        return False

# Initialize background web preview hosting daemon
start_static_web_server()

# Load secure local .env containing API keys
ENV_PATH = "/Users/apple/development/soluni/Solve-for-X/architecture/my-app-factory/.env"
load_dotenv(ENV_PATH)

# Function to load external CSS styles safely
def load_css(file_name):
    if os.path.exists(file_name):
        with open(file_name, "r") as f:
            st.markdown(f"<style>{f.read()}</style>", unsafe_allow_html=True)

# Load premium styles
load_css("styles.css")
load_css("app-factory-dashboard/styles.css")


# Workspace paths
WORKSPACE_DIR = "/Users/apple/development/soluni/Solve-for-X/architecture"
TEMPLATE_DIR = os.path.join(WORKSPACE_DIR, "base_flutter_app")
ENGINE_SCRIPT = os.path.join(WORKSPACE_DIR, "app-factory-engine", "engine.py")
BUILDS_DIR = os.path.join(WORKSPACE_DIR, "builds")

# Ensure builds directory exists
os.makedirs(BUILDS_DIR, exist_ok=True)

# Shared Status File for telemetry monitoring
STATUS_FILE_PATH = "/Users/apple/development/soluni/Solve-for-X/architecture/build_status.json"

# =========================================================================
#  🔮 REAL-TIME BACKGROUND APP ENGINE MONITOR (SIDEBAR)
# =========================================================================
with st.sidebar:
    st.markdown("<h3 style='color: #a78bfa; margin-bottom: 2px;'>🔮 App Engine Telemetry</h3>", unsafe_allow_html=True)
    st.markdown("<p style='color: #6b7280; font-size: 0.8rem; margin-top: 0;'>Real-time Local Daemon Pipeline</p>", unsafe_allow_html=True)
    
    if os.path.exists(STATUS_FILE_PATH):
        try:
            with open(STATUS_FILE_PATH, "r") as f:
                state = json.load(f)
            
            # Premium state styling colors and labels
            status_colors = {
                "IDLE": ("#3b82f6", "Awaiting Dispatches"),
                "PROCESSING": ("#f59e0b", "Compiling Tailored App"),
                "SUCCESS": ("#10b981", "Tailored Successfully"),
                "WARNING": ("#eab308", "Build Ready (Lints)"),
                "ERROR": ("#ef4444", "Forging Failed"),
                "OFFLINE": ("#6b7280", "Engine Offline")
            }
            
            curr_status = state.get("status", "IDLE")
            color, label = status_colors.get(curr_status, ("#6b7280", "Unknown State"))
            
            # Status Box Card
            st.markdown(f"""
            <div style='padding: 12px; border-radius: 8px; background: rgba(255,255,255,0.02); border: 1px solid rgba(255,255,255,0.06); margin-bottom: 12px;'>
                <div style='display: flex; justify-content: space-between; align-items: center;'>
                    <span style='font-size: 0.85rem; color: #9ca3af; font-weight: bold;'>Pipeline Stage</span>
                    <span style='background-color: {color}; color: #ffffff; padding: 2px 8px; border-radius: 12px; font-size: 0.7rem; font-weight: bold;'>{curr_status}</span>
                </div>
                <div style='margin-top: 8px; font-size: 0.75rem; color: #6b7280;'>
                    Current Stage: <span style='color: #d1d5db; font-weight: 500;'>{state.get("current_stage")}</span>
                </div>
            </div>
            """, unsafe_allow_html=True)
            
            # Interactive Progress bar
            prog_val = float(state.get("progress", 0.0))
            st.progress(prog_val, text=f"Stage Progress: {int(prog_val * 100)}%")
            
            # Detailed Info Box
            st.markdown("<p style='font-size: 0.8rem; color: #a78bfa; margin-bottom: 4px; font-weight: 500;'>Active Log telemetry:</p>", unsafe_allow_html=True)
            st.info(state.get("message", "Awaiting requests..."))
            
            if state.get("error"):
                st.error(f"Engine Exception:\n{state.get('error')}")
                
            st.markdown(f"<p style='font-size: 0.7rem; color: #4b5563; text-align: right;'>Last telemetry: {state.get('timestamp')}</p>", unsafe_allow_html=True)
            
        except Exception as e:
            st.caption(f"Reading telemetry stream... ({e})")
    else:
        st.markdown("""
        <div style='padding: 15px; border-radius: 8px; background: rgba(59, 130, 246, 0.04); border: 1px dashed rgba(59, 130, 246, 0.2);'>
            <p style='color: #93c5fd; font-size: 0.8rem; margin: 0;'>
                🟢 Local listener daemon ready to initialize. Run the daemon on this Mac to poll Repository Dispatch events and stream telemetry here.
            </p>
        </div>
        """, unsafe_allow_html=True)
        
    st.divider()
    
    # Real-time Auto-Refresh mechanism
    auto_refresh = st.checkbox("🔄 Auto-Poll Telemetry (3s)", value=True)

st.sidebar.caption("Antigravity Local Engine Integration v1.2")
st.sidebar.divider()


# Title & Dashboard Branding
st.markdown("""
<div class='glass-card'>
    <span class='pipeline-badge'>CONTROL PLANE v1.2.0</span>
    <h1 class='gradient-text' style='margin: 10px 0 0 0; font-size: 2.8rem;'>CLOUD-NATIVE APP FACTORY</h1>
    <p style='color: #a78bfa; margin-top: 5px;'>Autonomous Core Engine for On-Demand Micro-Tenant App Synthesis</p>
</div>
""", unsafe_allow_html=True)

# Establish premium double tabs
tab_manual, tab_ai = st.tabs([
    "🔧 직접 매개변수 설정 (Direct Parameter Customization)", 
    "🎨 AI & 오픈디자인 프로토타입 주조 (AI Design Forge)"
])

with tab_manual:
    col1, col2 = st.columns([1, 1.2])
    
    with col1:
        st.markdown("<h3 style='color: #ec4899;'>🛠️ Application Parameters</h3>", unsafe_allow_html=True)
        
        with st.container(border=True):
            app_name = st.text_input("Application Name", value="Horizon Portal", key="app_name_inp")
            package_name = st.text_input("Package ID / Bundle Identifier", value="com.horizon.portal", key="pkg_name_inp")
            version = st.text_input("Build Version", value="1.0.0", key="version_inp")
            api_base_url = st.text_input("API Gateway Endpoint", value="https://api.horizon-platform.io", key="api_inp")
            
            # Color palettes
            sub_col1, sub_col2 = st.columns(2)
            with sub_col1:
                primary_color = st.color_picker("Primary Glow Color", value="#6366F1", key="p_color_picker")
            with sub_col2:
                secondary_color = st.color_picker("Accent Highlight Color", value="#EC4899", key="s_color_picker")
                
            background_color = st.color_picker("Dark Background Color", value="#090514", key="bg_color_picker")
            card_color = st.color_picker("Panel Card Color", value="#120B24", key="card_color_picker")

        st.markdown("<h3 style='color: #ec4899;'>⚡ Navigation & Modules</h3>", unsafe_allow_html=True)
        with st.container(border=True):
            enable_chat = st.checkbox("Enable Chat Service Interface", value=True, key="enable_chat_cb")
            enable_profile = st.checkbox("Enable Dynamic Profiles Portal", value=True, key="enable_profile_cb")
            enable_settings = st.checkbox("Enable Platform Settings Dashboard", value=True, key="enable_settings_cb")
            
            hero_title = st.text_input("Welcome Hero Header", value="Dynamic Workspace Active", key="hero_title_inp")
            hero_subtitle = st.text_area("Welcome Hero Subtitle", value="Seamless multi-tenant edge client generated completely in real-time.", key="hero_sub_inp")

    with col2:
        st.markdown("<h3 style='color: #a855f7;'>📜 Core JSON Specification</h3>", unsafe_allow_html=True)
        
        spec_data = {
            "app_name": app_name,
            "package_name": package_name,
            "version": version,
            "api_base_url": api_base_url,
            "primary_color": primary_color,
            "secondary_color": secondary_color,
            "background_color": background_color,
            "card_color": card_color,
            "enable_chat": enable_chat,
            "enable_profile": enable_profile,
            "enable_settings": enable_settings,
            "hero_title": hero_title,
            "hero_subtitle": hero_subtitle,
            "dynamic_items": [
                {
                    "title": "Edge Compute Core",
                    "description": "High-throughput model execution pipeline.",
                    "icon": "bolt"
                },
                {
                    "title": "Distributed Fabric",
                    "description": "Zero latency micro-services synchronized globally.",
                    "icon": "layers"
                },
                {
                    "title": "Elastic Registry",
                    "description": "Multi-tenant directory with autonomous registration.",
                    "icon": "grain"
                }
            ]
        }
        
        json_spec_str = st.text_area(
            "Edit Raw Application AST (JSON)",
            value=json.dumps(spec_data, indent=2, ensure_ascii=False),
            height=320,
            key="json_spec_inp"
        )
        
        clean_app_id = package_name.replace(".", "_").lower()
        target_build_path = os.path.join(BUILDS_DIR, clean_app_id)
        st.markdown(f"**Target Build Destination:** `{target_build_path}`")
        
        act_col1, act_col2 = st.columns(2)
        with act_col1:
            start_build = st.button("🔥 앱 생성 엔진 가동 (Build App)", key="btn_build_manual")
        with act_col2:
            run_verify = st.button("🛡️ 무결성 테스트 검증 (Verify Integrity)", key="btn_verify_manual")

with tab_ai:
    ai_col1, ai_col2 = st.columns([1.15, 1])
    
    with ai_col1:
        st.markdown("<h3 style='color: #3b82f6; margin-top: 0;'>🎨 AI 브랜드 프로토타입 주조소 (Design Forge)</h3>", unsafe_allow_html=True)
        st.markdown("""
        신규 모바일/웹 프로토타입 스펙을 상세히 설정하고 고성능 **Gemma 4 31B Instruct** 지능형 엔진을 가동하여 문법 오류 없는 Flutter 모바일 코드를 자동으로 주조합니다.
        """)
        
        # Premium 86 Design Systems brand color tokens dictionary matching VoltAgent/awesome-design-md (72+ parity)
        brand_tokens = {
            "미니멀 모던 (Neutral Modern)": {"p_c": "#3b82f6", "s_c": "#10b981", "bg_c": "#f3f4f6", "card_c": "#ffffff"},
            "포근한 파스텔 (Cozy Warm Pastel)": {"p_c": "#a78bfa", "s_c": "#f472b6", "bg_c": "#f9fafb", "card_c": "#ffffff"},
            "네온 사이버펑크 (Cyberpunk Neon)": {"p_c": "#00f0ff", "s_c": "#ff007f", "bg_c": "#090514", "card_c": "#120b24"},
            "시크 다크 프로페셔널 (Sleek Dark Professional)": {"p_c": "#6366f1", "s_c": "#ec4899", "bg_c": "#0b0f19", "card_c": "#111827"},
            "에메랄드 가든 (Emerald Garden)": {"p_c": "#34d399", "s_c": "#047857", "bg_c": "#f0fdf4", "card_c": "#ffffff"},
            "노을빛 선셋 (Sunset Glow)": {"p_c": "#f87171", "s_c": "#fbbf24", "bg_c": "#fffbeb", "card_c": "#ffffff"},
            "클래식 로열 (Royal Velvet)": {"p_c": "#8b5cf6", "s_c": "#f59e0b", "bg_c": "#0f0a1c", "card_c": "#16102b"},
            "도쿄 나이트 (Tokyo Night)": {"p_c": "#7aa2f7", "s_c": "#ff007f", "bg_c": "#1a1b26", "card_c": "#24283b"},
            "북유럽 브리즈 (Nordic Breeze)": {"p_c": "#88c0d0", "s_c": "#81a1c1", "bg_c": "#d8dee9", "card_c": "#e5e9f0"},
            "드라큘라 헤이즈 (Dracula Haze)": {"p_c": "#bd93f9", "s_c": "#50fa7b", "bg_c": "#282a36", "card_c": "#44475a"},
            "솔라라이즈드 라이트 (Solarized Light)": {"p_c": "#b58900", "s_c": "#2aa198", "bg_c": "#fdf6e3", "card_c": "#eee8d5"},
            "솔라라이즈드 다크 (Solarized Dark)": {"p_c": "#268bd2", "s_c": "#859900", "bg_c": "#002b36", "card_c": "#073642"},
            "샌드스톤 코지 (Sandstone Cozy)": {"p_c": "#b45309", "s_c": "#d97706", "bg_c": "#fffbeb", "card_c": "#fef3c7"},
            "로즈 골드 미니멀 (Rose Gold Minimal)": {"p_c": "#fda4af", "s_c": "#b45309", "bg_c": "#fff5f5", "card_c": "#ffffff"},
            "딥 스페이스 다크 (Deep Space)": {"p_c": "#38bdf8", "s_c": "#c084fc", "bg_c": "#030712", "card_c": "#111827"},
            "Vercel (Vercel)": {"p_c": "#000000", "s_c": "#ffffff", "bg_c": "#fafafa", "card_c": "#ffffff"},
            "Stripe (Stripe)": {"p_c": "#635bff", "s_c": "#00d4ff", "bg_c": "#f8f9fa", "card_c": "#ffffff"},
            "Linear (Linear)": {"p_c": "#5e6ad2", "s_c": "#b4bcfe", "bg_c": "#0c0d0e", "card_c": "#151618"},
            "Notion (Notion)": {"p_c": "#000000", "s_c": "#f1f1ef", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Apple Interface (Apple)": {"p_c": "#007aff", "s_c": "#8e8e93", "bg_c": "#f5f5f7", "card_c": "#ffffff"},
            "Airbnb Cozy (Airbnb)": {"p_c": "#ff5a5f", "s_c": "#00a699", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Figma Brand (Figma)": {"p_c": "#f24e1e", "s_c": "#a259ff", "bg_c": "#fafafa", "card_c": "#ffffff"},
            "GitHub Primer (GitHub)": {"p_c": "#24292f", "s_c": "#0969da", "bg_c": "#f6f8fa", "card_c": "#ffffff"},
            "Tesla Red (Tesla)": {"p_c": "#e82127", "s_c": "#1e1e1e", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Slack Aubergine (Slack)": {"p_c": "#4a154b", "s_c": "#36c5f0", "bg_c": "#f8f9fa", "card_c": "#ffffff"},
            "Discord Blurple (Discord)": {"p_c": "#5865f2", "s_c": "#57f287", "bg_c": "#0f1015", "card_c": "#181920"},
            "OpenAI Mint (OpenAI)": {"p_c": "#10a37f", "s_c": "#1c1c1c", "bg_c": "#ffffff", "card_c": "#f7f7f8"},
            "Shopify Polaris (Shopify)": {"p_c": "#96bf48", "s_c": "#008060", "bg_c": "#f6f6f7", "card_c": "#ffffff"},
            "Spotify Dark (Spotify)": {"p_c": "#1db954", "s_c": "#191414", "bg_c": "#191414", "card_c": "#282828"},
            "Anthropic Claude (Claude)": {"p_c": "#cc9977", "s_c": "#191919", "bg_c": "#f9f8f6", "card_c": "#ffffff"},
            "Replicate Dark (Replicate)": {"p_c": "#000000", "s_c": "#ff0055", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Zoom Communication (Zoom)": {"p_c": "#2d8cff", "s_c": "#f26522", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Netflix Cinematic (Netflix)": {"p_c": "#e50914", "s_c": "#221f1f", "bg_c": "#141414", "card_c": "#1f1f1f"},
            "Microsoft Fluent (Microsoft)": {"p_c": "#0078d4", "s_c": "#107c41", "bg_c": "#f3f3f3", "card_c": "#ffffff"},
            "Google Material (Google)": {"p_c": "#4285f4", "s_c": "#ea4335", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "AWS Technical (AWS)": {"p_c": "#ff9900", "s_c": "#232f3e", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Supabase Tech (Supabase)": {"p_c": "#3ecf8e", "s_c": "#30a46c", "bg_c": "#1c1c1c", "card_c": "#242424"},
            "PlanetScale Orange (PlanetScale)": {"p_c": "#000000", "s_c": "#ff4400", "bg_c": "#fafafa", "card_c": "#ffffff"},
            "Resend Email (Resend)": {"p_c": "#000000", "s_c": "#ff3366", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "V0 Synthesis (V0)": {"p_c": "#000000", "s_c": "#ffffff", "bg_c": "#0a0a0a", "card_c": "#171717"},
            "Cursor AI (Cursor)": {"p_c": "#00e1d9", "s_c": "#9333ea", "bg_c": "#0b0f17", "card_c": "#131b2e"},
            "Framer Web (Framer)": {"p_c": "#0055ff", "s_c": "#ff0055", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Raycast Core (Raycast)": {"p_c": "#ff6363", "s_c": "#ff9999", "bg_c": "#18181b", "card_c": "#27272a"},
            "Retool Internal (Retool)": {"p_c": "#3c6df0", "s_c": "#333333", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Mailchimp Yellow (Mailchimp)": {"p_c": "#ffe01b", "s_c": "#007c89", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Dropbox Cloud (Dropbox)": {"p_c": "#0061ff", "s_c": "#1e1915", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Pinterest Board (Pinterest)": {"p_c": "#bd081c", "s_c": "#333333", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Uber Base (Uber)": {"p_c": "#000000", "s_c": "#276ef1", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Robinhood Emerald (Robinhood)": {"p_c": "#00c805", "s_c": "#1e1e1e", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Revolut Blue (Revolut)": {"p_c": "#000000", "s_c": "#0075eb", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Wise Neon (Wise)": {"p_c": "#00e676", "s_c": "#003366", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Duolingo Duo (Duolingo)": {"p_c": "#58cc02", "s_c": "#ffc200", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Canva Creative (Canva)": {"p_c": "#00c4cc", "s_c": "#7d2ae8", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Miro Yellow (Miro)": {"p_c": "#ffd02b", "s_c": "#050038", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Loom Video (Loom)": {"p_c": "#625df5", "s_c": "#ff635c", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Pitch Decks (Pitch)": {"p_c": "#000000", "s_c": "#2fcc71", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Intercom Chat (Intercom)": {"p_c": "#0057ff", "s_c": "#3d4d5c", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Asana Tasks (Asana)": {"p_c": "#fc636b", "s_c": "#373a3c", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Jira Blue (Jira)": {"p_c": "#0052cc", "s_c": "#172b4d", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Sentry Purple (Sentry)": {"p_c": "#362d59", "s_c": "#fb424a", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Datadog Neon (Datadog)": {"p_c": "#632ca6", "s_c": "#ff9000", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Cloudflare Flare (Cloudflare)": {"p_c": "#f38020", "s_c": "#2c7cb0", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "HashiCorp Gray (HashiCorp)": {"p_c": "#60a5fa", "s_c": "#000000", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Heroku Purple (Heroku)": {"p_c": "#79589f", "s_c": "#430099", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Netlify Teal (Netlify)": {"p_c": "#00ad9f", "s_c": "#20c997", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Vercel Geist System (Geist)": {"p_c": "#000000", "s_c": "#888888", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "IBM Carbon Grid (IBM)": {"p_c": "#0f62fe", "s_c": "#393939", "bg_c": "#f4f4f4", "card_c": "#ffffff"},
            "Salesforce Lightning UI (Salesforce)": {"p_c": "#0176d3", "s_c": "#1b96ff", "bg_c": "#f3f3f3", "card_c": "#ffffff"},
            "Atlassian Design System (Atlassian)": {"p_c": "#0052cc", "s_c": "#00b8d9", "bg_c": "#fafbfc", "card_c": "#ffffff"},
            "Adobe Spectrum UI (Adobe)": {"p_c": "#1473e6", "s_c": "#2c2c2c", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Tailwind CSS Dark (Tailwind)": {"p_c": "#06b6d4", "s_c": "#3b82f6", "bg_c": "#0f172a", "card_c": "#1e293b"},
            "Material Design 3 (Material)": {"p_c": "#6750a4", "s_c": "#625b71", "bg_c": "#fef7ff", "card_c": "#ffffff"},
            "Apple Human Interface Guidelines (AppleHIG)": {"p_c": "#007aff", "s_c": "#34c759", "bg_c": "#f2f2f7", "card_c": "#ffffff"},
            "Fluent Design Microsoft (Fluent)": {"p_c": "#0078d4", "s_c": "#2b579a", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Shopify Polaris System (Polaris)": {"p_c": "#008060", "s_c": "#004b36", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Carbon Design IBM (Carbon)": {"p_c": "#161616", "s_c": "#393939", "bg_c": "#f4f4f4", "card_c": "#ffffff"},
            "Primer GitHub Design (Primer)": {"p_c": "#0969da", "s_c": "#24292f", "bg_c": "#f6f8fa", "card_c": "#ffffff"},
            "Base Design Uber System (Base)": {"p_c": "#000000", "s_c": "#5b616a", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Evergreen Segment UI (Evergreen)": {"p_c": "#10b981", "s_c": "#047857", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Garden Zendesk UI (Garden)": {"p_c": "#03363d", "s_c": "#174f57", "bg_c": "#f5f7f7", "card_c": "#ffffff"},
            "EUI Elastic Design (EUI)": {"p_c": "#006bb4", "s_c": "#00b3a4", "bg_c": "#fafbfc", "card_c": "#ffffff"},
            "Ant Design System (AntDesign)": {"p_c": "#1890ff", "s_c": "#2f54eb", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Chakra UI Indigo (Chakra)": {"p_c": "#319795", "s_c": "#805ad5", "bg_c": "#edf2f7", "card_c": "#ffffff"},
            "Shadcn UI Minimalist (Shadcn)": {"p_c": "#09090b", "s_c": "#71717a", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "DaisyUI Theme System (DaisyUI)": {"p_c": "#570df8", "s_c": "#f000b8", "bg_c": "#ffffff", "card_c": "#ffffff"},
            "Bulma CSS Modern (Bulma)": {"p_c": "#00d1b2", "s_c": "#3273dc", "bg_c": "#fafafa", "card_c": "#ffffff"},
        }
        
        with st.container(border=True):
            st.markdown("<h4 style='color: #60a5fa; margin: 0 0 10px 0;'>✨ 신규 프로토타입 설계</h4>", unsafe_allow_html=True)
            proto_project_name = st.text_input("프로젝트 이름 (Project Name)", value="SafeSpace", key="proto_name_inp")
            
            # Automatically calculate target Package ID programmatically inside backend
            import re
            clean_proj_name = re.sub(r'[^a-zA-Z0-9]', '', proto_project_name.lower())
            if not clean_proj_name:
                clean_proj_name = "customapp"
            proto_package_name = f"com.{clean_proj_name}.privacy"
            
            st.divider()
            
            st.markdown("<h4 style='color: #a78bfa; margin: 0 0 10px 0;'>🎨 브랜드 디자인 시스템 토큰</h4>", unsafe_allow_html=True)
            proto_design_system = st.selectbox(
                "브랜드 비주얼 컬러 시스템 선택",
                options=list(brand_tokens.keys()),
                index=1,
                key="proto_sys_sb"
            )
            
            st.markdown("<h4 style='color: #a78bfa; margin: 15px 0 10px 0;'>📱 배포 아키텍처 플랫폼</h4>", unsafe_allow_html=True)
            proto_target_platform = st.selectbox(
                "모바일/웹 빌드 아키텍처 지정",
                options=["Flutter 모바일 (Flutter Mobile)", "반응형 웹 (Responsive Web)", "Flutter 데스크톱 (Flutter Desktop)"],
                index=0,
                key="proto_plat_sb"
            )
            
            st.divider()
            
            st.markdown("<h4 style='color: #f472b6; margin: 0 0 5px 0;'>🔗 동반 레이아웃 (Companion Surfaces)</h4>", unsafe_allow_html=True)
            proto_landing_page = st.toggle("랜딩 페이지 포함 (Include Landing Page)", value=True, key="proto_landing_tg")
            proto_os_widgets = st.toggle("OS 위젯 포함 (Include OS Widgets)", value=True, key="proto_widgets_tg")
            st.markdown("""
            <p style='color: #9ca3af; font-size: 0.8rem; margin-top: 2px; margin-bottom: 12px; line-height: 1.45;'>
                💡 모바일 앱 외에 함께 생성할 다중 채널 화면을 지정합니다. 랜딩 페이지 및 OS 홈스크린용 위젯 컴포넌트를 활성화하여 멀티 디바이스 환경을 구축합니다.
            </p>
            """, unsafe_allow_html=True)
            
            st.divider()
            
            st.markdown("<h4 style='color: #ec4899; margin: 0 0 5px 0;'>🎯 설계 정밀도 (Fidelity)</h4>", unsafe_allow_html=True)
            proto_fidelity = st.radio(
                "피델리티 단계 지정",
                options=["와이어프레임 (Wireframe)", "고정밀 디자인 (High fidelity)"],
                index=1,
                horizontal=True,
                key="proto_fidel_rd"
            )
            st.markdown("""
            <p style='color: #9ca3af; font-size: 0.8rem; margin-top: 2px; margin-bottom: 12px; line-height: 1.45;'>
                💡 <b>와이어프레임 (Wireframe)</b>: 불필요한 장식과 색상을 배제하고 레이아웃과 UI 그리드 뼈대만을 신속히 컴파일하여 직관적인 프로토타입을 설계합니다. (시뮬레이터에 무채색 회색조 테두리가 즉시 적용됩니다)<br>
                🎨 <b>고정밀 디자인 (High fidelity)</b>: 선택한 디자인 시스템 토큰(HSL 컬러, 서체, 24px 둥근 모서리 곡률)을 풍부하게 적용하여 완성도 높은 고품질 앱을 주조합니다.
            </p>
            """, unsafe_allow_html=True)
            
            st.divider()
            
            st.markdown("<h4 style='color: #60a5fa; margin: 0 0 10px 0;'>🤖 앱 개발 요구사항 설명 (Application Prompt)</h4>", unsafe_allow_html=True)
            proto_prompt = st.text_area(
                "앱의 핵심 기능 및 연동 모듈을 자연어로 기술해 주세요",
                value="A highly secure personal privacy lockbox app featuring an encrypted biometric vault, a private daily mindful journal with local-only storage, and real-time sentinel biometric lock logs.",
                height=120,
                key="proto_prompt_ta"
            )
            
        clean_ai_id = proto_package_name.replace(".", "_").lower()
        target_ai_path = os.path.join(BUILDS_DIR, clean_ai_id)
        
        st.markdown(f"**Target Build Destination:** `{target_ai_path}`")
        
        act_ai_col1, act_ai_col2 = st.columns(2)
        with act_ai_col1:
            start_ai_build = st.button("🚀 AI 브랜드 프로토타입 주조 가동 (Launch AI Forge)", key="btn_build_ai")
        with act_ai_col2:
            run_ai_verify = st.button("🛡️ AI 생성 앱 정적 무결성 스캔 (Verify AI Build)", key="btn_verify_ai")
            
    with ai_col2:
        st.markdown("<h3 style='color: #a855f7; margin-top: 0;'>📱 인터랙티브 시뮬레이터 (Interactive Simulator)</h3>", unsafe_allow_html=True)
        st.markdown("<p style='color: #6b7280; font-size: 0.85rem; margin-top: 0;'>주조 중인 테넌트 앱의 디자인 토큰 및 구성 요소를 아래 시뮬레이터에서 실시간으로 조작해 보세요!</p>", unsafe_allow_html=True)
        
        # Real-time visual binding: override simulator colors immediately when selectbox is toggled!
        selected_tokens = brand_tokens.get(proto_design_system, brand_tokens["포근한 파스텔 (Cozy Warm Pastel)"])
        p_c = selected_tokens["p_c"]
        s_c = selected_tokens["s_c"]
        bg_c = selected_tokens["bg_c"]
        card_c = selected_tokens["card_c"]
        
        # Override with flat grayscale colors if Wireframe is selected!
        if proto_fidelity == "와이어프레임 (Wireframe)":
            p_c = "#9ca3af"
            s_c = "#4b5563"
            bg_c = "#f9fafb"
            card_c = "#ffffff"
            
        # Ingest active spec
        sim_spec = {
            "app_name": proto_project_name,
            "primary_color": p_c,
            "secondary_color": s_c,
            "background_color": bg_c,
            "card_color": card_c,
            "hero_title": "Your Safe Haven" if "privacy" in proto_prompt.lower() or "safe" in proto_project_name.lower() else "Dynamic Workspace Active",
            "hero_subtitle": "A beautifully soft, highly secure environment protecting your private thoughts and secure data." if "privacy" in proto_prompt.lower() or "safe" in proto_project_name.lower() else "Seamless multi-tenant edge client generated completely in real-time.",
            "dynamic_items": [
                {"title": "Encrypted Vault" if "privacy" in proto_prompt.lower() or "safe" in proto_project_name.lower() else "Edge Compute Core", "description": "Zero-knowledge hardware lockbox protecting your passwords and credentials." if "privacy" in proto_prompt.lower() or "safe" in proto_project_name.lower() else "High-throughput model execution pipeline.", "icon": "security" if "privacy" in proto_prompt.lower() or "safe" in proto_project_name.lower() else "bolt"},
                {"title": "Mindful Journal" if "privacy" in proto_prompt.lower() or "safe" in proto_project_name.lower() else "Distributed Fabric", "description": "A private safe diary to log your daily emotional highlights with zero cloud leakage." if "privacy" in proto_prompt.lower() or "safe" in proto_project_name.lower() else "Zero latency micro-services synchronized globally.", "icon": "favorite" if "privacy" in proto_prompt.lower() or "safe" in proto_project_name.lower() else "layers"},
                {"title": "Sentinel Guard" if "privacy" in proto_prompt.lower() or "safe" in proto_project_name.lower() else "Elastic Registry", "description": "Real-time biometric threat logs capturing lock attempts." if "privacy" in proto_prompt.lower() or "safe" in proto_project_name.lower() else "Multi-tenant directory with autonomous registration.", "icon": "shield" if "privacy" in proto_prompt.lower() or "safe" in proto_project_name.lower() else "grain"}
            ]
        }
        
        # HEX colors
        app_n = sim_spec.get("app_name", proto_project_name)
        hero_t = sim_spec.get("hero_title", "Your Safe Haven")
        hero_sub = sim_spec.get("hero_subtitle", "A secure environment protecting your data.")
        
        items = sim_spec.get("dynamic_items", [])
        item1_t = items[0].get("title", "Encrypted Vault") if len(items) > 0 else "Encrypted Vault"
        item1_d = items[0].get("description", "Zero-knowledge hardware lockbox.") if len(items) > 0 else "Zero-knowledge hardware lockbox."
        item1_i = items[0].get("icon", "security") if len(items) > 0 else "security"
        
        item2_t = items[1].get("title", "Mindful Journal") if len(items) > 1 else "Mindful Journal"
        item2_d = items[1].get("description", "A private safe diary.") if len(items) > 1 else "A private safe diary."
        item2_i = items[1].get("icon", "favorite") if len(items) > 1 else "favorite"
        
        item3_t = items[2].get("title", "Sentinel Guard") if len(items) > 2 else "Sentinel Guard"
        item3_d = items[2].get("description", "Real-time biometric logs.") if len(items) > 2 else "Real-time biometric logs."
        item3_i = items[2].get("icon", "shield") if len(items) > 2 else "shield"
        
        preview_index_path = "/Users/apple/development/soluni/Solve-for-X/architecture/active_web_preview/index.html"
        has_compiled_app = os.path.exists(preview_index_path)
        
        import streamlit.components.v1 as components
        
        if has_compiled_app:
            web_sandbox_html = f"""
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;700&display=swap" rel="stylesheet">
              <style>
                body {{
                  margin: 0;
                  padding: 0;
                  background: transparent;
                  display: flex;
                  justify-content: center;
                  align-items: center;
                  font-family: 'Outfit', sans-serif;
                }}
                .phone-body {{
                  width: 320px;
                  height: 640px;
                  background: #1f1d2b;
                  border: 10px solid #1f1d2b;
                  border-radius: 36px;
                  box-shadow: 0 20px 40px rgba(0,0,0,0.6);
                  position: relative;
                  overflow: hidden;
                  display: flex;
                  flex-direction: column;
                  transition: all 0.3s ease;
                }}
                .notch {{
                  width: 120px;
                  height: 20px;
                  background: #1f1d2b;
                  position: absolute;
                  top: 0;
                  left: 50%;
                  transform: translateX(-50%);
                  border-bottom-left-radius: 12px;
                  border-bottom-right-radius: 12px;
                  z-index: 100;
                }}
                .phone-iframe {{
                  width: 100%;
                  height: 100%;
                  border: none;
                  border-radius: 28px;
                  background: #090514;
                }}
              </style>
            </head>
            <body>
              <div class="phone-body">
                <div class="notch"></div>
                <iframe class="phone-iframe" src="http://localhost:8502/"></iframe>
              </div>
            </body>
            </html>
            """
            components.html(web_sandbox_html, height=660)
        else:
            device_simulator_html = f"""
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;700&display=swap" rel="stylesheet">
          <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
          <style>
            body {{
              margin: 0;
              padding: 0;
              background: transparent;
              display: flex;
              justify-content: center;
              align-items: center;
              font-family: 'Outfit', sans-serif;
            }}
            .phone-body {{
              width: 320px;
              height: 640px;
              background: {bg_c};
              border: 10px solid #1f1d2b;
              border-radius: 36px;
              box-shadow: 0 20px 40px rgba(0,0,0,0.6);
              position: relative;
              overflow: hidden;
              display: flex;
              flex-direction: column;
              transition: all 0.3s ease;
            }}
            .notch {{
              width: 120px;
              height: 20px;
              background: #1f1d2b;
              position: absolute;
              top: 0;
              left: 50%;
              transform: translateX(-50%);
              border-bottom-left-radius: 12px;
              border-bottom-right-radius: 12px;
              z-index: 100;
            }}
            .status-bar {{
              height: 25px;
              padding: 5px 20px 0 20px;
              display: flex;
              justify-content: space-between;
              font-size: 11px;
              color: #6b7280;
              z-index: 10;
              margin-top: 5px;
            }}
            .screen {{
              flex: 1;
              display: none;
              flex-direction: column;
              padding: 15px;
              overflow-y: auto;
              animation: fadeIn 0.3s ease;
            }}
            .screen.active {{
              display: flex;
            }}
            @keyframes fadeIn {{
              from {{ opacity: 0; transform: translateY(5px); }}
              to {{ opacity: 1; transform: translateY(0); }}
            }}
            .header {{
              display: flex;
              justify-content: space-between;
              align-items: center;
              margin-top: 10px;
              margin-bottom: 15px;
            }}
            .header h2 {{
              margin: 0;
              font-size: 18px;
              color: #1f2937;
              font-weight: 700;
            }}
            .header span {{
              background: {p_c}20;
              color: {p_c};
              padding: 3px 8px;
              border-radius: 12px;
              font-size: 11px;
              font-weight: bold;
            }}
            .hero-card {{
              background: linear-gradient(135deg, {p_c}15, {s_c}15);
              border: 1px solid {p_c}30;
              padding: 15px;
              border-radius: 20px;
              margin-bottom: 15px;
            }}
            .hero-card h3 {{
              margin: 0 0 5px 0;
              font-size: 15px;
              color: #111827;
            }}
            .hero-card p {{
              margin: 0;
              font-size: 11px;
              color: #4b5563;
              line-height: 1.4;
            }}
            .module-card {{
              background: {card_c};
              border: 1px solid rgba(0,0,0,0.05);
              padding: 12px;
              border-radius: 20px;
              margin-bottom: 10px;
              display: flex;
              align-items: center;
              box-shadow: 0 4px 6px rgba(0,0,0,0.02);
            }}
            .module-icon {{
              width: 36px;
              height: 36px;
              border-radius: 10px;
              background: {p_c}20;
              color: {p_c};
              display: flex;
              justify-content: center;
              align-items: center;
              margin-right: 12px;
            }}
            .module-info {{
              flex: 1;
            }}
            .module-info h4 {{
              margin: 0 0 2px 0;
              font-size: 12px;
              color: #1f2937;
            }}
            .module-info p {{
              margin: 0;
              font-size: 10px;
              color: #6b7280;
            }}
            .nav-bar {{
              height: 55px;
              background: {card_c};
              border-top: 1px solid rgba(0,0,0,0.05);
              display: flex;
              justify-content: space-around;
              align-items: center;
              z-index: 10;
            }}
            .nav-item {{
              display: flex;
              flex-direction: column;
              align-items: center;
              color: #9ca3af;
              cursor: pointer;
              transition: all 0.2s ease;
            }}
            .nav-item.active {{
              color: {p_c};
            }}
            .nav-item span {{
              font-size: 10px;
              margin-top: 2px;
            }}
            /* Interactive lock overlay */
            .bio-overlay {{
              position: absolute;
              top: 0;
              left: 0;
              right: 0;
              bottom: 0;
              background: rgba(9, 5, 20, 0.95);
              backdrop-filter: blur(10px);
              display: none;
              flex-direction: column;
              justify-content: center;
              align-items: center;
              z-index: 1000;
              animation: fadeIn 0.3s ease;
            }}
            .fingerprint-btn {{
              width: 80px;
              height: 80px;
              border-radius: 50%;
              background: {p_c}20;
              border: 2px solid {p_c};
              color: {p_c};
              display: flex;
              justify-content: center;
              align-items: center;
              font-size: 40px;
              cursor: pointer;
              animation: pulse 1.5s infinite;
              transition: all 0.3s ease;
            }}
            @keyframes pulse {{
              0% {{ box-shadow: 0 0 0 0 {p_c}40; }}
              70% {{ box-shadow: 0 0 0 15px {p_c}0; }}
              100% {{ box-shadow: 0 0 0 0 {p_c}0; }}
            }}
            .lock-screen-btn {{
              background: {p_c};
              color: white;
              border: none;
              padding: 10px 20px;
              border-radius: 20px;
              cursor: pointer;
              font-weight: bold;
              margin-top: 15px;
            }}
            /* Settings controls */
            .settings-row {{
              display: flex;
              justify-content: space-between;
              align-items: center;
              padding: 10px 0;
              border-bottom: 1px solid rgba(0,0,0,0.05);
            }}
            .settings-row label {{
              font-size: 12px;
              color: #374151;
            }}
            /* Toggle Switch */
            .switch {{
              position: relative;
              display: inline-block;
              width: 34px;
              height: 20px;
            }}
            .switch input {{
              opacity: 0;
              width: 0;
              height: 0;
            }}
            .slider {{
              position: absolute;
              cursor: pointer;
              top: 0;
              left: 0;
              right: 0;
              bottom: 0;
              background-color: #ccc;
              transition: .4s;
              border-radius: 34px;
            }}
            .slider:before {{
              position: absolute;
              content: "";
              height: 14px;
              width: 14px;
              left: 3px;
              bottom: 3px;
              background-color: white;
              transition: .4s;
              border-radius: 50%;
            }}
            input:checked + .slider {{
              background-color: {p_c};
            }}
            input:checked + .slider:before {{
              transform: translateX(14px);
            }}
          </style>
        </head>
        <body>
          <div class="phone-body">
            <div class="notch"></div>
            <div class="status-bar">
              <span>10:11</span>
              <div>
                <span class="material-icons" style="font-size: 11px;">signal_cellular_4_bar</span>
                <span class="material-icons" style="font-size: 11px;">wifi</span>
                <span class="material-icons" style="font-size: 11px;">battery_full</span>
              </div>
            </div>
            
            <!-- SCREEN: HOME -->
            <div id="screen-home" class="screen active">
              <div class="header">
                <h2>{app_n}</h2>
                <span>Personal Privacy</span>
              </div>
              <div class="hero-card">
                <h3>{hero_t}</h3>
                <p>{hero_sub}</p>
              </div>
              <div class="module-card">
                <div class="module-icon"><span class="material-icons">{item1_i}</span></div>
                <div class="module-info">
                  <h4>{item1_t}</h4>
                  <p>{item1_d}</p>
                </div>
              </div>
              <div class="module-card">
                <div class="module-icon"><span class="material-icons">{item2_i}</span></div>
                <div class="module-info">
                  <h4>{item2_t}</h4>
                  <p>{item2_d}</p>
                </div>
              </div>
              <div class="module-card">
                <div class="module-icon"><span class="material-icons">{item3_i}</span></div>
                <div class="module-info">
                  <h4>{item3_t}</h4>
                  <p>{item3_d}</p>
                </div>
              </div>
            </div>
            
            <!-- SCREEN: VAULT -->
            <div id="screen-vault" class="screen">
              <div class="header">
                <h2>{item1_t}</h2>
                <span>Hardware Locked</span>
              </div>
              <div id="vault-lock-screen" style="display: flex; flex-direction: column; align-items: center; justify-content: center; flex: 1; text-align: center;">
                <span class="material-icons" style="font-size: 60px; color: {p_c}; margin-bottom: 10px;">lock</span>
                <h3 style="margin: 0; font-size: 15px;">Vault is Encrypted</h3>
                <p style="font-size: 11px; color: #6b7280; margin: 5px 0 15px 0;">Requires biometric signature verification to scan credentials.</p>
                <button class="lock-screen-btn" onclick="triggerBiometrics()">Verify Biometrics</button>
              </div>
              
              <div id="vault-unlocked" style="display: none; padding: 5px;">
                <div style="background: rgba(16, 185, 129, 0.05); border: 1px solid #10b981; border-radius: 12px; padding: 10px; color: #047857; font-size: 11px; display: flex; align-items: center; margin-bottom: 15px;">
                  <span class="material-icons" style="font-size: 14px; margin-right: 6px;">verified</span>
                  Access granted: Zero-knowledge hardware lock active.
                </div>
                <div style="background: white; border: 1px solid rgba(0,0,0,0.05); border-radius: 12px; padding: 10px; margin-bottom: 8px;">
                  <div style="font-size: 10px; color: #9ca3af;">Personal Lock Password</div>
                  <div style="font-size: 12px; font-weight: bold; color: #374151;">••••••••••••</div>
                </div>
                <div style="background: white; border: 1px solid rgba(0,0,0,0.05); border-radius: 12px; padding: 10px; margin-bottom: 8px;">
                  <div style="font-size: 10px; color: #9ca3af;">Recovery Backup Key</div>
                  <div style="font-size: 11px; font-weight: bold; color: #374151;">safespace_private_2026_aes</div>
                </div>
              </div>
            </div>
            
            <!-- SCREEN: SENTINEL -->
            <div id="screen-sentinel" class="screen">
              <div class="header">
                <h2>{item3_t}</h2>
                <span>Threat Logs</span>
              </div>
              <div style="display: flex; flex-direction: column; gap: 8px;">
                <div style="background: white; border-radius: 12px; padding: 10px; border: 1px solid rgba(0,0,0,0.05); display: flex; justify-content: space-between; align-items: center;">
                  <div>
                    <div style="font-size: 11px; font-weight: bold; color: #1f2937;">Biometric Signature Match</div>
                    <div style="font-size: 9px; color: #9ca3af;">Just now • Verified</div>
                  </div>
                  <span style="background: #e6f4ea; color: #137333; font-size: 9px; padding: 2px 6px; border-radius: 10px; font-weight: bold;">SECURE</span>
                </div>
                <div style="background: white; border-radius: 12px; padding: 10px; border: 1px solid rgba(0,0,0,0.05); display: flex; justify-content: space-between; align-items: center;">
                  <div>
                    <div style="font-size: 11px; font-weight: bold; color: #1f2937;">Intrusion Lock Attempt</div>
                    <div style="font-size: 9px; color: #9ca3af;">2 hours ago • Failed Fingerprint</div>
                  </div>
                  <span style="background: #fce8e6; color: #c5221f; font-size: 9px; padding: 2px 6px; border-radius: 10px; font-weight: bold;">BLOCKED</span>
                </div>
                <div style="background: white; border-radius: 12px; padding: 10px; border: 1px solid rgba(0,0,0,0.05); display: flex; justify-content: space-between; align-items: center;">
                  <div>
                    <div style="font-size: 11px; font-weight: bold; color: #1f2937;">Hardware Lockbox Synced</div>
                    <div style="font-size: 9px; color: #9ca3af;">Today 10:11 AM • Hardware API</div>
                  </div>
                  <span style="background: #e8f0fe; color: #1a73e8; font-size: 9px; padding: 2px 6px; border-radius: 10px; font-weight: bold;">SYNCED</span>
                </div>
              </div>
            </div>
            
            <!-- SCREEN: SETTINGS -->
            <div id="screen-settings" class="screen">
              <div class="header">
                <h2>Settings</h2>
                <span>App Config</span>
              </div>
              <div class="settings-row">
                <label>Enable Local Biometrics</label>
                <label class="switch">
                  <input type="checkbox" checked>
                  <span class="slider"></span>
                </label>
              </div>
              <div class="settings-row">
                <label>Hardware Zero-Leakage Guard</label>
                <label class="switch">
                  <input type="checkbox" checked>
                  <span class="slider"></span>
                </label>
              </div>
              <div class="settings-row">
                <label>Automatic Auto-Lock (5m)</label>
                <label class="switch">
                  <input type="checkbox" checked>
                  <span class="slider"></span>
                </label>
              </div>
              <div style="margin-top: 20px; text-align: center; font-size: 10px; color: #9ca3af;">
                Device Platform: {proto_target_platform}<br>
                Fidelity Level: {proto_fidelity}<br>
                Design Theme: {proto_design_system}
              </div>
            </div>
            
            <!-- BIOMETRIC OVERLAY -->
            <div id="bio-overlay" class="bio-overlay">
              <div id="bio-fingerprint" class="fingerprint-btn"><span class="material-icons" style="font-size: 44px;">fingerprint</span></div>
              <p id="bio-status" style="color: white; font-size: 12px; margin-top: 15px; font-weight: bold;">Place Finger on Scanner</p>
            </div>
            
            <!-- BOTTOM NAVIGATION -->
            <div class="nav-bar">
              <div class="nav-item active" onclick="switchScreen('screen-home', this)">
                <span class="material-icons" style="font-size: 20px;">home</span>
                <span>Home</span>
              </div>
              <div class="nav-item" onclick="switchScreen('screen-vault', this)">
                <span class="material-icons" style="font-size: 20px;">security</span>
                <span>Vault</span>
              </div>
              <div class="nav-item" onclick="switchScreen('screen-sentinel', this)">
                <span class="material-icons" style="font-size: 20px;">shield</span>
                <span>Guard</span>
              </div>
              <div class="nav-item" onclick="switchScreen('screen-settings', this)">
                <span class="material-icons" style="font-size: 20px;">settings</span>
                <span>Settings</span>
              </div>
            </div>
          </div>
          
          <script>
            function switchScreen(screenId, element) {{
              document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
              document.getElementById(screenId).classList.add('active');
              document.querySelectorAll('.nav-item').forEach(i => i.classList.remove('active'));
              element.classList.add('active');
            }}
            
            function triggerBiometrics() {{
              const overlay = document.getElementById('bio-overlay');
              overlay.style.display = 'flex';
              document.getElementById('bio-status').innerText = 'Place Finger on Scanner';
              document.getElementById('bio-fingerprint').style.color = '{p_c}';
              
              setTimeout(() => {{
                document.getElementById('bio-status').innerText = 'Scanning Biometrics...';
                setTimeout(() => {{
                  document.getElementById('bio-status').innerText = 'Access Granted!';
                  document.getElementById('bio-fingerprint').style.color = '#10b981';
                  setTimeout(() => {{
                    overlay.style.display = 'none';
                    document.getElementById('vault-unlocked').style.display = 'block';
                    document.getElementById('vault-lock-screen').style.display = 'none';
                  }}, 800);
                }}, 1200);
              }}, 600);
            }}
          </script>
        </body>
        </html>
        """
            components.html(device_simulator_html, height=660)

# Subprocess Logs Output
status_placeholder = st.empty()
log_placeholder = st.empty()

# Helper to run builds
def run_app_forge(spec_path=None, design_src=None, use_ai=False, target_path="", app_id=""):
    status_placeholder.markdown("""
    <div class='glass-card' style='border-color: #a855f7;'>
        <p style='color: #d8b4fe; font-weight: bold; margin:0;'>⚡ SYNTHESIS CORE STARTED: Restructuring design layout and package directories...</p>
    </div>
    """, unsafe_allow_html=True)
    
    log_area = log_placeholder.empty()
    logs_output = []
    
    cmd = [
        "python3", ENGINE_SCRIPT,
        "--out", target_path,
        "--template", TEMPLATE_DIR
    ]
    
    if design_src:
        cmd.extend(["--design-source", design_src])
        if use_ai:
            cmd.append("--use-ai")
    elif spec_path:
        cmd.extend(["--spec", spec_path])
        if use_ai:
            cmd.append("--use-ai")
        
    try:
        # Pass the fully loaded local environment (with GEMINI_API_KEY) directly to the subprocess
        env_copy = os.environ.copy()
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            env=env_copy
        )
        
        while True:
            line = process.stdout.readline()
            if not line and process.poll() is not None:
                break
            if line:
                logs_output.append(line.strip())
                log_area.code("\n".join(logs_output[-15:]), language="bash")
                
        rc = process.wait()
        
        # Cleanup temp spec
        if spec_path and os.path.exists(spec_path):
            os.remove(spec_path)
            
        if rc == 0:
            status_placeholder.markdown(f"""
            <div class='glass-card' style='border-color: #22c55e; background: rgba(34, 197, 94, 0.08);'>
                <h4 style='color: #4ade80; margin: 0;'>🎉 APP FORGED SUCCESSFULLY!</h4>
                <p style='color: #a7f3d0; margin: 5px 0 0 0;'>The tailored codebase has been structured at builds/{app_id}</p>
            </div>
            """, unsafe_allow_html=True)
            log_placeholder.code("\n".join(logs_output), language="bash")
            
            # Start Phase 2: flutter build web --release inside builds/{app_id}
            status_placeholder.markdown(f"""
            <div class='glass-card' style='border-color: #3b82f6;'>
                <p style='color: #93c5fd; font-weight: bold; margin:0;'>🌐 FLUTTER WEB COMPILATION ACTIVE: Generating high-performance static web assets...</p>
            </div>
            """, unsafe_allow_html=True)
            
            web_logs = ["Compiling Flutter Dart views to static WASM/JS binary...", "Running flutter build web --release inside target builds folder..."]
            log_placeholder.code("\n".join(web_logs), language="bash")
            
            try:
                web_proc = subprocess.Popen(
                    ["flutter", "build", "web", "--release"],
                    cwd=target_path,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    bufsize=1,
                    env=env_copy
                )
                
                while True:
                    line = web_proc.stdout.readline()
                    if not line and web_proc.poll() is not None:
                        break
                    if line:
                        web_logs.append(line.strip())
                        log_placeholder.code("\n".join(web_logs[-15:]), language="bash")
                        
                web_rc = web_proc.wait()
                if web_rc == 0:
                    success_symlink = update_web_preview_symlink(target_path)
                    if success_symlink:
                        status_placeholder.markdown(f"""
                        <div class='glass-card' style='border-color: #22c55e; background: rgba(34, 197, 94, 0.08);'>
                            <h4 style='color: #4ade80; margin: 0;'>🎉 APP FORGED & WEB SANDBOX LIVE!</h4>
                            <p style='color: #a7f3d0; margin: 5px 0 0 0;'>The codebase has been fully compiled. Simulator is now running the LIVE interactive app!</p>
                        </div>
                        """, unsafe_allow_html=True)
                        log_placeholder.code("\n".join(web_logs), language="bash")
                    else:
                        status_placeholder.warning("App forged, but active web preview symlink could not be established.")
                else:
                    status_placeholder.markdown(f"""
                    <div class='glass-card' style='border-color: #ef4444; background: rgba(239, 68, 68, 0.08);'>
                        <h4 style='color: #fca5a5; margin: 0;'>❌ FLUTTER WEB COMPILATION FAILED</h4>
                        <p style='color: #fecdd3; margin: 5px 0 0 0;'>Subprocess returned exit code {web_rc}. Review compilation logs below.</p>
                    </div>
                    """, unsafe_allow_html=True)
                    log_placeholder.code("\n".join(web_logs), language="bash")
            except Exception as ex:
                status_placeholder.error(f"Failed to compile web assets: {ex}")
        else:
            status_placeholder.markdown(f"""
            <div class='glass-card' style='border-color: #ef4444; background: rgba(239, 68, 68, 0.08);'>
                <h4 style='color: #fca5a5; margin: 0;'>❌ APP FORGING ENCOUNTERED AN ERROR</h4>
                <p style='color: #fecdd3; margin: 5px 0 0 0;'>Subprocess returned exit code {rc}. Review full trace below.</p>
            </div>
            """, unsafe_allow_html=True)
            log_placeholder.code("\n".join(logs_output), language="bash")
            
    except Exception as e:
        status_placeholder.error(f"Failed to launch subprocess swap engine: {e}")

# Helper to run verify
def run_app_verify(target_path=""):
    status_placeholder.markdown("""
    <div class='glass-card' style='border-color: #3b82f6;'>
        <p style='color: #93c5fd; font-weight: bold; margin:0;'>🔍 INTEGRITY ANALYSIS ACTIVE: Triggering static analyzer code scans...</p>
    </div>
    """, unsafe_allow_html=True)
    
    if not os.path.exists(target_path):
        status_placeholder.markdown("""
        <div class='glass-card' style='border-color: #eab308; background: rgba(234, 179, 8, 0.08);'>
            <p style='color: #fde047; font-weight: bold; margin:0;'>⚠️ NO BUILD FOUND: Please click [앱 생성 엔진 가동] before launching integrity test.</p>
        </div>
        """, unsafe_allow_html=True)
        return
        
    log_area = log_placeholder.empty()
    logs_output = ["Initializing 'flutter analyze' scans inside target build path...", "Analyzing dependencies and configs..."]
    log_area.code("\n".join(logs_output), language="bash")
    
    try:
        process = subprocess.Popen(
            ["flutter", "analyze"],
            cwd=target_path,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            env=os.environ.copy()
        )
        
        while True:
            line = process.stdout.readline()
            if not line and process.poll() is not None:
                break
            if line:
                logs_output.append(line.strip())
                log_area.code("\n".join(logs_output[-15:]), language="bash")
                
        rc = process.wait()
        
        if rc == 0:
            status_placeholder.markdown(f"""
            <div class='glass-card' style='border-color: #22c55e; background: rgba(34, 197, 94, 0.08);'>
                <h4 style='color: #4ade80; margin: 0;'>🛡️ STATIC INTEGRITY GUARANTEED: 100% SUCCESS</h4>
                <p style='color: #a7f3d0; margin: 5px 0 0 0;'>Flutter analyzer returned clean status code with 0 syntax errors or warnings.</p>
            </div>
            """, unsafe_allow_html=True)
            log_placeholder.code("\n".join(logs_output), language="bash")
        else:
            status_placeholder.markdown(f"""
            <div class='glass-card' style='border-color: #ef4444; background: rgba(239, 68, 68, 0.08);'>
                <h4 style='color: #fca5a5; margin: 0;'>⚠️ INTEGRITY FAILURE DETECTED</h4>
                <p style='color: #fecdd3; margin: 5px 0 0 0;'>Flutter analyzer found syntax issues. Review lint trace below.</p>
            </div>
            """, unsafe_allow_html=True)
            log_placeholder.code("\n".join(logs_output), language="bash")
            
    except Exception as e:
        status_placeholder.error(f"Failed to trigger 'flutter analyze' verification: {e}")

# Dispatch triggers
if start_build:
    try:
        parsed_spec = json.loads(json_spec_str)
    except Exception as e:
        status_placeholder.error(f"Invalid JSON specification input: {e}")
        st.stop()
        
    temp_spec_path = os.path.join(WORKSPACE_DIR, f"temp_spec_{clean_app_id}.json")
    with open(temp_spec_path, 'w', encoding='utf-8') as f:
        json.dump(parsed_spec, f, indent=2, ensure_ascii=False)
        
    run_app_forge(spec_path=temp_spec_path, target_path=target_build_path, app_id=clean_app_id)

if run_verify:
    run_app_verify(target_path=target_build_path)

if start_ai_build:
    import re
    # Extract English design system from the parenthesized format
    sys_match = re.search(r'\(([^)]+)\)', proto_design_system)
    eng_design_system = sys_match.group(1) if sys_match else "Cozy Warm Pastel"
    
    # Extract English platform
    plat_match = re.search(r'\(([^)]+)\)', proto_target_platform)
    eng_target_platform = plat_match.group(1) if plat_match else "Flutter Mobile"
    
    # Extract English fidelity
    fidel_match = re.search(r'\(([^)]+)\)', proto_fidelity)
    eng_fidelity = fidel_match.group(1) if fidel_match else "High fidelity"
    
    parsed_spec = {
        "app_name": proto_project_name,
        "package_name": proto_package_name,
        "design_system": eng_design_system,
        "target_platform": eng_target_platform,
        "landing_page": proto_landing_page,
        "os_widgets": proto_os_widgets,
        "fidelity": eng_fidelity,
        "prompt": proto_prompt
    }
    
    temp_spec_path = os.path.join(WORKSPACE_DIR, f"temp_spec_{clean_ai_id}.json")
    with open(temp_spec_path, 'w', encoding='utf-8') as f:
        json.dump(parsed_spec, f, indent=2, ensure_ascii=False)
        
    with st.spinner("🤖 AI 엔진이 고성능 Gemma 4 모델을 호출하여 브랜드 컬러 해석, 토큰 바인딩 및 앱 코드 합성을 진행 중입니다... (약 20~40초 소요)"):
        run_app_forge(
            spec_path=temp_spec_path,
            use_ai=True,
            target_path=target_ai_path,
            app_id=clean_ai_id
        )

if run_ai_verify:
    run_app_verify(target_path=target_ai_path)

# =========================================================================
#  📂 PREMIUM REAL-TIME TAILORED CODEBASE PREVIEW (4번 항목 개선)
# =========================================================================
st.markdown("<h3 style='color: #6366f1; margin-top: 30px;'>📂 Dynamic Tailored Codebase & Spec Viewer</h3>", unsafe_allow_html=True)
st.markdown("<p style='color: #6b7280; font-size: 0.85rem; margin-top: 0;'>Dynamically scans and renders all compiled tenant micro-app directories and configuration specifications.</p>", unsafe_allow_html=True)

# 1. Scan builds directories dynamically
builds_dirs = [
    "/Users/apple/development/soluni/Solve-for-X/architecture/builds",
    "/Users/apple/development/soluni/Solve-for-X/architecture/my-app-factory/builds"
]
detected_apps = []

for b_dir in builds_dirs:
    if os.path.exists(b_dir):
        for item in os.listdir(b_dir):
            full_path = os.path.join(b_dir, item)
            if os.path.isdir(full_path):
                config_path = os.path.join(full_path, "lib", "config", "app_config.dart")
                if os.path.exists(config_path):
                    detected_apps.append({
                        "id": item,
                        "path": full_path,
                        "config": config_path
                    })

if detected_apps:
    app_options = [app["id"] for app in detected_apps]
    selected_app_id = st.selectbox(
        "📂 Select Compiled Workspace to Inspect", 
        options=app_options, 
        index=0,
        help="Select a tenant workspace to view its generated config files and synthesis spec."
    )
    
    selected_app = next(app for app in detected_apps if app["id"] == selected_app_id)
    target_config_path = selected_app["config"]
    
    # Check for spec JSON inside build directory or in fallback directories
    target_spec_path = None
    local_spec_record = os.path.join(selected_app["path"], "app_spec.json")
    if os.path.exists(local_spec_record):
        target_spec_path = local_spec_record
    else:
        # Fallback to general listener folders
        for path in [
            "/Users/apple/development/soluni/Solve-for-X/architecture/my-app-factory/factory_engine/app_spec.json",
            "/Users/apple/development/soluni/Solve-for-X/architecture/factory_engine/app_spec.json"
        ]:
            if os.path.exists(path):
                target_spec_path = path
                break

    preview_col1, preview_col2 = st.columns(2)
    
    with preview_col1:
        st.markdown(f"<h4 style='color: #a78bfa;'>🌸 app_config.dart (Tailored Flutter Theme)</h4>", unsafe_allow_html=True)
        try:
            with open(target_config_path, "r", encoding="utf-8") as f:
                config_content = f.read()
            st.code(config_content, language="dart")
            st.caption(f"Previewing tailored file: `builds/{selected_app_id}/lib/config/app_config.dart`")
        except Exception as e:
            st.error(f"Failed to read tailored code: {e}")
            
    with preview_col2:
        st.markdown("<h4 style='color: #f472b6;'>📋 app_spec.json (AI Synthesized Specifications)</h4>", unsafe_allow_html=True)
        if target_spec_path:
            try:
                with open(target_spec_path, "r", encoding="utf-8") as f:
                    spec_content = json.load(f)
                st.json(spec_content)
                st.caption(f"Previewing synthesis spec source: `{os.path.basename(target_spec_path)}`")
            except Exception as e:
                st.error(f"Failed to load spec file: {e}")
        else:
            st.info("📋 No synthesis specifications found for this build. Run the AI forge to stream live specifications.")
else:
    st.info("🟢 No compiled tenant micro-apps detected in builds/ folder yet. Click [앱 생성 엔진 가동] or [AI 디자인 주조 가동] above to generate a workspace.")

# Real-time Auto-Refresh mechanism executed at the end of rendering
if auto_refresh:
    time.sleep(3)
    st.rerun()

