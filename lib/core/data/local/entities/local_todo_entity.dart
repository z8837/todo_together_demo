import 'package:isar_community/isar.dart';

part 'local_todo_entity.g.dart';

@collection
class LocalTodoEntity {
  LocalTodoEntity();

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String remoteId;

  @Index()
  late String projectId;

  String title = '';
  String status = 'todo';
  String kind = 'schedule';
  int version = 1;
  int createdByUserId = 0;
  bool isRecurring = false;
  bool isHidden = false;
  DateTime? startDate;
  String? startTime;
  int? weekdayMask;
  DateTime? endDate;
  String? endTime;
  int? alarmOffsetMinutes;
  DateTime? completedAt;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  List<int> assigneeIds = [];
}
