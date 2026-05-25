# Project: Legacy Vault Multi-Target (iOS + Android + Web)

> **Source Spec**: `CORE/projects/legacy_vault.md`
> **Vision**: "Google은 당신의 데이터를 학습하지만, Legacy Vault는 당신의 존엄을 보호합니다. 우리는 당신의 목소리를 듣지만, 결코 엿듣지 않습니다."
> **Package**: `com.sfx.legacyvault.*` (platform-specific)
> **Theme**: Dark mode (`#0A0A0F`) + Neon green accents (`#00FF88`) + Glassmorphism
> **Core Principle**: **100% On-device — Zero external API calls.** 모든 기능은 비행기 모드에서 작동.

---

## TL;DR

Legacy Vault spec의 4대 핵심 기능을 iOS(SwiftUI), Android(Kotlin/Compose), Web(Next.js PWA) 3개 플랫폼에 동시 구현.
각 플랫폼은 독립적인 네이티브 빌드이지만 **공통 디자인 시스템**, **동일 DB 스키마**, **동일 암호화 프로토콜**을 공유.
Firebase/Cloud Functions 모두 제거 → 완전히 로컬 독립형 생태계.

**Effort**: Massive (3 플랫폼 × 8 phases = 24 sub-phases, 일부 병렬)
**Timeline**: ~8-12주
**Deliverables**: iOS SwiftUI 프로젝트 1개 + Android Native 프로젝트 1개 + Web PWA 프로젝트 1개

---

## 1. 아키텍처 개요

```
                    ┌─────────────────────────────────────┐
                    │       Legacy Vault Spec              │
                    │  (Privacy-first • On-device only)    │
                    └──────────────┬──────────────────────┘
                                   │
                    ┌──────────────┼──────────────────────┐
                    │            │                      │
              ┌─────┴─────┐ ┌───┴────┐ ┌──────────────┴──────────┐
              │  iOS      │ │ Android│ │    Web (PWA)            │
              │  SwiftUI  │ │Compose │ │  Next.js + IndexedDB    │
              │  Swift 6  │ │ Kotlin │ │  TypeScript + PWA       │
              └───────────┘ └────────┘ └─────────────────────────┘
                    │           │              │
              ┌─────┴───────────┴──────────────┴──────┐
              │         Shared Abstractions            │
              │  • DB Schema  • Crypto Protocol        │
              │  • Design System • Feature Spec        │
              │  • Privacy Rules • Data Models         │
              └───────────────────────────────────────┘
```

### 플랫폼별 선택 이유

| 플랫폼 | 프레임워크 | 선택 이유 |
|--------|-----------|-----------|
| **iOS** | SwiftUI + Swift 6 | Repo 내 기존 구현 존재, Apple 생태계 최적화 |
| **Android** | Jetpack Compose + Kotlin 2.x | 네이티브 성능, Android 14+ 최적화 |
| **Web** | Next.js 15 + IndexedDB + WebAssembly PWA | 브랜드 관현 홈페이지 연동, 오프라인에서도 동작하는 서비스워커 |

---

## 2. 플랫폼별 Tech Stack

### iOS (SwiftUI) — 이미 계획됨

| 영역 | 라이브러리 |
|------|-----------|
| STT | `SpeechAnalyzer` (iOS 26+) / `WhisperKit` (iOS 17+) |
| LLM | `FoundationModels` / `mlx-swift-lm` |
| Vector | `sqlite-vec` |
| Embedding | `swift-embeddings` (Nomic Text v1.5, 768d) |
| Crypto | `CryptoKit` (AES-GCM) |
| Storage | Core Data + SQLite |

### Android (Kotlin + Compose) — 신규 생성

| 영역 | 라이브러리 |
|------|-----------|
| DI/Koin | `Koin 4.x` |
| Jetpack | `Compose 2.x`, `ViewModel`, `Navigation Compose` |
| Storage | `Room` + `SQLDelight` (for sqlite-vec equivalent) |
| Vector DB | `sqlite-android` + custom vec0 bridge |
| STT/Speech | `SpeechRecognizer` (Android) / `WhisperAndroid` |
| LLM | `MLC Android` 또는 `llama.cpp Android NDK` |
| Embedding | ONNX Runtime Mobile + `all-MiniLM-L6-v2` |
| Crypto | `AndroidKeystore` + `Jca` (Bouncy Castle) |
| Background | `WorkManager` + `AlarmManager` |
| Notifications | `NotificationCompat` / `NotificationManager` |
| Media | `MediaRecorder` + `AudioRecord` + `ExoPlayer` |

