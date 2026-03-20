part of '../pages/schedule_fragment.dart';

class _ScheduleContentData {
  const _ScheduleContentData({
    required this.projectLookup,
    required this.favoriteProjects,
    required this.selectedDay,
    required this.selectedDayKey,
    required this.visibleTodos,
    required this.selectedTodos,
    required this.holidayMap,
  });

  final Map<String, ProjectSummary> projectLookup;
  final List<ProjectSummary> favoriteProjects;
  final DateTime selectedDay;
  final DateTime selectedDayKey;
  final List<ProjectTodo> visibleTodos;
  final List<_ScheduledTodo> selectedTodos;
  final Map<DateTime, Holiday> holidayMap;
}

class _ScheduleJumpResult {
  const _ScheduleJumpResult({required this.targetPage});

  final int targetPage;
}

class _ScheduleWidgetRouteAction {
  const _ScheduleWidgetRouteAction({
    required this.targetDate,
    required this.shouldOpenAddTodo,
  });

  final DateTime targetDate;
  final bool shouldOpenAddTodo;
}

class _ScheduleFragmentViewModel {
  _ScheduleFragmentViewModel({
    required this.initialPageIndex,
    required ScheduleUseCases useCases,
  }) : _useCases = useCases {
    final today = DateUtils.dateOnly(DateTime.now());
    focusedMonth = DateTime(today.year, today.month, 1);
    selectedDay = today;
    initialMonth = focusedMonth;
    currentPageIndex = initialPageIndex;
    showFavoritesOnly = UiPreferences.scheduleFavoritesOnly();
  }

  final int initialPageIndex;
  final ScheduleUseCases _useCases;
  late DateTime focusedMonth;
  DateTime? selectedDay;
  late final DateTime initialMonth;
  late int currentPageIndex;
  bool showFavoritesOnly = false;
  String? _lastWidgetActionKey;

  bool get shouldLoadHolidayApi {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final countryCode = locale.countryCode?.toUpperCase();
    if (countryCode != null) {
      return countryCode == 'KR';
    }
    return locale.languageCode.toLowerCase() == 'ko';
  }

  bool toggleFavoriteFilter() {
    showFavoritesOnly = !showFavoritesOnly;
    unawaited(UiPreferences.setScheduleFavoritesOnly(showFavoritesOnly));
    return true;
  }

  _ScheduleWidgetRouteAction? resolveWidgetRouteAction({
    required String? action,
    required String? dateParam,
    String? tsParam,
  }) {
    if (action == null && dateParam == null) {
      return null;
    }

    final key = '${action ?? ''}|${dateParam ?? ''}|${tsParam ?? ''}';
    if (_lastWidgetActionKey == key) {
      return null;
    }
    _lastWidgetActionKey = key;

    final parsed = dateParam == null ? null : DateTime.tryParse(dateParam);
    final targetDate = DateUtils.dateOnly(parsed ?? DateTime.now());
    return _ScheduleWidgetRouteAction(
      targetDate: targetDate,
      shouldOpenAddTodo: action == 'add',
    );
  }

  _ScheduleContentData buildContentData({
    required List<ProjectSummary> projects,
    required List<ProjectTodo> todos,
    required List<Holiday> holidays,
    required Set<String> favoriteProjectIds,
  }) {
    final projectLookup = {for (final project in projects) project.id: project};
    final favoriteProjects = projects
        .where((project) => favoriteProjectIds.contains(project.id))
        .toList();
    final resolvedSelectedDay =
        selectedDay ?? DateUtils.dateOnly(DateTime.now());
    final selectedKey = DateUtils.dateOnly(resolvedSelectedDay);
    final visibleTodos = todos
        .where((todo) => !todo.isHidden)
        .where(
          (todo) =>
              !showFavoritesOnly || favoriteProjectIds.contains(todo.projectId),
        )
        .toList();
    final selectedTodos = buildSelectedDayTodos(visibleTodos, selectedKey);
    final holidayMap = <DateTime, Holiday>{
      for (final holiday in holidays) DateUtils.dateOnly(holiday.date): holiday,
    };

    return _ScheduleContentData(
      projectLookup: projectLookup,
      favoriteProjects: favoriteProjects,
      selectedDay: resolvedSelectedDay,
      selectedDayKey: selectedKey,
      visibleTodos: visibleTodos,
      selectedTodos: selectedTodos,
      holidayMap: holidayMap,
    );
  }

