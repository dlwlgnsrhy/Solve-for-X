# Solve-for-X : App Factory 매크로 프롬프트 카탈로그

지훈님(설계자)이 퇴근 후 로컬 데스크탑의 **Gemma 31B (OpenCode)** 환경에 복사/붙여넣기 하여 앱을 통째로 찍어내기 위한 매크로 스케일(Macro-Scale) 작업 지시서 모음입니다.

---

## 1️⃣ [App 1-FE] SFX Life-Log (생체 수집 센서) 클라이언트

**목표:** 안드로이드 Health Connect API를 활용하여 수면 데이터를 Mac 서버로 동기화하는 Flutter 앱 프론트엔드 전체.

```text
@workspace 당신은 시니어 Flutter 아키텍트이자 10x 개발자입니다. 지금부터 `apps/life_log_app` 폴더(SFX Life-Log) 생성 및 클라이언트 파트 전체(App 1-FE)를 단숨에 구현합니다.

[기술 스택]
- 언어/프레임워크: Dart / Flutter
- 아키텍처: Clean Architecture (Data, Domain, Presentation)
- 주요 라이브러리: Riverpod (상태관리), Dio (네트워크 API 통신), health ^13.2.0 (안드로이드 수면 데이터 접근)

[구현 명세]
1. 인프라 및 권한:
- `pubspec.yaml` 파일에 라이브러리 의존성을 완벽하게 주입하세요.
- `android/app/src/main/AndroidManifest.xml`에 Health Connect 접근 권한(`READ_SLEEP_SESSIONS` 등 필요한 명세)과 인터넷 권한을 세팅하세요.
- Health Connect 팝업을 띄우기 위해 안드로이드의 `MainActivity.kt` 의 클래스 상속을 `FlutterFragmentActivity` 설정으로 변경하세요.

2. Data Layer:
- `HealthRepository` 클래스를 구현해 스마트폰 자체 로컬의 어제 수면 데이터를 가져오세요.
- `PlannerApiClient` 클래스를 구현해 Dio를 통해 `http://192.168.45.61:8080/api/health/sleep` 으로 `{"score": 93, "duration": "시간 분"}` 맵핑 데이터를 쏘는 POST 로직을 작성하세요.

3. Presentation Layer:
- `DashboardScreen`을 구현하고, 화면 중앙에 `[AI 플래너 동기화]` 커다란 물리적인 액션 버튼을 만드십시오.
- 상태관리는 Riverpod을 사용하여, 데이터를 가져오고 통신하는 로딩(Loading) 상태일 때는 UI에 CircularProgressIndicator를 보여주세요.

제공된 VRAM 한계 내에서 최대한 완성도 높게 위 도메인을 아우르는 파일들을 단 한 번의 턴출력(Generation)으로 작성하고, 필요한 명령(flutter pub get 등)을 구동하세요.
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
