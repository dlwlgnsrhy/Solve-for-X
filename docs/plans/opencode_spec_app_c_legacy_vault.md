# OpenCode App Spec: SFX Legacy Vault (App C - Dead Man's Switch)

## 1. Product Overview
- **Name:** SFX Legacy Vault (레거시 볼트 / 가제: 데드맨 스위치)
- **Concept:** 죽음이나 사고를 대비해 디지털 자산과 마지막 메시지를 안전하게 보관하고, 만약의 사태에 자동 전달하는 보안 앱.
- **Core Feature (MVP):** 
  - 앱에 암호(비밀번호, 시드 구문) 또는 텍스트 편지를 저장해 둡니다.
  - 앱이 주기적으로(예: 1주일에 한 번) "생존 확인" 알림을 보냅니다.
  - 사용자가 앱을 열어 확인 버튼을 누르지 않은 상태로 N주가 지나면(사망/사고로 간주), 지정된 이메일로 해당 정보가 자동 발송됩니다.

## 2. Past Trial & Error (Lessons Learned)
- **[Background Service & Permissions]:**
  - 앱이 꺼져 있어도 알림이 오거나 백그라운드에서 만료 여부를 체크해야 합니다. 과거 Android/iOS 권한 문제로 앱스토어 리젝 및 알림 실패를 겪었던 것을 기억해야 합니다.
  - 해결책: 백그라운드 로직에 의존하기보다는, **Firebase Cloud Functions (Cron Job)**를 활용하여 서버에서 유저의 '마지막 로그인 시간(Last Active)'을 체크하고 서버 주도로 알림(FCM)과 이메일을 발송하는 아키텍처로 설계하세요. 모바일 클라이언트는 단순히 서버를 찌르는(Ping) 역할만 하도록 구성하여 모바일 사이드의 에러 포인트를 줄입니다.
- **[Security & Privacy Policy]:**
  - 개인의 민감 정보(유서, 암호)를 다루므로, Firebase Firestore에 저장할 때 반드시 클라이언트 사이드 암호화(Client-Side Encryption)를 적용해야 합니다.
  - App Store 심사 시 Privacy Policy와 EULA가 완벽하게 준비되어 있어야 리젝을 면합니다.

## 3. Implementation Step-by-Step (For OpenCode)
1. **Step 1: Firebase Auth & Firestore Setup**
   - 사용자 인증 및 Firestore 스키마 설계 (`users` 컬렉션 안에 `lastActiveAt`, `targetEmail`, `encryptedData`, `deadlineDays` 필드 포함).
2. **Step 2: Client App (Ping & Save)**
   - 보안 데이터(텍스트)를 입력하고 타겟 이메일을 설정하는 UI.
   - 앱을 켤 때마다(생존 시) `lastActiveAt`을 현재 시간으로 업데이트하는 로직.
3. **Step 3: Serverless Backend (Cloud Functions)**
   - 매일 밤 자정에 도는 Cron Job을 작성하여, `lastActiveAt`에서 `deadlineDays`가 초과된 유저를 탐색.
   - 조건에 맞는 유저의 `encryptedData`를 복호화 링크와 함께 `targetEmail`로 전송(SendGrid 등 이메일 API 활용)하는 뼈대 작성.
