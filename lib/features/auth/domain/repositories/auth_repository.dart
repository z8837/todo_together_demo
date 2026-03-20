import '../../../../core/network/result/api_error.dart';
import '../../../../core/network/simple_result.dart';
import '../entities/demo_user.dart';

abstract interface class AuthRepository {
  Future<SimpleResult<DemoUser, ApiError>> mockLogin();
}
