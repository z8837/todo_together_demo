import 'dart:async';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:todotogether/app/router.dart';
import 'package:todotogether/core/core.dart';
import 'package:todotogether/core/widgets/schedule_home_widget_service.dart';
import 'package:todotogether/core/widgets/schedule_widget_models.dart';
import 'package:todotogether/core/network/result/api_error.dart';
import 'package:todotogether/core/network/simple_result.dart';
import 'package:todotogether/core/ui/breakpoints.dart';
import 'package:todotogether/features/auth/application/state/auth_controller_provider.dart';
import 'package:todotogether/features/holiday/domain/entities/holiday.dart';
import 'package:todotogether/features/project/domain/entities/project_summary.dart';
import 'package:todotogether/features/project/domain/entities/project_todo.dart';
import 'package:todotogether/features/schedule/application/schedule_providers.dart';
import 'package:todotogether/features/schedule/domain/usecases/schedule_use_cases.dart';
import 'package:todotogether/features/project/presentation/pages/add_todo/add_project_todo_sheet.dart';
import 'package:todotogether/features/project/presentation/pages/create_project_page.dart';
import 'package:todotogether/features/project/presentation/state/project_feature_providers.dart';
import 'package:todotogether/features/holiday/application/holiday_providers.dart';
import 'package:todotogether/app/state/sync_coordinator.dart';
import 'package:todotogether/features/project/presentation/widgets/project_color_resolver.dart';

part 'schedule_add_todo_flow.dart';
part 'schedule_fragment_calendar.dart';
part 'schedule_fragment_day_panel.dart';
part 'schedule_fragment_error.dart';
part 'schedule_fragment_types.dart';
part 'schedule_fragment_utils.dart';
part '../viewmodels/schedule_fragment_view_model.dart';

final _scheduleFragmentViewModelProvider =
    Provider.family<_ScheduleFragmentViewModel, int>((ref, initialPageIndex) {
      return _ScheduleFragmentViewModel(
        initialPageIndex: initialPageIndex,
        useCases: ref.read(scheduleUseCasesProvider),
      );
    });

class ScheduleFragment extends ConsumerStatefulWidget {
  const ScheduleFragment({super.key});

  @override
  ConsumerState<ScheduleFragment> createState() => _ScheduleFragmentState();
}

class _ScheduleFragmentState extends ConsumerState<ScheduleFragment> {
  static const int _initialPageIndex = 1000;
  late final _ScheduleFragmentViewModel _viewModel;
  late final PageController _monthPageController;
  final PanelController _dayPanelController = PanelController();
  final GlobalKey _dayPanelHeaderKey = GlobalKey();
  final GlobalKey _weekdayHeaderKey = GlobalKey();
  final ValueNotifier<bool> _dayPanelListScrollable = ValueNotifier(false);
  final ValueNotifier<double> _dayPanelVisibleHeight = ValueNotifier(0.0);
  double _dayPanelPosition = 0.0;
  double _measuredDayPanelHeaderHeight = 0.0;
  double _measuredWeekdayHeaderHeight = 0.0;
  bool _didSetInitialPanelPosition = false;
  double? _dayPanelDragPosition;
  bool _panelMoveScheduled = false;
  double _pendingPanelPosition = 0.0;
  bool _isDayPanelSnapping = false;
  bool _isCalendarExpanded = false;
  String? _lastWidgetPreviewSignature;
  DateTime get _focusedMonth => _viewModel.focusedMonth;
  DateTime? get _selectedDay => _viewModel.selectedDay;
  DateTime get _initialMonth => _viewModel.initialMonth;
  int get _currentPageIndex => _viewModel.currentPageIndex;
  bool get _showFavoritesOnly => _viewModel.showFavoritesOnly;

  bool get _shouldLoadHolidayApi => _viewModel.shouldLoadHolidayApi;

