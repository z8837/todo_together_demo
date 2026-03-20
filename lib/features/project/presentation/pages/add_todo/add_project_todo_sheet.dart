import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:todotogether/app/router.dart';
import 'package:todotogether/core/localization/tr_extension.dart';
import 'package:todotogether/core/ui/app_system_ui.dart';
import 'package:todotogether/core/ui/app_tokens.dart';
import 'package:todotogether/core/widgets/w_tap.dart';
import 'package:todotogether/features/project/domain/entities/project_summary.dart';
import 'package:todotogether/features/project/domain/entities/project_todo.dart';
import 'package:todotogether/features/project/presentation/viewmodels/add_todo/add_project_todo_view_model.dart';
import 'package:todotogether/features/project/presentation/pages/add_todo/project_picker_screen.dart';
import 'package:todotogether/features/project/presentation/pages/create_project_page.dart';
import 'package:todotogether/features/project/presentation/state/project_feature_providers.dart';
import 'package:todotogether/core/ui/app_spacing.dart';
import 'package:todotogether/core/widgets/dialogs/app_confirm_dialog.dart';

class AddProjectTodoArgs {
  const AddProjectTodoArgs({
    this.project,
    this.initialTodo,
    this.initialSelectedDate,
    this.allowProjectSelection = false,
  });

  final ProjectSummary? project;
  final ProjectTodo? initialTodo;
  final DateTime? initialSelectedDate;
  final bool allowProjectSelection;
}

class AddProjectTodoSheet extends ConsumerStatefulWidget {
  const AddProjectTodoSheet({
    super.key,
    this.project,
    this.initialTodo,
    this.initialSelectedDate,
    this.allowProjectSelection = false,
  }) : assert(
         project != null || allowProjectSelection,
         'project must be provided when project selection is disabled',
       ),
       assert(
         initialTodo == null || project != null,
         'project must be provided when editing a todo',
       );

  final ProjectSummary? project;
  final ProjectTodo? initialTodo;
  final DateTime? initialSelectedDate;
  final bool allowProjectSelection;

  @override
  ConsumerState<AddProjectTodoSheet> createState() =>
      _AddProjectTodoSheetState();
}

class _AddProjectTodoSheetState extends ConsumerState<AddProjectTodoSheet> {
  static const TimeOfDay _defaultStartTime = TimeOfDay(hour: 0, minute: 0);
  static const TimeOfDay _defaultEndTime = TimeOfDay(hour: 23, minute: 59);
  static String get _defaultStartTimeLabel => '오전 12:00'.tr();
  static String get _defaultEndTimeLabel => '오후 11:59'.tr();
  late final AddProjectTodoSheetViewModel _viewModel;
  final TextEditingController _titleController = TextEditingController();
  ProjectSummary? _selectedProject;

  bool get _isEditing => widget.initialTodo != null;
  bool get _canSelectProject => widget.allowProjectSelection && !_isEditing;
  bool get _hasTitle => _titleController.text.trim().isNotEmpty;
  bool _isRecurring = false;
  DateTime _singleStartDate = DateUtils.dateOnly(DateTime.now());
  DateTime? _singleEndDate;
  TimeOfDay? _singleStartTime;
  TimeOfDay? _singleEndTime;
  DateTime _recurringStartDate = DateUtils.dateOnly(DateTime.now());
  DateTime? _recurringEndDate;
  TimeOfDay? _recurringStartTime;
  TimeOfDay? _recurringEndTime;
  final List<bool> _weekdaySelections = List<bool>.filled(7, false);
  bool _isSubmitting = false;

  bool _isAlarmEnabled = false;
  int _alarmHours = 0;
  int _alarmMinutes = 0;

  DateTime get _activeStartDate =>
      _isRecurring ? _recurringStartDate : _singleStartDate;

  DateTime? get _activeEndDate =>
      _isRecurring ? _recurringEndDate : _singleEndDate;

  TimeOfDay? get _activeStartTime =>
      _isRecurring ? _recurringStartTime : _singleStartTime;

  TimeOfDay? get _activeEndTime =>
      _isRecurring ? _recurringEndTime : _singleEndTime;

