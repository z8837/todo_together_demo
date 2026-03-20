import 'package:flutter/foundation.dart';
import 'package:todotogether/core/network/result/api_error.dart';
import 'package:todotogether/core/network/simple_result.dart';
import 'package:todotogether/features/project/domain/entities/project_summary.dart';
import 'package:todotogether/features/project/domain/usecases/project_use_cases.dart';

typedef CreateProjectAuthorizedExecutor =
    Future<SimpleResult<T, ApiError>> Function<T>(
      Future<SimpleResult<T, ApiError>> Function(String accessToken) action,
    );

class CreateProjectPermission {
  const CreateProjectPermission({
    required this.canEditProject,
    required this.canDeleteProject,
  });

  final bool canEditProject;
  final bool canDeleteProject;
}

class CreateProjectSubmitOutput {
  const CreateProjectSubmitOutput({
    required this.project,
    this.invitedCount = 0,
    this.failedInvites = const [],
  });

  final ProjectSummary project;
  final int invitedCount;
  final List<String> failedInvites;
}

class CreateProjectPageViewModel {
  CreateProjectPageViewModel({
    required ProjectUseCases projectUseCases,
    required CreateProjectAuthorizedExecutor executeAuthorized,
    required VoidCallback invalidateProjects,
    required ProjectSummary? initialProject,
    required bool canDelete,
  }) : _initialProject = initialProject,
       _canDelete = canDelete,
       _projectUseCases = projectUseCases,
       _executeAuthorized = executeAuthorized,
       _invalidateProjects = invalidateProjects {
    _initializeExistingMembers();
  }

  final ProjectSummary? _initialProject;
  final bool _canDelete;
  final ProjectUseCases _projectUseCases;
  final CreateProjectAuthorizedExecutor _executeAuthorized;
  final VoidCallback _invalidateProjects;

  bool _isSubmitting = false;
  bool _isDeleting = false;
  String? _errorMessage;
  final List<ProjectUser> _selectedMembers = [];
  String _searchQuery = '';
  List<ProjectUser> _searchResults = const [];
  bool _isSearching = false;
  String? _searchError;
  final Set<int> _existingMemberIds = <int>{};

  ProjectSummary? get initialProject => _initialProject;
  bool get isEditing => _initialProject != null;
  bool get isSubmitting => _isSubmitting;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;
  List<ProjectUser> get selectedMembers => List.unmodifiable(_selectedMembers);
  List<ProjectUser> get filteredSearchResults {
    return _searchResults
        .where((user) => !_existingMemberIds.contains(user.id))
        .toList(growable: false);
  }

  void _initializeExistingMembers() {
    final initial = _initialProject;
    if (initial == null) {
      return;
    }

    _existingMemberIds.add(initial.owner.id);
    for (final member in initial.members) {
      _existingMemberIds.add(member.id);
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
  }

  void clearSearchState() {
    _searchResults = const [];
    _searchError = null;
    _isSearching = false;
  }

  void setErrorMessage(String? message) {
    _errorMessage = message;
  }

  void toggleCandidate(ProjectUser user) {
    if (_existingMemberIds.contains(user.id)) {
      return;
    }
    final index = _selectedMembers.indexWhere((member) => member.id == user.id);
    if (index >= 0) {
      _selectedMembers.removeAt(index);
      return;
    }
    _selectedMembers.add(user);
  }

  void removeCandidate(ProjectUser user) {
    _selectedMembers.removeWhere((member) => member.id == user.id);
  }

  bool isCandidateSelected(ProjectUser user) {
    return _selectedMembers.any((member) => member.id == user.id);
  }

  CreateProjectPermission resolvePermission(int? currentUserId) {
    if (!isEditing) {
      return const CreateProjectPermission(
        canEditProject: true,
        canDeleteProject: false,
      );
    }

    if (currentUserId == null || _initialProject == null) {
      return const CreateProjectPermission(
        canEditProject: false,
        canDeleteProject: false,
      );
    }

    final isOwner = _initialProject.owner.id == currentUserId;
    final isManager = _initialProject.members.any(
      (member) =>
          member.id == currentUserId &&
          member.role.trim().toLowerCase() == 'manager',
    );

    return CreateProjectPermission(
      canEditProject: isOwner || isManager,
      canDeleteProject: _canDelete && isOwner,
    );
  }

  Future<void> performSearch(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      clearSearchState();
      return;
    }

    _isSearching = true;
    _searchError = null;

    final result = await _executeAuthorized(
      (accessToken) => _projectUseCases.searchUsers(
        accessToken: accessToken,
        query: trimmedQuery,
        limit: 12,
      ),
    );

    if (result.isSuccess) {
      _searchResults = result.successData ?? const [];
      _isSearching = false;
      return;
    }

    _isSearching = false;
    _searchError = result.failureData?.message;
    _searchResults = const [];
  }

