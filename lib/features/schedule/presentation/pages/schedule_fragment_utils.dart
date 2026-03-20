part of 'schedule_fragment.dart';

String _formatFullDate(DateTime day) => '{month}월 {day}일'.tr(
  namedArgs: {'month': day.month.toString(), 'day': day.day.toString()},
);

String _weekdayKorean(DateTime day) {
  final labels = [
    '일요일'.tr(),
    '월요일'.tr(),
    '화요일'.tr(),
    '수요일'.tr(),
    '목요일'.tr(),
    '금요일'.tr(),
    '토요일'.tr(),
  ];
  return labels[day.weekday % 7];
}

String _formatKoreanTime(ProjectTodo todo, DateTime day) {
  final normalizedDay = DateUtils.dateOnly(day);
  if (todo.isRecurring) {
    final startLabel = _formatKoreanTimeValue(todo.startTime);
    final endLabel = _formatKoreanTimeValue(todo.endTime);
    if (startLabel == null) {
      return '시간 미정'.tr();
    }
    if (endLabel == null) {
      return startLabel;
    }
    return '$startLabel ~ $endLabel';
  }

  final startDate = todo.startDate == null
      ? null
      : DateUtils.dateOnly(todo.startDate!);
  final endDate = todo.endDate == null
      ? null
      : DateUtils.dateOnly(todo.endDate!);
  final hasDateRange =
      startDate != null &&
      endDate != null &&
      !DateUtils.isSameDay(startDate, endDate);

  if (!hasDateRange) {
    final startLabel = _formatKoreanTimeValue(todo.startTime);
    final endLabel = _formatKoreanTimeValue(todo.endTime);
    if (startLabel == null) {
      return '시간 미정'.tr();
    }
    if (endLabel == null) {
      return startLabel;
    }
    return '$startLabel ~ $endLabel';
  }

  if (DateUtils.isSameDay(normalizedDay, startDate)) {
    final startLabel = _formatKoreanTimeValue(todo.startTime);
    return startLabel == null ? '시작시간 미정'.tr() : '시작 : $startLabel';
  }
  if (DateUtils.isSameDay(normalizedDay, endDate)) {
    final endLabel = _formatKoreanTimeValue(todo.endTime);
    return endLabel == null ? '마감시간 미정'.tr() : '마감 : $endLabel';
  }
  return '하루종일'.tr();
}

String? _formatKoreanTimeValue(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }

  final parts = raw.split(':');
  final hour = int.tryParse(parts.first) ?? 0;
  final minute = parts.length >= 2 ? int.tryParse(parts[1]) ?? 0 : 0;
  final isPm = hour >= 12;
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;

  final meridiem = isPm ? '오후'.tr() : '오전'.tr();
  return '$meridiem $hour12:${minute.toString().padLeft(2, '0')}';
}

bool _isScheduleOverdue(ProjectTodo todo, DateTime now) {
  if (todo.isCompleted) {
    return false;
  }
  final dueDateTime = _resolveScheduleOverdueDateTime(todo);
  if (dueDateTime == null) {
    return false;
  }
  return now.isAfter(dueDateTime);
}

DateTime? _resolveScheduleOverdueDateTime(ProjectTodo todo) {
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
    final endParts = _parseScheduleTimeParts(endTime);
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

  final endParts = _parseScheduleTimeParts(endTime);
  if (endParts != null) {
    return DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      endParts.$1,
      endParts.$2,
    );
  }

  final startParts = _parseScheduleTimeParts(startTime);
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

(int, int)? _parseScheduleTimeParts(String? raw) {
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

class _SchedulePalette {
  const _SchedulePalette._();
  static const divider = AppTokens.dividerSoft;
  static const background = AppTokens.surface;
  static const primary = Color(0xFF1A56FF);
  static const primarySoft = Color(0xFFD6E7FF);
  static const accent = Color(0xFF84A3FF);
  static const holiday = Color(0xFFDA4F4C);
  static const subHoliday = Color(0xFFE8AFAD);
  static const title = Color(0xFF1E2331);
  static const subtitle = Color(0xFFABB0BC);
  static const weekdays = Color(0xFFA1A2A8);
}
