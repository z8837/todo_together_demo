part of 'schedule_fragment.dart';

class _DayScheduleCard extends StatefulWidget {
  const _DayScheduleCard({
    required this.day,
    required this.todos,
    required this.todosForDay,
    required this.projectLookup,
    required this.currentUserId,
    required this.onTodoTap,
    required this.onAddTodo,
    required this.onDaySwipe,
    required this.isListScrollable,
    required this.holiday,
    this.headerKey,
    this.onHeaderDragStart,
    this.onHeaderDragUpdate,
    this.onHeaderDragEnd,
    this.showDragHandle = true,
    this.borderRadius,
  });

  final DateTime day;
  final List<_ScheduledTodo> todos;
  final List<_ScheduledTodo> Function(DateTime day) todosForDay;
  final Map<String, ProjectSummary> projectLookup;
  final int? currentUserId;
  final Holiday? holiday;
  final void Function(
    ProjectTodo todo,
    DateTime occurrence,
    ProjectSummary? project,
    bool canManage,
  )
  onTodoTap;
  final VoidCallback onAddTodo;
  final ValueChanged<DateTime> onDaySwipe;
  final Key? headerKey;
  final GestureDragStartCallback? onHeaderDragStart;
  final GestureDragUpdateCallback? onHeaderDragUpdate;
  final GestureDragEndCallback? onHeaderDragEnd;
  final ValueNotifier<bool> isListScrollable;
  final bool showDragHandle;
  final BorderRadiusGeometry? borderRadius;

  @override
  State<_DayScheduleCard> createState() => _DayScheduleCardState();
}

class _DayScheduleCardState extends State<_DayScheduleCard> {
  static const int _initialPageIndex = 10000;

  late final PageController _pageController;
  DateTime _anchorDay = DateTime(1970, 1, 1);
  int _anchorPageIndex = _initialPageIndex;

  @override
  void initState() {
    super.initState();
    _anchorDay = DateUtils.dateOnly(widget.day);
    _pageController = PageController(initialPage: _initialPageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _DayScheduleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameDay(oldWidget.day, widget.day)) {
      _anchorDay = DateUtils.dateOnly(widget.day);
      if (_pageController.hasClients) {
        _anchorPageIndex = _pageController.page?.round() ?? _anchorPageIndex;
      }
    }
  }

