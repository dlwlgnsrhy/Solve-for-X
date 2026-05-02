# Project: Legacy Vault iOS Native App

> **Vision**: "Google은 당신의 데이터를 학습하지만, Legacy Vault는 당신의 존엄을 보호합니다. 우리는 당신의 목소리를 듣지만, 결코 엿듣지 않습니다."
> **Source Spec**: `CORE/projects/legacy_vault.md`
> **App Name**: Legacy Vault
> **Package**: `com.sfx.legacyvault`
> **Framework**: SwiftUI + Native iOS (Swift 6)
> **Architecture**: Clean Architecture (Feature-first, MVVM)
> **Storage**: SQLite + sqlite-vec (Local RAG)
> **Backend**: **None — 100% on-device** (Firebase/Firestore ABANDONED)
> **Theme**: Dark mode (`#0A0A0F`) with Neon green accents (`#00FF88`)
> **Min iOS**: iOS 17.0 (iPhone 14+)

---

## TL;DR

> sfx_legacy_vault_v1 (Flutter + Firebase) 의 핵심 기능(데드맨스위치 + AES-256 암호화)은 유지하되, Legacy Vault spec의 4대 핵심 기능(온디바이스 STT, 로컬 LLM, 벡터 RAG, 디지털 페르소나)을 완전 새로 구현. Firebase/Firestore/Cloud Functions 모두 제거 → 100% on-device. Deliverables: 새 SwiftUI 프로젝트 1개 + 4개 주요 기능 + 40+ Swift 파일.
> **Effort**: Large (8 phases, 3 parallelizable) | **Timeline**: ~4-6주

---

## 1. 기존 vs 신규 아키텍처

| 영역 | 기존 (sfx_legacy_vault_v1) | 신규 (Legacy Vault iOS) |
|------|---------------------------|------------------------|
| 언어/프레임워크 | Flutter (Dart) | **Swift 6 + SwiftUI** |
| 인증 | Firebase Auth | **Apple Sign-In + Keychain** |
| 스토리지 | Firestore (cloud) | **SQLite + sqlite-vec** (local only) |
| 암호화 | AES-256-CBC (encrypt.dart) | **AES-256-GCM (CryptoKit)** |
| STT | 없음 | **SpeechAnalyzer (iOS 26+) / WhisperKit** |
| LLM | 없음 | **Foundation Models / mlx-swift-lm** |
| 벡터 검색 | 없음 | **sqlite-vec** (KNN exact search) |
| 백그라운드 | Firestore Stream | **Local Notification + Background Task** |
| 백업 | 없음 | **iCloud KeyChain (encrypted)** |
| 클라우드 의존 | 전체 | **제로** |

---

## 2. 핵심 기능 정의 (spec 기반)

### Feature 1: AI 지능형 라이프 로깅 (Soul-Mining)
- **음성 일기**: 사용자가 말 → 기기 내 즉시 텍스트 변환 (서버 전송 없음)
- **맥락 감지 에이전트**: on-device LLM이 철학적 질문 → 기록 풍성화
- **개인화 학습**: Gemma-2b/Llama-3-8B quantized → 사용자 말투/가치관 학습

### Feature 2: 가치관 지도 (Value Mapping)
- **키워드 추출**: 기록에서 중요 키워드(가족, 도전, 평화 등) 자동 추출
- **인생 타임라인**: 텍스트+사진+감정 →的人生 서사(reconstructed)

### Feature 3: 가디언 프로토콜 (Inheritance & Security)
- **Dead Man's Switch**: 일정 기간 미접속 시 지정된 상속인에게 데이터 접근 권한 이양 또는 영구 삭제
- **Zero-Knowledge Backup**: Keychain 키로 이중 암호화 → iCloud/Drive backup

### Feature 4: 디지털 페르소나 엔진 (Legacy Agent)
- **미래를 위한 대화**: 후손이 앱 켜면, 사용자의 가치관 학습한 AI가 사용자의 목소리로 답변
- **순수 로컬**: 외부 서버 없이 기기 안에서만 존재

---

## 3. Tech Stack

