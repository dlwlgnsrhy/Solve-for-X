import 'package:flutter/foundation.dart';

/// 유서 저작 플랫폼 내 개별 유서의 라이프사이클을 견고하게 통제하는 불변 데이터 모델입니다.
/// 모든 필드는 불변(Immutable) 상태이며, 값 객체(Value Object)로서의 동등성 비교를 지원합니다.
@immutable
class WillCardModel {
  /// 고유 식별자(UUID)
  final String uuid;

  /// 유서의 텍스트 본문 내용
  final String content;

  /// 작성자 이름 혹은 식별자
  final String author;

  /// 선택된 템플릿의 스타일 고유 ID
  final String styleId;

  /// 작성 완료 또는 최종 수정 시간
  final DateTime updatedAt;

  /// 모든 필드가 final로 정의된 컴파일 타임 상수를 보장하는 생성자입니다.
  const WillCardModel({
    required this.uuid,
    required this.content,
    required this.author,
    required this.styleId,
    required this.updatedAt,
  });

  /// 불변 객체의 안전한 상태 전이를 지원하기 위한 Deep Copy 메서드입니다.
  WillCardModel copyWith({
    String? uuid,
    String? content,
    String? author,
    String? styleId,
    DateTime? updatedAt,
  }) {
    return WillCardModel(
      uuid: uuid ?? this.uuid,
      content: content ?? this.content,
      author: author ?? this.author,
      styleId: styleId ?? this.styleId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// REST API 및 로컬 영속성 스토리지(Isar, SQLite 등) 연동을 위한 JSON 직렬화 메서드입니다.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'uuid': uuid,
      'content': content,
      'author': author,
      'styleId': styleId,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 역직렬화를 통해 타입 안전성이 확보된 모델 인스턴스를 동적으로 구성합니다.
  factory WillCardModel.fromJson(Map<String, dynamic> json) {
    return WillCardModel(
      uuid: json['uuid'] as String,
      content: json['content'] as String,
      author: json['author'] as String,
      styleId: json['styleId'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 엔티티가 아닌 값 객체로서 속성(Attribute) 기반 동등성을 보장하기 위해 operator [==]를 재정의합니다.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WillCardModel &&
          runtimeType == other.runtimeType &&
          uuid == other.uuid &&
          content == other.content &&
          author == other.author &&
          styleId == other.styleId &&
          updatedAt == other.updatedAt;

  /// 동등성 비교와 함께 해시 맵 등 구조적 탐색 효율성을 극대화하기 위해 hashCode를 재정의합니다.
  @override
  int get hashCode =>
      uuid.hashCode ^
      content.hashCode ^
      author.hashCode ^
      styleId.hashCode ^
      updatedAt.hashCode;

  /// DevOps 모니터링 및 터미널 로깅 디버깅 편의를 극대화한 가독성 높은 toString 재정의입니다.
  @override
  String toString() {
    return 'WillCardModel(uuid: $uuid, content: $content, author: $author, styleId: $styleId, updatedAt: $updatedAt)';
  }
}
