# 🚀 Life-Log V7 — omo 풀 오케스트레이션 작업 계획서 (Qwen 3.6)

**작성일**: 2026-04-17  
**모델**: Qwen 3.6-35B-A3B (에이전트 특화 MoE)  
**전략**: omo의 내장 파이프라인(Prometheus → Atlas → Sisyphus)을 100% 활용  
**목표**: Life-Log MVP를 **omo만으로** 기획부터 구현까지 완성

---

## 🧠 omo의 내장 워크플로 이해 (왜 이 방식이 최선인가)

omo는 단순한 코딩 도우미가 아니라, **3단계 오케스트레이션 시스템**입니다:

```
[Tab] Prometheus (기획자)
  ↓ 인터뷰 → 리서치 → 설계서 생성 → .sisyphus/plans/에 저장
  ↓
[/start-work] Atlas (오케스트레이터)
  ↓ 설계서 읽기 → 태스크 분해 → boulder.json 상태 관리
  ↓ 태스크마다 Sisyphus에게 위임
  ↓
Sisyphus (실행자)
  ↓ 코드 작성 → 도구 호출 → 파일 생성 → 검증
  ↓
[/review-work 스킬] 5개 에이전트 병렬 감사
```

이전에는 이 파이프라인을 무시하고 직접 "코드 짜줘"라고 채팅했기 때문에 실패했습니다.  
이번에는 **omo가 설계한 대로** 정석 루트를 타봅니다.

---

## 📋 실행 매뉴얼 (지표님이 따라할 순서)

### 🟢 Step 0: 프로젝트 초기화 (터미널에서 직접)

omo를 띄우기 전에 깨끗한 V7 프로젝트를 먼저 세팅합니다.

```bash
cd /Users/apple/development/soluni/Solve-for-X

# V6 스켈레톤을 V7으로 복사
cp -R apps/life_log_v6 apps/life_log_v7

# pubspec 이름 변경
sed -i '' 's/name: life_log_v6/name: life_log_v7/' apps/life_log_v7/pubspec.yaml

# omo가 깨뜨린 파일 삭제 (Antigravity가 작성한 무결 파일만 보존)
rm -f apps/life_log_v7/lib/data/datasources/planner_api_client.dart

# test import 업데이트
sed -i '' 's/life_log_v6/life_log_v7/g' apps/life_log_v7/test/widget_test.dart

# 의존성 설치
cd apps/life_log_v7 && flutter pub get && cd ../..

# .sisyphus 폴더 초기화 (omo의 작업 공간)
mkdir -p .sisyphus/plans .sisyphus/drafts
```

---

### 🔵 Step 1: Prometheus 모드로 설계서 생성 (Tab 키)

omo 터미널(`opencode`)을 열고, **Tab 키를 눌러 Prometheus(기획 모드)**에 진입합니다.

그러면 Prometheus가 인터뷰를 시작합니다. 아래 내용을 **첫 번째 메시지로 통째로 붙여넣기** 하세요:

```
나는 Solve-for-X 프로젝트의 Life-Log 앱을 만들고 있어.

## 프로젝트 정보
- 경로: /Users/apple/development/soluni/Solve-for-X/apps/life_log_v7
- 기술 스택: Flutter, Riverpod (flutter_riverpod), Dio, GoogleFonts
- 아키텍처: Clean Architecture (domain/data/presentation 3계층)

## 이미 존재하는 파일 (Antigravity가 작성, 수정 금지)
1. lib/domain/entities/checkin_data.dart
   - CheckinData 클래스 (energyLevel, mood, focusMode)
   - toJson(), fromJson() 포함
2. lib/domain/repositories/planner_repository.dart
   - abstract PlannerRepository { Future<bool> submitCheckin(CheckinData) }

## 내가 원하는 것
1. PlannerApiClient 구현 (Dio로 POST http://192.168.45.61:8080/api/health/daily-checkin)
2. CheckinProvider 구현 (Riverpod StateNotifier, idle/loading/success/error 상태)
3. CheckinScreen UI 구현 (Glassmorphism 디자인, 에너지 별점, 이모지 기분, 포커스 모드 선택)
4. main.dart 통합 (ProviderScope, dark theme, GoogleFonts.inter)

## 반드시 지켜야 할 규칙
- 기존 domain/ 파일은 절대 수정하지 말 것
- 각 파일 작성 후 반드시 flutter analyze로 에러 0건 검증할 것
- 제네릭 타입에서 부등호 중복 금지 (예: Future<<boolbool> 같은 오타 금지)
- import는 반드시 package:life_log_v7/... 형식 사용

## 디자인 요구사항
- 배경: Deep Abyss 그라디언트 (0xFF0F2027 → 0xFF203A43 → 0xFF2C5364)
- 카드: ClipRRect + BackdropFilter(sigma 15) + white opacity 0.05
- 제출 성공 시: SnackBar("오늘의 AI 플래너가 생성되었습니다!")
```

> Prometheus가 추가 질문을 하면 성실히 답변하세요. 답변이 끝나면 Prometheus가 자동으로 설계서를 `.sisyphus/plans/`에 저장합니다.

---

### 🟡 Step 2: /start-work로 실행 시작

Prometheus가 "Plan saved. Run `/start-work`" 메시지를 보내면:

```
/start-work
```

