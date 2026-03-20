class ProjectSummary {
  const ProjectSummary({
    required this.id,
    required this.remoteId,
    required this.name,
    required this.description,
    required this.version,
    required this.members,
    required this.owner,
    this.recentUpdateAt,
    required this.createdAt,
    required this.updatedAt,
    required this.isFavorite,
  });

  final String id;
  final String remoteId;
  final String name;
  final String description;
  final int version;
  final List<ProjectMember> members;
  final ProjectUser owner;
  final DateTime? recentUpdateAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
}

class ProjectUser {
  const ProjectUser({
    required this.id,
    required this.email,
    required this.nickname,
    this.provider,
  });

  final int id;
  final String email;
  final String nickname;
  final String? provider;
}

class ProjectMember extends ProjectUser {
  const ProjectMember({
    required super.id,
    required super.email,
    required super.nickname,
    super.provider,
    required this.role,
  });

  final String role;
}
