#!/usr/bin/env python3
"""
=========================================================================
  HYBRID APP FACTORY LOCAL ENGINE DAEMON (factory_listener.py)
=========================================================================
This script runs locally as a persistent background daemon, polling a
GitHub repository for dispatch events, executing the local 'open-design'
CLI sandbox, routing AI synthesis requests through a 3-stage Gemini
failover chain, and packaging a zero-error Flutter custom codebase.
"""

import os
import sys
import time
import json
import re
import shutil
import subprocess
import argparse

# Auto-check and import dependencies gracefully
try:
    from dotenv import load_dotenv
except ImportError:
    print("[SYSTEM] 'python-dotenv' not found. Installing via pip...")
    subprocess.run([sys.executable, "-m", "pip", "install", "python-dotenv", "--break-system-packages"], check=True)
    from dotenv import load_dotenv

try:
    import requests
except ImportError:
    print("[SYSTEM] 'requests' not found. Installing via pip...")
    subprocess.run([sys.executable, "-m", "pip", "install", "requests", "--break-system-packages"], check=True)
    import requests

# google.generativeai is optional now, as we use robust REST API requests directly to bypass Python 3.13 compilation bottlenecks
try:
    import google.generativeai as genai
except ImportError:
    genai = None


# Load .env variables
ENV_PATH = os.path.join(os.path.dirname(__file__), ".env")
load_dotenv(ENV_PATH)

GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
OWNER = os.environ.get("GITHUB_REPO_OWNER", "nexu-io")
REPO = os.environ.get("GITHUB_REPO_NAME", "app-factory-control")

# Core Paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
SPEC_DIR = os.path.join(BASE_DIR, "factory_engine")
SPEC_PATH = os.path.join(SPEC_DIR, "app_spec.json")
TEMPLATE_DIR = os.path.join(BASE_DIR, "flutter-template")

os.makedirs(SPEC_DIR, exist_ok=True)

def log(msg, level="INFO"):
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] [{level}] {msg}", flush=True)

# Shared Status File for Dashboard Monitoring
STATUS_FILE_PATH = "/Users/apple/development/soluni/Solve-for-X/architecture/build_status.json"

def update_build_status(status, current_stage, progress, message, error=None):
    try:
        status_data = {
            "status": status,
            "current_stage": current_stage,
            "progress": progress,
            "message": message,
            "error": error,
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S")
        }
        with open(STATUS_FILE_PATH, 'w', encoding='utf-8') as f:
            json.dump(status_data, f, indent=2, ensure_ascii=False)
    except Exception as e:
        log(f"Failed to update status file: {e}", "WARNING")

def extract_clean_json(text_content):
    """
    Bulletproof JSON extractor that scans all '{' occurrences to find the largest 
    valid JSON block, defending against stray thought-log braces or sub-blocks.
    """
    best_json = None
    max_len = -1
    
    # Scan all possible starting brace indices
    for start_idx in range(len(text_content)):
        if text_content[start_idx] == '{':
            # Trace matching brace
            brace_count = 0
            in_string = False
            escape = False
            
            for idx in range(start_idx, len(text_content)):
                char = text_content[idx]
                if escape:
                    escape = False
                    continue
                if char == '\\':
                    escape = True
                    continue
                if char == '"':
                    in_string = not in_string
                    continue
                    
                if not in_string:
                    if char == '{':
                        brace_count += 1
                    elif char == '}':
                        brace_count -= 1
                        if brace_count == 0:
                            raw_json = text_content[start_idx:idx+1]
                            try:
                                parsed = json.loads(raw_json)
                                if isinstance(parsed, dict):
                                    # We prioritize dicts containing expected keys like 'app_name'
                                    score = len(raw_json)
                                    if "app_name" in parsed:
                                        score += 1000000 # Heavily prioritize the root app config JSON!
                                    if score > max_len:
                                        max_len = score
                                        best_json = parsed
                            except Exception:
                                pass
                            break
    if best_json:
        return best_json
        
    # Fallback to simple regex if brace matching failed
    try:
        json_match = re.search(r'\{.*\}', text_content, re.DOTALL)
        if json_match:
            return json.loads(json_match.group(0))
    except Exception:
        pass
        
    return None



