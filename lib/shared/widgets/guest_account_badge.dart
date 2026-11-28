import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

/// Displays the active Account / Temp Guest avatar badge, intense green verified
/// tick when email-verified, and optional tap/sign-out actions.
class GuestAccountBadge extends StatelessWidget {
  const GuestAccountBadge({
    super.key,
    this.username = 'Guest',
    this.email,
    this.isGuest = true,
    this.emailVerified = false,
    this.compact = false,
    this.onTap,
    this.onLogout,
  });

  final String username;
  final String? email;
  final bool isGuest;
  final bool emailVerified;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onLogout;

  String get _initials {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return 'G';
    final parts = trimmed
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = isGuest
        ? 'Temp Guest Account'
        : (email ?? 'Firebase Account');

    final avatar = CircleAvatar(
      radius: compact ? 14 : 18,
      backgroundColor: theme.colorScheme.primary.withAlpha(32),
      foregroundColor: theme.colorScheme.primary,
      child: isGuest
          ? Icon(Icons.person_outline_rounded, size: compact ? 16 : 20)
          : Text(
              _initials,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
    );

    final verifiedTick = emailVerified && !isGuest
        ? Padding(
            padding: const EdgeInsetsDirectional.only(start: 4),
            child: Icon(
              Icons.verified_rounded,
              key: const Key('verified_account_tick'),
              size: compact ? 15 : 17,
              color: AppTheme.verifiedGreen(context),
            ),
          )
        : const SizedBox.shrink();

    if (compact) {
      final chip = Chip(
        avatar: avatar,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(username, overflow: TextOverflow.ellipsis)),
            verifiedTick,
          ],
        ),
        visualDensity: VisualDensity.compact,
      );
      return Tooltip(
        message: '$username ($subtitle)',
        child: onTap != null
            ? InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: chip,
              )
            : chip,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            username,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        verifiedTick,
                      ],
                    ),
                    Text(
                      subtitle,
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
        ),
      ),
    );
  }
}
