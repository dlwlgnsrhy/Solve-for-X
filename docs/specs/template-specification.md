# Module & App Template Specification

## Folder Structure Standard
Every generated module must follow this hierarchy to ensure compatibility with the Injector logic:
```text
module_name/
├── .factory_metadata.json   # Module identity and dependencies
├── src/                     # Core logic (Dart/Flutter)
│   ├── features/            # Feature-driven architecture
│   ├── domain/              # Business logic & entities
│   └── data/                # Repositories & Data sources
├── test/                    # Automated unit & integration tests
├── assets/                  # Static resources
└── README.md                # Module documentation
```

## Injection Logic (The Injector)
The `Module Injector` reads `.factory_metadata.json` and performs:
1. **Dependency Resolution**: Checks `pubspec.yaml` for conflicts.
2. **Code Merging**: Injects new feature folders into the target project's `lib/`.
3. **Asset Registration**: Automatically adds paths to `pubspec.yaml`.
