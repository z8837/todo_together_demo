import 'package:todotogether/core/network/result/api_error.dart';
import 'package:todotogether/core/network/simple_result.dart';
import 'package:todotogether/features/project/domain/entities/project_summary.dart';
import 'package:todotogether/features/project/domain/entities/project_todo.dart';
import 'package:todotogether/features/project/domain/repositories/project_repository.dart';

class FakeProjectRepository implements ProjectRepository {
  FakeProjectRepository({
    this.onFetchProjects,
    this.onFetchTodos,
    this.onCreateProject,
    this.onUpdateProject,
    this.onDeleteProject,
    this.onSearchUsers,
    this.onInviteProjectMember,
    this.onCreateTodo,
    this.onUpdateTodo,
    this.onUpdateTodoStatus,
    this.onUpdateTodoVisibility,
    this.onDeleteTodo,
    this.onToggleFavoriteProject,
  });

  final Future<SimpleResult<List<ProjectSummary>, ApiError>> Function(
    String accessToken,
  )?
  onFetchProjects;
  final Future<SimpleResult<List<ProjectTodo>, ApiError>> Function(
    String accessToken,
  )?
  onFetchTodos;
  final Future<SimpleResult<ProjectSummary, ApiError>> Function(
    String accessToken,
    String name,
    String? description,
  )?
  onCreateProject;
  final Future<SimpleResult<ProjectSummary, ApiError>> Function(
    String accessToken,
    String projectId,
    String name,
    String? description,
  )?
  onUpdateProject;
  final Future<SimpleResult<void, ApiError>> Function(
    String accessToken,
    String projectId,
  )?
  onDeleteProject;
  final Future<SimpleResult<List<ProjectUser>, ApiError>> Function(
    String accessToken,
    String query,
    int limit,
  )?
  onSearchUsers;
  final Future<SimpleResult<void, ApiError>> Function(
    String accessToken,
    String projectId,
    int userId,
    String role,
  )?
  onInviteProjectMember;
  final Future<SimpleResult<ProjectTodo, ApiError>> Function(
    String accessToken,
    Map<String, dynamic> body,
  )?
  onCreateTodo;
  final Future<SimpleResult<ProjectTodo, ApiError>> Function(
    String accessToken,
    String todoId,
    Map<String, dynamic> body,
  )?
  onUpdateTodo;
  final Future<SimpleResult<ProjectTodo, ApiError>> Function(
    String accessToken,
    String todoId,
    String nextStatus,
  )?
  onUpdateTodoStatus;
  final Future<SimpleResult<bool, ApiError>> Function(
    String accessToken,
    String todoId,
    bool isHidden,
  )?
  onUpdateTodoVisibility;
  final Future<SimpleResult<void, ApiError>> Function(
    String accessToken,
    String todoId,
  )?
  onDeleteTodo;
  final Future<void> Function(String projectId)? onToggleFavoriteProject;

  Never _unsupported(String method) {
    throw UnimplementedError(
      'FakeProjectRepository.$method was not configured',
    );
  }

  @override
  Future<SimpleResult<List<ProjectSummary>, ApiError>> fetchProjects({
    required String accessToken,
  }) {
    final handler = onFetchProjects;
    if (handler == null) {
      _unsupported('fetchProjects');
    }
    return handler(accessToken);
  }

  @override
  Future<SimpleResult<List<ProjectTodo>, ApiError>> fetchTodos({
    required String accessToken,
  }) {
    final handler = onFetchTodos;
    if (handler == null) {
      _unsupported('fetchTodos');
    }
    return handler(accessToken);
  }

  @override
  Future<SimpleResult<ProjectSummary, ApiError>> createProject({
    required String accessToken,
    required String name,
    String? description,
  }) {
    final handler = onCreateProject;
    if (handler == null) {
      _unsupported('createProject');
    }
    return handler(accessToken, name, description);
  }

  @override
  Future<SimpleResult<ProjectSummary, ApiError>> updateProject({
    required String accessToken,
    required String projectId,
    required String name,
    String? description,
  }) {
    final handler = onUpdateProject;
    if (handler == null) {
      _unsupported('updateProject');
    }
    return handler(accessToken, projectId, name, description);
  }

  @override
  Future<SimpleResult<void, ApiError>> deleteProject({
    required String accessToken,
    required String projectId,
  }) {
    final handler = onDeleteProject;
    if (handler == null) {
      _unsupported('deleteProject');
    }
    return handler(accessToken, projectId);
  }

  @override
  Future<SimpleResult<List<ProjectUser>, ApiError>> searchUsers({
    required String accessToken,
    required String query,
    int limit = 10,
  }) {
    final handler = onSearchUsers;
    if (handler == null) {
      _unsupported('searchUsers');
    }
    return handler(accessToken, query, limit);
  }

  @override
  Future<SimpleResult<void, ApiError>> inviteProjectMember({
    required String accessToken,
    required String projectId,
    required int userId,
    String role = 'writer',
  }) {
    final handler = onInviteProjectMember;
    if (handler == null) {
      _unsupported('inviteProjectMember');
    }
    return handler(accessToken, projectId, userId, role);
  }

  @override
  Future<SimpleResult<ProjectTodo, ApiError>> createTodo({
    required String accessToken,
    required Map<String, dynamic> body,
  }) {
    final handler = onCreateTodo;
    if (handler == null) {
      _unsupported('createTodo');
    }
    return handler(accessToken, body);
  }

  @override
  Future<SimpleResult<ProjectTodo, ApiError>> updateTodo({
    required String accessToken,
    required String todoId,
    required Map<String, dynamic> body,
  }) {
    final handler = onUpdateTodo;
    if (handler == null) {
      _unsupported('updateTodo');
    }
    return handler(accessToken, todoId, body);
  }

  @override
  Future<SimpleResult<ProjectTodo, ApiError>> updateTodoStatus({
    required String accessToken,
    required String todoId,
    required String nextStatus,
  }) {
    final handler = onUpdateTodoStatus;
    if (handler == null) {
      _unsupported('updateTodoStatus');
    }
    return handler(accessToken, todoId, nextStatus);
  }

  @override
  Future<SimpleResult<bool, ApiError>> updateTodoVisibility({
    required String accessToken,
    required String todoId,
    required bool isHidden,
  }) {
    final handler = onUpdateTodoVisibility;
    if (handler == null) {
      _unsupported('updateTodoVisibility');
    }
    return handler(accessToken, todoId, isHidden);
  }

  @override
  Future<SimpleResult<void, ApiError>> deleteTodo({
    required String accessToken,
    required String todoId,
  }) {
    final handler = onDeleteTodo;
    if (handler == null) {
      _unsupported('deleteTodo');
    }
    return handler(accessToken, todoId);
  }

  @override
  Future<void> toggleFavoriteProject(String projectId) async {
    final handler = onToggleFavoriteProject;
    if (handler == null) {
      _unsupported('toggleFavoriteProject');
    }
    await handler(projectId);
  }
}