  void _handleDayPageChanged(int pageIndex) {
    if (pageIndex == _anchorPageIndex) return;

    if (_anchorDay.year == 1970) {
      _anchorDay = DateUtils.dateOnly(widget.day);
    }

    final deltaDays = pageIndex - _anchorPageIndex;
    final nextDay = DateUtils.dateOnly(
      _anchorDay.add(Duration(days: deltaDays)),
    );

    _anchorDay = nextDay;
    _anchorPageIndex = pageIndex;
    widget.onDaySwipe(nextDay);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomSafeInset = MediaQuery.of(context).viewPadding.bottom;
    final bottomScrollPadding = 16.0 + bottomSafeInset;
    final resolvedRadius =
        widget.borderRadius ??
        const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        );
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          color: AppSystemUi.mainSurface,
          borderRadius: resolvedRadius,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: resolvedRadius,
          border: const Border.fromBorderSide(
            BorderSide(color: AppSystemUi.outline, width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              key: widget.headerKey,
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: widget.onHeaderDragStart,
                onVerticalDragUpdate: widget.onHeaderDragUpdate,
                onVerticalDragEnd: widget.onHeaderDragEnd,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatFullDate(widget.day),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: _SchedulePalette.title,
                            ),
                          ),
                          AppGap.h2,
                          Row(
                            children: [
                              Text(
                                _weekdayKorean(widget.day),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _SchedulePalette.subtitle,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (widget.holiday != null &&
                                  widget.holiday!.name.isNotEmpty) ...[
                                AppGap.w8,
                                Flexible(
                                  child: Text(
                                    widget.holiday!.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: widget.holiday!.isHoliday
                                          ? _SchedulePalette.holiday
                                          : _SchedulePalette.subtitle,
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: widget.showDragHandle
                          ? Icon(
                              Icons.drag_handle_rounded,
                              size: 22,
                              color: _SchedulePalette.subtitle,
                            )
                          : AppGap.w12,
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _AddTodoButton(onPressed: widget.onAddTodo),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: _handleDayPageChanged,
                itemBuilder: (context, index) {
                  final day = DateUtils.dateOnly(
                    _anchorDay.add(Duration(days: index - _anchorPageIndex)),
                  );
                  return _DayScheduleList(
                    todos: widget.todosForDay(day),
                    projectLookup: widget.projectLookup,
                    currentUserId: widget.currentUserId,
                    onTodoTap: widget.onTodoTap,
                    isListScrollable: widget.isListScrollable,
                    bottomScrollPadding: bottomScrollPadding,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayScheduleList extends StatelessWidget {
  const _DayScheduleList({
    required this.todos,
    required this.projectLookup,
    required this.currentUserId,
    required this.onTodoTap,
    required this.isListScrollable,
    required this.bottomScrollPadding,
  });

  final List<_ScheduledTodo> todos;
  final Map<String, ProjectSummary> projectLookup;
  final int? currentUserId;
  final void Function(
    ProjectTodo todo,
    DateTime occurrence,
    ProjectSummary? project,
    bool canManage,
  )
  onTodoTap;
  final ValueNotifier<bool> isListScrollable;
  final double bottomScrollPadding;

  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty) {
      return ValueListenableBuilder<bool>(
        valueListenable: isListScrollable,
        builder: (context, scrollable, _) {
          return ListView(
            primary: false,
            physics: scrollable
                ? const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  )
                : const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: const [_EmptyDayMessage()],
          );
        },
      );
    }
    final sortedTodos = _ScheduleFragmentViewModel.sortTodosForDayPanel(
      List<_ScheduledTodo>.from(todos),
    );

    return ValueListenableBuilder<bool>(
      valueListenable: isListScrollable,
      builder: (context, scrollable, _) {
        return ListView.separated(
          primary: false,
          physics: scrollable
              ? const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                )
              : const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: bottomScrollPadding),
          itemCount: sortedTodos.length,
          separatorBuilder: (_, _) => const Divider(
            height: 1,
            thickness: 0.6,
            color: _SchedulePalette.divider,
          ),
          itemBuilder: (context, index) {
            final entry = sortedTodos[index];
            final todo = entry.todo;
            final project = projectLookup[todo.projectId];
            final accent = ProjectColorResolver.resolve(todo.projectId);
            final isCompleted = todo.isCompleted;
            final isSingleOverdue =
                !todo.isRecurring &&
                !isCompleted &&
                _isScheduleOverdue(todo, DateTime.now());
            final userId = currentUserId;
            final canManage = _ScheduleFragmentViewModel.canManageTodo(
              userId: userId,
              project: project,
              todo: todo,
            );
            return _TodoRow(
              title: todo.title,
              timeLabel: _formatKoreanTime(todo, entry.date),
              alarmOffsetMinutes: todo.alarmOffsetMinutes,
              tagLabel: project?.name ?? '미분류'.tr(),
              createdByNickname: todo.createdBy.nickname,
              accent: accent,
              isRecurring: todo.isRecurring,
              status: todo.status,
              isCompleted: isCompleted,
              isSingleOverdue: isSingleOverdue,
              canManage: canManage,
              onTap: () {
                onTodoTap(todo, entry.date, project, canManage);
              },
            );
          },
        );
      },
    );
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({
    required this.title,
    required this.timeLabel,
    required this.alarmOffsetMinutes,
    required this.tagLabel,
    required this.createdByNickname,
    required this.accent,
    required this.isRecurring,
    required this.status,
    required this.isCompleted,
    required this.isSingleOverdue,
    required this.canManage,
    required this.onTap,
  });

  final String title;
  final String timeLabel;
  final int? alarmOffsetMinutes;
  final String tagLabel;
  final String createdByNickname;
  final Color accent;
  final bool isRecurring;
  final String status;
  final bool isCompleted;
  final bool isSingleOverdue;
  final bool canManage;
  final VoidCallback onTap;

  static const Color _doneForeground = AppTokens.textDisabled;

  static const Color _titleColor = _SchedulePalette.title;
  static const Color _mutedText = _SchedulePalette.subtitle;

  @override
  Widget build(BuildContext context) {
    final scheduleTypeLabel = isRecurring ? '반복'.tr() : '단일'.tr();
    final titleColor = isCompleted ? _doneForeground : _titleColor;
    final metaColor = isCompleted ? _doneForeground : _mutedText;
    final overdueColor = AppTokens.danger;
    final timeLabelColor = isSingleOverdue ? overdueColor : metaColor;
    final scheduleTypeColor = isCompleted
        ? _doneForeground
        : (isRecurring ? AppTokens.todoRecurring : AppTokens.todoSingle);

    final alarmColor = alarmOffsetMinutes == null
        ? (isCompleted ? _doneForeground : _mutedText)
        : AppTokens.warning;

    return Opacity(
      opacity: isCompleted ? 0.55 : 1,
      child: Tap(
        borderRadius: BorderRadius.zero,
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: scheduleTypeLabel,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: scheduleTypeColor,
                                  fontWeight: FontWeight.w700,
                                ),
                            children: [
                              TextSpan(
                                text: ' · ',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: metaColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Icon(
                                    Icons.folder_rounded,
                                    size: 12,
                                    color: metaColor,
                                  ),
                                ),
                              ),
                              TextSpan(
                                text: tagLabel,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: metaColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppGap.h6,
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                                color: titleColor,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor: _doneForeground,
                              ),
                        ),
                        AppGap.h6,
                        Text(
                          timeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: timeLabelColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        AppGap.h4,
                        Text(
                          _formatAlarmLabel(alarmOffsetMinutes),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: alarmColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  AppGap.w8,
                  Icon(Icons.chevron_right_rounded, size: 18, color: metaColor),
                ],
              ),
            ),
            Positioned(
              right: 22,
              bottom: 12,
              child: Text(
                createdByNickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isCompleted ? _doneForeground : _mutedText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleTodoActionTile extends StatelessWidget {
  const _ScheduleTodoActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tap(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: AppInsets.h14v14,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTokens.divider, width: 0.6),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTokens.surfaceIcon,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTokens.textPrimary, size: 18),
            ),
            AppGap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: AppTokens.textPrimary,
                    ),
                  ),
                  AppGap.h3,
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTokens.textMuted),
          ],
        ),
      ),
    );
  }
}

