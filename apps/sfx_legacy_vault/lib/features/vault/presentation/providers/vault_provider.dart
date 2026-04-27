import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_legacy_vault/core/services/review_service.dart';
import 'package:sfx_legacy_vault/features/vault/data/vault_repository.dart';
import 'package:sfx_legacy_vault/features/vault/domain/models/vault_model.dart';

final vaultRepositoryProvider = Provider<VaultRepository>(
  (ref) => VaultRepository(),
);

/// Stream-based vault list provider for real-time updates.
final vaultsStreamProvider =
    StreamProvider.family<List<VaultModel>, String>((ref, userId) {
  final repo = ref.watch(vaultRepositoryProvider);
  return repo.vaultsStream(userId);
});

/// Notifier for vault list CRUD operations.
class VaultsNotifier extends Notifier<List<VaultModel>> {
  @override
  List<VaultModel> build() => [];

  /// Get a single vault by ID from the current list.
  VaultModel? getVaultById(String id) {
    try {
      return state.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Add a new vault.
  Future<String> addVault(VaultModel vault) async {
    final repo = ref.read(vaultRepositoryProvider);
    final id = await repo.createVault(vault);
    final created = vault.copyWith(id: id);
    state = [...state, created];
    return id;
  }

  /// Save a new vault (alias for addVault, legacy compatibility).
  Future<void> saveVault(VaultModel vault) async {
    await addVault(vault);
  }

  /// Update an existing vault.
  Future<void> updateVault(String userId, String vaultId, VaultModel updated) async {
    final repo = ref.read(vaultRepositoryProvider);
    await repo.updateVault(userId, vaultId, updated);
    state = state.map((v) => v.id == vaultId ? updated : v).toList();
  }

  /// Update specific fields of a vault.
  Future<void> updateVaultFields(
    String userId,
    String vaultId,
    Map<String, dynamic> fields,
  ) async {
    final repo = ref.read(vaultRepositoryProvider);
    await repo.updateVaultFields(userId, vaultId, fields);

    // Update local state
    final current = getVaultById(vaultId);
    if (current != null) {
      VaultModel updated;
      if (fields.containsKey('lastActiveAt')) {
        updated = current.copyWith(lastActiveAt: DateTime.now());
      } else if (fields.containsKey('status')) {
        updated = current.copyWith(status: fields['status'] as String? ?? current.status);
      } else {
        updated = current;
      }
      state = state.map((v) => v.id == vaultId ? updated : v).toList();
    }
  }

  /// Delete a vault.
  Future<void> deleteVault(String userId, String vaultId) async {
    final repo = ref.read(vaultRepositoryProvider);
    await repo.deleteVault(userId, vaultId);
    state = state.where((v) => v.id != vaultId).toList();
  }

  /// Ping a specific vault to update lastActiveAt.
  Future<void> pingVault(String userId, String vaultId) async {
    final repo = ref.read(vaultRepositoryProvider);
    await repo.pingVault(userId, vaultId);
    final current = getVaultById(vaultId);
    if (current != null) {
      final updated = current.copyWith(lastActiveAt: DateTime.now(), status: 'active');
      state = state.map((v) => v.id == vaultId ? updated : v).toList();
    }

    // Track ping for in-app review
    await _trackPing();
  }

  /// Ping all active vaults.
  Future<void> pingAll(String userId) async {
    final repo = ref.read(vaultRepositoryProvider);
    await repo.ping(userId);
    final now = DateTime.now();
    state = state.map((v) {
      if (v.status == 'active') {
        return v.copyWith(lastActiveAt: now, status: 'active');
      }
      return v;
    }).toList();

    // Track ping for in-app review
    await _trackPing();
  }

  /// Pause vault monitoring.
  Future<void> pauseVault(String userId, String vaultId) async {
    final repo = ref.read(vaultRepositoryProvider);
    await repo.pauseVault(userId, vaultId);
    state = state.map((v) => v.id == vaultId ? v.copyWith(status: 'paused') : v).toList();
  }

  /// Resume vault monitoring.
  Future<void> resumeVault(String userId, String vaultId) async {
    final repo = ref.read(vaultRepositoryProvider);
    await repo.resumeVault(userId, vaultId);
    final current = getVaultById(vaultId);
    if (current != null) {
      final updated = current.copyWith(lastActiveAt: DateTime.now(), status: 'active');
      state = state.map((v) => v.id == vaultId ? updated : v).toList();
    }
  }

  /// Clear cached vaults (on sign out).
  void clear() {
    state = [];
  }

  /// Track a ping event for in-app review eligibility.
  Future<void> _trackPing() async {
    final reviewService = ref.read(reviewServiceProvider.notifier);
    await reviewService.incrementPingCount();
  }
}

final vaultNotifierProvider = NotifierProvider<VaultsNotifier, List<VaultModel>>(
  VaultsNotifier.new,
);