| 영역 | 라이브러리 | 용도 | 대안 |
|------|-----------|------|------|
| STT/Speech | `SpeechAnalyzer` (iOS 26+) | on-device 음성인식 | `WhisperKit` (iOS 17+) |
| LLM Inference | `FoundationModels` (iOS 26+) | on-device LLM Chat | `mlx-swift-lm` |
| Vector Search | `sqlite-vec` | local RAG (KNN Exact) | `sqlite-vector` (HNSW) |
| Embedding | `swift-embeddings` (MLX) | 텍스트 임베딩 (Nomic Text v1.5, 768d) | CoreML `all-MiniLM-L6-v2` |
| Encryption | `CryptoKit` (AES-GCM) | AES-256-GCM | 기존 encrypt 패턴 유지 |
| Keychain | `KeychainAccess` | 키 관리 | `SecItemAdd` 직접 |
| Recording | `AVFoundation` | 오디오 녹음 | `AUAudioTapConsumer` |
| Notifications | `UserNotifications` | 데드맨스위치 알림 | `BackgroundTasks` |

---

## 4. 폴더 구조

```
apps/legacy_vault/
├── Package.swift                          # swift-vec, WhisperKit, swift-embeddings
├── legacy_vault.xcodeproj/                # Xcode project
├── legacy_vault/
│   ├── AppDelegate.swift                  # Keychain + Core Data + UNUserNotificationCenter
│   ├── SceneDelegate.swift
│   ├── Info.plist                         # Mic, Speech Recognition, HealthKit, etc.
│   │
│   ├── App/
│   │   ├── LegacyVaultApp.swift           # @main
│   │   └── AppRouter.swift                # NavigationPath routing
│   │
│   ├── Core/
│   │   ├── Theme/                         # Dark mode (#0A0A0F), Neon Green (#00FF88)
│   │   ├── Services/
│   │   │   ├── EncryptionService.swift    # CryptoKit AES-GCM + Keychain
│   │   │   ├── STTService.swift           # SpeechAnalyzer/WhisperKit wrapper
│   │   │   ├── LocalLLMService.swift      # FoundationModels/mlx-swift-lm wrapper
│   │   │   ├── EmbeddingService.swift      # swift-embeddings/MLX
│   │   │   ├── VectorDBService.swift       # sqlite-vec operations
│   │   │   ├── DeadManSwitchService.swift  # Background task + notifications
│   │   │   ├── iCloudBackupService.swift   # CloudKit encrypted backup
│   │   │   └── AppLifecycleService.swift   # App lifecycle tracking
│   │   ├── Database/
│   │   │   ├── DatabaseManager.swift       # Core Data stack + sqlite-vec init
│   │   │   ├── MigrationManager.swift
│   │   │   └── Schema.swift
│   │   ├── Models/                        # Value objects (VoiceLogEntry, VaultRecord, etc.)
│   │   └── Utilities/                     # KeychainHelper, DateFormatters, AudioPlayer
│   │
│   ├── Features/
│   │   ├── onboarding/                    # Welcome, Privacy Policy, First Launch
│   │   ├── auth/                          # Apple Sign-In, FaceID, Passphrase Setup
│   │   ├── soul_mining/                   # Feature 1: Voice diary + AI enrichment
│   │   │   ├── presentation/              # SoulMiningHomeView, RecordingView, AIContextView...
│   │   │   ├── domain/                    # RecordingSession, Transcript, AIEnrichment
│   │   │   └── infrastructure/            # STTCoordinator, AIPromptGenerator, EnrichmentEngine
│   │   ├── value_mapping/                 # Feature 2: Keyword cloud, Timeline
│   │   │   ├── presentation/              # ValueMapView, KeywordCloudView, TimelineCellView...
│   │   │   ├── domain/                    # KeywordGroup, LifeEvent
│   │   │   └── infrastructure/            # KeywordExtractor, ValueAnalyzer, TimelineBuilder
│   │   ├── guardian/                      # Feature 3: Dead Man's Switch, Vault, Backup
│   │   │   ├── presentation/              # GuardianDashboardView, DeadManSwitchSetupView...
│   │   │   ├── domain/                    # DeadManSwitchConfig, InheritanceContact, BackupState
│   │   │   └── infrastructure/            # DeadManSwitchEngine, LocalNotificationHandler...
│   │   ├── legacy_agent/                  # Feature 4: Chat with persona (RAG)
│   │   │   ├── presentation/              # LegacyAgentView, PersonaConfigView...
│   │   │   ├── domain/                    # ChatMessage, PersonaProfile, LegacyKnowledgeBase
│   │   │   └── infrastructure/            # PersonaChatService, RAGRetriever, KnowledgeIndexer
│   │   └── home/                          # NavigationTabView, HomeDashboardView
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets/               # AppIcon, splash_logo
│   │   ├── Localization/                  # ko.lproj, en.lproj, ja.lproj, zh.lproj
│   │   └── PrivacyInfo.xcprivacy
│   └── Tests/
│       ├── Unit/                          # EncryptionServiceTests, STTServiceTests, etc.
│       └── Integration/                   # RecordingFlowTests, VaultCRUDTests
```