class _EmptyDayMessage extends StatelessWidget {
  const _EmptyDayMessage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleStyle = theme.textTheme.bodyLarge ?? const TextStyle();
        final subtitleStyle = theme.textTheme.bodySmall ?? const TextStyle();
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final titleHeight =
            (titleStyle.fontSize ?? 16) *
            textScale *
            (titleStyle.height ?? 1.0);
        final subtitleHeight =
            (subtitleStyle.fontSize ?? 12) *
            textScale *
            (subtitleStyle.height ?? 1.0);
        const verticalPadding = 20.0;
        const spacing = 4.0;
        final minContentHeight = titleHeight + spacing + subtitleHeight;
        final minTotalHeight = minContentHeight + verticalPadding;

        if (constraints.maxHeight < minTotalHeight) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '등록된 TODO가 없어요.'.tr(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _SchedulePalette.subtitle,
                ),
              ),
              AppGap.h4,
              Text(
                '새로운 TODO를 추가하려면 위의 + 버튼을 누르세요.'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _SchedulePalette.subtitle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GhostCircleButton extends StatelessWidget {
  const _GhostCircleButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: _SchedulePalette.title, size: 20),
      style: IconButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(10),
        backgroundColor: Colors.white.withAlpha(0),
      ),
    );
  }
}

class _AddTodoButton extends StatelessWidget {
  const _AddTodoButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 18),
      splashRadius: 20,
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(36, 36),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _SchedulePalette.primary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

String _formatAlarmLabel(int? minutes) {
  if (minutes == null) {
    return '알림 없음'.tr();
  }
  if (minutes == 0) {
    return '시작 시간 알림'.tr();
  }
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  final parts = <String>[];
  if (hours > 0) {
    parts.add('{hours}시간'.tr(namedArgs: {'hours': hours.toString()}));
  }
  if (mins > 0) {
    parts.add('{minutes}분'.tr(namedArgs: {'minutes': mins.toString()}));
  }
  final label = parts.join(' ');
  return '시작 {label} 전 알림'.tr(namedArgs: {'label': label});
}
