part of 'schedule_fragment.dart';

enum _ScheduleTodoAction { edit, toggleCompletion, toggleVisibility }

class _ScheduledTodo {
  const _ScheduledTodo({required this.todo, required this.date});

  final ProjectTodo todo;
  final DateTime date;
}
