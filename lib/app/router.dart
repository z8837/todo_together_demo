import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/state/auth_controller_provider.dart';
import '../features/auth/presentation/pages/login_screen.dart';
import '../features/home/presentation/pages/main_screen.dart';
import '../features/project/presentation/pages/add_todo/add_project_todo_sheet.dart';
import '../features/project/presentation/pages/add_todo/project_picker_screen.dart';
import '../features/project/domain/entities/project_summary.dart';
import '../features/project/presentation/pages/create_project_page.dart';
import '../features/project/presentation/pages/project_detail/project_detail_screen.dart';
import '../features/project/presentation/pages/project_list_fragment.dart';
import '../features/schedule/presentation/pages/schedule_fragment.dart';

class AppRoutePaths {
  const AppRoutePaths._();

  static const login = '/login';
  static const homeProjects = '/home/projects';
  static const homeSchedule = '/home/schedule';
  static const projectPicker = '/project-picker';
  static const projectEditor = '/project-editor';
  static const projectTodoEditor = '/project-todo-editor';

  static String projectDetailPath(String projectId) => '/project/$projectId';
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  final notifier = RouterNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutePaths.login,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.homeProjects,
                builder: (context, state) => const ProjectListFragment(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.homeSchedule,
                builder: (context, state) => const ScheduleFragment(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/project/:projectId',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId'] ?? '';
          return ProjectDetailScreen(projectId: projectId);
        },
      ),
      GoRoute(
        path: AppRoutePaths.projectPicker,
        builder: (context, state) {
          final args = state.extra is ProjectPickerArgs
              ? state.extra! as ProjectPickerArgs
              : const ProjectPickerArgs(projects: <ProjectSummary>[]);
          return ProjectPickerScreen(
            projects: args.projects,
            selectedProject: args.selectedProject,
          );
        },
      ),
      GoRoute(
        path: AppRoutePaths.projectEditor,
        builder: (context, state) {
          final args = state.extra is CreateProjectArgs
              ? state.extra! as CreateProjectArgs
              : const CreateProjectArgs();
          return CreateProjectPage(
            initialProject: args.initialProject,
            canDelete: args.canDelete,
          );
        },
      ),
      GoRoute(
        path: AppRoutePaths.projectTodoEditor,
        builder: (context, state) {
          final args = state.extra is AddProjectTodoArgs
              ? state.extra! as AddProjectTodoArgs
              : const AddProjectTodoArgs(allowProjectSelection: true);
          return AddProjectTodoSheet(
            project: args.project,
            initialTodo: args.initialTodo,
            initialSelectedDate: args.initialSelectedDate,
            allowProjectSelection: args.allowProjectSelection,
          );
        },
      ),
    ],
  );
});

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _sub = _ref.listen<AuthStatus>(
      authControllerProvider.select((state) => state.status),
      (_, next) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthStatus> _sub;

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authControllerProvider);
    final isLogin = state.matchedLocation == AppRoutePaths.login;

    switch (authState.status) {
      case AuthStatus.loading:
        return null;
      case AuthStatus.unauthenticated:
        return isLogin ? null : AppRoutePaths.login;
      case AuthStatus.authenticated:
        return isLogin ? AppRoutePaths.homeProjects : null;
    }
  }

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
