# TS-0008: Life-Log V5 omo(Gemma) 치명적 문법 붕괴 및 공수표 TDD 보고서

## 📅 날짜: 2026-04-17
## 🏷️ 태그: #문법오류 #Gemma-4bit #omo #실패분석 #V5실패

---

## 1. 🚨 사건 요약
V4 에러를 극복하고자 V5 아키텍처와 엄격한 TDD 파이프라인을 수립하여 omo에게 실행을 지시했으나, omo(Gemma 31B 4-bit)는 또다시 치명적인 제네릭 문법 오류를 일으키고 작성해야 할 파일을 누락하는 **공수표 TDD(Empty TDD)** 현상을 보였습니다. 

## 2. 🔍 상세 진단 결과 (V5 부검)

### A. 제네릭/타입 문법 붕괴 (Syntax Collapse)
- **현상 1**: `lib/domain/entities/checkin_data.dart` 파일에서 `Map<<StringString, dynamic>` 생성. 부등호 중첩과 단어(`String`) 반복이 나타남.
- **현상 2**: `test/data/datasources/planner_api_client_test.dart` 파일에서 `isA << ExceptionException >` 생성. 역시 부등호 중첩과 클래스 이름 중복이 나타남.
- **원인**: 4-bit 양자화 모델이 복잡한 프로그래밍 문맥(특히 Dart의 제네릭 $< >$ 처리 및 예외 클래스 처리)에서 추론 확률(Logits) 계산 오류를 일으키며 '말더듬' 현상이 도짐.

### B. 공수표 TDD (Empty TDD)
- **현상**: `test/data/datasources/planner_api_client_test.dart` 테스트 파일은 작성되었으나, 실제 테스트의 대상이 되는 구현 파일 `lib/data/datasources/planner_api_client.dart`는 존재하지 않음.
- **원인**: omo 시스템의 도구 한도, 프롬프트 컨텍스트 창 축적, 또는 인지 한계로 인해 구현 단계를 완전히 스킵하면서도 "모두 완료했다"고 착각함.

### C. 프로젝트 통합 실패
- **현상**: `main.dart`는 여전히 Flutter 템플릿(카운터 앱) 상태로 남아있어, 작성된 Domain/Data/Test 레이어가 앱과 전혀 결합되지 못함.

## 3. 📉 영향 및 학습
- AI를 통한 완전 자동화 한계 파악: 양자화된 로컬 모델에 전적으로 의존하는 '선 구현, 후 테스트' 혹은 '선 테스트, 후 구현' 모두 코드 조각들이 파편화되고 문법이 오염된 채 방치될 위험이 매우 높습니다.
- **인간(혹은 고지능 상위 에이전트)의 개입 필수**: 프로젝트의 뼈대 스켈레톤(Skeleton)은 반드시 오타가 나지 않도록 하드코딩해서 쥐어주고, 에이전트는 '빈칸 채우기' 혹은 '정해진 로직 채우기' 수준으로 업무를 잘게 쪼개야 합니다.

## 4. 🛠️ 조치 및 향후 방침 (V6)
- **V5 격리**: `apps/life_log_v5` 디렉토리를 `apps/life_log_v5_failed`로 변경하여 증거자료 보존.
- **V6 (Antigravity 직접 주도)**: 
  - `apps/life_log_v6` 뼈대(Clean Architecture 폴더, 기본 Entity, 인터페이스 템플릿 등)를 Antigravity가 직접 오류 없이 작성.
  - omo에게는 **파일 하나 단위**로만 업무 할당 및 `flutter analyze` 후 다음 스텝 진행 허용 방식 도입.

---
**상태**: 🔴 V5 실패. V6 재건축 진입.
