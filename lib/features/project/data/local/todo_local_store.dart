import 'dart:async';

import 'package:isar_community/isar.dart';

import '../../../../core/data/local/entities/local_todo_entity.dart';
import '../../../../core/data/local/entities/local_user_entity.dart';
import '../../../../core/data/local/local_db.dart';
import '../../../../core/data/local/local_user_store.dart';
import '../../../../core/data/models/user_dto.dart';
import '../../domain/entities/project_todo.dart';
import '../models/todo_dto.dart';

class TodoLocalStore {
  TodoLocalStore({Isar? isar, LocalUserStore? userStore})
    : _isar = isar ?? LocalDB.instance,
      _userStore = userStore ?? LocalUserStore();

  final Isar _isar;
  final LocalUserStore _userStore;

  Future<void> upsert(TodoDto dto) async {
    await _isar.writeTxn(() async {
      await _upsertUsers(dto);
      await _isar.localTodoEntitys.putByRemoteId(_mapEntity(dto));
    });
  }

  Future<void> applySync(List<TodoDto> todos) async {
    await _isar.writeTxn(() async {
      final todoIds = <String>{};
      for (final dto in todos) {
        todoIds.add(dto.id);
        await _upsertUsers(dto);
        await _isar.localTodoEntitys.putByRemoteId(_mapEntity(dto));
      }

      final existing = await _isar.localTodoEntitys.where().findAll();
      final deletedIds = existing
          .where((entity) => !todoIds.contains(entity.remoteId))
          .map((entity) => entity.id)
          .toList(growable: false);
      if (deletedIds.isNotEmpty) {
        await _isar.localTodoEntitys.deleteAll(deletedIds);
      }
    });
  }