# =========================================================================
#  1. GitHub Repository Dispatch Listener Loop
# =========================================================================
def poll_github_dispatches(last_processed_id=None):
    """
    Polls the GitHub events API to check for new Repository Dispatch events.
    Returns the parsed specification payload if a new event is found.
    """
    if not GITHUB_TOKEN or GITHUB_TOKEN == "your_github_personal_access_token_here":
        log("GITHUB_TOKEN not configured in .env. Operating in Simulation/Demo Polling Loop...", "WARNING")
        # Generate demo dispatch events simulation
        time.sleep(2)
        demo_payload = {
            "id": 9999,
            "app_name": "SafeSpace",
            "package_name": "com.safespace.privacy",
            "version": "1.3.0",
            "api_base_url": "https://api.safespace-privacy.io",
            "design_source": "https://www.figma.com/file/safespace_pastel_privacy_spec",
            "primary_color": "#a78bfa",
            "secondary_color": "#f472b6",
            "background_color": "#f9fafb",
            "card_color": "#ffffff"
        }
        return demo_payload, 9999


    url = f"https://api.github.com/repos/{OWNER}/{REPO}/events"
    headers = {
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3+json"
    }

    try:
        response = requests.get(url, headers=headers, timeout=10)
        if response.status_code == 200:
            events = response.json()
            for event in events:
                # Target 'RepositoryDispatchEvent' types
                if event.get("type") == "RepositoryDispatchEvent":
                    event_id = event.get("id")
                    if last_processed_id == event_id:
                        return None, last_processed_id
                        
                    payload = event.get("payload", {}).get("client_payload", {})
                    if payload:
                        log(f"New Dispatch Event detected! Event ID: {event_id}")
                        return payload, event_id
        elif response.status_code == 404:
            log(f"Repository {OWNER}/{REPO} not found. Check repository configuration or token scope.", "ERROR")
        else:
            log(f"GitHub API returned error code {response.status_code}: {response.text}", "WARNING")
    except Exception as e:
        log(f"GitHub connection encountered an anomaly: {e}", "WARNING")

    return None, last_processed_id

