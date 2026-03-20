import 'dart:async';

import 'package:flutter/material.dart';
import 'package:todotogether/app/router.dart';
import 'package:todotogether/core/preferences/ui_preferences.dart';
import 'package:todotogether/features/project/domain/entities/project_summary.dart';
import 'package:todotogether/features/project/domain/entities/project_todo.dart';

class ProjectListRouteTransition {
  const ProjectListRouteTransition({
    required this.leftProjectTab,
    required this.enteredProjectTab,
  });

  final bool leftProjectTab;
  final bool enteredProjectTab;
}

class ProjectListDisplayData {
  const ProjectListDisplayData({
    required this.sortedProjects,
    required this.favoriteProjects,
    required this.visibleProjects,
    required this.showEmptySkeleton,
    required this.showFavoriteEmpty,
  });

  final List<ProjectSummary> sortedProjects;
  final List<ProjectSummary> favoriteProjects;
  final List<ProjectSummary> visibleProjects;
  final bool showEmptySkeleton;
  final bool showFavoriteEmpty;
}

class ProjectListFragmentViewModel {
  ProjectListFragmentViewModel({
    required String? focusProjectId,
    required String? focusTodoId,
    required String? focusFromProvider,
  }) {
    _viewModeStorage = UiPreferences.projectListViewMode();
    _showFavoritesOnly = UiPreferences.projectFavoritesOnly();
    _pendingFocusProjectId = focusProjectId;
    _selectedTodoId = focusTodoId;
    if ((_pendingFocusProjectId == null || _pendingFocusProjectId!.isEmpty) &&
        focusFromProvider != null &&
        focusFromProvider.isNotEmpty) {
      _pendingFocusProjectId = focusFromProvider;
      _didScrollToFocusProject = false;
      _focusScrollRetries = 0;
    }
  }

  static const int _maxFocusScrollRetries = 6;
  static const int _maxFocusScrollAttempts = 6;
  static const double _estimatedProjectCardExtentDetailed = 280;
  static const double _estimatedProjectCardExtentSimple = 132;
  static const double _projectListTopPadding = 8;

  String _viewModeStorage = 'detail';
  bool _showFavoritesOnly = false;
  String? _pendingFocusProjectId;
  bool _didScrollToFocusProject = false;
  bool _isResolvingFocusProjectId = false;
  bool _isFocusScrollScheduled = false;
  int _focusScrollRetries = 0;
  String? _pendingScrollProjectId;
  int _scrollAttempts = 0;
  bool _wasOnProjectTab = true;
  List<ProjectSummary> _latestProjectsSnapshot = const [];
  String? _selectedProjectId;
  String? _selectedTodoId;

  String get viewModeStorage => _viewModeStorage;
  bool get showFavoritesOnly => _showFavoritesOnly;
  String? get selectedProjectId => _selectedProjectId;
  String? get selectedTodoId => _selectedTodoId;
  bool get shouldBuildAllProjects =>
      _pendingFocusProjectId != null && !_didScrollToFocusProject;

  bool get isSimpleView => _viewModeStorage == 'simple';

  void applyWidgetUpdate({
    required String? oldFocusProjectId,
    required String? newFocusProjectId,
    required String? oldFocusTodoId,
    required String? newFocusTodoId,
  }) {
    if (oldFocusProjectId != newFocusProjectId) {
      _pendingFocusProjectId = newFocusProjectId;
      _didScrollToFocusProject = false;
      _focusScrollRetries = 0;
    }
    if (oldFocusTodoId != newFocusTodoId) {
      _selectedTodoId = newFocusTodoId;
    }
  }

  void applyFocusFromProvider(String next) {
    if (next.isEmpty) {
      return;
    }
    _pendingFocusProjectId = next;
    _didScrollToFocusProject = false;
    _focusScrollRetries = 0;
  }

  Future<bool> handleRefresh({
    required Future<void> Function() syncProjects,
    required Future<void> Function() syncTodos,
    required VoidCallback invalidateProjects,
  }) async {
    try {
      await Future.wait([syncProjects(), syncTodos()]);
      invalidateProjects();
      return true;
    } catch (_) {
      return false;
    }
  }

  void triggerUserSync(Future<void> Function() triggerUserAction) {
    unawaited(triggerUserAction());
  }

