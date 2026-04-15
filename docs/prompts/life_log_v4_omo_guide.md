# 🚀 omo 전용 앱 개발 가이드 (V4 개선판)

이 가이드는 Gemma 4-bit 모델(omo)이 흔히 저지르는 **환각(Hallucination)**과 **경로 오류**를 방지하기 위해 작성되었습니다. 향후 omo를 활용한 모든 앱 개발 시 아래 원칙을 프롬프트에 포함하십시오.

---

## 🛡️ omo의 필수 3대 방어 원칙

### 1. 절대 경로(Absolute Path)의 생활화
- **실수**: `apps/life_log`에 만들어줘 (X) -> 중첩 폴더 발생의 원인
- **개선**: `/Users/apple/development/soluni/Solve-for-X/apps/life_log_v4/` 처럼 **항상 전체 경로**를 명시하십시오.

### 2. "보고" 대신 "증거" 제출 (Verification)
- **실수**: "다 만들었습니다" (X) -> 환각 가능성 높음
- **개선**: 파일 생성 직후 반드시 `ls -la [경로]` 명령어를 실행하여 **파일의 실제 존재 여부를 시스템 출력으로 증명**하게 하십시오.

### 3. `/ulw-loop` (Ultrawork) 모드 강제
- 일반 대화는 omo가 중간에 포기하거나 거짓말을 할 확률이 높습니다. 반드시 `/ulw-loop` 명령어를 사용하여 검증이 완료될 때까지 루프를 돌리십시오.

---

## ✍️ omo가 가장 잘 듣는 프롬프트 템플릿 (6-Section)

omo에게 명령할 때는 반드시 아래 구조를 지켜서 복사/붙여넣기 하십시오.

```text
/ulw-loop "
[1. TASK]
(한 번에 딱 하나의 파일만 생성/수정하도록 원자적으로 지시)

[2. EXPECTED OUTCOME]
- 생성될 파일명: /Users/apple/development/soluni/Solve-for-X/apps/life_log_v4/lib/...
- 결과 확인용 명령어: ls -la [폴더경로]

[3. REQUIRED TOOLS]
- write_file, run_command(ls) 필수 사용

[4. MUST DO]
- Flutter Clean Architecture 패턴 엄수
- UI 구현 시 Glassmorphism 디자인 적용
- 반드시 '실제로' 도구를 호출할 것 (텍스트 리포트만 쓰지 말 것)

[5. MUST NOT DO]
- 절대로 'v4' 폴더 안에 또 다른 'apps' 폴더를 만들지 말 것
- 문법 오류(Map<<StringString...) 발생 시 즉시 스스로 사과하고 수정할 것

[6. CONTEXT]
- 프로젝트 경로: /Users/apple/development/soluni/Solve-for-X/apps/life_log_v4
- 현재 상태: [Phase X 진행 중]
" --strategy=continue
```

---

## 📈 단계별 진행 절차 (V4 기준)

1.  **Step 1 (Entity)**: 데이터 구조 정의 및 `ls`로 존재 확인.
2.  **Step 2 (API Client)**: Dio 기반 클라이언트 작성 및 `flutter analyze`로 문법 검사.
3.  **Step 3 (Provider)**: Riverpod 상태 관리자 구현.
4.  **Step 4 (UI & Design)**: Glassmorphism이 적용된 화면 구현.
5.  **Step 5 (Final Audit)**: 인격체 에이전트(`review-work`)를 통한 최종 감사.

---
**학습된 교훈**: "AI는 믿는 것이 아니라, 도구 호출 결과(Terminal Output)로 증명하는 존재다."
