import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todotogether/core/localization/tr_extension.dart';

import 'package:todotogether/features/auth/application/state/auth_controller_provider.dart';
import 'package:todotogether/features/project/domain/entities/project_summary.dart';
import 'package:todotogether/features/project/presentation/viewmodels/create_project_page_view_model.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:todotogether/core/ui/app_button_styles.dart';
import 'package:todotogether/core/ui/app_system_ui.dart';
import 'package:todotogether/core/ui/app_spacing.dart';
import 'package:todotogether/core/ui/app_tokens.dart';
import 'package:todotogether/core/widgets/app_card.dart';
import 'package:todotogether/core/widgets/w_provider_avatar.dart';
import 'package:todotogether/core/widgets/dialogs/app_confirm_dialog.dart';
import 'package:todotogether/features/project/presentation/state/project_feature_providers.dart';
part 'create_project_widgets.dart';

class CreateProjectArgs {
  const CreateProjectArgs({this.initialProject, this.canDelete = true});

  final ProjectSummary? initialProject;
  final bool canDelete;
}

class CreateProjectPage extends ConsumerStatefulWidget {
  const CreateProjectPage({
    super.key,
    this.initialProject,
    this.canDelete = true,
  });

  final ProjectSummary? initialProject;
  final bool canDelete;