  bool updateViewModeStorage(String value) {
    if (_viewModeStorage == value) {
      return false;
    }
    _viewModeStorage = value;
    unawaited(UiPreferences.setProjectListViewMode(value));
    return true;
  }

  bool toggleFavoritesOnly() {
    _showFavoritesOnly = !_showFavoritesOnly;
    unawaited(UiPreferences.setProjectFavoritesOnly(_showFavoritesOnly));
    return true;
  }

  void toggleFavoriteProject(
    ProjectSummary project, {
    required void Function(String projectId) toggleFavoriteProjectById,
  }) {
    toggleFavoriteProjectById(project.id);
  }

  void initializeRouteState(String location) {
    _wasOnProjectTab = _isProjectTab(location);
  }

  ProjectListRouteTransition? handleRouteChange(String location) {
    if (location.isEmpty) {
      return null;
    }
    final isProjectTab = _isProjectTab(location);
    final enteredProjectTab = !_wasOnProjectTab && isProjectTab;
    final leftProjectTab = _wasOnProjectTab && !isProjectTab;
    _wasOnProjectTab = isProjectTab;
    return ProjectListRouteTransition(
      leftProjectTab: leftProjectTab,
      enteredProjectTab: enteredProjectTab,
    );
  }

  ProjectListDisplayData buildDisplayData({
    required List<ProjectSummary> projects,
    required Set<String> favoriteProjectIds,
    required bool isSyncing,
  }) {
    final sortedProjects = [...projects]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final favoriteProjects = sortedProjects
        .where((project) => favoriteProjectIds.contains(project.id))
        .toList();
    final visibleProjects = _showFavoritesOnly
        ? favoriteProjects
        : sortedProjects;
    _latestProjectsSnapshot = visibleProjects;

    return ProjectListDisplayData(
      sortedProjects: sortedProjects,
      favoriteProjects: favoriteProjects,
      visibleProjects: visibleProjects,
      showEmptySkeleton: sortedProjects.isEmpty && isSyncing,
      showFavoriteEmpty: _showFavoritesOnly && visibleProjects.isEmpty,
    );
  }

  void syncProjectItemKeys(
    Map<String, GlobalKey> projectItemKeys,
    List<ProjectSummary> projects,
  ) {
    final projectIds = projects.map((project) => project.remoteId).toSet();
    projectItemKeys.removeWhere((key, _) => !projectIds.contains(key));
    for (final project in projects) {
      projectItemKeys.putIfAbsent(project.remoteId, () => GlobalKey());
    }
  }

  Future<bool> resolveFocusProjectId(
    List<ProjectSummary> projects, {
    required bool mounted,
    required Future<String?> Function(int localId) readRemoteIdByLocalId,
  }) async {
    final focusProjectId = _pendingFocusProjectId;
    if (focusProjectId == null ||
        _didScrollToFocusProject ||
        _isResolvingFocusProjectId) {
      return false;
    }
    final hasMatch = projects.any(
      (project) => project.remoteId == focusProjectId,
    );
    if (hasMatch) {
      return false;
    }
    final localId = int.tryParse(focusProjectId);
    if (localId == null) {
      return false;
    }

    _isResolvingFocusProjectId = true;
    try {
      final remoteId = await readRemoteIdByLocalId(localId);
      if (!mounted ||
          remoteId == null ||
          remoteId.isEmpty ||
          remoteId == focusProjectId) {
        return false;
      }
      _pendingFocusProjectId = remoteId;
      _didScrollToFocusProject = false;
      return true;
    } finally {
      _isResolvingFocusProjectId = false;
    }
  }

