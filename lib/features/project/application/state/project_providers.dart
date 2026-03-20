import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/project_di.dart' as di;
import '../../domain/entities/project_summary.dart';
import '../../domain/entities/project_todo.dart';

final projectUseCasesProvider = di.projectUseCasesProvider;
final projectLocalStoreProvider = di.projectLocalStoreProvider;
final todoLocalStoreProvider = di.todoLocalStoreProvider;
final checklistOrderLocalStoreProvider = Provider<Object?>((ref) => null);

final projectsProvider = StreamProvider<List<ProjectSummary>>(
  (ref) => ref.watch(projectLocalStoreProvider).watchProjects(),
);

final projectTodosProvider = StreamProvider.family<List<ProjectTodo>, String>((
  ref,
  projectId,
) {
  return ref.watch(todoLocalStoreProvider).watchTodos(projectId: projectId);
});

final scheduleTodosProvider = StreamProvider<List<ProjectTodo>>(
  (ref) => ref.watch(todoLocalStoreProvider).watchTodos(),
);

class ProjectChecklistOrder {
  const ProjectChecklistOrder({required this.orderedChecklistIds});

  final List<String> orderedChecklistIds;
}

final projectChecklistOrderProvider =
    Provider.family<AsyncValue<ProjectChecklistOrder?>, String>((
      ref,
      projectId,
    ) {
      return const AsyncValue.data(null);
    });