  @override
  ConsumerState<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends ConsumerState<CreateProjectPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  late final CreateProjectPageViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ref.read(
      createProjectPageViewModelProvider(
        CreateProjectPageViewModelArgs(
          initialProject: widget.initialProject,
          canDelete: widget.canDelete,
        ),
      ),
    );
    _searchController.addListener(_handleSearchChanged);
    final initial = _viewModel.initialProject;
    if (initial != null) {
      _nameController.text = initial.name;
      _descriptionController.text = initial.description;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    _debounce?.cancel();
    final query = _searchController.text.trim();
    setState(() {
      _viewModel.updateSearchQuery(query);
    });

    if (query.isEmpty) {
      setState(() {
        _viewModel.clearSearchState();
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final searchFuture = _viewModel.performSearch(query);
    setState(() {});
    await searchFuture;

    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _toggleCandidate(ProjectUser user) {
    setState(() {
      _viewModel.toggleCandidate(user);
    });
  }

  void _removeCandidate(ProjectUser user) {
    setState(() {
      _viewModel.removeCandidate(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(
      authControllerProvider.select((state) => state.user?.id),
    );
    final permission = _viewModel.resolvePermission(currentUserId);
    final canEditProject = permission.canEditProject;
    final canDeleteProject = permission.canDeleteProject;

    if (!canEditProject) {
      return _buildUnauthorizedScaffold(context);
    }

    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            // 🔥 키보드에 맞춰 body 영역만 줄어들게 (Scaffold가 알아서 처리)
            resizeToAvoidBottomInset: true,
            backgroundColor: _CreateProjectPalette.background,
            appBar: AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: _CreateProjectPalette.background,
              foregroundColor: _CreateProjectPalette.title,
              systemOverlayStyle: AppSystemUi.mainOverlayStyle,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Text(
                _viewModel.isEditing ? '프로젝트 수정'.tr() : '프로젝트 생성'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _CreateProjectPalette.title,
                ),
              ),
              centerTitle: true,
            ),

            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel('프로젝트 이름'.tr()),
                          AppGap.h8,
                          TextField(
                            controller: _nameController,
                            decoration: _inputDecoration(
                              hintText: '예: 1분기 마케팅 캠페인'.tr(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          AppGap.h24,

                          _SectionLabel('설명 (선택)'.tr()),
                          AppGap.h8,
                          TextField(
                            controller: _descriptionController,
                            decoration: _inputDecoration(
                              hintText: '프로젝트 목표를 간단히 설명해주세요.'.tr(),
                            ),
                            minLines: 4,
                            maxLines: 6,
                            textInputAction: TextInputAction.newline,
                          ),

                          // 수정 화면에서는 팀원 목록/초대 기능을 숨깁니다.
                          if (_viewModel.errorMessage != null) ...[
                            AppGap.h12,
                            Text(
                              _viewModel.errorMessage!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],

                          if (!_viewModel.isEditing) ...[
                            const SizedBox(height: 32),
                            _SectionLabel('팀원 초대하기'.tr()),
                            AppGap.h8,
                            TextField(
                              controller: _searchController,
                              decoration: _inputDecoration(
                                hintText: '이메일 또는 닉네임으로 검색'.tr(),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: _CreateProjectPalette.hint,
                                ),
                                suffixIcon: _searchController.text.isEmpty
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        color: _CreateProjectPalette.hint,
                                        onPressed: () =>
                                            _searchController.clear(),
                                      ),
                              ),
                              textInputAction: TextInputAction.search,
                            ),
                            AppGap.h12,

                            if (_viewModel.selectedMembers.isNotEmpty) ...[
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: _viewModel.selectedMembers
                                    .map(
                                      (member) => _SelectedMemberChip(
                                        member: member,
                                        onRemoved: () =>
                                            _removeCandidate(member),
                                      ),
                                    )
                                    .toList(),
                              ),
                              AppGap.h12,
                            ],

                            _buildSearchResults() ?? const SizedBox(),
                          ],
                          AppGap.h24,

                          // 🔥 키보드가 올라왔을 때만, 스크롤 맨 아래에 버튼 표시
                          if (isKeyboardVisible) ...[
                            AppGap.h16,
                            _buildActionButtons(canDeleteProject),
                            AppGap.h16,
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🔥 키보드가 없을 때만, 항상 하단 고정 버튼
            bottomNavigationBar: isKeyboardVisible
                ? null
                : SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: _buildActionButtons(canDeleteProject),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: AppButtonStyles.outlined(
          foreground: _CreateProjectPalette.primary,
          border: _CreateProjectPalette.secondary,
          borderRadius: AppRadii.r18,
        ),
        onPressed: (_viewModel.isSubmitting || _viewModel.isDeleting)
            ? null
            : _handleSubmit,
        child: _viewModel.isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: _CreateProjectPalette.title,
                ),
              )
            : Text(
                _viewModel.isEditing ? '저장하기'.tr() : '생성하고 초대하기'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Widget _buildActionButtons(bool canDeleteProject) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSubmitButton(),
        if (_viewModel.isEditing && canDeleteProject)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildDeleteButton(),
          ),
      ],
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: AppButtonStyles.outlined(
          foreground: Colors.redAccent,
          border: Colors.redAccent,
          borderRadius: AppRadii.r18,
        ),
        onPressed: (_viewModel.isSubmitting || _viewModel.isDeleting)
            ? null
            : _confirmDeleteProject,
        child: _viewModel.isDeleting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.redAccent,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.delete_outline, size: 20),
                  AppGap.w8,
                  Text(
                    '프로젝트 삭제'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }

  Widget? _buildSearchResults() {
    if (_viewModel.searchQuery.isEmpty) {
      return null;
    }

    if (_viewModel.searchError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // _SearchProgressIndicator(visible: _viewModel.isSearching),
          AppGap.h12,
          _InfoCard(_viewModel.searchError!),
        ],
      );
    }

    final filtered = _viewModel.filteredSearchResults;

    final hasResults = filtered.isNotEmpty;
    final list = hasResults
        ? Column(
            children: filtered
                .map(
                  (user) => _CandidateTile(
                    user: user,
                    isSelected: _viewModel.isCandidateSelected(user),
                    onTap: () => _toggleCandidate(user),
                  ),
                )
                .toList(),
          )
        : (_viewModel.isSearching
              ? const SizedBox.shrink()
              : _InfoCard('일치하는 팀원을 찾지 못했어요.'.tr()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // _SearchProgressIndicator(visible: _viewModel.isSearching),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: hasResults || !_viewModel.isSearching
              ? list
              : const SizedBox(height: 0, width: double.infinity),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: AppInsets.h18v14,
      hintStyle: const TextStyle(
        color: _CreateProjectPalette.hint,
        fontSize: 15,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _CreateProjectPalette.border,
          width: 0.6,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _CreateProjectPalette.primary,
          width: 1,
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _viewModel.setErrorMessage('프로젝트 이름을 입력해주세요.'.tr());
      });
      return;
    }

    FocusScope.of(context).unfocus();
    final submitFuture = _viewModel.submit(
      name: name,
      description: description,
    );
    setState(() {});
    final submitResult = await submitFuture;

    if (!mounted) {
      return;
    }
    setState(() {});
    if (submitResult == null) {
      return;
    }

    Navigator.of(context).pop(
      CreateProjectResult(
        project: submitResult.project,
        invitedCount: submitResult.invitedCount,
        failedInvites: submitResult.failedInvites,
      ),
    );
  }

  Future<void> _confirmDeleteProject() async {
    final project = _viewModel.initialProject;
    if (project == null) {
      return;
    }

    final shouldDelete = await showAppConfirmDialog(
      context: context,
      title: '프로젝트 삭제'.tr(),
      message: '"{projectName}" 프로젝트를 삭제할까요? 이 작업은 되돌릴 수 없어요.'.tr(
        namedArgs: {'projectName': project.name},
      ),
      confirmColor: Colors.redAccent,
      confirmLabel: '삭제'.tr(),
      cancelLabel: '취소'.tr(),
    );

    if (shouldDelete == true) {
      final deleteFuture = _viewModel.deleteProject();
      setState(() {});
      final deletedProject = await deleteFuture;
      if (!mounted) {
        return;
      }
      setState(() {});
      if (deletedProject == null) {
        return;
      }

      Navigator.of(context).pop(
        CreateProjectResult(
          project: deletedProject,
          invitedCount: 0,
          failedInvites: const [],
          isDeleted: true,
        ),
      );
    }
  }

  Widget _buildUnauthorizedScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: _CreateProjectPalette.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _CreateProjectPalette.background,
        foregroundColor: _CreateProjectPalette.title,
        systemOverlayStyle: AppSystemUi.mainOverlayStyle,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          '프로젝트 수정'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: _CreateProjectPalette.title,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: AppInsets.h32,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 48,
                color: _CreateProjectPalette.hint,
              ),
              AppGap.h16,
              Text(
                '프로젝트 소유자만 수정할 수 있어요.'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _CreateProjectPalette.title,
                ),
              ),
              AppGap.h8,
              Text(
                '권한이 있는 계정으로 다시 로그인하거나, 소유자에게 수정이나 삭제를 요청해주세요.'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: _CreateProjectPalette.hint),
              ),
              AppGap.h24,
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text('돌아가기'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: _CreateProjectPalette.title,
        fontSize: 15,
      ),
    );
  }
}
