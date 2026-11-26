import 'package:material_ui/material_ui.dart';

/// Displays the Temporary Guest Account avatar/logo and optional sign-out action.
class GuestAccountBadge extends StatelessWidget {
  const GuestAccountBadge({
    super.key,
    this.username = 'Guest',
    this.compact = false,
    this.onLogout,
  });

  final String username;
  final bool compact;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatar = CircleAvatar(
      radius: compact ? 14 : 18,
      backgroundColor: theme.colorScheme.primary.withAlpha(32),
      foregroundColor: theme.colorScheme.primary,
      child: Icon(Icons.person_outline_rounded, size: compact ? 16 : 20),
    );

    if (compact) {
      return Tooltip(
        message: 'Temp Guest Account ($username)',
        child: Chip(
          avatar: avatar,
          label: Text(username),
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  username,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Temp Guest Account',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10.5,
                    letterSpacing: 0.2,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout_rounded, size: 18),
              tooltip: 'Sign out',
              onPressed: onLogout,
            ),
        ],
      ),
    );
  }
}
