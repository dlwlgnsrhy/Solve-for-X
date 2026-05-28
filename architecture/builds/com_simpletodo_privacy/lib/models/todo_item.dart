class TodoItem {
  final String id;
  String title;
  String category;
  bool isCompleted;

  TodoItem({
    required this.id,
    required this.title,
    required this.category,
    this.isCompleted = false,
  });
}