  void scrollToFocusedProject({
    required List<ProjectSummary> projects,
    required ScrollController scrollController,
    required Map<String, GlobalKey> projectItemKeys,
    required VoidCallback clearExternalFocusState,
    required bool mounted,
  }) {
    final focusProjectId = _pendingFocusProjectId;
    if (focusProjectId == null || _didScrollToFocusProject) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final targetIndex = projects.indexWhere(
        (project) => project.remoteId == focusProjectId,
      );
      if (targetIndex < 0) {
        _scheduleFocusScrollRetry(
          scrollController: scrollController,
          projectItemKeys: projectItemKeys,
          clearExternalFocusState: clearExternalFocusState,
          mounted: mounted,
        );
        return;
      }

      final targetKey = projectItemKeys[focusProjectId];
      final targetContext = targetKey?.currentContext;
      if (targetContext != null) {
        _didScrollToFocusProject = true;
        _focusScrollRetries = 0;
        _scrollAttempts = 0;
        _isFocusScrollScheduled = false;
        unawaited(
          Scrollable.ensureVisible(
            targetContext,
            alignment: 0.1,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          ),
        );
        _pendingFocusProjectId = null;
        clearExternalFocusState();
        return;
      }

      if (!scrollController.hasClients) {
        _scheduleFocusScrollRetry(
          scrollController: scrollController,
          projectItemKeys: projectItemKeys,
          clearExternalFocusState: clearExternalFocusState,
          mounted: mounted,
        );
        return;
      }

      if (_pendingScrollProjectId == focusProjectId) {
        _scrollAttempts += 1;
      } else {
        _pendingScrollProjectId = focusProjectId;
        _scrollAttempts = 0;
      }
      if (_scrollAttempts > _maxFocusScrollAttempts) {
        _didScrollToFocusProject = true;
        _pendingFocusProjectId = null;
        clearExternalFocusState();
        return;
      }

      final cardExtent = _resolveProjectCardExtent(projectItemKeys, projects);
      final targetOffset = _projectListTopPadding + targetIndex * cardExtent;
      final maxExtent = scrollController.position.maxScrollExtent;
      final clampedOffset = targetOffset.clamp(0.0, maxExtent);
      unawaited(
        scrollController.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        scrollToFocusedProject(
          projects: _latestProjectsSnapshot,
          scrollController: scrollController,
          projectItemKeys: projectItemKeys,
          clearExternalFocusState: clearExternalFocusState,
          mounted: mounted,
        );
      });
    });
  }

  void _scheduleFocusScrollRetry({
    required ScrollController scrollController,
    required Map<String, GlobalKey> projectItemKeys,
    required VoidCallback clearExternalFocusState,
    required bool mounted,
  }) {
    if (_isFocusScrollScheduled ||
        _focusScrollRetries >= _maxFocusScrollRetries) {
      return;
    }
    _isFocusScrollScheduled = true;
    _focusScrollRetries++;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isFocusScrollScheduled = false;
      if (!mounted) {
        return;
      }
      scrollToFocusedProject(
        projects: _latestProjectsSnapshot,
        scrollController: scrollController,
        projectItemKeys: projectItemKeys,
        clearExternalFocusState: clearExternalFocusState,
        mounted: mounted,
      );
    });
  }

  double _resolveProjectCardExtent(
    Map<String, GlobalKey> projectItemKeys,
    List<ProjectSummary> projects,
  ) {
    if (projects.isEmpty) {
      return _estimatedProjectCardExtentForMode();
    }
    final firstKey = projectItemKeys[projects.first.remoteId];
    final context = firstKey?.currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      return renderObject.size.height;
    }
    return _estimatedProjectCardExtentForMode();
  }

  double _estimatedProjectCardExtentForMode() {
    return isSimpleView
        ? _estimatedProjectCardExtentSimple
        : _estimatedProjectCardExtentDetailed;
  }

  void ensureSelectedProject({
    required List<ProjectSummary> visibleProjects,
    required bool isSplitView,
    required String? fallbackFocusTodoId,
    required bool mounted,
    required VoidCallback requestRebuild,
  }) {
    if (!isSplitView) {
      return;
    }
    final currentId = _selectedProjectId;
    final hasCurrent =
        currentId != null &&
        visibleProjects.any((project) => project.id == currentId);
    if (hasCurrent) {
      return;
    }
    String? nextId;
    final focusId = _pendingFocusProjectId;
    if (focusId != null && focusId.isNotEmpty) {
      for (final project in visibleProjects) {
        if (project.remoteId == focusId || project.id == focusId) {
          nextId = project.id;
          break;
        }
      }
    }
    nextId ??= visibleProjects.isEmpty ? null : visibleProjects.first.id;
    if (nextId == _selectedProjectId) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _selectedProjectId = nextId;
      _selectedTodoId = fallbackFocusTodoId;
      requestRebuild();
    });
  }

  bool handleProjectTap(ProjectSummary project, {required bool isSplitView}) {
    if (!isSplitView) {
      return false;
    }
    final changed = _selectedProjectId != project.id || _selectedTodoId != null;
    _selectedProjectId = project.id;
    _selectedTodoId = null;
    return changed;
  }

  bool clearSelectedProject() {
    if (_selectedProjectId == null && _selectedTodoId == null) {
      return false;
    }
    _selectedProjectId = null;
    _selectedTodoId = null;
    return true;
  }

  bool _isProjectTab(String location) {
    return location == AppRoutePaths.homeProjects;
  }
}

