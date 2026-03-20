class ProjectTodo {
  const ProjectTodo({
    required this.id,
    required this.projectId,
    required this.title,
    required this.status,
    required this.kind,
    required this.version,
    required this.createdBy,
    required this.isRecurring,
    required this.isHidden,
    this.startDate,
    this.startTime,
    this.weekdayMask,
    this.endDate,
    this.endTime,
    this.alarmOffsetMinutes,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.assignees,
  });

  final String id;
  final String projectId;
  final String title;
  final String status;
  final String kind;
  final int version;
  final TodoUser createdBy;
  final bool isRecurring;
  final bool isHidden;
  final DateTime? startDate;
  final String? startTime;
  final int? weekdayMask;
  final DateTime? endDate;
  final String? endTime;
  final int? alarmOffsetMinutes;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TodoUser> assignees;

  bool get isCompleted => status.toLowerCase() == 'done' || completedAt != null;

  ProjectTodo copyWith({
    String? status,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return ProjectTodo(
      id: id,
      projectId: projectId,
      title: title,
      status: status ?? this.status,
      kind: kind,
      version: version,
      createdBy: createdBy,
      isRecurring: isRecurring,
      isHidden: isHidden,
      startDate: startDate,
      startTime: startTime,
      weekdayMask: weekdayMask,
      endDate: endDate,
      endTime: endTime,
      alarmOffsetMinutes: alarmOffsetMinutes,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignees: assignees,
    );
  }
}

class TodoUser {
  const TodoUser({
    required this.id,
    required this.email,
    required this.nickname,
  });

  final int id;
  final String email;
  final String nickname;
}
