import 'dart:convert';

class QRVerificationData {
  final String signature;
  final String contentHash;
  final double score;
  final String timestamp;
  final String userId;
  final String deviceId;

  const QRVerificationData({
    required this.signature,
    required this.contentHash,
    required this.score,
    required this.timestamp,
    required this.userId,
    this.deviceId = '',
  });

  Map<String, dynamic> toJson() => {
        'signature': signature,
        'contentHash': contentHash,
        'score': score,
        'timestamp': timestamp,
        'userId': userId,
        'deviceId': deviceId,
      };

  factory QRVerificationData.fromJson(Map<String, dynamic> json) {
    return QRVerificationData(
      signature: json['signature'] as String? ?? '',
      contentHash: json['contentHash'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
    );
  }

  factory QRVerificationData.fromMap(Map<String, dynamic> map) =>
      QRVerificationData(
        signature: map['signature'] as String? ?? '',
        contentHash: map['contentHash'] as String? ?? '',
        score: (map['score'] as num?)?.toDouble() ?? 0.0,
        timestamp: map['timestamp'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        deviceId: map['deviceId'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => toJson();

  String toJsonString() => jsonEncode(toJson());

  factory QRVerificationData.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return QRVerificationData(
      signature: json['signature'] as String? ?? '',
      contentHash: json['contentHash'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
    );
  }

  @override
  String toString() => toJsonString();
}
