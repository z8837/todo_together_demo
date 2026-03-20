class TodoSyncResponseDto {
  const TodoSyncResponseDto({required this.todos});

  final List<TodoDto> todos;

  factory TodoSyncResponseDto.fromJson(Map<String, dynamic> json) {
    final raw = json['todos'] as List<dynamic>? ?? const [];
    return TodoSyncResponseDto(
      todos: raw
          .map((item) => TodoDto.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class TodoDto {
  const TodoDto({
    required this.id,
    required this.project,
    required this.title,
    required this.status,
    required this.kind,
    required this.version,
    required this.createdBy,
    required this.assignees,
    required this.isRecurring,
    required this.isHidden,
    required this.startDate,
    required this.startTime,
    required this.weekdayMask,
    required this.endDate,
    required this.endTime,
    required this.alarmOffsetMinutes,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String project;
  final String title;
  final String status;
  final String kind;
  final int version;
  final TodoUserDto createdBy;
  final List<TodoUserDto> assignees;
  final bool isRecurring;
  final bool isHidden;
  final String? startDate;
  final String? startTime;
  final int? weekdayMask;
  final String? endDate;
  final String? endTime;
  final int? alarmOffsetMinutes;
  final String? completedAt;
  final String createdAt;
  final String updatedAt;

  factory TodoDto.fromJson(Map<String, dynamic> json) {
    final assigneeRaw = json['assignees'] as List<dynamic>? ?? const [];
    return TodoDto(
      id: json['id'] as String,
      project: json['project'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      kind: json['kind'] as String,
      version: json['version'] as int,
      createdBy: TodoUserDto.fromJson(
        json['created_by'] as Map<String, dynamic>,
      ),
      assignees: assigneeRaw
          .map((item) => TodoUserDto.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      isRecurring: json['is_recurring'] as bool? ?? false,
      isHidden: json['is_hidden'] as bool? ?? false,
      startDate: json['start_date'] as String?,
      startTime: json['start_time'] as String?,
      weekdayMask: json['weekday_mask'] as int?,
      endDate: json['end_date'] as String?,
      endTime: json['end_time'] as String?,
      alarmOffsetMinutes: json['alarm_offset_minutes'] as int?,
      completedAt: json['completed_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

class TodoUserDto {
  const TodoUserDto({
    required this.id,
    required this.email,
    required this.nickname,
  });

  final int id;
  final String email;
  final String nickname;

  factory TodoUserDto.fromJson(Map<String, dynamic> json) {
    return TodoUserDto(
      id: json['id'] as int,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
    );
  }
}