enum _ProjectTodoFilterTab { all, overdue, inProgress, upcoming, completed }

class ProjectChecklistStatus {
  const ProjectChecklistStatus({
    required this.overdue,
    required this.inProgress,
    required this.upcoming,
    required this.completed,
  });

  final int overdue;
  final int inProgress;
  final int upcoming;
  final int completed;
}

class ProjectTodoStatus {
  const ProjectTodoStatus({
    required this.overdue,
    required this.inProgress,
    required this.upcoming,
    required this.completed,
  });

  final int overdue;
  final int inProgress;
  final int upcoming;
  final int completed;
}

class ProjectTodoCardSummary {
  const ProjectTodoCardSummary({
    required this.checklistStatus,
    required this.scheduleStatus,
    required this.previewTodos,
  });

  final ProjectChecklistStatus checklistStatus;
  final ProjectTodoStatus scheduleStatus;
  final List<ProjectTodo> previewTodos;
}

class ProjectTodoSummaryViewModel {
  const ProjectTodoSummaryViewModel._();

  static const int _checklistPreviewLimit = 3;

  static ProjectTodoCardSummary buildCardSummary(
    List<ProjectTodo> todos, {
    List<String>? checklistOrderIds,
    DateTime? now,
  }) {
    final resolvedNow = now ?? DateTime.now();
    final checklistTodos = todos
        .where((todo) => isChecklistTodo(todo))
        .toList();
    return ProjectTodoCardSummary(
      checklistStatus: buildChecklistStatus(checklistTodos, now: resolvedNow),
      scheduleStatus: buildTodoStatus(todos),
      previewTodos: resolveChecklistPreviewTodos(
        checklistTodos,
        orderIds: checklistOrderIds,
      ),
    );
  }

  static ProjectChecklistStatus buildChecklistStatus(
    List<ProjectTodo> todos, {
    DateTime? now,
  }) {
    final resolvedNow = now ?? DateTime.now();
    final overdue = _applyChecklistFilter(
      todos,
      _ProjectTodoFilterTab.overdue,
      resolvedNow,
    ).length;
    final inProgress = _applyChecklistFilter(
      todos,
      _ProjectTodoFilterTab.inProgress,
      resolvedNow,
    ).length;
    final upcoming = _applyChecklistFilter(
      todos,
      _ProjectTodoFilterTab.upcoming,
      resolvedNow,
    ).length;
    final completed = _applyChecklistFilter(
      todos,
      _ProjectTodoFilterTab.completed,
      resolvedNow,
    ).length;

    return ProjectChecklistStatus(
      overdue: overdue,
      inProgress: inProgress,
      upcoming: upcoming,
      completed: completed,
    );
  }

  static ProjectTodoStatus buildTodoStatus(List<ProjectTodo> todos) {
    final now = DateTime.now();
    var overdue = 0;
    var inProgress = 0;
    var upcoming = 0;
    var completed = 0;

    for (final todo in todos) {
      if (!isScheduleTodo(todo)) {
        continue;
      }
      if (todo.isCompleted) {
        completed++;
        continue;
      }

      final isOverdue = _isTodoOverdue(todo, now);
      if (isOverdue) {
        overdue++;
        continue;
      }
      final isInProgress = _isTodoInProgress(todo, now);
      if (isInProgress) {
        inProgress++;
      } else {
        upcoming++;
      }
    }

    return ProjectTodoStatus(
      overdue: overdue,
      inProgress: inProgress,
      upcoming: upcoming,
      completed: completed,
    );
  }

  static List<ProjectTodo> resolveChecklistPreviewTodos(
    List<ProjectTodo> todos, {
    List<String>? orderIds,
  }) {
    if (todos.isEmpty) {
      return const <ProjectTodo>[];
    }
    final activeTodos = todos
        .where((todo) => resolveChecklistStatus(todo) != 'done')
        .toList();
    final doneTodos = todos
        .where((todo) => resolveChecklistStatus(todo) == 'done')
        .toList();
    final orderedActiveTodos = _resolveChecklistOrder(
      activeTodos,
      overrideIds: orderIds,
    );
    final sortedDoneTodos = _sortChecklistDoneTodos(doneTodos);
    final orderedAllTodos = [...orderedActiveTodos, ...sortedDoneTodos];
    if (orderedAllTodos.length <= _checklistPreviewLimit) {
      return orderedAllTodos;
    }
    return orderedAllTodos.sublist(0, _checklistPreviewLimit);
  }

