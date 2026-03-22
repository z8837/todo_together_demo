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

  group('ProjectTodoSummaryViewModel', () {
    test(
      'buildTodoStatus splits overdue, in progress, upcoming, completed',
      () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final overdue = demoTodo(
          id: 'overdue',
          title: 'Overdue',
          kind: 'schedule',
          status: 'todo',
          startDate: today.subtract(const Duration(days: 1)),
          endDate: today.subtract(const Duration(days: 1)),
          endTime: '23:59:00',
        );
        final inProgress = demoTodo(
          id: 'in-progress',
          title: 'In Progress',
          kind: 'schedule',
          status: 'doing',
          startDate: today,
          startTime: '00:00:00',
          endDate: today,
          endTime: '23:59:00',
        );
        final upcoming = demoTodo(
          id: 'upcoming',
          title: 'Upcoming',
          kind: 'schedule',
          status: 'todo',
          startDate: today.add(const Duration(days: 1)),
          endDate: today.add(const Duration(days: 1)),
        );
        final completed = demoTodo(
          id: 'completed',
          title: 'Completed',
          kind: 'schedule',
          status: 'done',
          completedAt: now.subtract(const Duration(hours: 1)),
        );

        final summary = ProjectTodoSummaryViewModel.buildTodoStatus([
          overdue,
          inProgress,
          upcoming,
          completed,
        ]);

        expect(summary.overdue, 1);
        expect(summary.inProgress, 1);
        expect(summary.upcoming, 1);
        expect(summary.completed, 1);
      },
    );

    test(
      'resolveChecklistPreviewTodos keeps explicit order for active items',
      () {
        final todo = demoTodo(
          id: 'todo',
          title: 'Todo',
          kind: 'checklist',
          status: 'todo',
          createdAt: DateTime(2026, 3, 10, 9),
        );
        final doing = demoTodo(
          id: 'doing',
          title: 'Doing',
          kind: 'checklist',
          status: 'doing',
          createdAt: DateTime(2026, 3, 10, 10),
        );
        final done = demoTodo(
          id: 'done',
          title: 'Done',
          kind: 'checklist',
          status: 'done',
          completedAt: DateTime(2026, 3, 10, 11),
        );

        final preview =
            ProjectTodoSummaryViewModel.resolveChecklistPreviewTodos(
              [todo, doing, done],
              orderIds: const ['doing', 'todo'],
            );

        expect(preview.map((item) => item.id), ['doing', 'todo', 'done']);
      },
    );
  });
}
