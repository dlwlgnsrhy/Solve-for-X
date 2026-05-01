# Project: Origin — Human Authenticity Protocol
## Development Plan

> **Mission**: AGI 시대에 "사유의 과정"을 기록하여 인간의 오리지널리티를 증명한다.
> **Principles**: On-device First · Process over Result · No External AI API · Zero-Knowledge Proof

---

## 1. App Overview

| Field | Value |
|-------|-------|
| **App Name** | Origin (OAO) |
| **Package** | `com.sfx.origin` |
| **Framework** | Flutter 3.7+ (Dart) |
| **Architecture** | Clean Architecture (Feature-first) |
| **State** | Riverpod |
| **Storage** | SQLite (encrypted) + SharedPreferences |
| **Backend** | None — 100% on-device |
| **Theme** | Dark mode (`#0A0A0F`) with Neon accents |

---

## 2. Tech Stack & Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^2.6.1
  # Keystroke tracking
  raw_keyboard: ^0.10.1     # RawKeyboardListener for event capture
  # Data storage
  sqflite: ^2.3.0           # SQLite for mobile
  sqflite_common_ffi: ^2.3.0 # Desktop fallback (optional)
  encrypt: ^5.0.3           # SQLCipher-style encryption for DB
  crypto: ^3.0.3            # SHA-256 for Origin Stamps
  shared_preferences: ^2.3.3
  # Export / sharing
  share_plus: ^10.1.3       # Share certificate via share sheet
  pdf: ^3.10.8              # Generate PDF certificates
  path_provider: ^2.1.4     # File system access
  # Animation
  flutter_animate: ^4.5.0
  in_app_review: ^2.0.9     # App Store review prompt

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  flutter_launcher_icons: ^0.14.3
  flutter_native_splash: ^2.4.4
  # LLM integration (Phase 2)
  # mlc_llm: ^0.x     # On-device LLM inference (deferred)
```

---

## 3. Feature Architecture

### 3.1 Human Pulse Tracker

Captures keystroke dynamics without blocking UI.

**Data Flow:**
```
RawKeyboardListener (t0: key down event)
        ↓
TextInputFormatter (t1: text mutation)
        ↓
KeystrokeAggregator → compute t_delta, is_backspace, context
        ↓
SQLiteBatchWriter (throttled, every 2s or 50 events)
        ↓
SQLite: keystroke_events table (encrypted)
```

**Key Insight:** Use `RawKeyboardListener` as the ancestor of `TextField` + custom `TextInputFormatter` that receives key event timestamps from a shared tracker object. This gives ~10ms precision on modern devices, sufficient for rhythm entropy analysis.

**Precision:** 5-15ms on iOS/Android (limited by Flutter vsync cycle). Not forensic — good enough for behavioral classification.

### 3.2 Authentic Analyzer

Deterministic scoring pipeline (Phase 1, no LLM). Replaceable LLM interface for Phase 2.

**Score = 0.35 × RhythmEntropy + 0.25 × RevisionPattern + 0.20 × VocabularyRichness + 0.20 × TemporalConsistency**

Each metric is a pure Dart function — testable, isolatable, explorable.

### 3.3 Origin Stamp

SHA-256 hash of (content ⫶ timestamp ⫶ userId) with optional Ed25519 signature.

Outputs: JSON certificate for sharing, PDF certificate for archival.

---

## 4. Database Schema

```sql
-- Keystroke events batched by session
CREATE TABLE IF NOT EXISTS keystroke_events (
  id               TEXT PRIMARY KEY,
  session_id       TEXT    NOT NULL,
  key_code         INTEGER NOT NULL,        -- LogicalKeyboardKey value
  key_name         TEXT    NOT NULL,        -- Human-readable key
  t_delta          INTEGER NOT NULL,        -- ms since previous key
  timestamp        TEXT    NOT NULL,        -- ISO8601
  is_backspace     INTEGER NOT NULL,        -- 0 or 1
  prev_length      INTEGER NOT NULL,
  new_length       INTEGER NOT NULL
);

-- Per-session aggregates (computed once, queried fast)
CREATE TABLE IF NOT EXISTS sessions (
  id                    TEXT PRIMARY KEY,
  user_id               TEXT    NOT NULL,
  started_at            TEXT    NOT NULL,
  ended_at              TEXT,
  content               TEXT    NOT NULL,
  content_length        INTEGER NOT NULL,
  keystroke_event_count INTEGER NOT NULL,
  avg_t_delta           REAL,
  is_completed          INTEGER NOT NULL DEFAULT 0
);

