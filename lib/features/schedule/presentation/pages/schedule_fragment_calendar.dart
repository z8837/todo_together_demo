part of 'schedule_fragment.dart';

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.days,
    required this.focusedMonth,
    required this.selectedDay,
    required this.dayTodoMap,
    required this.holidayMap,
    required this.onDaySelected,
    required this.isExpanded,
    this.mainAxisSpacing = 15.0,
    this.crossAxisSpacing = 15.0,
    this.bottomPadding = 15.0,
  });

  final List<DateTime> days;
  final DateTime focusedMonth;
  final DateTime selectedDay;
  final Map<DateTime, List<_ScheduledTodo>> dayTodoMap;
  final Map<DateTime, Holiday> holidayMap;
  final ValueChanged<DateTime> onDaySelected;
  final bool isExpanded;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const crossAxisCount = 7;
          const dateCircleWidth = 46.0;
          const dateCircleHeight = 34.0;
          const topPadding = 0.0;
          const gapBelowDate = 0.0;
          const todoLineHeight = 13.0;
          const double todoStepGranularity = 0.1;
          final double todoFontSize = (todoLineHeight * 0.8)
              .clamp(8.0, 12.0)
              .toDouble();
          final columnSpacing = crossAxisSpacing * 0;
          final rowSpacing = mainAxisSpacing * 0;
          final unitWidth =
              (constraints.maxWidth - columnSpacing * (crossAxisCount - 1)) /
              crossAxisCount;
          final gridDays = _visibleMonthDaysInRows(days);
          final rowCount = (gridDays.length / crossAxisCount).ceil();
          final maxGridHeight = (constraints.maxHeight - bottomPadding).clamp(
            0.0,
            double.infinity,
          );
          final spacingSlots = rowCount > 1 ? rowCount - 1 : 0;

          final availableHeight = (maxGridHeight - rowSpacing * spacingSlots)
              .clamp(0.0, double.infinity);
          final unitHeight = rowCount > 0
              ? (availableHeight / rowCount).clamp(0.0, double.infinity)
              : unitWidth;
          final gridHeight = unitHeight * rowCount + rowSpacing * spacingSlots;
          final availableForTodos =
              (unitHeight - topPadding - dateCircleHeight - gapBelowDate).clamp(
                0.0,
                double.infinity,
              );
          final maxTodoLines = (availableForTodos / todoLineHeight).floor();
          final dayIndex = <DateTime, int>{
            for (var i = 0; i < gridDays.length; i++)
              DateUtils.dateOnly(gridDays[i]): i,
          };
          final rangeLayout = _buildRangeLayout(
            dayIndex,
            rowCount: rowCount,
            maxLines: maxTodoLines,
          );
          final rangePlacements = rangeLayout.placements;
          final dayLineMasks = rangeLayout.dayLineMasks;
          final dayBarTodoIds = rangeLayout.dayBarTodoIds;
          final hasRangeBars = rangePlacements.isNotEmpty;
          final now = DateTime.now();

          Widget buildDay(int index) {
            final day = gridDays[index];
            final key = DateUtils.dateOnly(day);
            final isSelected = DateUtils.isSameDay(day, selectedDay);
            final isToday = DateUtils.isSameDay(day, now);
            final isCurrentMonth = day.month == focusedMonth.month;
            final holiday = holidayMap[key];
            final todos = _sortTodos(
              List<_ScheduledTodo>.from(
                dayTodoMap[key] ?? const <_ScheduledTodo>[],
              ),
            );

            return LayoutBuilder(
              builder: (context, _) {
                final filteredTodos = hasRangeBars
                    ? todos.where((entry) {
                        final todo = entry.todo;
                        if (_isMultiDayTodo(todo)) {
                          return false;
                        }
                        if (todo.isRecurring &&
                            dayBarTodoIds[index].contains(todo.id)) {
                          return false;
                        }
                        return true;
                      }).toList()
                    : todos;
                final lineMask = hasRangeBars ? dayLineMasks[index] : 0;
                final freeLines = <int>[
                  for (var line = 0; line < maxTodoLines; line++)
                    if ((lineMask & (1 << line)) == 0) line,
                ];
                final visibleTodos = freeLines.isEmpty
                    ? const <_ScheduledTodo>[]
                    : filteredTodos.take(freeLines.length).toList();
                final isSingleTodoLine =
                    !isExpanded && visibleTodos.length == 1;

                String? resolveSingleLineTodoId(DateTime day) {
                  if (isExpanded) {
                    return null;
                  }
                  final dayKey = DateUtils.dateOnly(day);
                  final dayTodos = _sortTodos(
                    List<_ScheduledTodo>.from(
                      dayTodoMap[dayKey] ?? const <_ScheduledTodo>[],
                    ),
                  );
                  if (dayTodos.isEmpty) {
                    return null;
                  }
                  final filtered = hasRangeBars
                      ? dayTodos.where((entry) {
                          final index = dayIndex[dayKey] ?? 0;
                          final todo = entry.todo;
                          if (_isMultiDayTodo(todo) &&
                              dayBarTodoIds[index].contains(todo.id)) {
                            return false;
                          }
                          if (todo.isRecurring &&
                              dayBarTodoIds[index].contains(todo.id)) {
                            return false;
                          }
                          return true;
                        }).toList()
                      : dayTodos;
                  if (filtered.isEmpty) {
                    return null;
                  }
                  final index = dayIndex[dayKey] ?? 0;
                  final lineMask = hasRangeBars ? dayLineMasks[index] : 0;
                  final freeLines = <int>[
                    for (var line = 0; line < maxTodoLines; line++)
                      if ((lineMask & (1 << line)) == 0) line,
                  ];
                  if (freeLines.isEmpty) {
                    return null;
                  }
                  final visible = filtered.take(freeLines.length).toList();
                  if (visible.length != 1) {
                    return null;
                  }
                  return visible.first.todo.id;
                }

                final currentTodoId = isSingleTodoLine
                    ? visibleTodos.first.todo.id
                    : null;
                final prevTodoId = currentTodoId == null
                    ? null
                    : resolveSingleLineTodoId(
                        key.subtract(const Duration(days: 1)),
                      );
                final nextTodoId = currentTodoId == null
                    ? null
                    : resolveSingleLineTodoId(key.add(const Duration(days: 1)));
                final hasPrevSame =
                    currentTodoId != null && prevTodoId == currentTodoId;
                final hasNextSame =
                    currentTodoId != null && nextTodoId == currentTodoId;
                final showSingleLineTitle =
                    currentTodoId != null &&
                    _shouldShowSingleLineTitle(
                      todoId: currentTodoId,
                      day: key,
                      dayIndex: dayIndex,
                      days: gridDays,
                      resolveSingleLineTodoId: resolveSingleLineTodoId,
                    );

                final hasBadge = todos.isNotEmpty;
                final hasHolidayLabel =
                    holiday != null && holiday.name.isNotEmpty;
                final isSunday = day.weekday == DateTime.sunday;
                final holidayTextColor = holiday?.isHoliday == true
                    ? (isCurrentMonth
                          ? _SchedulePalette.holiday
                          : _SchedulePalette.subHoliday)
                    : _SchedulePalette.subtitle;
                final dateTextColor = isToday
                    ? _SchedulePalette.primary
                    : holiday?.isHoliday == true
                    ? (isCurrentMonth
                          ? _SchedulePalette.holiday
                          : _SchedulePalette.subHoliday)
                    : isSunday
                    ? (isCurrentMonth
                          ? _SchedulePalette.holiday
                          : _SchedulePalette.subHoliday)
                    : isCurrentMonth
                    ? _SchedulePalette.title
                    : _SchedulePalette.subtitle;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: dateCircleWidth,
                          height: dateCircleHeight,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _SchedulePalette.primarySoft
                                : Colors.transparent,
                            shape: BoxShape.rectangle,
                            // border: isSelected
                            //     ? Border.all(
                            //         color: _SchedulePalette.primary.withAlpha(120),
                            //         width: 0,
                            //       )
                            //     : null,
                            borderRadius: BorderRadiusGeometry.all(
                              Radius.circular(6.0),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.0,
                                  color: dateTextColor,
                                ),
                          ),
                        ),
                        if (hasHolidayLabel)
                          Positioned(
                            bottom: 0,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: dateCircleWidth,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 0.8,
                                ),
                                child: Text(
                                  holiday.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.start,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 8.5,
                                        color: holidayTextColor,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        if (hasBadge)
                          Positioned(
                            right: 1,
                            top: 1,
                            child: _TodoCountBadge(
                              count: todos.length,
                              isHighlighted: isSelected,
                            ),
                          ),
                      ],
                    ),
                    if (visibleTodos.isNotEmpty)
                      const SizedBox(height: gapBelowDate),
                    if (visibleTodos.isNotEmpty)
                      SizedBox(
                        height: maxTodoLines * todoLineHeight,
                        child: Stack(
                          children: [
                            for (var i = 0; i < visibleTodos.length; i++)
                              Positioned(
                                top: freeLines[i] * todoLineHeight,
                                left: 0,
                                right: 0,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: 0.7,
                                    right: 0.7,
                                  ),
                                  child: SizedBox(
                                    height: todoLineHeight,
                                    child: DecoratedBox(
                                      decoration: _todoDecoration(
                                        visibleTodos[i].todo,
                                        isSingleLine: isSingleTodoLine,
                                        hasPrev: hasPrevSame,
                                        hasNext: hasNextSame,
                                      ),
                                      child: Center(
                                        child: AutoSizeText(
                                          isSingleTodoLine &&
                                                  !showSingleLineTitle
                                              ? ''
                                              : visibleTodos[i].todo.title,
                                          maxLines: 1,
                                          maxFontSize: 10.0,
                                          minFontSize: 10.0,
                                          stepGranularity: todoStepGranularity,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    isSingleTodoLine &&
                                                        (hasPrevSame ||
                                                            hasNextSame)
                                                    ? Colors.white
                                                    : _todoTextColor(
                                                        visibleTodos[i].todo,
                                                      ),
                                                decoration:
                                                    visibleTodos[i]
                                                        .todo
                                                        .isCompleted
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                                decorationColor:
                                                    visibleTodos[i]
                                                        .todo
                                                        .isCompleted
                                                    ? AppTokens.todoCompleted
                                                    : null,
                                                fontSize: todoFontSize,
                                                height: 1.0,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            );
          }

          void handleTap(Offset position) {
            final dx = position.dx.clamp(0, constraints.maxWidth);
            final dy = position.dy.clamp(0, gridHeight);
            final unitX = unitWidth + columnSpacing;
            final unitY = unitHeight + rowSpacing;

            int column = (dx / unitX).floor();
            if (column >= crossAxisCount) {
              column = crossAxisCount - 1;
            }
            double remainderX = dx - column * unitX;
            if (remainderX > unitWidth) {
              final gap = remainderX - unitWidth;
              final distanceToLeft = gap;
              final distanceToRight = columnSpacing - gap;
              if (distanceToRight < distanceToLeft &&
                  column < crossAxisCount - 1) {
                column += 1;
              }
            }

            int row = (dy / unitY).floor();
            if (row >= rowCount) {
              row = rowCount - 1;
            }
            double remainderY = dy - row * unitY;
            if (remainderY > unitHeight) {
              final gap = remainderY - unitHeight;
              final distanceToTop = gap;
              final distanceToBottom = rowSpacing - gap;
              if (distanceToBottom < distanceToTop && row < rowCount - 1) {
                row += 1;
              }
            }

            final index = row * crossAxisCount + column;
            if (index >= 0 && index < gridDays.length) {
              onDaySelected(gridDays[index]);
            }
          }

          return Column(
            children: [
              SizedBox(
                height: constraints.maxHeight,
                width: constraints.maxWidth,
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: bottomPadding),
                      child: Column(
                        children: [
                          for (int row = 0; row < rowCount; row++) ...[
                            SizedBox(
                              height: unitHeight,
                              child: Row(
                                children: [
                                  for (
                                    int col = 0;
                                    col < crossAxisCount;
                                    col++
                                  ) ...[
                                    Expanded(
                                      child: buildDay(
                                        row * crossAxisCount + col,
                                      ),
                                    ),
                                    if (col < crossAxisCount - 1)
                                      SizedBox(width: columnSpacing),
                                  ],
                                ],
                              ),
                            ),
                            if (row < rowCount - 1)
                              SizedBox(height: rowSpacing),
                          ],
                        ],
                      ),
                    ),
                    if (rangePlacements.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: _RangeOverlay(
                            placements: rangePlacements,
                            rowHeight: unitHeight,
                            rowSpacing: rowSpacing,
                            unitWidth: unitWidth,
                            columnSpacing: columnSpacing,
                            topOffset:
                                topPadding + dateCircleHeight + gapBelowDate,
                            lineHeight: todoLineHeight,
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapDown: (details) =>
                            handleTap(details.localPosition),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<DateTime> _visibleMonthDaysInRows(List<DateTime> monthDays) {
    final firstInMonthIndex = monthDays.indexWhere((day) {
      return day.year == focusedMonth.year && day.month == focusedMonth.month;
    });
    final lastInMonthIndex = monthDays.lastIndexWhere((day) {
      return day.year == focusedMonth.year && day.month == focusedMonth.month;
    });
    if (firstInMonthIndex == -1 || lastInMonthIndex == -1) {
      return monthDays;
    }
    final startIndex = (firstInMonthIndex ~/ 7) * 7;
    final endExclusive = min(
      monthDays.length,
      ((lastInMonthIndex ~/ 7) + 1) * 7,
    );
    return monthDays.sublist(startIndex, endExclusive);
  }

  List<_ScheduledTodo> _sortTodos(List<_ScheduledTodo> todos) {
    return _ScheduleFragmentViewModel.sortTodosForCalendar(todos);
  }

  bool _isMultiDayTodo(ProjectTodo todo) {
    return _ScheduleFragmentViewModel.isMultiDayTodo(todo);
  }

  BoxDecoration _todoDecoration(
    ProjectTodo todo, {
    bool isSingleLine = false,
    bool hasPrev = false,
    bool hasNext = false,
    double radius = 3.0,
  }) {
    final isConnected = isSingleLine && (hasPrev || hasNext);
    final background = isConnected
        ? _todoConnectedBackground(todo)
        : _todoBaseBackground(todo);
    final borderColor = isConnected
        ? Colors.white
        : todo.isCompleted
        ? AppTokens.todoCompleted
        : todo.isRecurring
        ? AppTokens.todoRecurring
        : AppTokens.todoSingle;
    final borderRadius = isSingleLine
        ? BorderRadius.horizontal(
            left: hasPrev ? Radius.zero : Radius.circular(radius),
            right: hasNext ? Radius.zero : Radius.circular(radius),
          )
        : BorderRadius.circular(radius);
    final leftSide = hasPrev
        ? BorderSide.none
        : BorderSide(width: 0.5, color: borderColor);
    final rightSide = hasNext
        ? BorderSide.none
        : BorderSide(width: 0.5, color: borderColor);

    return BoxDecoration(
      color: background,
      border: isSingleLine
          ? Border(
              top: BorderSide(width: 0.5, color: borderColor),
              bottom: BorderSide(width: 0.5, color: borderColor),
              left: leftSide,
              right: rightSide,
            )
          : Border.all(width: 0.5, color: borderColor),
      borderRadius: borderRadius,
    );
  }

  Color _todoTextColor(ProjectTodo todo) {
    if (todo.isCompleted) {
      return AppTokens.todoCompleted;
    }
    if (todo.isRecurring) {
      return AppTokens.todoRecurring;
    }
    return AppTokens.todoSingle;
  }

  Color _todoBaseBackground(ProjectTodo todo) {
    if (todo.isCompleted) {
      return AppTokens.todoCompletedBackground;
    }
    if (todo.isRecurring) {
      return AppTokens.todoRecurringBackground;
    }
    return AppTokens.todoSingleBackground;
  }

  Color _todoConnectedBackground(ProjectTodo todo) {
    if (todo.isCompleted) {
      return AppTokens.todoCompletedConnected;
    }
    if (todo.isRecurring) {
      return AppTokens.todoRecurringConnected;
    }
    return AppTokens.todoSingleConnected;
  }

  bool _shouldShowSingleLineTitle({
    required String todoId,
    required DateTime day,
    required Map<DateTime, int> dayIndex,
    required List<DateTime> days,
    required String? Function(DateTime day) resolveSingleLineTodoId,
  }) {
    return _ScheduleFragmentViewModel.shouldShowSingleLineTitle(
      todoId: todoId,
      day: day,
      dayIndex: dayIndex,
      days: days,
      resolveSingleLineTodoId: resolveSingleLineTodoId,
    );
  }

  _RangeLayout _buildRangeLayout(
    Map<DateTime, int> dayIndex, {
    required int rowCount,
    required int maxLines,
  }) {
    return _ScheduleFragmentViewModel.buildRangeLayout(
      visibleDays: days,
      dayTodoMap: dayTodoMap,
      dayIndex: dayIndex,
      rowCount: rowCount,
      maxLines: maxLines,
    );
  }
}

class _RangeLayout {
  const _RangeLayout({
    required this.placements,
    required this.dayLineMasks,
    required this.dayBarTodoIds,
  });

  const _RangeLayout.empty()
    : placements = const [],
      dayLineMasks = const [],
      dayBarTodoIds = const <Set<String>>[];

  final List<_RangePlacement> placements;
  final List<int> dayLineMasks;
  final List<Set<String>> dayBarTodoIds;
}

class _RangeSpan {
  const _RangeSpan({
    required this.todo,
    required this.start,
    required this.end,
    required this.sortKey,
    required this.continuesBefore,
    required this.continuesAfter,
  });

  final ProjectTodo todo;
  final DateTime start;
  final DateTime end;
  final DateTime sortKey;
  final bool continuesBefore;
  final bool continuesAfter;
}

class _RecurringOccurrence {
  const _RecurringOccurrence({required this.todo, required this.dates});

  final ProjectTodo todo;
  final List<DateTime> dates;
}

class _RangePlacement {
  const _RangePlacement({
    required this.span,
    required this.startCol,
    required this.endCol,
    required this.line,
    required this.row,
    required this.hasPrev,
    required this.hasNext,
  });

  final _RangeSpan span;
  final int startCol;
  final int endCol;
  final int line;
  final int row;
  final bool hasPrev;
  final bool hasNext;
}

class _RangeOverlay extends StatelessWidget {
  const _RangeOverlay({
    required this.placements,
    required this.rowHeight,
    required this.rowSpacing,
    required this.unitWidth,
    required this.columnSpacing,
    required this.topOffset,
    required this.lineHeight,
  });

  final List<_RangePlacement> placements;
  final double rowHeight;
  final double rowSpacing;
  final double unitWidth;
  final double columnSpacing;
  final double topOffset;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    if (placements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        for (final placement in placements)
          Positioned(
            left: placement.startCol * (unitWidth + columnSpacing),
            top:
                placement.row * (rowHeight + rowSpacing) +
                topOffset +
                placement.line * lineHeight,
            child: _RangeBarBody(
              placement: placement,
              width:
                  (placement.endCol - placement.startCol + 1) * unitWidth +
                  (placement.endCol - placement.startCol) * columnSpacing,
              height: lineHeight,
            ),
          ),
      ],
    );
  }
}

class _RangeBarBody extends StatelessWidget {
  const _RangeBarBody({
    required this.placement,
    required this.width,
    required this.height,
  });

  final _RangePlacement placement;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final todo = placement.span.todo;
    final background = todo.isCompleted
        ? AppTokens.todoCompletedConnected
        : todo.isRecurring
        ? AppTokens.todoRecurringConnected
        : AppTokens.todoSingleConnected;
    final fadeStartColor = todo.isCompleted
        ? AppTokens.todoCompletedBackground
        : todo.isRecurring
        ? const Color(0xFFD3E2FF)
        : const Color(0xFFDDF6E3);
    final textColor = Colors.white;
    final radius = 3.0;
    const double barStepGranularity = 0.1;
    final double barFontSize = max(1.0, height);

    final hasPrev = placement.hasPrev;
    final hasNext = placement.hasNext;
    final LinearGradient? edgeGradient;
    if (hasPrev && hasNext) {
      edgeGradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [fadeStartColor, background, background, fadeStartColor],
        stops: const [0.0, 0.2, 0.8, 1.0],
      );
    } else if (hasPrev) {
      edgeGradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [fadeStartColor, background],
        stops: const [0.0, 0.2],
      );
    } else if (hasNext) {
      edgeGradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [background, fadeStartColor],
        stops: const [0.8, 1.0],
      );
    } else {
      edgeGradient = null;
    }

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: edgeGradient == null ? background : null,
          gradient: edgeGradient,
          // border: Border.all(width: 0.6, color: borderColor),
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(radius),
            right: Radius.circular(radius),
          ),
          border: Border.all(color: Colors.white, width: 0.5),
        ),
        child: Center(
          child: AutoSizeText(
            todo.title,
            maxLines: 1,
            maxFontSize: 10.0,
            minFontSize: 10.0,
            stepGranularity: barStepGranularity,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: barFontSize,
              height: 1.0,
              color: textColor,
              decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _TodoCountBadge extends StatelessWidget {
  const _TodoCountBadge({required this.count, required this.isHighlighted});

  final int count;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      // decoration: BoxDecoration(
      //   shape: BoxShape.circle,
      //   color: isHighlighted ? _SchedulePalette.primary : Colors.white,
      //   border: Border.all(
      //     color: isHighlighted ? Colors.transparent : _SchedulePalette.accent,
      //     width: 1.0,
      //   ),
      //   boxShadow: isHighlighted
      //       ? const [
      //           BoxShadow(
      //             color: Color(0x140F1F3D),
      //             blurRadius: 8,
      //           ),
      //         ]
      //       : null,
      // ),
      alignment: Alignment.center,
      child: Text(
        '+$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 10.0,
          color: isHighlighted
              ? _SchedulePalette.primary
              : _SchedulePalette.accent,
        ),
      ),
    );
  }
}

class _CalendarWeekdayHeader extends StatelessWidget {
  const _CalendarWeekdayHeader({this.textStyle});

  final TextStyle? textStyle;

  static const List<String> _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      child: Row(
        children: _weekdays.asMap().entries.map((e) {
          final i = e.key;
          final day = e.value;
          return Expanded(
            child: Center(
              child: Text(
                day.tr(),
                style: i == 0
                    ? textStyle?.copyWith(color: _SchedulePalette.holiday)
                    : textStyle?.copyWith(fontWeight: FontWeight.bold) ??
                          const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
