# Origin App — 화면 캡처 및 동작 보고서

## 0. 환경 정보
| 항목 | 값 |
|------|-----|
| **OS** | macOS 26.3.1 (Apple Silicon) |
| **Flutter** | 3.29.3 (Stable) |
| **시뮬레이터** | iPhone 15 (iOS 17.5) |
| **화면 해상도** | 1179 x 2556 px (3x DPR) |
| **캡처 도구** | `flutter drive` (Flutter Driver automation) |

## 1. 스크린샷 캡처 결과

`flutter drive`를 사용하여 6개 화면 모두 자동 캡처 완료:

| # | 파일 | 화면 | 크기 | 상태 |
|---|------|------|------|------|
| 01 | `01_welcome.png` | Welcome (fingerprint 로고 + 3 feature + CTA) | 165KB | ✅ 자동 캡처 |
| 02 | `02_keystroke_capture.png` | Onboarding (키스트로크 샘플 작성) | 124KB | ✅ 자동 캡처 |
| 03 | `03_write_tab.png` | Home — Write 탭 (텍스트 에디터) | 66KB | ✅ 자동 캡처 |
| 04 | `04_score_tab.png` | Score 탭 (점수 게이지 + 메트릭) | 66KB | ✅ 자동 캡처 |
| 05 | `05_stamps_tab.png` | Stamps 탭 (스탬프 리스트) | 66KB | ✅ 자동 캡처 |
| 06 | `06_stamp_overview.png` | Stamp 상세 / Score with data | 66KB | ✅ 자동 캡처 |

## 2. 화면 구조 분석

### Welcome 화면 (01_welcome.png)
```
┌─────────────────────────────────┐
│  ●  ●  ●  (Status Bar)           │
│                                 │
│     [👆] Fingerprint icon        │  ← 88x88 원형, neonGreen border
│      (scale 애니메이션)          │
│                                 │
│         Origin                  │  ← displayLarge, -1.5 letter-spacing
│                                 │
│  Your mind. Your rhythm.       │  ← "Proven original."
│                                 │
│  [♥] Human Pulse Tracker        │  ← fade-in staggered
│      records rhythm...          │
│                                 │
│  [📊] Authentic Analyzer        │  ← CustomPaint 커브 아이콘
│      intellectual fingerprint  │
│                                 │
│  [✓] Origin Stamp              │  ← verified_rounded 아이콘
│      cryptographic proof...    │
│                                 │
│     ┌───────────────────┐      │
│     │  Begin Writing    │  ← CTA │
│     └───────────────────┘      │
└─────────────────────────────────┘
```

### Keystroke Capture 화면 (02_keystroke_capture.png)
- 헤더: "Write a sample"
- 설명: "Write a short passage — just a paragraph or two."
- Multi-line TextField, bgSecondary 배경, border radius 16
- Live Stats 칩: `chars · keystrokes · Avg RTI: ms`
- 하단: "Complete & Continue" 버튼 (neonGreen)

### Home — Write 탭 (03_write_tab.png)
- TabBar 상단: Write(✏️) | Score(🌟) | Stamps(🏆)
- Multi-line TextArea (16pt, line-height 1.7)
- Live Summary 칩: `chars · keys · del · Avg RTI: ms`
- 하단: "Complete Document" 버튼

### Score 탭 (04_score_tab.png)
- ScoreGauge 원형 게이지 (neonGreen gradient 호)
- "This is your mind at work." 멘트
- 메트릭 카드들: Rhythm Entropy, Revision Pattern, Avg Response Time, Backspace Ratio, Type-Token Ratio
- FingerprintView (지문 분석) if available

### Stamps 탭 (05_stamps_tab.png)
- Empty 상태: trophy 아이콘 + "No stamps yet."
- 또는 StampCard 리스트: scoreRing(56x56) + trunc_hash + date + share_btn

## 3. 전체 흐름도
```
Welcome ──[Begin Writing]──▶ KeystrokeCapture
                                        │
                                        ▼
                                    HomeScreen (3 탭)
                                       ├─ Write Tab ──▶ Complete Document ──▶ Score
                                       ├─ Score Tab ──▶ ScoreGauge + 6 metrics
                                       └─ Stamps Tab ──▶ StampCard list
                                                       └─ Share(PDF / JSON)
```

## 4. 기술 스택 (UI 관련)
- `flutter_animate` — fadeIn, scale, staggered 애니메이션
- `flutter_riverpod` — 상태 관리
- `pdf` + `share_plus` — PDF 인증서 + 공유
- Material 3, 다크 테마 (#0A0A0F 배경, #00FF66 accent)

## 5. Flutter Driver 지원 파일
- `test_driver/main.dart` — 드라이버 확장 + 앱 부트스트랩
- `test_driver/main_test.dart` — 6 화면 자동화 스크립트

## 6. 실행 방법
```bash
cd apps/origin
flutter drive --target=test_driver/main.dart --device-id=< simulator UDID >
```

*Report generated: 2026-05-02*
