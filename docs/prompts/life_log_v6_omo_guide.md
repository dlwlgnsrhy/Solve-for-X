# 🚀 omo 전용 앱 개발 가이드 (V6 마이크로 태스킹 개선판)

이 가이드는 omo(Gemma 4-bit)의 제네릭 문법 붕괴(예: `Map<<StringString`) 및 공수표 TDD(파일 생성 스킵) 현상을 원천 차단하기 위해 작성되었습니다.

---

## 🛡️ V6 핵심 전략: 스켈레톤 사전 주입 & 마이크로 태스킹

더 이상 omo에게 "알아서 폴더 만들고 다 구현해줘"라는 자유도를 주지 않습니다. **기반 파일(Entity, Repository Interface)은 모두 Antigravity가 미리 하드코딩해서 제공**합니다. omo는 오직 "빈칸 채우기"만 수행합니다.

### 📝 omo 전용 프롬프트 지시어 (복사하여 사용)

omo에게 다음 작업을 지시할 때 반드시 아래의 프롬프트를 덧붙이십시오.

```text
/ulw-loop "
[1. CRITICAL RULES]
- **한 번에 단 하나의 파일만 작성/수정할 것!** 여러 기능(API, Provider, UI)을 한 번의 턴에 동시에 만들지 마십시오.
- 문법 오타(예: \`Map<<StringString\`)가 발생하는 것을 막기 위해, 코드 작성 후 **반드시 \`run_command(flutter analyze)\` 를 실행**하여 무결성을 스스로 증명하십시오.
- 만약 \`flutter analyze\`에서 에러가 나오면 즉시 스스로 원인을 분석하고 \`replace_file_content\`나 \`write_to_file\`을 통해 코드를 다시 수정한 뒤, 다시 \`analyze\`를 돌려 pass할 때까지 반복하십시오.

[2. CONTEXT & GOAL]
- 작업 경로: /Users/apple/development/soluni/Solve-for-X/apps/life_log_v6
- 현재 목표: [여기에 단일 목표 작성. 예: planner_api_client.dart 구현]

[3. PROVIDED SKELETON]
- Base Entity ('checkin_data.dart') 와 Interface ('planner_repository.dart')는 이미 완벽하게 존재합니다. 기존 코드를 임의로 변경하지 말고, 이를 'import'하여 사용하십시오.
" --strategy=continue
```

---

## 📈 V6 업무 지시 절차 (순차적 진행 필수)

1.  **API Client 빈칸 채우기**:
    - 목표: `lib/data/datasources/planner_api_client.dart` 에 `Dio`를 이용한 POST 통신 로직 작성. (Endpoint: `http://192.168.45.61:8080/api/health/daily-checkin`)
    - 조건: 작성이 끝나면 무조건 `flutter analyze`.
2.  **State Provider 구현**:
    - 목표: `lib/presentation/providers/checkin_provider.dart`작성 (Riverpod `StateNotifier` 활용).
    - 조건: API Client 주입 및 상태 관리(idle/loading/success). 작성 후 `flutter analyze`.
3.  **UI 렌더링**:
    - 목표: `lib/presentation/pages/checkin_screen.dart`에 Glassmorphism 프리미엄 UI 작성 및 `main.dart`와 연결.
    - 조건: `flutter run` 또는 `analyze`를 통한 검증.

> **에이전트 주의사항**: V6의 목적은 "가장 단순하고 멍청하게, 하지만 절대 오타 없이 확실하게" 1보씩 전진하는 것입니다.
