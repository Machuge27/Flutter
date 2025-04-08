// models/task.dart
class Task {
  int? id;
  String title;
  String description;
  DateTime? deadline;
  String status;
  bool isEditing;
  bool isCompleted;

  Task({
    this.id,
    required this.title,
    this.description = '',
    this.deadline,
    this.status = 'Pending',
    this.isEditing = false,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'status': status,
      'isEditing': isEditing,
      'isCompleted': isCompleted,
    };
  }
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      status: json['status'],
      isEditing: json['isEditing'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

