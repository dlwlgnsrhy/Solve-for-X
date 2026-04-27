# Solve-for-X Master Development Plan

## Overview
3개 Flutter 앱을 순차적으로 개발하는 마스터 계획서.

| Priority | App | Name | Concept | Status |
|----------|-----|------|---------|--------|
| 1 | App A | SFX Imjong Care | 긍정적 유서 / 디지털 유서 카드 | ✅ Scaffold 완료 (15개 파일) |
| 2 | App B | SFX Memento Mori | 스토익 철학 / 남은 주 시각화 (4,160 grid) | ⏳ Pending |
| 3 | App C | SFX Legacy Vault | 데드맨 스위치 / 디지털 유산 자동 발송 | ⏳ Pending |

---

## App A: SFX Imjong Care (임종 케어)

### Current State
- Scaffold 완료: 15개 Dart 파일 (Clean Architecture)
- 폴더 구조: `lib/core/` + `lib/features/will_input/` + `lib/features/will_card/`
- 기존 코드: EULA 체크박스, 입력 폼, 3D 네온 카드, 공유 버튼

### Remaining Tasks (Estimated: 3-5 days)

#### Phase A1: Polish & QA (2-3 days)
- [ ] Flutter analyze 모든 warning/error 해결
- [ ] iOS Simulator 에서 빌드 + 실행 테스트
- [ ] 다크모드 + 네온 테마 UI 최종 다듬기
- [ ] 카드 공유 기능 (이미지 공유) 테스트
- [ ] EULA 동의 → 동의하지 않을 경우의 UX 검증
- [ ] 3회 이상 테스트-개선 사이클 수행

#### Phase A2: Medium 블로그 연동 (1-2 days)
- [ ] 작성 완료한 카드 정보를 Medium 포스팅으로 자동 발행
- [ ] browser-harness + Medium 자동화 파이프라인 연결
- [ ] Telegram 봇 명령어로 Medium 발행 트리거

#### Phase A3: App Store 준비 (2-3 days)
- [ ] App Store Connect 설정 (번들 ID, 프로비저닝)
- [ ] Privacy Policy, EULA 최종 문서화
- [ ] App Icon, 스크린샷, 앱 설명 작성
- [ ] TestFlight 빌드 → 피드백 수집

---

## App B: SFX Memento Mori (메멘토 모리)

### Concept
Stoic 철학 기반. 생년월일 + 예상수명 입력 → 4,160개 주(Grid) 렌더링. 지나간 주는 회색, 남은 주는 네온 그린.

### Development Plan (Estimated: 5-7 days)

#### Phase B1: Project Setup (1 day)
- [ ] Flutter 프로젝트 생성: `sfx-memento-mori`
- [ ] Clean Architecture 폴더 구조 (`lib/features/`, `lib/core/`)
- [ ] 다크모드 + 네온 테마 정의
- [ ] 의존성: `riverpod_generator`, `shared_preferences`, `intl`

#### Phase B2: Core Logic (1-2 days)
- [ ] `DateTime` → `Weeks` 계산 로직 (생년월일 ~ 현재)
- [ ] `LifeTimeProvider`: 경과주/남은주/총주 계산
- [ ] SharedPreferences 저장/로드 (생년월일, 타겟나이)
- [ ] 테스트: 계산 로직 unit test

#### Phase B3: Onboarding UI (1 day)
- [ ] EULA 동의 화면 (체크박스 필수)
- [ ] 생년월일 입력 (DatePicker)
- [ ] 타겟 나이 선택 (Slider 또는 버튼: 70-90)
- [ ] 로컬 저장 + 메인 화면 이동

#### Phase B4: Main Grid UI (2 days)
- [ ] `GridView.builder` 사용 (4,160개 네모 렌더링, 메모리 최적화)
- [ ] 지난 주: 회색 + 부드러운 어둡게
- [ ] 남은 주: 네온 그린 + 부드러운 빛나는 효과
- [ ] 현재 위치 표시 (지금 여기)
- [ ] 남은 주 수 메시지: "당신에게 남은 시간은 N주입니다"
- [ ] 스크롤 시 Smooth 애니메이션

#### Phase B5: Polish & QA (1-2 days)
- [ ] 성능 테스트 (4,160개 렌더링 FPS 확인)
- [ ] iOS Simulator 빌드 테스트
- [ ] 3회 이상 테스트-개선 사이클
- [ ] App Store 준비 (Privacy Policy, 아이콘 등)

### Key Technical Decisions
- **Local-only**: Firebase 미사용, SharedPreferences만 사용
- **Performance**: GridView.builder 필수, CustomScrollView 고려
- **Animation**: 남은 칸에 집중하는 부드러운 네온 효과

---

## App C: SFX Legacy Vault (레거시 볼트 / 데드맨 스위치)

### Concept
암호/시드구문/편지를 앱에 저장. 주기적 생존확인 알림. N주 동안 미응답 시 지정 이메일로 자동 발송.

### Development Plan (Estimated: 10-14 days)

