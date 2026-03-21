import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:todotogether/core/network/result/api_error.dart';
import 'package:todotogether/core/network/simple_result.dart';
import 'package:todotogether/features/project/domain/usecases/project_use_cases.dart';
import 'package:todotogether/features/project/presentation/pages/create_project_page.dart';
import 'package:todotogether/features/project/presentation/state/project_view_model_providers.dart';
import 'package:todotogether/features/project/presentation/viewmodels/create_project_page_view_model.dart';

import '../test/test_helpers/fake_project_repository.dart';
import '../test/test_helpers/project_fixtures.dart';

Future<SimpleResult<T, ApiError>> _executeAuthorized<T>(
  Future<SimpleResult<T, ApiError>> Function(String accessToken) action,
) {
  return action('token');
}

class _CreateProjectFlowHost extends StatefulWidget {
  const _CreateProjectFlowHost();

  @override
  State<_CreateProjectFlowHost> createState() => _CreateProjectFlowHostState();
}

class _CreateProjectFlowHostState extends State<_CreateProjectFlowHost> {
  final List<String> _projectNames = <String>['Existing Project'];

  Future<void> _openCreateProjectPage() async {
    final result = await Navigator.of(context).push<CreateProjectResult>(
      MaterialPageRoute<CreateProjectResult>(
        builder: (context) => const CreateProjectPage(),
      ),
    );

    if (!mounted || result == null || result.isDeleted) {
      return;
    }

    setState(() {
      _projectNames.add(result.project.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Integration Test Host')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    key: const Key('open_create_project'),
                    onPressed: _openCreateProjectPage,
                    child: const Text('Open create project'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('refresh_project_list'),
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Refresh list'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: _projectNames
                  .map((projectName) => ListTile(title: Text(projectName)))
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('created project remains visible after a refresh action', (
    tester,
  ) async {
    final viewModel = CreateProjectPageViewModel(
      projectUseCases: ProjectUseCases(
        FakeProjectRepository(
          onCreateProject: (token, name, description) async {
            return SimpleResult.success(
              demoProject(
                id: 'created-project',
                name: name,
                description: description ?? '',
              ),
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
        child: const MaterialApp(home: _CreateProjectFlowHost()),
      ),
    );

    expect(find.text('Existing Project'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open_create_project')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      'Integration Test Project',
    );
    await tester.pump();

    await tester.ensureVisible(find.byType(OutlinedButton).first);
    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pumpAndSettle();

    expect(find.text('Integration Test Project'), findsOneWidget);

    await tester.tap(find.byKey(const Key('refresh_project_list')));
    await tester.pumpAndSettle();

    expect(find.text('Integration Test Project'), findsOneWidget);
  });
}
