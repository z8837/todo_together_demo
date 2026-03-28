import 'package:json_annotation/json_annotation.dart';

part 'todo_dto.g.dart';

@JsonSerializable()
class TodoSyncResponseDto {
  const TodoSyncResponseDto({required this.todos});

  final List<TodoDto> todos;

  factory TodoSyncResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TodoSyncResponseDtoFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake)
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

  factory TodoDto.fromJson(Map<String, dynamic> json) =>
      _$TodoDtoFromJson(json);
}

@JsonSerializable()
class TodoUserDto {
  const TodoUserDto({
    required this.id,
    required this.email,
    required this.nickname,
  });

  final int id;
  final String email;
  final String nickname;

  factory TodoUserDto.fromJson(Map<String, dynamic> json) =>
      _$TodoUserDtoFromJson(json);
}
