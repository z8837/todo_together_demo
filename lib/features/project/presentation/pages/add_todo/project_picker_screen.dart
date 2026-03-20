import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todotogether/core/localization/tr_extension.dart';
import 'package:todotogether/core/ui/app_system_ui.dart';
import 'package:todotogether/core/ui/app_tokens.dart';
import 'package:todotogether/core/widgets/w_tap.dart';
import 'package:todotogether/features/project/domain/entities/project_summary.dart';
import 'package:todotogether/features/project/presentation/viewmodels/add_todo/add_project_todo_view_model.dart';
import 'package:todotogether/features/project/presentation/state/project_feature_providers.dart';
import 'package:todotogether/core/ui/app_spacing.dart';

class ProjectPickerResult {
  const ProjectPickerResult.select(this.project) : shouldCreateProject = false;

  const ProjectPickerResult.create()
    : project = null,
      shouldCreateProject = true;

  final ProjectSummary? project;
  final bool shouldCreateProject;
}

class ProjectPickerArgs {
  const ProjectPickerArgs({required this.projects, this.selectedProject});

  final List<ProjectSummary> projects;
  final ProjectSummary? selectedProject;
}

class ProjectPickerScreen extends ConsumerStatefulWidget {
  const ProjectPickerScreen({
    super.key,
    required this.projects,
    this.selectedProject,
  });

  final List<ProjectSummary> projects;
  final ProjectSummary? selectedProject;

  @override
  ConsumerState<ProjectPickerScreen> createState() =>
      _ProjectPickerScreenState();
}