이 한 줄만 입력하면 **Atlas 오케스트레이터**가:
1. `.sisyphus/plans/`에서 설계서를 읽고
2. `boulder.json`에 상태를 기록하고
3. 태스크를 세분화하여 **Sisyphus에게 하나씩 위임**합니다

Atlas가 알아서 순서를 정하고, 각 태스크 완료 후 다음 태스크로 자동 전환합니다.

---

### 🟠 Step 3: 작업 중 모니터링

Atlas/Sisyphus가 작업하는 동안 **지표님이 해야 할 것**:

#### 3-1. 생존 확인 (5분마다 한 번)
omo가 멈추거나 반복만 하고 있다면:
```
continue
```

#### 3-2. 컨텍스트 리셋이 필요할 때
omo가 길을 잃었거나 환각을 보이면:
```
/start-work
```
→ boulder.json의 상태를 읽어서 **마지막 미완료 태스크부터 자동 재개**합니다.

#### 3-3. 세션이 끊어졌을 때 (터미널 재시작 등)
새 opencode 세션을 열고:
```
/start-work
```
→ 이전 세션의 진행 상태(`boulder.json`)를 이어받아 자동 재개합니다.

---

### 🔴 Step 4: 최종 검증 (review-work 스킬)

모든 태스크가 완료되면, **5개 에이전트 병렬 감사**를 실행합니다:

```
이 프로젝트의 코드 품질을 review-work 스킬로 감사해줘.
대상 경로: /Users/apple/development/soluni/Solve-for-X/apps/life_log_v7
```

review-work는 다음 5명의 감사관을 동시에 실행합니다:
1. **Goal Alignment** — 원래 목표와 일치하는지
2. **QA Engineer** — 에러 핸들링, 엣지 케이스
3. **Code Quality** — 코드 스타일, 아키텍처 준수
4. **Security** — 보안 취약점
5. **Context Validator** — 파일 간 import 관계 무결성

---

## 🛡️ 비상 대응 프로토콜

### 만약 제네릭 오타가 또 나온다면?
```
방금 작성한 파일에 제네릭 오타(예: Future<<boolbool>)가 있다. 
즉시 해당 파일을 다시 읽고, 모든 < > 타입 선언을 검사하여 수정하라.
수정 후 flutter analyze로 에러 0건을 증명하라.
```

### 만약 파일이 생성되지 않았다면?
```
ls -la /Users/apple/development/soluni/Solve-for-X/apps/life_log_v7/lib/data/datasources/
위 명령어를 실행하여 planner_api_client.dart가 실제로 존재하는지 확인하라.
존재하지 않으면 즉시 생성하라. "만들었습니다"라는 텍스트 보고만 하지 말고, 
반드시 write_file 도구를 호출하여 실제로 파일을 디스크에 기록하라.
```

### 만약 무한 루프에 빠졌다면?
```
/stop
```
→ 현재 루프를 강제 중단합니다. 이후 `/start-work`로 마지막 미완료 태스크부터 재개.

---

## 📊 Gemma(구) vs Qwen 3.6(신) + omo 정석 루트 비교

| 항목 | Gemma 4-bit + 자유 채팅 (V1~V5) | Qwen 3.6 + omo 정석 루트 (V7) |
|------|-------------------------------|------------------------------|
| 기획 | 사람이 프롬프트로 직접 지시 | Prometheus가 인터뷰 후 설계서 자동 생성 |
| 태스크 관리 | 없음 (한 번에 다 시킴) | Atlas가 boulder.json으로 상태 추적 |
| 실행 | Sisyphus에게 자유 위임 | Atlas가 1태스크씩 Sisyphus에 위임 |
| 검증 | 없음 (환각 그대로 통과) | flutter analyze 강제 + review-work 감사 |
| 세션 복구 | 불가능 (처음부터 다시) | boulder.json으로 자동 재개 |
| 에이전트 특화 | Dense 모델, 도구 호출 취약 | MoE 에이전트 특화, 도구 호출 강화 |

---

## ⏰ 예상 타임라인

| 단계 | 예상 시간 | 비고 |
|------|----------|------|
| Step 0 (초기화) | 3분 | 터미널 수동 작업 |
| Step 1 (Prometheus 기획) | 5~10분 | Tab → 인터뷰 → 설계서 |
| Step 2 (Atlas 실행) | 20~40분 | /start-work → 4개 파일 순차 생성 |
| Step 3 (모니터링) | 진행 중 감시 | 5분마다 생존 확인 |
| Step 4 (review-work) | 5~10분 | 5개 에이전트 병렬 감사 |
| **총합** | **약 40분~1시간** | |

---

## ✅ 성공 기준 체크리스트

- [ ] `.sisyphus/plans/`에 설계서 파일 존재
- [ ] `lib/data/datasources/planner_api_client.dart` 존재 및 compile 통과
- [ ] `lib/presentation/providers/checkin_provider.dart` 존재 및 compile 통과
- [ ] `lib/presentation/pages/checkin_screen.dart` 존재 및 compile 통과
- [ ] `main.dart`가 CheckinScreen과 연결됨
- [ ] `flutter analyze` 에러 0건
- [ ] review-work 감사 통과

---

**이 계획서대로 실행하면, omo의 전체 파이프라인을 처음으로 정석대로 활용하게 됩니다.**  
**Qwen 3.6의 에이전트 특화 능력 + omo의 오케스트레이션 = V1~V6의 실패를 넘어서는 첫 번째 성공.**
