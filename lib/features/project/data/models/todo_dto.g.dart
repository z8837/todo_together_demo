// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TodoSyncResponseDto _$TodoSyncResponseDtoFromJson(Map<String, dynamic> json) =>
    TodoSyncResponseDto(
      todos: (json['todos'] as List<dynamic>)
          .map((e) => TodoDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TodoSyncResponseDtoToJson(
  TodoSyncResponseDto instance,
) => <String, dynamic>{'todos': instance.todos};

TodoDto _$TodoDtoFromJson(Map<String, dynamic> json) => TodoDto(
  id: json['id'] as String,
  project: json['project'] as String,
  title: json['title'] as String,
  status: json['status'] as String,
  kind: json['kind'] as String,
  version: (json['version'] as num).toInt(),
  createdBy: TodoUserDto.fromJson(json['created_by'] as Map<String, dynamic>),
  assignees: (json['assignees'] as List<dynamic>)
      .map((e) => TodoUserDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  isRecurring: json['is_recurring'] as bool,
  isHidden: json['is_hidden'] as bool,
  startDate: json['start_date'] as String?,
  startTime: json['start_time'] as String?,
  weekdayMask: (json['weekday_mask'] as num?)?.toInt(),
  endDate: json['end_date'] as String?,
  endTime: json['end_time'] as String?,
  alarmOffsetMinutes: (json['alarm_offset_minutes'] as num?)?.toInt(),
  completedAt: json['completed_at'] as String?,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$TodoDtoToJson(TodoDto instance) => <String, dynamic>{
  'id': instance.id,
  'project': instance.project,
  'title': instance.title,
  'status': instance.status,
  'kind': instance.kind,
  'version': instance.version,
  'created_by': instance.createdBy,
  'assignees': instance.assignees,
  'is_recurring': instance.isRecurring,
  'is_hidden': instance.isHidden,
  'start_date': instance.startDate,
  'start_time': instance.startTime,
  'weekday_mask': instance.weekdayMask,
  'end_date': instance.endDate,
  'end_time': instance.endTime,
  'alarm_offset_minutes': instance.alarmOffsetMinutes,
  'completed_at': instance.completedAt,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};

TodoUserDto _$TodoUserDtoFromJson(Map<String, dynamic> json) => TodoUserDto(
  id: (json['id'] as num).toInt(),
  email: json['email'] as String,
  nickname: json['nickname'] as String,
);

Map<String, dynamic> _$TodoUserDtoToJson(TodoUserDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'nickname': instance.nickname,
    };
