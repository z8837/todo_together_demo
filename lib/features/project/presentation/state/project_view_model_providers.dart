import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/state/auth_controller_provider.dart';
import '../../application/state/project_providers.dart';
import '../../domain/entities/project_summary.dart';
import '../viewmodels/add_todo/add_project_todo_view_model.dart';
import '../viewmodels/create_project_page_view_model.dart';

class CreateProjectPageViewModelArgs {
  const CreateProjectPageViewModelArgs({
    required this.initialProject,
    required this.canDelete,
  });

  final ProjectSummary? initialProject;
  final bool canDelete;
}

final createProjectPageViewModelProvider =
    Provider.family<CreateProjectPageViewModel, CreateProjectPageViewModelArgs>(
      (ref, args) {
        return CreateProjectPageViewModel(
          projectUseCases: ref.read(projectUseCasesProvider),
          executeAuthorized: ref
              .read(authControllerProvider.notifier)
              .executeAuthorized,
          invalidateProjects: () {
            ref.invalidate(projectsProvider);
          },
          initialProject: args.initialProject,
          canDelete: args.canDelete,
        );
      },
    );

final addProjectTodoSheetViewModelProvider =
    Provider<AddProjectTodoSheetViewModel>((ref) {
      return AddProjectTodoSheetViewModel(
        projectUseCases: ref.read(projectUseCasesProvider),
        executeAuthorized: ref
            .read(authControllerProvider.notifier)
            .executeAuthorized,
      );
    });

final projectReadRemoteIdByLocalIdProvider =
    Provider<Future<String?> Function(int)>((ref) {
      final store = ref.read(projectLocalStoreProvider);
      return (localId) => store.readRemoteIdByLocalId(localId);
    });