---

## 5. DB 스키마 (Core Data + sqlite-vec)

### Core Data Entities

| Entity | Fields |
|--------|--------|
| `VoiceLogEntry` | id(UUID), title, recordingDate, transcript, aiSummary, aiEnrichment, sentiment(-100~+100), duration(ms), keywords(JSON), audioURL |
| `VaultRecord` | id(UUID), name, vaultType(letter/passwords/crypto/legal/custom), encryptedData(Base64), salt(Data), lastPingDate, deadlineDays, targetEmails(JSON), status(active/paused/expired/alert_sent) |
| `InheritanceContact` | id(UUID), name, email, relationship(spouse/child/friend/org), notificationStatus(0-3) |
| `ChatMessage` | id(UUID), role(user/assistant), content, timestamp, embeddingId(UUID) |
| `ValueKeyword` | id(UUID), word, frequency, firstOccurrence, lastOccurrence, associatedValues(JSON), category(family/career/emotion) |

### sqlite-vec Virtual Tables

```sql
-- recording_vectors: Voice log embeddings
CREATE VIRTUAL TABLE recording_vectors USING vec0(embedding float[768]);

-- chat_vectors: Legacy agent conversation embeddings
CREATE VIRTUAL TABLE chat_vectors USING vec0(embedding float[768]);

-- keyword_vectors: Keyword cloud embeddings
CREATE VIRTUAL TABLE keyword_vectors USING vec0(embedding float[768]);
```

### Embedding Pipeline
1. Input: VoiceLogEntry.transcript
2. Clean text (strip punctuation, normalize Korean)
3. Generate embedding via `swift-embeddings` (Nomic Text v1.5, 768d)
4. Store in Core Data VoiceLogEntry + recording_vectors
5. Extract keywords via co-occurrence graph → ValueKeyword
6. Done.

---

## 6. Implementation Phases

### Phase 1: Project Init + Core Infra (1 week)
- Swift Xcode project creation
- Custom AppDelegate → Keychain + Core Data + UNUserNotificationCenter
- Theme: #0A0A0F + #00FF88
- **Services**: EncryptionService, STTService, LocalLLMService, EmbeddingService
- **Database**: DatabaseManager, sqlite-vec init
- **Blocks**: P2-P6 | **Parallel**: None

### Phase 2: Feature 1 — Soul-Mining (1 week)
- VoiceRecordingView + pulsing mic FAB + waveform
- STT real-time transcription
- AIContextView: on-device LLM follow-up questions
- SessionSummaryView: emotion analysis + keyword extraction
- **Parallel**: With P3 | **Blocks**: P6 (Value Mapping)

### Phase 3: Feature 3 — Guardian Protocol (1 week)
- DeadManSwitchService: background task + countdown
- DeadManSwitchSetupView: deadline, heirs, actions
- LocalNotificationHandler: 7d → 3d → 1d → deadline → send
- SecureVaultRepository: encrypted vault CRUD
- iCloudBackupCoordinator: zero-knowledge encrypted backup
- **Parallel**: With P2 | **Blocks**: None

### Phase 4: Feature 2 — Value Mapping (1 week)
- VoiceLogEntry list timeline
- KeywordExtractor: co-occurrence graph from transcripts
- ValueAnalyzer: frequency + sentiment analysis
- KeywordCloudView: interactive keyword cloud
- Timeline canvas: text + emotion + keyword visualization
- **Parallel**: With P5 | **Blocks**: None

