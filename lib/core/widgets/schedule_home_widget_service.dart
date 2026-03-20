import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import 'schedule_widget_models.dart';

class ScheduleHomeWidgetService {
  const ScheduleHomeWidgetService._();

  static const _appGroupId = 'group.kr.co.heeyun.todo_together_demo';
  static const _selectedDayKey = 'selected_day';
  static const _todoPreviewKey = 'todo_preview';
  static const _holidayPreviewKey = 'holiday_preview';

  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (_) {}
  }

  static Future<void> setSelectedDay(DateTime day) async {
    try {
      await HomeWidget.saveWidgetData<String>(
        _selectedDayKey,
        day.toIso8601String(),
      );
      await HomeWidget.updateWidget(
        androidName: 'ScheduleWidgetProvider',
        iOSName: 'ScheduleWidget',
      );
    } catch (_) {}
  }

  static void scheduleUpdateFromTodos(
    List<ScheduleWidgetTodo> todos, {
    List<ScheduleWidgetHoliday> holidays = const [],
  }) {
    updateFromTodos(todos, holidays: holidays);
  }

  static Future<void> updateFromTodos(
    List<ScheduleWidgetTodo> todos, {
    List<ScheduleWidgetHoliday> holidays = const [],
  }) async {
    try {
      final todoPayload = jsonEncode(
        todos.map((todo) => todo.toJson()).toList(growable: false),
      );
      final holidayPayload = jsonEncode(
        holidays.map((holiday) => holiday.toJson()).toList(growable: false),
      );
      await HomeWidget.saveWidgetData<String>(_todoPreviewKey, todoPayload);
      await HomeWidget.saveWidgetData<String>(
        _holidayPreviewKey,
        holidayPayload,
      );
      await HomeWidget.updateWidget(
        androidName: 'ScheduleWidgetProvider',
        iOSName: 'ScheduleWidget',
      );
    } catch (_) {}
  }
}