  Future<CreateProjectSubmitOutput?> submit({
    required String name,
    required String description,
  }) async {
    if (isEditing) {
      return _updateProject(name: name, description: description);
    }
    return _createProject(name: name, description: description);
  }

  Future<CreateProjectSubmitOutput?> _createProject({
    required String name,
    required String description,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;

    final result = await _executeAuthorized(
      (accessToken) => _projectUseCases.createProject(
        accessToken: accessToken,
        name: name,
        description: description.isEmpty ? '' : description,
      ),
    );

    if (!result.isSuccess) {
      _isSubmitting = false;
      _errorMessage = result.failureData?.message;
      return null;
    }

    final project = result.successData!;
    _invalidateProjects();
    final inviteResult = await _inviteSelectedMembers(project);
    _isSubmitting = false;

    return CreateProjectSubmitOutput(
      project: project,
      invitedCount: inviteResult.successCount,
      failedInvites: inviteResult.failedNames,
    );
  }

  Future<CreateProjectSubmitOutput?> _updateProject({
    required String name,
    required String description,
  }) async {
    final project = _initialProject;
    if (project == null) {
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;

    final result = await _executeAuthorized(
      (accessToken) => _projectUseCases.updateProject(
        accessToken: accessToken,
        projectId: project.id,
        name: name,
        description: description.isEmpty ? '' : description,
      ),
    );

    if (!result.isSuccess) {
      _isSubmitting = false;
      _errorMessage = result.failureData?.message;
      return null;
    }

    final updatedProject = result.successData!;
    _invalidateProjects();
    _isSubmitting = false;

    return CreateProjectSubmitOutput(project: updatedProject);
  }

  Future<ProjectSummary?> deleteProject() async {
    final project = _initialProject;
    if (project == null) {
      return null;
    }

    _isDeleting = true;
    _errorMessage = null;

    final result = await _executeAuthorized(
      (accessToken) => _projectUseCases.deleteProject(
        accessToken: accessToken,
        projectId: project.id,
      ),
    );

    if (!result.isSuccess) {
      _isDeleting = false;
      _errorMessage = result.failureData?.message;
      return null;
    }

    _invalidateProjects();
    _isDeleting = false;
    return project;
  }

  Future<_InviteResult> _inviteSelectedMembers(ProjectSummary project) async {
    if (_selectedMembers.isEmpty) {
      return const _InviteResult();
    }

    var successCount = 0;
    final failedNames = <String>[];

    for (final user in _selectedMembers) {
      final result = await _executeAuthorized(
        (accessToken) => _projectUseCases.inviteProjectMember(
          accessToken: accessToken,
          projectId: project.id,
          userId: user.id,
        ),
      );

      if (result.isSuccess) {
        successCount++;
      } else {
        failedNames.add(user.nickname.isNotEmpty ? user.nickname : user.email);
      }
    }

    return _InviteResult(successCount: successCount, failedNames: failedNames);
  }
}

class _InviteResult {
  const _InviteResult({this.successCount = 0, this.failedNames = const []});

  final int successCount;
  final List<String> failedNames;
}