### Web (Next.js PWA) — 신규 생성

| 영역 | 라이브러리 |
|------|-----------|
| Framework | `Next.js 15` (App Router) + TypeScript |
| State | `Zustand` or `Jotai` |
| Storage | `Dexie.js` (IndexedDB wrapper) |
| Vector | `tiny-embeddings` or ONNX Web |
| STT | `Web Speech API` (`SpeechRecognition`) |
| LLM | `WebLLM` (`@mlc-ai/web-llm`) — WASM 기반 on-device LLM |
| Embedding | `Transformers.js` or `tiny-encoder` |
| Crypto | `Web Crypto API` (AES-GCM) |
| PWA | `next-pwa` or custom `ServiceWorker` |
| UI | `TailwindCSS 4` + `Shadcn/ui` (forked, custom theme) |
| Auth | `WebAuthn` (Passkeys) + Pin Code |

---

## 3. 공통 데이터 모델 (Cross-Platform)

모든 플랫폼이 동일한 로깅 구조를 공유. JSON 스키마로 정의:

### VoiceLogEntry
```typescript
interface VoiceLogEntry {
  id: string;                    // UUID v4
  title: string;
  recordingDate: number;         // epoch ms
  transcript: string;
  aiSummary: string | null;
  aiEnrichment: string[];        // follow-up questions
  sentiment: number;             // -100 ~ +100
  durationMs: number;
  keywords: string[];
  audioDataUri: string;          // base64 WAV
  embeddingId: string;           // FK → vector index
}
```

### VaultRecord
```typescript
interface VaultRecord {
  id: string;
  name: string;
  vaultType: 'letter' | 'password' | 'crypto' | 'legal' | 'custom';
  encryptedData: string;         // base64 AES-GCM ciphertext
  salt: string;                  // hex salt for PBKDF2
  lastPingDate: number;
  deadlineDays: number;
  targetEmails: string[];
  status: 'active' | 'paused' | 'expired' | 'alert_sent';
}
```

### InheritanceContact
```typescript
interface InheritanceContact {
  id: string;
  name: string;
  email: string;
  relationship: 'spouse' | 'child' | 'friend' | 'organization';
  notificationStatus: number;    // 0=pending, 1=alert_7d, 2=alert_3d, 3=alert_1d, 4=delivered
}
```

### ChatMessage (Legacy Agent)
```typescript
interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: number;
  embeddingId: string | null;
}
```

### ValueKeyword
```typescript
interface ValueKeyword {
  id: string;
  word: string;
  frequency: number;
  firstOccurrence: number;
  lastOccurrence: number;
  associatedValues: string[];
  category: 'family' | 'career' | 'emotion' | 'philosophy' | 'growth' | 'peace';
}
```

---

## 4. 공통 Design System

### Color Palette
```
Primary Background:    #0A0A0F (Deep void black)
Surface:               #1A1A2E (Muted dark)
Secondary Surface:     #2A2A3E (Card elevation)
Primary Accent:        #00FF88 (Neon green)
Secondary Accent:      #8B5CF6 (Electric purple)
Alert:                 #FF3860 (Neon coral)
Text Primary:          #E8E8ED
Text Secondary:        #8E8EA0
```

### Typography
```
Headlines:       SF Pro Display (iOS) / Roboto (Android) / Inter (Web) — 18-34sp/pt, Medium/Bold
Body:            14-16sp/pt, Regular
Caption:         11-12sp/pt, Regular, Secondary text
```

### Layout Principles
- **Safe Area First**: 모든 플랫폼에서 safe area inset 강제 적용
- **Gesture Unified**: Swipe-to-delete, long-press menu, pull-to-refresh
- **Micro-interactions**: FAB pulse animation (recording active), haptic feedback
- **Accessibility**: WCAG 2.2 AA contrast ratio, VoiceOver/TalkBack native support

---

## 5. 폴더 구조 (3 플랫폼)

### 5.1 iOS — `apps/legacy_vault_ios/`

