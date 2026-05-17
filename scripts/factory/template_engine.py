import os
import json
from pathlib import Path

class TemplateEngine:
    def __init__(self, base_output_dir: str):
        self.base_dir = Path(base_output_dir).expanduser().resolve()

    def create_module(self, module_name: str, dependencies: list = None):
        module_path = self.base_dir / module_name
        print(f"🚀 Generating module: {module_name} at {module_path}")

        # 1. Create Directory Structure
        subdirs = [
            "src/features",
            "src/domain",
            "src/data",
            "test",
            "assets"
        ]
        for subdir in subdirs:
            (module_path / subdir).mkdir(parents=True, exist_ok=True)

        # 2. Create .factory_metadata.json
        metadata = {
            "module_name": module_name,
            "version": "1.0.0",
            "dependencies": dependencies or [],
            "generated_at": os.popen('date').read().strip()
        }
        with open(module_path / ".factory_template_metadata.json", "w") as f:
            json.dump(metadata, f, indent=2)

        # 3. Create basic pubspec.yaml
        pubspec = f"""name: {module_name}
description: A factory-generated Flutter module.
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  riverpod: ^2.0.0
"""
        with open(module_path / "pubspec.yaml", "w") as f:
            f.write(pubspec)

        # 4. Create a placeholder main.dart
        main_dart = f"import 'package:flutter/material.dart';\n\nvoid main() => runApp(const MyApp());\n\nclass MyApp extends StatelessWidget {{ @override Widget build(BuildContext context) => MaterialApp(home: Scaffold(body: Center(child: Text('{module_name}')))); }}"
        with open(module_path / "src/main.dart", "w") as f:
            f.write(main_dart)

        print(f"✅ Module {module_name} generation complete.")
        return module_path

if __name__ == "__main__":
    import sys
    engine = TemplateEngine(os.getcwd())
    name = sys.argv[1] if len(sys.argv) > 1 else "default_module"
    engine.create_module(name)
