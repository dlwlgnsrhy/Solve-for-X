/// Domain model for a writing session.
class WritingSession {
  final String id;
  final String userId;
  final String startedAt;
  final String? endedAt;
  final String content;
  final int contentLength;
  final int keystrokeEventCount;
  final bool isCompleted;

  WritingSession({
    required this.id,
    required this.userId,
    required this.startedAt,
    this.endedAt,
    required this.content,
    required this.contentLength,
    required this.keystrokeEventCount,
    required this.isCompleted,
  });
}
