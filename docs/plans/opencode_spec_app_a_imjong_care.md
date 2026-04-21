# OpenCode App Spec: SFX Imjong Care (App A)

## 1. Product Overview
- **Name:** SFX Imjong Care (임종 케어)
- **Concept:** MZ세대를 위한 트렌디한 '긍정적 유서' 및 인생 마감 명함.
- **Core Feature (MVP):** 가입 시 남기고 싶은 3가지 가치와 유언 1줄을 입력하면, 인스타그램에 공유할 수 있는 화려한 '3D 디지털 유서 카드(Neon/Dark Mode)'를 생성해주는 단일 기능.

## 2. Past Trial & Error (Lessons Learned)
이 앱을 OpenCode(AI)로 개발할 때, 과거 `life_log_vX` 시리즈의 실패를 반복하지 않기 위해 다음 규칙을 엄수해야 합니다.

- **[Apple App Store Rejection 방지]:** 
  - 앱 시작 시 EULA(최종사용자라이선스계약) 동의 화면을 반드시 포함할 것 (가이드라인 5.1.1).
  - 권한 거부 시 설정 앱으로 강제 리다이렉트(`openAppSettings()`)하지 말고, 앱 내에서 우회 UI를 제공할 것 (가이드라인 3.1.2).
- **[Token Limit & Hallucination 방지]:**
  - 처음부터 모든 기능을 만들지 마세요. MVP는 오직 '입력 폼 -> 카드 렌더링 화면' 2개 스크린으로 제한합니다.
- **[State Management Modernization]:**
  - 과거의 낡은 Riverpod 문법 대신, 최신 `@riverpod` 어노테이션 기반의 Riverpod Generator 문법을 사용하세요.
  - 불필요한 데드 코드(Dead Code)를 남기지 않도록 매 스텝마다 `flutter analyze`를 수행하는 것을 전제합니다.

## 3. Implementation Step-by-Step (For OpenCode)
1. **Step 1: Project Setup & Theme**
   - Clean Architecture 폴더 구조 세팅 (`lib/features/`, `lib/core/`).
   - Dark Mode 전용 테마 및 Neon Color 팔레트 정의.
2. **Step 2: Core Entity & State**
   - `WillCard` 엔티티 생성 (이름, 3가지 가치, 한줄 유언).
   - Riverpod Generator를 이용해 입력 폼 상태 관리(`WillFormController`) 구현.
3. **Step 3: UI Implementation**
   - `WillInputScreen`: 사용자 입력을 받는 힙한 텍스트 필드 폼. EULA 체크박스 필수 포함.
   - `WillCardRenderScreen`: 입력된 데이터를 받아 반짝이는 3D 카드 형태로 렌더링하는 뷰 (공유 버튼 포함).
