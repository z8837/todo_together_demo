import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart' hide RefreshIndicator;
import 'package:skeletonizer/skeletonizer.dart';
import 'package:todotogether/app/router.dart';
import 'package:todotogether/core/ads/native_ad_cache.dart';
import 'package:todotogether/core/localization/tr_extension.dart';
import 'package:todotogether/core/network/result/api_error.dart';
import 'package:todotogether/core/ui/app_tokens.dart';
import 'package:todotogether/core/widgets/app_async_view.dart';
import 'package:todotogether/core/widgets/bear_native_ad.dart';
import 'package:todotogether/core/widgets/w_tap.dart';
import 'package:todotogether/features/project/domain/entities/project_summary.dart';
import 'package:todotogether/features/project/domain/entities/project_todo.dart';
import 'package:todotogether/features/project/presentation/pages/create_project_page.dart';
import 'package:todotogether/features/project/presentation/viewmodels/project_list_fragment_view_model.dart';
import 'package:todotogether/features/project/presentation/state/project_feature_providers.dart';
import 'package:todotogether/app/state/sync_coordinator.dart';
import 'package:todotogether/core/ui/app_spacing.dart';

enum _ProjectListViewMode { detail, simple }

// 목록 카드 표현 방식을 "간단/상세"로 전환할 때 쓰는 변환 유틸입니다.
extension _ProjectListViewModeX on _ProjectListViewMode {
  String get storageValue =>
      this == _ProjectListViewMode.simple ? 'simple' : 'detail';

  String get label =>
      this == _ProjectListViewMode.simple ? '간단 보기'.tr() : '상세 보기'.tr();

  IconData get icon => this == _ProjectListViewMode.simple
      ? Icons.view_list_rounded
      : Icons.view_agenda_rounded;

  static _ProjectListViewMode fromStorage(String? raw) {
    if (raw == 'simple') {
      return _ProjectListViewMode.simple;
    }
    return _ProjectListViewMode.detail;
  }
}

/// [중요] 프로젝트 탭의 메인 목록 화면입니다.
/// 탭 진입 시 목록을 보여주고, 태블릿에서는 상세 패널과 분할 화면으로 동작합니다.
class ProjectListFragment extends ConsumerStatefulWidget {
  const ProjectListFragment({super.key, this.focusProjectId, this.focusTodoId});

  final String? focusProjectId;
  final String? focusTodoId;

  @override
  ConsumerState<ProjectListFragment> createState() =>
      _ProjectListFragmentState();
}

class _ProjectListFragmentState extends ConsumerState<ProjectListFragment> {
  late final RefreshController _refreshController;
  late final ScrollController _scrollController;
  RouteInformationProvider? _routeInfoProvider;
  ProviderSubscription<String?>? _projectFocusSubscription;
  final Map<String, GlobalKey> _projectItemKeys = {};
  late final ProjectListFragmentViewModel _viewModel;

