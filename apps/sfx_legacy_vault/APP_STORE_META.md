# SFX Legacy Vault - App Store Metadata

## App Information

| Field | Value |
|-------|-------|
| **App Title** | SFX Legacy Vault - 데드맨스위치 |
| **Subtitle** | 암호화 디지털 유산 보관 |
| **Category** | Productivity / Utilities |
| **Rating** | 12+ |
| **Version** | 1.0.0 |
| **Bundle ID** | com.sfxvault.legacypreserve |

---

## Keywords

데드맨스위치, 유산, 암호화, 보안, 편지, 자동발송, 디지털유산, deadmanswitch, vault, encryption, legacy, digital inheritance, AES-256, privacy, zeroknowledge

---

## App Description (Korean)

### SFX Legacy Vault - 당신의 디지털 유산을 안전하게 보관하세요

SFX Legacy Vault는 "데드맨스위치(Dead Man's Switch)" 기술을 활용하여 당신의 중요한 디지털 정보를 안전하게 보관하고, 필요할 때 신뢰하는 사람에게 자동으로 전달하는 앱입니다.

---

### 주요 기능

🔐 **암호화된 디지털 금고**
- AES-256 군사급 암호화로 데이터를 보호합니다
- 암호화 키는 오직 당신의 기기에서만 보관됩니다
- 서버에서는 복호화가 절대 불가능합니다

⏰ **자동 발송 데드맨스위치**
- 정해진 기간 동안 앱에 접속하지 않으면 자동으로 데이터가 발송됩니다
- 정기적인 Ping(생체확인)으로 발송을 지연시킬 수 있습니다
- 여러 금고를 동시에 관리할 수 있습니다

📧 **신뢰받는 수취인에게만 전달**
- 미리 지정된 이메일 주소로 암호화된 데이터를 발송합니다
- 발송 후 모든 데이터는 서버에서 영구적으로 삭제됩니다

🛡️ **다양한 금고 유형**
- 암호화폐 지갑 정보
- 비밀번호 및 보안 키
- 개인 편지 및 마지막 메시지
- 법적 문서 및 계약서
- 맞춤형 금고

---

### 보안 아키텍처

🔒 **Zero-Knowledge 설계**
- SFX Legacy Vault 서버는 귀하의 데이터 내용을 알 수 없습니다
- 모든 암호화/복호화 작업이 기기 내에서만 수행됩니다
- 암호화 키는 절대 서버로 전송되지 않습니다

🔑 **AES-256 클라이언트 측 암호화**
- 군사급 AES-256 CBC 모드를 사용하여 데이터를 암호화합니다
- 고유한 솔트와 IV(초기화 벡터)를 사용하여 각 암호화 작업이 고유합니다
- 강력한 패스프레이즈(암호문구) 생성기를 제공합니다

🗑️ **자동 삭제 정책**
- 데이터가 수취인에게 성공적으로 전달되면 서버에서 즉시 삭제됩니다
- 삭제된 데이터는 복구할 수 없습니다
- 사용자도 언제든지 금고를 삭제할 수 있습니다

---

### 프라이버시 정책

**SFX Legacy Vault는 귀하의 프라이버시를 최우선으로 생각합니다.**

#### 수집하는 정보
- 이메일 주소 (인증 목적만 사용)
- 암호화된 데이터 블록 (내용을 읽을 수 없음)
- 마지막 활성 타임스탬프 (제한 기간 모니터링용)
- 대상 수신인 이메일 (전달 목적만 사용)

#### 정보 사용 방법
- 데드맨스위치 기능 제공을 위해
- 제한 기간을 놓친 경우 암호화된 데이터 전달을 위해
- 서비스 보안 유지 및 오용 방지를 위해

#### 데이터 보안
- 모든 금고 데이터는 서버 저장 전에 AES-256으로 암호화됩니다
- 암호화 키는 절대 귀하의 기기에서 벗어나지 않습니다
- Firebase 보안 규칙으로 저장 데이터 보호
- 전달 완료 후 데이터 즉시 삭제

#### 제3자 서비스
- Firebase (인증, 데이터베이스)
- Apple Sign-In (선택 시)
- SendGrid/Nodemailer (Cloud Functions를 통한 이메일 발송)

#### 귀하의 권리
- 언제든지 데이터 삭제 요청
- 암호화된 데이터 내보내기
- 데이터 처리에 대한 동의 철회
- 계정 및 모든 데이터 완전 삭제

#### 연락처
프라이버시 문의: privacy@sfxvault.com

---

### 기술 사양

| 항목 | 세부사항 |
|------|----------|
| 플랫폼 | iOS |
| 최소 iOS 버전 | iOS 15.0+ |
| 프레임워크 | Flutter |
| 암호화 | AES-256-CBC |
| 아키텍처 | Zero-Knowledge, Client-Side Only |
| 백엔드 | Firebase (Auth, Firestore) |
| 이메일 발송 | Cloud Functions + SendGrid |

---

### 사주 스크린샷 안내

1. **웰컴 화면**: 보안 중심 랜딩 페이지 (군사급 AES-256 암호화, Zero-Knowledge, Client-Side Only, Auto-Delete 배지)
2. **EULA 화면**: 이용약관 및 개인정보처리방침
3. **로그인 화면**: 이메일/Apple Sign-In 로그인
4. **홈 화면**: 금고 대시보드 (카운트다운 타이머, 상태 뱃지, 마지막 Ping 타임스탬프)
5. **금고 설정 화면**: 5단계 설정 위자드 (금고 이름, 비밀 데이터, 수신인, 제한 기간, 암호화 키)
6. **보안 팁 화면**: 보안 인증 배지 및 보안 팁

---

### 마케터 노트

SFX Legacy Vault는 디지털 유산 보호를 위한 최초의 Zero-Knowledge 데드맨스위치 앱입니다. 군사급 암호화와 클라이언트 측 처리를 통해 사용자의 데이터 프라이버시를 최상으로 보장합니다. 보안과 신뢰를 최우선으로 하는 앱을 찾는 사용자들을 위한 최적의 선택입니다.

---

## App Store Review Notes

이 앱은 Zero-Knowledge 아키텍처를 사용합니다. 개발자/서버는 사용자의 암호화된 데이터에 접근할 수 없습니다. 데모 목적으로 다음을 사용할 수 있습니다:

- 데모 계정: demo@sfxvault.com / Demo1234!
- 테스트 vault 생성 시 임의의 passphrase가 자동 생성됩니다
- 모든 데이터는 기기 내에서 암호화되며 서버에는 암호화된 형태만 저장됩니다

---

## Screenshots Requirements

- iPhone 6.7" (1290x2796)
- iPhone 6.1" (1170x2532)
- iPad 10.9" (2048x2732) - if applicable
- iPad 12.9" (2732x2048) - if applicable

---

## Supported Languages

- 한국어 (Primary)
- English
- 日本語
- 中文

---

*Last updated: 2026-04-27*
