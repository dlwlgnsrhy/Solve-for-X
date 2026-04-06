# 🤖 Agent Memory (Short-term Storage)

## 📌 Project: Imjong Care Service (임종 케어 서비스)
- **Goal**: Flutter MVP for EOL (End-of-Life) care service.
- **Architecture**: Clean Architecture (core, data, domain, presentation).
- **Tech Stack**: Flutter, Riverpod, GoRouter, Dio, Freezed.

---

## 🏗 Current Architecture Status
- [x] Initialized Flutter project (`apps/imjong-care-app`).
- [x] Pre-configured `pubspec.yaml` with Riverpod, Freezed, GoRouter, etc.
- [x] Created Skeleton folder structure.
- [ ] Core: Error handling & Network client (Dio) setup.
- [ ] Domain: Entities and Repository interface for [Login/Dashboard].
- [ ] Data: API implementation & Mock data source.
- [ ] Presentation: Atomic Design widgets & Riverpod providers.

---

## 🗓 Next Steps (Night-Shift Mission)
1. **Core Layer**: 
   - `lib/core/network/dio_client.dart` 생성 (Dio 초기화).
   - `lib/core/error/failures.dart` 공통 에러 처리 정의.
2. **Domain Layer**: 
   - `User` 모델(`freezed`) 정의.
   - `AuthRepository` 인터페이스 정의.
3. **Data Layer**:
   - `AuthRepositoryImpl` 및 목업 데이터(`MockAuthDataSource`) 구현.
4. **Presentation Layer**:
   - `LoginScreen`, `DashboardScreen` UI 베이스라인 구축.
   - `AuthNotifier` (Riverpod) 상태 관리 구현.
5. **Automation Rules**:
   - Every file change must be followed by `flutter analyze`.
   - If `freezed` or `json_serializable` is used, run `flutter pub run build_runner build --delete-conflicting-outputs`.
   - Update this file (`AGENTS.md`) after each major step.

---

## 🛠 Useful Commands
- `flutter pub get`
- `flutter analyze`
- `flutter pub run build_runner build --delete-conflicting-outputs`