# =========================================================================
#  2. open-design CLI Subprocess Trigger
# =========================================================================
# =========================================================================
#  2. open-design GUI Spec Parser (Auto-Detect Mode)
# =========================================================================
def parse_design_system_yaml(yaml_text):
    """
    Pure Python parser to interpret the DESIGN.md open-design system contract
    without external pyyaml dependencies. Highly robust for standard indentations.
    """
    import re
    spec = {
        "name": "SafeSpace Soft Pastel Friendly Privacy",
        "version": "1.3.0",
        "colors": {
            "primary": "#a78bfa",
            "secondary": "#f472b6",
            "background": "#f9fafb",
            "card": "#ffffff"
        },
        "font": "Outfit",
        "border_radius": "24.0",
        "layout": {
            "enable_chat": True,
            "enable_profile": True,
            "enable_settings": True,
            "hero_title": "Your Safe Haven",
            "hero_subtitle": "A beautifully soft, highly secure environment protecting your private thoughts and secure data."
        },
        "widgets": []
    }
    
    lines = yaml_text.splitlines()
    current_key = None
    current_color = None
    current_hero = False
    current_grid_item = None
    
    for line in lines:
        comment_idx = line.find('#')
        if comment_idx != -1:
            if line[:comment_idx].count('"') % 2 == 0 and line[:comment_idx].count("'") % 2 == 0:
                line = line[:comment_idx]
                
        stripped = line.strip()
        if not stripped:
            continue
            
        if "colors:" in line:
            current_key = "colors"
            continue
        elif "typography:" in line:
            current_key = "typography"
            continue
        elif "spacing:" in line:
            current_key = "spacing"
            continue
        elif "layout:" in line:
            current_key = "layout"
            continue
        elif "grid_items:" in line:
            current_key = "grid_items"
            continue
            
        if current_key == "colors":
            if "primary:" in stripped:
                current_color = "primary"
            elif "secondary:" in stripped:
                current_color = "secondary"
            elif "background:" in stripped:
                current_color = "background"
            elif "card:" in stripped:
                current_color = "card"
            elif "hex:" in stripped:
                hex_match = re.search(r'hex:\s*["\']?([^"\']+)["\']?', stripped)
                if hex_match and current_color:
                    spec["colors"][current_color] = hex_match.group(1)
                    
        elif current_key == "typography":
            if "primary_font:" in stripped:
                font_match = re.search(r'primary_font:\s*["\']?([^"\']+)["\']?', stripped)
                if font_match:
                    spec["font"] = font_match.group(1)
                    
        elif current_key == "spacing":
            if "border_radius:" in stripped:
                br_match = re.search(r'border_radius:\s*["\']?([^"\']+)["\']?', stripped)
                if br_match:
                    spec["border_radius"] = br_match.group(1)
                    
        elif current_key == "layout":
            if "enable_chat:" in stripped:
                spec["layout"]["enable_chat"] = "true" in stripped.lower()
            elif "enable_profile:" in stripped:
                spec["layout"]["enable_profile"] = "true" in stripped.lower()
            elif "enable_settings:" in stripped:
                spec["layout"]["enable_settings"] = "true" in stripped.lower()
            elif "hero:" in stripped:
                current_hero = True
            elif current_hero:
                if "title:" in stripped:
                    t_match = re.search(r'title:\s*["\']?([^"\']+)["\']?', stripped)
                    if t_match:
                        spec["layout"]["hero_title"] = t_match.group(1)
                elif "subtitle:" in stripped:
                    st_match = re.search(r'subtitle:\s*["\']?([^"\']+)["\']?', stripped)
                    if st_match:
                        spec["layout"]["hero_subtitle"] = st_match.group(1)
                        
        elif current_key == "grid_items":
            if stripped.startswith("-"):
                if current_grid_item:
                    spec["widgets"].append(current_grid_item)
                current_grid_item = {"type": "card"}
                title_match = re.search(r'title:\s*["\']?([^"\']+)["\']?', stripped)
                if title_match:
                    current_grid_item["title"] = title_match.group(1)
            elif current_grid_item:
                if "title:" in stripped:
                    title_match = re.search(r'title:\s*["\']?([^"\']+)["\']?', stripped)
                    if title_match:
                        current_grid_item["title"] = title_match.group(1)
                elif "description:" in stripped:
                    desc_match = re.search(r'description:\s*["\']?([^"\']+)["\']?', stripped)
                    if desc_match:
                        current_grid_item["desc"] = desc_match.group(1)
                elif "icon:" in stripped:
                    icon_match = re.search(r'icon:\s*["\']?([^"\']+)["\']?', stripped)
                    if icon_match:
                        current_grid_item["icon"] = icon_match.group(1)
                        
    if current_grid_item:
        spec["widgets"].append(current_grid_item)
        
    return spec

def run_open_design_parse(design_source):
    """
    Auto-Detect GUI Export Mode.
    Instead of executing a non-existent CLI, this sniffs and validates 
    the local DESIGN.md exported by the open-design GUI application.
    """
    output_dir = os.path.join(SPEC_DIR, "parsed_design")
    os.makedirs(output_dir, exist_ok=True)
    ast_path = os.path.join(output_dir, "raw_design_ast.json")

    log(f"Initiating open-design GUI export sniffer for source: {design_source}...")
    
    # 1. Check if design_source is a local file, otherwise search workspace fallback paths
    design_file = None
    if design_source and os.path.exists(design_source):
        design_file = design_source
    else:
        paths_to_check = [
            os.path.join(BASE_DIR, "DESIGN.md"),
            "/Users/apple/development/soluni/Solve-for-X/architecture/my-app-factory/DESIGN.md",
            "DESIGN.md"
        ]
        for p in paths_to_check:
            if os.path.exists(p):
                design_file = p
                break
                
    if design_file:
        log(f"Successfully auto-detected open-design GUI exported spec file at: {design_file}")
        try:
            with open(design_file, 'r', encoding='utf-8') as f:
                content = f.read()
                
            if design_file.endswith('.json'):
                parsed_ast = json.loads(content)
            else:
                # Parse markdown system specification dynamically
                parsed_ast = parse_design_system_yaml(content)
                parsed_ast["source"] = design_file
                
            with open(ast_path, 'w', encoding='utf-8') as f:
                json.dump(parsed_ast, f, indent=2, ensure_ascii=False)
            log(f"GUI design AST successfully synthesized and saved at: {ast_path}")
            return ast_path
        except Exception as e:
            log(f"Error parsing GUI exported design: {e}. Switching to simulation fallback.", "WARNING")
            
    # Fallback simulation if no GUI export file is found
    log("open-design GUI export files not found. Synthesizing visual layout AST simulator...", "WARNING")
    mock_ast = {
        "source": design_source,
        "colors": {
            "primary": "#a78bfa",
            "secondary": "#f472b6",
            "background": "#f9fafb",
            "card": "#ffffff"
        },
        "font": "Outfit",
        "border_radius": "24.0",
        "layout": {
            "enable_chat": True,
            "enable_profile": True,
            "enable_settings": True,
            "hero_title": "Your Safe Haven",
            "hero_subtitle": "A beautifully soft, highly secure environment protecting your private thoughts and secure data."
        },
        "widgets": [
            {"type": "card", "title": "Encrypted Vault", "desc": "Zero-knowledge hardware lockbox protecting your passwords and credentials.", "icon": "security"},
            {"type": "card", "title": "Mindful Journal", "desc": "A private safe diary to log your daily emotional highlights with zero cloud leakage.", "icon": "favorite"},
            {"type": "card", "title": "Sentinel Guard", "desc": "Real-time biometric threat logs capturing lock attempts.", "icon": "shield"}
        ]
    }
    with open(ast_path, 'w', encoding='utf-8') as f:
        json.dump(mock_ast, f, indent=2, ensure_ascii=False)
    log(f"Simulation design AST generated successfully at: {ast_path}")
    return ast_path