  bool updateSelectedDay(DateTime day) {
    final normalized = DateUtils.dateOnly(day);
    final current = selectedDay;
    if (current != null && DateUtils.isSameDay(current, normalized)) {
      return false;
    }
    selectedDay = normalized;
    return true;
  }

  _ScheduleJumpResult jumpToDate(DateTime date) {
    final nextSelectedDay = DateUtils.dateOnly(date);
    final month = DateTime(nextSelectedDay.year, nextSelectedDay.month, 1);
    final monthDelta =
        (month.year - initialMonth.year) * 12 +
        (month.month - initialMonth.month);
    final targetPage = initialPageIndex + monthDelta;

    selectedDay = nextSelectedDay;
    focusedMonth = month;
    currentPageIndex = targetPage;
    return _ScheduleJumpResult(targetPage: targetPage);
  }

  int? resolveTargetPageForMonthOffset(int offset) {
    if (offset == 0) {
      return null;
    }
    return currentPageIndex + offset;
  }

  bool updatePageIndex(int pageIndex) {
    if (pageIndex == currentPageIndex) {
      return false;
    }
    final delta = pageIndex - currentPageIndex;
    focusedMonth = DateTime(focusedMonth.year, focusedMonth.month + delta, 1);
    currentPageIndex = pageIndex;
    return true;
  }

  List<DateTime> visibleDaysFor(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;

    final days = <DateTime>[];
    for (int i = 0; i < firstWeekday; i++) {
      days.add(firstDayOfMonth.subtract(Duration(days: firstWeekday - i)));
    }
    for (int day = 0; day < lastDayOfMonth.day; day++) {
      days.add(DateTime(month.year, month.month, day + 1));
    }
    while (days.length % 7 != 0) {
      final last = days.last;
      days.add(last.add(const Duration(days: 1)));
    }
    while (days.length < 42) {
      final last = days.last;
      days.add(last.add(const Duration(days: 1)));
    }
    return days;
  }

  Map<DateTime, List<_ScheduledTodo>> buildDayTodoMap(
    List<ProjectTodo> todos,
    List<DateTime> days,
  ) {
    final result = <DateTime, List<_ScheduledTodo>>{};
    for (final day in days) {
      final key = DateUtils.dateOnly(day);
      final matches = <_ScheduledTodo>[];
      for (final todo in todos) {
        if (_occursOnDay(todo, key)) {
          matches.add(_ScheduledTodo(todo: todo, date: key));
        }
      }
      if (matches.isNotEmpty) {
        result[key] = matches;
      }
    }
    return result;
  }

  List<_ScheduledTodo> buildSelectedDayTodos(
    List<ProjectTodo> todos,
    DateTime day,
  ) {
    final key = DateUtils.dateOnly(day);
    final matches = <_ScheduledTodo>[];
    for (final todo in todos) {
      if (_occursOnDay(todo, key)) {
        matches.add(_ScheduledTodo(todo: todo, date: key));
      }
    }
    return _sortScheduledTodosForDetail(matches, DateTime.now());
  }

