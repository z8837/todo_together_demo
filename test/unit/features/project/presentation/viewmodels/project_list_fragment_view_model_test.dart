import 'package:flutter_test/flutter_test.dart';
import 'package:todotogether/app/router.dart';
import 'package:todotogether/core/preferences/ui_preferences.dart';
import 'package:todotogether/features/project/presentation/viewmodels/project_list_fragment_view_model.dart';

import '../../../../../test_helpers/project_fixtures.dart';

void main() {
  setUp(() async {
    await UiPreferences.setProjectFavoritesOnly(false);
    await UiPreferences.setProjectListViewMode('detail');
  });

  group('ProjectListFragmentViewModel', () {
    test('buildDisplayData sorts projects and filters favorites', () {
      final viewModel = ProjectListFragmentViewModel(
        focusProjectId: null,
        focusTodoId: null,
        focusFromProvider: null,
      );
      final older = demoProject(
        id: 'older',
        name: 'Older',
        createdAt: DateTime(2026, 3, 1),
      );
      final newer = demoProject(
        id: 'newer',
        name: 'Newer',
        createdAt: DateTime(2026, 3, 2),
      );

      final allProjects = viewModel.buildDisplayData(
        projects: [newer, older],
        favoriteProjectIds: {'newer'},
        isSyncing: false,
      );

      expect(allProjects.sortedProjects.map((project) => project.id), [
        'older',
        'newer',
      ]);
      expect(allProjects.visibleProjects.map((project) => project.id), [
        'older',
        'newer',
      ]);

      viewModel.toggleFavoritesOnly();
      final favoritesOnly = viewModel.buildDisplayData(
        projects: [newer, older],
        favoriteProjectIds: {'newer'},
        isSyncing: false,
      );

      expect(favoritesOnly.favoriteProjects.map((project) => project.id), [
        'newer',
      ]);
      expect(favoritesOnly.visibleProjects.map((project) => project.id), [
        'newer',
      ]);
      expect(favoritesOnly.showFavoriteEmpty, isFalse);
    });

    test('handleRouteChange reports entering and leaving project tab', () {
      final viewModel = ProjectListFragmentViewModel(
        focusProjectId: null,
        focusTodoId: null,
        focusFromProvider: null,
      );

      viewModel.initializeRouteState(AppRoutePaths.homeProjects);

      final leaving = viewModel.handleRouteChange(AppRoutePaths.homeSchedule);
      expect(leaving, isNotNull);
      expect(leaving!.leftProjectTab, isTrue);
      expect(leaving.enteredProjectTab, isFalse);

      final entering = viewModel.handleRouteChange(AppRoutePaths.homeProjects);
      expect(entering, isNotNull);
      expect(entering!.leftProjectTab, isFalse);
      expect(entering.enteredProjectTab, isTrue);
    });
  });
}
