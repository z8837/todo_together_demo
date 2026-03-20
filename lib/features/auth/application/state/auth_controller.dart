import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/result/api_error.dart';
import '../../../../core/network/simple_result.dart';
import '../../di/auth_di.dart';
import '../../domain/entities/demo_user.dart';

enum AuthStatus { loading, unauthenticated, authenticated }

class AuthState {
  const AuthState({required this.status, this.user, this.message});

  final AuthStatus status;
  final DemoUser? user;
  final String? message;

  AuthState copyWith({AuthStatus? status, DemoUser? user, String? message}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      message: message ?? this.message,
    );
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> mockLogin() async {
    state = state.copyWith(status: AuthStatus.loading, message: null);
    final useCases = ref.read(authUseCasesProvider);
    final result = await useCases.mockLogin();
    if (result.isSuccess) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.successData,
      );
      return true;
    }
    state = AuthState(
      status: AuthStatus.unauthenticated,
      message: result.failureData?.message,
    );
    return false;
  }

  void logout() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<SimpleResult<T, ApiError>> executeAuthorized<T>(
    Future<SimpleResult<T, ApiError>> Function(String token) action,
  ) async {
    final user = state.user;
    if (state.status != AuthStatus.authenticated || user == null) {
      return SimpleResult.failure(const ApiError(message: 'unauthorized'));
    }
    return action(user.accessToken);
  }
}