  List<_ScheduledTodo> _sortScheduledTodosForDetail(
    List<_ScheduledTodo> todos,
    DateTime now,
  ) {
    if (todos.length <= 1) {
      return todos;
    }

    final overdue = <_ScheduledTodo>[];
    final incomplete = <_ScheduledTodo>[];
    final completed = <_ScheduledTodo>[];

    for (final entry in todos) {
      final todo = entry.todo;
      if (todo.isCompleted) {
        completed.add(entry);
        continue;
      }

      if (isTodoOverdue(todo, now)) {
        overdue.add(entry);
      } else {
        incomplete.add(entry);
      }
    }

    overdue.sort((a, b) {
      final aTodo = a.todo;
      final bTodo = b.todo;
      final aDate = aTodo.isRecurring ? aTodo.endDate : aTodo.startDate;
      final bDate = bTodo.isRecurring ? bTodo.endDate : bTodo.startDate;
      final aKey = aDate == null ? DateTime(9999) : DateUtils.dateOnly(aDate);
      final bKey = bDate == null ? DateTime(9999) : DateUtils.dateOnly(bDate);
      final compare = aKey.compareTo(bKey);
      if (compare != 0) {
        return compare;
      }
      return aTodo.id.compareTo(bTodo.id);
    });

    incomplete.sort((a, b) {
      final aTodo = a.todo;
      final bTodo = b.todo;
      final aTime = resolveOccurrenceTime(aTodo, a.date);
      final bTime = resolveOccurrenceTime(bTodo, b.date);

      if (aTime == null && bTime == null) {
        final compare = aTodo.createdAt.compareTo(bTodo.createdAt);
        if (compare != 0) {
          return compare;
        }
        return aTodo.id.compareTo(bTodo.id);
      }
      if (aTime == null) {
        return 1;
      }
      if (bTime == null) {
        return -1;
      }

      final compare = aTime.compareTo(bTime);
      if (compare != 0) {
        return compare;
      }
      return aTodo.id.compareTo(bTodo.id);
    });

    completed.sort((a, b) {
      final aTodo = a.todo;
      final bTodo = b.todo;
      final aKey = aTodo.completedAt;
      final bKey = bTodo.completedAt;

      if (aKey == null && bKey == null) {
        final compare = aTodo.updatedAt.compareTo(bTodo.updatedAt);
        if (compare != 0) {
          return compare;
        }
        return aTodo.id.compareTo(bTodo.id);
      }
      if (aKey == null) {
        return 1;
      }
      if (bKey == null) {
        return -1;
      }

      final compare = aKey.compareTo(bKey);
      if (compare != 0) {
        return compare;
      }
      return aTodo.id.compareTo(bTodo.id);
    });

    return [...overdue, ...incomplete, ...completed];
  }

  bool _occursOnDay(ProjectTodo todo, DateTime day) {
    if (todo.isRecurring) {
      final mask = todo.weekdayMask ?? 0;
      if (mask == 0) {
        return false;
      }

      final normalizedDay = DateUtils.dateOnly(day);
      final completedAt = todo.completedAt == null
          ? null
          : DateUtils.dateOnly(todo.completedAt!);
      final startDate = todo.startDate == null
          ? null
          : DateUtils.dateOnly(todo.startDate!);
      final endDate = todo.endDate == null
          ? null
          : DateUtils.dateOnly(todo.endDate!);

      if (startDate != null && normalizedDay.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && normalizedDay.isAfter(endDate)) {
        return false;
      }
      if (completedAt != null && normalizedDay.isAfter(completedAt)) {
        return false;
      }

      final weekdayIndex = _weekdayIndex(normalizedDay);
      return (mask & (1 << weekdayIndex)) != 0;
    }

    final dueDate = todo.startDate;
    if (dueDate == null) {
      return false;
    }
    final normalizedDay = DateUtils.dateOnly(day);
    final normalizedStart = DateUtils.dateOnly(dueDate);
    final endDate = todo.endDate;
    if (endDate == null) {
      return DateUtils.isSameDay(normalizedStart, normalizedDay);
    }
    final normalizedEnd = DateUtils.dateOnly(endDate);
    if (DateUtils.isSameDay(normalizedStart, normalizedEnd)) {
      return DateUtils.isSameDay(normalizedStart, normalizedDay);
    }
    if (normalizedDay.isBefore(normalizedStart) ||
        normalizedDay.isAfter(normalizedEnd)) {
      return false;
    }
    return true;
  }

  int _weekdayIndex(DateTime day) {
    return (day.weekday + 6) % 7;
  }

  static List<_ScheduledTodo> sortTodosForCalendar(List<_ScheduledTodo> todos) {
    if (todos.length <= 1) {
      return todos;
    }

    final pending = todos.where((entry) => !entry.todo.isCompleted).toList();
    pending.sort((a, b) {
      final aMinutes = sortMinutesForTodo(a);
      final bMinutes = sortMinutesForTodo(b);
      if (aMinutes == null && bMinutes == null) {
        return 0;
      }
      if (aMinutes == null) {
        return 1;
      }
      if (bMinutes == null) {
        return -1;
      }
      return aMinutes.compareTo(bMinutes);
    });

    final completed = todos.where((entry) => entry.todo.isCompleted).toList();
    return [...pending, ...completed];
  }

  static List<_ScheduledTodo> sortTodosForDayPanel(List<_ScheduledTodo> todos) {
    return sortTodosForCalendar(todos);
  }