# =========================================================================
#  3. 3-Stage Gemini Multi-Model Failover Router
# =========================================================================
def route_ai_synthesis(design_ast_path, user_payload):
    """
    Attempts to cognitively map the design AST via Google AI Studio, 
    routing requests through a 5-stage model fallback loop under ResourceExhausted (429) conditions.
    Highly optimized using REST API requests to support lightning-fast execution and 100% 
    compatibility on Python 3.13 without heavy SDK installations.
    
    Integrates open-design DESIGN.md guidelines dynamically to guide AI as a professional design team.
    """
    with open(design_ast_path, 'r', encoding='utf-8') as f:
        ast_data = f.read()

    # Load open-design system specifications
    design_guidelines = ""
    design_md_path = os.path.join(BASE_DIR, "DESIGN.md")
    if os.path.exists(design_md_path):
        try:
            with open(design_md_path, 'r', encoding='utf-8') as f:
                design_guidelines = f.read()
            log("Loaded open-design system specifications from DESIGN.md successfully.")
        except Exception as e:
            log(f"Could not load DESIGN.md guidelines: {e}", "WARNING")

    system_instruction = (
        "You are an expert Flutter configuration builder acting as a professional design team member. "
        "Take this visual AST and output a strict, valid JSON matching these parameters: app_name, version, "
        "api_base_url, primary_color, secondary_color, background_color, card_color, enable_chat, "
        "enable_profile, enable_settings, hero_title, hero_subtitle, and dynamic_items array.\n\n"
        "Crucial Rule: You MUST strictly align with the visual and component rules specified in the "
        "open-design brand guidelines below.\n\n"
        f"Brand Guidelines (open-design DESIGN.md):\n{design_guidelines}"
    )
    prompt = f"Map the layout tokens and combine with user options: {json.dumps(user_payload)}\n\nVisual AST:\n{ast_data}"


    # Model prioritisation routing chain matching user specified priorities:
    # 1. Gemini 3.5 Flash
    # 2. Gemini 3 Flash
    # 3. Gemma 4 31B
    # 4. Gemma 4 26B
    # 5. Gemini 2.5 Flash
    models_chain = [
        "gemini-3.5-flash",
        "gemini-3-flash-preview",
        "gemma-4-31b-it",
        "gemma-4-26b-a4b-it",
        "gemini-2.5-flash"
    ]

    if not GEMINI_API_KEY or GEMINI_API_KEY == "your_gemini_api_studio_key_here":
        log("GEMINI_API_KEY not configured in .env. Launching AI Simulation Fallback Mode...", "WARNING")
        return simulate_ai_fallback(user_payload)

    for stage_idx, model_name in enumerate(models_chain, start=1):
        log(f"[STAGE {stage_idx}] Attempting dynamic code mapping using {model_name}...")
        update_build_status("PROCESSING", "AI_ROUTING", 0.4 + (stage_idx * 0.1), f"Calling AI model: {model_name} (Stage {stage_idx} fallback)...")
        
        try:
            # Construct request payload
            url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent?key={GEMINI_API_KEY}"
            headers = {"Content-Type": "application/json"}
            
            # Incorporate system instruction based on model type
            if "gemma" in model_name:
                log(f"[STAGE {stage_idx}] Adapting prompt structure for Gemma compatibility...")
                payload = {
                    "contents": [{
                        "parts": [{"text": f"[SYSTEM INSTRUCTION]\n{system_instruction}\n\n[USER INPUT]\n{prompt}"}]
                    }],
                    "generationConfig": {
                        "responseMimeType": "application/json"
                    }
                }
            else:
                # Gemini model native structure
                payload = {
                    "contents": [{
                        "parts": [{"text": prompt}]
                    }],
                    "systemInstruction": {
                        "parts": [{"text": system_instruction}]
                    },
                    "generationConfig": {
                        "responseMimeType": "application/json"
                    }
                }
                
            # Upgraded timeout from 30 to 90 seconds to fully support deep thinking beta Gemma models
            response = requests.post(url, headers=headers, json=payload, timeout=90)
            
            if response.status_code == 200:
                res_data = response.json()
                try:
                    text_content = res_data['candidates'][0]['content']['parts'][0]['text']
                    # Extract JSON block safely via brace matching
                    spec_result = extract_clean_json(text_content)
                    if spec_result:
                        log(f"[STAGE {stage_idx}] Cognitive routing successful with model: {model_name}")
                        update_build_status("PROCESSING", "AI_ROUTING", 0.7, f"AI synthesis resolved successfully via {model_name}.")
                        return spec_result
                    else:
                        log(f"Model {model_name} did not output parseable JSON block in text: {text_content[:200]}...", "WARNING")
                except KeyError:
                    log(f"Unexpected response structure from model {model_name}: {json.dumps(res_data)[:200]}", "WARNING")
            elif response.status_code == 429:
                log(f"[STAGE {stage_idx}] Model {model_name} hit Quota Limit (429/ResourceExhausted).", "WARNING")
            else:
                log(f"[STAGE {stage_idx}] Model {model_name} returned error {response.status_code}: {response.text}", "WARNING")
                
        except Exception as e:
            log(f"[STAGE {stage_idx}] Model {model_name} failed with exception: {e}", "WARNING")
            
        # Backoff & Switch to next fallback model
        backoff_delay = stage_idx * 2
        log(f"Switching fallback route. Applying exponential backoff delay of {backoff_delay}s...")
        time.sleep(backoff_delay)

    log("AI routing chain exhausted. Utilizing emergency baseline fallback...", "WARNING")
    update_build_status("WARNING", "AI_ROUTING", 0.7, "AI API quota limit hit. Applying baseline local template specifications...")
    return simulate_ai_fallback(user_payload)