  static bool isScheduleTodo(ProjectTodo todo) {
    return todo.kind.trim().toLowerCase() == 'schedule';
  }

  static bool isChecklistTodo(ProjectTodo todo) {
    return todo.kind.trim().toLowerCase() == 'checklist';
  }

  static String resolveChecklistStatus(ProjectTodo todo) {
    if (todo.isCompleted) {
      return 'done';
    }
    return _normalizeChecklistStatus(todo.status);
  }

  static String _normalizeChecklistStatus(String rawStatus) {
    final normalized = rawStatus.trim().toLowerCase();
    if (normalized == 'done') {
      return 'done';
    }
    if (normalized == 'doing' ||
        normalized == 'in_progress' ||
        normalized == 'inprogress' ||
        normalized == 'progress') {
      return 'doing';
    }
    return 'todo';
  }

  static bool _isTodoOverdue(ProjectTodo todo, DateTime now) {
    if (todo.isCompleted) {
      return false;
    }

    final dueDateTime = _resolveTodoOverdueDateTime(todo);
    if (dueDateTime == null) {
      return false;
    }
    return now.isAfter(dueDateTime);
  }

  static bool _isChecklistOverdue(ProjectTodo todo, DateTime now) {
    if (todo.isCompleted) {
      return false;
    }
    final due = _resolveChecklistDueDateTime(todo);
    if (due == null) {
      return false;
    }
    return now.isAfter(due);
  }

  static DateTime? _resolveChecklistDueDateTime(ProjectTodo todo) {
    final endDate = todo.endDate;
    if (endDate == null) {
      return null;
    }
    return _resolveEndBoundary(endDate, todo.endTime);
  }

  static bool _isTodoInProgress(ProjectTodo todo, DateTime now) {
    if (todo.isCompleted) {
      return false;
    }

    final startDate = todo.startDate;
    if (startDate == null) {
      return false;
    }

    final endDate = todo.endDate;
    final today = DateUtils.dateOnly(now);
    final startDay = DateUtils.dateOnly(startDate);
    final endDay = DateUtils.dateOnly(endDate ?? startDate);

    if (today.isBefore(startDay)) {
      return false;
    }
    if (endDate != null && today.isAfter(endDay)) {
      return false;
    }

    if (todo.isRecurring) {
      if (!_matchesWeekday(todo.weekdayMask, today.weekday)) {
        return false;
      }
      final startBoundary = _resolveStartBoundary(today, todo.startTime);
      final endBoundary = _resolveEndBoundary(today, todo.endTime);
      if (startBoundary.isAfter(endBoundary)) {
        return false;
      }
      return !_isBefore(now, startBoundary) && !_isAfter(now, endBoundary);
    }

    if (today.isAfter(endDay)) {
      return false;
    }

    if (DateUtils.isSameDay(startDay, endDay) &&
        DateUtils.isSameDay(today, startDay)) {
      final startBoundary = _resolveStartBoundary(today, todo.startTime);
      final endBoundary = _resolveEndBoundary(today, todo.endTime);
      if (startBoundary.isAfter(endBoundary)) {
        return false;
      }
      return !_isBefore(now, startBoundary) && !_isAfter(now, endBoundary);
    }

    if (DateUtils.isSameDay(today, startDay)) {
      final startBoundary = _resolveStartBoundary(today, todo.startTime);
      return !_isBefore(now, startBoundary);
    }

    if (DateUtils.isSameDay(today, endDay)) {
      final endBoundary = _resolveEndBoundary(today, todo.endTime);
      return !_isAfter(now, endBoundary);
    }

    return true;
  }

  static DateTime _resolveStartBoundary(DateTime day, String? rawTime) {
    final parts = _tryParseTime(rawTime);
    if (parts == null) {
      return DateTime(day.year, day.month, day.day);
    }
    return DateTime(day.year, day.month, day.day, parts.$1, parts.$2);
  }