```
apps/legacy_vault_ios/
├── Package.swift
├── legacy_vault_ios.xcodeproj/
├── legacy_vault_ios/
│   ├── App/
│   │   ├── LegacyVaultApp.swift          # @main
│   │   └── AppRouter.swift               # NavigationPath routing
│   ├── Core/
│   │   ├── Theme/                        # ColorPalette, Typography, Shapes
│   │   ├── Services/
│   │   │   ├── EncryptionService.swift
│   │   │   ├── STTService.swift
│   │   │   ├── LocalLLMService.swift
│   │   │   ├── EmbeddingService.swift
│   │   │   ├── VectorDBService.swift
│   │   │   ├── DeadManSwitchService.swift
│   │   │   ├── iCloudBackupService.swift
│   │   │   └── AppLifecycleService.swift
│   │   ├── Database/
│   │   │   ├── DatabaseManager.swift
│   │   │   ├── MigrationManager.swift
│   │   │   └── Schema.swift
│   │   ├── Models/
│   │   └── Utilities/
│   ├── Features/
│   │   ├── onboarding/
│   │   ├── auth/
│   │   ├── soul_mining/
│   │   ├── value_mapping/
│   │   ├── guardian/
│   │   ├── legacy_agent/
│   │   └── home/
│   ├── Resources/
│   │   ├── Assets.xcassets/
│   │   ├── Localization/
│   │   └── PrivacyInfo.xcprivacy
│   └── Tests/
```

### 5.2 Android — `apps/legacy_vault_android/`

```
apps/legacy_vault_android/
├── build.gradle.kts                      # Top-level: compose, kotlin, koin
├── settings.gradle.kts
├── gradle.properties
├── app/
│   ├── build.gradle.kts                  # Dependencies: compose, room, sqldelight, koin, workmanager
│   ├── src/main/
│   │   ├── AndroidManifest.xml           # Permissions: RECORD_AUDIO, FOREGROUND_SERVICE, etc.
│   │   └── java/com/sfx/legacyvault/
│   │       ├── LegacyVaultApp.kt         # @ModuleProvider (Koin) + Application
│   │       ├── di/                       # Koin modules
│   │       │   ├── DatabaseModule.kt
│   │       │   ├── ServiceModule.kt
│   │       │   └── ViewModelModule.kt
│   │       ├── core/
│   │       │   ├── theme/                # Color.kt, Type.kt, Shape.kt
│   │       │   ├── services/
│   │       │   │   ├── EncryptionService.kt
│   │       │   │   ├── STTService.kt
│   │       │   │   ├── LocalLLMService.kt
│   │       │   │   ├── EmbeddingService.kt
│   │       │   │   ├── VectorDBService.kt
│   │       │   │   ├── DeadManSwitchService.kt
│   │       │   │   └── AppLifecycleService.kt
│   │       │   ├── database/
│   │       │   │   ├── DatabaseProvider.kt   # Room + SQLDelight
│   │       │   │   ├── MigrationManager.kt
│   │       │   │   └── Schema.kt
│   │       │   ├── models/                   # Data classes matching spec
│   │       │   └── util/
│   │       ├── features/
│   │       │   ├── onboarding/
│   │       │   ├── auth/
│   │       │   ├── soul_mining/
│   │       │   ├── value_mapping/
│   │       │   ├── guardian/
│   │       │   ├── legacy_agent/
│   │       │   └── home/
│   │       └── navigation/
│   │           ├── AppNavGraph.kt
│   │           └── NavDestinations.kt
│   └── assets/
└── test/
```

### 5.3 Web — `apps/legacy_vault_web/`

