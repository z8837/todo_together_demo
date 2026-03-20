import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/demo_http_client_adapter.dart';
import '../models/project_dto.dart';
import '../models/todo_dto.dart';

part 'project_api.g.dart';

@RestApi()
abstract class ProjectApi {
  factory ProjectApi(Dio dio, {String baseUrl}) = _ProjectApi;

  factory ProjectApi.create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://demo.todo-together.app/',
        headers: const {'Content-Type': 'application/json'},
      ),
    );
    dio.httpClientAdapter = DemoHttpClientAdapter();
    return ProjectApi(dio);
  }

  @POST('/projects/sync/')
  Future<ProjectSyncResponseDto> syncProjects(
    @Header('Authorization') String token,
    @Body() Map<String, dynamic> body,
  );

  @POST('/todos/sync/')
  Future<TodoSyncResponseDto> syncTodos(
    @Header('Authorization') String token,
    @Body() Map<String, dynamic> body,
  );

  @POST('/projects/')
  Future<ProjectDto> createProject(
    @Header('Authorization') String token,
    @Body() Map<String, dynamic> body,
  );

  @PATCH('/projects/{projectId}/')
  Future<ProjectDto> updateProject(
    @Header('Authorization') String token,
    @Path('projectId') String projectId,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/projects/{projectId}/')
  Future<void> deleteProject(
    @Header('Authorization') String token,
    @Path('projectId') String projectId,
  );

  @GET('/users/search/')
  Future<List<ProjectUserDto>> searchUsers(
    @Header('Authorization') String token,
    @Query('q') String query,
    @Query('limit') int limit,
  );

  @POST('/projects/{projectId}/invites/')
  Future<void> createProjectInvite(
    @Header('Authorization') String token,
    @Path('projectId') String projectId,
    @Body() Map<String, dynamic> body,
  );

  @POST('/todos/')
  Future<TodoDto> createTodo(
    @Header('Authorization') String token,
    @Body() Map<String, dynamic> body,
  );

  @PATCH('/todos/{todoId}/')
  Future<TodoDto> updateTodo(
    @Header('Authorization') String token,
    @Path('todoId') String todoId,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/todos/{todoId}/')
  Future<void> deleteTodo(
    @Header('Authorization') String token,
    @Path('todoId') String todoId,
  );
}
