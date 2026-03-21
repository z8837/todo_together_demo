import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import 'schedule_widget_models.dart';

class ScheduleHomeWidgetService {
  const ScheduleHomeWidgetService._();

  static const _appGroupId = 'group.kr.co.heeyun.todo_together_demo';
  static const _appSelectedDayKey = 'app_selected_day';
  static const _widgetSelectedDayKey = 'widget_selected_day';
  static const _todoPreviewKey = 'todo_preview';
  static const _holidayPreviewKey = 'holiday_preview';

  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (_) {}
  }

  // 앱 내부 캘린더 상태는 위젯이 읽는 날짜와 분리해 저장합니다.
  static Future<void> setAppSelectedDay(DateTime day) async {
    try {
      await HomeWidget.saveWidgetData<String>(
        _appSelectedDayKey,
        day.toIso8601String(),
      );
    } catch (_) {}
  }

  // 실제 위젯 선택 날짜는 네이티브 위젯 액션에서만 갱신하는 용도입니다.
  static Future<void> setWidgetSelectedDay(DateTime day) async {
    try {
      await HomeWidget.saveWidgetData<String>(
        _widgetSelectedDayKey,
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
