import 'dart:async';

import 'package:flutter/material.dart';
import 'package:todotogether/core/network/result/api_error.dart';
import 'package:todotogether/core/network/simple_result.dart';
import 'package:todotogether/core/preferences/ui_preferences.dart';
import 'package:todotogether/features/project/domain/entities/project_summary.dart';
import 'package:todotogether/features/project/domain/entities/project_todo.dart';
import 'package:todotogether/features/project/domain/usecases/project_use_cases.dart';

typedef AddTodoAuthorizedExecutor =
    Future<SimpleResult<T, ApiError>> Function<T>(
      Future<SimpleResult<T, ApiError>> Function(String accessToken) action,
    );

class AddProjectTodoSheetViewModel {
  AddProjectTodoSheetViewModel({
    required ProjectUseCases projectUseCases,
    required AddTodoAuthorizedExecutor executeAuthorized,
  }) : _projectUseCases = projectUseCases,
       _executeAuthorized = executeAuthorized;

  static const TimeOfDay defaultStartTime = TimeOfDay(hour: 0, minute: 0);
  static const TimeOfDay defaultEndTime = TimeOfDay(hour: 23, minute: 59);

  final ProjectUseCases _projectUseCases;
  final AddTodoAuthorizedExecutor _executeAuthorized;

  ProjectSummary? resolveAutoSelectProject(
    List<ProjectSummary> projects,
    Set<String> favoriteProjectIds,
  ) {
    if (projects.isEmpty) {
      return null;
    }

    final favoritesOnly = UiPreferences.projectPickerFavoritesOnly();
    if (favoritesOnly) {
      final favorites = projects
          .where((project) => favoriteProjectIds.contains(project.id))
          .toList();
      if (favorites.length == 1) {
        return favorites.first;
      }
      return null;
    }

    if (projects.length == 1) {
      return projects.first;
    }
    return null;
  }

  bool canSubmit({
    required bool isSubmitting,
    required bool hasTitle,
    required bool canSelectProject,
    required ProjectSummary? selectedProject,
  }) {
    return !isSubmitting &&
        hasTitle &&
        (!canSelectProject || selectedProject != null);
  }

  int weekdayIndex(DateTime day) {
    final normalized = DateUtils.dateOnly(day);
    return normalized.weekday % 7;
  }

  TimeOfDay? parseTimeOfDay(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final parts = raw.split(':');
    if (parts.isEmpty) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : 0;
    if (hour == null || minute == null) {
      return null;
    }
    final normalizedHour = hour.clamp(0, 23);
    final normalizedMinute = minute.clamp(0, 59);
    return TimeOfDay(hour: normalizedHour, minute: normalizedMinute);
  }

  TimeOfDay resolveStartTime(
    TimeOfDay? time, {
    TimeOfDay defaultValue = defaultStartTime,
  }) {
    return time ?? defaultValue;
  }

  TimeOfDay resolveEndTime(
    TimeOfDay? time, {
    TimeOfDay defaultValue = defaultEndTime,
  }) {
    return time ?? defaultValue;
  }

  String formatEndTimeValue(TimeOfDay? rawEndTime, TimeOfDay resolvedEndTime) {
    if (rawEndTime == null) {
      return '23:59:59';
    }
    return formatTimeOfDay(resolvedEndTime);
  }

  String formatAlarmSummary(int hours, int minutes) {
    if (hours == 0 && minutes == 0) {
      return '시작 시간에 알림';
    }
    if (hours == 0) {
      return '시작 $minutes분 전에 알림';
    }
    if (minutes == 0) {
      return '시작 $hours시간 전에 알림';
    }
    return '시작 $hours시간 $minutes분 전에 알림';
  }

  int encodeWeekdays(List<bool> weekdaySelections) {
    var mask = 0;
    for (var i = 0; i < weekdaySelections.length; i++) {
      if (weekdaySelections[i]) {
        final bitIndex = (i + 6) % 7;
        mask |= (1 << bitIndex);
      }
    }
    return mask;
  }

  bool shouldLockTimeRange({
    required bool isRecurring,
    required DateTime activeStartDate,
    required DateTime? activeEndDate,
  }) {
    if (isRecurring) {
      return true;
    }
    return activeEndDate == null ||
        DateUtils.isSameDay(activeStartDate, activeEndDate);
  }

  bool isValidTimeRange({
    required TimeOfDay? activeStartTime,
    required TimeOfDay? activeEndTime,
  }) {
    final startTime = activeStartTime;
    final endTime = activeEndTime;
    if (startTime == null || endTime == null) {
      return true;
    }
    return compareTimeOfDay(startTime, endTime) <= 0;
  }

  int compareTimeOfDay(TimeOfDay a, TimeOfDay b) {
    final aMinutes = a.hour * 60 + a.minute;
    final bMinutes = b.hour * 60 + b.minute;
    return aMinutes.compareTo(bMinutes);
  }