class _ProjectPickerScreenState extends ConsumerState<ProjectPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final ProjectPickerScreenViewModel _viewModel;

  @override
  void dispose() {
    _searchController.removeListener(_handleQueryChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _viewModel = ProjectPickerScreenViewModel(projects: widget.projects);
    _searchController.addListener(_handleQueryChanged);
  }

  @override
  void didUpdateWidget(ProjectPickerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projects != widget.projects) {
      _viewModel.updateProjects(widget.projects);
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _handleQueryChanged() {
    final changed = _viewModel.updateQuery(_searchController.text);
    if (changed && mounted) {
      setState(() {});
    }
  }

  void _toggleFavoriteFilter() {
    _viewModel.toggleFavoriteFilter();
    setState(() {});
  }

  void _toggleFavorite(String projectId) {
    ref.read(favoriteProjectIdsProvider.notifier).toggle(projectId);
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProjectIds = ref.watch(favoriteProjectIdsProvider);
    final filtered = _viewModel.filterProjects(favoriteProjectIds);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppSystemUi.mainOverlayStyle,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: _PickerPalette.background,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            systemOverlayStyle: AppSystemUi.mainOverlayStyle,
            surfaceTintColor: Colors.transparent,
            backgroundColor: _PickerPalette.background,
            foregroundColor: _PickerPalette.title,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Text(
              '프로젝트 선택'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: _PickerPalette.title,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AutoSizeText(
                              '일정을 추가할 프로젝트를 골라주세요.'.tr(),
                              maxLines: 1,
                              minFontSize: 10,
                              maxFontSize: 14,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: _PickerPalette.subtitle,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                          AppGap.w8,
                          _PickerFavoriteFilterButton(
                            isSelected: _viewModel.showFavoritesOnly,
                            count: _viewModel.favoriteCount(
                              widget.projects,
                              favoriteProjectIds,
                            ),
                            onTap: _toggleFavoriteFilter,
                          ),
                        ],
                      ),
                      AppGap.h14,
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: '프로젝트 검색'.tr(),
                          filled: true,
                          fillColor: _PickerPalette.inputFill,
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
                            Navigator.of(
                              context,
                            ).pop(const ProjectPickerResult.create());
                          },
                          icon: const Icon(Icons.add),
                          label: Text('새 프로젝트 만들기'.tr()),
                          style: OutlinedButton.styleFrom(
                            padding: AppInsets.v12,
                            foregroundColor: _PickerPalette.primary,
                            side: BorderSide(
                              color: _PickerPalette.primary.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppGap.h8,
                Expanded(
                  child: filtered.isEmpty
                      ? _ProjectPickerEmptyState(
                          hasQuery: _viewModel.query.isNotEmpty,
                        )
                      : ListView.separated(
                          padding: AppInsets.screenTop8,
                          itemBuilder: (context, index) {
                            final project = filtered[index];
                            return _ProjectPickerTile(
                              project: project,
                              isSelected:
                                  widget.selectedProject?.id == project.id,
                              isFavorite: favoriteProjectIds.contains(
                                project.id,
                              ),
                              onToggleFavorite: () =>
                                  _toggleFavorite(project.id),
                              onTap: () => Navigator.of(
                                context,
                              ).pop(ProjectPickerResult.select(project)),
                            );
                          },
                          separatorBuilder: (_, index) => AppGap.h10,
                          itemCount: filtered.length,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerFavoriteFilterButton extends StatelessWidget {
  const _PickerFavoriteFilterButton({
    required this.isSelected,
    required this.count,
    required this.onTap,
  });

  final bool isSelected;
  final int count;
  final VoidCallback onTap;

  static const _favoriteAccent = AppTokens.favoriteAccent;
  static const _favoriteBackground = AppTokens.favoriteBackground;
  static const _favoriteBorder = AppTokens.favoriteBorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isSelected ? _favoriteBackground : Colors.white;
    final border = isSelected ? _favoriteBorder : _PickerPalette.divider;
    final icon = isSelected ? Icons.star_rounded : Icons.star_border_rounded;
    final iconColor = isSelected ? _favoriteAccent : _PickerPalette.subtitle;
    final textColor = isSelected ? _favoriteAccent : _PickerPalette.subtitle;
    final label = count > 0
        ? '즐겨찾기 {count}'.tr(namedArgs: {'count': count.toString()})
        : '즐겨찾기'.tr();

    return SizedBox(
      height: 34,
      child: Tap(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                maxFontSize: 14.0,
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

class _ProjectPickerFavoriteIconButton extends StatelessWidget {
  const _ProjectPickerFavoriteIconButton({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = isSelected ? Icons.star_rounded : Icons.star_border_rounded;
    final iconColor = isSelected
        ? _PickerPalette.favoriteAccent
        : _PickerPalette.subtitle;
    final background = isSelected
        ? _PickerPalette.favoriteBackground
        : Colors.white;
    final border = isSelected
        ? _PickerPalette.favoriteBorder
        : _PickerPalette.divider;

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

class _ProjectPickerTile extends StatelessWidget {
  const _ProjectPickerTile({
    required this.project,
    required this.isSelected,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onTap,
  });

  final ProjectSummary project;
  final bool isSelected;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final description = project.description.trim().isEmpty
        ? '설명이 없습니다.'.tr()
        : project.description.trim();
    final ownerLabel = project.owner.nickname.trim().isEmpty
        ? project.owner.email
        : project.owner.nickname;
    final members = <ProjectUser>[project.owner, ...project.members];
    final memberCount = members.length;
    final createdLabel = _formatProjectDate(project.createdAt);
    return Tap(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: isSelected
              ? _PickerPalette.primary.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? _PickerPalette.primary : _PickerPalette.divider,
            width: 0.6,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _PickerPalette.title,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                AppGap.w8,
                _ProjectPickerFavoriteIconButton(
                  isSelected: isFavorite,
                  onTap: onToggleFavorite,
                ),
              ],
            ),
            AppGap.h6,
            Text(
              description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _PickerPalette.subtitle,
                height: 1.4,
              ),
            ),
            AppGap.h4,
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AutoSizeText(
                    createdLabel,
                    minFontSize: 6.0,
                    maxFontSize: 12.0,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _PickerPalette.subtitle,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AppGap.w10,
                Container(width: 1, height: 10, color: _PickerPalette.divider),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _PickerPalette.subtitle,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AppGap.w10,
                Container(width: 1, height: 10, color: _PickerPalette.divider),
                AppGap.w10,
                Expanded(
                  flex: 2,
                  child: AutoSizeText(
                    ownerLabel,
                    minFontSize: 6.0,
                    maxFontSize: 12.0,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _PickerPalette.primary,
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
                      child: _ProjectPickerParticipantAvatars(
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
    );
  }
}

class _ProjectPickerParticipantAvatars extends StatelessWidget {
  const _ProjectPickerParticipantAvatars({
    required this.users,
    required this.owner,
  });

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
              child: _ProjectPickerAvatarCircle(user: shown[i], owner: owner),
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
                    color: _PickerPalette.title,
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

class _ProjectPickerAvatarCircle extends StatelessWidget {
  const _ProjectPickerAvatarCircle({required this.user, required this.owner});

  final ProjectUser user;
  final ProjectUser owner;

  @override
  Widget build(BuildContext context) {
    final label = user.nickname.trim().isEmpty ? user.email : user.nickname;
    final initial = label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();
    final background = owner.id == user.id
        ? _PickerPalette.primaryAvatar
        : _PickerPalette.divider;

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
          color: owner.id == user.id ? Colors.white : _PickerPalette.title,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _formatProjectDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}.$month.$day';
}

class _ProjectPickerEmptyState extends StatelessWidget {
  const _ProjectPickerEmptyState({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final title = hasQuery ? '일치하는 프로젝트가 없어요.'.tr() : '아직 프로젝트가 없어요.'.tr();
    final subtitle = hasQuery
        ? '다른 키워드로 검색하거나 새 프로젝트를 만들어보세요.'.tr()
        : '먼저 프로젝트를 만들고 일정을 추가해보세요.'.tr();
    return Center(
      child: Padding(
        padding: AppInsets.h24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 48,
              color: _PickerPalette.subtitle,
            ),
            AppGap.h12,
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _PickerPalette.title,
              ),
            ),
            AppGap.h6,
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _PickerPalette.subtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerPalette {
  const _PickerPalette._();

  static const background = AppTokens.surface;
  static const title = AppTokens.textPrimary;
  static const subtitle = AppTokens.textSecondary;
  static const divider = AppTokens.divider;
  static const inputFill = AppTokens.surfaceInput;
  static const primary = AppTokens.primary;
  static const primaryAvatar = AppTokens.primaryAvatar;
  static const favoriteAccent = AppTokens.favoriteAccent;
  static const favoriteBackground = AppTokens.favoriteBackground;
  static const favoriteBorder = AppTokens.favoriteBorder;
}