  @override
  /// [중요] 화면 초기 상태를 복원하고, 외부에서 넘어온 포커스 프로젝트를 준비합니다.
  void initState() {
    super.initState();
    _refreshController = RefreshController();
    _scrollController = ScrollController();
    _viewModel = ProjectListFragmentViewModel(
      focusProjectId: widget.focusProjectId,
      focusTodoId: widget.focusTodoId,
      focusFromProvider: ref.read(projectFocusProvider),
    );
    _projectFocusSubscription = ref.listenManual<String?>(
      projectFocusProvider,
      (previous, next) {
        if (next == null || next.isEmpty) {
          return;
        }
        _viewModel.applyFocusFromProvider(next);
        if (mounted) {
          setState(() {});
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachRouteListener();
    });
  }

  @override
  // 라우트/구독/스크롤 컨트롤러를 해제해 메모리 누수를 방지합니다.
  void dispose() {
    _routeInfoProvider?.removeListener(_handleRouteChange);
    _projectFocusSubscription?.close();
    _scrollController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  // 부모가 전달한 포커스 대상이 바뀌면 내부 선택 상태를 맞춥니다.
  void didUpdateWidget(ProjectListFragment oldWidget) {
    super.didUpdateWidget(oldWidget);
    _viewModel.applyWidgetUpdate(
      oldFocusProjectId: oldWidget.focusProjectId,
      newFocusProjectId: widget.focusProjectId,
      oldFocusTodoId: oldWidget.focusTodoId,
      newFocusTodoId: widget.focusTodoId,
    );
  }

  /// [중요] 당겨서 새로고침 시 프로젝트와 할 일을 함께 동기화합니다.
  Future<void> _handleRefresh() async {
    final isSuccess = await _viewModel.handleRefresh(
      syncProjects: () async {
        await ref.read(syncCoordinatorProvider).syncProjects();
      },
      syncTodos: () async {
        await ref.read(syncCoordinatorProvider).syncTodos();
      },
      invalidateProjects: () {
        ref.invalidate(projectsProvider);
      },
    );
    if (isSuccess) {
      _refreshController.refreshCompleted();
    } else {
      _refreshController.refreshFailed();
    }
  }

  // 목록 아이템마다 키를 유지해 "해당 카드로 스크롤"이 안정적으로 동작하게 만듭니다.
  Widget _buildProjectListItem(
    ProjectSummary project,
    int index,
    int totalCount,
    bool isFavorite, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final itemKey = _projectItemKeys[project.remoteId];
    final showDivider = index != totalCount - 1;
    final bottomPadding = showDivider ? 0.0 : 24.0;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: KeyedSubtree(
        key: itemKey,
        child: _ProjectCard(
          project: project,
          showDivider: showDivider,
          isFavorite: isFavorite,
          onToggleFavorite: () => _toggleFavorite(project),
          onTap: onTap,
          viewMode: _ProjectListViewModeX.fromStorage(
            _viewModel.viewModeStorage,
          ),
          isSelected: isSelected,
        ),
      ),
    );
  }

  void _syncProjectItemKeys(List<ProjectSummary> projects) {
    _viewModel.syncProjectItemKeys(_projectItemKeys, projects);
  }

  /// [중요] 포커스 ID가 로컬 ID로 들어온 경우 원격 ID로 변환해 실제 목록 매칭을 보장합니다.
  Future<void> _resolveFocusProjectId(List<ProjectSummary> projects) async {
    final changed = await _viewModel.resolveFocusProjectId(
      projects,
      mounted: mounted,
      readRemoteIdByLocalId: ref.read(projectReadRemoteIdByLocalIdProvider),
    );
    if (changed && mounted) {
      setState(() {});
    }
  }

  /// [중요] 특정 프로젝트 카드 위치로 자동 스크롤해 사용자를 바로 목적지로 이동시킵니다.
  void _scrollToFocusedProject(List<ProjectSummary> projects) {
    _viewModel.scrollToFocusedProject(
      projects: projects,
      scrollController: _scrollController,
      projectItemKeys: _projectItemKeys,
      clearExternalFocusState: () {
        final focusNotifier = ref.read(projectFocusProvider.notifier);
        if (focusNotifier.state != null) {
          focusNotifier.state = null;
        }
      },
      mounted: mounted,
    );
  }

  // 카드 표현 모드 변경 후 사용자 선호를 로컬 저장소에 유지합니다.
  void _handleViewModeChange(_ProjectListViewMode mode) {
    final changed = _viewModel.updateViewModeStorage(mode.storageValue);
    if (!changed) {
      return;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleFavorite(ProjectSummary project) {
    _viewModel.toggleFavoriteProject(
      project,
      toggleFavoriteProjectById: (projectId) {
        ref.read(favoriteProjectIdsProvider.notifier).toggle(projectId);
      },
    );
  }

  void _toggleFavoriteFilter() {
    _viewModel.toggleFavoritesOnly();
    if (mounted) {
      setState(() {});
    }
  }

  /// [중요] 프로젝트 탭 진입/이탈 이벤트를 감지해 네이티브 광고 프리패치를 관리합니다.
  void _attachRouteListener() {
    if (!mounted) {
      return;
    }
    final provider = GoRouter.of(context).routeInformationProvider;
    _routeInfoProvider = provider;
    final location = _currentLocation();
    _viewModel.initializeRouteState(location);
    provider.addListener(_handleRouteChange);
  }

  void _handleRouteChange() {
    final location = _currentLocation();
    final transition = _viewModel.handleRouteChange(location);
    if (transition == null) {
      return;
    }
    if (transition.leftProjectTab) {
      ref
          .read(nativeAdCacheProvider)
          .prefetchNext(NativeAdPlacement.projectList);
    }
    if (transition.enteredProjectTab && mounted) {
      ref
          .read(nativeAdCacheProvider)
          .swapInPrefetched(NativeAdPlacement.projectList);
    }
  }

  String _currentLocation() {
    final info = _routeInfoProvider?.value;
    if (info == null) {
      return '';
    }
    return info.uri.path;
  }

  // 태블릿은 오른쪽 상세 패널 선택 상태만 바꾸고, 모바일은 상세 화면으로 이동합니다.
  Future<void> _handleProjectTap(
    BuildContext context,
    ProjectSummary project,
  ) async {
    await context.push<CreateProjectResult>(
      AppRoutePaths.projectEditor,
      extra: CreateProjectArgs(initialProject: project, canDelete: true),
    );

    if (!mounted) {
      return;
    }

    ref.invalidate(projectsProvider);
    ref.invalidate(projectTodosProvider(project.id));
    ref.invalidate(projectChecklistOrderProvider(project.id));
    unawaited(ref.read(syncCoordinatorProvider).trigger(SyncReason.userAction));
  }

  @override
  /// [중요] 목록 정렬/필터/포커스 이동/분할 화면 선택을 한 사이클에서 구성합니다.
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);
    final favoriteProjectIds = ref.watch(favoriteProjectIdsProvider);
    final isSyncing = ref.watch(syncInProgressProvider);
    const appBarTitle = _ProjectsAppBarTitle();

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: _ProjectListPalette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: appBarTitle,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _CreateButton(
              onPressed: () => _handleCreateProject(context, ref),
            ),
          ),
        ],
      ),
      backgroundColor: _ProjectListPalette.background,
      body: AppAsyncView(
        value: projectsAsync,
        dataBuilder: (projects) {
          final displayData = _viewModel.buildDisplayData(
            projects: projects,
            favoriteProjectIds: favoriteProjectIds,
            isSyncing: isSyncing,
          );
          final sortedProjects = displayData.sortedProjects;
          final favoriteProjects = displayData.favoriteProjects;
          final visibleProjects = displayData.visibleProjects;
          final shouldBuildAllProjects = _viewModel.shouldBuildAllProjects;
          if (visibleProjects.isNotEmpty) {
            _syncProjectItemKeys(visibleProjects);
            unawaited(_resolveFocusProjectId(visibleProjects));
            // 빌드 이후 목표 카드로 자동 스크롤을 시도합니다.
            _scrollToFocusedProject(visibleProjects);
          }

          final showEmptySkeleton = displayData.showEmptySkeleton;
          final showFavoriteEmpty = displayData.showFavoriteEmpty;
          final slivers = <Widget>[
            SliverPersistentHeader(
              pinned: true,
              delegate: _ProjectViewModeHeaderDelegate(
                height: 46,
                child: _ProjectListHeader(
                  count: sortedProjects.length,
                  showToggle: sortedProjects.isNotEmpty,
                  mode: _ProjectListViewModeX.fromStorage(
                    _viewModel.viewModeStorage,
                  ),
                  onChanged: _handleViewModeChange,
                  showFavoritesOnly: _viewModel.showFavoritesOnly,
                  favoritesCount: favoriteProjects.length,
                  onToggleFavorites: _toggleFavoriteFilter,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: BearNativeAdCard(
                  key: const ValueKey('project-list-native-ad'),
                  placement: NativeAdPlacement.projectList,
                ),
              ),
            ),
            if (showEmptySkeleton)
              const _ProjectListSkeletonSliver()
            else if (showFavoriteEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 48),
                  child: _FavoriteEmptyState(),
                ),
              )
            else if (sortedProjects.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                  child: CreateProjectCallout(
                    onCreate: () => _handleCreateProject(context, ref),
                    emphasize: true,
                  ),
                ),
              )
            else
              SliverList(
                delegate: shouldBuildAllProjects
                    ? SliverChildListDelegate([
                        for (
                          var index = 0;
                          index < visibleProjects.length;
                          index++
                        )
                          _buildProjectListItem(
                            visibleProjects[index],
                            index,
                            visibleProjects.length,
                            favoriteProjectIds.contains(
                              visibleProjects[index].id,
                            ),
                            isSelected: false,
                            onTap: () => _handleProjectTap(
                              context,
                              visibleProjects[index],
                            ),
                          ),
                      ])
                    : SliverChildBuilderDelegate(
                        (context, index) => _buildProjectListItem(
                          visibleProjects[index],
                          index,
                          visibleProjects.length,
                          favoriteProjectIds.contains(
                            visibleProjects[index].id,
                          ),
                          isSelected: false,
                          onTap: () => _handleProjectTap(
                            context,
                            visibleProjects[index],
                          ),
                        ),
                        childCount: visibleProjects.length,
                      ),
              ),
          ];

          final listContent = SafeArea(
            bottom: false,
            child: RefreshConfiguration(
              dragSpeedRatio: 0.95,
              headerTriggerDistance: 64,
              maxOverScrollExtent: 84,
              springDescription: const SpringDescription(
                mass: 2.2,
                stiffness: 90,
                damping: 20,
              ),
              child: SmartRefresher(
                controller: _refreshController,
                enablePullDown: true,
                header: const MaterialClassicHeader(
                  height: 60,
                  distance: 36,
                  color: _ProjectListPalette.primaryAccent,
                  backgroundColor: _ProjectListPalette.background,
                ),
                onRefresh: _handleRefresh,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: slivers,
                ),
              ),
            ),
          );

          return listContent;
        },
        loading: () => const _ProjectListSkeletonScreen(),
        errorBuilder: (error, stackTrace) => _ProjectErrorState(
          message: _resolveErrorMessage(error),
          onRetry: () => _viewModel.triggerUserSync(
            () => ref
                .read(syncCoordinatorProvider)
                .trigger(SyncReason.userAction),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCreateProject(BuildContext context, WidgetRef ref) async {
    final result = await context.push<CreateProjectResult>(
      AppRoutePaths.projectEditor,
      extra: const CreateProjectArgs(),
    );

    if (result == null || !context.mounted) {
      return;
    }

    final createdProject = result.project;
    final message = StringBuffer(
      '"{projectName}" 프로젝트를 만들었어요.'.tr(
        namedArgs: {'projectName': createdProject.name},
      ),
    );
    if (result.invitedCount > 0) {
      message.write(
        ' {count}명에게 초대장을 보냈어요.'.tr(
          namedArgs: {'count': result.invitedCount.toString()},
        ),
      );
    }
  }

  String _resolveErrorMessage(Object error) {
    if (error is ApiError) {
      return error.message;
    }

    return '프로젝트 목록을 불러오지 못했어요.'.tr();
  }
}

class _ProjectListSkeletonScreen extends StatelessWidget {
  const _ProjectListSkeletonScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Skeletonizer(
        enabled: true,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: const [_ProjectListSkeletonSliver()],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ProjectDetailPlaceholder extends StatelessWidget {
  const _ProjectDetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: _ProjectListPalette.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 52,
              color: _ProjectListPalette.subtitle,
            ),
            AppGap.h10,
            Text(
              '프로젝트를 선택해주세요'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _ProjectListPalette.subtitle,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectListSkeletonSliver extends StatelessWidget {
  const _ProjectListSkeletonSliver();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: _SkeletonProjectCard(),
          ),
          childCount: 6,
        ),
      ),
    );
  }
}

