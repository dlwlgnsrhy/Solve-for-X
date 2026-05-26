class WillCardModel {
  final String id;
  final String author;
  final String content;
  final String? questionPrompt;
  final DateTime createdAt;
  final int likes;

  WillCardModel({
    required this.id,
    required this.author,
    required this.content,
    this.questionPrompt,
    required this.createdAt,
    this.likes = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'author': author,
      'content': content,
      'questionPrompt': questionPrompt,
      'createdAt': createdAt.toIso8601String(),
      'likes': likes,
    };
  }

  factory WillCardModel.fromMap(Map<String, dynamic> map) {
    return WillCardModel(
      id: map['id'] ?? '',
      author: map['author'] ?? '',
      content: map['content'] ?? '',
      questionPrompt: map['questionPrompt'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      likes: map['likes'] ?? 0,
    );
  }

  WillCardModel copyWith({
    String? id,
    String? author,
    String? content,
    String? questionPrompt,
    DateTime? createdAt,
    int? likes,
  }) {
    return WillCardModel(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      questionPrompt: questionPrompt ?? this.questionPrompt,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
    );
  }
}
