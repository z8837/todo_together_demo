import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todotogether/core/network/result/api_error.dart';
import 'package:todotogether/core/network/simple_result.dart';
import 'package:todotogether/features/project/domain/usecases/project_use_cases.dart';
import 'package:todotogether/features/project/presentation/viewmodels/add_todo/add_project_todo_view_model.dart';

import '../../../../../test_helpers/fake_project_repository.dart';
import '../../../../../test_helpers/project_fixtures.dart';

Future<SimpleResult<T, ApiError>> _executeAuthorized<T>(
  Future<SimpleResult<T, ApiError>> Function(String accessToken) action,
) {
  return action('token');
}

void main() {
  late AddProjectTodoSheetViewModel viewModel;

  setUp(() {
    viewModel = AddProjectTodoSheetViewModel(
      projectUseCases: ProjectUseCases(FakeProjectRepository()),
      executeAuthorized: _executeAuthorized,
    );
  });

  group('AddProjectTodoSheetViewModel', () {
    test('encodeWeekdays maps sunday-based selections to API bitmask', () {
      final mask = viewModel.encodeWeekdays([
        false,
        true,
        false,
        true,
        false,
        false,
        false,
      ]);

      expect(mask, 5);
    });

    test(
      'buildUpdateBody clears weekday mask when recurring todo becomes single',
      () {
        final project = demoProject();
        final initialTodo = demoTodo(
          id: 'todo-recurring',
          isRecurring: true,
          weekdayMask: 42,
          startDate: DateTime(2026, 3, 10),
          endDate: DateTime(2026, 3, 12),
          startTime: '10:00:00',
          endTime: '11:00:00',
        );

        final body = viewModel.buildUpdateBody(
          project: project,
          initialTodo: initialTodo,
          title: 'Updated Todo',
          isRecurring: false,
          singleStartDate: DateTime(2026, 3, 15),
          singleEndDate: DateTime(2026, 3, 16),
          singleStartTime: const TimeOfDay(hour: 9, minute: 0),
          singleEndTime: const TimeOfDay(hour: 18, minute: 0),
          recurringStartDate: DateTime(2026, 3, 10),
          recurringEndDate: DateTime(2026, 3, 12),
          recurringStartTime: const TimeOfDay(hour: 10, minute: 0),
          recurringEndTime: const TimeOfDay(hour: 11, minute: 0),
          weekdaySelections: const [
            false,
            true,
            false,
            true,
            false,
            false,
            false,
          ],
          totalAlarmMinutes: null,
        );

        expect(body['title'], 'Updated Todo');
        expect(body['weekday_mask'], 0);
        expect(body['start_date'], '2026-03-15');
        expect(body['end_date'], '2026-03-16');
        expect(body['start_time'], '09:00:00');
        expect(body['end_time'], '18:00:00');
      },
    );

    test(
      'canSubmit requires title and selected project when selection is enabled',
      () {
        expect(
          viewModel.canSubmit(
            isSubmitting: false,
            hasTitle: true,
            canSelectProject: true,
            selectedProject: null,
          ),
          isFalse,
        );

        expect(
          viewModel.canSubmit(
            isSubmitting: false,
            hasTitle: true,
            canSelectProject: true,
            selectedProject: demoProject(),
          ),
          isTrue,
        );
      },
    );
  });
}
