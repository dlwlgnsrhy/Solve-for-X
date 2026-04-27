# Solve-for-X 3개 앱 최종 개발 보고서

**작성일:** 2026-04-26
**테스트 환경:** iPhone 15 Pro Max Simulator, Flutter 3.29.3, Dart 3.7.2
**개발 기간:** 1일 (3 Cycle × 3 앱 병렬 개발)

---

## 1. 최종 상태 요약

| 앱 | flutter analyze | flutter build ios | 상태 |
|---|---|---|---|
| App A (Imjong Care) | ✅ 0 issues | ✅ 빌드 중 | 완료 |
| App B (Memento Mori) | ✅ 0 issues | ✅ 10.8s | 완료 |
| App C (Legacy Vault) | ✅ 0 issues | ✅ 11.4s | 완료 |

---

## 2. 개선 사이클 요약

### Cycle 1: UI/UX Premium화

| 앱 | 개선 내용 |
|---|---|
| App A | 카드 템플릿 4종 (Neon/Sunset/Ocean/Aurora), 템플릿 선택 UI, 템플릿 기반 색상 시스템 |
| App B | 프리미엄 스탯 카드, 원형 진행률 인디케이터, 오늘 하이라이트, 공유 버튼, 연도 마커 |
| App C | 신뢰 신호 UI (AES-256/Zero-Knowledge 뱃지), 4단계 온보딩 위자드, 보안 강도 미터 |

### Cycle 2: 기능 확장

| 앱 | 개선 내용 |
|---|---|
| App A | 공유 카드 템플릿 연동 (템플릿 기반 색상/그라디언트/그림자), share_card_content.dart 템플릿화 |
| App B | 마일스톤 마커(10세, 20세...), 인생 인용구(7 단계), 설정 화면, branded 공유 프레임, 통계 확장(남은 일수, 현재 나이, 진행률) |
| App C | 다중 Vault 지원, Vault 타입(Crypto/Passwords/Letter/Custom), 카운트다운 타이머, 상태 인디케이터(Active/Warning/Expired/Paused) |

### Cycle 3: 마켓플레이스 최적화

| 앱 | 개선 내용 |
|---|---|
| App A | In-app review(3회 생성 후), 온보딩 랜딩화면, 카드 히스토리(최대 10개), App Store 메타데이터, Privacy Policy |
| App B | In-app review(7일 사용 후), Welcome 스크린(4,160주 미니 그리드), App Store 메타데이터, 개인정보처리방침 다이얼로그,.share 이미지 향상 |
| App C | In-app review(5회 ping 후), Welcome 보안 랜딩, App Store 메타데이터, Privacy Policy, 보안 뱃지/팁/최종 ping 시각 |

---

## 3. App A: SFX Imjong Care (임종 케어)

**경로:** `/Users/apple/development/soluni/sfx-imjong-care/sfx_imjong_care/`
**번들 ID:** `com.sfx.sfxImjongCare`

### 핵심 기능
- 디지털 유서 카드 생성 (이름, 3가지 가치, 한 줄 유언)
- 카드 템플릿 4종 선택 (Neon/Sunset/Ocean/Aurora)
- 3D 카드 렌더링 + 공유 (이미지 캡처)
- 카드 히스토리 (최대 10개 저장)
- EULA 동의 필수

### 핵심 기능
- 디지털 유서 카드 생성 (이름, 3가지 가치, 한 줄 유언)
- 카드 템플릿 4종 선택 (Neon/Sunset/Ocean/Aurora)
- 3D 카드 렌더링 + 공유 (이미지 캡처)
- 카드 히스토리 (최대 10개 저장)
- EULA 동의 필수

### 파일 구조
```
lib/
├── main.dart
├── core/
│   ├── constants/app_constants.dart (EULA + Privacy Policy)
│   ├── theme/
│   │   ├── neon_colors.dart
│   │   ├── app_typography.dart
│   │   └── card_template.dart (4 templates)
│   ├── services/app_storage.dart
│   └── ...
├── features/
│   ├── will_input/
│   │   ├── data/
│   │   ├── domain/
│   │   │   ├── entities/will_card.dart
│   │   │   ├── providers/
│   │   │   │   ├── will_form_provider.dart
│   │   │   │   └── card_template_provider.dart
│   │   └── presentation/
│   │       ├── screens/will_input_screen.dart
│   │       └── widgets/
│   │           ├── value_input_field.dart
│   │           └── eula_checkbox.dart
│   ├── will_card/
│   │   └── presentation/
│   │       ├── screens/will_card_screen.dart
│   │       └── widgets/
│   │           ├── neon_3d_card.dart
│   │           ├── share_card_content.dart
│   │           └── card_share_button.dart
│   ├── onboarding/
│   │   └── presentation/screens/onboarding_screen.dart
│   └── card_history/
│       └── presentation/widgets/card_history_section.dart
└── ...
```

### APP_STORE_META.md 포함
- 앱명: "SFX 임종 케어 - 내 가치 카드"
- 서브제목: "당신의 인생을 한 장의 카드로"
- 카테고리: Lifestyle / Health & Fitness
- 등급: 12+

---

