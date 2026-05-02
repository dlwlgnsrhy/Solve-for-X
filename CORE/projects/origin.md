# Project: Origin (Human Authenticity Protocol)

> **Mission**: AGI 시대에 지능의 결과물이 아닌, **'사유의 과정'**을 기록하여 인간의 오리지널리티를 증명한다.

---

## 1. 핵심 기술 원칙 (Core Principles)

- **On-device First**: 모든 개인 정보와 사유 데이터는 기기를 떠나지 않는다.
- **Process over Result**: 결과물이 아닌, 생성되는 과정(Rhythm, Revisions)을 데이터화한다.
- **No External AI API**: OpenAI, Anthropic 등의 외부 API를 일절 배제하고 로컬 LLM만 사용한다.
- **Zero-Knowledge Proof**: 제3자에게 데이터를 공개하지 않고도 진위 여부만 증명한다.

---

## 2. 주요 기능 명세 (Feature Specification)

### ① Human Pulse Tracker (인간 맥동 추적기)
- **목적**: AI가 흉내 낼 수 없는 인간의 불규칙하고 고뇌 섞인 '입력 리듬'을 기록.
- **데이터 포인트**:
  - 키스트로크 간의 시간 간격 ($t_{delta}$)
  - 문장 중간의 멈춤(Pause) 위치와 지속 시간
  - 수정(Backspace) 횟수 및 재작성된 문구의 맥락
- **기술적 구현**: 모바일 키보드 이벤트 또는 텍스트 필드 변경 리스너를 통해 로컬 SQLite에 원시 데이터를 저장.

### ② Authentic Analyzer (로컬 사유 분석기)
- **모델**: 기기 내 탑재된 Gemma-2b 또는 Llama-3 (Quantized).
- **분석 로직**:
  - 사용자의 평소 문체, 자주 쓰는 단어, 사고의 전개 방식을 로컬에서 학습.
  - 현재 작성 중인 글이 사용자의 '지적 지문(Intellectual Fingerprint)'과 얼마나 일치하는지 계산.
  - $$Authenticity Score = f(Rhythm, Revisions, Continuity)$$

### ③ Origin Stamp (오리진 타임스탬프)
- **인증**: 사유의 과정이 완료되면, 해당 데이터의 해시값과 타임스탬프를 결합하여 로컬 인증서 생성.
- **증명**: 타인에게 "이것은 AI가 만든 것이 아님"을 보여줄 때, 원본 데이터는 숨기고 '인증된 결과물'임만을 보여주는 인터페이스 제공.

---

## 3. 에이전트 개발 지침 (AGENTS.md)

### Technical Constraints
- **Framework**: Flutter (Mobile) or React Native (On-device focus).
- **AI Engine**: Use Local LLM only (Gemma-2b via MLC-LLM or MediaPipe). **NO OpenAI/Anthropic APIs.**
- **Database**: SQLite with encryption for local data storage.
- **Privacy**: Every function must work in 'Airplane Mode'.

### Coding Rules (Vibe Coding)
- **Security First**: Data flows must be unidirectional toward local storage. 
- **Modular Design**: Separate the 'Data Collection' module from the 'AI Analysis' module.
- **Performance**: On-device model execution should not hinder UI performance. Use background isolates/threads.

### High-Priority Tasks
1. Build a 'Human Pulse' listener that records keystroke intervals and deletion history.
2. Implement an On-device LLM wrapper to process local text data.
3. Design a 'Privacy Vault' UI that visualizes the authenticity score without leaking the content.

---

## 4. Vision Alignment
우리는 "인간의 존엄을 위한 성소(Sanctuary for Human Dignity)"를 짓고 있습니다. 모든 코드는 '신뢰'와 '주권'을 반영해야 합니다. 원시 텍스트를 외부 서버로 전송하는 기능은 절대 구현하지 마십시오.
