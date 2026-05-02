import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sfx_legacy_vault/features/vault/domain/models/vault_model.dart';

/// Firestore repository for vault data operations.
/// Uses a subcollection pattern: users/{userId}/vaults/{vaultId}
class VaultRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _vaultsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('vaults');
  }

  /// Fetch all vaults for a user.
  Future<List<VaultModel>> getVaults(String userId) async {
    try {
      final snapshot = await _vaultsCollection(userId).get();
      return snapshot.docs
          .map((doc) =>
              VaultModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream all vaults for real-time updates.
  Stream<List<VaultModel>> vaultsStream(String userId) {
    return _vaultsCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              VaultModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  /// Fetch a single vault by ID.
  Future<VaultModel?> getVault(String userId, String vaultId) async {
    try {
      final doc = await _vaultsCollection(userId).doc(vaultId).get();
      if (!doc.exists) return null;
      return VaultModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      return null;
    }
  }

  /// Create a new vault.
  Future<String> createVault(VaultModel vault) async {
    final docRef = await _vaultsCollection(vault.userId).add(vault.toFirestore());
    return docRef.id;
  }

  /// Update an existing vault.
  Future<void> updateVault(String userId, String vaultId, VaultModel vault) async {
    await _vaultsCollection(userId).doc(vaultId).set(vault.toFirestore());
  }

  /// Update specific fields of a vault.
  Future<void> updateVaultFields(
    String userId,
    String vaultId,
    Map<String, dynamic> fields,
  ) async {
    await _vaultsCollection(userId).doc(vaultId).update(fields);
  }

  /// Delete a vault.
  Future<void> deleteVault(String userId, String vaultId) async {
    await _vaultsCollection(userId).doc(vaultId).delete();
  }

  /// Ping: update lastActiveAt to now for a specific vault.
  Future<void> pingVault(String userId, String vaultId) async {
    await _vaultsCollection(userId).doc(vaultId).update({
      'lastActiveAt': Timestamp.now(),
      'status': 'active',
    });
  }

  /// Pause vault monitoring.
  Future<void> pauseVault(String userId, String vaultId) async {
    await _vaultsCollection(userId).doc(vaultId).update({
      'status': 'paused',
    });
  }

  /// Resume vault monitoring.
  Future<void> resumeVault(String userId, String vaultId) async {
    await _vaultsCollection(userId).doc(vaultId).update({
      'lastActiveAt': Timestamp.now(),
      'status': 'active',
    });
  }

  /// Check if user has any vaults.
  Future<bool> hasVaults(String userId) async {
    final snapshot = await _vaultsCollection(userId).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  /// Legacy compatibility: save single vault as userId doc (migrates old data).
  Future<void> saveVault(VaultModel vault) async {
    await createVault(vault);
  }

  /// Legacy compatibility: ping all active vaults for a user.
  Future<void> ping(String userId) async {
    final vaults = await getVaults(userId);
    for (final vault in vaults) {
      if (vault.status == 'active') {
        await pingVault(userId, vault.id);
      }
    }
  }

  /// Legacy compatibility: check if any vault exists.
  Future<bool> vaultExists(String userId) async {
    return hasVaults(userId);
  }
}
