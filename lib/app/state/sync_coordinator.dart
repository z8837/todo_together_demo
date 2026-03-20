import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/state/auth_controller_provider.dart';
import '../../features/project/di/project_di.dart';

enum SyncReason { appStart, userAction, pullToRefresh }

final syncInProgressProvider = StateProvider<bool>((ref) => false);

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final coordinator = SyncCoordinator(ref);
  ref.listen<AuthStatus>(
    authControllerProvider.select((state) => state.status),
    (previous, next) {
      if (previous != AuthStatus.authenticated &&
          next == AuthStatus.authenticated) {
        unawaited(coordinator.trigger(SyncReason.appStart));
      }
    },
  );
  return coordinator;
});

class SyncCoordinator {
  SyncCoordinator(this._ref);

  final Ref _ref;
  bool _isSyncing = false;

  Future<void> syncProjects() async {
    final authController = _ref.read(authControllerProvider.notifier);
    final projectUseCases = _ref.read(projectUseCasesProvider);
    await authController.executeAuthorized(
      (token) => projectUseCases.fetchProjects(accessToken: token),
    );
  }

  Future<void> syncTodos() async {
    final authController = _ref.read(authControllerProvider.notifier);
    final projectUseCases = _ref.read(projectUseCasesProvider);
    await authController.executeAuthorized(
      (token) => projectUseCases.fetchTodos(accessToken: token),
    );
  }

  Future<void> syncNotifications() async {
    await trigger(SyncReason.userAction);
  }

  Future<void> trigger(SyncReason reason) async {
    if (_isSyncing) {
      return;
    }
    _isSyncing = true;
    _ref.read(syncInProgressProvider.notifier).state = true;

    try {
      await syncProjects();
      await syncTodos();
    } finally {
      _isSyncing = false;
      _ref.read(syncInProgressProvider.notifier).state = false;
    }
  }
}
