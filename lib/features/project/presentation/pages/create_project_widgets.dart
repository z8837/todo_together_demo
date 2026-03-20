part of 'create_project_page.dart';

class _SelectedMemberChip extends StatelessWidget {
  const _SelectedMemberChip({required this.member, required this.onRemoved});

  final ProjectUser member;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    final displayName = member.nickname.isNotEmpty
        ? member.nickname
        : member.email;

    return InputChip(
      label: Text(
        displayName,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: _CreateProjectPalette.title,
        ),
      ),
      backgroundColor: Colors.white,
      deleteIcon: const Icon(Icons.close, size: 16),
      deleteIconColor: _CreateProjectPalette.hint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: _CreateProjectPalette.border, width: 0.6),
      ),
      onDeleted: onRemoved,
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.user,
    required this.onTap,
    required this.isSelected,
  });

  final ProjectUser user;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = user.nickname.isNotEmpty ? user.nickname : user.email;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: AppRadii.r16,
      borderSide: const BorderSide(
        color: _CreateProjectPalette.border,
        width: 0.6,
      ),
      child: ListTile(
        onTap: onTap,
        leading: ProviderAvatar(
          size: 40,
          radius: 26,
          initial: displayName.substring(0, 1).toUpperCase(),
          backgroundColor: _CreateProjectPalette.primary.withAlpha(26),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            color: _CreateProjectPalette.primary,
            fontSize: 17,
          ),
          provider: user.provider,
          badgeSize: 14,
          googleBadgePadding: 0.5,
          googleBorderColor: _CreateProjectPalette.border,
          appleIconSize: 10,
        ),
        title: Text(
          displayName,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: _CreateProjectPalette.title,
          ),
        ),
        subtitle: Text(
          user.email,
          style: theme.textTheme.bodySmall?.copyWith(
            color: _CreateProjectPalette.hint,
          ),
        ),
        trailing: isSelected
            ? const Icon(
                Icons.check_circle,
                color: _CreateProjectPalette.primary,
              )
            : const Icon(
                Icons.add_circle_outline,
                color: _CreateProjectPalette.primary,
              ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        borderRadius: AppRadii.r16,
        borderSide: const BorderSide(
          color: _CreateProjectPalette.border,
          width: 0.6,
        ),
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: _CreateProjectPalette.hint,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _CreateProjectPalette {
  const _CreateProjectPalette._();

  static const background = AppTokens.surface;
  static const border = AppTokens.divider;
  static const primary = AppTokens.primary;
  static const secondary = AppTokens.primarySoft;
  static const hint = AppTokens.textMuted;
  static const title = AppTokens.textPrimary;
}

class CreateProjectResult {
  const CreateProjectResult({
    required this.project,
    this.invitedCount = 0,
    this.failedInvites = const [],
    this.isDeleted = false,
  });

  final ProjectSummary project;
  final int invitedCount;
  final List<String> failedInvites;
  final bool isDeleted;
}
