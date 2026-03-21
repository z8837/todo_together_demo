class ProjectSummary {
  static const Object _unset = Object();

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

  ProjectSummary copyWith({
    String? id,
    String? remoteId,
    String? name,
    String? description,
    int? version,
    List<ProjectMember>? members,
    ProjectUser? owner,
    Object? recentUpdateAt = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
  }) {
    return ProjectSummary(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      members: members ?? this.members,
      owner: owner ?? this.owner,
      recentUpdateAt: identical(recentUpdateAt, _unset)
          ? this.recentUpdateAt
          : recentUpdateAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
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