```
apps/legacy_vault_web/
├── package.json
├── next.config.ts
├── tsconfig.json
├── tailwind.config.ts
├── public/
│   ├── manifest.json                      # PWA manifest
│   ├── service-worker.js                  # Offline cache + background sync
│   └── icons/                             # Favicon, apple-touch-icon
├── src/
│   ├── app/
│   │   ├── layout.tsx                     # Root layout: theme + PWA provider
│   │   ├── page.tsx                       # Redirect to /app or onboarding
│   │   ├── onboarding/
│   │   │   └── page.tsx                   # Welcome + Privacy consent + passphrase setup
│   │   ├── auth/
│   │   │   └── page.tsx                   # WebAuthn/Pin unlock
│   │   └── app/
│   │       ├── layout.tsx                 # App shell: sidebar + main content
│   │       ├── page.tsx                   # Home dashboard
│   │       ├── soul-mining/
│   │       ├── value-mapping/
│   │       ├── guardian/
│   │       └── legacy-agent/
│   ├── lib/
│   │   ├── db/
│   │   │   ├── index.ts                   # Dexie database setup
│   │   │   ├── schema.ts                  # Table definitions matching spec
│   │   │   └── migrations.ts
│   │   ├── crypto/
│   │   │   ├── aes-gcm.ts                 # Web Crypto API AES-GCM
│   │   │   ├── pbkdf2.ts                  # Key derivation
│   │   │   └── webauthn.ts                # Passkey operations
│   │   ├── ai/
│   │   │   ├── stt.ts                     # Web Speech API wrapper
│   │   │   ├── llm.ts                     # WebLLM wrapper
│   │   │   ├── embedding.ts               # Web embeddings
│   │   │   └── vector.ts                  # IndexedDB vector search
│   │   ├── services/
│   │   │   ├── encryptionService.ts
│   │   │   ├── sttService.ts
│   │   │   ├── llmService.ts
│   │   │   ├── embeddingService.ts
│   │   │   ├── vectorDBService.ts
│   │   │   ├── deadManSwitchService.ts
│   │   │   └── backupService.ts           # Local encrypted export (no cloud)
│   │   ├── models/                       # TypeScript interfaces matching spec
│   │   └── utils/
│   ├── stores/
│   │   ├── authStore.ts                  # Auth state, passkey presence
│   │   ├── soulMiningStore.ts            # Recording + transcript state
│   │   ├── guardianStore.ts              # Dead man switch state
│   │   ├── legacyAgentStore.ts           # Chat messages + persona
│   │   └── valueMappingStore.ts          # Keywords + timeline state
│   ├── components/
│   │   ├── ui/                           # Reusable primitives: Button, Card, Input...
│   │   ├── layout/                       # AppShell, Sidebar, TopBar
│   │   ├── soul-mining/                  # MIC FAB, Waveform, Transcript, AI Enrichment
│   │   ├── value-mapping/                # KeywordCloud, Timeline canvas
│   │   ├── guardian/                     # Dashboard, countdown timer, heir manager
│   │   ├── legacy-agent/                 # Chat input, message bubble, persona config
│   │   └── shared/                       # Loading, Error, EmptyState
│   └── styles/
│       └── globals.css                   # Tailwind + custom theme variables
└── tests/
```

---

## 6. DB 스키마 (Platform-Specific Implementations)

### iOS: Core Data + sqlite-vec
```sql
CREATE VIRTUAL TABLE recording_vectors USING vec0(embedding float[768]);
CREATE VIRTUAL TABLE chat_vectors USING vec0(embedding float[768]);
CREATE VIRTUAL TABLE keyword_vectors USING vec0(embedding float[768]);
```

### Android: Room + SQLDelite
```kotlin
// Room Entities (structured data)
@Entity(tableName = "voice_log_entries") data class VoiceLogEntry(...)
@Entity(tableName = "vault_records") data class VaultRecord(...)
@Entity(tableName = "inheritance_contacts") data class InheritanceContact(...)
@Entity(tableName = "chat_messages") data class ChatMessage(...)
@Entity(tableName = "value_keywords") data class ValueKeyword(...)

// SQLDelight Custom Tables (vector storage)
• recording_vectors.sq → CREATE VIRTUAL TABLE ... USING vec0(embedding float[768])
• chat_vectors.sq
• keyword_vectors.sq
```

### Web: Dexie (IndexedDB)
```typescript
class LegacyDB extends Dexie {
  voiceLogEntries: Table<VoiceLogEntry, string>;
  vaultRecords: Table<VaultRecord, string>;
  inheritanceContacts: Table<InheritanceContact, string>;
  chatMessages: Table<ChatMessage, string>;
  valueKeywords: Table<ValueKeyword, string>;
  
  // Vector indexes (stored as raw arrays, searched with custom KNN)
  recordingVectors: Store<string, number[]>;
  chatVectors: Store<string, number[]>;
  keywordVectors: Store<string, number[]>;
}
```