  Future<void> removeByIds(List<String> todoIds) async {
    if (todoIds.isEmpty) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.localTodoEntitys
          .where()
          .anyOf(todoIds, (q, id) => q.remoteIdEqualTo(id))
          .deleteAll();
    });
  }

  Future<void> removeByProjectIds(List<String> projectIds) async {
    if (projectIds.isEmpty) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.localTodoEntitys
          .where()
          .anyOf(projectIds, (q, projectId) => q.projectIdEqualTo(projectId))
          .deleteAll();
    });
  }

  Future<List<ProjectTodo>> readTodos({String? projectId}) async {
    final query = _isar.localTodoEntitys.where();
    final entities = projectId == null
        ? await query.findAll()
        : await query.projectIdEqualTo(projectId).findAll();

    final userIds = <int>{};
    for (final todo in entities) {
      userIds.add(todo.createdByUserId);
      userIds.addAll(todo.assigneeIds);
    }
    final userMap = await _userStore.loadUsersByIds(userIds);
    return entities.map((todo) => _mapToDomain(todo, userMap)).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<LocalTodoEntity?> readByRemoteId(String todoId) {
    return _isar.localTodoEntitys.getByRemoteId(todoId);
  }

  Future<ProjectTodo?> updateStatusLocal({
    required String todoId,
    required String nextStatus,
  }) async {
    final entity = await _isar.localTodoEntitys
        .where()
        .remoteIdEqualTo(todoId)
        .findFirst();
    if (entity == null) {
      return null;
    }
    entity.status = nextStatus;
    entity.completedAt = nextStatus == 'done' ? DateTime.now() : null;
    entity.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.localTodoEntitys.put(entity);
    });
    final userMap = await _userStore.loadUsersByIds({
      entity.createdByUserId,
      ...entity.assigneeIds,
    });
    return _mapToDomain(entity, userMap);
  }

  Future<ProjectTodo?> updateVisibilityLocal({
    required String todoId,
    required bool isHidden,
  }) async {
    final entity = await _isar.localTodoEntitys
        .where()
        .remoteIdEqualTo(todoId)
        .findFirst();
    if (entity == null) {
      return null;
    }
    entity.isHidden = isHidden;
    entity.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.localTodoEntitys.put(entity);
    });
    final userMap = await _userStore.loadUsersByIds({
      entity.createdByUserId,
      ...entity.assigneeIds,
    });
    return _mapToDomain(entity, userMap);
  }

  Future<void> updateHidden({
    required String todoId,
    required bool isHidden,
  }) async {
    await updateVisibilityLocal(todoId: todoId, isHidden: isHidden);
  }

  Stream<List<ProjectTodo>> watchTodos({String? projectId}) {
    final queryBuilder = _isar.localTodoEntitys.where();
    final stream =
        (projectId == null
                ? queryBuilder
                : queryBuilder.projectIdEqualTo(projectId))
            .watchLazy(fireImmediately: true);
    return _todoStream(
      todoChanges: stream,
      loader: () => readTodos(projectId: projectId),
    );
  }

  Future<void> _upsertUsers(TodoDto dto) async {
    await _userStore.upsertUser(_mapTodoUser(dto.createdBy));
    for (final assignee in dto.assignees) {
      await _userStore.upsertUser(_mapAssignee(assignee));
    }
  }

  LocalTodoEntity _mapEntity(TodoDto dto) {
    return LocalTodoEntity()
      ..remoteId = dto.id
      ..projectId = dto.project
      ..title = dto.title
      ..status = dto.status
      ..kind = _normalizeKind(dto.kind)
      ..version = dto.version
      ..createdByUserId = dto.createdBy.id
      ..isRecurring = dto.isRecurring
      ..isHidden = dto.isHidden
      ..startDate = _parseDate(dto.startDate)
      ..startTime = dto.startTime
      ..weekdayMask = dto.weekdayMask
      ..endDate = _parseDate(dto.endDate)
      ..endTime = dto.endTime
      ..alarmOffsetMinutes = dto.alarmOffsetMinutes
      ..completedAt = _parseDateTime(dto.completedAt)
      ..createdAt = _parseDateTime(dto.createdAt) ?? DateTime.now()
      ..updatedAt = _parseDateTime(dto.updatedAt) ?? DateTime.now()
      ..assigneeIds = dto.assignees.map((assignee) => assignee.id).toList();
  }

  ProjectTodo _mapToDomain(
    LocalTodoEntity entity,
    Map<int, LocalUserEntity> userMap,
  ) {
    final creator = userMap[entity.createdByUserId];
    final createdBy = TodoUser(
      id: creator?.remoteId ?? -1,
      email: creator?.email ?? '',
      nickname: creator?.nickname ?? '',
    );
    final assignees = entity.assigneeIds
        .map((userId) {
          final user = userMap[userId];
          return TodoUser(
            id: user?.remoteId ?? userId,
            email: user?.email ?? '',
            nickname: user?.nickname ?? '',
          );
        })
        .toList(growable: false);

    return ProjectTodo(
      id: entity.remoteId,
      projectId: entity.projectId,
      title: entity.title,
      status: entity.status,
      kind: _normalizeKind(entity.kind),
      version: entity.version,
      createdBy: createdBy,
      isRecurring: entity.isRecurring,
      isHidden: entity.isHidden,
      startDate: entity.startDate,
      startTime: entity.startTime,
      weekdayMask: entity.weekdayMask,
      endDate: entity.endDate,
      endTime: entity.endTime,
      alarmOffsetMinutes: entity.alarmOffsetMinutes,
      completedAt: entity.completedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      assignees: assignees,
    );
  }

  Stream<List<ProjectTodo>> _todoStream({
    required Stream<void> todoChanges,
    required Future<List<ProjectTodo>> Function() loader,
  }) {
    late final StreamController<List<ProjectTodo>> controller;
    StreamSubscription<void>? todoSub;
    StreamSubscription<void>? userSub;

    Future<void> emit() async {
      try {
        final todos = await loader();
        if (!controller.isClosed) {
          controller.add(todos);
        }
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    controller = StreamController<List<ProjectTodo>>(
      onListen: () {
        emit();
        todoSub = todoChanges.listen((_) => emit());
        userSub = _isar.localUserEntitys.watchLazy().listen((_) => emit());
      },
      onCancel: () async {
        await todoSub?.cancel();
        await userSub?.cancel();
      },
    );

    return controller.stream;
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  DateTime? _parseDateTime(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  String _normalizeKind(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? 'schedule' : trimmed;
  }

  UserDto _mapTodoUser(TodoUserDto dto) {
    return UserDto(id: dto.id, email: dto.email, nickname: dto.nickname);
  }

  UserDto _mapAssignee(TodoUserDto dto) {
    return UserDto(id: dto.id, email: dto.email, nickname: dto.nickname);
  }
}