### Phase 5: Feature 4 — Legacy Agent (1 week)
- RAGRetriever: sqlite-vec retrieval → augment LLM context
- PersonaChatService: chat with on-device LLM (RAG-augmented)
- PersonaPromptBuilder: system prompt construction from recorded data
- KnowledgeIndexer: index all recordings into persona KB
- **Parallel**: With P4 | **Blocks**: None

### Phase 6: Auth + Onboarding + Data Migration (0.5 week)
- Apple Sign-In + FaceID
- Onboarding: Welcome → Privacy → Keychain Init → First Voice Log
- Migrate sfx_legacy_vault_v1 Firestore data → local SQLite (if exists)

### Phase 7: Tests + App Store Prep (0.5 week)
- Unit tests: all pure functions, Privacy test (NO `networking` imports)
- Integration: End-to-end recording → transcription → embedding → retrieval
- App Store metadata (Korean primary, 4 languages)
- Fastlane CI: TestFlight build + deployment

---

## 7. TODOs

---

### P1: 프로젝트 초기화 & Xcode 프로젝트 생성

**What to do**:
1. `mkdir -p apps/legacy_vault/`
2. Xcode 프로젝트 생성 (SwiftUI, Swift 6) 또는 `xcodegen` 템플릿 활용
3. 기본 파일 구조 생성 (모든 디렉토리 비어있는 상태)
4. `Package.swift` 생성 (sqlite-vec, WhisperKit, swift-embeddings, MLX)
5. `Info.plist` 기본 설정 + Privacy Manifest
6. 앱 아이콘 + 스플래시 aset 설정

**Must NOT do**: Firebase 관련 코드가 절대 포함되지 않도록. 기존 `sfx_legacy_vault_v1/` 절대 건드리지 않음.

**Parallel**: NO | Blocks: P2-P6 | BlockedBy: None

**Acceptance Criteria**:
- [ ] `apps/legacy_vault/` 폴더 구조 생성 완료
- [ ] XcodeProj 생성됨
- [ ] Package.swift에 sqlite-vec, WhisperKit, swift-embeddings 선언
- [ ] 앱 빌드 성공 (빌드 에러 0건)

---

### P2: Core/Services — 암호화, STT, LLM, 벡터 DB, 백그라운드

**What to do** (9 files):

| 파일 | 설명 |
|------|------|
| `EncryptionService.swift` | CryptoKit AES-GCM, PBKDF2 키 도출, Keychain 바인딩 |
| `STTService.swift` | SpeechAnalyzer wrapper (iOS 26) + WhisperKit fallback (iOS 17) |
| `LocalLLMService.swift` | FoundationModels wrapper (iOS 26) + mlx-swift-lm fallback |
| `EmbeddingService.swift` | swift-embeddings + MLX, Nomic Text v1.5 |
| `VectorDBService.swift` | sqlite-vec wrapper: insert, search, delete, count |
| `DeadManSwitchService.swift` | BackgroundTask, UNUserNotificationCenter, 상태 전환 |
| `iCloudBackupService.swift` | CloudKit, 암호화된 백업/리스트ores |
| `AppLifecycleService.swift` | App lifecycle tracking, heartbeating |
| `KeychainHelper.swift` | Keychain 읽기/쓰기 (Secure Enclave) |

**Must NOT do**: 외부 네트워크 호출 (URLSession 사용 금지). 모든 API는 on-device만.

**Parallel**: NO | Blocks: Phase 2-6 UI | BlockedBy: P1

**Acceptance Criteria**:
- [ ] `EncryptionService.encrypt()`/`decrypt()` 테스트 통과
- [ ] `STTService.startTranscription()` → STTDelegate 콜백 확인
- [ ] `VectorDBService.queryNearest()` → 벡터 유사도 검색 확인
- [ ] `LocalLLMService.generate()` → on-device 응답 확인

---

### P3: Core/Database — Core Data + sqlite-vec 스키마