---

## 7. 구현 페이즈 (24 Sub-Phases, 병렬 최적화)

> **전제**: 각 플랫폼의 Core/Infrastructure(암호화, DB, AI 서비스)는 먼저 생성 → Feature UI가 그 위에 빌드.

### Phase 0: 공통 정의 — 1일

| 작업 | 담당 | 파일 |
|------|------|------|
| 공통 JSON 스키마 정의 | All 3 | `CORE/projects/common_models.json` |
| 디자인 시스템 토큰 정의 | All 3 | `tokens.json` (color, typography, spacing) |
| Privacy rules 체크리스트 | All 3 | `privacy_rules.md` |

---

### Phase 1: 프로젝트 초기화 — 2일 (3 플랫폼 병렬)

| 작업 | iOS | Android | Web |
|------|-----|---------|-----|
| 빈 프로젝트 scaffold | ✓ | ✓ | ✓ |
| Xcode / Gradle / Next.js 생성 | ✓ | ✓ | ✓ |
| 기본 디렉토리 구조 | ✓ | ✓ | ✓ |
| Package 설정 | ✓ (Package.swift) | ✓ (build.gradle.kts) | ✓ (package.json + PWA config) |
| 디자인 시스템 초기화 | ✓ (ColorPalette.swift) | ✓ (Color.kt) | ✓ (tailwind.config.ts + globals.css) |
| 앱 아이콘 + 스플래시 | ✓ | ✓ | ✓ |

**병렬**: 3 플랫폼 동시 생성
**Blocks**: Phase 2-6
**Acceptance**: 각 플랫폼 `Hello World` 빌드 성공

---

### Phase 2: Core Infrastructure — 3일 (3 platforms × ~3일, 병렬)

각 플랫폼의 Core/Services + Core/Database 생성.

| 파일/모듈 | iOS | Android | Web |
|-----------|-----|---------|-----|
| `EncryptionService` | ✓ AES-GCM + CryptoKit | ✓ AES-GCM + AndroidKeystore | ✓ AES-GCM + Web Crypto API |
| `STTService` | ✓ SpeechAnalyzer / WhisperKit | ✓ SpeechRecognizer / WhisperAndroid | ✓ Web Speech API |
| `LocalLLMService` | ✓ FoundationModels / mlx-swift-lm | ✓ MLC Android / llama.cpp NDK | ✓ WebLLM (WASM) |
| `EmbeddingService` | ✓ swift-embeddings | ✓ ONNX Runtime Mobile | ✓ Transformers.js |
| `VectorDBService` | ✓ sqlite-vec wrapper | ✓ SQLDelite vec0 | ✓ Dexie + custom KNN |
| `DeadManSwitch` | ✓ BackgroundTask + UNNotification | ✓ WorkManager + Notification | ✓ ServiceWorker + Web Push (opt) |
| `iCloudBackup / Export` | ✓ CloudKit encrypted | ✓ SecureFileExport | ✓ EncryptedZIP download |
| `AppLifecycle` | ✓ UIApplicationDelegate | ✓ WorkManager watchdog | ✓ ServiceWorker heartbeat |
| `DatabaseManager + Schema` | ✓ Core Data + vec0 | ✓ Room + SQLDelite + vec | ✓ Dexie + vector stores |

**병렬**: 3 플랫폼 동시 구현
**Blocks**: Phase 3-7 (모든 Feature UI)
**Acceptance**: 모든 platform에서 `encrypt → decrypt` 테스트 통과, `insertVector + searchNearest` 통과

---

### Phase 3: Feature 1 — Soul-Mining (AI 지능형 라이프 로깅) — 4일 (병렬)

| 파일/컴포넌트 | iOS | Android | Web |
|--------------|-----|---------|-----|
| `SoulMiningMainView` | ✓ | ✓ | ✓ |
| `VoiceRecordingButton` (pulsing FAB) | ✓ | ✓ | ✓ |
| `RecordingView` (waveform + live transcript) | ✓ | ✓ | ✓ |
| `RecordingPlayerView` | ✓ | ✓ | ✓ |
| `AIContextView` (follow-up questions) | ✓ | ✓ | ✓ |
| `SessionSummaryView` (emotion + keywords) | ✓ | ✓ | ✓ |
| `STTCoordinator` | ✓ | ✓ | ✓ |
| `AIPromptGenerator` | ✓ | ✓ | ✓ |
| `EnrichmentEngine` | ✓ | ✓ | ✓ |
| `RecordingSessionStore` | ✓ Core Data | ✓ Room VM | ✓ Zustand store |

