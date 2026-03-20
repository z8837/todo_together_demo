part of 'schedule_fragment.dart';

class ScheduleAddTodoFlow {
  const ScheduleAddTodoFlow._();

  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required List<ProjectSummary> projects,
    required DateTime selectedDay,
  }) async {
    final action = await _showProjectPickerSheet(context, projects);
    if (action == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    ProjectSummary? targetProject;
    if (action.shouldCreateProject) {
      targetProject = await _openCreateProjectPage(context);
      if (!context.mounted) {
        return;
      }
    } else {
      targetProject = action.project;
    }
    if (targetProject == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    await _openProjectTodoSheet(
      context: context,
      ref: ref,
      project: targetProject,
      selectedDay: DateUtils.dateOnly(selectedDay),
    );
  }

  static Future<_ProjectPickerAction?> _showProjectPickerSheet(
    BuildContext context,
    List<ProjectSummary> projects,
  ) {
    final sheetContext = rootNavigatorKey.currentContext ?? context;
    return showModalBottomSheet<_ProjectPickerAction>(
      context: sheetContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (modalContext) {
        final navigator = Navigator.of(modalContext);
        return _ProjectPickerSheet(
          projects: projects,
          onProjectTap: (project) {
            navigator.pop(_ProjectPickerAction.select(project));
          },
          onCreateProject: () {
            navigator.pop(const _ProjectPickerAction.create());
          },
        );
      },
    );
  }

  static Future<ProjectSummary?> _openCreateProjectPage(
    BuildContext context,
  ) async {
    final result = await context.push<CreateProjectResult>(
      AppRoutePaths.projectEditor,
      extra: const CreateProjectArgs(),
    );
    if (result == null || result.isDeleted) {
      return null;
    }
    return result.project;
  }

  static Future<void> _openProjectTodoSheet({
    required BuildContext context,
    required WidgetRef ref,
    required ProjectSummary project,
    required DateTime selectedDay,
  }) async {
    final created = await context.push<bool>(
      AppRoutePaths.projectTodoEditor,
      extra: AddProjectTodoArgs(
        project: project,
        initialSelectedDate: selectedDay,
      ),
    );
    if (created == true) {
      if (context.mounted) {
        //         ScaffoldMessenger.of(context).showSnackBar(
        //           SnackBar(content: Text('"${project.name}"에 TODO를 추가했어요.')),
        //         );
      }
    }
  }
}

class _ProjectPickerAction {
  const _ProjectPickerAction.select(this.project) : shouldCreateProject = false;

  const _ProjectPickerAction.create()
    : project = null,
      shouldCreateProject = true;

  final ProjectSummary? project;
  final bool shouldCreateProject;
}

class _ProjectPickerSheet extends StatefulWidget {
  const _ProjectPickerSheet({
    required this.projects,
    required this.onProjectTap,
    required this.onCreateProject,
  });

  final List<ProjectSummary> projects;
  final ValueChanged<ProjectSummary> onProjectTap;
  final VoidCallback onCreateProject;

  @override
  State<_ProjectPickerSheet> createState() => _ProjectPickerSheetState();
}

class _ProjectPickerSheetState extends State<_ProjectPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProjects();
    final rootMediaQuery = MediaQuery.of(context);
    final bottomInset = rootMediaQuery.viewInsets.bottom;
    final maxHeight = rootMediaQuery.size.height * 0.9;
    final sheetHeight = maxHeight;
    final listBottomPadding = bottomInset > 0 ? bottomInset + 16 : 16.0;
    final focusScope = FocusScope.of(context);

    return MediaQuery(
      data: rootMediaQuery.copyWith(viewInsets: EdgeInsets.zero),
      child: Padding(
        padding: EdgeInsets.only(bottom: 0.0),
        child: PopScope(
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) {
              FocusScope.of(context).unfocus();
            }
          },
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerMove: (event) {
              if (event.delta.dy > 0 && focusScope.hasFocus) {
                focusScope.unfocus();
              }
            },
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: sheetHeight,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '프로젝트 선택'.tr(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                                AppGap.h4,
                                Text(
                                  'TODO를 추가할 프로젝트를 고르거나 새로 만들어보세요.'.tr(),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: _SchedulePalette.subtitle,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          AppGap.h16,
                          TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _query = value.trim();
                              });
                            },
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: '프로젝트 검색'.tr(),
                              filled: true,
                              fillColor: const Color(0xFFF2F4F8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          AppGap.h12,
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                widget.onCreateProject();
                              },
                              icon: const Icon(Icons.add),
                              label: Text('새 프로젝트 만들기'.tr()),
                              style: OutlinedButton.styleFrom(
                                padding: AppInsets.v12,
                                foregroundColor: _SchedulePalette.primary,
                                side: BorderSide(
                                  color: _SchedulePalette.primary.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          AppGap.h16,
                          Expanded(
                            child: filtered.isEmpty
                                ? _ProjectPickerEmptyState(
                                    hasQuery: _query.isNotEmpty,
                                    onCreateProject: widget.onCreateProject,
                                  )
                                : ListView.separated(
                                    physics: const BouncingScrollPhysics(),
                                    padding: EdgeInsets.only(
                                      bottom: listBottomPadding,
                                    ),
                                    itemBuilder: (context, index) {
                                      final project = filtered[index];
                                      return _ProjectPickerTile(
                                        project: project,
                                        onTap: () {
                                          FocusScope.of(context).unfocus();
                                          widget.onProjectTap(project);
                                        },
                                      );
                                    },
                                    separatorBuilder: (_, _) => AppGap.h12,
                                    itemCount: filtered.length,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<ProjectSummary> _filteredProjects() {
    if (_query.isEmpty) {
      return widget.projects;
    }
    final keyword = _query.toLowerCase();
    return widget.projects
        .where(
          (project) =>
              project.name.toLowerCase().contains(keyword) ||
              project.description.toLowerCase().contains(keyword),
        )
        .toList();
  }
}

class _ProjectPickerTile extends StatelessWidget {
  const _ProjectPickerTile({required this.project, required this.onTap});

  final ProjectSummary project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = ProjectColorResolver.resolve(project.id);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: Tap(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: accent.withValues(alpha: 0.18),
                foregroundColor: accent,
                child: Text(
                  _projectInitial(project.name),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: _SchedulePalette.title,
                      ),
                    ),
                    if (project.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          project.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: _SchedulePalette.subtitle),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _SchedulePalette.subtitle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectPickerEmptyState extends StatelessWidget {
  const _ProjectPickerEmptyState({
    required this.hasQuery,
    required this.onCreateProject,
  });

  final bool hasQuery;
  final VoidCallback onCreateProject;

  @override
  Widget build(BuildContext context) {
    final title = hasQuery ? '일치하는 프로젝트가 없어요.'.tr() : '아직 프로젝트가 없어요.'.tr();
    final subtitle = hasQuery
        ? '다른 키워드로 검색하거나 새 프로젝트를 만들어보세요.'.tr()
        : '먼저 프로젝트를 만들고 TODO를 추가해보세요.'.tr();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppGap.h10,
        const Icon(
          Icons.inbox_outlined,
          size: 48,
          color: _SchedulePalette.subtitle,
        ),
        AppGap.h12,
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: _SchedulePalette.title,
          ),
        ),
        AppGap.h4,
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: _SchedulePalette.subtitle),
        ),
      ],
    );
  }
}

String _projectInitial(String rawName) {
  final trimmed = rawName.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  final rune = trimmed.runes.first;
  return String.fromCharCode(rune).toUpperCase();
}