class _SkeletonProjectCard extends StatelessWidget {
  const _SkeletonProjectCard();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const fallbackMaxWidth = 280.0;
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : fallbackMaxWidth;
        final rightColumnMaxWidth = maxWidth * 0.45;

        double resolveWidth(double width) {
          if (width.isInfinite) {
            return maxWidth;
          }
          return width > maxWidth ? maxWidth : width;
        }

        Widget bar(double width, double height) {
          return Container(
            width: resolveWidth(width),
            height: height,
            decoration: BoxDecoration(
              color: _ProjectListPalette.toggleBackground,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }

        Widget circle(double size) {
          return Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: _ProjectListPalette.toggleBackground,
              shape: BoxShape.circle,
            ),
          );
        }

        return Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _ProjectListPalette.divider,
                width: 0.6,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 18, 0, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(160, 22),
                AppGap.h10,
                bar(double.infinity, 14),
                AppGap.h6,
                bar(220, 14),
                AppGap.h12,
                Row(
                  children: [
                    circle(14),
                    AppGap.w6,
                    bar(90, 12),
                    AppGap.w12,
                    circle(14),
                    AppGap.w6,
                    Expanded(child: bar(double.infinity, 12)),
                  ],
                ),
                AppGap.h14,
                const Divider(height: 1, color: _ProjectListPalette.divider),
                AppGap.h14,
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bar(100, 12),
                          AppGap.h8,
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [bar(48, 12), bar(48, 12), bar(48, 12)],
                          ),
                        ],
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: rightColumnMaxWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: bar(80, 12),
                          ),
                          AppGap.h8,
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            runSpacing: 8,
                            children: [circle(28), circle(28), circle(28)],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  const _ProjectCard({
    required this.project,
    required this.onTap,
    required this.showDivider,
    required this.viewMode,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.isSelected,
  });

  final ProjectSummary project;
  final VoidCallback onTap;
  final bool showDivider;
  final _ProjectListViewMode viewMode;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = <ProjectUser>[project.owner, ...project.members];
    final memberCount = members.length;
    final description = project.description.trim().isEmpty
        ? '설명이 없습니다.'.tr()
        : project.description.trim();
    final ownerLabel = project.owner.nickname.trim().isEmpty
        ? project.owner.email
        : project.owner.nickname;
    final todosAsync = ref.watch(projectTodosProvider(project.id));
    final checklistOrderAsync = ref.watch(
      projectChecklistOrderProvider(project.id),
    );
    final checklistOrderIds = checklistOrderAsync.maybeWhen(
      data: (order) => order?.orderedChecklistIds,
      orElse: () => null,
    );
    final createdLabel = _formatProjectDate(project.createdAt);

    final isSimple = viewMode == _ProjectListViewMode.simple;
    final verticalPadding = isSimple ? 12.0 : 22.0;
    final cardRadius = BorderRadius.circular(16);
    return Column(
      children: [
        Tap(
          onTap: onTap,
          borderRadius: cardRadius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isSelected
                  ? _ProjectListPalette.selectedBackground
                  : Colors.transparent,
              borderRadius: cardRadius,
              border: Border.all(
                color: isSelected
                    ? _ProjectListPalette.selectedBorder
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                verticalPadding,
                20,
                verticalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: _ProjectListPalette.title,
                                fontSize: 18.0,
                              ),
                        ),
                      ),
                      AppGap.w8,
                      _FavoriteIconButton(
                        isSelected: isFavorite,
                        onTap: onToggleFavorite,
                      ),
                    ],
                  ),
                  AppGap.h6,
                  Text(
                    description,
                    maxLines: isSimple ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _ProjectListPalette.subtitle,
                      height: 1.4,
                    ),
                  ),
                  if (!isSimple) AppGap.h12,
                  if (!isSimple)
                    _TodoSummaryCard(
                      todosAsync: todosAsync,
                      memberCount: memberCount,
                      users: members,
                      owner: project.owner,
                      checklistOrderIds: checklistOrderIds,
                    ),
                  SizedBox(height: isSimple ? 4 : 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: AutoSizeText(
                          createdLabel,
                          minFontSize: 6.0,
                          maxFontSize: 12.0,
                          maxLines: 1,

                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: _ProjectListPalette.subtitle,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      AppGap.w10,
                      Container(
                        width: 1,
                        height: 10,
                        color: _ProjectListPalette.divider,
                      ),
                      AppGap.w10,
                      Expanded(
                        flex: 2,
                        child: AutoSizeText(
                          '참여 {count}'.tr(
                            namedArgs: {'count': memberCount.toString()},
                          ),
                          textAlign: TextAlign.center,
                          minFontSize: 6.0,
                          maxFontSize: 12.0,
                          maxLines: 1,

                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: _ProjectListPalette.subtitle,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      AppGap.w10,
                      Container(
                        width: 1,
                        height: 10,
                        color: _ProjectListPalette.divider,
                      ),
                      AppGap.w10,
                      Expanded(
                        flex: 2,
                        child: AutoSizeText(
                          ownerLabel,
                          minFontSize: 6.0,
                          maxFontSize: 12.0,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: _ProjectListPalette.primaryAccent,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      if (members.isNotEmpty) ...[
                        AppGap.w8,
                        Expanded(
                          flex: 6,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _ParticipantAvatars(
                              users: members,
                              owner: project.owner,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 0.6,
            color: _ProjectListPalette.divider,
          ),
      ],
    );
  }
}

// ignore: unused_element
class _ProjectSimpleCard extends ConsumerWidget {
  const _ProjectSimpleCard({
    required this.project,
    required this.onTap,
    required this.showDivider,
  });

  final ProjectSummary project;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = <ProjectUser>[project.owner, ...project.members];
    final memberCount = members.length;
    final todosAsync = ref.watch(projectTodosProvider(project.id));

    return Column(
      children: [
        Tap(
          onTap: onTap,
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _ProjectListPalette.title,
                    ),
                  ),
                  AppGap.h10,
                  _TodoSummaryCard(
                    todosAsync: todosAsync,
                    memberCount: memberCount,
                    users: members,
                    owner: project.owner,
                    isSimple: true,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 0.6,
            color: _ProjectListPalette.divider,
          ),
      ],
    );
  }
}

String _formatProjectDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}.$month.$day';
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '프로젝트 추가'.tr(),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: Tap(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: _ProjectListPalette.primaryAccent,
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.add,
              size: 20,
              color: _ProjectListPalette.primaryAccent,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectsAppBarTitle extends StatelessWidget {
  const _ProjectsAppBarTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      '내 프로젝트'.tr(),
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: _ProjectListPalette.title,
      ),
    );
  }
}

