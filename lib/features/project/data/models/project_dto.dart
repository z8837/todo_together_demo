import 'package:json_annotation/json_annotation.dart';

part 'project_dto.g.dart';

@JsonSerializable()
class ProjectSyncResponseDto {
  const ProjectSyncResponseDto({required this.projects});

  final List<ProjectDto> projects;

  factory ProjectSyncResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ProjectSyncResponseDtoFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ProjectDto {
  const ProjectDto({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.owner,
    required this.membership,
    required this.createdAt,
    required this.updatedAt,
    this.recentUpdateAt,
  });

  final String id;
  final String name;
  final String description;
  final int version;
  final ProjectUserDto owner;
  final List<ProjectMembershipDto> membership;
  final String createdAt;
  final String updatedAt;
  final String? recentUpdateAt;

  factory ProjectDto.fromJson(Map<String, dynamic> json) =>
      _$ProjectDtoFromJson(json);
}

@JsonSerializable()
class ProjectMembershipDto {
  const ProjectMembershipDto({required this.user, required this.role});

  final ProjectUserDto user;
  final String role;

  factory ProjectMembershipDto.fromJson(Map<String, dynamic> json) =>
      _$ProjectMembershipDtoFromJson(json);
}

@JsonSerializable()
class ProjectUserDto {
  const ProjectUserDto({
    required this.id,
    required this.email,
    required this.nickname,
    this.provider,
  });

  final int id;
  final String email;
  final String nickname;
  final String? provider;

  factory ProjectUserDto.fromJson(Map<String, dynamic> json) =>
      _$ProjectUserDtoFromJson(json);
}
