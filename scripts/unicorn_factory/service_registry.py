import json
from pathlib import Path

class ServiceRegistry:
    """
    Service Registry that dynamically scans for sfx_app.json configurations 
    within the apps/ folder, registers them, and exposes metadata to SRE tasks.
    """
    def __init__(self, repo_root: Path):
        self.repo_root = Path(repo_root).resolve()
        self.apps = {}
        self.scan_apps()

    def scan_apps(self):
        apps_dir = self.repo_root / "apps"
        if not apps_dir.exists():
            return
        
        for config_path in apps_dir.rglob("sfx_app.json"):
            try:
                with open(config_path, "r", encoding="utf-8") as f:
                    app_config = json.load(f)
                    app_id = app_config.get("id")
                    if app_id:
                        app_config["config_file_path"] = str(config_path)
                        workspace_rel = app_config.get("workspace_path", f"apps/{app_id}")
                        app_config["resolved_workspace_path"] = str(self.repo_root / workspace_rel)
                        self.apps[app_id] = app_config
            except Exception as e:
                print(f"[REGISTRY WARN]: Failed to parse config at {config_path}: {e}")

    def get_app(self, app_id: str):
        """Find an app config by exact ID or fuzzy-matching key/prompt triggers."""
        if not app_id:
            return self._default_fallback()

        if app_id in self.apps:
            return self.apps[app_id]
        
        app_id_lower = app_id.lower()
        for key, config in self.apps.items():
            if app_id_lower in key.lower() or key.lower() in app_id_lower:
                return config
            
            # Key thematic mappings
            if "memento" in app_id_lower or "mori" in app_id_lower or "메멘토" in app_id_lower:
                if "memento" in key.lower():
                    return config
            if "imjong" in app_id_lower or "임종" in app_id_lower:
                if "imjong" in key.lower():
                    return config
            if "vault" in app_id_lower or "legacy" in app_id_lower:
                if "vault" in key.lower():
                    return config

        return self._default_fallback()

    def _default_fallback(self):
        if self.apps:
            if "sfx_memento_mori" in self.apps:
                return self.apps["sfx_memento_mori"]
            return list(self.apps.values())[0]
        return None

    def get_all_apps(self):
        return self.apps