  static int? sortMinutesForTodo(_ScheduledTodo entry) {
    final todo = entry.todo;
    if (!todo.isRecurring && todo.startDate != null) {
      final startDate = DateUtils.dateOnly(todo.startDate!);
      final occurrenceDate = DateUtils.dateOnly(entry.date);
      if (startDate.isBefore(occurrenceDate)) {
        return 0;
      }
    }
    return parseTimeToMinutes(todo.startTime);
  }

  static int? parseTimeToMinutes(String? rawTime) {
    if (rawTime == null || rawTime.trim().isEmpty) {
      return null;
    }
    final parts = rawTime.split(':');
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
    return hour * 60 + minute;
  }

  static DateTime? resolveOccurrenceTime(
    ProjectTodo todo,
    DateTime occurrenceDate,
  ) {
    final parsed = tryParseTime(todo.startTime);
    if (parsed == null) {
      return null;
    }
    return DateTime(
      occurrenceDate.year,
      occurrenceDate.month,
      occurrenceDate.day,
      parsed.$1,
      parsed.$2,
    );
  }

  static bool isTodoOverdue(ProjectTodo todo, DateTime now) {
    if (todo.isCompleted) {
      return false;
    }

    final dueDateTime = resolveTodoOverdueDateTime(todo);
    if (dueDateTime == null) {
      return false;
    }
    return now.isAfter(dueDateTime);
  }

  static DateTime? resolveTodoOverdueDateTime(ProjectTodo todo) {
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
      final endParts = tryParseTime(endTime);
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

    final endParts = tryParseTime(endTime);
    if (endParts != null) {
      return DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        endParts.$1,
        endParts.$2,
      );
    }

    final startParts = tryParseTime(startTime);
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