  static DateTime _resolveEndBoundary(DateTime day, String? rawTime) {
    final parts = _tryParseTime(rawTime);
    if (parts == null) {
      return DateTime(day.year, day.month, day.day, 23, 59, 59);
    }
    return DateTime(day.year, day.month, day.day, parts.$1, parts.$2);
  }

  static bool _isBefore(DateTime a, DateTime b) => a.isBefore(b);

  static bool _isAfter(DateTime a, DateTime b) => a.isAfter(b);

  static DateTime? _resolveTodoOverdueDateTime(ProjectTodo todo) {
    final startDate = todo.startDate;
    if (startDate == null) {
      return null;
    }

    final endDate = todo.endDate;
    final hasDifferentEndDate =
        endDate != null && !DateUtils.isSameDay(startDate, endDate);
    final endTime = todo.endTime;
    final startTime = todo.startTime;

    if (hasDifferentEndDate) {
      final endParts = _tryParseTime(endTime);
      if (endParts == null) {
        return DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
        ).add(const Duration(days: 1));
      }
      return DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        endParts.$1,
        endParts.$2,
      );
    }

    final endParts = _tryParseTime(endTime);
    if (endParts != null) {
      return DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        endParts.$1,
        endParts.$2,
      );
    }

    final startParts = _tryParseTime(startTime);
    if (startParts != null) {
      return DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        startParts.$1,
        startParts.$2,
      );
    }

    return DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    ).add(const Duration(days: 1));
  }

  static (int, int)? _tryParseTime(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final parts = raw.split(':');
    if (parts.length < 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return (hour, minute);
  }

  static bool _matchesWeekday(int? mask, int weekday) {
    if (mask == null || mask == 0) {
      return true;
    }
    final index = (weekday + 6) % 7;
    return (mask & (1 << index)) != 0;
  }

  static List<ProjectTodo> _applyChecklistFilter(
    List<ProjectTodo> todos,
    _ProjectTodoFilterTab filter,
    DateTime now,
  ) {
    if (filter == _ProjectTodoFilterTab.all) {
      return todos;
    }
    return todos.where((todo) {
      final status = resolveChecklistStatus(todo);
      final isCompleted = status == 'done';
      final isOverdue = _isChecklistOverdue(todo, now);
      final isInProgress = status == 'doing';
      final isUpcoming = status == 'todo';
      return switch (filter) {
        _ProjectTodoFilterTab.all => true,
        _ProjectTodoFilterTab.overdue => !isCompleted && isOverdue,
        _ProjectTodoFilterTab.inProgress =>
          !isCompleted && !isOverdue && isInProgress,
        _ProjectTodoFilterTab.upcoming =>
          !isCompleted && !isOverdue && isUpcoming,
        _ProjectTodoFilterTab.completed => isCompleted,
      };
    }).toList();
  }

  static List<ProjectTodo> _sortChecklistTodos(List<ProjectTodo> todos) {
    if (todos.length <= 1) {
      return todos;
    }

    final ordered = [...todos]
      ..sort((a, b) {
        final compare = a.createdAt.compareTo(b.createdAt);
        if (compare != 0) {
          return compare;
        }
        return a.id.compareTo(b.id);
      });
    return ordered;
  }

  static List<ProjectTodo> _sortChecklistDoneTodos(List<ProjectTodo> todos) {
    if (todos.length <= 1) {
      return todos;
    }
    final sorted = [...todos];
    sorted.sort((a, b) {
      final aKey = a.completedAt ?? a.updatedAt;
      final bKey = b.completedAt ?? b.updatedAt;
      final compare = bKey.compareTo(aKey);
      if (compare != 0) {
        return compare;
      }
      return a.id.compareTo(b.id);
    });
    return sorted;
  }

  static List<ProjectTodo> _resolveChecklistOrder(
    List<ProjectTodo> todos, {
    List<String>? overrideIds,
  }) {
    if (todos.isEmpty) {
      return todos;
    }
    final override = overrideIds;
    if (override == null || override.isEmpty) {
      return _sortChecklistTodos(todos);
    }
    final todoMap = {for (final todo in todos) todo.id: todo};
    final ordered = <ProjectTodo>[];
    for (final id in override) {
      final todo = todoMap.remove(id);
      if (todo != null) {
        ordered.add(todo);
      }
    }
    if (todoMap.isNotEmpty) {
      final remaining = _sortChecklistTodos(todoMap.values.toList());
      ordered.addAll(remaining);
    }
    return ordered;
  }
}