class _ProjectListHeader extends StatelessWidget {
  const _ProjectListHeader({
    required this.count,
    required this.mode,
    required this.onChanged,
    required this.showToggle,
    required this.showFavoritesOnly,
    required this.favoritesCount,
    required this.onToggleFavorites,
  });

  final int count;
  final _ProjectListViewMode mode;
  final ValueChanged<_ProjectListViewMode> onChanged;
  final bool showToggle;
  final bool showFavoritesOnly;
  final int favoritesCount;
  final VoidCallback onToggleFavorites;

  @override
  Widget build(BuildContext context) {
    final countLabel = '총 {count}개'.tr(namedArgs: {'count': count.toString()});
    return Column(
      children: [
        Expanded(
          child: Container(
            color: _ProjectListPalette.background,
            padding: const EdgeInsets.fromLTRB(20, 0, 10, 8),
            child: Row(
              children: [
                Text(
                  countLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _ProjectListPalette.subtitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _FavoriteFilterButton(
                  isSelected: showFavoritesOnly,
                  count: favoritesCount,
                  onTap: onToggleFavorites,
                ),
                AppGap.w8,
                if (showToggle)
                  _ProjectViewModeToggle(mode: mode, onChanged: onChanged),
              ],
            ),
          ),
        ),
        const Divider(
          height: 1,
          thickness: 0.6,
          color: _ProjectListPalette.divider,
        ),
      ],
    );
  }
}

class _ProjectViewModeHeaderDelegate extends SliverPersistentHeaderDelegate {
  _ProjectViewModeHeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _ProjectViewModeHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _ProjectViewModeToggle extends StatelessWidget {
  const _ProjectViewModeToggle({required this.mode, required this.onChanged});

  final _ProjectListViewMode mode;
  final ValueChanged<_ProjectListViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _ProjectListPalette.toggleBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ProjectListPalette.divider, width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ProjectViewModeOption(
            mode: _ProjectListViewMode.detail,
            isSelected: mode == _ProjectListViewMode.detail,
            onTap: onChanged,
          ),
          AppGap.w4,
          _ProjectViewModeOption(
            mode: _ProjectListViewMode.simple,
            isSelected: mode == _ProjectListViewMode.simple,
            onTap: onChanged,
          ),
        ],
      ),
    );
  }
}

