import 'package:flutter_test/flutter_test.dart';
import 'package:todotogether/core/network/result/api_error.dart';
import 'package:todotogether/core/network/simple_result.dart';
import 'package:todotogether/features/project/domain/usecases/project_use_cases.dart';
import 'package:todotogether/features/project/presentation/viewmodels/create_project_page_view_model.dart';

import '../../../../../test_helpers/fake_project_repository.dart';
import '../../../../../test_helpers/project_fixtures.dart';

Future<SimpleResult<T, ApiError>> _executeAuthorized<T>(
  Future<SimpleResult<T, ApiError>> Function(String accessToken) action,
) {
  return action('token');
}

void main() {
  group('CreateProjectPageViewModel', () {
    test('resolvePermission allows owner to edit and delete', () {
      final project = demoProject(
        owner: demoUser(id: 10, nickname: 'Owner'),
        members: [demoMember(id: 20, role: 'writer')],
      );
      final viewModel = CreateProjectPageViewModel(
        projectUseCases: ProjectUseCases(FakeProjectRepository()),
        executeAuthorized: _executeAuthorized,
        invalidateProjects: () {},
        initialProject: project,
        canDelete: true,
      );

      final permission = viewModel.resolvePermission(10);

      expect(permission.canEditProject, isTrue);
      expect(permission.canDeleteProject, isTrue);
    });

    test('toggleCandidate ignores existing members on edit page', () {
      final existingMember = demoMember(id: 2, nickname: 'Existing');
      final viewModel = CreateProjectPageViewModel(
        projectUseCases: ProjectUseCases(FakeProjectRepository()),
        executeAuthorized: _executeAuthorized,
        invalidateProjects: () {},
        initialProject: demoProject(members: [existingMember]),
        canDelete: true,
      );

      viewModel.toggleCandidate(existingMember);
      viewModel.toggleCandidate(demoUser(id: 3, nickname: 'Invited'));

      expect(viewModel.selectedMembers.map((member) => member.id), [3]);
    });

    test(
      'submit creates project, invites selected members, and invalidates',
      () async {
        final invitedUsers = <int>[];
        var invalidateCount = 0;
        final createdProject = demoProject(
          id: 'created-project',
          name: 'Created',
        );
        final repository = FakeProjectRepository(
          onCreateProject: (token, name, description) async {
            return SimpleResult.success(
              createdProject.copyWith(
                name: name,
                description: description ?? '',
              ),
            );
          },
          onInviteProjectMember: (token, projectId, userId, role) async {
            invitedUsers.add(userId);
            return SimpleResult.success(null);
          },
        );
        final viewModel = CreateProjectPageViewModel(
          projectUseCases: ProjectUseCases(repository),
          executeAuthorized: _executeAuthorized,
          invalidateProjects: () {
            invalidateCount++;
          },
          initialProject: null,
          canDelete: false,
        );

        viewModel.toggleCandidate(demoUser(id: 2, nickname: 'One'));
        viewModel.toggleCandidate(demoUser(id: 3, nickname: 'Two'));

        final result = await viewModel.submit(
          name: 'New Project',
          description: 'Created from test',
        );

        expect(result, isNotNull);
        expect(result!.project.name, 'New Project');
        expect(result.invitedCount, 2);
        expect(invitedUsers, [2, 3]);
        expect(invalidateCount, 1);
        expect(viewModel.isSubmitting, isFalse);
      },
    );

    test('submit exposes error message when creation fails', () async {
      final repository = FakeProjectRepository(
        onCreateProject: (token, name, description) async {
          return SimpleResult.failure(
            const ApiError(message: 'create_project_failed'),
          );
        },
      );
      final viewModel = CreateProjectPageViewModel(
        projectUseCases: ProjectUseCases(repository),
        executeAuthorized: _executeAuthorized,
        invalidateProjects: () {},
        initialProject: null,
        canDelete: false,
      );

      final result = await viewModel.submit(name: 'Broken', description: '');

      expect(result, isNull);
      expect(viewModel.errorMessage, 'create_project_failed');
      expect(viewModel.isSubmitting, isFalse);
    });
  });
}
