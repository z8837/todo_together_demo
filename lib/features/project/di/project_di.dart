import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/local/local_user_store.dart';
import '../../../core/data/models/user_dto.dart';
import '../../auth/application/state/auth_controller_provider.dart';
import '../data/local/project_local_store.dart';
import '../data/local/todo_local_store.dart';
import '../data/repositories/project_repository.dart';
import '../domain/repositories/project_repository.dart' as domain;
import '../domain/usecases/project_use_cases.dart';

final localUserStoreProvider = Provider((ref) => LocalUserStore());

final projectLocalStoreProvider = Provider((ref) {
  return ProjectLocalStore(userStore: ref.watch(localUserStoreProvider));
});

final todoLocalStoreProvider = Provider((ref) {
  return TodoLocalStore(userStore: ref.watch(localUserStoreProvider));
});

final projectRepositoryProvider = Provider<domain.ProjectRepository>((ref) {
  return ProjectRepository(
    projectLocalStore: ref.watch(projectLocalStoreProvider),
    todoLocalStore: ref.watch(todoLocalStoreProvider),
    localUserStore: ref.watch(localUserStoreProvider),
    readCurrentUser: () {
      final user = ref.read(authControllerProvider).user;
      if (user == null) {
        return null;
      }
      return UserDto(
        id: user.id,
        email: user.email,
        nickname: user.nickname,
        provider: 'mock',
      );
    },
  );
});

final projectUseCasesProvider = Provider((ref) {
  return ProjectUseCases(ref.watch(projectRepositoryProvider));
});