class _FavoriteFilterButton extends StatelessWidget {
  const _FavoriteFilterButton({
    required this.isSelected,
    required this.count,
    required this.onTap,
  });

  final bool isSelected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isSelected
        ? _ProjectListPalette.favoriteBackground
        : Colors.white;
    final border = isSelected
        ? _ProjectListPalette.favoriteBorder
        : _ProjectListPalette.divider;
    final icon = isSelected ? Icons.star_rounded : Icons.star_border_rounded;
    final iconColor = isSelected
        ? _ProjectListPalette.favoriteAccent
        : _ProjectListPalette.subtitle;
    final textColor = isSelected
        ? _ProjectListPalette.favoriteAccent
        : _ProjectListPalette.subtitle;
    final label = count > 0
        ? '즐겨찾기 {count}'.tr(namedArgs: {'count': count.toString()})
        : '즐겨찾기'.tr();

    return SizedBox(
      height: 38,
      child: Tap(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: 0.6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: iconColor),
              AppGap.w4,
              AutoSizeText(
                label,
                maxLines: 1,
                minFontSize: 8.0,
                maxFontSize: 16.0,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteIconButton extends StatelessWidget {
  const _FavoriteIconButton({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = isSelected ? Icons.star_rounded : Icons.star_border_rounded;
    final iconColor = isSelected
        ? _ProjectListPalette.favoriteAccent
        : _ProjectListPalette.subtitle;
    final background = isSelected
        ? _ProjectListPalette.favoriteBackground
        : Colors.white;
    final border = isSelected
        ? _ProjectListPalette.favoriteBorder
        : _ProjectListPalette.divider;

    return Tap(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: background,
          border: Border.all(color: border, width: 0.6),
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }
}

class _ProjectViewModeOption extends StatelessWidget {
  const _ProjectViewModeOption({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  final _ProjectListViewMode mode;
  final bool isSelected;
  final ValueChanged<_ProjectListViewMode> onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = isSelected
        ? _ProjectListPalette.title
        : _ProjectListPalette.inactiveIcon;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: mode.label,
        child: Tap(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onTap(mode),
          child: SizedBox(
            width: 34,
            height: 28,
            child: Icon(mode.icon, size: 18, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class CreateProjectCallout extends StatelessWidget {
  const CreateProjectCallout({
    super.key,
    required this.onCreate,
    this.emphasize = false,
  });

  final VoidCallback onCreate;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = emphasize
        ? _ProjectListPalette.primaryAccent.withAlpha(40)
        : _ProjectListPalette.divider;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 0.6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: AppInsets.all14,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTokens.surfaceIcon,
            ),
            child: const Icon(
              Icons.folder_rounded,
              size: 28,
              color: _ProjectListPalette.title,
            ),
          ),
          AppGap.h16,
          Text(
            '아직 프로젝트가 없어요'.tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: _ProjectListPalette.title,
            ),
          ),
          AppGap.h8,
          Text(
            '지금 새 프로젝트를 만들어 TODO를 함께 관리하세요.'.tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _ProjectListPalette.subtitle,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _ProjectListPalette.primaryAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: Text(
              '프로젝트 만들기'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoSummaryCard extends StatelessWidget {
  const _TodoSummaryCard({
    required this.todosAsync,
    required this.memberCount,
    required this.users,
    required this.owner,
    this.checklistOrderIds,
    this.isSimple = false,
  });

  final bool isSimple;
  final AsyncValue<List<ProjectTodo>> todosAsync;
  final int memberCount;
  final List<ProjectUser> users;
  final ProjectUser owner;
  final List<String>? checklistOrderIds;

  @override
  Widget build(BuildContext context) {
    return AppAsyncView(
      value: todosAsync,
      dataBuilder: (todos) {
        if (isSimple) {
          final status = ProjectTodoSummaryViewModel.buildTodoStatus(todos);
          return _buildSimpleStatusRow(context, status);
        }
        return _buildDetailSummary(context, todos);
      },
      loading: () => _buildInfoRow(context, '불러오는 중'.tr()),
      errorBuilder: (_, _) => _buildInfoRow(context, '불러오지 못했어요'.tr()),
    );
  }

  Widget _buildSimpleStatusRow(BuildContext context, ProjectTodoStatus status) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _StatusLabel(
                  text: '지남'.tr(),
                  value: status.overdue,
                  color: _ProjectListPalette.primaryAccent,
                ),
              ),
              Expanded(
                child: _StatusLabel(
                  text: '진행'.tr(),
                  value: status.inProgress,
                  color: _ProjectListPalette.title,
                ),
              ),
              Expanded(
                child: _StatusLabel(
                  text: '예정'.tr(),
                  value: status.upcoming,
                  color: _ProjectListPalette.primaryAccent,
                ),
              ),
              Expanded(
                child: _StatusLabel(
                  text: '완료'.tr(),
                  value: status.completed,
                  color: _ProjectListPalette.primaryAccent,
                ),
              ),
            ],
          ),
        ),
        AppGap.w12,
        Text(
          '참여 {count}'.tr(namedArgs: {'count': memberCount.toString()}),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _ProjectListPalette.primaryAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSummary(BuildContext context, List<ProjectTodo> todos) {
    final summary = ProjectTodoSummaryViewModel.buildCardSummary(
      todos,
      checklistOrderIds: checklistOrderIds,
    );
    final titleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: _ProjectListPalette.statusTitle,
      fontWeight: FontWeight.w800,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryHeader(
          context,
          title: '일정'.tr(),
          titleStyle: titleStyle,
          overdue: summary.scheduleStatus.overdue,
          inProgress: summary.scheduleStatus.inProgress,
          upcoming: summary.scheduleStatus.upcoming,
          completed: summary.scheduleStatus.completed,
        ),
        AppGap.h12,

        _buildSummaryHeader(
          context,
          title: '체크리스트'.tr(),
          titleStyle: titleStyle,
          overdue: summary.checklistStatus.overdue,
          inProgress: summary.checklistStatus.inProgress,
          upcoming: summary.checklistStatus.upcoming,
          completed: summary.checklistStatus.completed,
        ),
        if (summary.previewTodos.isNotEmpty) ...[
          const SizedBox(height: 18),
          _ChecklistPreviewList(todos: summary.previewTodos),
        ],
      ],
    );
  }

  Widget _buildSummaryHeader(
    BuildContext context, {
    required String title,
    required TextStyle? titleStyle,
    required int overdue,
    required int inProgress,
    required int upcoming,
    required int completed,
  }) {
    return Row(
      children: [
        SizedBox(width: 5.0),
        Expanded(
          flex: 1,
          child: AutoSizeText(
            title,
            maxLines: 1,
            maxFontSize: 12.0,
            minFontSize: 6.0,
            stepGranularity: 0.1,
            style: titleStyle,
          ),
        ),
        SizedBox(width: 10.0),
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Expanded(
                child: _StatusLabel(
                  text: '지남'.tr(),
                  value: overdue,
                  color: _ProjectListPalette.primaryAccent,
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: _StatusLabel(
                  text: '진행'.tr(),
                  value: inProgress,
                  color: _ProjectListPalette.primaryAccent,
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: _StatusLabel(
                  text: '예정'.tr(),
                  value: upcoming,
                  color: _ProjectListPalette.primaryAccent,
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: _StatusLabel(
                  text: '완료'.tr(),
                  value: completed,
                  color: _ProjectListPalette.primaryAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label) {
    final memberStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: _ProjectListPalette.primaryAccent,
      fontWeight: FontWeight.w700,
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _ProjectListPalette.subtitle,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        AppGap.w8,
        if (users.isNotEmpty) _ParticipantAvatars(users: users, owner: owner),
        if (users.isNotEmpty) AppGap.w8,
        Text(
          '참여 {count}'.tr(namedArgs: {'count': memberCount.toString()}),
          style: memberStyle,
        ),
      ],
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({
    required this.text,
    required this.value,
    required this.color,
  });

  final String text;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: _ProjectListPalette.subtitle2,
      fontWeight: FontWeight.w600,
      fontSize: 12,
    );
    final valueStyle = labelStyle?.copyWith(
      color: value > 0 ? color : _ProjectListPalette.subtitle2,
      fontWeight: FontWeight.w700,
    );

    return AutoSizeText.rich(
      TextSpan(
        text: text,
        style: labelStyle,
        children: [TextSpan(text: ' $value', style: valueStyle)],
      ),
      maxLines: 1,
      minFontSize: 5.0,
      stepGranularity: 0.1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ChecklistPreviewList extends StatelessWidget {
  const _ChecklistPreviewList({required this.todos});

  final List<ProjectTodo> todos;

  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Column(
        children: [
          for (var i = 0; i < todos.length; i++)
            _ChecklistPreviewItem(
              todo: todos[i],
              isFirst: i == 0,
              isLast: i == todos.length - 1,
            ),
        ],
      ),
    );
  }
}

class _ChecklistPreviewItem extends StatelessWidget {
  const _ChecklistPreviewItem({
    required this.todo,
    required this.isFirst,
    required this.isLast,
  });

  final ProjectTodo todo;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final status = ProjectTodoSummaryViewModel.resolveChecklistStatus(todo);
    final isCompleted = status == 'done';
    final titleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: isCompleted
          ? _ProjectListPalette.subtitle2
          : _ProjectListPalette.title,
      fontWeight: FontWeight.w600,
      decoration: isCompleted
          ? TextDecoration.lineThrough
          : TextDecoration.none,
    );
    final indicatorColor = isCompleted
        ? _ProjectListPalette.primaryAccent
        : Colors.white;
    final borderColor = isCompleted
        ? _ProjectListPalette.primaryAccent
        : _ProjectListPalette.divider;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 1,
            height: double.infinity,
            color: _ProjectListPalette.divider,
          ),
          AppGap.w16,
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: indicatorColor,
                border: Border.all(color: borderColor, width: 1.2),
              ),
              alignment: Alignment.center,
              child: isCompleted
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : status == 'doing'
                  ? const Icon(
                      Icons.circle,
                      size: 11,
                      color: _ProjectListPalette.primaryAccent,
                    )
                  : null,
            ),
          ),
          AppGap.w12,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Text(
                todo.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantAvatars extends StatelessWidget {
  const _ParticipantAvatars({required this.users, required this.owner});

  final List<ProjectUser> users;
  final ProjectUser owner;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const SizedBox.shrink();
    }

    const visibleCount = 4;
    final shown = users.take(visibleCount).toList(growable: false);
    final remaining = users.length - shown.length;

    return SizedBox(
      height: 28,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < shown.length; i++)
            Align(
              widthFactor: 0.72,
              child: _AvatarCircle(user: shown[i], owner: owner),
            ),
          if (remaining > 0)
            Align(
              widthFactor: 0.72,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTokens.avatarOverflow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$remaining',
                  style: const TextStyle(
                    color: _ProjectListPalette.title,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.user, required this.owner});

  final ProjectUser user;
  final ProjectUser owner;

  @override
  Widget build(BuildContext context) {
    final label = user.nickname.trim().isEmpty ? user.email : user.nickname;
    final initial = label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();
    final background = owner.id == user.id
        ? _ProjectListPalette.primaryAvatar
        : _ProjectListPalette.divider;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: owner.id == user.id ? Colors.white : _ProjectListPalette.title,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ignore: unused_element
class _NextTodoPreview extends StatelessWidget {
  const _NextTodoPreview({
    required this.nextTodo,
    required this.badge,
    required this.title,
    required this.subtitle,
  });

  final ProjectTodo? nextTodo;
  final String badge;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textColor = nextTodo?.isRecurring == true
        ? Color(0xFF2D6BFF)
        : AppTokens.todoSingle;

    return Row(
      children: [
        if (nextTodo != null)
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            child: Icon(
              nextTodo?.isRecurring == true
                  ? Icons.autorenew_rounded
                  : Icons.calendar_month_outlined,
              size: 20,
              color: textColor,
            ),
          ),
        AppGap.w12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (nextTodo != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: nextTodo?.isRecurring == true
                        ? Color(0xFFEAF2FF)
                        : Color(0xFFF3FFF8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              AppGap.h8,
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ProjectListPalette.title,
                  fontWeight: FontWeight.w800,
                ),
              ),
              AppGap.h4,
              if (nextTodo != null)
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: _ProjectListPalette.subtitle,
                    ),
                    AppGap.w6,
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ProjectListPalette.subtitle,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProjectListPalette {
  const _ProjectListPalette._();

  static const background = AppTokens.surface;
  static const title = AppTokens.textPrimary;
  static const statusTitle = Color(0xFF5C76A1);
  static const subtitle = AppTokens.textSecondary;
  static const subtitle2 = AppTokens.textMuted;
  static const divider = AppTokens.divider;
  static const toggleBackground = AppTokens.surfaceSubtle;
  static const inactiveIcon = AppTokens.iconMuted;
  static const primaryAccent = AppTokens.primary;
  static const primaryAvatar = AppTokens.primaryAvatar;
  static const selectedBackground = Color(0xFFF1F5FF);
  static const selectedBorder = Color(0xFFD6E0FF);
  static const favoriteAccent = AppTokens.favoriteAccent;
  static const favoriteBackground = AppTokens.favoriteBackground;
  static const favoriteBorder = AppTokens.favoriteBorder;
}

class _ProjectErrorState extends StatelessWidget {
  const _ProjectErrorState({required this.message, required this.onRetry});

  final String message;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            AppGap.h12,
            Padding(
              padding: AppInsets.h24,
              child: Text(message, textAlign: TextAlign.center),
            ),
            AppGap.h12,
            FilledButton(onPressed: onRetry, child: Text('다시 시도'.tr())),
          ],
        ),
      ),
    );
  }
}

class _FavoriteEmptyState extends StatelessWidget {
  const _FavoriteEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _ProjectListPalette.favoriteBackground,
              shape: BoxShape.circle,
              border: Border.all(
                color: _ProjectListPalette.favoriteBorder,
                width: 0.8,
              ),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: _ProjectListPalette.favoriteAccent,
              size: 28,
            ),
          ),
          AppGap.h12,
          Text(
            '즐겨찾기한 프로젝트가 없어요.'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _ProjectListPalette.subtitle,
              fontWeight: FontWeight.w600,
            ),
          ),
          AppGap.h4,
          Text(
            '별 아이콘을 눌러 추가할 수 있어요.'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _ProjectListPalette.subtitle2,
            ),
          ),
        ],
      ),
    );
  }
}
