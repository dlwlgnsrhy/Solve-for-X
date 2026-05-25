# Privacy Rules — Legacy Vault (All 3 Platforms)

## 1. NO Network Imports
- **iOS**: `URLSession`, `Network` 프레임워크 import 금지
- **Android**: `OkHttp`, `Retrofit`, `java.net` import 금지
- **Web**: `fetch()`, `axios`, `XMLHttpRequest` 호출 금지
- **빌드 체크**: `grep -r "networking\|URLSession\|OkHttp\|fetch" --exclude="*.md" --exclude="*.yml" | wc -l` → 0

## 2. NO External SDK
- Firebase, Sentry, Mixpanel, Amplitude 등 외부 관찰 SDK 절대 포함 금지
- 광고 SDK, 분석 SDK 포함 금지

## 3. Local Only
- 모든 데이터(음성, 텍스트, 임베딩, 키) → 기기 저장소 ONLY
- Core Data / Room / IndexedDB 외의 클라우드 저장소 사용 금지
- iCloud Keychain / Android Keystore / Web Crypto → 기기 보안 스토어는 허용

## 4. Privacy Test
- CI pipeline에서 위 grep 명령 자동 실행
- 결과 0이 아니면 CI 실패
- `grep -r "urlSession\\|fetch\\|OkHttp" --include="*.{swift,kt,ts,tsx}" | wc -l` → 0

## 5. Airplane Mode
- 모든 4 대 기능(Soul Mining, Guardian, Value Mapping, Legacy Agent)이 비행기 모드에서 정상 작동
- 테스트: WiFi/Cellular OFF 상태에서 앱 실행 → 100% 기능 동작

## 6. Permission Declaration
- iOS: `NSMicrophoneUsageDescription` (음성 녹음 전용), `PrivacyInfo.xcprivacy` 필수
- Android: `RECORD_AUDIO` 권한, `AndroidManifest.xml`에 purpose 명시
- Web: MediaRecorder API 사용 시 `userMedia` prompt 표시