  @override
  void initState() {
    super.initState();
    _viewModel = ref.read(
      _scheduleFragmentViewModelProvider(_initialPageIndex),
    );
    _monthPageController = PageController(initialPage: _currentPageIndex);
    Future.microtask(() async {
      final coordinator = ref.read(holidaySyncCoordinatorProvider);
      if (_shouldLoadHolidayApi) {
        await coordinator.ensureHolidaysSynced();
      } else {
        await coordinator.clearCachedHolidays();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _persistAppSelectedDay();
    });
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    _dayPanelListScrollable.dispose();
    _dayPanelVisibleHeight.dispose();
    super.dispose();
  }

  void _requestPanelPosition(double position) {
    if (_isDayPanelSnapping) {
      return;
    }
    _pendingPanelPosition = position.clamp(0.0, 1.0);
    if (_panelMoveScheduled) {
      return;
    }
    _panelMoveScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _panelMoveScheduled = false;
      if (_isDayPanelSnapping) {
        return;
      }
      try {
        _dayPanelController.animatePanelToPosition(
          _pendingPanelPosition,
          duration: Duration.zero,
          curve: Curves.linear,
        );
      } catch (_) {}
    });
  }

  void _toggleFavoriteFilter() {
    final changed = _viewModel.toggleFavoriteFilter();
    if (!changed) {
      return;
    }
    setState(() {});
  }

  void _handleWidgetRouteParams(BuildContext context) {
    final queryParameters = GoRouterState.of(context).uri.queryParameters;
    final routeAction = _viewModel.resolveWidgetRouteAction(
      action: queryParameters['action'],
      dateParam: queryParameters['date'],
      tsParam: queryParameters['ts'],
    );
    if (routeAction == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      _jumpToDate(routeAction.targetDate);
      if (routeAction.shouldOpenAddTodo) {
        final created = await _handleAddTodo(context, routeAction.targetDate);
        if (created == true) {
          SystemNavigator.pop();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _handleWidgetRouteParams(context);
    final projectsAsync = ref.watch(projectsProvider);
    final todosAsync = ref.watch(scheduleTodosProvider);
    final holidaysAsync = _shouldLoadHolidayApi
        ? ref.watch(holidaysProvider)
        : const AsyncValue<List<Holiday>>.data(<Holiday>[]);
    final favoriteProjectIds = ref.watch(favoriteProjectIdsProvider);
    final holidays = holidaysAsync.maybeWhen(
      data: (items) => items,
      orElse: () => const <Holiday>[],
    );

    return projectsAsync.when(
      data: (projects) {
        return todosAsync.when(
          data: (todos) => _buildContent(
            context,
            projects,
            todos,
            holidays,
            favoriteProjectIds,
          ),
          loading: _buildLoadingScaffold,
          error: (error, stackTrace) => _buildErrorScaffold(
            _resolveErrorMessage(error),
            () => unawaited(
              ref.read(syncCoordinatorProvider).syncNotifications(),
            ),
          ),
        );
      },
      loading: _buildLoadingScaffold,
      error: (error, stackTrace) =>
          _buildErrorScaffold(_resolveErrorMessage(error), () {
            unawaited(ref.read(syncCoordinatorProvider).syncNotifications());
          }),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<ProjectSummary> projects,
    List<ProjectTodo> todos,
    List<Holiday> holidays,
    Set<String> favoriteProjectIds,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncWidgetPreviewIfNeeded(todos: todos, holidays: holidays);
    });

    final contentData = _viewModel.buildContentData(
      projects: projects,
      todos: todos,
      holidays: holidays,
      favoriteProjectIds: favoriteProjectIds,
    );
    final projectLookup = contentData.projectLookup;
    final favoriteProjects = contentData.favoriteProjects;
    final selectedDay = contentData.selectedDay;
    final selectedKey = contentData.selectedDayKey;
    final visibleTodos = contentData.visibleTodos;
    final selectedTodos = contentData.selectedTodos;
    final holidayMap = contentData.holidayMap;
    final currentUserId = ref.watch(
      authControllerProvider.select((state) => state.user?.id),
    );
    final isSplitView = AppBreakpoints.isTablet(context);
    final header = _buildHeaderRow(context, favoriteProjects.length);

    Future<void> openTodoActions(
      ProjectTodo todo,
      DateTime occurrence,
      ProjectSummary? project,
      bool canManage,
    ) async {
      if (project == null) {
        if (context.mounted) {
          //           ScaffoldMessenger.of(context).showSnackBar(
          //             const SnackBar(content: Text('프로젝트 정보를 불러오지 못했어요.'.tr())),
          //           );
        }
        return;
      }
      // 카드 액션(완료/수정/숨김 등)은 공통 바텀시트 핸들러로 위임합니다.
      await _openTodoActions(
        context: context,
        project: project,
        todo: todo,
        occurrenceDate: occurrence,
        canManage: canManage,
      );
    }

    if (isSplitView) {
      return _buildSplitLayout(
        context: context,
        header: header,
        projectLookup: projectLookup,
        visibleTodos: visibleTodos,
        holidayMap: holidayMap,
        selectedDay: selectedDay,
        selectedTodos: selectedTodos,
        currentUserId: currentUserId,
        openTodoActions: openTodoActions,
      );
    }

    return Scaffold(
      backgroundColor: _SchedulePalette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            header,
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    final headerContext = _dayPanelHeaderKey.currentContext;
                    final weekdayContext = _weekdayHeaderKey.currentContext;
                    final headerHeight = headerContext?.size?.height ?? 0.0;
                    final weekdayHeight = weekdayContext?.size?.height ?? 0.0;
                    final shouldUpdateHeader =
                        headerHeight > 0.0 &&
                        (headerHeight - _measuredDayPanelHeaderHeight).abs() >
                            0.5;
                    final shouldUpdateWeekday =
                        weekdayHeight > 0.0 &&
                        (weekdayHeight - _measuredWeekdayHeaderHeight).abs() >
                            0.5;
                    if (!shouldUpdateHeader && !shouldUpdateWeekday) {
                      return;
                    }
                    setState(() {
                      if (shouldUpdateHeader) {
                        _measuredDayPanelHeaderHeight = headerHeight;
                      }
                      if (shouldUpdateWeekday) {
                        _measuredWeekdayHeaderHeight = weekdayHeight;
                      }
                    });
                  });

                  const horizontalPadding = 7.0;
                  const crossAxisCount = 7;
                  const spacing = 15.0;
                  const rowCount = 6;
                  final gridWidth =
                      constraints.maxWidth - horizontalPadding * 2;
                  final unitWidth =
                      (gridWidth - spacing * (crossAxisCount - 1)) /
                      crossAxisCount;
                  final pagerHeight =
                      unitWidth * rowCount + spacing * (rowCount - 1) + spacing;

                  final weekdayHeaderHeight = _measuredWeekdayHeaderHeight > 0.0
                      ? _measuredWeekdayHeaderHeight
                      : 28.0;
                  final calendarTargetHeight =
                      weekdayHeaderHeight + 4 + pagerHeight;

                  final minPanelHeight = _measuredDayPanelHeaderHeight > 0.0
                      ? _measuredDayPanelHeaderHeight
                      : 72.0;
                  final maxPanelHeight = constraints.maxHeight;
                  final midPanelHeight = (maxPanelHeight - calendarTargetHeight)
                      .clamp(minPanelHeight, maxPanelHeight);

                  final snapPosition = (maxPanelHeight - minPanelHeight) <= 0
                      ? 0.0
                      : ((midPanelHeight - minPanelHeight) /
                                (maxPanelHeight - minPanelHeight))
                            .clamp(0.0, 1.0);

                  final stage1CalendarHeight =
                      (constraints.maxHeight - minPanelHeight).clamp(
                        0.0,
                        constraints.maxHeight,
                      );
                  final stage2CalendarHeight =
                      (constraints.maxHeight - midPanelHeight).clamp(
                        0.0,
                        constraints.maxHeight,
                      );

                  if (!_didSetInitialPanelPosition) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted || _didSetInitialPanelPosition) return;
                      try {
                        _dayPanelController.animatePanelToPosition(
                          snapPosition,
                          duration: Duration.zero,
                          curve: Curves.linear,
                        );
                        _dayPanelPosition = snapPosition;
                        _dayPanelListScrollable.value = true;
                        _dayPanelVisibleHeight.value = midPanelHeight;
                        _isCalendarExpanded = false;
                        _didSetInitialPanelPosition = true;
                      } catch (_) {}
                    });
                  }

                  Future<void> animatePanelToStage(double position) async {
                    try {
                      await _dayPanelController.animatePanelToPosition(
                        position.clamp(0.0, 1.0),
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                      );
                    } catch (_) {}
                  }

                  final calendarContent = Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: SizedBox(
                          key: _weekdayHeaderKey,
                          child: _CalendarWeekdayHeader(
                            textStyle: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _SchedulePalette.weekdays,
                                ),
                          ),
                        ),
                      ),
                      AppGap.h4,
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: PageView.builder(
                            controller: _monthPageController,
                            onPageChanged: _handlePageChanged,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final offset = index - _initialPageIndex;
                              final month = DateTime(
                                _initialMonth.year,
                                _initialMonth.month + offset,
                                1,
                              );
                              final monthDays = _visibleDaysFor(month);
                              final monthTodoMap = _buildDayTodoMap(
                                visibleTodos,
                                monthDays,
                              );
                              return _MonthGrid(
                                days: monthDays,
                                focusedMonth: month,
                                selectedDay: selectedDay,
                                dayTodoMap: monthTodoMap,
                                holidayMap: holidayMap,
                                onDaySelected: _handleDayTap,
                                isExpanded: _isCalendarExpanded,
                                mainAxisSpacing: spacing,
                                crossAxisSpacing: spacing,
                                bottomPadding: 0,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );

                  return SlidingUpPanel(
                    controller: _dayPanelController,
                    isDraggable: false,
                    renderPanelSheet: false,
                    minHeight: minPanelHeight,
                    maxHeight: maxPanelHeight,
                    onPanelSlide: (position) {
                      if ((_dayPanelPosition - position).abs() < 0.001) {
                        return;
                      }
                      _dayPanelPosition = position;
                      _dayPanelVisibleHeight.value =
                          minPanelHeight +
                          position * (maxPanelHeight - minPanelHeight);
                    },
                    body: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        end: _isCalendarExpanded
                            ? stage1CalendarHeight
                            : stage2CalendarHeight,
                      ),
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      child: RepaintBoundary(child: calendarContent),
                      builder: (context, height, child) {
                        return Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            height: height,
                            width: double.infinity,
                            child: child,
                          ),
                        );
                      },
                    ),
                    panelBuilder: (_) {
                      final card = _DayScheduleCard(
                        day: selectedDay,
                        todos: selectedTodos,
                        todosForDay: (day) =>
                            _buildSelectedDayTodos(visibleTodos, day),
                        projectLookup: projectLookup,
                        currentUserId: currentUserId,
                        onTodoTap: openTodoActions,
                        onAddTodo: () => _handleAddTodo(context, selectedDay),
                        onDaySwipe: _handleDayTap,
                        headerKey: _dayPanelHeaderKey,
                        isListScrollable: _dayPanelListScrollable,
                        holiday: holidayMap[selectedKey],
                        onHeaderDragStart: (_) {
                          _dayPanelDragPosition = _dayPanelPosition;
                          _dayPanelListScrollable.value = false;
                        },
                        onHeaderDragUpdate: (details) {
                          final start =
                              _dayPanelDragPosition ?? _dayPanelPosition;
                          final denom = (maxPanelHeight - minPanelHeight);
                          if (denom <= 0) return;
                          final delta = -details.delta.dy / denom;
                          final next = (start + delta).clamp(0.0, 1.0);
                          _requestPanelPosition(next);
                          _dayPanelDragPosition = next;
                        },
                        onHeaderDragEnd: (details) {
                          final current =
                              _dayPanelDragPosition ?? _dayPanelPosition;
                          _dayPanelDragPosition = null;
                          final stagePositions = <double>[
                            0.0,
                            snapPosition,
                            1.0,
                          ];

                          final velocityDy =
                              details.velocity.pixelsPerSecond.dy;
                          const velocityThreshold = 650.0;

                          double target;
                          if (velocityDy.abs() >= velocityThreshold) {
                            if (velocityDy < 0) {
                              target = stagePositions
                                  .where((p) => p > current)
                                  .fold<double>(
                                    1.0,
                                    (min, p) => p < min ? p : min,
                                  );
                            } else {
                              target = stagePositions
                                  .where((p) => p < current)
                                  .fold<double>(
                                    0.0,
                                    (max, p) => p > max ? p : max,
                                  );
                            }
                          } else {
                            target = stagePositions.reduce((a, b) {
                              final da = (a - current).abs();
                              final db = (b - current).abs();
                              return da <= db ? a : b;
                            });
                          }

                          final shouldScroll =
                              (target - snapPosition).abs() < 0.0001 ||
                              (target - 1.0).abs() < 0.0001;
                          final targetHeight =
                              minPanelHeight +
                              target * (maxPanelHeight - minPanelHeight);

                          _isDayPanelSnapping = true;
                          animatePanelToStage(target).whenComplete(() {
                            _isDayPanelSnapping = false;
                            _dayPanelVisibleHeight.value = targetHeight;
                            _dayPanelListScrollable.value = shouldScroll;
                            final nextExpanded = target <= 0.0001;
                            if (mounted &&
                                _isCalendarExpanded != nextExpanded) {
                              setState(() {
                                _isCalendarExpanded = nextExpanded;
                              });
                            }
                          });
                        },
                      );

                      return SizedBox.expand(
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ValueListenableBuilder<double>(
                              valueListenable: _dayPanelVisibleHeight,
                              child: card,
                              builder: (context, visibleHeight, child) {
                                final height = visibleHeight <= 0.0
                                    ? midPanelHeight
                                    : visibleHeight;
                                return SizedBox(
                                  height: height,
                                  width: double.infinity,
                                  child: child,
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context, int favoriteCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _GhostCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: () => _changeMonth(-1),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Tap(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _pickCalendarDate(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Align(
                        alignment: Alignment.center,
                        child: AutoSizeText(
                          '{year}년 {month}월'.tr(
                            namedArgs: {
                              'year': _focusedMonth.year.toString(),
                              'month': _focusedMonth.month.toString(),
                            },
                          ),
                          maxLines: 1,
                          minFontSize: 12,
                          maxFontSize: 22,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: _SchedulePalette.title,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                _GhostCircleButton(
                  icon: Icons.arrow_forward_ios_rounded,
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          AppGap.w8,
          _ScheduleFavoriteFilterButton(
            isSelected: _showFavoritesOnly,
            count: favoriteCount,
            onTap: _toggleFavoriteFilter,
          ),
        ],
      ),
    );
  }

  Widget _buildSplitLayout({
    required BuildContext context,
    required Widget header,
    required Map<String, ProjectSummary> projectLookup,
    required List<ProjectTodo> visibleTodos,
    required Map<DateTime, Holiday> holidayMap,
    required DateTime selectedDay,
    required List<_ScheduledTodo> selectedTodos,
    required int? currentUserId,
    required Future<void> Function(
      ProjectTodo todo,
      DateTime occurrence,
      ProjectSummary? project,
      bool canManage,
    )
    openTodoActions,
  }) {
    if (!_dayPanelListScrollable.value) {
      _dayPanelListScrollable.value = true;
    }

    final selectedKey = DateUtils.dateOnly(selectedDay);
    const horizontalPadding = 7.0;
    const spacing = 15.0;

    final calendarContent = Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: SizedBox(
            key: _weekdayHeaderKey,
            child: _CalendarWeekdayHeader(
              textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _SchedulePalette.weekdays,
              ),
            ),
          ),
        ),
        AppGap.h4,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: PageView.builder(
              controller: _monthPageController,
              onPageChanged: _handlePageChanged,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final offset = index - _initialPageIndex;
                final month = DateTime(
                  _initialMonth.year,
                  _initialMonth.month + offset,
                  1,
                );
                final monthDays = _visibleDaysFor(month);
                final monthTodoMap = _buildDayTodoMap(visibleTodos, monthDays);
                return _MonthGrid(
                  days: monthDays,
                  focusedMonth: month,
                  selectedDay: selectedDay,
                  dayTodoMap: monthTodoMap,
                  holidayMap: holidayMap,
                  onDaySelected: _handleDayTap,
                  isExpanded: true,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  bottomPadding: 0,
                );
              },
            ),
          ),
        ),
      ],
    );

    final dayPanel = _DayScheduleCard(
      day: selectedDay,
      todos: selectedTodos,
      todosForDay: (day) => _buildSelectedDayTodos(visibleTodos, day),
      projectLookup: projectLookup,
      currentUserId: currentUserId,
      onTodoTap: openTodoActions,
      onAddTodo: () => _handleAddTodo(context, selectedDay),
      onDaySwipe: _handleDayTap,
      isListScrollable: _dayPanelListScrollable,
      holiday: holidayMap[selectedKey],
      showDragHandle: false,
      borderRadius: BorderRadius.circular(24),
    );

    return Scaffold(
      backgroundColor: _SchedulePalette.background,
      body: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  header,
                  Expanded(child: calendarContent),
                ],
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 0.6,
              color: _SchedulePalette.divider,
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                child: dayPanel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDayTap(DateTime day) {
    final changed = _viewModel.updateSelectedDay(day);
    if (changed) {
      setState(() {});
    }
    _persistAppSelectedDay();
  }

  void _persistAppSelectedDay() {
    final currentSelectedDay =
        _selectedDay ?? DateUtils.dateOnly(DateTime.now());
    unawaited(ScheduleHomeWidgetService.setAppSelectedDay(currentSelectedDay));
  }

  void _syncWidgetPreviewIfNeeded({
    required List<ProjectTodo> todos,
    required List<Holiday> holidays,
  }) {
    final signature = _buildWidgetPreviewSignature(
      todos: todos,
      holidays: holidays,
    );
    if (_lastWidgetPreviewSignature == signature) {
      return;
    }
    _lastWidgetPreviewSignature = signature;
    ScheduleHomeWidgetService.scheduleUpdateFromTodos(
      _mapWidgetTodos(todos),
      holidays: _mapWidgetHolidays(holidays),
    );
  }

  String _buildWidgetPreviewSignature({
    required List<ProjectTodo> todos,
    required List<Holiday> holidays,
  }) {
    final buffer = StringBuffer();
    for (final todo in todos) {
      buffer
        ..write(todo.id)
        ..write('|')
        ..write(todo.projectId)
        ..write('|')
        ..write(todo.status)
        ..write('|')
        ..write(todo.isHidden)
        ..write('|')
        ..write(todo.updatedAt.toIso8601String())
        ..write(';');
    }
    buffer.write('#');
    for (final holiday in holidays) {
      buffer
        ..write(holiday.date.toIso8601String())
        ..write('|')
        ..write(holiday.name)
        ..write('|')
        ..write(holiday.isHoliday)
        ..write(';');
    }
    return buffer.toString();
  }

  List<ScheduleWidgetTodo> _mapWidgetTodos(List<ProjectTodo> todos) {
    return todos
        .map(
          (todo) => ScheduleWidgetTodo(
            id: todo.id,
            title: todo.title,
            status: todo.status,
            isRecurring: todo.isRecurring,
            isHidden: todo.isHidden,
            startDate: todo.startDate,
            startTime: todo.startTime,
            weekdayMask: todo.weekdayMask,
            endDate: todo.endDate,
            endTime: todo.endTime,
            completedAt: todo.completedAt,
            updatedAt: todo.updatedAt,
          ),
        )
        .toList(growable: false);
  }

  List<ScheduleWidgetHoliday> _mapWidgetHolidays(List<Holiday> holidays) {
    return holidays
        .map(
          (holiday) => ScheduleWidgetHoliday(
            date: holiday.date,
            name: holiday.name,
            isHoliday: holiday.isHoliday,
          ),
        )
        .toList(growable: false);
  }

  // 달력에서 날짜 직접 선택 다이얼로그를 열고 결과 날짜로 점프합니다.
  Future<void> _pickCalendarDate(BuildContext context) async {
    final initial = _selectedDay ?? DateUtils.dateOnly(DateTime.now());
    final selected = await _pickDate(context, initial);
    if (selected == null) {
      return;
    }
    _jumpToDate(selected);
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime initial) async {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: Colors.white,
              headerForegroundColor: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  void _jumpToDate(DateTime date) {
    final jumpResult = _viewModel.jumpToDate(date);
    setState(() {});
    _persistAppSelectedDay();

    try {
      _monthPageController.animateToPage(
        jumpResult.targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}
  }

  Future<bool?> _handleAddTodo(
    BuildContext context,
    DateTime selectedDay,
  ) async {
    return context.push<bool>(
      AppRoutePaths.projectTodoEditor,
      extra: AddProjectTodoArgs(
        allowProjectSelection: true,
        initialSelectedDate: DateUtils.dateOnly(selectedDay),
      ),
    );
  }

  void _changeMonth(int offset) {
    final targetPage = _viewModel.resolveTargetPageForMonthOffset(offset);
    if (targetPage == null) {
      return;
    }
    _monthPageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  // PageView의 인덱스를 실제 년/월로 환산해 포커스 월 상태를 동기화합니다.
  void _handlePageChanged(int pageIndex) {
    final changed = _viewModel.updatePageIndex(pageIndex);
    if (!changed) {
      return;
    }
    setState(() {});
  }

  List<DateTime> _visibleDaysFor(DateTime month) {
    return _viewModel.visibleDaysFor(month);
  }

  Map<DateTime, List<_ScheduledTodo>> _buildDayTodoMap(
    List<ProjectTodo> todos,
    List<DateTime> days,
  ) {
    return _viewModel.buildDayTodoMap(todos, days);
  }

  List<_ScheduledTodo> _buildSelectedDayTodos(
    List<ProjectTodo> todos,
    DateTime day,
  ) {
    return _viewModel.buildSelectedDayTodos(todos, day);
  }

  String _resolveErrorMessage(Object error) {
    return _viewModel.resolveErrorMessage(error);
  }

  Future<void> _openTodoActions({
    required BuildContext context,
    required ProjectSummary project,
    required ProjectTodo todo,
    required DateTime occurrenceDate,
    required bool canManage,
  }) async {
    final sheetContext = rootNavigatorKey.currentContext ?? context;
    final selected = await showModalBottomSheet<_ScheduleTodoAction>(
      context: sheetContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (sheetContext) {
        final toggleLabel = todo.isCompleted ? '미완료로 변경'.tr() : '완료로 변경'.tr();
        final toggleIcon = todo.isCompleted
            ? Icons.radio_button_unchecked_rounded
            : Icons.check_circle_rounded;
        final currentStatusLabel = todo.isCompleted ? '완료'.tr() : '미완료'.tr();
        final visibilityTitle = todo.isHidden ? '다시 표시'.tr() : '표시 안 함'.tr();
        final visibilitySubtitle = todo.isHidden
            ? '알림이 오며 캘린더에 표시됩니다.'.tr()
            : '알림이 오지 않고 캘린더에 표시되지 않습니다.'.tr();
        final visibilityIcon = todo.isHidden
            ? Icons.visibility_rounded
            : Icons.visibility_off_outlined;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(
              top: BorderSide(color: AppTokens.divider, width: 0.6),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTokens.handle,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  AppGap.h14,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              todo.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppTokens.textPrimary,
                              ),
                            ),
                            AppGap.h6,
                            Text(
                              project.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppTokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppTokens.textSecondary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  if (canManage) AppGap.h16,
                  if (canManage)
                    _ScheduleTodoActionTile(
                      icon: Icons.edit_rounded,
                      title: '일정 편집'.tr(),
                      subtitle: '상세 내용 및 일정 수정'.tr(),
                      onTap: () => Navigator.of(
                        sheetContext,
                      ).pop(_ScheduleTodoAction.edit),
                    ),
                  if (canManage) AppGap.h10,
                  if (canManage)
                    _ScheduleTodoActionTile(
                      icon: toggleIcon,
                      title: toggleLabel,
                      subtitle: '현재 상태: {status}'.tr(
                        namedArgs: {'status': currentStatusLabel},
                      ),
                      onTap: () => Navigator.of(
                        sheetContext,
                      ).pop(_ScheduleTodoAction.toggleCompletion),
                    ),
                  AppGap.h10,
                  _ScheduleTodoActionTile(
                    icon: visibilityIcon,
                    title: visibilityTitle,
                    subtitle: visibilitySubtitle,
                    onTap: () => Navigator.of(
                      sheetContext,
                    ).pop(_ScheduleTodoAction.toggleVisibility),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected == null || !context.mounted) {
      return;
    }

    switch (selected) {
      case _ScheduleTodoAction.toggleCompletion:
        await _toggleCompletion(
          context: context,
          projectId: project.id,
          todo: todo,
        );
      case _ScheduleTodoAction.toggleVisibility:
        await _toggleVisibility(
          context: context,
          projectId: project.id,
          todo: todo,
        );
      case _ScheduleTodoAction.edit:
        await _editTodo(
          context: context,
          project: project,
          todo: todo,
          occurrenceDate: occurrenceDate,
        );
    }
  }

  VoidCallback _showBlockingLoadingDialog(BuildContext context) {
    final dialogContext = rootNavigatorKey.currentContext ?? context;
    showDialog<void>(
      context: dialogContext,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    return () {
      final navigator = Navigator.of(dialogContext, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
    };
  }

  Future<void> _toggleCompletion({
    required BuildContext context,
    required String projectId,
    required ProjectTodo todo,
  }) async {
    final close = _showBlockingLoadingDialog(context);
    late final SimpleResult<ProjectTodo, ApiError> result;
    try {
      result = await _viewModel.toggleCompletion(todo: todo);
    } finally {
      close();
    }

    if (!context.mounted) {
      return;
    }

    if (result.isSuccess) {
      _syncAfterTodoMutation(projectId: projectId);
      return;
    }
  }

  Future<void> _toggleVisibility({
    required BuildContext context,
    required String projectId,
    required ProjectTodo todo,
  }) async {
    final close = _showBlockingLoadingDialog(context);
    late final SimpleResult<bool, ApiError> result;
    try {
      result = await _viewModel.toggleVisibility(todo: todo);
    } finally {
      close();
    }

    if (!context.mounted) {
      return;
    }

    if (result.isSuccess) {
      _syncAfterTodoMutation(projectId: projectId);
      return;
    }
  }

  Future<void> _editTodo({
    required BuildContext context,
    required ProjectSummary project,
    required ProjectTodo todo,
    required DateTime occurrenceDate,
  }) async {
    final updated = await context.push<bool>(
      AppRoutePaths.projectTodoEditor,
      extra: AddProjectTodoArgs(
        project: project,
        initialTodo: todo,
        initialSelectedDate: occurrenceDate,
      ),
    );
    if (updated == true && context.mounted) {
      _syncAfterTodoMutation(projectId: project.id);
    }
  }

  void _syncAfterTodoMutation({required String projectId}) {
    ref.invalidate(scheduleTodosProvider);
    ref.invalidate(projectTodosProvider(projectId));
    unawaited(ref.read(syncCoordinatorProvider).trigger(SyncReason.userAction));
  }

  Widget _buildLoadingScaffold() {
    return const Scaffold(
      backgroundColor: _SchedulePalette.background,
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorScaffold(String message, VoidCallback onRetry) {
    return Scaffold(
      backgroundColor: _SchedulePalette.background,
      body: _ScheduleErrorState(message: message, onRetry: onRetry),
    );
  }
}

class _ScheduleFavoriteFilterButton extends StatelessWidget {
  const _ScheduleFavoriteFilterButton({
    required this.isSelected,
    required this.count,
    required this.onTap,
  });

  final bool isSelected;
  final int count;
  final VoidCallback onTap;

  static const _favoriteAccent = AppTokens.favoriteAccent;
  static const _favoriteBackground = AppTokens.favoriteBackground;
  static const _favoriteBorder = AppTokens.favoriteBorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isSelected ? _favoriteBackground : Colors.white;
    final border = isSelected ? _favoriteBorder : _SchedulePalette.divider;
    final icon = isSelected ? Icons.star_rounded : Icons.star_border_rounded;
    final iconColor = isSelected ? _favoriteAccent : _SchedulePalette.subtitle;
    final textColor = isSelected ? _favoriteAccent : _SchedulePalette.subtitle;
    final label = count > 0
        ? '즐겨찾기 {count}'.tr(namedArgs: {'count': count.toString()})
        : '즐겨찾기'.tr();

    return SizedBox(
      height: 38,
      child: Tap(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: 0.6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: iconColor),
              AppGap.w4,
              AutoSizeText(
                label,
                maxLines: 1,
                minFontSize: 8.0,
                maxFontSize: 16.0,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
