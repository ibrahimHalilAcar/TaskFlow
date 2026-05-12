class Task {
  int? id;
  String title;
  String? description;
  bool isCompleted;
  String priority;
  DateTime createdAt;

  Task({
    this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.priority = 'medium',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'title': title,
    'description': description,
    'isCompleted': isCompleted ? 1 : 0,
    'priority': priority,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
    id: map['id'],
    title: map['title'],
    description: map['description'],
    isCompleted: map['isCompleted'] == 1,
    priority: map['priority'],
    createdAt: DateTime.parse(map['createdAt']),
  );
}