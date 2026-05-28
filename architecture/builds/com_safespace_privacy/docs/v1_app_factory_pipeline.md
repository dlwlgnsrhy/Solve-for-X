# SafeSpace App Factory — Phase 1: Local Orchestration & App Factory Pipeline Report

이 문서는 **SafeSpace** 로컬 앱 팩토리 파이프라인의 Phase 1 아키텍처와 구축 역사를 상세히 정리한 실물 보고서입니다.

---

## 🏗️ 1. App Factory 로컬 파이프라인 개요

Phase 1의 핵심 목표는 사용자가 웹 화면에서 직접 앱의 스펙(Specification)을 정의하면, 로컬 시스템이 AI 모델 API를 오케스트레이션하여 코드를 자동으로 작성·빌드하고, 실시간으로 모니터링 및 시연할 수 있는 **종합 오프라인 앱 개발 파이프라인**을 정립하는 것이었습니다.

```
[사용자 대시보드 (Streamlit: 8501)] 
       │ 
       ▼ (빌드 요청 및 스펙 전달)
[App Factory Engine (engine.py)] 
       │ 
       ├─► [API 모델 오케스트레이션 체인 (Gemini/Gemma)] ──► 코드 설계도(JSON AST) 분석 및 Dart 스펙 도출
       │ 
       ├─► [Flutter 템플릿 복제 & 패키지 변환] ──► com_safespace_privacy 생성
       │ 
       └─► [Release Web Compilation] ──► active_web_preview 심볼릭 링크 연결
       │ 
       ▼ (실시간 모동작 피드백)
[Web Preview Server (HTTP: 8502)] ◄── 사용자 브라우저 즉시 테스트
```

---

## 🤖 2. 연결된 API 모델 체인 (Orchestration Chain)

로컬 엔진(`engine.py`)은 로컬 `.env` 파일에 기록된 `GEMINI_API_KEY`를 바탕으로 작동하며, 설계도 분석의 무결성과 복원력을 극대화하기 위해 다음과 같이 **우선순위 기반 폴백 체인(Prioritized Model Fallback Chain)**을 구성하여 외부 구글 Generative Language REST API를 다이나믹하게 제어합니다.

1. **`gemini-3.5-flash`** (기본 최우선 모델: 고성능 및 초고속 AST 구조 해석)
2. **`gemini-3-flash-preview`** (1차 폴백: 차세대 코드 완성 시험용)
3. **`gemma-4-31b-it`** (2차 폴백: 미세조정된 로컬 친화형 명령어 이행 모델)
4. **`gemma-4-26b-a4b-it`** (3차 폴백: 고성능 텍스트-코드 매핑용)
5. **`gemini-2.5-flash`** (최종 백업: 안정적인 레거시 스펙 파서 대안)

---

## 🛠️ 3. 시스템 연동 프로세스 및 모니터링 흐름

* **대시보드 모니터링 (`http://localhost:8501/`)**: Streamlit으로 작동하는 GUI를 통해 사용자는 빌드의 시작, AI 라우팅 상태, Flutter 정적 정비, 빌드 진행 상황을 시각적으로 모니터링할 수 있습니다.
* **상태 파일 제어 (`build_status.json`)**: 엔진 내부의 모든 상태 변화(`PROCESSING`, `AI_ROUTING`, `COMPILING`, `SUCCESS`)가 `build_status.json`에 기록되어 대시보드로 실시간 전달됩니다.
* **실시간 시연 세팅 (`http://localhost:8502/`)**: 컴파일 성공 시 `active_web_preview` 심볼릭 링크가 최신 웹 빌드 타깃을 가리키도록 설정되어, 사용자가 대시보드 내에서 즉각 마우스 클릭과 제스처로 결과물을 테스트해 볼 수 있도록 아키텍처를 완성했습니다.
