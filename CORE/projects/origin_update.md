# Origin Update: Phase 2 Implementation Plan (Option A - Sovereign Local)

> **상태**: 사용자 승인 완료 (Option A: 순수 로컬/앱 대 앱 검증)
> **핵심 가치**: 중앙 서버 없이 기기 내 암호화와 로컬 AI만으로 인간의 오리지널리티를 증명한다.

---

## 1. 개요 (Executive Summary)
현재 Origin 앱의 기술적 토대는 마련되었으나, 핵심 기능(로컬 LLM 분석)과 검증 기능(ZK 증명)이 누락되어 있습니다. 또한 치명적인 UUID 생생 버그를 포함하고 있습니다. 본 계획은 이를 수정하고, 중앙 백엔드 없이 **기기 간 신뢰(Peer-to-Peer Trust)**를 구축하는 '원칙 노선'을 구체화합니다.

---

## 2. Phase 1: 기반 안정화 (Foundations) - 즉시 실행

### 1-1. 치명적 버그 수정 (Critical Fix)
- **대상**: `lib/core/services/database_service.dart`, `lib/features/home/presentation/widgets/keystroke_write_page.dart`
- **내용**: `Random.secure()`를 사용하여 0으로 고정된 UUID 생성 로직을 실제 난수 기반 UUID로 교체.
- **목적**: 모든 데이터(세션, 스탬프)의 ID 충돌 방지 및 DB 무결성 확보.

### 1-2. 인간의 맥동(Pause) 기록 구현
- **대상**: `KeystrokeTracker`, `DatabaseService`, `KeystrokeWritePage`
- **내용**:
    - 2초 이상의 입력 중단을 'Pause' 이벤트로 정의하고 기록.
    - DB 마이그레이션 (Version 1 → 2): `keystroke_events` 테이블에 `is_pause`, `pause_duration` 컬럼 추가.
- **목적**: AI와 구별되는 인간만의 '고민의 흔적'을 정량화.

### 1-3. 데이터 정렬 및 시각화 개선
- **내용**: `getAllStamps()` 쿼리에 최신순 정렬 추가 및 Stamp 카드의 제목을 'Hash'에서 '날짜/시간'으로 변경하여 가독성 확보.

---

## 3. Phase 2: On-device Intelligence (Gemma Integration)

### 2-1. flutter_gemma 통합
- **모델**: Gemma-3 1B (MediaPipe .task format).
- **특징**: 2025년 최신 모델로, 모바일 기기(iOS Metal, Android GPU)에서 로컬 가속 지원.
- **기술 제약**: 앱 배포 시 모델을 포함하지 않고, 사용자 동의 하에 Wi-Fi에서 최초 1회 다운로드.

### 2-2. 사유 분석 로직 (Local LLM Style Score)
- **로직**: `0.6 * 통계 점수(엔트로피, 수정율 등) + 0.4 * LLM 문체 일치도`.
- **분석**: 작성된 텍스트를 로컬 LLM이 분석하여 사용자의 기존 문체(Baseline Fingerprint)와 얼마나 일치하는지 0~1 사이 점수 산출.

### 2-3. UI 구성
- **Model Setup Screen**: 모델 다운로드 및 준비 상태 관리.
- **Analyzer Dashboard**: 통계 데이터와 AI 분석 결과를 결합한 종합 시각화.

---

## 4. Phase 3: Sovereign Verification (Option A - Pure Local)

> **중앙 서버 없이 Stamp의 위조 여부를 검증하는 로컬 암호화 체계**

### 3-1. 기기 고유 서명 (Digital Signature)
- **Key Storage**: 앱 설치 시 기기에서 Ed25519(또는 RSA-2048) 키쌍을 생성하여 iOS Keychain / Android Keystore에 보안 저장.
- **Signing**: Stamp 생성 시 `(Content Hash + Score + Timestamp + Device ID)`를 개인키로 서명.

### 3-2. QR 기반 검증 (Verification Interface)
- **Generator**: 서명된 메타데이터와 공개키가 포함된 QR 코드를 Stamp 카드에 생성.
- **Scanner**: 검증자가 Origin 앱의 'Verify' 기능을 사용하여 작성자의 QR을 스캔.
- **Logic**:
    1. QR 데이터에서 공개키와 서명 추출.
    2. 공개키로 서명의 유효성 검증.
    3. 유효할 경우 "✅ Verified Original by Human" 메시지 출력.

### 3-3. 오프라인 증명서 (PDF Export)
- Stamp 카드 + QR 코드가 포함된 PDF 내보내기 구현.
- 원문 내용은 절대 포함하지 않아 개인정보(사유의 내용) 보호 유지.

---

## 5. 단계별 실행 로드맵 (Execution Roadmap)

| 단계 | 작업명 | 핵심 산출물 | 기간 |
| :--- | :--- | :--- | :--- |
| **Phase 1** | 기반 안정화 | UUID 수정, Pause 감지, DB 정렬 | 1주 |
| **Phase 2** | AI 통합 | flutter_gemma 서비스, 모델 다운로더, 문체 분석기 | 3주 |
| **Phase 3** | 로컬 검증 | Keychain 서명 로직, QR 생성/스캔, PDF 내보내기 | 2주 |

---

## 6. 개발 지침 (Guidelines)
- **No Internet**: 모든 분석 및 검증 로직은 에어플레인 모드에서 작동해야 함 (모델 다운로드 제외).
- **Privacy First**: 원시 데이터는 절대 밖으로 나가지 않으며, 공유 시에는 서명된 해시와 점수만 전달됨.
- **Sovereign Trust**: 신뢰의 주체는 서버가 아니라 사용자 기기의 암호화 키임.
