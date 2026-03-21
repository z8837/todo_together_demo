import '../../../../core/data/local/local_user_store.dart';
import '../../../../core/data/local/local_sync_state_store.dart';
import '../../../../core/data/models/user_dto.dart';
import '../../../../core/network/result/api_error.dart';
import '../../../../core/network/simple_result.dart';
import '../../domain/entities/project_summary.dart';
import '../../domain/entities/project_todo.dart';
import '../../domain/repositories/project_repository.dart' as domain;
import '../datasources/project_api.dart';
import '../local/project_local_store.dart';
import '../local/todo_local_store.dart';
import '../models/project_dto.dart';
import '../models/todo_dto.dart';

typedef CurrentProjectUserReader = UserDto? Function();

class ProjectRepository implements domain.ProjectRepository {
  ProjectRepository({
    ProjectApi? api,
    ProjectLocalStore? projectLocalStore,
    TodoLocalStore? todoLocalStore,
    LocalUserStore? localUserStore,
    CurrentProjectUserReader? readCurrentUser,
  }) : _api = api ?? ProjectApi.create(),
       _projectLocalStore = projectLocalStore ?? ProjectLocalStore(),
       _todoLocalStore = todoLocalStore ?? TodoLocalStore(),
       _localUserStore = localUserStore ?? LocalUserStore(),
       _readCurrentUser = readCurrentUser ?? _emptyCurrentUser;

  final ProjectApi _api;
  final ProjectLocalStore _projectLocalStore;
  final TodoLocalStore _todoLocalStore;
  final LocalUserStore _localUserStore;
  final CurrentProjectUserReader _readCurrentUser;

  static UserDto? _emptyCurrentUser() => null;

  @override
  Future<SimpleResult<List<ProjectSummary>, ApiError>> fetchProjects({
    required String accessToken,
  }) async {
    try {
      final response = await _api.syncProjects('Bearer $accessToken', const {
        'source': 'demo',
      });
      final deletedProjectIds = await LocalSyncStateStore.deletedProjectIds();
      final filteredProjects = response.projects
          .where((project) => !deletedProjectIds.contains(project.id))
          .toList(growable: false);
      await _projectLocalStore.applySync(filteredProjects);
      return SimpleResult.success(
        filteredProjects.map(_mapProject).toList(growable: false),
      );
    } catch (error) {
      return SimpleResult.failure(
        ApiError(message: 'fetch_projects_failed: $error'),
      );
    }
  }

  @override
  Future<SimpleResult<List<ProjectTodo>, ApiError>> fetchTodos({
    required String accessToken,
  }) async {
    try {
      final response = await _api.syncTodos('Bearer $accessToken', const {
        'source': 'demo',
      });
      final deletedProjectIds = await LocalSyncStateStore.deletedProjectIds();
      final deletedTodoIds = await LocalSyncStateStore.deletedTodoIds();
      final filteredTodos = response.todos
          .where(
            (todo) =>
                !deletedTodoIds.contains(todo.id) &&
                !deletedProjectIds.contains(todo.project),
          )
          .toList(growable: false);
      await _todoLocalStore.applySync(filteredTodos);
      return SimpleResult.success(
        filteredTodos.map(_mapTodo).toList(growable: false),
      );
    } catch (error) {
      return SimpleResult.failure(
        ApiError(message: 'fetch_todos_failed: $error'),
      );
    }
  }

  @override
  Future<SimpleResult<ProjectSummary, ApiError>> createProject({
    required String accessToken,
    required String name,
    String? description,
  }) async {
    final currentUser = await _ensureCurrentUserStored();
    if (currentUser == null) {
      return SimpleResult.failure(const ApiError(message: 'unauthorized'));
    }

    final temporaryId = _nextTemporaryId('project');
    final optimisticProject = _buildOptimisticProject(
      temporaryId: temporaryId,
      currentUser: currentUser,
      name: name,
      description: description,
    );
    await _projectLocalStore.upsertDomain(optimisticProject);

    try {
      final response = await _api.createProject('Bearer $accessToken', {
        'name': name,
        'description': description ?? '',
      });
      final confirmed = _mapProject(response);
      await _projectLocalStore.replaceRemoteId(
        currentRemoteId: temporaryId,
        project: confirmed,
      );
      return SimpleResult.success(confirmed);
    } catch (error) {
      await _projectLocalStore.removeProjects([temporaryId]);
      return SimpleResult.failure(
        ApiError(message: 'create_project_failed: $error'),
      );
    }
  }

