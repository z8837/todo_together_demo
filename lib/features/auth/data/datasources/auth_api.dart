import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/demo_http_client_adapter.dart';
import '../models/mock_login_response.dart';

part 'auth_api.g.dart';

@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String baseUrl}) = _AuthApi;

  factory AuthApi.create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://demo.todo-together.app/',
        headers: const {'Content-Type': 'application/json'},
      ),
    );
    dio.httpClientAdapter = DemoHttpClientAdapter();
    return AuthApi(dio);
  }

  @POST('/auth/mock-login/')
  Future<MockLoginResponse> mockLogin(@Body() Map<String, dynamic> body);
}