-- Completed documents with Origin Stamps
CREATE TABLE IF NOT EXISTS origin_stamps (
  id                        TEXT PRIMARY KEY,
  session_id                TEXT    UNIQUE NOT NULL,
  user_id                   TEXT    NOT NULL,
  content_hash              TEXT    NOT NULL,  -- SHA-256
  content_length            INTEGER NOT NULL,
  timestamp                 TEXT    NOT NULL,
  authenticity_score        REAL,
  keystroke_event_count     INTEGER,
  rhythm_entropy            REAL,
  revision_pattern_score    REAL,
  certificate_json          TEXT,              -- Full cert for export
  created_at                TEXT
);

-- User's intellectual fingerprint (long-term style profile)
CREATE TABLE IF NOT EXISTS fingerprint (
  id                        INTEGER PRIMARY KEY CHECK (id = 1),
  vocabulary_richness       REAL,              -- Type-token ratio
  avg_t_delta               REAL,              -- Baseline rhythm
  revision_ratio            REAL,              -- Long-term average
  function_word_ratio       REAL,              -- Stop words / total words
  sentence_length_stddev    REAL,
  updated_at                TEXT
);
```

**Encryption:** SQLCipher-level encryption via `encrypt` package wrapping the SQLite file. Key: auto-generated on first launch, stored in SharedPreferences, bound to device.

---

## 5. Folder Structure

```
apps/origin/
├── lib/
│   ├── main.dart                     # App entry: ProviderScope, PreferenceService, route init
│   │
│   ├── core/
│   │   ├── theme/
│   │   │   ├── app_theme.dart        # Dark mode, Material ThemeData
│   │   │   └── neon_colors.dart      # #0A0A0F bg, neon green accents
│   │   │
│   │   ├── services/
│   │   │   ├── preference_service.dart  # SharedPreferences wrapper (shared pattern)
│   │   │   ├── encryption_service.dart  # Key management, file encryption
│   │   │   └── review_service.dart      # App Store review prompt
│   │   │
│   │   ├── utils/
│   │   │   ├── date_utils.dart        # DateTime helpers
│   │   │   └── keystroke_tracker.dart # Shared state between RawKeyboardListener + TextInputFormatter
│   │   │
│   │   ├── constants/
│   │   │   └── app_colors.dart        # Hardcoded color constants
│   │
│   ├── features/
│   │   │
│   │   ├── pulse_tracker/            # Feature 1: Keystroke data collection
│   │   │   ├── domain/
│   │   │   │   ├── models/
│   │   │   │   │   ├── keystroke_event.dart
│   │   │   │   │   └── writing_session.dart
│   │   │   │   └── repositories/
│   │   │   │       └── pulse_repository.dart     # Interface
│   │   │   │
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── keystroke_sqlite_datasource.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── pulse_repository_impl.dart
│   │   │   │   └── models/
│   │   │   │       └── keystroke_event_dao.dart  # DB mapping
│   │   │   │
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── pulse_provider.dart
│   │   │       └── widgets/
│   │   │           └── keystroke_capture_field.dart  # Main writing area
│   │   │
│   │   ├── authentic_analyzer/       # Feature 2: Scoring engine
│   │   │   ├── domain/
│   │   │   │   ├── models/
│   │   │   │   │   ├── authenticity_result.dart
│   │   │   │   │   └── writing_fingerprint.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── authenticity_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── compute_authenticity_score.dart
│   │   │   │       ├── build_fingerprint.dart
│   │   │   │       └── compare_session_to_fingerprint.dart
│   │   │   │
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── metric_datasource.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── authenticity_repository_impl.dart
│   │   │   │   └── metrics/          # Pure function metrics
│   │   │   │       ├── rhythm_entropy_metric.dart
│   │   │   │       ├── revision_pattern_metric.dart
│   │   │   │       ├── vocabulary_richness_metric.dart
│   │   │   │       └── temporal_consistency_metric.dart
│   │   │   │
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── analyzer_dashboard_screen.dart
│   │   │       │   └── analysis_detail_screen.dart
│   │   │       ├── widgets/
│   │   │       │   ├── authenticity_gauge.dart      # Score ring
│   │   │       │   ├── rhythm_heatmap.dart          # t_delta distribution
│   │   │       │   ├── revision_timeline.dart       # Backspace/rewrite visual
│   │   │       │   └── fingerprint_view.dart
│   │   │       └── providers/
│   │   │           ├── analyzer_provider.dart
│   │   │           ├── score_provider.dart
│   │   │           └── fingerprint_provider.dart
│   │   │
│   │   ├── origin_stamp/             # Feature 3: Certificate generation
│   │   │   ├── domain/
│   │   │   │   ├── models/
│   │   │   │   │   └── origin_stamp.dart
│   │   │   │   └── usecases/
│   │   │   │       └── create_origin_stamp.dart
│   │   │   │
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── stamp_sqlite_datasource.dart
│   │   │   │   └── services/
│   │   │   │       ├── hash_service.dart            # SHA-256
│   │   │   │       └── certificate_generator.dart   # JSON + PDF
│   │   │   │
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── stamp_list_screen.dart
│   │   │       │   └── stamp_detail_screen.dart
│   │   │       ├── widgets/
│   │   │       │   ├── certificate_preview.dart
│   │   │       │   └── verify_button.dart
│   │   │       └── providers/
│   │   │           └── stamp_provider.dart
│   │   │
│   │   └── home/                     # Landing / navigation
│   │       ├── presentation/
│   │       │   ├── screens/
│   │       │   │   ├── home_screen.dart               # Tab dashboard
│   │       │   │   └── onboarding_screen.dart         # First launch
│   │       │   └── providers/
│   │       │       └── home_provider.dart
│   │       └── navigation/
│   │           └── app_router.dart
│   │
│   └── shared/
│       └── utils/
│           └── id_generator.dart    # UUID v4 generator
│
├── pubspec.yaml
├── analysis_options.yaml
├── assets/
│   └── images/
│       ├── app_icon.png
│       └── splash_logo.png
└── test/                          # Unit tests for all pure functions
    ├── features/authentic_analyzer/data/metrics/
    ├── features/pulse_tracker/data/
    └── features/origin_stamp/data/services/
