import '../../../../core/network/result/api_error.dart';
import '../../../../core/network/simple_result.dart';
import '../../../project/domain/entities/project_todo.dart';
import '../../../project/domain/usecases/project_use_cases.dart';

class ScheduleUseCases {
  const ScheduleUseCases(this._executeAuthorized, this._projectUseCases);

  final Future<SimpleResult<T, ApiError>> Function<T>(
    Future<SimpleResult<T, ApiError>> Function(String accessToken) action,
  )
  _executeAuthorized;
  final ProjectUseCases _projectUseCases;

  Future<SimpleResult<ProjectTodo, ApiError>> toggleCompletion({
    required ProjectTodo todo,
  }) {
    final nextStatus = todo.isCompleted ? 'todo' : 'done';
    return _executeAuthorized<ProjectTodo>(
      (accessToken) => _projectUseCases.updateTodoStatus(
        accessToken: accessToken,
        todoId: todo.id,
        nextStatus: nextStatus,
      ),
    );
  }

  Future<SimpleResult<bool, ApiError>> toggleVisibility({
    required ProjectTodo todo,
  }) {
    return _executeAuthorized<bool>(
      (accessToken) => _projectUseCases.updateTodoVisibility(
        accessToken: accessToken,
        todoId: todo.id,
        isHidden: !todo.isHidden,
      ),
    );
  }
}