  @override
  void initState() {
    super.initState();
    _viewModel = ref.read(addProjectTodoSheetViewModelProvider);
    final today = DateUtils.dateOnly(DateTime.now());
    final baseDate = DateUtils.dateOnly(widget.initialSelectedDate ?? today);
    _selectedProject = widget.project;
    _titleController.addListener(_handleTitleChange);
    _singleStartDate = baseDate;
    _recurringStartDate = baseDate;
    if (widget.initialTodo == null && widget.initialSelectedDate != null) {
      final weekdayIndex = _weekdayIndex(_recurringStartDate);
      if (weekdayIndex >= 0 && weekdayIndex < _weekdaySelections.length) {
        _weekdaySelections[weekdayIndex] = true;
      }
    }
    final todo = widget.initialTodo;
    if (todo != null) {
      _prefillFromTodo(todo);
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_handleTitleChange);
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);
    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: AppSystemUi.mainOverlayStyle,
            child: Scaffold(
              resizeToAvoidBottomInset: true,
              backgroundColor: _TodoPalette.background,
              appBar: AppBar(
                elevation: 0,
                scrolledUnderElevation: 0,
                systemOverlayStyle: AppSystemUi.mainOverlayStyle,
                surfaceTintColor: Colors.transparent,
                backgroundColor: _TodoPalette.background,
                foregroundColor: _TodoPalette.title,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                title: Text(
                  _isEditing ? '일정 수정'.tr() : '일정 추가'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: _TodoPalette.title,
                  ),
                ),
                centerTitle: true,
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionCard(
                        header: _SectionHeader(
                          icon: Icons.folder_rounded,
                          title: '프로젝트'.tr(),
                        ),
                        child: _buildProjectSelector(context, projectsAsync),
                      ),
                      AppGap.h14,
                      _SectionCard(
                        header: _SectionHeader(
                          icon: Icons.short_text_rounded,
                          title: '일정 이름'.tr(),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _titleController,
                              decoration: _inputDecoration(
                                hintText: '팀 전체 회고 준비하기'.tr(),
                              ),
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),
                      ),
                      AppGap.h14,
                      _SectionCard(
                        header: _SectionHeader(
                          icon: Icons.event_rounded,
                          title: '날짜/시간'.tr(),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '반복'.tr(),
                                style: const TextStyle(
                                  color: _TodoPalette.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              AppGap.w6,
                              Switch.adaptive(
                                value: _isRecurring,
                                activeThumbColor: _TodoPalette.background,
                                activeTrackColor: _TodoPalette.primary,
                                inactiveTrackColor: _TodoPalette.border,
                                trackOutlineColor: WidgetStateProperty.all(
                                  _TodoPalette.border,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _isRecurring = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        child: _isRecurring
                            ? _RecurringInputs(
                                weekdaySelections: _weekdaySelections,
                                startDate: _recurringStartDate,
                                endDate: _recurringEndDate,
                                startTime: _recurringStartTime,
                                endTime: _recurringEndTime,
                                endDateLabel: '무기한'.tr(),
                                defaultStartTimeLabel: _defaultStartTimeLabel,
                                defaultEndTimeLabel: _defaultEndTimeLabel,
                                onWeekdayChanged: (index, selected) {
                                  setState(() {
                                    _weekdaySelections[index] = selected;
                                  });
                                },
                                onPickStartDate: () => _pickStartDate(context),
                                onPickEndDate: () => _pickEndDate(context),
                                onClearEndDate: () {
                                  setState(() {
                                    _recurringEndDate = null;
                                    _resetInvalidTimeRangeIfNeeded();
                                  });
                                },
                                onPickStartTime: () => _pickStartTime(context),
                                onPickEndTime: () => _pickEndTime(context),
                                onClearEndTime: () {
                                  setState(() {
                                    _recurringEndTime = null;
                                  });
                                },
                                onClearStartTime: () {
                                  setState(() {
                                    _recurringStartTime = null;
                                  });
                                },
                              )
                            : _NonRecurringInputs(
                                startDate: _singleStartDate,
                                endDate: _singleEndDate,
                                startTime: _singleStartTime,
                                endTime: _singleEndTime,
                                endDateLabel: _formatDisplayDateLabel(
                                  _singleStartDate,
                                ),
                                defaultStartTimeLabel: _defaultStartTimeLabel,
                                defaultEndTimeLabel: _defaultEndTimeLabel,
                                onPickStartDate: () => _pickStartDate(context),
                                onPickEndDate: () => _pickEndDate(context),
                                onClearEndDate: () {
                                  setState(() {
                                    _singleEndDate = null;
                                    _resetInvalidTimeRangeIfNeeded();
                                  });
                                },
                                onPickStartTime: () => _pickStartTime(context),
                                onPickEndTime: () => _pickEndTime(context),
                                onClearStartTime: () {
                                  setState(() {
                                    _singleStartTime = null;
                                  });
                                },
                                onClearEndTime: () {
                                  setState(() {
                                    _singleEndTime = null;
                                  });
                                },
                              ),
                      ),
                      AppGap.h24,
                      _SectionCard(
                        header: _SectionHeader(
                          icon: Icons.notifications_rounded,
                          title: "시작 전 알림".tr(),
                          trailing: Switch.adaptive(
                            value: _isAlarmEnabled,
                            activeThumbColor: _TodoPalette.background,
                            activeTrackColor: _TodoPalette.primary,
                            inactiveTrackColor: _TodoPalette.border,
                            trackOutlineColor: WidgetStateProperty.all(
                              _TodoPalette.border,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _isAlarmEnabled = value;
                                if (!value) {
                                  _alarmHours = 0;
                                  _alarmMinutes = 0;
                                }
                              });
                            },
                          ),
                        ),
                        child: _buildAlarmInputs(context),
                      ),
                      AppGap.h24,
                      if (isKeyboardVisible) ...[
                        AppGap.h16,
                        _buildSubmitButton(),
                        AppGap.h16,
                      ],
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: isKeyboardVisible
                  ? null
                  : SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _buildSubmitButton(),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectSelector(
    BuildContext context,
    AsyncValue<List<ProjectSummary>> projectsAsync,
  ) {
    final selectedProject = _selectedProject;
    final projects = projectsAsync.value;
    if (projects != null) {
      final favoriteProjectIds = ref.watch(favoriteProjectIdsProvider);
      _maybeAutoSelectProject(projects, favoriteProjectIds);
    }
    if (!_canSelectProject) {
      return _ProjectNameTile(
        name: selectedProject?.name ?? widget.project?.name ?? '',
      );
    }

    final isLoading = projectsAsync.isLoading;
    final hasError = projectsAsync.hasError;
    final label = isLoading
        ? '프로젝트를 불러오는 중이에요.'.tr()
        : hasError
        ? '프로젝트 정보를 불러올 수 없어요.'.tr()
        : (selectedProject?.name ?? '프로젝트를 선택해주세요.'.tr());
    final hint = isLoading
        ? '잠시만 기다려주세요.'.tr()
        : hasError
        ? '잠시 후 다시 시도해주세요.'.tr()
        : selectedProject == null
        ? '프로젝트를 선택해야 저장할 수 있어요.'.tr()
        : '탭해서 프로젝트를 변경할 수 있어요.'.tr();
    final canTap = !isLoading && !hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputTile(
          label: label,
          icon: null,
          onTap: canTap
              ? () => _handleProjectSelection(
                  context,
                  projectsAsync.value ?? const <ProjectSummary>[],
                )
              : () {},
          trailing: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _TodoPalette.primary,
                  ),
                )
              : const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          isPlaceholder: selectedProject == null || isLoading || hasError,
        ),
        AppGap.h8,
        Text(
          hint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _TodoPalette.muted,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Future<void> _handleProjectSelection(
    BuildContext context,
    List<ProjectSummary> projects,
  ) async {
    if (!_canSelectProject) {
      return;
    }

    _clearFocus(context);
    final action = await _openProjectPickerScreen(context, projects);
    if (!context.mounted || action == null) {
      return;
    }

    ProjectSummary? targetProject;
    if (action.shouldCreateProject) {
      targetProject = await _openCreateProjectPage(context);
    } else {
      targetProject = action.project;
    }

    if (!context.mounted || targetProject == null) {
      return;
    }

    setState(() {
      _selectedProject = targetProject;
    });
    _clearFocus(context);
  }

  void _maybeAutoSelectProject(
    List<ProjectSummary> projects,
    Set<String> favoriteProjectIds,
  ) {
    if (!_canSelectProject || _selectedProject != null) {
      return;
    }

    final target = _resolveAutoSelectProject(projects, favoriteProjectIds);
    if (target == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selectedProject != null) {
        return;
      }
      setState(() {
        _selectedProject = target;
      });
    });
  }

  ProjectSummary? _resolveAutoSelectProject(
    List<ProjectSummary> projects,
    Set<String> favoriteProjectIds,
  ) {
    return _viewModel.resolveAutoSelectProject(projects, favoriteProjectIds);
  }

  Future<ProjectPickerResult?> _openProjectPickerScreen(
    BuildContext context,
    List<ProjectSummary> projects,
  ) {
    return context.push<ProjectPickerResult>(
      AppRoutePaths.projectPicker,
      extra: ProjectPickerArgs(
        projects: projects,
        selectedProject: _selectedProject,
      ),
    );
  }

  Future<ProjectSummary?> _openCreateProjectPage(BuildContext context) async {
    final result = await context.push<CreateProjectResult>(
      AppRoutePaths.projectEditor,
      extra: const CreateProjectArgs(),
    );
    if (result == null || result.isDeleted) {
      return null;
    }
    return result.project;
  }

  bool get _canSubmit => _viewModel.canSubmit(
    isSubmitting: _isSubmitting,
    hasTitle: _hasTitle,
    canSelectProject: _canSelectProject,
    selectedProject: _selectedProject,
  );

  Widget _buildSubmitButton() {
    final submitButton = SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: _TodoPalette.primary,
          side: BorderSide(
            color: _canSubmit ? _TodoPalette.secondary : _TodoPalette.border,
          ),
          padding: AppInsets.v12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: _canSubmit ? _handleSubmit : null,
        child: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _TodoPalette.title,
                ),
              )
            : Text(
                _isSubmitting
                    ? (_isEditing ? '수정 중...'.tr() : '추가 중...'.tr())
                    : (_isEditing ? '수정 완료'.tr() : '추가하기'.tr()),
              ),
      ),
    );

    if (!_isEditing) {
      return submitButton;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        submitButton,
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _buildDeleteButton(),
        ),
      ],
    );
  }

  Widget _buildDeleteButton() {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        foregroundColor: Colors.redAccent,
        side: const BorderSide(color: Colors.redAccent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      onPressed: _isSubmitting ? null : _confirmDeleteTodo,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.delete_outline, size: 20),
          AppGap.w8,
          Text(
            '삭제하기'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmInputs(BuildContext context) {
    final label = _isAlarmEnabled
        ? _formatAlarmSummary(_alarmHours, _alarmMinutes)
        : '알림 꺼짐'.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputTile(
          label: label,
          icon: Icons.notifications_active_outlined,
          onTap: _isAlarmEnabled
              ? () => _pickAlarmOffset(context)
              : () {
                  setState(() {
                    _isAlarmEnabled = true;
                  });
                },
          isPlaceholder: !_isAlarmEnabled,
          trailing: _isAlarmEnabled
              ? const Icon(Icons.chevron_right_rounded, size: 18.0)
              : null,
        ),
        AppGap.h8,
        Text(
          '일정 시작 전에 알림을 받을 시간을 설정해요.'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _TodoPalette.muted,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Future<DateTime?> _pickDate(
    BuildContext context,
    DateTime initial, {
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    FocusScope.of(context).unfocus();
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate ?? DateTime(DateTime.now().year - 5),
      lastDate: lastDate ?? DateTime(DateTime.now().year + 5),
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: Colors.white,
              headerForegroundColor: Colors.black,
              // // 선택된 날짜 동그라미 색 등
              // dayBackgroundColor: WidgetStatePropertyAll(AppTokens.todoRecurring),
              // dayForegroundColor: WidgetStatePropertyAll(Colors.white),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final selected = await _pickDate(context, _activeStartDate);
    if (!context.mounted) return;
    _clearFocus(context);
    if (selected != null) {
      final previousStartDate = _activeStartDate;
      final previousEndDate = _activeEndDate;
      setState(() {
        if (_isRecurring) {
          _recurringStartDate = selected;
          if (previousEndDate != null &&
              DateUtils.isSameDay(previousStartDate, previousEndDate)) {
            _recurringEndDate = selected;
          } else if (_recurringEndDate != null &&
              _recurringEndDate!.isBefore(selected)) {
            _recurringEndDate = null;
          }
        } else {
          _singleStartDate = selected;
          if (previousEndDate != null &&
              DateUtils.isSameDay(previousStartDate, previousEndDate)) {
            _singleEndDate = selected;
          } else if (_singleEndDate != null &&
              _singleEndDate!.isBefore(selected)) {
            _singleEndDate = null;
          }
        }
        _resetInvalidTimeRangeIfNeeded();
      });
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final selected = await _pickDate(
      context,
      _activeEndDate ?? _activeStartDate,
      firstDate: _activeStartDate,
    );
    if (!context.mounted) return;
    _clearFocus(context);
    if (selected != null) {
      setState(() {
        if (_isRecurring) {
          _recurringEndDate = selected;
        } else {
          _singleEndDate = selected;
        }
        _resetInvalidTimeRangeIfNeeded();
      });
    }
  }

  Future<T?> _showBearPickerDialog<T>({
    required String barrierLabel,
    required Widget Function(BuildContext, StateSetter) builder,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Align(
            alignment: Alignment.center,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: AppInsets.screenTop24,
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppTokens.divider, width: 0.6),
                    ),
                    child: StatefulBuilder(builder: builder),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<TimeOfDay?> showWheelTimePickerAmPm({
    required TimeOfDay initial,
    int minuteInterval = 1, // 1, 5, 10 ??
    int? minMinutes,
    int? maxMinutes,
  }) async {
    // initial -> AM/PM + 12-hour
    int initialMinutes = initial.hour * 60 + initial.minute;
    if (minMinutes != null && initialMinutes < minMinutes) {
      initialMinutes = minMinutes;
    }
    if (maxMinutes != null && initialMinutes > maxMinutes) {
      initialMinutes = maxMinutes;
    }

    int periodIndex = initialMinutes >= 12 * 60 ? 1 : 0; // 0=무기한??, 1=무기한??
    int hour12 = (initialMinutes ~/ 60) % 12;
    if (hour12 == 0) hour12 = 12;

    int selectedPeriod = periodIndex; // 0=무기한??, 1=무기한??
    int selectedHour12 = hour12; // 1..12
    int selectedMinute =
        ((initialMinutes % 60) ~/ minuteInterval) * minuteInterval;

    int toMinutes(int period, int hour, int minute) {
      final hour24 = (hour % 12) + (period == 1 ? 12 : 0);
      return hour24 * 60 + minute;
    }

    bool isAllowed(int minutes) {
      if (minMinutes != null && minutes < minMinutes) {
        return false;
      }
      if (maxMinutes != null && minutes > maxMinutes) {
        return false;
      }
      return true;
    }

    bool hasAllowedMinutes(int period, int hour) {
      for (var minute = 0; minute < 60; minute += minuteInterval) {
        final total = toMinutes(period, hour, minute);
        if (isAllowed(total)) {
          return true;
        }
      }
      return false;
    }

    List<int> availablePeriods() {
      final periods = <int>[];
      for (final period in [0, 1]) {
        for (var hour = 1; hour <= 12; hour++) {
          if (hasAllowedMinutes(period, hour)) {
            periods.add(period);
            break;
          }
        }
      }
      return periods.isEmpty ? [selectedPeriod] : periods;
    }

    List<int> availableHours(int period) {
      final hours = <int>[];
      for (var hour = 1; hour <= 12; hour++) {
        if (hasAllowedMinutes(period, hour)) {
          hours.add(hour);
        }
      }
      return hours.isEmpty ? [selectedHour12] : hours;
    }

    List<int> availableMinutes(int period, int hour) {
      final minutes = <int>[];
      for (var minute = 0; minute < 60; minute += minuteInterval) {
        final total = toMinutes(period, hour, minute);
        if (isAllowed(total)) {
          minutes.add(minute);
        }
      }
      return minutes.isEmpty ? [selectedMinute] : minutes;
    }

    TimeOfDay toTimeOfDay() {
      final h = selectedHour12 % 12; // 12 -> 0 무기한무기한
      final hour24 = selectedPeriod == 0 ? h : h + 12; // 무기한??/무기한?? 무기한무기한
      return TimeOfDay(hour: hour24, minute: selectedMinute);
    }

    String label() {
      final p = selectedPeriod == 0 ? '오전'.tr() : '오후'.tr();
      final hh = selectedHour12.toString();
      final mm = selectedMinute.toString().padLeft(2, '0');
      return '{period} {hour}시 {minute}분'.tr(
        namedArgs: {'period': p, 'hour': hh, 'minute': mm},
      );
    }

    final initialPeriods = availablePeriods();
    if (!initialPeriods.contains(selectedPeriod)) {
      selectedPeriod = initialPeriods.first;
    }
    final initialHours = availableHours(selectedPeriod);
    if (!initialHours.contains(selectedHour12)) {
      selectedHour12 = initialHours.first;
    }
    final initialMinuteOptions = availableMinutes(
      selectedPeriod,
      selectedHour12,
    );
    if (!initialMinuteOptions.contains(selectedMinute)) {
      selectedMinute = initialMinuteOptions.first;
    }

    int safeIndex(List<int> values, int target) {
      final index = values.indexOf(target);
      return index < 0 ? 0 : index;
    }

    final periodCtrl = FixedExtentScrollController(
      initialItem: safeIndex(initialPeriods, selectedPeriod),
    );
    final hourCtrl = FixedExtentScrollController(
      initialItem: safeIndex(initialHours, selectedHour12),
    );
    final minuteCtrl = FixedExtentScrollController(
      initialItem: safeIndex(initialMinuteOptions, selectedMinute),
    );

    final result = await _showBearPickerDialog<TimeOfDay>(
      barrierLabel: '시간 선택'.tr(),
      builder: (ctx, setState) {
        final periods = availablePeriods();
        if (!periods.contains(selectedPeriod)) {
          selectedPeriod = periods.first;
          if (periodCtrl.hasClients) {
            periodCtrl.jumpToItem(safeIndex(periods, selectedPeriod));
          }
        }

        final hours = availableHours(selectedPeriod);
        if (!hours.contains(selectedHour12)) {
          selectedHour12 = hours.first;
          if (hourCtrl.hasClients) {
            hourCtrl.jumpToItem(safeIndex(hours, selectedHour12));
          }
        }

        final minutes = availableMinutes(selectedPeriod, selectedHour12);
        if (!minutes.contains(selectedMinute)) {
          selectedMinute = minutes.first;
          if (minuteCtrl.hasClients) {
            minuteCtrl.jumpToItem(safeIndex(minutes, selectedMinute));
          }
        }

        return SizedBox(
          height: 340,
          child: Column(
            children: [
              Padding(
                padding: AppInsets.h6v6,
                child: Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTokens.textPrimary,
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('취소'.tr()),
                    ),
                    const Spacer(),
                    Text(
                      label(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTokens.textPrimary,
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      onPressed: () => Navigator.pop(ctx, toTimeOfDay()),
                      child: Text('완료'.tr()),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker.builder(
                        scrollController: periodCtrl,
                        itemExtent: 40,
                        useMagnifier: false,
                        magnification: 1.0,
                        selectionOverlay:
                            const CupertinoPickerDefaultSelectionOverlay(),
                        onSelectedItemChanged: (i) => setState(() {
                          selectedPeriod = periods[i];
                          final updatedHours = availableHours(selectedPeriod);
                          if (!updatedHours.contains(selectedHour12)) {
                            selectedHour12 = updatedHours.first;
                            if (hourCtrl.hasClients) {
                              hourCtrl.jumpToItem(
                                safeIndex(updatedHours, selectedHour12),
                              );
                            }
                          }
                          final updatedMinutes = availableMinutes(
                            selectedPeriod,
                            selectedHour12,
                          );
                          if (!updatedMinutes.contains(selectedMinute)) {
                            selectedMinute = updatedMinutes.first;
                            if (minuteCtrl.hasClients) {
                              minuteCtrl.jumpToItem(
                                safeIndex(updatedMinutes, selectedMinute),
                              );
                            }
                          }
                        }),
                        childCount: periods.length,
                        itemBuilder: (_, i) {
                          final period = periods[i];
                          return Center(
                            child: Text(period == 0 ? '오전'.tr() : '오후'.tr()),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker.builder(
                        scrollController: hourCtrl,
                        itemExtent: 40,
                        useMagnifier: false,
                        magnification: 1.0,
                        selectionOverlay:
                            const CupertinoPickerDefaultSelectionOverlay(),
                        onSelectedItemChanged: (i) => setState(() {
                          selectedHour12 = hours[i];
                          final updatedMinutes = availableMinutes(
                            selectedPeriod,
                            selectedHour12,
                          );
                          if (!updatedMinutes.contains(selectedMinute)) {
                            selectedMinute = updatedMinutes.first;
                            if (minuteCtrl.hasClients) {
                              minuteCtrl.jumpToItem(
                                safeIndex(updatedMinutes, selectedMinute),
                              );
                            }
                          }
                        }),
                        childCount: hours.length,
                        itemBuilder: (_, i) => Center(
                          child: Text(
                            '{hour}시'.tr(
                              namedArgs: {'hour': hours[i].toString()},
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker.builder(
                        scrollController: minuteCtrl,
                        itemExtent: 40,
                        useMagnifier: false,
                        magnification: 1.0,
                        selectionOverlay:
                            const CupertinoPickerDefaultSelectionOverlay(),
                        onSelectedItemChanged: (i) =>
                            setState(() => selectedMinute = minutes[i]),
                        childCount: minutes.length,
                        itemBuilder: (_, i) {
                          final minute = minutes[i];
                          return Center(
                            child: Text(
                              '{minute}분'.tr(
                                namedArgs: {
                                  'minute': minute.toString().padLeft(2, '0'),
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    return result;
  }

  Future<void> _pickStartTime(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final endTime = _activeEndTime;
    final selected = await showWheelTimePickerAmPm(
      initial: _activeStartTime ?? _defaultStartTime,
      maxMinutes: _shouldLockTimeRange() && endTime != null
          ? _timeOfDayToMinutes(endTime)
          : null,
    );

    if (!context.mounted) return;
    _clearFocus(context);
    if (selected != null) {
      if (_shouldLockTimeRange() &&
          endTime != null &&
          _compareTimeOfDay(selected, endTime) > 0) {
        _showMessage('시작 시간은 마감 시간 이전으로 선택해주세요.'.tr());
        return;
      }
      setState(() {
        if (_isRecurring) {
          _recurringStartTime = selected;
        } else {
          _singleStartTime = selected;
        }
      });
    }
  }

  Future<void> _pickEndTime(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final startTime = _activeStartTime;
    final endTime = _activeEndTime;
    TimeOfDay initial = endTime ?? startTime ?? _defaultEndTime;
    if (startTime != null && endTime != null) {
      final startMinutes = _timeOfDayToMinutes(startTime);
      final endMinutes = _timeOfDayToMinutes(endTime);
      if (endMinutes < startMinutes) {
        initial = startTime;
      }
    }
    final selected = await showWheelTimePickerAmPm(
      initial: initial,
      minMinutes: _shouldLockTimeRange() && startTime != null
          ? _timeOfDayToMinutes(startTime)
          : null,
    );

    if (!context.mounted) return;
    _clearFocus(context);
    if (selected != null) {
      if (_shouldLockTimeRange() &&
          startTime != null &&
          _compareTimeOfDay(selected, startTime) < 0) {
        _showMessage('마감 시간은 시작 시간 이후로 선택해주세요.'.tr());
        return;
      }
      setState(() {
        if (_isRecurring) {
          _recurringEndTime = selected;
        } else {
          _singleEndTime = selected;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedProject == null) {
      _showMessage('프로젝트를 선택해주세요.'.tr());
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showMessage('일정 이름을 입력해주세요.'.tr());
      return;
    }

    final startDate = _activeStartDate;
    final endDate = _activeEndDate;

    if (_isRecurring) {
      if (!_weekdaySelections.contains(true)) {
        _showMessage('반복 요일을 최소 한 개 이상 선택해주세요.'.tr());
        return;
      }
      if (_shouldLockTimeRange() && !_isValidTimeRange()) {
        _showMessage('시간 범위를 확인해주세요.'.tr());
        return;
      }
      if (endDate != null && endDate.isBefore(startDate)) {
        _showMessage('마감 날짜는 시작 날짜 이후여야 해요.'.tr());
        return;
      }
    } else {
      if (endDate != null && endDate.isBefore(startDate)) {
        _showMessage('마감 날짜는 시작 날짜 이후여야 해요.'.tr());
        return;
      }
      if (_shouldLockTimeRange() && !_isValidTimeRange()) {
        _showMessage('시간 범위를 확인해주세요.'.tr());
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    final int? totalAlarmMinutes = _isAlarmEnabled
        ? (_alarmHours * 60) + _alarmMinutes
        : null;

    final body = _buildRequestBody(
      title: title,
      totalAlarmMinutes: totalAlarmMinutes,
    );
    final updateBody = _isEditing
        ? _buildUpdateBody(title: title, totalAlarmMinutes: totalAlarmMinutes)
        : null;
    if (_isEditing && updateBody!.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
      });
      Navigator.of(context).pop(true);
      return;
    }

    final result = await _viewModel.submitTodo(
      isEditing: _isEditing,
      todoId: widget.initialTodo?.id ?? '',
      createBody: body,
      updateBody: updateBody ?? const <String, dynamic>{},
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (result.isSuccess) {
      Navigator.of(context).pop(true);
    } else {
      _showMessage(result.failureData?.message ?? '처리 중 오류가 발생했습니다.');
    }
  }

  Map<String, dynamic> _buildRequestBody({
    required String title,
    required int? totalAlarmMinutes,
  }) {
    final project = _selectedProject ?? widget.project;
    return _viewModel.buildRequestBody(
      project: project!,
      initialTodo: widget.initialTodo,
      isEditing: _isEditing,
      title: title,
      isRecurring: _isRecurring,
      singleStartDate: _singleStartDate,
      singleEndDate: _singleEndDate,
      singleStartTime: _singleStartTime,
      singleEndTime: _singleEndTime,
      recurringStartDate: _recurringStartDate,
      recurringEndDate: _recurringEndDate,
      recurringStartTime: _recurringStartTime,
      recurringEndTime: _recurringEndTime,
      weekdaySelections: _weekdaySelections,
      totalAlarmMinutes: totalAlarmMinutes,
    );
  }

  Map<String, dynamic> _buildUpdateBody({
    required String title,
    required int? totalAlarmMinutes,
  }) {
    final project = _selectedProject ?? widget.project;
    return _viewModel.buildUpdateBody(
      project: project!,
      initialTodo: widget.initialTodo,
      title: title,
      isRecurring: _isRecurring,
      singleStartDate: _singleStartDate,
      singleEndDate: _singleEndDate,
      singleStartTime: _singleStartTime,
      singleEndTime: _singleEndTime,
      recurringStartDate: _recurringStartDate,
      recurringEndDate: _recurringEndDate,
      recurringStartTime: _recurringStartTime,
      recurringEndTime: _recurringEndTime,
      weekdaySelections: _weekdaySelections,
      totalAlarmMinutes: totalAlarmMinutes,
    );
  }

  Future<void> _confirmDeleteTodo() async {
    final todo = widget.initialTodo;
    if (todo == null) {
      return;
    }

    final shouldDelete = await showAppConfirmDialog(
      context: context,
      title: '일정 삭제'.tr(),
      message: '"{title}" 일정을 삭제할까요?'.tr(namedArgs: {'title': todo.title}),
      confirmColor: Colors.redAccent,
      confirmLabel: '삭제'.tr(),
      cancelLabel: '취소'.tr(),
    );

    if (shouldDelete == true) {
      await _deleteTodo(todo);
    }
  }

  Future<void> _deleteTodo(ProjectTodo todo) async {
    final navigator = Navigator.of(context);
    final closeDialog = _showLoadingDialog(context);
    final result = await _viewModel.deleteTodo(todoId: todo.id);

    closeDialog();

    if (!mounted) {
      return;
    }

    if (result.isSuccess) {
      //       messenger.showSnackBar(
      //         const SnackBar(content: Text('일정을 삭제했어요.'.tr())),
      //       );
      navigator.pop(true);
    } else {
      _showMessage(result.failureData?.message ?? '처리 중 오류가 발생했습니다.');
    }
  }

  VoidCallback _showLoadingDialog(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    return () {
      if (navigator.canPop()) {
        navigator.pop();
      }
    };
  }

  void _prefillFromTodo(ProjectTodo todo) {
    _titleController.text = todo.title;
    _isRecurring = todo.isRecurring;

    if (todo.alarmOffsetMinutes != null) {
      final alarmMinutes = max(todo.alarmOffsetMinutes!, 0);
      _isAlarmEnabled = true;
      _alarmHours = (alarmMinutes ~/ 60).clamp(0, 23);
      _alarmMinutes = (alarmMinutes % 60).clamp(0, 59);
    } else {
      _isAlarmEnabled = false;
      _alarmHours = 0;
      _alarmMinutes = 0;
    }

    if (todo.isRecurring) {
      final mask = todo.weekdayMask ?? 0;
      for (var i = 0; i < _weekdaySelections.length; i++) {
        final bitIndex = (i + 6) % 7;
        _weekdaySelections[i] = (mask & (1 << bitIndex)) != 0;
      }
    }
    final startDate = todo.startDate ?? DateTime.now();
    final endDate = todo.endDate;
    final startTime = _parseTimeOfDay(todo.startTime);
    final endTime = _parseTimeOfDay(todo.endTime);

    if (todo.isRecurring) {
      _recurringStartDate = startDate;
      _recurringEndDate = endDate;
      _recurringStartTime = startTime;
      _recurringEndTime = endTime;
    } else {
      _singleStartDate = startDate;
      _singleEndDate = endDate;
      _singleStartTime = startTime;
      _singleEndTime = endTime;
    }
  }

  int _weekdayIndex(DateTime day) {
    return _viewModel.weekdayIndex(day);
  }

  TimeOfDay? _parseTimeOfDay(String? raw) {
    return _viewModel.parseTimeOfDay(raw);
  }

  String _formatAlarmSummary(int hours, int minutes) {
    if (hours == 0 && minutes == 0) {
      return '시작 시간에 알림'.tr();
    }
    if (hours == 0) {
      return '시작 {minutes}분전에 알림'.tr(
        namedArgs: {'minutes': minutes.toString()},
      );
    }
    if (minutes == 0) {
      return '시작 {hours}시간전에 알림'.tr(namedArgs: {'hours': hours.toString()});
    }
    return '시작 {hours}시간 {minutes}분전에 알림'.tr(
      namedArgs: {'hours': hours.toString(), 'minutes': minutes.toString()},
    );
  }

  Future<void> _pickAlarmOffset(BuildContext context) async {
    FocusScope.of(context).unfocus();
    var selectedHour = _alarmHours.clamp(0, 23);
    var selectedMinute = _alarmMinutes.clamp(0, 59);
    final hourCtrl = FixedExtentScrollController(initialItem: selectedHour);
    final minuteCtrl = FixedExtentScrollController(initialItem: selectedMinute);
    final selected = await _showBearPickerDialog<_AlarmOffset>(
      barrierLabel: '알림 선택'.tr(),
      builder: (ctx, setState) {
        return SizedBox(
          height: 340,
          child: Column(
            children: [
              Padding(
                padding: AppInsets.h6v6,
                child: Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTokens.textPrimary,
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('취소'.tr()),
                    ),
                    const Spacer(),
                    Text(
                      _formatAlarmSummary(selectedHour, selectedMinute),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTokens.textPrimary,
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      onPressed: () => Navigator.pop(
                        ctx,
                        _AlarmOffset(selectedHour, selectedMinute),
                      ),
                      child: Text('완료'.tr()),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker.builder(
                        scrollController: hourCtrl,
                        itemExtent: 40,
                        useMagnifier: false,
                        magnification: 1.0,
                        selectionOverlay:
                            const CupertinoPickerDefaultSelectionOverlay(),
                        onSelectedItemChanged: (i) =>
                            setState(() => selectedHour = i),
                        childCount: 24,
                        itemBuilder: (_, i) => Center(
                          child: Text(
                            '{hours}시간'.tr(namedArgs: {'hours': i.toString()}),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker.builder(
                        scrollController: minuteCtrl,
                        itemExtent: 40,
                        useMagnifier: false,
                        magnification: 1.0,
                        selectionOverlay:
                            const CupertinoPickerDefaultSelectionOverlay(),
                        onSelectedItemChanged: (i) =>
                            setState(() => selectedMinute = i),
                        childCount: 60,
                        itemBuilder: (_, i) => Center(
                          child: Text(
                            '{minute}분'.tr(
                              namedArgs: {
                                'minute': i.toString().padLeft(2, '0'),
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _alarmHours = selected.hours;
      _alarmMinutes = selected.minutes;
    });
  }

  bool _shouldLockTimeRange() {
    return _viewModel.shouldLockTimeRange(
      isRecurring: _isRecurring,
      activeStartDate: _activeStartDate,
      activeEndDate: _activeEndDate,
    );
  }

  bool _isValidTimeRange() {
    return _viewModel.isValidTimeRange(
      activeStartTime: _activeStartTime,
      activeEndTime: _activeEndTime,
    );
  }

  void _resetInvalidTimeRangeIfNeeded() {
    if (!_shouldLockTimeRange()) {
      return;
    }
    final startTime = _activeStartTime;
    final endTime = _activeEndTime;
    if (startTime == null || endTime == null) {
      return;
    }
    if (_compareTimeOfDay(startTime, endTime) > 0) {
      if (_isRecurring) {
        _recurringStartTime = null;
        _recurringEndTime = null;
      } else {
        _singleStartTime = null;
        _singleEndTime = null;
      }
    }
  }

  int _compareTimeOfDay(TimeOfDay a, TimeOfDay b) {
    return _viewModel.compareTimeOfDay(a, b);
  }

  int _timeOfDayToMinutes(TimeOfDay time) {
    return _viewModel.timeOfDayToMinutes(time);
  }

  void _clearFocus(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _handleTitleChange() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _showMessage(String message) {
    if (!mounted) return;
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text(message)),
    //     );
  }
}

class _NonRecurringInputs extends StatelessWidget {
  const _NonRecurringInputs({
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.endDateLabel,
    required this.defaultStartTimeLabel,
    required this.defaultEndTimeLabel,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onClearEndDate,
    required this.onPickStartTime,
    required this.onPickEndTime,
    required this.onClearStartTime,
    required this.onClearEndTime,
  });

  final DateTime startDate;
  final DateTime? endDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String endDateLabel;
  final String defaultStartTimeLabel;
  final String defaultEndTimeLabel;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final VoidCallback onClearEndDate;
  final VoidCallback onPickStartTime;
  final VoidCallback onPickEndTime;
  final VoidCallback onClearStartTime;
  final VoidCallback onClearEndTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('시작'.tr()),
        AppGap.h8,
        _DateTimeRow(
          dateLabel: _formatDisplayDateLabel(startDate),
          timeLabel: startTime == null
              ? defaultStartTimeLabel
              : startTime!.format(context),
          dateLabelIsPlaceholder: false,
          timeLabelIsPlaceholder: startTime == null,
          onPickDate: onPickStartDate,
          onPickTime: onPickStartTime,
          onClearTime: onClearStartTime,
          showClearTime: startTime != null,
        ),
        AppGap.h12,
        _FieldLabel('마감'.tr()),
        AppGap.h8,
        _DateTimeRow(
          dateLabel: endDate == null
              ? endDateLabel
              : _formatDisplayDateLabel(endDate!),
          timeLabel: endTime == null
              ? defaultEndTimeLabel
              : endTime!.format(context),
          dateLabelIsPlaceholder: endDate == null,
          timeLabelIsPlaceholder: endTime == null,
          onPickDate: onPickEndDate,
          onPickTime: onPickEndTime,
          onClearDate: onClearEndDate,
          onClearTime: onClearEndTime,
          showClearDate: endDate != null,
          showClearTime: endTime != null,
        ),
      ],
    );
  }
}

class _RecurringInputs extends StatelessWidget {
  const _RecurringInputs({
    required this.weekdaySelections,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.endDateLabel,
    required this.defaultStartTimeLabel,
    required this.defaultEndTimeLabel,
    required this.onWeekdayChanged,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onClearEndDate,
    required this.onPickStartTime,
    required this.onPickEndTime,
    required this.onClearEndTime,
    required this.onClearStartTime,
  });

  final List<bool> weekdaySelections;
  final DateTime startDate;
  final DateTime? endDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String endDateLabel;
  final String defaultStartTimeLabel;
  final String defaultEndTimeLabel;
  final void Function(int index, bool selected) onWeekdayChanged;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final VoidCallback onClearEndDate;
  final VoidCallback onPickStartTime;
  final VoidCallback onPickEndTime;
  final VoidCallback onClearEndTime;
  final VoidCallback onClearStartTime;

  List<String> get _weekdayLabels => [
    '일'.tr(),
    '월'.tr(),
    '화'.tr(),
    '수'.tr(),
    '목'.tr(),
    '금'.tr(),
    '토'.tr(),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('반복 요일'.tr()),
        AppGap.h8,
        Row(
          children: List.generate(7, (index) {
            final selected = weekdaySelections[index];
            final isSunday = index == 0;
            final labelColor = isSunday
                ? Colors.redAccent
                : selected
                ? _TodoPalette.primary
                : _TodoPalette.title;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 6 ? 0 : 4),
                child: FilterChip(
                  padding: EdgeInsets.zero,
                  label: Center(child: Text(_weekdayLabels[index])),
                  selected: selected,
                  showCheckmark: false,
                  backgroundColor: Colors.white,
                  selectedColor: _TodoPalette.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                  onSelected: (value) => onWeekdayChanged(index, value),
                ),
              ),
            );
          }),
        ),
        AppGap.h16,
        _FieldLabel('날짜'.tr()),
        AppGap.h8,
        _DateRangeRow(
          startDate: startDate,
          endDate: endDate,
          onPickStartDate: onPickStartDate,
          onPickEndDate: onPickEndDate,
          onClearEndDate: onClearEndDate,
          endDateLabel: endDateLabel,
          endDateLabelIsPlaceholder: endDate == null,
        ),
        AppGap.h12,
        _FieldLabel('시간'.tr()),
        AppGap.h8,
        _TimeRangeRow(
          startTime: startTime,
          endTime: endTime,
          onPickStartTime: onPickStartTime,
          onPickEndTime: onPickEndTime,
          onClearEndTime: onClearEndTime,
          onClearStartTime: onClearStartTime,
          startLabel: defaultStartTimeLabel,
          endLabel: defaultEndTimeLabel,
          startLabelIsPlaceholder: startTime == null,
          endLabelIsPlaceholder: endTime == null,
        ),
      ],
    );
  }
}

String _formatDisplayDateLabel(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

class _DateRangeRow extends StatelessWidget {
  const _DateRangeRow({
    required this.startDate,
    required this.endDate,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onClearEndDate,
    this.endDateLabel,
    this.endDateLabelIsPlaceholder = false,
  });

  final DateTime startDate;
  final DateTime? endDate;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final VoidCallback onClearEndDate;
  final String? endDateLabel;
  final bool endDateLabelIsPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InputTile(
            label: _formatDisplayDateLabel(startDate),
            icon: Icons.calendar_today,
            onTap: onPickStartDate,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Icon(Icons.horizontal_rule_rounded, size: 14.0),
        ),
        Expanded(
          child: _InputTile(
            label: endDate == null
                ? (endDateLabel ?? '마감 날짜'.tr())
                : _formatDisplayDateLabel(endDate!),
            icon: Icons.calendar_today,
            onTap: onPickEndDate,
            isPlaceholder: endDateLabelIsPlaceholder && endDate == null,
            trailing: endDate == null
                ? null
                : const Icon(Icons.clear, size: 18.0),
            onTrailingTap: onClearEndDate,
          ),
        ),
      ],
    );
  }
}

class _TimeRangeRow extends StatelessWidget {
  const _TimeRangeRow({
    required this.startTime,
    required this.endTime,
    required this.onPickStartTime,
    required this.onPickEndTime,
    this.onClearStartTime,
    this.onClearEndTime,
    this.startLabel,
    this.endLabel,
    this.startLabelIsPlaceholder = false,
    this.endLabelIsPlaceholder = false,
  });

  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final VoidCallback onPickStartTime;
  final VoidCallback onPickEndTime;
  final VoidCallback? onClearStartTime;
  final VoidCallback? onClearEndTime;
  final String? startLabel;
  final String? endLabel;
  final bool startLabelIsPlaceholder;
  final bool endLabelIsPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InputTile(
            label: startTime == null
                ? (startLabel ?? '시작 시간'.tr())
                : startTime!.format(context),
            icon: Icons.schedule,
            onTap: onPickStartTime,
            isPlaceholder: startLabelIsPlaceholder && startTime == null,
            trailing: (startTime == null || onClearStartTime == null)
                ? null
                : const Icon(Icons.clear, size: 18.0),
            onTrailingTap: onClearStartTime,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Icon(Icons.horizontal_rule_rounded, size: 14.0),
        ),
        Expanded(
          child: _InputTile(
            label: endTime == null
                ? (endLabel ?? '마감 시간'.tr())
                : endTime!.format(context),
            icon: Icons.schedule,
            onTap: onPickEndTime,
            isPlaceholder: endLabelIsPlaceholder && endTime == null,
            trailing: (endTime == null || onClearEndTime == null)
                ? null
                : const Icon(Icons.clear, size: 18.0),
            onTrailingTap: onClearEndTime,
          ),
        ),
      ],
    );
  }
}

class _InputTile extends StatelessWidget {
  const _InputTile({
    required this.label,
    this.icon,
    required this.onTap,
    this.trailing,
    this.onTrailingTap,
    this.isPlaceholder = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final Widget? trailing;
  final VoidCallback? onTrailingTap;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _TodoPalette.inputFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _TodoPalette.border, width: 0.6),
      ),
      child: Tap(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Row(
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(
                  left: 12.0,
                  top: 14.0,
                  bottom: 14.0,
                ),
                child: Icon(icon, color: _TodoPalette.muted, size: 18),
              ),
            SizedBox(
              width: icon != null ? 7 : 12,
              height: icon != null ? 0 : 45,
            ),

            // ✅ label: Expanded -> Flexible (텍스트는 필요만큼만, 넘치면 말줄임)
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isPlaceholder
                      ? _TodoPalette.muted
                      : _TodoPalette.title,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.0,
                ),
              ),
            ),

            // ✅ trailing: 남은 공간 전부 차지 + 오른쪽 정렬 + 영역 전체 탭 가능
            if (trailing != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque, // ✅ 빈 공간도 탭 잡기
                onTap: onTrailingTap,
                child: SizedBox(
                  height: 40,
                  width: 30,
                  child: Align(alignment: Alignment.center, child: trailing!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlarmOffset {
  const _AlarmOffset(this.hours, this.minutes);

  final int hours;
  final int minutes;
}

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({
    required this.dateLabel,
    required this.timeLabel,
    required this.onPickDate,
    required this.onPickTime,
    this.onClearDate,
    this.onClearTime,
    this.showClearDate = false,
    this.showClearTime = false,
    this.dateLabelIsPlaceholder = false,
    this.timeLabelIsPlaceholder = false,
  });

  final String dateLabel;
  final String timeLabel;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback? onClearDate;
  final VoidCallback? onClearTime;
  final bool showClearDate;
  final bool showClearTime;
  final bool dateLabelIsPlaceholder;
  final bool timeLabelIsPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InputTile(
            label: dateLabel,
            icon: Icons.calendar_today,
            onTap: onPickDate,
            isPlaceholder: dateLabelIsPlaceholder,
            trailing: showClearDate && onClearDate != null
                ? const Icon(Icons.clear, size: 18.0)
                : null,
            onTrailingTap: onClearDate,
          ),
        ),
        AppGap.w10,
        Expanded(
          child: _InputTile(
            label: timeLabel,
            icon: Icons.schedule,
            onTap: onPickTime,
            isPlaceholder: timeLabelIsPlaceholder,
            trailing: showClearTime && onClearTime != null
                ? const Icon(Icons.clear, size: 18.0)
                : null,
            onTrailingTap: onClearTime,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.header});

  final Widget child;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final headerWidgets = header == null
        ? const <Widget>[]
        : <Widget>[header!, AppGap.h12];
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [...headerWidgets, child],
      ),
    );
  }
}

class _ProjectNameTile extends StatelessWidget {
  const _ProjectNameTile({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: _TodoPalette.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _TodoPalette.border, width: 0.6),
      ),
      padding: AppInsets.h14v14,
      child: Row(
        children: [
          // const Icon(Icons.folder_rounded,
          //     color: _TodoPalette.muted, size: 18),
          // AppGap.w8,
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _TodoPalette.title,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailingWidgets = trailing == null
        ? const <Widget>[]
        : <Widget>[trailing!];
    return Row(
      children: [
        Icon(icon, color: _TodoPalette.primary, size: 18),
        AppGap.w10,
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: _TodoPalette.title,
              fontSize: 16,
            ),
          ),
        ),
        ...trailingWidgets,
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: _TodoPalette.muted,
        fontSize: 13,
      ),
    );
  }
}

InputDecoration _inputDecoration({
  String? labelText,
  required String hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    filled: true,
    fillColor: _TodoPalette.inputFill,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    contentPadding: AppInsets.h18v14,
    hintStyle: const TextStyle(color: _TodoPalette.hint, fontSize: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _TodoPalette.border, width: 0.6),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _TodoPalette.primary, width: 1),
    ),
  );
}

class _TodoPalette {
  const _TodoPalette._();

  static const background = AppTokens.surface;
  static const border = AppTokens.divider;
  static const primary = AppTokens.primary;
  static const secondary = AppTokens.primarySoft;
  static const hint = AppTokens.textMuted;
  static const muted = AppTokens.textSecondary;
  static const inputFill = AppTokens.surface;
  static const title = AppTokens.textPrimary;
}
