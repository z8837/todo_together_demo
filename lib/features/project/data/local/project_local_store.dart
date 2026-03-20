import 'dart:async';

import 'package:isar_community/isar.dart';

import '../../../../core/data/local/entities/local_project_entity.dart';
import '../../../../core/data/local/entities/local_user_entity.dart';
import '../../../../core/data/local/local_db.dart';
import '../../../../core/data/local/local_user_store.dart';
import '../../../../core/data/models/user_dto.dart';
import '../../domain/entities/project_summary.dart';
import '../models/project_dto.dart';

class ProjectLocalStore {
  ProjectLocalStore({Isar? isar, LocalUserStore? userStore})
    : _isar = isar ?? LocalDB.instance,
      _userStore = userStore ?? LocalUserStore();

  final Isar _isar;
  final LocalUserStore _userStore;

  Future<void> upsert(ProjectDto dto) async {
    await _isar.writeTxn(() async {
      await _upsertUsers(dto);
      await _isar.localProjectEntitys.putByRemoteId(_mapProjectEntity(dto));
    });
  }

  Future<void> applySync(List<ProjectDto> projects) async {
    await _isar.writeTxn(() async {
      final projectIds = <String>{};
      for (final dto in projects) {
        projectIds.add(dto.id);
        await _upsertUsers(dto);
        await _isar.localProjectEntitys.putByRemoteId(_mapProjectEntity(dto));
      }

      final existing = await _isar.localProjectEntitys.where().findAll();
      final deletedIds = existing
          .where((entity) => !projectIds.contains(entity.remoteId))
          .map((entity) => entity.id)
          .toList(growable: false);
      if (deletedIds.isNotEmpty) {
        await _isar.localProjectEntitys.deleteAll(deletedIds);
      }
    });
  }

  Future<void> removeProjects(List<String> projectIds) async {
    if (projectIds.isEmpty) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.localProjectEntitys
          .where()
          .anyOf(projectIds, (q, id) => q.remoteIdEqualTo(id))
          .deleteAll();
    });
  }

  Future<List<ProjectSummary>> readAll() async {
    final entities = await _isar.localProjectEntitys.where().findAll();
    final userIds = <int>{};
    for (final project in entities) {
      if (project.ownerUserId != null) {
        userIds.add(project.ownerUserId!);
      }
      userIds.addAll(project.members.map((member) => member.userId));
    }
    final userMap = await _userStore.loadUsersByIds(userIds);
    return entities.map((project) => _mapToDomain(project, userMap)).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<ProjectSummary?> readById(String projectId) async {
    final entity = await _isar.localProjectEntitys
        .where()
        .remoteIdEqualTo(projectId)
        .findFirst();
    if (entity == null) {
      return null;
    }
    final userIds = <int>{};
    if (entity.ownerUserId != null) {
      userIds.add(entity.ownerUserId!);
    }
    userIds.addAll(entity.members.map((member) => member.userId));
    final userMap = await _userStore.loadUsersByIds(userIds);
    return _mapToDomain(entity, userMap);
  }

  Future<String?> readRemoteIdByLocalId(int localId) async {
    final entity = await _isar.localProjectEntitys.get(localId);
    return entity?.remoteId;
  }

  Stream<List<ProjectSummary>> watchProjects() {
    final projectChanges = _isar.localProjectEntitys.where().watchLazy(
      fireImmediately: true,
    );
    return _projectStream(projectChanges);
  }

  Future<void> _upsertUsers(ProjectDto dto) async {
    await _userStore.upsertUser(_mapOwnerToUser(dto.owner));
    for (final member in dto.membership) {
      await _userStore.upsertUser(_mapMemberUserToUser(member.user));
    }
  }

  LocalProjectEntity _mapProjectEntity(ProjectDto dto) {
    return LocalProjectEntity()
      ..remoteId = dto.id
      ..name = dto.name
      ..description = dto.description
      ..version = dto.version
      ..ownerUserId = dto.owner.id
      ..recentUpdateAt = _parseDateTime(dto.recentUpdateAt)
      ..createdAt = _parseDateTime(dto.createdAt) ?? DateTime.now()
      ..updatedAt = _parseDateTime(dto.updatedAt) ?? DateTime.now()
      ..members = dto.membership
          .map(
            (member) => LocalProjectMemberEmbedded()
              ..userId = member.user.id
              ..role = member.role,
          )
          .toList(growable: false);
  }

  ProjectSummary _mapToDomain(
    LocalProjectEntity entity,
    Map<int, LocalUserEntity> userMap,
  ) {
    final owner = userMap[entity.ownerUserId ?? -1];
    final ownerUser = ProjectUser(
      id: owner?.remoteId ?? -1,
      email: owner?.email ?? '',
      nickname: owner?.nickname ?? '',
      provider: owner?.provider,
    );
    final members = entity.members
        .map((member) {
          final user = userMap[member.userId];
          return ProjectMember(
            id: member.userId,
            email: user?.email ?? '',
            nickname: user?.nickname ?? '',
            provider: user?.provider,
            role: member.role,
          );
        })
        .toList(growable: false);

    return ProjectSummary(
      id: entity.remoteId,
      remoteId: entity.remoteId,
      name: entity.name,
      description: entity.description,
      version: entity.version,
      members: members,
      owner: ownerUser,
      recentUpdateAt: entity.recentUpdateAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isFavorite: false,
    );
  }

  Stream<List<ProjectSummary>> _projectStream(Stream<void> projectChanges) {
    late final StreamController<List<ProjectSummary>> controller;
    StreamSubscription<void>? projectSub;
    StreamSubscription<void>? userSub;

    Future<void> emit() async {
      try {
        final projects = await readAll();
        if (!controller.isClosed) {
          controller.add(projects);
        }
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    controller = StreamController<List<ProjectSummary>>(
      onListen: () {
        emit();
        projectSub = projectChanges.listen((_) => emit());
        userSub = _isar.localUserEntitys.watchLazy().listen((_) => emit());
      },
      onCancel: () async {
        await projectSub?.cancel();
        await userSub?.cancel();
      },
    );

    return controller.stream;
  }

  DateTime? _parseDateTime(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  UserDto _mapOwnerToUser(ProjectUserDto owner) {
    return UserDto(
      id: owner.id,
      email: owner.email,
      nickname: owner.nickname,
      provider: owner.provider,
    );
  }

  UserDto _mapMemberUserToUser(ProjectUserDto member) {
    return UserDto(
      id: member.id,
      email: member.email,
      nickname: member.nickname,
      provider: member.provider,
    );
  }
}