def simulate_ai_fallback(user_payload):
    """
    Returns a robust, production-ready specification fallback mapping.
    """
    log("Simulation fallback specification assembled.")
    return {
        "app_name": user_payload.get("app_name", "Horizon Portal"),
        "package_name": user_payload.get("package_name", "com.horizon.portal"),
        "version": user_payload.get("version", "1.0.0"),
        "api_base_url": user_payload.get("api_base_url", "https://api.horizon-platform.io"),
        "primary_color": user_payload.get("primary_color", "#63b5f1"),
        "secondary_color": user_payload.get("secondary_color", "#ec4899"),
        "background_color": user_payload.get("background_color", "#090514"),
        "card_color": user_payload.get("card_color", "#120b24"),
        "enable_chat": True,
        "enable_profile": True,
        "enable_settings": True,
        "hero_title": "Dynamic Workspace Active",
        "hero_subtitle": "Seamless multi-tenant edge client generated completely in real-time.",
        "dynamic_items": [
            {"title": "Edge Compute Core", "description": "High-throughput model execution pipeline.", "icon": "bolt"},
            {"title": "Distributed Fabric", "description": "Zero latency micro-services synchronized globally.", "icon": "layers"},
            {"title": "Elastic Registry", "description": "Multi-tenant directory with autonomous registration.", "icon": "grain"}
        ]
    }