  @override
  Future<SimpleResult<ProjectSummary, ApiError>> updateProject({
    required String accessToken,
    required String projectId,
    required String name,
    String? description,
  }) async {
    final previous = await _projectLocalStore.readById(projectId);
    if (previous != null) {
      final now = DateTime.now();
      final optimistic = previous.copyWith(
        name: name,
        description: description ?? '',
        version: previous.version + 1,
        recentUpdateAt: now,
        updatedAt: now,
      );
      await _projectLocalStore.upsertDomain(optimistic);
    }

    try {
      final response = await _api.updateProject(
        'Bearer $accessToken',
        projectId,
        {'name': name, 'description': description ?? ''},
      );
      final confirmed = _mapProject(response);
      await _projectLocalStore.upsertDomain(confirmed);
      return SimpleResult.success(confirmed);
    } catch (error) {
      if (previous != null) {
        await _projectLocalStore.upsertDomain(previous);
      }
      return SimpleResult.failure(
        ApiError(message: 'update_project_failed: $error'),
      );
    }
  }

  @override
  Future<SimpleResult<void, ApiError>> deleteProject({
    required String accessToken,
    required String projectId,
  }) async {
    final previousProject = await _projectLocalStore.readById(projectId);
    final previousTodos = await _todoLocalStore.readTodos(projectId: projectId);
    final deletedTodoIds = previousTodos
        .map((todo) => todo.id)
        .toList(growable: false);

    if (previousProject != null) {
      await LocalSyncStateStore.markProjectDeleted(projectId);
      await LocalSyncStateStore.markTodosDeleted(deletedTodoIds);
      await _projectLocalStore.removeProjects([projectId]);
      await _todoLocalStore.removeByProjectIds([projectId]);
    }

    try {
      await _api.deleteProject('Bearer $accessToken', projectId);
      return SimpleResult.success<void, ApiError>(null);
    } catch (error) {
      if (previousProject != null) {
        await LocalSyncStateStore.unmarkProjectDeleted(projectId);
        await LocalSyncStateStore.unmarkTodosDeleted(deletedTodoIds);
        await _projectLocalStore.upsertDomain(previousProject);
      }
      if (previousTodos.isNotEmpty) {
        await _todoLocalStore.upsertDomains(previousTodos);
      }
      return SimpleResult.failure(
        ApiError(message: 'delete_project_failed: $error'),
      );
    }
  }

  @override
  Future<SimpleResult<List<ProjectUser>, ApiError>> searchUsers({
    required String accessToken,
    required String query,
    int limit = 10,
  }) async {
    try {
      final response = await _api.searchUsers(
        'Bearer $accessToken',
        query,
        limit,
      );
      final users = response
          .map(
            (user) => ProjectUser(
              id: user.id,
              email: user.email,
              nickname: user.nickname,
              provider: user.provider,
            ),
          )
          .toList(growable: false);
      await _localUserStore.upsertUsers(
        response
            .map(
              (user) => UserDto(
                id: user.id,
                email: user.email,
                nickname: user.nickname,
                provider: user.provider,
              ),
            )
            .toList(growable: false),
      );
      return SimpleResult.success(users);
    } catch (error) {
      return SimpleResult.failure(
        ApiError(message: 'search_users_failed: $error'),
      );
    }
  }

  @override
  Future<SimpleResult<void, ApiError>> inviteProjectMember({
    required String accessToken,
    required String projectId,
    required int userId,
    String role = 'writer',
  }) async {
    final previousProject = await _projectLocalStore.readById(projectId);
    if (previousProject != null) {
      final optimistic = await _applyInvite(
        project: previousProject,
        userId: userId,
        role: role,
      );
      await _projectLocalStore.upsertDomain(optimistic);
    }

    try {
      await _api.createProjectInvite('Bearer $accessToken', projectId, {
        'user_id': userId,
        'role': role,
      });
      final synced = await _api.syncProjects('Bearer $accessToken', const {
        'source': 'demo',
      });
      final deletedProjectIds = await LocalSyncStateStore.deletedProjectIds();
      await _projectLocalStore.applySync(
        synced.projects
            .where((project) => !deletedProjectIds.contains(project.id))
            .toList(growable: false),
      );
      return SimpleResult.success<void, ApiError>(null);
    } catch (error) {
      if (previousProject != null) {
        await _projectLocalStore.upsertDomain(previousProject);
      }
      return SimpleResult.failure(
        ApiError(message: 'invite_project_member_failed: $error'),
      );
    }
  }

