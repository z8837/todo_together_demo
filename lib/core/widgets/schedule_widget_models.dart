class ScheduleWidgetTodo {
  const ScheduleWidgetTodo({
    required this.id,
    required this.title,
    required this.status,
    required this.isRecurring,
    required this.isHidden,
    required this.startDate,
    required this.startTime,
    required this.weekdayMask,
    required this.endDate,
    required this.endTime,
    required this.completedAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String status;
  final bool isRecurring;
  final bool isHidden;
  final DateTime? startDate;
  final String? startTime;
  final int? weekdayMask;
  final DateTime? endDate;
  final String? endTime;
  final DateTime? completedAt;
  final DateTime updatedAt;

  bool get isCompleted => status.toLowerCase() == 'done' || completedAt != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'is_recurring': isRecurring,
      'is_hidden': isHidden,
      'start_date': startDate?.toIso8601String(),
      'start_time': startTime,
      'weekday_mask': weekdayMask,
      'end_date': endDate?.toIso8601String(),
      'end_time': endTime,
      'completed_at': completedAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ScheduleWidgetHoliday {
  const ScheduleWidgetHoliday({
    required this.date,
    required this.name,
    required this.isHoliday,
  });

  final DateTime date;
  final String name;
  final bool isHoliday;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'name': name,
      'is_holiday': isHoliday,
    };
  }
}
