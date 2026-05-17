import os
import json
from pathlib import Path
import shutil
import yaml

class FactoryInjectionError(Exception):
    """Base class for all errors during the module injection process."""
    def __init__(self, message, error_type="UNKNOWN_ERROR", details=None):
        super().__init__(message)
        self.error_type = error_type
        self.details = details or {}

class DependencyManager:
    """Handles parsing and updating pubspec.yaml dependencies with version conflict resolution."""
    def __init__(self, pubspec_path: Path):
        self.pubspec_path = pubspec_path
        self.change_log = []

    def load_pubspec(self) -> dict:
        with open(self.pubspec_path, "r") as f:
            return yaml.safe_load(f) or {}

    def save_pubspec(self, data: dict):
        with open(self.pubspec_path, "w") as f:
            yaml.dump(data, f, sort_keys=False)

    def update_dependencies(self, new_deps: list):
        """Updates dependencies and resolves version conflicts (takes higher version)."""
        data = self.load_pubspec()
        if "dependencies" not in data:
            data["dependencies"] = {}
        
        current_deps = data["dependencies"]
        conflicts = []

        for dep_str in new_deps:
            if ":" in dep_str:
                name, version = [s.strip() for s in dep_str.split(":", 1)]
                new_version = version.lstrip("^").lstrip("~")
            else:
                name = dep_str.strip()
                new_version = "any"

            if name in current_deps:
                existing_version = str(current_deps[name]).lstrip("^").lstrip("~")
                if existing_version != "any" and new_version != "api" and new_version != "any" and new_version != existing_version:
                    if new_version > existing_version:
                        print(f"  [UPGRADE] {name}: {existing_version} -> {new_version}")
                        current_deps[name] = f"^{new_version}"
                        self.change_log.append({"package": name, "action": "UPGRADED", "from": existing_version, "to": new_version})
                    else:
                        print(f"  [KEEP] {name}: {existing_version} (Existing is newer or equal)")
                        conflicts.append({"package": name, "issue": "VERSION_CONFLICT", "resolved": "KEPT_EXISTING"})
                elif new_version == "any":
                    current_deps[name] = "any"
            else:
                if ":" in dep_str:
                    current_deps[name] = f"^{new_version}" if new_version != "any" else "any"
                else:
                    current_deps[name] = "api" # Placeholder for logic
                    current_deps[name] = "any"
                print(f"  [ADD] {name}: {current_deps[name]}")
                self.change_log.append({"package": name, "action": "ADDED", "from": None, "to": current_deps[name]})

        self.save_pubspec(data)
        return conflicts

    def get_change_log(self):
        return self.change_log

class ConflictResolver:
    """Handles file system conflicts by creating backups instead of destructive overwrites."""
    def __init__(self, target_dir: Path):
        self.target_dir = target_dir
        self.backup_dir = target_dir / ".factory_backups"

    def resolve_file_conflict(self, dest_path: Path, source_file: Path) -> str:
        """Resolates conflict by backing up the existing file."""
        if not dest_path.exists():
            return "CREATED"

        if not self.backup_dir.exists():
            self.backup_dir.mkdir(parents=True, exist_ok=True)

        timestamp = os.getpid() 
        backup_path = self.backup_dir / f"{dest_path.name}.{timestamp}.bak"
        shutil.copy2(dest_path, backup_path)
        
        print(f"  [BACKUP] Existing file moved to {backup_path.name}")
        return f"BACKED_UP_TO_{backup_path.name}"