```

---

## 6. Implementation Phases

### Phase 1: Foundation (1-2 days)

**Setup + Database + Keystroke Tracker**

1. **Project scaffold** — `flutter create`, pubspec.yaml, analysis_options.yaml, theme setup
2. **Database layer** — SQLCipher setup, schema creation, migration support
3. **KeystrokeTracker** — Shared state object wired to RawKeyboardListener + TextInputFormatter, batching writes to SQLite
4. **PulseTracker feature** — Domain models, repository, SQLite datasource, basic capture UI

**Deliverable:** Writing with a text field — keystrokes captured to encrypted SQLite with t_delta, backspace detection, session tracking.

---

### Phase 2: Authentic Analyzer (2-3 days)

**Scoring Engine + UI**

1. **Metric extractors** — Pure Dart functions for all 4 metrics, unit tested
2. **Score combiner** — Weighted aggregation (35/25/20/20)
3. **Fingerprint builder** — Long-term style profile from historical sessions
4. **Dashboard** — AuthenticityGauge widget (score ring), rhythmHeatmap, revisionTimeline
5. **Fingerprint view** — Show user's intellectual fingerprint stats

**Deliverable:** Score computed from keystroke data, dashboard showing authenticity breakdown and fingerprint.

---

### Phase 3: Origin Stamp (1-2 days)

**Certificate Generation**

1. **HashService** — SHA-256 of (content ⫶ timestamp ⫶ userId)
2. **CertificateGenerator** — JSON serialization + PDF export
3. **Stamp repository** — Store stamps in SQLite, query/export
4. **Stamp screens** — List of completed documents with scores, detail view with certificate
5. **Share flow** — share_plus integration for certificate export

**Deliverable:** Complete documents with verifiable Origin Stamps, exportable as JSON/PDF.

---

### Phase 4: Polish & QA (1-2 days)

**Testing + App Store prep**

1. Unit tests for all pure functions (metrics, hashing, scoring)
2. Integration: end-to-end keystroke → score → stamp flow
3. App-level: theme polish, animations, splash screen, icons
4. App Store prep: privacy policy, metadata, TestFlight build

**Total: ~2 weeks by one senior Flutter engineer**