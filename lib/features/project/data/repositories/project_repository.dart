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

class ProjectRepository implements domain.ProjectRepository {
  ProjectRepository({
    ProjectApi? api,
    ProjectLocalStore? projectLocalStore,
    TodoLocalStore? todoLocalStore,
  }) : _api = api ?? ProjectApi.create(),
       _projectLocalStore = projectLocalStore ?? ProjectLocalStore(),
       _todoLocalStore = todoLocalStore ?? TodoLocalStore();

  final ProjectApi _api;
  final ProjectLocalStore _projectLocalStore;
  final TodoLocalStore _todoLocalStore;

  @override
  Future<SimpleResult<List<ProjectSummary>, ApiError>> fetchProjects({
    required String accessToken,
  }) async {
    try {
      final response = await _api.syncProjects('Bearer $accessToken', const {
        'source': 'demo',
      });
      await _projectLocalStore.applySync(response.projects);
      return SimpleResult.success(
        response.projects.map(_mapProject).toList(growable: false),
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
      await _todoLocalStore.applySync(response.todos);
      return SimpleResult.success(
        response.todos.map(_mapTodo).toList(growable: false),
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
    try {
      final response = await _api.createProject('Bearer $accessToken', {
        'name': name,
        'description': description ?? '',
      });
      await _projectLocalStore.upsert(response);
      return SimpleResult.success(_mapProject(response));
    } catch (error) {
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
    try {
      final response = await _api.updateProject(
        'Bearer $accessToken',
        projectId,
        {'name': name, 'description': description ?? ''},
      );
      await _projectLocalStore.upsert(response);
      return SimpleResult.success(_mapProject(response));
    } catch (error) {
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
    try {
      await _api.deleteProject('Bearer $accessToken', projectId);
      await _projectLocalStore.removeProjects([projectId]);
      await _todoLocalStore.removeByProjectIds([projectId]);
      return SimpleResult.success<void, ApiError>(null);
    } catch (error) {
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
      return SimpleResult.success(
        response
            .map(
              (user) => ProjectUser(
                id: user.id,
                email: user.email,
                nickname: user.nickname,
                provider: user.provider,
              ),
            )
            .toList(growable: false),
      );
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
    try {
      await _api.createProjectInvite('Bearer $accessToken', projectId, {
        'user_id': userId,
        'role': role,
      });
      final synced = await _api.syncProjects('Bearer $accessToken', const {
        'source': 'demo',
      });
      await _projectLocalStore.applySync(synced.projects);
      return SimpleResult.success<void, ApiError>(null);
    } catch (error) {
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
    try {
      final response = await _api.createTodo('Bearer $accessToken', body);
      await _todoLocalStore.upsert(response);
      return SimpleResult.success(_mapTodo(response));
    } catch (error) {
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
    try {
      final response = await _api.updateTodo(
        'Bearer $accessToken',
        todoId,
        body,
      );
      await _todoLocalStore.upsert(response);
      return SimpleResult.success(_mapTodo(response));
    } catch (error) {
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
    try {
      await _api.deleteTodo('Bearer $accessToken', todoId);
      await _todoLocalStore.removeByIds([todoId]);
      return SimpleResult.success<void, ApiError>(null);
    } catch (error) {
      return SimpleResult.failure(
        ApiError(message: 'delete_todo_failed: $error'),
      );
    }
  }

  @override
  Future<void> toggleFavoriteProject(String projectId) async {}

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