class ModuleInjector:
    """The main orchestrator for injecting modules into a Flutter project."""
    def __init__(self, target_project_path: str):
        self.target_path = Path(target_project_path).expanduser().resolve()
        if not (self.target_path / "pubspec.yaml").exists():
            raise FactoryInjectionError(f"Target '{self.target_path}' is not a valid Flutter project.", "MISSING_PROJECT")

        self.dep_manager = DependencyManager(self.target_path / "pubspec.yaml")
        self.conflict_resolver = ConflictResolver(self.target_path)
        self.file_changes = []

    def inject_module(self, module_source_path: str):
        source_path = Path(module_source_path).expanduser().resolve()
        if not (source_path / ".factory_template_metadata.json").exists():
            raise FactoryInjectionError(f"Source '{source_path}' is invalid.", "INVALID_MODULE")

        with open(source_path / ".factory_template_metadata.json", "r") as f:
            metadata = json.load(f)
        
        module_name = metadata["module_name"]
        print(f"🚀 [FACTORY-03] Injecting module '{module_name}' into {self.target_path}")

        # 1. Update Dependencies
        new_deps = metadata.get("dependencies", [])
        dep_conflicts = self.dep_manager.update_dependencies(new_deps)
        if dep_conflicts:
            print(f"⚠️  Dependency conflicts encountered: {dep_conflicts}")

        # 2. Copy Source Files (with Backup/Conflict Resolution)
        src_dir = source_path / "src"
        target_lib_dir = self.target_path / "lib"
        
        if src_dir.exists():
            for item in os.listdir(src_dir):
                s = src_dir / item
                d = target_lib_dir / item
                
                if s.is_dir():
                    if d.exists():
                        status = self.conflict_resolver.resolve_file_conflict(d, s)
                        self.file_changes.append({"path": str(d), "format": "directory", "action": "BACKED_UP", "detail": status})
                        shutil.rmtree(d)
                    shutil.copytree(s, d)
                    self.file_changes.append({"path": str(d), "format": "directory", "action": "CREATED", "detail": "directory"})
                else:
                    status = self.conflict_resolver.resolve_file_conflict(d, s)
                    shutil.copy2(s, d)
                    action = "BACKED_UP" if "BACKED_UP" in status else "CREATED"
                    self.file_changes.append({"path": str(d), "format": "file", "action": action, "detail": status})
                    print(f"  [FILE] {item} -> {status}")

        # 3. Copy Assets & Register
        assets_src = source_path / "assets"
        if assets_src.exists():
            target_assets = self.target_path / "assets"
            target_assets.mkdir(exist_ok=True)
            for asset in os.listdir(assets_src):
                shutil.copy2(assets_src / asset, target_assets / asset)
            self._register_assets()

        # 4. Generate Production Report
        import sys
        factory_dir = Path(__file__).parent.resolve()
        if str(factory_dir) not in sys.path:
            sys.path.insert(0, str(factory_dir))
        from reports.production_reporter import ProductionReporter
        
        reporter = ProductionReporter(str(factory_dir / "reports"))
        
        try:
            report_path = reporter.generate_report(
                module_name=module_name,
                target_path=self.target_path,
                status="SUCCESS",
                changes={
                    "dependencies": self.dep_manager.get_change_log(),
                    "files": self.file_changes,
                    "assets": [] 
                }
            )
            print(f"📝 [REPORT] Production report generated: {report_path}")
        except Exception as e:
            print(f"⚠️  Failed to generate production report: {e}")

        print(f"✅ Module '{module_name}' injection completed successfully.")
        return True

    def _register_assets(self):
        pubspec_path = self.target_path / "pubspec.yaml"
        data = self.dep_manager.load_pubspec()
        if not (self.target_path / "assets").exists():
            return

        if "flutter" not in data:
            data["flutter"] = {}
        if "assets" not in data["flutter"]:
            data["flutter"]["assets"] = []
        
        if "assets/" not in data["flutter"]["assets"]:
            data["flutter"]["assets"].append("assets/")
            self.dep_manager.save_pubspec(data)
            print("✨ Registered assets in pubspec.yaml")

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 3:
        print("Usage: python module_injector.py <target_project_path> <module_source_path>")
    else:
        try:
            injector = ModuleInjector(sys.argv[1])
            injector.inject_module(sys.argv[2])
        except Exception as e:
            print(f"❌ [FATAL ERROR] {str(e)}")
            sys.exit(1)
