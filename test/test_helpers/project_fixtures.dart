import 'package:todotogether/features/project/domain/entities/project_summary.dart';
import 'package:todotogether/features/project/domain/entities/project_todo.dart';

ProjectUser demoUser({
  int id = 1,
  String email = 'demo@todo-together.app',
  String nickname = 'Demo User',
  String? provider = 'mock',
}) {
  return ProjectUser(
    id: id,
    email: email,
    nickname: nickname,
    provider: provider,
  );
}

ProjectMember demoMember({
  int id = 2,
  String email = 'member@todo-together.app',
  String nickname = 'Member',
  String role = 'writer',
  String? provider = 'mock',
}) {
  return ProjectMember(
    id: id,
    email: email,
    nickname: nickname,
    provider: provider,
    role: role,
  );
}

ProjectSummary demoProject({
  String id = 'project-1',
  String? remoteId,
  String name = 'Demo Project',
  String description = 'Demo description',
  int version = 1,
  ProjectUser? owner,
  List<ProjectMember>? members,
  DateTime? recentUpdateAt,
  DateTime? createdAt,
  DateTime? updatedAt,
  bool isFavorite = false,
}) {
  final resolvedOwner = owner ?? demoUser();
  final resolvedCreatedAt = createdAt ?? DateTime(2026, 3, 1);
  final resolvedUpdatedAt = updatedAt ?? resolvedCreatedAt;
  return ProjectSummary(
    id: id,
    remoteId: remoteId ?? id,
    name: name,
    description: description,
    version: version,
    members: members ?? const [],
    owner: resolvedOwner,
    recentUpdateAt: recentUpdateAt,
    createdAt: resolvedCreatedAt,
    updatedAt: resolvedUpdatedAt,
    isFavorite: isFavorite,
  );
}

TodoUser demoTodoUser({
  int id = 1,
  String email = 'demo@todo-together.app',
  String nickname = 'Demo User',
}) {
  return TodoUser(id: id, email: email, nickname: nickname);
}

ProjectTodo demoTodo({
  String id = 'todo-1',
  String projectId = 'project-1',
  String title = 'Demo Todo',
  String status = 'todo',
  String kind = 'schedule',
  int version = 1,
  TodoUser? createdBy,
  bool isRecurring = false,
  bool isHidden = false,
  DateTime? startDate,
  String? startTime = '09:00:00',
  int? weekdayMask,
  DateTime? endDate,
  String? endTime = '18:00:00',
  int? alarmOffsetMinutes,
  DateTime? completedAt,
  DateTime? createdAt,
  DateTime? updatedAt,
  List<TodoUser>? assignees,
}) {
  final resolvedCreatedAt = createdAt ?? DateTime(2026, 3, 1, 9);
  return ProjectTodo(
    id: id,
    projectId: projectId,
    title: title,
    status: status,
    kind: kind,
    version: version,
    createdBy: createdBy ?? demoTodoUser(),
    isRecurring: isRecurring,
    isHidden: isHidden,
    startDate: startDate ?? DateTime(2026, 3, 1),
    startTime: startTime,
    weekdayMask: weekdayMask,
    endDate: endDate ?? DateTime(2026, 3, 1),
    endTime: endTime,
    alarmOffsetMinutes: alarmOffsetMinutes,
    completedAt: completedAt,
    createdAt: resolvedCreatedAt,
    updatedAt: updatedAt ?? resolvedCreatedAt,
    assignees: assignees ?? [demoTodoUser()],
  );
}