  static (int, int)? tryParseTime(String? raw) {
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

  static bool isMultiDayTodo(ProjectTodo todo) {
    if (todo.isRecurring) {
      return false;
    }
    final startDate = todo.startDate;
    final endDate = todo.endDate;
    if (startDate == null || endDate == null) {
      return false;
    }
    return !DateUtils.isSameDay(startDate, endDate);
  }

  static bool recurringOccursOnDate(ProjectTodo todo, DateTime day) {
    final mask = todo.weekdayMask ?? 0;
    if (mask == 0) {
      return false;
    }
    final normalizedDay = DateUtils.dateOnly(day);
    final completedAt = todo.completedAt == null
        ? null
        : DateUtils.dateOnly(todo.completedAt!);
    final startDate = todo.startDate == null
        ? null
        : DateUtils.dateOnly(todo.startDate!);
    final endDate = todo.endDate == null
        ? null
        : DateUtils.dateOnly(todo.endDate!);

    if (startDate != null && normalizedDay.isBefore(startDate)) {
      return false;
    }
    if (endDate != null && normalizedDay.isAfter(endDate)) {
      return false;
    }
    if (completedAt != null && normalizedDay.isAfter(completedAt)) {
      return false;
    }

    final weekdayIndex = (normalizedDay.weekday + 6) % 7;
    return (mask & (1 << weekdayIndex)) != 0;
  }

  static bool shouldShowSingleLineTitle({
    required String todoId,
    required DateTime day,
    required Map<DateTime, int> dayIndex,
    required List<DateTime> days,
    required String? Function(DateTime day) resolveSingleLineTodoId,
  }) {
    final index = dayIndex[DateUtils.dateOnly(day)];
    if (index == null) {
      return true;
    }
    var start = index;
    while (start > 0) {
      final prevDay = DateUtils.dateOnly(days[start - 1]);
      if (resolveSingleLineTodoId(prevDay) != todoId) {
        break;
      }
      start--;
    }
    var end = index;
    while (end < days.length - 1) {
      final nextDay = DateUtils.dateOnly(days[end + 1]);
      if (resolveSingleLineTodoId(nextDay) != todoId) {
        break;
      }
      end++;
    }
    final mid = (start + end) ~/ 2;
    return index == mid;
  }

  static _RangeLayout buildRangeLayout({
    required List<DateTime> visibleDays,
    required Map<DateTime, List<_ScheduledTodo>> dayTodoMap,
    required Map<DateTime, int> dayIndex,
    required int rowCount,
    required int maxLines,
  }) {
    if (dayIndex.isEmpty || maxLines <= 0) {
      return const _RangeLayout.empty();
    }
    final spans = _buildRangeSpans(
      visibleDays: visibleDays,
      dayTodoMap: dayTodoMap,
      dayIndex: dayIndex,
    );
    if (spans.isEmpty) {
      return const _RangeLayout.empty();
    }

    final days = dayIndex.keys.toList()..sort();
    final placements = <_RangePlacement>[];
    final dayLineMasks = List<int>.filled(days.length, 0);
    final dayBarTodoIds = List<Set<String>>.generate(
      days.length,
      (_) => <String>{},
    );
    final dayLineIndex = <DateTime, Map<String, int>>{};
    for (final day in days) {
      final dayKey = DateUtils.dateOnly(day);
      final todos = sortTodosForCalendar(
        List<_ScheduledTodo>.from(
          dayTodoMap[dayKey] ?? const <_ScheduledTodo>[],
        ),
      );
      if (todos.isEmpty) {
        continue;
      }
      final map = <String, int>{};
      for (var i = 0; i < todos.length; i++) {
        map[todos[i].todo.id] = i;
      }
      dayLineIndex[dayKey] = map;
    }

    for (var row = 0; row < rowCount; row++) {
      final weekStartIndex = row * 7;
      if (weekStartIndex >= days.length) {
        break;
      }
      final weekEndIndex = min(weekStartIndex + 6, days.length - 1);
      final weekStart = DateUtils.dateOnly(days[weekStartIndex]);
      final weekEnd = DateUtils.dateOnly(days[weekEndIndex]);
      final rowSpans = spans.where((span) {
        return !span.end.isBefore(weekStart) && !span.start.isAfter(weekEnd);
      }).toList();

      if (rowSpans.isEmpty) {
        continue;
      }

      int resolveDesiredLine(_RangeSpan span, DateTime day) {
        final dayKey = DateUtils.dateOnly(day);
        final lineMap = dayLineIndex[dayKey];
        return lineMap?[span.todo.id] ?? 0;
      }

      rowSpans.sort((a, b) {
        final lineCompare = resolveDesiredLine(
          a,
          a.start,
        ).compareTo(resolveDesiredLine(b, b.start));
        if (lineCompare != 0) {
          return lineCompare;
        }
        final compare = a.sortKey.compareTo(b.sortKey);
        if (compare != 0) {
          return compare;
        }
        return a.todo.id.compareTo(b.todo.id);
      });

      if (maxLines == 1) {
        final lane = <_RangePlacement>[];
        bool placeSegment(
          _RangeSpan span,
          int segmentStartIndex,
          int segmentEndIndex,
          int spanStartIndex,
          int spanEndIndex,
        ) {
          if (segmentStartIndex > segmentEndIndex) {
            return false;
          }
          final startCol = segmentStartIndex % 7;
          final endCol = segmentEndIndex % 7;
          final overlap = lane.any((existing) {
            return startCol <= existing.endCol && endCol >= existing.startCol;
          });
          if (overlap) {
            return false;
          }
          final hasPrev =
              span.continuesBefore || segmentStartIndex > spanStartIndex;
          final hasNext = span.continuesAfter || segmentEndIndex < spanEndIndex;
          final placement = _RangePlacement(
            span: span,
            startCol: startCol,
            endCol: endCol,
            line: 0,
            row: row,
            hasPrev: hasPrev,
            hasNext: hasNext,
          );
          lane.add(placement);
          placements.add(placement);
          _applyDayLineMask(
            dayLineMasks: dayLineMasks,
            row: row,
            startCol: startCol,
            endCol: endCol,
            line: 0,
          );
          _applyDayBarTodoIds(
            dayBarTodoIds: dayBarTodoIds,
            row: row,
            startCol: startCol,
            endCol: endCol,
            todoId: span.todo.id,
          );
          return true;
        }

        final rowStartIndex = row * 7;
        final rowEndIndex = min(rowStartIndex + 6, days.length - 1);
        for (final span in rowSpans) {
          final startIndex = dayIndex[span.start];
          final endIndex = dayIndex[span.end];
          if (startIndex == null || endIndex == null) {
            continue;
          }
          final segmentStartIndex = max(startIndex, rowStartIndex);
          final segmentEndIndex = min(endIndex, rowEndIndex);
          if (segmentStartIndex > segmentEndIndex) {
            continue;
          }

          int? currentStart;
          for (var i = segmentStartIndex; i <= segmentEndIndex; i++) {
            final desiredLine = resolveDesiredLine(span, days[i]);
            if (desiredLine != 0) {
              if (currentStart != null) {
                placeSegment(span, currentStart, i - 1, startIndex, endIndex);
                currentStart = null;
              }
              continue;
            }
            currentStart ??= i;
          }
          if (currentStart != null) {
            placeSegment(
              span,
              currentStart,
              segmentEndIndex,
              startIndex,
              endIndex,
            );
          }
        }
        continue;
      }

      final lanes = List<List<_RangePlacement>>.generate(
        maxLines,
        (_) => <_RangePlacement>[],
      );
      for (final span in rowSpans) {
        final segmentStart = span.start.isBefore(weekStart)
            ? weekStart
            : span.start;
        final segmentEnd = span.end.isAfter(weekEnd) ? weekEnd : span.end;
        final hasPrev =
            span.continuesBefore ||
            !DateUtils.isSameDay(segmentStart, span.start);
        final hasNext =
            span.continuesAfter || !DateUtils.isSameDay(segmentEnd, span.end);
        final startIndex = dayIndex[segmentStart];
        final endIndex = dayIndex[segmentEnd];
        if (startIndex == null || endIndex == null) {
          continue;
        }
        final startCol = startIndex % 7;
        final endCol = endIndex % 7;
        final desiredLine = resolveDesiredLine(span, segmentStart);
        if (desiredLine >= maxLines) {
          continue;
        }

        for (var line = desiredLine; line < maxLines; line++) {
          final overlap = lanes[line].any((existing) {
            return startCol <= existing.endCol && endCol >= existing.startCol;
          });
          if (overlap) {
            continue;
          }
          final placement = _RangePlacement(
            span: span,
            startCol: startCol,
            endCol: endCol,
            line: line,
            row: row,
            hasPrev: hasPrev,
            hasNext: hasNext,
          );
          lanes[line].add(placement);
          placements.add(placement);
          _applyDayLineMask(
            dayLineMasks: dayLineMasks,
            row: row,
            startCol: startCol,
            endCol: endCol,
            line: line,
          );
          _applyDayBarTodoIds(
            dayBarTodoIds: dayBarTodoIds,
            row: row,
            startCol: startCol,
            endCol: endCol,
            todoId: span.todo.id,
          );
          break;
        }
      }
    }

    return _RangeLayout(
      placements: placements,
      dayLineMasks: dayLineMasks,
      dayBarTodoIds: dayBarTodoIds,
    );
  }

  static List<_RangeSpan> _buildRangeSpans({
    required List<DateTime> visibleDays,
    required Map<DateTime, List<_ScheduledTodo>> dayTodoMap,
    required Map<DateTime, int> dayIndex,
  }) {
    if (dayIndex.isEmpty) {
      return const <_RangeSpan>[];
    }
    final visibleStart = DateUtils.dateOnly(visibleDays.first);
    final visibleEnd = DateUtils.dateOnly(visibleDays.last);
    final spans = <_RangeSpan>[];
    final seen = <String>{};

    for (final entries in dayTodoMap.values) {
      for (final entry in entries) {
        final todo = entry.todo;
        if (!isMultiDayTodo(todo)) {
          continue;
        }
        if (seen.contains(todo.id)) {
          continue;
        }
        seen.add(todo.id);

        final startDate = DateUtils.dateOnly(todo.startDate!);
        final endDate = DateUtils.dateOnly(todo.endDate!);
        final originalStart = startDate.isBefore(endDate) ? startDate : endDate;
        final originalEnd = startDate.isBefore(endDate) ? endDate : startDate;
        final clampedStart = originalStart.isBefore(visibleStart)
            ? visibleStart
            : originalStart;
        final clampedEnd = originalEnd.isAfter(visibleEnd)
            ? visibleEnd
            : originalEnd;
        if (clampedStart.isAfter(clampedEnd)) {
          continue;
        }
        spans.add(
          _RangeSpan(
            todo: todo,
            start: clampedStart,
            end: clampedEnd,
            sortKey: originalStart,
            continuesBefore: originalStart.isBefore(visibleStart),
            continuesAfter: originalEnd.isAfter(visibleEnd),
          ),
        );
      }
    }

    final recurringGroups = _collectRecurringOccurrences(dayTodoMap);
    for (final group in recurringGroups.values) {
      final todo = group.todo;
      final occurrences = group.dates..sort();
      if (occurrences.length < 2) {
        continue;
      }
      DateTime? runStart;
      DateTime? previous;
      for (final date in occurrences) {
        if (runStart == null) {
          runStart = date;
          previous = date;
          continue;
        }
        final expectedNext = previous!.add(const Duration(days: 1));
        if (DateUtils.isSameDay(date, expectedNext)) {
          previous = date;
          continue;
        }
        _addRecurringSpan(
          spans: spans,
          todo: todo,
          runStart: runStart,
          runEnd: previous,
        );
        runStart = date;
        previous = date;
      }
      if (runStart != null && previous != null) {
        _addRecurringSpan(
          spans: spans,
          todo: todo,
          runStart: runStart,
          runEnd: previous,
        );
      }
    }

    spans.sort((a, b) {
      final compare = a.sortKey.compareTo(b.sortKey);
      if (compare != 0) {
        return compare;
      }
      return a.todo.id.compareTo(b.todo.id);
    });

    return spans;
  }

  static Map<String, _RecurringOccurrence> _collectRecurringOccurrences(
    Map<DateTime, List<_ScheduledTodo>> dayTodoMap,
  ) {
    final result = <String, _RecurringOccurrence>{};
    for (final entry in dayTodoMap.entries) {
      final date = entry.key;
      for (final scheduled in entry.value) {
        final todo = scheduled.todo;
        if (!todo.isRecurring) {
          continue;
        }
        result
            .putIfAbsent(
              todo.id,
              () => _RecurringOccurrence(todo: todo, dates: <DateTime>[]),
            )
            .dates
            .add(date);
      }
    }
    return result;
  }

  static void _addRecurringSpan({
    required List<_RangeSpan> spans,
    required ProjectTodo todo,
    required DateTime runStart,
    required DateTime runEnd,
  }) {
    if (runStart.isAtSameMomentAs(runEnd)) {
      return;
    }
    final before = runStart.subtract(const Duration(days: 1));
    final after = runEnd.add(const Duration(days: 1));
    final continuesBefore = recurringOccursOnDate(todo, before);
    final continuesAfter = recurringOccursOnDate(todo, after);
    spans.add(
      _RangeSpan(
        todo: todo,
        start: runStart,
        end: runEnd,
        sortKey: runStart,
        continuesBefore: continuesBefore,
        continuesAfter: continuesAfter,
      ),
    );
  }

  static void _applyDayLineMask({
    required List<int> dayLineMasks,
    required int row,
    required int startCol,
    required int endCol,
    required int line,
  }) {
    final mask = 1 << line;
    final rowStart = row * 7;
    for (var col = startCol; col <= endCol; col++) {
      final index = rowStart + col;
      if (index >= 0 && index < dayLineMasks.length) {
        dayLineMasks[index] |= mask;
      }
    }
  }

  static void _applyDayBarTodoIds({
    required List<Set<String>> dayBarTodoIds,
    required int row,
    required int startCol,
    required int endCol,
    required String todoId,
  }) {
    final rowStart = row * 7;
    for (var col = startCol; col <= endCol; col++) {
      final index = rowStart + col;
      if (index >= 0 && index < dayBarTodoIds.length) {
        dayBarTodoIds[index].add(todoId);
      }
    }
  }

  static bool canManageTodo({
    required int? userId,
    required ProjectSummary? project,
    required ProjectTodo todo,
  }) {
    if (userId == null) {
      return false;
    }
    final isManager =
        project != null &&
        project.members.any(
          (member) =>
              member.id == userId &&
              member.role.trim().toLowerCase() == 'manager',
        );
    return userId == todo.createdBy.id ||
        (project != null && (userId == project.owner.id || isManager));
  }

  String resolveErrorMessage(Object error) {
    if (error is ApiError) {
      return error.message;
    }
    return 'Failed to load schedule.';
  }

  Future<SimpleResult<ProjectTodo, ApiError>> toggleCompletion({
    required ProjectTodo todo,
  }) async {
    final result = await _useCases.toggleCompletion(todo: todo);
    return result;
  }

  Future<SimpleResult<bool, ApiError>> toggleVisibility({
    required ProjectTodo todo,
  }) async {
    final result = await _useCases.toggleVisibility(todo: todo);
    return result;
  }
}