  int timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  String formatApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Map<String, dynamic> buildRequestBody({
    required ProjectSummary project,
    required ProjectTodo? initialTodo,
    required bool isEditing,
    required String title,
    required bool isRecurring,
    required DateTime singleStartDate,
    required DateTime? singleEndDate,
    required TimeOfDay? singleStartTime,
    required TimeOfDay? singleEndTime,
    required DateTime recurringStartDate,
    required DateTime? recurringEndDate,
    required TimeOfDay? recurringStartTime,
    required TimeOfDay? recurringEndTime,
    required List<bool> weekdaySelections,
    required int? totalAlarmMinutes,
  }) {
    final body = <String, dynamic>{
      'project': project.id,
      'title': title,
      'status': initialTodo?.status ?? 'todo',
      'kind': isEditing ? (initialTodo?.kind ?? 'schedule') : 'schedule',
      'assignees':
          initialTodo?.assignees.map((assignee) => assignee.id).toList() ??
          <int>[],
      'is_recurring': isRecurring,
      'alarm_offset_minutes': totalAlarmMinutes,
    };

    if (isRecurring) {
      final startDate = recurringStartDate;
      final endDate = recurringEndDate;
      final startTime = resolveStartTime(recurringStartTime);
      final rawEndTime = recurringEndTime;
      final endTime = resolveEndTime(rawEndTime);
      body['weekday_mask'] = encodeWeekdays(weekdaySelections);
      body['start_date'] = formatApiDate(startDate);
      body['start_time'] = formatTimeOfDay(startTime);
      if (endDate != null) {
        body['end_date'] = formatApiDate(endDate);
      } else if (isEditing && initialTodo?.endDate != null) {
        body['end_date'] = null;
      }
      body['end_time'] = formatEndTimeValue(rawEndTime, endTime);
    } else {
      final startDate = singleStartDate;
      final endDate = singleEndDate ?? startDate;
      final startTime = resolveStartTime(singleStartTime);
      final rawEndTime = singleEndTime;
      final endTime = resolveEndTime(rawEndTime);
      body['start_date'] = formatApiDate(startDate);
      body['start_time'] = formatTimeOfDay(startTime);
      body['end_date'] = formatApiDate(endDate);
      body['end_time'] = formatEndTimeValue(rawEndTime, endTime);
      if (isEditing && (initialTodo?.isRecurring ?? false)) {
        body['weekday_mask'] = 0;
      }
    }

    return body;
  }

  Map<String, dynamic> buildUpdateBody({
    required ProjectSummary project,
    required ProjectTodo? initialTodo,
    required String title,
    required bool isRecurring,
    required DateTime singleStartDate,
    required DateTime? singleEndDate,
    required TimeOfDay? singleStartTime,
    required TimeOfDay? singleEndTime,
    required DateTime recurringStartDate,
    required DateTime? recurringEndDate,
    required TimeOfDay? recurringStartTime,
    required TimeOfDay? recurringEndTime,
    required List<bool> weekdaySelections,
    required int? totalAlarmMinutes,
  }) {
    final initial = initialTodo;
    if (initial == null) {
      return buildRequestBody(
        project: project,
        initialTodo: initialTodo,
        isEditing: false,
        title: title,
        isRecurring: isRecurring,
        singleStartDate: singleStartDate,
        singleEndDate: singleEndDate,
        singleStartTime: singleStartTime,
        singleEndTime: singleEndTime,
        recurringStartDate: recurringStartDate,
        recurringEndDate: recurringEndDate,
        recurringStartTime: recurringStartTime,
        recurringEndTime: recurringEndTime,
        weekdaySelections: weekdaySelections,
        totalAlarmMinutes: totalAlarmMinutes,
      );
    }
    final body = <String, dynamic>{};
    if (title != initial.title) {
      body['title'] = title;
    }
    if (totalAlarmMinutes != initial.alarmOffsetMinutes) {
      body['alarm_offset_minutes'] = totalAlarmMinutes;
    }
    if (isRecurring != initial.isRecurring) {
      body['is_recurring'] = isRecurring;
    }

    if (isRecurring) {
      final startDate = recurringStartDate;
      final endDate = recurringEndDate;
      final startTime = resolveStartTime(recurringStartTime);
      final rawEndTime = recurringEndTime;
      final endTime = resolveEndTime(rawEndTime);
      final currentWeekdayMask = encodeWeekdays(weekdaySelections);
      final currentStartDate = formatApiDate(startDate);
      final currentStartTime = formatTimeOfDay(startTime);
      final currentEndDate = endDate != null ? formatApiDate(endDate) : null;
      final currentEndTime = formatEndTimeValue(rawEndTime, endTime);
      final initialStartDate = initial.startDate == null
          ? null
          : formatApiDate(initial.startDate!);
      final initialStartTime = initial.startTime;
      final initialEndDate = initial.endDate == null
          ? null
          : formatApiDate(initial.endDate!);
      final initialEndTime = initial.endTime;
      final initialWeekdayMask = initial.weekdayMask ?? 0;

      if (currentWeekdayMask != initialWeekdayMask) {
        body['weekday_mask'] = currentWeekdayMask;
      }
      if (currentStartDate != initialStartDate) {
        body['start_date'] = currentStartDate;
      }
      if (currentStartTime != initialStartTime) {
        body['start_time'] = currentStartTime;
      }
      if (currentEndDate != initialEndDate) {
        body['end_date'] = currentEndDate;
      }
      if (currentEndTime != initialEndTime) {
        body['end_time'] = currentEndTime;
      }
    } else {
      final startDate = singleStartDate;
      final endDate = singleEndDate ?? startDate;
      final startTime = resolveStartTime(singleStartTime);
      final rawEndTime = singleEndTime;
      final endTime = resolveEndTime(rawEndTime);
      final currentStartDate = formatApiDate(startDate);
      final currentStartTime = formatTimeOfDay(startTime);
      final currentEndDate = formatApiDate(endDate);
      final currentEndTime = formatEndTimeValue(rawEndTime, endTime);
      final initialStartDate = initial.startDate == null
          ? null
          : formatApiDate(initial.startDate!);
      final initialStartTime = initial.startTime;
      final initialEndDate = initial.endDate == null
          ? null
          : formatApiDate(initial.endDate!);
      final initialEndTime = initial.endTime;

      if (currentStartDate != initialStartDate) {
        body['start_date'] = currentStartDate;
      }
      if (currentStartTime != initialStartTime) {
        body['start_time'] = currentStartTime;
      }
      if (currentEndDate != initialEndDate) {
        body['end_date'] = currentEndDate;
      }
      if (currentEndTime != initialEndTime) {
        body['end_time'] = currentEndTime;
      }
      if (initial.isRecurring) {
        final initialWeekdayMask = initial.weekdayMask ?? 0;
        if (initialWeekdayMask != 0) {
          body['weekday_mask'] = 0;
        }
      }
    }

    return body;
  }