**What to do** (3 files):
- `DatabaseManager.swift`: NSPersistentContainer, Core Data stack, sqlite-vec extension init
- `MigrationManager.swift`: schema migrations
- `Schema.swift`: 모든 Core Data entity 정의

sqlite-vec virtual table 생성:
```
recording_vectors (float[768])
chat_vectors (float[768])
keyword_vectors (float[768])
```

Core Data + sqlite-vec bridge (NSManagedObject ↔ vec0 테이블 연동)

**Must NOT do**: 외부 DB 의존성. 반드시 로컬 SQLite + sqlite-vec 사용.

**Parallel**: NO | Blocks: Phase 2-6 | BlockedBy: P2

**Acceptance Criteria**:
- [ ] `DatabaseManager.managedObjectContext` 접근 가능
- [ ] sqlite-vec virtual tables 생성 확인
- [ ] Core Data entity 6개 모두 등록됨
- [ ] `fetchWithSimilarity()` → 벡터 검색 반환

---

### P4: Feature 1 — Soul-Mining (AI 지능형 라이프 로깅)

**What to do** (10 files):

| 파일 | 설명 |
|------|------|
| `SoulMiningHomeView.swift` | 녹음 리스트 + pulsing mic FAB |
| `VoiceRecordingButton.swift` | Pulsing glow FAB, tap-to-record |
| `RecordingView.swift` | Active recording UI, waveform, live transcript |
| `RecordingPlayerView.swift` | Playback + transcript display + highlight |
| `AIContextView.swift` | AI-generated follow-up questions |
| `SessionSummaryView.swift` | Post-recording summary, emotion, keywords |
| `STTCoordinator.swift` | SpeechAnalyzer ↔ WhisperKit dispatch |
| `AIPromptGenerator.swift` | On-device LLM prompt construction |
| `EnrichmentEngine.swift` | Context detection + question generation |
| `RecordingSessionStore.swift` | NSManagedObjectStore CRUD for VoiceLogEntry |

**Must NOT do**: Voice recording 시 서버 전송 금지. LLM prompt 생성 시 데이터 외부 전송 금지.

**Parallel**: With P5 | Blocks: P6 (Value Mapping) | BlockedBy: P2, P3

**Acceptance Criteria**:
- [ ] Mic tap → recording 시작 → waveform visualization
- [ ] Release → transcription live display
- [ ] AI prompt button → LLM generates contextual question
- [ ] Summary: emotion, keywords extracted and displayed

---

### P5: Feature 3 — Guardian Protocol (가디언 프로토콜)

**What to do** (9 files):

| 파일 | 설명 |
|------|------|
| `GuardianDashboardView.swift` | 데드맨스위치 상태 대시보드 |
| `DeadManSwitchSetupView.swift` | 데드라인, 상속인, 액션 설정 |
| `HeirListManagerView.swift` | 상속인 추가/수정/삭제 |
| `BackupStatusView.swift` | Zero-knowledge 백업 상태 표시 |
| `VaultDecryptionView.swift` | FaceID + passphrase로 Vault decryption |
| `DeadManSwitchEngine.swift` | Background task monitoring |
| `LocalNotificationHandler.swift` | 경고 알림 (7→3→1→데드라인→전송) |
| `SecureVaultRepository.swift` | AES-GCM Vault CRUD |
| `iCloudBackupCoordinator.swift` | CloudKit encrypted backup |

**Must NOT do**: 백업 시 원본 데이터 네트워크 전송 금지. 반드시 로컬 암호화 후 CloudKit upload.

**Parallel**: With P4 | Blocks: None | BlockedBy: P2, P3

**Acceptance Criteria**:
- [ ] Vault 생성 → 암호화 → 로컬 저장 → 복호화 확인
- [ ] 데드맨스위치 설정 → Background task 등록 → Heartbeat tracking
- [ ] 알림: 7일 → 3일 → 1일 → 데드라인 도달 순서 전송
- [ ] iCloud 백업 → 복호화 시 passphrase 필요

---

### P6: Feature 4 — Legacy Agent + Feature 2 — Value Mapping

**What to do** (17 files):

