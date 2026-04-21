# OpenCode App Spec: SFX Memento Mori (App B)

## 1. Product Overview
- **Name:** SFX Memento Mori (메멘토 모리)
- **Concept:** 스토익(Stoic) 철학을 바탕으로, 내 인생의 남은 시간을 시각적으로 타격감 있게 보여주는 앱.
- **Core Feature (MVP):** 
  - 사용자의 생년월일과 예상 수명(예: 80세)을 입력받습니다.
  - 80년 = 약 4,160주의 작은 네모 칸(Grid)을 화면에 렌더링하고, 이미 지나간 주는 어둡게(회색), 남은 주는 밝게(Neon Green) 칠하여 보여줍니다. "당신에게 남은 시간은 N주입니다"라는 메시지를 띄웁니다.

## 2. Past Trial & Error (Lessons Learned)
- **[UI 렌더링 성능 최적화]:**
  - 4,160개의 위젯을 그릴 때 `GridView.builder`를 반드시 사용하여 메모리 릭(Memory Leak)을 방지하세요. 과거 성능 최적화 실패 사례를 참고하여 렌더링 비용을 최소화해야 합니다.
- **[Architecture Simplicity]:**
  - 서버나 DB 연동 없이 오직 로컬(Shared Preferences)에만 생년월일을 저장하여 초기 개발 속도를 극대화합니다. Firebase조차 붙이지 않는 '완전한 클라이언트 로컬 앱'으로 기획합니다. (빠른 시장 출시 목적)
- **[User Motivation]:**
  - 앱이 너무 우울해지지 않도록, 지나간 시간을 후회하게 만드는 것이 아니라 '남은 빛나는 네모 칸(시간)'에 집중하도록 UI 애니메이션을 추가하세요.

## 3. Implementation Step-by-Step (For OpenCode)
1. **Step 1: Local Storage & State**
   - `shared_preferences` 패키지를 이용해 User의 생년월일(DOB) 저장/로드 로직 구현.
   - Riverpod을 통해 '오늘 날짜 - 생년월일'을 계산하여 경과된 '주(Weeks)'를 도출하는 `LifeTimeProvider` 생성.
2. **Step 2: Onboarding UI**
   - 생년월일과 원하는 타겟 나이(예: 80)를 입력받는 심플한 화면. EULA 동의 체크 필수.
3. **Step 3: Main Grid UI**
   - `CustomScrollView` 또는 `GridView.builder`를 사용하여 4000여 개의 네모 칸 렌더링.
   - 스크롤을 내리면서 압도적인 시간의 시각화를 경험하도록 Smooth Scroll 구현.
