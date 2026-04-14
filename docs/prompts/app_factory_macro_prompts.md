# Solve-for-X : App Factory 매크로 프롬프트 카탈로그

지훈님(설계자)이 퇴근 후 로컬 데스크탑의 **Gemma 31B (OpenCode)** 환경에 복사/붙여넣기 하여 앱을 통째로 찍어내기 위한 매크로 스케일(Macro-Scale) 작업 지시서 모음입니다.

---

## 1️⃣ [App 1-FE V2] SFX Life-Log (프리미엄 UI & 크로스플랫폼 센서)

**목표:** 단순한 기능 구현을 넘어, 브랜딩에 걸맞는 '프리미엄 다크테마 UI'와 웹(Chrome) 브라우저 테스트 환경에서도 뻗지 않는 '플랫폼 방어 로직'이 탑재된 완전체 클라이언트를 단숨에 찍어냅니다.

```text
@workspace 당신은 구글 출신의 수석 Flutter UI/UX 디자이너이자 SRE 엔지니어입니다. `apps/life_log_v2_premium` 폴더에 'SFX Life-Log' 앱 디자인과 아키텍처를 단숨에 구현합니다. 절대 촌스러운 기본 테마를 쓰지 마세요.

[기술 스택]
- 언어: Dart / Flutter
- 아키텍처: Clean Architecture (Data, Domain, Presentation)
- 라이브러리: Riverpod, Dio, health ^13.1.3, google_fonts

[구현 명세]
1. 완벽한 프리미엄 UI (Wow Effect):
- 기본 Material Blue 테마와 하얀 배경은 철저히 배제합니다.
- 다크 모드 기반의 우주/블랙톤 그라데이션, Glassmorphism(유리 질감) 카드 UI를 적용하세요.
- `google_fonts` 패키지를 연동하여 아주 세련된 현대적 폰트(Inter 등)를 화면 전반(버튼, 텍스트)에 적용하고, 동기화 시 미세한 애니메이션(로딩 프로그레스바 등)을 넣으세요.

2. Web/Android 크로스 플랫폼 방어 로직 (가장 중요):
- `health` 패키지는 안드로이드 전용이라 웹(Chrome)에서 호출 시 PlatformException으로 크래시가 납니다.
- `kIsWeb` 상수를 사용해서 "만약 웹 환경이면 health 플러그인 연동 코드를 우회하고 RANDOM 가짜 수면 데이터(예: 93점)를 강제로 리턴"하는 방어 로직을 `HealthRepository`에 반드시 넣으세요. 그래야 PC 환경 검증이 가능합니다.

3. 데이터 및 네트워크 레이어:
- Dio를 사용해 `http://192.168.45.61:8080/api/health/sleep` 로 데이터를 POST 쏘는 로직을 구현합니다.
- 데이터 전송 중일 때는 투명하고 아름다운 로딩 애니메이션이 화면을 덮도록 Riverpod을 갱신하세요.

명심하세요. 앱을 띄웠을 때 디자인 첫인상이 "최고급 시스템" 느낌이 나지 않는다면 실패한 프로젝트입니다. 제공된 VRAM 내에서 한 큐에 전체 폴더를 작성하고, pub get까지 구동하세요.
```

---

## 2️⃣ [App 2-FE] SFX Imjong Care (소셜 유서 & 버킷리스트)
*※ App 1 구축이 완료된 이후에 사용하세요.*

**목표:** MZ세대들에게 자신을 돌아보는 긍정적인 '소셜 유서' 작성 트렌드를 이끄는 앱 뷰 전체.

```text
@workspace 당신은 시니어 Flutter 아키텍트입니다. 지금부터 `apps/imjong_care_app` 폴더 내에 MZ세대 타겟의 긍정적 소셜 유언장 앱(App 2-FE)의 주요 화면 흐름 전체를 단숨에 구현합니다.

[기술 스택]
- 언어/프레임워크: Dart / Flutter
- 아키텍처: Clean Architecture 분리 상태
- 특징: 생체 인증 라이브러리 (local_auth) 적용

[구현 명세]
1. 인프라 및 인증:
- `local_auth` 패키지를 연동하여, 앱 실행 시 지문/페이스ID를 통과해야만 내 디지털 금고(메인 뷰)에 접근할 수 있게 구성하세요.

2. Presentation Layer (핵심 UI 뷰 기획):
- `MainVaultScreen`: 잠금이 풀렸을 때 메인 UI. 하단 탭으로 네비게이션을 구성하세요.
- `BucketListTab`: 죽기 전 꼭 이루고 싶은 긍정적 성취 리스트 UI (추가, 체크박스 기능).
- `DigitalMessageTab`: 나 스스로 또는 소중한 사람에게 한 줄씩 남기는 하루 회고/소셜 유서 카드 UI (카드 형태의 UI 컴포넌트로 세련되게 디자인).

기능 작동보다는 UI의 틀과 Clean Architecture 라우팅, 생체 인증 방어막 세팅에 집중해서 전체 덩어리 코드를 한 번에 짜주세요.
```

---

## 3️⃣ [App 3-FE] SFX Career Vault (범용 지식 퍼블리셔)
*※ 향후 확장을 대비한 프롬프트입니다.*

**목표:** 누구나 본인의 로컬 지식(Git 커밋, 메모 등)을 모아 여러 플랫폼으로 배포하는 통합 지식 브릿지 웹 대시보드.

```text
@workspace 당신은 시니어 프론트엔드 React 개발자입니다. `apps/career_vault_web` 폴더를 생성하고 범용 지식 퍼블리싱 브릿지용 대시보드 웹 뷰 전체를 작성하세요.

[기술 스택]
- Framework: Next.js (App Router), Tailwind CSS
- 상태/통신: swr 혹은 react-query

[구현 명세]
- 메인 대시보드에는 좌측에 '오늘 수집된 지식 조각(Raw Data)' 리스트 UI가 있어야 합니다.
- 우측에는 해당 Raw Data를 AI가 예쁘게 가공한 포스트 본문 에디터 뷰가 위치합니다.
- 하단에는 [Publish to Medium], [Publish to GitHub] 와 같은 플랫폼 배포 버튼들을 연동(UI)해 두세요.
- 모던하고 전문적인 SRE 대시보드 느낌의 다크모드 기반 레이아웃을 구현하세요.
```
