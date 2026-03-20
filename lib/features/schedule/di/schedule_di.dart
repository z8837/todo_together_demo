import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/state/auth_controller_provider.dart';
import '../../project/di/project_di.dart';
import '../domain/usecases/schedule_use_cases.dart';

final scheduleUseCasesProvider = Provider((ref) {
  final authController = ref.watch(authControllerProvider.notifier);
  return ScheduleUseCases(
    authController.executeAuthorized,
    ref.watch(projectUseCasesProvider),
  );
});