  Future<SimpleResult<ProjectTodo, ApiError>> submitTodo({
    required bool isEditing,
    required String todoId,
    required Map<String, dynamic> createBody,
    required Map<String, dynamic> updateBody,
  }) {
    return _executeAuthorized(
      (accessToken) => isEditing
          ? _projectUseCases.updateTodo(
              accessToken: accessToken,
              todoId: todoId,
              body: updateBody,
            )
          : _projectUseCases.createTodo(
              accessToken: accessToken,
              body: createBody,
            ),
    );
  }

  Future<SimpleResult<void, ApiError>> deleteTodo({required String todoId}) {
    return _executeAuthorized(
      (accessToken) =>
          _projectUseCases.deleteTodo(accessToken: accessToken, todoId: todoId),
    );
  }
}

class ProjectPickerScreenViewModel {
  ProjectPickerScreenViewModel({required List<ProjectSummary> projects})
    : _showFavoritesOnly = UiPreferences.projectPickerFavoritesOnly() {
    _sortedProjects = _sortProjects(projects);
  }

  String _query = '';
  bool _showFavoritesOnly = false;
  List<ProjectSummary> _sortedProjects = const [];

  String get query => _query;
  bool get showFavoritesOnly => _showFavoritesOnly;

  bool updateQuery(String rawQuery) {
    final nextQuery = rawQuery.trim();
    if (_query == nextQuery) {
      return false;
    }
    _query = nextQuery;
    return true;
  }

  void toggleFavoriteFilter() {
    _showFavoritesOnly = !_showFavoritesOnly;
    unawaited(UiPreferences.setProjectPickerFavoritesOnly(_showFavoritesOnly));
  }

  void updateProjects(List<ProjectSummary> projects) {
    _sortedProjects = _sortProjects(projects);
  }

  List<ProjectSummary> filterProjects(Set<String> favoriteProjectIds) {
    var baseProjects = _sortedProjects;
    if (_showFavoritesOnly) {
      baseProjects = baseProjects
          .where((project) => favoriteProjectIds.contains(project.id))
          .toList();
    }
    if (_query.isEmpty) {
      return baseProjects;
    }
    final keyword = _query.toLowerCase();
    return baseProjects
        .where(
          (project) =>
              project.name.toLowerCase().contains(keyword) ||
              project.description.toLowerCase().contains(keyword),
        )
        .toList();
  }

  int favoriteCount(
    List<ProjectSummary> projects,
    Set<String> favoriteProjectIds,
  ) {
    return projects
        .where((project) => favoriteProjectIds.contains(project.id))
        .length;
  }

  static List<ProjectSummary> _sortProjects(List<ProjectSummary> projects) {
    final sorted = [...projects]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }
}