**Legacy Agent** (7):
| 파일 | 설명 |
|------|------|
| `LegacyAgentView.swift` | 메시지 채팅 UI |
| `ConversationThreadView.swift` | conversation thread + scroll |
| `PersonaConfigView.swift` | 페르소나 설정 (목소리, 스타일) |
| `PersonaChatService.swift` | RAG-augmented chat with LLM |
| `RAGRetriever.swift` | sqlite-vec retrieval → augment context |
| `PersonaPromptBuilder.swift` | System prompt construction |
| `KnowledgeIndexer.swift` | Index recordings → knowledge KB |

**Value Mapping** (7):
| 파일 | 설명 |
|------|------|
| `ValueMapView.swift` | Timeline canvas |
| `KeywordCloudView.swift` | Interactive keyword cloud |
| `TimelineCellView.swift` | Single timeline entry card |
| `ValueInsightView.swift` | "최근 3개월 감정 변화" insights |
| `KeywordExtractor.swift` | Co-occurrence graph |
| `ValueAnalyzer.swift` | Frequency + sentiment analysis |
| `TimelineBuilder.swift` | Narrative construction |

**Must NOT do**: 페르소나 채팅 시 외부 서버 호출 금지. 모든 LLM 추론 on-device.

**Parallel**: With P4-P5 | Blocks: None | BlockedBy: P2, P3, P4

**Acceptance Criteria**:
- [ ] Legacy Agent chat → RAG context retrieved → LLM generates persona-consistent response
- [ ] Knowledge Base indexing → 10개 녹음 → 검색 정확도 확인
- [ ] Value Map → 전체 녹음 기록에서 키워드 클라우드 생성
- [ ] Timeline → 시간순 서사 시각화

---

### P7: 인증 + 온보딩 + 데이터 마이그레이션

**What to do** (4 files):
- `AppleSignInProvider.swift`: Apple Sign-In flow
- `FaceIDView.swift`: FaceID로 인증
- `PassphraseSetupView.swift`: 새 사용자 passphrase 생성
- `OnboardingFlow.swift`: Welcome → Privacy → Keychain Init → First Voice Log
- Data migration: sfx_legacy_vault_v1 Firestore data → local SQLite (if exists)

**Must NOT do**: 이메일/비밀번호 조합 로그인 금지 (Apple Sign-In만). Firebase 직접 호출 금지.

**Parallel**: NO | Blocks: None | BlockedBy: P2, P4, P5

**Acceptance Criteria**:
- [ ] Apple Sign-In → FaceID 또는 passphrase 잠금
- [ ] 온보딩 플로우 100% 완료
- [ ] 첫 녹음 → 전체 pipeline: STT → Embedding → VectorDB 저장 → Keyword 추출
- [ ] 데이터 마이그레이션 확인 (기존 Vault 데이터 존재 시)

---

### P8: 테스트 + App Store 준비

**What to do**:
- **Unit tests**: 모든 pure functions (Encryption, STT dispatch, Vector search, Keyword extraction, LLM prompt building)
- **Privacy test**: `NoNetworkDependenciesTests.swift` — Network 또는 URLSession import 확인 시 테스트 실패
- **Integration tests**: End-to-end recording → transcription → embedding → retrieval
- App Store metadata (Korean primary, 4 languages)
- Fastlane CI: TestFlight build + deployment
- Performance profiling: LLM inference latency, STT accuracy, memory usage

**Acceptance Criteria**:
- [ ] flutter analyze → 에러 0건 (SwiftLint)
- [ ] Unit tests → 100% pass
- [ ] Integration tests → recording flow 성공
- [ ] Privacy test → PASS (no URLSession imports)
- [ ] Fastlane → TestFlight build 성공

---

## Commit Strategy
P1: git init + 첫 커밋 (프로젝트 scaffold)
P2-P7: 각 파일 단위/기능 단위 커밋
P8: 전체 검증 완료 커밋

## Success Criteria
1. 빌드 에러 0건
2. 앱 실행 시 Onboarding 표시
3. Onboarding 완료 → Soul-Mining home 화면 표시
4. Mic tap → Recording → Transcription → AI Summary flow 100% on-device
5. 데드맨스위치 설정 → Background task → 알림 발송
6. Legacy Agent 채팅 → RAG context retrieved → LLM from-device response
7. Privacy test → PASS (no network calls)
