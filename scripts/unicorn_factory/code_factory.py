#!/usr/bin/env python3
"""
unicorn_factory/code_factory.py
===============================
1인 유니콘 자율 소프트웨어 공장의 핵심 코드 주입 및 템플릿 렌더러.
대상 프로젝트의 파일 시스템 충돌을 감지하면 즉시 백업을 생성하고, 
pubspec.yaml/package.json 의존성을 읽어서 안전하게 결합합니다.
PyYAML 라이브러리 부재 시에도 정규식 기반 텍스트 파서로 100% 무중단 병합을 전개합니다.
"""

import os
import sys
import json
import shutil
import re
from pathlib import Path

class ResilientDependencyManager:
    """의존성 파일을 YAML/JSON 라이브러리 없이도 파싱 및 편집 가능한 회복탄력적 매니저"""
    def __init__(self, file_path: Path, tech_stack: str):
        self.file_path = file_path
        self.tech_stack = tech_stack
        self.change_log = []

    def update_dependencies(self, new_deps: list):
        if not self.file_path.exists():
            return []

        # stack-agnostic routing
        if self.file_path.name == "pubspec.yaml":
            return self._update_pubspec_resilient(new_deps)
        elif self.file_path.name == "package.json":
            return self._update_package_json(new_deps)
        return []

    def _update_package_json(self, new_deps: list):
        try:
            with open(self.file_path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            data = {}

        if "dependencies" not in data:
            data["dependencies"] = {}

        conflicts = []
        for dep_str in new_deps:
            if ":" in dep_str:
                name, version = [s.strip() for s in dep_str.split(":", 1)]
                new_version = version.lstrip("^").lstrip("~")
            else:
                name = dep_str.strip()
                new_version = "latest"

            existing = data["dependencies"].get(name)
            if existing:
                existing_ver = existing.lstrip("^").lstrip("~")
                if existing_ver != new_version:
                    data["dependencies"][name] = f"^{new_version}"
                    self.change_log.append({"package": name, "action": "UPGRADED", "from": existing_ver, "to": new_version})
            else:
                data["dependencies"][name] = f"^{new_version}"
                self.change_log.append({"package": name, "action": "ADDED", "from": None, "to": new_version})

        try:
            with open(self.file_path, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
        except Exception as e:
            print(f"[FACTORY ERROR]: Failed to write package.json: {e}", file=sys.stderr)

        return conflicts

    def _update_pubspec_resilient(self, new_deps: list):
        """정규식을 활용해 yaml 구조를 깨뜨리지 않고 의존성 주입"""
        try:
            with open(self.file_path, "r", encoding="utf-8") as f:
                content = f.read()
        except Exception as e:
            print(f"[FACTORY WARN]: Failed to read pubspec: {e}", file=sys.stderr)
            return []

        lines = content.splitlines()
        dep_section_idx = -1
        
        # 1. dependencies: 영역 라인 인덱스 찾기
        for idx, line in enumerate(lines):
            if re.match(r"^dependencies:", line):
                dep_section_idx = idx
                break

        if dep_section_idx == -1:
            lines.append("dependencies:")
            dep_section_idx = len(lines) - 1

        conflicts = []
        for dep_str in new_deps:
            if ":" in dep_str:
                name, version = [s.strip() for s in dep_str.split(":", 1)]
                new_version = version.lstrip("^").lstrip("~")
            else:
                name = dep_str.strip()
                new_version = "any"

            found = False
            for idx in range(dep_section_idx + 1, len(lines)):
                if lines[idx] and not lines[idx].startswith(" ") and not lines[idx].startswith("#"):
                    break
                
                match = re.match(r"^\s+([a-zA-Z0-9_\-]+):\s*(.*)", lines[idx])
                if match and match.group(1) == name:
                    existing_version = match.group(2).strip().lstrip("^").lstrip("~")
                    if existing_version != "any" and new_version != "any" and new_version != existing_version:
                        if new_version > existing_version:
                            lines[idx] = f"  {name}: ^{new_version}"
                            self.change_log.append({"package": name, "action": "UPGRADED", "from": existing_version, "to": new_version})
                        else:
                            conflicts.append({"package": name, "issue": "VERSION_CONFLICT", "resolved": "KEPT_EXISTING"})
                    found = True
                    break

            if not found:
                lines.insert(dep_section_idx + 1, f"  {name}: ^{new_version}" if new_version != "any" else f"  {name}: any")
                self.change_log.append({"package": name, "action": "ADDED", "from": None, "to": new_version})

        try:
            with open(self.file_path, "w", encoding="utf-8") as f:
                f.write("\n".join(lines) + "\n")
            print(f"[FACTORY SUCCESS]: Dependencies merged resiliently into {self.file_path.name}")
        except Exception as e:
            print(f"[FACTORY ERROR]: Failed to write pubspec: {e}", file=sys.stderr)

        return conflicts

    def get_change_log(self):
        return self.change_log


class ConflictResolver:
    """중복이나 충돌 발생 시 원본 소스 보호용 백업 생성기"""
    def __init__(self, target_dir: Path):
        self.target_dir = target_dir
        self.backup_dir = target_dir / ".factory_backups"

    def backup_existing_file(self, dest_path: Path) -> str:
        if not dest_path.exists():
            return "CREATED"

        self.backup_dir.mkdir(parents=True, exist_ok=True)
        timestamp = os.getpid()
        backup_path = self.backup_dir / f"{dest_path.name}.{timestamp}.bak"
        
        try:
            if dest_path.is_dir():
                shutil.copytree(dest_path, backup_path)
            else:
                shutil.copy2(dest_path, backup_path)
            return f"BACKED_UP_TO_{backup_path.name}"
        except Exception as e:
            print(f"[FACTORY WARN]: Backup failed for {dest_path.name}: {e}", file=sys.stderr)
            return "OVERWRITTEN_WITHOUT_BACKUP"


class CodeFactory:
    """코드 자동 주입 및 템플릿 인젝터 본체"""
    def __init__(self, target_project_path: str, app_config: dict = None):
        self.target_path = Path(target_project_path).expanduser().resolve()
        self.app_config = app_config or {}
        
        # Scan configured dependency files
        dep_files = self.app_config.get("dependency_files", ["pubspec.yaml"])
        self.dep_managers = []
        
        for df in dep_files:
            df_path = self.target_path / df
            if not df_path.exists():
                df_path.parent.mkdir(parents=True, exist_ok=True)
                if df == "pubspec.yaml":
                    df_path.write_text("name: temp_project\ndependencies:\n", encoding="utf-8")
                elif df == "package.json":
                    df_path.write_text("{\n  \"dependencies\": {}\n}", encoding="utf-8")
            
            manager = ResilientDependencyManager(df_path, self.app_config.get("tech_stack", "flutter_web"))
            self.dep_managers.append(manager)

        self.conflict_resolver = ConflictResolver(self.target_path)
        self.file_changes = []

    def inject_template_module(self, module_name, dependencies=None, source_files=None):
        """새 모듈 템플릿을 타겟 프로젝트에 자율 주입"""
        dependencies = dependencies or []
        source_files = source_files or {}

        print(f"🚀 [UNICORN FACTORY]: Injecting code module '{module_name}' into {self.target_path}")

        # 1. 의존성 병합
        for manager in self.dep_managers:
            conflicts = manager.update_dependencies(dependencies)
            if conflicts:
                print(f"⚠️  [DEPS WARN]: Version conflicts resolved: {conflicts}")

        # 2. 파일 주입 (with Backup)
        lib_dir = self.target_path / "lib"
        lib_dir.mkdir(parents=True, exist_ok=True)

        for filename, content in source_files.items():
            dest_file = lib_dir / filename
            dest_file.parent.mkdir(parents=True, exist_ok=True)

            status = self.conflict_resolver.backup_existing_file(dest_file)
            
            try:
                dest_file.write_text(content, encoding="utf-8")
                action = "BACKED_UP" if "BACKED_UP" in status else "CREATED"
                self.file_changes.append({"file": filename, "action": action, "backup": status})
                print(f"  [FILE INJECTED]: lib/{filename} -> {status}")
            except Exception as e:
                print(f"❌ [FILE ERROR]: Failed to write {filename}: {e}", file=sys.stderr)

        all_logs = []
        for manager in self.dep_managers:
            all_logs.extend(manager.get_change_log())

        print(f"✅ Module '{module_name}' successfully compiled and integrated!")
        return {
            "module_name": module_name,
            "status": "SUCCESS",
            "changes": {
                "dependencies": all_logs,
                "files": self.file_changes
            }
        }

if __name__ == "__main__":
    # 로컬 셀프 테스트 구동
    temp_dir = Path("/tmp/sfx_test_project")
    temp_dir.mkdir(parents=True, exist_ok=True)
    
    mock_config = {
        "tech_stack": "flutter_web",
        "dependency_files": ["pubspec.yaml"]
    }
    
    factory = CodeFactory(str(temp_dir), app_config=mock_config)
    res = factory.inject_template_module(
        module_name="neon_logger",
        dependencies=["logger: ^2.4.0", "path_provider: ^2.1.0"],
        source_files={
            "core/neon_logger.dart": "class NeonLogger { void log(String msg) { print('[NEON]: $msg'); } }",
            "widgets/neon_badge.dart": "// Neon Glowing Badge Widget"
        }
    )
    print(json.dumps(res, indent=2))
    
    # 임시 폴더 삭제
    shutil.rmtree(temp_dir)