**Acceptance**: Mic tap → recording → waveform → transcription → AI summary flow on all 3 platforms

---

### Phase 4: Feature 3 — Guardian Protocol (가디언 프로토콜) — 3일 (병렬)

> Note: Phase 3/4 병렬 실행 가능 (기능 간독립)

| 파일/컴포넌트 | iOS | Android | Web |
|--------------|-----|---------|-----|
| `GuardianDashboard` | ✓ | ✓ | ✓ |
| `DeadManSwitchSetup` | ✓ | ✓ | ✓ |
| `HeirManager` | ✓ | ✓ | ✓ |
| `BackupStatusView` | ✓ CloudKit | ✓ FileExport | ✓ Download ZIP |
| `VaultDecryptionView` | ✓ FaceID + pass | ✓ Biometric + pass | ✓ Passkey + pin |
| `DeadManSwitchEngine` | ✓ BG Task | ✓ Work Manager | ✓ SW Heartbeat |
| `NotificationHandler` | ✓ UNNotification | ✓ NotificationCompat | ✓ Web Push (opt) |
| `SecureVaultRepo` | ✓ | ✓ | ✓ IndexedDB |

**Acceptance**: Dead man switch setup → background watchdog → countdown → alert → deadline

---

### Phase 5: Feature 2 — Value Mapping (가치관 지도) — 3일 (병렬)

| 파일/컴포넌트 | iOS | Android | Web |
|--------------|-----|---------|-----|
| `ValueMappingMainView` | ✓ | ✓ | ✓ |
| `KeywordCloudView` | ✓ | ✓ | ✓ |
| `ValueMappingTimelineView` | ✓ | ✓ | ✓ |
| `TimelineCellView` | ✓ | ✓ | ✓ |
| `ValueInsightView` | ✓ | ✓ | ✓ |
| `KeywordExtractor` | ✓ | ✓ | ✓ |
| `ValueAnalyzer` | ✓ | ✓ | ✓ |
| `TimelineBuilder` | ✓ | ✓ | ✓ |

---

### Phase 6: Feature 4 — Legacy Agent + Auth/Onboarding — 4일 (병렬)

**Feature 4: Legacy Agent**

| 파일/컴포넌트 | iOS | Android | Web |
|--------------|-----|---------|-----|
| `LegacyAgentMainView` | ✓ | ✓ | ✓ |
| `LegacyAgentChatView` | ✓ | ✓ | ✓ |
| `LegacyAgentPersonaView` | ✓ | ✓ | ✓ |
| `ConversationThreadView` | ✓ | ✓ | ✓ |
| `PersonaChatService` (RAG-augmented) | ✓ | ✓ | ✓ |
| `RAGRetriever` (vector search + prompt augment) | ✓ | ✓ | ✓ |
| `PersonaPromptBuilder` | ✓ | ✓ | ✓ |
| `KnowledgeIndexer` (index recordings → KB) | ✓ | ✓ | ✓ |

**Auth + Onboarding**

| 파일/컴포넌트 | iOS | Android | Web |
|--------------|-----|---------|-----|
| Apple Sign-In | ✓ | — | — |
| Google Sign-In | — | ✓ | — |
| Passkey / WebAuthn | — | — | ✓ |
| FaceID / Biometric | ✓ | ✓ | — |
| Passphrase/Pin Setup | ✓ | ✓ | ✓ |
| OnboardingFlow | ✓ | ✓ | ✓ |

---

### Phase 7: 테스트 + 빌드 검증 — 3일 (병렬)

| 테스트 유형 | iOS | Android | Web |
|------------|-----|---------|-----|
| Unit tests (pure functions) | ✓ | ✓ | ✓ |
| Integration tests (recording → transcribe → retrieve) | ✓ | ✓ | ✓ |
| Privacy test (no network imports) | ✓ | ✓ | ✓ |
| Lint (SwiftLint) | ✓ | ✓ (ktlint) | ✓ (ESLint + tsc) |
| PWA verification (Lighthouse 100 offline) | — | — | ✓ |
| Performance profiling | ✓ | ✓ | ✓ |