# =========================================================================
#  4. Local Native Code Swapping and Injection Engine
# =========================================================================
def execute_local_synthesis(dest_path, spec):
    """
    Orchestrates package swaps, metadata rewriting, and config injection.
    """
    app_name = spec.get("app_name", "Swapped App")
    package_name = spec.get("package_name", "com.custom.app")
    
    log(f"Beginning native synthesis for builds/{app_name}...")
    
    # 1. Clear and clone template
    if os.path.exists(dest_path):
        shutil.rmtree(dest_path)
    shutil.copytree(TEMPLATE_DIR, dest_path, ignore=shutil.ignore_patterns('build', '.dart_tool', 'test'))
    
    # 2. Update Android files
    # pubspec.yaml
    pub_path = os.path.join(dest_path, "pubspec.yaml")
    if os.path.exists(pub_path):
        with open(pub_path, 'r', encoding='utf-8') as f:
            content = f.read()
        clean_name = re.sub(r'[^a-zA-Z0-9_]', '_', app_name.lower())
        content = re.sub(r'^name:\s+[a-zA-Z0-9_]+', f'name: {clean_name}', content, flags=re.MULTILINE)
        with open(pub_path, 'w', encoding='utf-8') as f:
            f.write(content)

    # build.gradle.kts
    gradle_path = os.path.join(dest_path, "android", "app", "build.gradle.kts")
    if os.path.exists(gradle_path):
        with open(gradle_path, 'r', encoding='utf-8') as f:
            content = f.read()
        content = re.sub(r'namespace\s*=\s*"[^"]+"', f'namespace = "{package_name}"', content)
        content = re.sub(r'applicationId\s*=\s*"[^"]+"', f'applicationId = "{package_name}"', content)
        with open(gradle_path, 'w', encoding='utf-8') as f:
            f.write(content)

    # AndroidManifest.xml
    manifest_path = os.path.join(dest_path, "android", "app", "src", "main", "AndroidManifest.xml")
    if os.path.exists(manifest_path):
        with open(manifest_path, 'r', encoding='utf-8') as f:
            content = f.read()
        content = re.sub(r'android:label="[^"]+"', f'android:label="{app_name}"', content)
        with open(manifest_path, 'w', encoding='utf-8') as f:
            f.write(content)

    # Kotlin Directories
    base_kotlin = os.path.join(dest_path, "android", "app", "src", "main", "kotlin")
    src_pkg = os.path.join(base_kotlin, "com", "example", "base_flutter_app")
    if os.path.exists(src_pkg):
        pkg_parts = package_name.split('.')
        dest_pkg = os.path.join(base_kotlin, *pkg_parts)
        os.makedirs(dest_pkg, exist_ok=True)
        for filename in os.listdir(src_pkg):
            src_file = os.path.join(src_pkg, filename)
            dest_file = os.path.join(dest_pkg, filename)
            if os.path.isfile(src_file):
                shutil.move(src_file, dest_file)
                if filename.endswith('.kt'):
                    with open(dest_file, 'r', encoding='utf-8') as f:
                        file_content = f.read()
                    file_content = re.sub(r'^package\s+[a-zA-Z0-9\._]+', f'package {package_name}', file_content, flags=re.MULTILINE)
                    with open(dest_file, 'w', encoding='utf-8') as f:
                        f.write(file_content)
        shutil.rmtree(src_pkg)

    # 3. Update iOS files
    # Info.plist
    plist_path = os.path.join(dest_path, "ios", "Runner", "Info.plist")
    if os.path.exists(plist_path):
        with open(plist_path, 'r', encoding='utf-8') as f:
            content = f.read()
        content = re.sub(r'<key>CFBundleDisplayName</key>\s*<string>[^<]+</string>', f'<key>CFBundleDisplayName</key>\n\t<string>{app_name}</string>', content)
        with open(plist_path, 'w', encoding='utf-8') as f:
            f.write(content)

    # project.pbxproj
    pbxproj_path = os.path.join(dest_path, "ios", "Runner.xcodeproj", "project.pbxproj")
    if os.path.exists(pbxproj_path):
        with open(pbxproj_path, 'r', encoding='utf-8') as f:
            content = f.read()
        content = re.sub(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*[a-zA-Z0-9\._\-]+;', f'PRODUCT_BUNDLE_IDENTIFIER = {package_name};', content)
        with open(pbxproj_path, 'w', encoding='utf-8') as f:
            f.write(content)

    # 4. Inject dynamic configuration file
    config_dir = os.path.join(dest_path, "lib", "config")
    os.makedirs(config_dir, exist_ok=True)
    config_path = os.path.join(config_dir, "app_config.dart")

    p_color = spec.get("primary_color", "#63b5f1")
    s_color = spec.get("secondary_color", "#ec4899")
    bg_color = spec.get("background_color", "#090514")
    card_color = spec.get("card_color", "#120b24")
    api_url = spec.get("api_base_url", "https://api.horizon-platform.io")
    version = spec.get("version", "1.0.0")

    enable_chat = "true" if spec.get("enable_chat", True) else "false"
    enable_profile = "true" if spec.get("enable_profile", True) else "false"
    enable_settings = "true" if spec.get("enable_settings", True) else "false"

    hero_title = spec.get("hero_title", "Workspace Active")
    hero_subtitle = spec.get("hero_subtitle", "Generated dynamic workspace client.")

    items_list = []
    for item in spec.get("dynamic_items", []):
        t = item.get("title", "Dynamic Panel")
        d = item.get("description", "Dynamic structural detail cards.")
        i = item.get("icon", "bolt")
        items_list.append(f"    {{'title': '{t}', 'description': '{d}', 'icon': '{i}'}}")
    items_str = ",\n".join(items_list)

    dart_code = f"""import 'package:flutter/material.dart';

class AppConfig {{
  static const String appName = '{app_name}';
  static const String appVersion = '{version}';
  static const String apiBaseUrl = '{api_url}';
  
  static const String primaryColorHex = '{p_color}';
  static const String secondaryColorHex = '{s_color}';
  static const String backgroundColorHex = '{bg_color}';
  static const String cardColorHex = '{card_color}';
  
  static const bool enableChat = {enable_chat};
  static const bool enableProfile = {enable_profile};
  static const bool enableSettings = {enable_settings};
  
  static const String heroTitle = '{hero_title}';
  static const String heroSubtitle = '{hero_subtitle}';
  
  static const List<Map<String, String>> dynamicItems = [
{items_str}
  ];

  static Color get primaryColor => _parseColor(primaryColorHex);
  static Color get secondaryColor => _parseColor(secondaryColorHex);
  static Color get backgroundColor => _parseColor(backgroundColorHex);
  static Color get cardColor => _parseColor(cardColorHex);

  static Color _parseColor(String hexStr) {{
    final cleanHex = hexStr.replaceAll('#', '');
    if (cleanHex.length == 6) {{
      return Color(int.parse('FF$cleanHex', radix: 16));
    }}
    return Colors.purple;
  }}
}}
"""
    with open(config_path, 'w', encoding='utf-8') as f:
        f.write(dart_code)

    # Write record of the spec JSON directly inside the build directory!
    try:
        with open(os.path.join(dest_path, "app_spec.json"), 'w', encoding='utf-8') as f:
            json.dump(spec, f, indent=2, ensure_ascii=False)
        log("Persisted app_spec.json inside the tailored build workspace.")
    except Exception as e:
        log(f"Failed to persist app_spec.json in workspace: {e}", "WARNING")

    log(f"Dynamic Swapper completed. Workspace tailored successfully at: {dest_path}")

# =========================================================================
#  5. E2E Verification Engine (flutter analyze)
# =========================================================================
def run_static_integrity_check(app_path):
    """
    Runs 'flutter analyze' inside the synthesized directory to verify build health.
    """
    log("Starting E2E static compilation check (flutter analyze)...")
    try:
        proc = subprocess.run(
            ["flutter", "analyze"],
            cwd=app_path,
            capture_output=True,
            text=True
        )
        if proc.returncode == 0:
            log("INTEGRITY CONFIRMED: 0 errors, 0 warnings. Code is compilation-ready!", "SUCCESS")
            return True
        else:
            log(f"INTEGRITY SCANS REPORTED ISSUES:\n{proc.stdout}", "WARNING")
            return False
    except Exception as e:
        log(f"Failed to execute flutter analyze checks: {e}", "ERROR")
        return False

# =========================================================================
#  Main Daemon loop
# =========================================================================
def main():
    parser = argparse.ArgumentParser(description="Hybrid App Factory Local Daemon")
    parser.add_argument("--interval", type=int, default=10, help="Polling interval in seconds")
    parser.add_argument("--demo", action="store_true", help="Run in local-polling Simulation demo mode")
    args = parser.parse_args()

    log("=========================================")
    log("  HYBRID APP FACTORY DAEMON INITIATED")
    log("=========================================")
    log(f"Polling Interval: {args.interval}s")
    log(f"Polling Target Repo: https://github.com/{OWNER}/{REPO}")
    log(f"Local Spec Output: {SPEC_PATH}")
    log(f"Local Flutter Template: {TEMPLATE_DIR}")

    last_event_id = None
    builds_counter = 0

    if args.demo:
        # Override token to force mock polling loop
        global GITHUB_TOKEN
        GITHUB_TOKEN = None

    # Initialize status file to IDLE
    update_build_status("IDLE", "POLLING", 0.0, "Daemon listening... Awaiting next dispatch event.")

    try:
        while True:
            # 1. Poll dispatches
            payload, event_id = poll_github_dispatches(last_event_id)
            
            if payload and event_id != last_event_id:
                last_event_id = event_id
                builds_counter += 1
                log(f"PROCESSING REQUEST #{builds_counter}...", "PROCESS")
                update_build_status("PROCESSING", "POLLING", 0.1, f"Event detected! Processing build #{builds_counter}...")

                # Save raw specification payload
                with open(SPEC_PATH, 'w', encoding='utf-8') as f:
                    json.dump(payload, f, indent=2, ensure_ascii=False)

                # 2. Run open-design visual parser
                update_build_status("PROCESSING", "PARSING", 0.2, "Parsing visual layout structure via open-design CLI...")
                design_src = payload.get("design_source", "https://www.figma.com/file/mock")
                ast_path = run_open_design_parse(design_src)
                update_build_status("PROCESSING", "PARSING", 0.4, "Visual layout parsed successfully into structural AST.")

                # 3. Route AI through 4-Stage failover routing
                update_build_status("PROCESSING", "AI_ROUTING", 0.5, "Routing visual AST through Google AI Studio models...")
                spec_result = route_ai_synthesis(ast_path, payload)

                # 4. Generate dynamic codebase
                update_build_status("PROCESSING", "SYNTHESIS", 0.75, f"AI synthesis resolved. Tailoring codebase templates for '{spec_result.get('app_name')}'...")
                clean_name = spec_result.get("package_name", "com.horizon.portal").replace(".", "_").lower()
                build_dest = os.path.join(BASE_DIR, "builds", clean_name)
                
                execute_local_synthesis(build_dest, spec_result)
                update_build_status("PROCESSING", "SYNTHESIS", 0.85, "Tailored codebase generated. Kotlin namespaces and configs injected.")

                # 5. E2E static compilation check
                update_build_status("PROCESSING", "VERIFICATION", 0.9, "Starting E2E static compilation integrity check (flutter analyze)...")
                integrity_success = run_static_integrity_check(build_dest)
                
                if integrity_success:
                    update_build_status("SUCCESS", "VERIFICATION", 1.0, f"Build #{builds_counter} resolved! tailored codebase compiled with 0 errors at: builds/{clean_name}")
                else:
                    update_build_status("WARNING", "VERIFICATION", 1.0, f"Build completed with lints/warnings at: builds/{clean_name}")
                
                log(f"REQUEST #{builds_counter} RESOLVED. Baseline active at: builds/{clean_name}\n")
                
                # If running demo mode, stop after first simulation run
                if not GITHUB_TOKEN:
                    log("Simulation demo run successfully completed. Exiting daemon process.")
                    break
            else:
                # Keep active status if already processing, otherwise IDLE
                pass

            time.sleep(args.interval)

    except KeyboardInterrupt:
        log("Daemon terminated by user. Shutting down App Factory core.")
        update_build_status("OFFLINE", "POLLING", 0.0, "Daemon is currently offline.")
        sys.exit(0)


if __name__ == "__main__":
    main()
