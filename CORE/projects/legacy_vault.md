# Project: Legacy Vault (레거시 볼트)

> **Subtitle**: The Only Place for Your True Self.
> **Vision**: "Google은 당신의 데이터를 학습하지만, Legacy Vault는 당신의 존엄을 보호합니다. 우리는 당신의 목소리를 듣지만, 결코 엿듣지 않습니다."

---

## 1. 핵심 기능 (Feature Specification)

### ① AI 지능형 라이프 로깅 (Soul-Mining)
- **음성 일기 (Local STT)**: 사용자가 말을 하면 기기 내에서 즉시 텍스트로 변환됩니다. (서버 전송 없음)
- **맥락 감지 에이전트 (On-device LLM)**: 
  - 단순한 사실 기록을 넘어, AI가 철학적 질문을 던져 기록을 풍성하게 만듦.
  - 예: "그때 기분은 어떠셨나요?", "그 선택이 당신의 삶에 어떤 의미인가요?"
- **개인화 학습**: Gemma-2b 또는 Llama-3-8B 경량화 모델이 사용자만의 말투와 가치관을 학습.

### ② 가치관 지도 (Value Mapping)
- **키워드 추출**: 기록된 데이터에서 중요 키워드(가족, 도전, 평화 등) 자동 추출.
- **인생 타임라인**: 텍스트, 사진, 감정을 결합하여 한 개인의 인생을 서사(Narrative)로 재구성.

### ③ 가디언 프로토콜 (Inheritance & Security)
- **데드맨 스위치 (Dead Man’s Switch)**: 일정 기간 미접속 시 지정된 상속인에게 데이터 접근 권한 이양 또는 영구 삭제.
- **제로 놀리지 백업 (Zero-Knowledge Backup)**: 기기에서만 풀 수 있는 키로 이중 암호화하여 iCloud/Drive에 백업.

### ④ 디지털 페르소나 엔진 (Legacy Agent)
- **미래를 위한 대화**: 후손이 앱을 켰을 때, 사용자의 가치관을 학습한 AI가 사용자의 목소리와 생각으로 답변.
- **순수 로컬 구동**: 페르소나 역시 외부 서버가 아닌 해당 기기 안에서만 존재.

---

## 2. 기술 스택 (Tech Stack for Sovereignty)

- **AI Engine**: MLC LLM or Google MediaPipe AI Edge (iOS/Android)
- **Model**: Gemma-2b-it-q4f16 (4-bit quantization)
- **Storage**: SQLite + Vector Extension (Local RAG 구현)
- **Privacy**: 모든 API 호출을 차단하는 '오프라인 모드 우선' 설계

---

## 3. 에이전트 개발 지침 (AGENTS.md)

### Technical Constraints
- **Principle**: "No External AI API" - 절대 외부 서버로 데이터를 보내는 라이브러리 사용 금지.
- **Offline First**: 모든 기능은 비행기 모드에서도 완벽하게 작동해야 함.

### Automation Strategy
- **멀티 타겟 빌드**: 각 국가의 언어와 '장례/유산 문화'에 맞춘 UI 셋 자동 생성.
- **A/B 테스트 자동화**: "보안 강조형" vs "감성 기록형" 스토어 페이지 문구 자동 생성 및 최적화.

---

## 4. 핵심 가치 (The 결정적 한 방)
Legacy Vault는 지능이 아닌 **'존엄'**을 보호하는 곳입니다. 우리의 코드는 사용자의 목소리를 듣지만, 결코 엿듣지 않는 구조를 유지해야 합니다.
