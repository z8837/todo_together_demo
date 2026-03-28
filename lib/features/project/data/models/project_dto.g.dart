// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectSyncResponseDto _$ProjectSyncResponseDtoFromJson(
  Map<String, dynamic> json,
) => ProjectSyncResponseDto(
  projects: (json['projects'] as List<dynamic>)
      .map((e) => ProjectDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ProjectSyncResponseDtoToJson(
  ProjectSyncResponseDto instance,
) => <String, dynamic>{'projects': instance.projects};

ProjectDto _$ProjectDtoFromJson(Map<String, dynamic> json) => ProjectDto(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  version: (json['version'] as num).toInt(),
  owner: ProjectUserDto.fromJson(json['owner'] as Map<String, dynamic>),
  membership: (json['membership'] as List<dynamic>)
      .map((e) => ProjectMembershipDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
  recentUpdateAt: json['recent_update_at'] as String?,
);

Map<String, dynamic> _$ProjectDtoToJson(ProjectDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'version': instance.version,
      'owner': instance.owner,
      'membership': instance.membership,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'recent_update_at': instance.recentUpdateAt,
    };

ProjectMembershipDto _$ProjectMembershipDtoFromJson(
  Map<String, dynamic> json,
) => ProjectMembershipDto(
  user: ProjectUserDto.fromJson(json['user'] as Map<String, dynamic>),
  role: json['role'] as String,
);

Map<String, dynamic> _$ProjectMembershipDtoToJson(
  ProjectMembershipDto instance,
) => <String, dynamic>{'user': instance.user, 'role': instance.role};

ProjectUserDto _$ProjectUserDtoFromJson(Map<String, dynamic> json) =>
    ProjectUserDto(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      provider: json['provider'] as String?,
    );

Map<String, dynamic> _$ProjectUserDtoToJson(ProjectUserDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'nickname': instance.nickname,
      'provider': instance.provider,
    };