---

## 8. 병렬 실행 그래프

```
Phase 0: 공통 정의 (1일)
         │
Phase 1: 프로젝트 초기화 (2일) ← 3プラットフォーム 병렬
         │
Phase 2: Core基础设施 (3일) ← 3プラットフォーム 병列
         │
    ┌────┼────┐
    │        │           (Feature间部分独立)
Phase 3  Phase 4          Phase 5
Soul-    Guardian         Value
Mining   Protocol         Mapping
(4日)    (3日)            (3日)
    │        │              │
    └──┬─────┴──────────────┘
       │
Phase 6: Legacy Agent + Auth/Onboarding (4日)
       │
Phase 7: 테스트 + 빌드 검증 (3日) ← 3プラットフォーム  병列
       │
     완료
```

**최대 병렬**: 3 플랫폼 × 5 フェイズ = 동시 3개 프로덕트 생성/수정

---

## 9. Privacy Rules (모든 플랫폼 공통)

1. **NO Network Imports**: 어떤 파일에서도 `URLSession`/`OkHttp`/`fetch`/`axios` 사용 금지
2. **NO External SDK**: Firebase, Sentry, Mixpanel 등 외부 관찰 SDK 금지
3. **Local Only**: 모든 데이터(음성, 텍스트, 임베딩, 키)는 기기 저장소에만
4. **Privacy Test**: 빌드 시 `grep -r "networking\|URLSession\|OkHttp\|fetch" --exclude="*.md" | wc -l` → 0이어야 함
5. **Airplane Mode**: 비행기 모드에서 모든 기능 확인 테스트 필수

---

## 10. Commit Strategy

| Phase | Commit |
|-------|--------|
| P0 | `chore: add common models and design tokens` |
| P1 | `feat(ios): init SwiftUI project scaffold` |
| P1 | `feat(android): init Jetpack Compose project scaffold` |
| P1 | `feat(web): init Next.js PWA project scaffold` |
| P2-P6 | 기능 단위 커밋 (파일/모듈별) |
| P7 | `test: add privacy and integration tests` |
| 완료 | `chore: multi-target Legacy Vault — build verified` |

---

## 11. Success Criteria

1. **Build**: 각 플랫폼 빌드 실패 0건
2. **Onboarding**: 완료 → Soul-Mining 홈 화면 표시
3. **Soul-Mining**: Mic tap → Recording → Transcription → AI Summary (100% on-device)
4. **Guardian**: Dead man switch → Background → Alert flow 동작
5. **Value Mapping**: 전체 녹음에서 키워드 클라우드 + 타임라인 생성
6. **Legacy Agent**: RAG 컨텍스트 검색 → LLM이 페르소나 일관성 응답 생성
7. **Privacy**: 모든 플랫폼에서 네트워크 import 0건, 비행기 모드全機能 작동
8. **PWA**: Web에서 offline-first, ServiceWorker 캐시, manifest 정상

---

## 12. 기존 프로젝트와의 관계

| 기존 프로젝트 | 새 Multi-Target 계획과의 관계 |
|-------------|--------------------------|
| `sfx_legacy_vault_v1` (Flutter+Firebase) | **사용 안 함**. 이 plan은 Firebase를 완전히 제거한 100% on-device |
| `legacy-vault-ios-plan.md` | iOS 파트 내용과 호환. Android/Web 추가 |
| `legacy-core` (Spring Boot) | **사용 안 함**. 백엔드 서버 없이 완전 독립형 |
| `brand-web` (Next.js) | Web 파트에서 디자인/톤 참조 가능 |

---

## 13. 실행 옵션

### 옵션 A: 순차적 (안정적)
iOS → Android → Web 순서. 각 플랫폼 완성도 높음.
**시간**: ~10-12주

### 옵션 B: 동시 (병렬)
3 플랫폼을 동시에 생성. 오케스트레이션 복잡도 높음.
**시간**: ~8-10주

### 옵션 C: MVP 우선 (추천)
1주 차: iOS 완성 (이미 plan 있음)
2-3주 차: Android + Web 동시 MVP
4주 차: 3 플랫폼 통합 검증
**시간**: ~6-8주 (MVP 기준)