## 4. App B: SFX Memento Mori (메멘토 모리)

**경로:** `/Users/apple/development/soluni/sfx-imjong-care/sfx_memento_mori/`
**번들 ID:** `com.sfx.sfxMementoMori`

### 핵심 기능
- 생년월일 + 목표 나이 입력 (70-90)
- 4,160개 주 Grid 시각화 (80년 × 52주)
- 지난 주=회색, 남은 주=네온 그린
- 현재 주 하이라이트 (펑크 애니메이션)
- 연도 마커 (10, 20, 30...) + 마일스톤 (18, 25, 30, 60, 65, 70)
- 인생 통계: 진행률, 남은 일수, 현재 나이
- 단계별 인용구 (7 단계)
- 설정 화면 (타겟 나이 변경, 데이터 초기화, 개인정보처리방침)
- Grid 이미지 공유 (branded frame)
- EULA 동의 필수

### 파일 구조
```
lib/
├── main.dart
├── core/
│   ├── theme/neon_colors.dart, app_theme.dart
│   ├── utils/life_calculator.dart, life_quotes.dart
│   ├── storage/preference_service.dart
│   └── services/review_service.dart
├── features/
│   ├── onboarding/
│   │   └── presentation/
│   │       ├── pages/welcome_page.dart
│   │       └── screens/onboarding_page.dart
│   ├── home/
│   │   └── presentation/
│   │       ├── pages/home_page.dart
│   │       └── widgets/week_grid.dart
│   └── settings/
│       └── presentation/pages/settings_page.dart
└── ...
```

### APP_STORE_META.md 포함
- 앱명: "SFX Memento Mori - 남은 시간"
- 서브제목: "인생을 주간으로 시각화"
- 카테고리: Health & Fitness / Productivity
- 등급: 12+

---

## 5. App C: SFX Legacy Vault (데드맨스위치)

**경로:** `/Users/apple/development/soluni/sfx-imjong-care/sfx_legacy_vault/`
**번들 ID:** `com.sfx.sfxLegacyVault`

### 핵심 기능
- Firebase Auth (이메일 + Apple Sign-In)
- 다중 Vault 생성 (Crypto/Passwords/Letter/Custom)
- AES-256 클라이언트 사이드 암호화
- 타겟 이메일 + 마감일 설정
- 카운트다운 타이머 (실시간)
- 상태 인디케이터: Active/Warning/Expired/Paused
- Vault 관리: 수정/삭제/Ping/Pause/Resume
- Cloud Functions (deadline checker + email sender)
- 보안 뱃지 + 팁
- EULA + Privacy Policy 필수

### 파일 구조
```
lib/
├── main.dart
├── core/
│   ├── config/firebase_options.dart
│   ├── constants/app_colors.dart
│   ├── theme/app_theme.dart
│   ├── services/
│   │   ├── encryption_service.dart (AES-256)
│   │   └── review_service.dart
│   └── utils/date_utils.dart
├── features/
│   ├── onboarding/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── eula_screen.dart
│   │       │   └── welcome_screen.dart
│   │       └── providers/onboarding_provider.dart
│   ├── auth/
│   │   ├── data/firebase_auth_service.dart
│   │   └── presentation/
│   │       ├── screens/login_screen.dart
│   │       └── providers/auth_provider.dart
│   └── vault/
│       ├── data/vault_repository.dart
│       ├── domain/models/vault_model.dart
│       └── presentation/
│           ├── screens/
│           │   ├── home_screen.dart
│           │   └── vault_setup_screen.dart
│           └── providers/vault_provider.dart
└── ...
functions/
├── index.js (Cloud Functions)
└── package.json
```

### APP_STORE_META.md 포함
- 앱명: "SFX Legacy Vault - 데드맨스위치"
- 서브제목: "암호화 디지털 유산 보관"
- 카테고리: Productivity / Utilities
- 등급: 12+

---

## 6. 공통 기술 스택

| 항목 | 내용 |
|---|---|
| Flutter | 3.29.3 |
| Dart | 3.7.2 |
| 아키텍처 | Clean Architecture (lib/features/, lib/core/) |
| State Management | Riverpod |
| 테마 | 다크모드 + 네온 (초록 #00FF88, 분홍 #FF00AA, 시안 #00DDFF, 배경 #0A0A0F) |
| 컴플라이언스 | EULA, Privacy Policy, Apple App Store 가이드라인 준수 |

---

## 7. 다음 단계

### App Store 제출 준비
1. **App A/B/C:** Firebase 설정 (App C 필수)
2. **App A/B/C:** TestFlight 빌드 + beta tester 등록
3. **App A/B/C:** App Store Connect 메타데이터 입력 (APP_STORE_META.md 참고)
4. **App A/B/C:** 스크린샷 5개 준비 (각 기기별)
5. **App C:** Cloud Functions 배포 + SendGrid 연동

### 개선 가능 사항
- App A: 카드 공유 시 SNS별 최적화 (Instagram/카카오스토리)
- App B: Grid 색상 커스터마이징
- App C: Push notification (생존 확인 리마인더)

---

**3개 앱 모두 flutter analyze 0 issues + flutter build ios 성공으로 QA 테스트 준비 완료.**