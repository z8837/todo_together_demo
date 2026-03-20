import '../../../../core/network/result/api_error.dart';
import '../../../../core/network/simple_result.dart';
import '../entities/project_summary.dart';
import '../entities/project_todo.dart';

abstract interface class ProjectRepository {
  Future<SimpleResult<List<ProjectSummary>, ApiError>> fetchProjects({
    required String accessToken,
  });

  Future<SimpleResult<List<ProjectTodo>, ApiError>> fetchTodos({
    required String accessToken,
  });

  Future<SimpleResult<ProjectSummary, ApiError>> createProject({
    required String accessToken,
    required String name,
    String? description,
  });

  Future<SimpleResult<ProjectSummary, ApiError>> updateProject({
    required String accessToken,
    required String projectId,
    required String name,
    String? description,
  });

  Future<SimpleResult<void, ApiError>> deleteProject({
    required String accessToken,
    required String projectId,
  });

  Future<SimpleResult<List<ProjectUser>, ApiError>> searchUsers({
    required String accessToken,
    required String query,
    int limit = 10,
  });

  Future<SimpleResult<void, ApiError>> inviteProjectMember({
    required String accessToken,
    required String projectId,
    required int userId,
    String role = 'writer',
  });

  Future<SimpleResult<ProjectTodo, ApiError>> createTodo({
    required String accessToken,
    required Map<String, dynamic> body,
  });

  Future<SimpleResult<ProjectTodo, ApiError>> updateTodo({
    required String accessToken,
    required String todoId,
    required Map<String, dynamic> body,
  });

  Future<SimpleResult<ProjectTodo, ApiError>> updateTodoStatus({
    required String accessToken,
    required String todoId,
    required String nextStatus,
  });

  Future<SimpleResult<bool, ApiError>> updateTodoVisibility({
    required String accessToken,
    required String todoId,
    required bool isHidden,
  });

  Future<SimpleResult<void, ApiError>> deleteTodo({
    required String accessToken,
    required String todoId,
  });

  Future<void> toggleFavoriteProject(String projectId);
}
