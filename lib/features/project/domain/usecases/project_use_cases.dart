import '../../../../core/network/result/api_error.dart';
import '../../../../core/network/simple_result.dart';
import '../entities/project_summary.dart';
import '../entities/project_todo.dart';
import '../repositories/project_repository.dart';

class ProjectUseCases {
  const ProjectUseCases(this._repository);

  final ProjectRepository _repository;

  Future<SimpleResult<List<ProjectSummary>, ApiError>> fetchProjects({
    required String accessToken,
  }) => _repository.fetchProjects(accessToken: accessToken);

  Future<SimpleResult<List<ProjectTodo>, ApiError>> fetchTodos({
    required String accessToken,
  }) => _repository.fetchTodos(accessToken: accessToken);

  Future<SimpleResult<ProjectSummary, ApiError>> createProject({
    required String accessToken,
    required String name,
    String? description,
  }) => _repository.createProject(
    accessToken: accessToken,
    name: name,
    description: description,
  );

  Future<SimpleResult<ProjectSummary, ApiError>> updateProject({
    required String accessToken,
    required String projectId,
    required String name,
    String? description,
  }) => _repository.updateProject(
    accessToken: accessToken,
    projectId: projectId,
    name: name,
    description: description,
  );

  Future<SimpleResult<void, ApiError>> deleteProject({
    required String accessToken,
    required String projectId,
  }) =>
      _repository.deleteProject(accessToken: accessToken, projectId: projectId);

  Future<SimpleResult<List<ProjectUser>, ApiError>> searchUsers({
    required String accessToken,
    required String query,
    int limit = 10,
  }) => _repository.searchUsers(
    accessToken: accessToken,
    query: query,
    limit: limit,
  );

  Future<SimpleResult<void, ApiError>> inviteProjectMember({
    required String accessToken,
    required String projectId,
    required int userId,
    String role = 'writer',
  }) => _repository.inviteProjectMember(
    accessToken: accessToken,
    projectId: projectId,
    userId: userId,
    role: role,
  );

  Future<SimpleResult<ProjectTodo, ApiError>> createTodo({
    required String accessToken,
    required Map<String, dynamic> body,
  }) => _repository.createTodo(accessToken: accessToken, body: body);

  Future<SimpleResult<ProjectTodo, ApiError>> updateTodo({
    required String accessToken,
    required String todoId,
    required Map<String, dynamic> body,
  }) => _repository.updateTodo(
    accessToken: accessToken,
    todoId: todoId,
    body: body,
  );

  Future<SimpleResult<ProjectTodo, ApiError>> updateTodoStatus({
    required String accessToken,
    required String todoId,
    required String nextStatus,
  }) => _repository.updateTodoStatus(
    accessToken: accessToken,
    todoId: todoId,
    nextStatus: nextStatus,
  );

  Future<SimpleResult<bool, ApiError>> updateTodoVisibility({
    required String accessToken,
    required String todoId,
    required bool isHidden,
  }) => _repository.updateTodoVisibility(
    accessToken: accessToken,
    todoId: todoId,
    isHidden: isHidden,
  );

  Future<SimpleResult<void, ApiError>> deleteTodo({
    required String accessToken,
    required String todoId,
  }) => _repository.deleteTodo(accessToken: accessToken, todoId: todoId);

  Future<void> toggleFavoriteProject(String projectId) {
    return _repository.toggleFavoriteProject(projectId);
  }
}
