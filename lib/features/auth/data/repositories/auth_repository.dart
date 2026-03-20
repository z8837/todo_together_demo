import '../../../../core/network/result/api_error.dart';
import '../../../../core/network/simple_result.dart';
import '../../domain/entities/demo_user.dart';
import '../../domain/repositories/auth_repository.dart' as domain;
import '../datasources/auth_api.dart';

class AuthRepository implements domain.AuthRepository {
  AuthRepository({AuthApi? api}) : _api = api ?? AuthApi.create();

  final AuthApi _api;

  @override
  Future<SimpleResult<DemoUser, ApiError>> mockLogin() async {
    try {
      final response = await _api.mockLogin({'mode': 'demo'});
      return SimpleResult.success(response.toEntity());
    } catch (error) {
      return SimpleResult.failure(
        ApiError(message: 'mock_login_failed: $error'),
      );
    }
  }
}
