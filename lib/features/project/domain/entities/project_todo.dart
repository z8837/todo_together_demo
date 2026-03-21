class ProjectTodo {
  static const Object _unset = Object();

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
    String? id,
    String? projectId,
    String? title,
    String? status,
    String? kind,
    int? version,
    TodoUser? createdBy,
    bool? isRecurring,
    bool? isHidden,
    Object? startDate = _unset,
    Object? startTime = _unset,
    Object? weekdayMask = _unset,
    Object? endDate = _unset,
    Object? endTime = _unset,
    Object? alarmOffsetMinutes = _unset,
    Object? completedAt = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TodoUser>? assignees,
  }) {
    return ProjectTodo(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      status: status ?? this.status,
      kind: kind ?? this.kind,
      version: version ?? this.version,
      createdBy: createdBy ?? this.createdBy,
      isRecurring: isRecurring ?? this.isRecurring,
      isHidden: isHidden ?? this.isHidden,
      startDate: identical(startDate, _unset)
          ? this.startDate
          : startDate as DateTime?,
      startTime: identical(startTime, _unset)
          ? this.startTime
          : startTime as String?,
      weekdayMask: identical(weekdayMask, _unset)
          ? this.weekdayMask
          : weekdayMask as int?,
      endDate: identical(endDate, _unset) ? this.endDate : endDate as DateTime?,
      endTime: identical(endTime, _unset) ? this.endTime : endTime as String?,
      alarmOffsetMinutes: identical(alarmOffsetMinutes, _unset)
          ? this.alarmOffsetMinutes
          : alarmOffsetMinutes as int?,
      completedAt: identical(completedAt, _unset)
          ? this.completedAt
          : completedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignees: assignees ?? this.assignees,
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
