enum TaskPriority { low, medium, high, critical }
enum TaskStatus { pending, inProgress, completed, skipped }

class CareTask {
  final String id;
  final String carePlanId;
  final String assignedUserId;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? completedAt;

  CareTask({
    required this.id,
    required this.carePlanId,
    required this.assignedUserId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.status,
    this.completedAt,
  });

  CareTask copyWith({
    String? id,
    String? carePlanId,
    String? assignedUserId,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? completedAt,
  }) {
    return CareTask(
      id: id ?? this.id,
      carePlanId: carePlanId ?? this.carePlanId,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
