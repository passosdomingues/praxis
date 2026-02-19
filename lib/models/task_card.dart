class TaskCard {
  final int? id;
  final int sprintId;
  int columnId; // 0: Backlog, 1: ToDo, 2: InProgress, 3: Done
  final String title;
  final String description;
  final int labelColorIndex; // 0-7
  final int points; // Fibonacci
  final DateTime? dueDate;
  final bool isAi;

  TaskCard({
    this.id,
    required this.sprintId,
    required this.columnId,
    required this.title,
    required this.description,
    required this.labelColorIndex,
    required this.points,
    this.dueDate,
    this.isAi = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sprintId': sprintId,
      'columnId': columnId,
      'title': title,
      'description': description,
      'labelColorIndex': labelColorIndex,
      'points': points,
      'dueDate': dueDate?.toIso8601String(),
      'isAi': isAi ? 1 : 0,
    };
  }

  factory TaskCard.fromMap(Map<String, dynamic> map) {
    return TaskCard(
      id: map['id'],
      sprintId: map['sprintId'],
      columnId: map['columnId'],
      title: map['title'],
      description: map['description'],
      labelColorIndex: map['labelColorIndex'],
      points: map['points'],
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      isAi: map['isAi'] == 1,
    );
  }

  TaskCard copyWith({
    int? id,
    int? sprintId,
    int? columnId,
    String? title,
    String? description,
    int? labelColorIndex,
    int? points,
    DateTime? dueDate,
    bool? isAi,
  }) {
    return TaskCard(
      id: id ?? this.id,
      sprintId: sprintId ?? this.sprintId,
      columnId: columnId ?? this.columnId,
      title: title ?? this.title,
      description: description ?? this.description,
      labelColorIndex: labelColorIndex ?? this.labelColorIndex,
      points: points ?? this.points,
      dueDate: dueDate ?? this.dueDate,
      isAi: isAi ?? this.isAi,
    );
  }
}
