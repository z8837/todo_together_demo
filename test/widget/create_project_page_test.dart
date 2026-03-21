import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todotogether/core/network/result/api_error.dart';
import 'package:todotogether/core/network/simple_result.dart';
import 'package:todotogether/features/project/domain/usecases/project_use_cases.dart';
import 'package:todotogether/features/project/presentation/pages/create_project_page.dart';
import 'package:todotogether/features/project/presentation/state/project_view_model_providers.dart';
import 'package:todotogether/features/project/presentation/viewmodels/create_project_page_view_model.dart';

import '../test_helpers/fake_project_repository.dart';
import '../test_helpers/project_fixtures.dart';

Future<SimpleResult<T, ApiError>> _executeAuthorized<T>(
  Future<SimpleResult<T, ApiError>> Function(String accessToken) action,
) {
  return action('token');
}

void main() {
  testWidgets('create project page validates empty project name', (
    tester,
  ) async {
    final viewModel = CreateProjectPageViewModel(
      projectUseCases: ProjectUseCases(
        FakeProjectRepository(
          onCreateProject: (token, name, description) async {
            return SimpleResult.success(
              demoProject(name: name, description: description ?? ''),
            );
          },
        ),
      ),
      executeAuthorized: _executeAuthorized,
      invalidateProjects: () {},
      initialProject: null,
      canDelete: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          createProjectPageViewModelProvider.overrideWith(
            (ref, args) => viewModel,
          ),
        ],
        child: const MaterialApp(home: CreateProjectPage()),
      ),
    );

    expect(find.text('프로젝트 생성'), findsOneWidget);
    expect(find.text('생성하고 초대하기'), findsOneWidget);

    await tester.tap(find.text('생성하고 초대하기'));
    await tester.pump();

    expect(find.text('프로젝트 이름을 입력해주세요.'), findsOneWidget);
  });
}