  @override
  Future<SimpleResult<ProjectTodo, ApiError>> createTodo({
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final currentUser = await _ensureCurrentUserStored();
    if (currentUser == null) {
      return SimpleResult.failure(const ApiError(message: 'unauthorized'));
    }

    final temporaryId = _nextTemporaryId('todo');
    final optimisticTodo = await _buildOptimisticTodo(
      temporaryId: temporaryId,
      body: body,
      currentUser: currentUser,
    );
    await _todoLocalStore.upsertDomain(optimisticTodo);

    try {
      final response = await _api.createTodo('Bearer $accessToken', body);
      final confirmed = _mapTodo(response);
      await _todoLocalStore.replaceRemoteId(
        currentRemoteId: temporaryId,
        todo: confirmed,
      );
      return SimpleResult.success(confirmed);
    } catch (error) {
      await _todoLocalStore.removeByIds([temporaryId]);
      return SimpleResult.failure(
        ApiError(message: 'create_todo_failed: $error'),
      );
    }
  }

  @override
  Future<SimpleResult<ProjectTodo, ApiError>> updateTodo({
    required String accessToken,
    required String todoId,
    required Map<String, dynamic> body,
  }) async {
    final previous = await _todoLocalStore.readTodoById(todoId);
    if (previous != null) {
      final optimistic = await _applyTodoPatch(previous, body);
      await _todoLocalStore.upsertDomain(optimistic);
    }

    try {
      final response = await _api.updateTodo(
        'Bearer $accessToken',
        todoId,
        body,
      );
      final confirmed = _mapTodo(response);
      await _todoLocalStore.upsertDomain(confirmed);
      return SimpleResult.success(confirmed);
    } catch (error) {
      if (previous != null) {
        await _todoLocalStore.upsertDomain(previous);
      }
      return SimpleResult.failure(
        ApiError(message: 'update_todo_failed: $error'),
      );
    }
  }

  @override
  Future<SimpleResult<ProjectTodo, ApiError>> updateTodoStatus({
    required String accessToken,
    required String todoId,
    required String nextStatus,
  }) {
    return updateTodo(
      accessToken: accessToken,
      todoId: todoId,
      body: {'status': nextStatus},
    );
  }

  @override
  Future<SimpleResult<bool, ApiError>> updateTodoVisibility({
    required String accessToken,
    required String todoId,
    required bool isHidden,
  }) async {
    final result = await updateTodo(
      accessToken: accessToken,
      todoId: todoId,
      body: {'is_hidden': isHidden},
    );
    if (result.isSuccess) {
      return SimpleResult.success(true);
    }
    return SimpleResult.failure(result.failureData!);
  }

  @override
  Future<SimpleResult<void, ApiError>> deleteTodo({
    required String accessToken,
    required String todoId,
  }) async {
    final previous = await _todoLocalStore.readTodoById(todoId);
    if (previous != null) {
      await LocalSyncStateStore.markTodoDeleted(todoId);
      await _todoLocalStore.removeByIds([todoId]);
    }

    try {
      await _api.deleteTodo('Bearer $accessToken', todoId);
      return SimpleResult.success<void, ApiError>(null);
    } catch (error) {
      if (previous != null) {
        await LocalSyncStateStore.unmarkTodoDeleted(todoId);
        await _todoLocalStore.upsertDomain(previous);
      }
      return SimpleResult.failure(
        ApiError(message: 'delete_todo_failed: $error'),
      );
    }
  }

  @override
  Future<void> toggleFavoriteProject(String projectId) async {}

  Future<UserDto?> _ensureCurrentUserStored() async {
    final currentUser = _readCurrentUser();
    if (currentUser == null) {
      return null;
    }
    await _localUserStore.upsertUsers([currentUser]);
    return currentUser;
  }

  ProjectSummary _buildOptimisticProject({
    required String temporaryId,
    required UserDto currentUser,
    required String name,
    String? description,
  }) {
    final now = DateTime.now();
    return ProjectSummary(
      id: temporaryId,
      remoteId: temporaryId,
      name: name.trim(),
      description: (description ?? '').trim(),
      version: 1,
      members: const [],
      owner: _mapProjectUserFromDto(currentUser),
      recentUpdateAt: now,
      createdAt: now,
      updatedAt: now,
      isFavorite: false,
    );
  }

  Future<ProjectSummary> _applyInvite({
    required ProjectSummary project,
    required int userId,
    required String role,
  }) async {
    if (project.members.any((member) => member.id == userId)) {
      return project;
    }

    final userMap = await _localUserStore.loadUsersByIds([userId]);
    final invited = userMap[userId];
    final nextMember = ProjectMember(
      id: invited?.remoteId ?? userId,
      email: invited?.email ?? '',
      nickname: invited?.nickname ?? '',
      provider: invited?.provider,
      role: role,
    );
    final now = DateTime.now();
    return project.copyWith(
      members: [...project.members, nextMember],
      version: project.version + 1,
      recentUpdateAt: now,
      updatedAt: now,
    );
  }

  Future<ProjectTodo> _buildOptimisticTodo({
    required String temporaryId,
    required Map<String, dynamic> body,
    required UserDto currentUser,
  }) async {
    final now = DateTime.now();
    final status = _readString(body, 'status', fallback: 'todo');
    final assigneeIds = _parseUserIds(body['assignees']);
    final assigneeUsers = await _localUserStore.loadUsersByIds(assigneeIds);
    return ProjectTodo(
      id: temporaryId,
      projectId: _readString(body, 'project'),
      title: _readString(body, 'title'),
      status: status,
      kind: _readString(body, 'kind', fallback: 'schedule'),
      version: 1,
      createdBy: _mapTodoUserFromDto(currentUser),
      isRecurring: body['is_recurring'] == true,
      isHidden: body['is_hidden'] == true,
      startDate: _parseApiDate(body['start_date']),
      startTime: _parseNullableString(body['start_time']),
      weekdayMask: _parseNullableInt(body['weekday_mask']),
      endDate: _parseApiDate(body['end_date']),
      endTime: _parseNullableString(body['end_time']),
      alarmOffsetMinutes: _parseNullableInt(body['alarm_offset_minutes']),
      completedAt: status.toLowerCase() == 'done' ? now : null,
      createdAt: now,
      updatedAt: now,
      assignees: _resolveTodoUsers(assigneeIds, assigneeUsers),
    );
  }

  Future<ProjectTodo> _applyTodoPatch(
    ProjectTodo previous,
    Map<String, dynamic> body,
  ) async {
    final assigneeIds = body.containsKey('assignees')
        ? _parseUserIds(body['assignees'])
        : previous.assignees
              .map((assignee) => assignee.id)
              .toList(growable: false);
    final assigneeUsers = body.containsKey('assignees')
        ? await _localUserStore.loadUsersByIds(assigneeIds)
        : const <int, dynamic>{};
    final nextStatus = body.containsKey('status')
        ? _readString(body, 'status', fallback: previous.status)
        : previous.status;

    return previous.copyWith(
      projectId: body.containsKey('project')
          ? _readString(body, 'project', fallback: previous.projectId)
          : previous.projectId,
      title: body.containsKey('title')
          ? _readString(body, 'title', fallback: previous.title)
          : previous.title,
      status: nextStatus,
      kind: body.containsKey('kind')
          ? _readString(body, 'kind', fallback: previous.kind)
          : previous.kind,
      version: previous.version + 1,
      isRecurring: body.containsKey('is_recurring')
          ? body['is_recurring'] == true
          : previous.isRecurring,
      isHidden: body.containsKey('is_hidden')
          ? body['is_hidden'] == true
          : previous.isHidden,
      startDate: body.containsKey('start_date')
          ? _parseApiDate(body['start_date'])
          : previous.startDate,
      startTime: body.containsKey('start_time')
          ? _parseNullableString(body['start_time'])
          : previous.startTime,
      weekdayMask: body.containsKey('weekday_mask')
          ? _parseNullableInt(body['weekday_mask'])
          : previous.weekdayMask,
      endDate: body.containsKey('end_date')
          ? _parseApiDate(body['end_date'])
          : previous.endDate,
      endTime: body.containsKey('end_time')
          ? _parseNullableString(body['end_time'])
          : previous.endTime,
      alarmOffsetMinutes: body.containsKey('alarm_offset_minutes')
          ? _parseNullableInt(body['alarm_offset_minutes'])
          : previous.alarmOffsetMinutes,
      completedAt: body.containsKey('status')
          ? (nextStatus.toLowerCase() == 'done' ? DateTime.now() : null)
          : previous.completedAt,
      updatedAt: DateTime.now(),
      assignees: body.containsKey('assignees')
          ? _resolveTodoUsers(assigneeIds, assigneeUsers)
          : previous.assignees,
    );
  }

  String _nextTemporaryId(String prefix) {
    return 'local-$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }

  String _readString(
    Map<String, dynamic> body,
    String key, {
    String fallback = '',
  }) {
    final raw = '${body[key] ?? fallback}'.trim();
    return raw.isEmpty ? fallback : raw;
  }

  String? _parseNullableString(Object? raw) {
    final value = '$raw'.trim();
    if (raw == null || value.isEmpty || value.toLowerCase() == 'null') {
      return null;
    }
    return value;
  }

  DateTime? _parseApiDate(Object? raw) {
    final value = _parseNullableString(raw);
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  int? _parseNullableInt(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is int) {
      return raw;
    }
    return int.tryParse('$raw');
  }

  List<int> _parseUserIds(Object? raw) {
    final values = raw is List ? raw : const [];
    return values
        .map((value) => value is int ? value : int.tryParse('$value'))
        .whereType<int>()
        .toList(growable: false);
  }

  List<TodoUser> _resolveTodoUsers(
    List<int> userIds,
    Map<int, dynamic> userMap,
  ) {
    return userIds
        .map((userId) {
          final user = userMap[userId];
          return TodoUser(
            id: user?.remoteId ?? userId,
            email: user?.email ?? '',
            nickname: user?.nickname ?? '',
          );
        })
        .toList(growable: false);
  }

  ProjectUser _mapProjectUserFromDto(UserDto user) {
    return ProjectUser(
      id: user.id,
      email: user.email,
      nickname: user.nickname,
      provider: user.provider,
    );
  }

  TodoUser _mapTodoUserFromDto(UserDto user) {
    return TodoUser(id: user.id, email: user.email, nickname: user.nickname);
  }

  ProjectSummary _mapProject(ProjectDto dto) {
    return ProjectSummary(
      id: dto.id,
      remoteId: dto.id,
      name: dto.name,
      description: dto.description,
      version: dto.version,
      members: dto.membership
          .map(
            (member) => ProjectMember(
              id: member.user.id,
              email: member.user.email,
              nickname: member.user.nickname,
              provider: member.user.provider,
              role: member.role,
            ),
          )
          .toList(growable: false),
      owner: ProjectUser(
        id: dto.owner.id,
        email: dto.owner.email,
        nickname: dto.owner.nickname,
        provider: dto.owner.provider,
      ),
      recentUpdateAt: dto.recentUpdateAt == null
          ? null
          : DateTime.parse(dto.recentUpdateAt!),
      createdAt: DateTime.parse(dto.createdAt),
      updatedAt: DateTime.parse(dto.updatedAt),
      isFavorite: false,
    );
  }

  ProjectTodo _mapTodo(TodoDto dto) {
    return ProjectTodo(
      id: dto.id,
      projectId: dto.project,
      title: dto.title,
      status: dto.status,
      kind: dto.kind,
      version: dto.version,
      createdBy: TodoUser(
        id: dto.createdBy.id,
        email: dto.createdBy.email,
        nickname: dto.createdBy.nickname,
      ),
      isRecurring: dto.isRecurring,
      isHidden: dto.isHidden,
      startDate: dto.startDate == null ? null : DateTime.parse(dto.startDate!),
      startTime: dto.startTime,
      weekdayMask: dto.weekdayMask,
      endDate: dto.endDate == null ? null : DateTime.parse(dto.endDate!),
      endTime: dto.endTime,
      alarmOffsetMinutes: dto.alarmOffsetMinutes,
      completedAt: dto.completedAt == null
          ? null
          : DateTime.parse(dto.completedAt!),
      createdAt: DateTime.parse(dto.createdAt),
      updatedAt: DateTime.parse(dto.updatedAt),
      assignees: dto.assignees
          .map(
            (item) => TodoUser(
              id: item.id,
              email: item.email,
              nickname: item.nickname,
            ),
          )
          .toList(growable: false),
    );
  }
}
