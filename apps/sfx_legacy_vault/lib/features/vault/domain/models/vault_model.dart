import 'package:cloud_firestore/cloud_firestore.dart';

/// Vault data model representing a user's dead man's switch configuration.
/// Supports multiple vaults per user, each with its own encryption, deadline, and recipient.
class VaultModel {
  final String id;
  final String userId;
  final String name;
  final String vaultType;
  final DateTime lastActiveAt;
  final String targetEmail;
  final String encryptedData;
  final int deadlineDays;
  final DateTime createdAt;
  final String status; // 'active', 'paused'

  const VaultModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.vaultType,
    required this.lastActiveAt,
    required this.targetEmail,
    required this.encryptedData,
    required this.deadlineDays,
    required this.createdAt,
    this.status = 'active',
  });

  /// Firestore map to VaultModel.
  factory VaultModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return VaultModel(
      id: documentId,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? 'Untitled Vault',
      vaultType: data['vaultType'] as String? ?? 'other',
      lastActiveAt: (data['lastActiveAt'] as Timestamp).toDate(),
      targetEmail: data['targetEmail'] as String? ?? '',
      encryptedData: data['encryptedData'] as String? ?? '',
      deadlineDays: data['deadlineDays'] as int? ?? 14,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] as String? ?? 'active',
    );
  }

  /// VaultModel to Firestore map.
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'vaultType': vaultType,
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'targetEmail': targetEmail,
      'encryptedData': encryptedData,
      'deadlineDays': deadlineDays,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  /// Copy with modifications.
  VaultModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? vaultType,
    DateTime? lastActiveAt,
    String? targetEmail,
    String? encryptedData,
    int? deadlineDays,
    DateTime? createdAt,
    String? status,
  }) {
    return VaultModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      vaultType: vaultType ?? this.vaultType,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      targetEmail: targetEmail ?? this.targetEmail,
      encryptedData: encryptedData ?? this.encryptedData,
      deadlineDays: deadlineDays ?? this.deadlineDays,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  /// Returns the visual status based on deadline proximity and vault state.
  VaultStatus get visualStatus {
    if (status == 'paused') return VaultStatus.paused;
    if (!isActive) return VaultStatus.expired;

    final deadline = lastActiveAt.add(Duration(days: deadlineDays));
    final remaining = deadline.difference(DateTime.now()).inDays;

    if (remaining <= 0) return VaultStatus.expired;
    if (remaining <= 3) return VaultStatus.warning;
    return VaultStatus.active;
  }

  /// Whether the vault has data stored.
  bool get hasData => encryptedData.isNotEmpty;

  /// Whether the vault deadline has passed.
  bool get isActive {
    final deadline = lastActiveAt.add(Duration(days: deadlineDays));
    return DateTime.now().isBefore(deadline);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VaultModel && other.id == id && other.userId == userId;
  }

  @override
  int get hashCode => id.hashCode ^ userId.hashCode;
}

/// Visual status indicators for vault cards.
enum VaultStatus { active, warning, expired, paused }
