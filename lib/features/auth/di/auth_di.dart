import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/auth_repository.dart';
import '../domain/repositories/auth_repository.dart' as domain;
import '../domain/usecases/auth_use_cases.dart';

final authRepositoryProvider = Provider<domain.AuthRepository>((ref) {
  return AuthRepository();
});

final authUseCasesProvider = Provider((ref) {
  return AuthUseCases(ref.watch(authRepositoryProvider));
});