#### Phase C1: Firebase Setup (2 days)
- [ ] Firebase 프로젝트 생성 (App Store용)
- [ ] Firebase Auth 설정 (이메일/패스워드 또는 Apple 로그인)
- [ ] Firestore 스키마 설계:
  ```
  users/{userId}/
    - lastActiveAt: Timestamp
    - targetEmail: String
    - encryptedData: String (AES-256)
    - deadlineDays: int
    - createdAt: Timestamp
    - status: "active" | "alerted" | "sent"
  ```
- [ ] Firebase Cloud Functions 프로젝트 설정

#### Phase C2: Client App - Auth & UI (2-3 days)
- [ ] Flutter 프로젝트 생성: `sfx-legacy-vault`
- [ ] Firebase Auth 통합 (이메일/Apple Sign-in)
- [ ] EULA + Privacy Policy 동의 화면 (필수)
- [ ] 보안 데이터 입력 UI:
  - 암호 저장 (비트코인 시드, 비밀번호 등)
  - 편지 작성 (텍스트 + 이미지/영상 업로드)
  - 타겟 이메일 설정
  - 생존확인 기간 설정 (7일 단위)
- [ ] 클라이언트 사이드 암호화 (AES-256)
- [ ] 앱 실행 시 서버 Ping (lastActiveAt 업데이트)

#### Phase C3: Serverless Backend (3-4 days)
- [ ] Cloud Function: `checkDeadMansSwitch` (매일 00:00 UTC)
  - lastActiveAt에서 deadlineDays 초과된 유저 찾기
  - 상태에 따라 알림/발송 로직 분기
- [ ] Cloud Function: `sendSurvivalCheck` (FCM 푸시)
  - deadline 7일 전: 첫 번째 경고
  - deadline 3일 전: 두 번째 경고
  - deadline 도래: 최종 발송
- [ ] 이메일 발송: SendGrid 또는 Firebase SendGrid 연동
  - encryptedData + 복호화 링크 포함
  - 보안 이메일 템플릿
- [ ] Cloud Function: `ping` endpoint
  - 클라이언트에서 호출하여 lastActiveAt 업데이트

#### Phase C4: Security & Compliance (2 days)
- [ ] 클라이언트 사이드 암호화 검증 (단방향 암호화 확인)
- [ ] Firestore Security Rules 작성
- [ ] Privacy Policy 문서화 (EU GDPR 대응)
- [ ] EULA 최종 문서화
- [ ] App Store 심사 준비 (민감 정보 취급 앱 기준)

#### Phase C5: QA & Deployment (2-3 days)
- [ ] Firebase Test Lab 실행
- [ ] End-to-end 테스트 (Ping → deadline 초과 → 이메일 발송)
- [ ] 3회 이상 테스트-개선 사이클
- [ ] TestFlight 빌드
- [ ] App Store 제출 준비

### Key Technical Decisions
- **Server-driven**: 백그라운드 알림이 아닌 서버主導로 설계
- **Security**: 클라이언트 암호화 필수 (Firebase가 데이터 볼 수 없음)
- **Compliance**: GDPR + App Store 심사 가이드라인 5.1.1 준수
- **Email**: SendGrid 또는 Firebase Email API

---

## 전체 로드맵 (Estimated Timeline)

```
Week 1: App A Polish & QA (3-5 days)
  ├── Phase A1: Flutter 빌드 + 테스트 + 다듬기
  ├── Phase A2: Medium 연동
  └── Phase A3: App Store 제출 준비

Week 2-3: App B Full Development (5-7 days)
  ├── Phase B1-B2: Setup + Core Logic
  ├── Phase B3-B4: Onboarding + Grid UI
  └── Phase B5: Polish & QA

Week 4-6: App C Full Development (10-14 days)
  ├── Phase C1: Firebase + Cloud Functions Setup
  ├── Phase C2: Client App (Auth + Security)
  ├── Phase C3: Backend (Cron + Email)
  ├── Phase C4: Security & Compliance
  └── Phase C5: QA & Deployment
```

### Total Estimated: 5-6 weeks

---

## Tech Stack Summary

| App | Backend | Storage | Auth | Special |
|-----|---------|---------|------|---------|
| A | None | Hive/SharedPreferences | None | browser-harness (Medium) |
| B | None | SharedPreferences | None | GridView (4,160 items) |
| C | Firebase | Firestore + Storage | Firebase Auth | Cloud Functions + SendGrid |

---

## 공통 규칙 (모든 앱에 적용)

1. **App Store 준수**: EULA 필수, 강제 리다이렉트 금지
2. **Clean Architecture**: `lib/features/`, `lib/core/` 구조
3. **Riverpod Generator**: 최신 어노테이션 기반 문법
4. **테스트-개선 사이클**: 3회 이상 반복
5. **Flutter analyze**: 각 단계마다 실행, 경고 없이 통과해야 함
6. **OpenCode 사용**: AI 에이전트 기반 코드 생성 활용
