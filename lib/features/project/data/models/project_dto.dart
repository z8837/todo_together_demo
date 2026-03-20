class ProjectSyncResponseDto {
  const ProjectSyncResponseDto({required this.projects});

  final List<ProjectDto> projects;

  factory ProjectSyncResponseDto.fromJson(Map<String, dynamic> json) {
    final raw = json['projects'] as List<dynamic>? ?? const [];
    return ProjectSyncResponseDto(
      projects: raw
          .map((item) => ProjectDto.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

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

  factory ProjectDto.fromJson(Map<String, dynamic> json) {
    final members = json['membership'] as List<dynamic>? ?? const [];
    return ProjectDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      version: json['version'] as int,
      owner: ProjectUserDto.fromJson(json['owner'] as Map<String, dynamic>),
      membership: members
          .map(
            (item) =>
                ProjectMembershipDto.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      recentUpdateAt: json['recent_update_at'] as String?,
    );
  }
}

class ProjectMembershipDto {
  const ProjectMembershipDto({required this.user, required this.role});

  final ProjectUserDto user;
  final String role;

  factory ProjectMembershipDto.fromJson(Map<String, dynamic> json) {
    return ProjectMembershipDto(
      user: ProjectUserDto.fromJson(json['user'] as Map<String, dynamic>),
      role: json['role'] as String,
    );
  }
}

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

  factory ProjectUserDto.fromJson(Map<String, dynamic> json) {
    return ProjectUserDto(
      id: json['id'] as int,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      provider: json['provider'] as String?,
    );
  }
}
