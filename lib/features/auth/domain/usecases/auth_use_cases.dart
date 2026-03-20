import '../../../../core/network/result/api_error.dart';
import '../../../../core/network/simple_result.dart';
import '../entities/demo_user.dart';
import '../repositories/auth_repository.dart';

class AuthUseCases {
  const AuthUseCases(this._repository);

  final AuthRepository _repository;

  Future<SimpleResult<DemoUser, ApiError>> mockLogin() {
    return _repository.mockLogin();
  }
}
