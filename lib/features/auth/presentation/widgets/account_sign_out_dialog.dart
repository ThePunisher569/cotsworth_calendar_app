import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/motion_cubit.dart';
import '../../../../shared/widgets/smooth_page_transitions.dart';
import '../../../profile/profile_screen.dart';
import '../../domain/auth_user.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Account summary & sign-out confirmation dialog accessible from the app bar
/// or mobile navigation drawer.
class AccountSignOutDialog extends StatelessWidget {
  const AccountSignOutDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AuthCubit>(),
        child: const AccountSignOutDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final AuthUser? user = authState is AuthAuthenticated
            ? authState.user
            : null;
        if (user == null) return const SizedBox.shrink();

        final isLoading = authState is AuthAuthenticated && authState.isLoading;
        final info = authState is AuthAuthenticated
            ? authState.infoMessage
            : null;
        final error = authState is AuthAuthenticated
            ? authState.errorMessage
            : null;

        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary.withAlpha(32),
                foregroundColor: theme.colorScheme.primary,
                child: user.isGuest
                    ? const Icon(Icons.person_outline_rounded)
                    : Text(
                        user.initials,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            user.username,
                            style: theme.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!user.isGuest && user.emailVerified)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 5),
                            child: Icon(
                              Icons.verified_rounded,
                              size: 18,
                              color: AppTheme.verifiedGreen(context),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      user.accountSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsetsDirectional.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      user.isGuest
                          ? Icons.offline_bolt_outlined
                          : user.emailVerified
                          ? Icons.verified_rounded
                          : Icons.mark_email_unread_outlined,
                      size: 18,
                      color: user.emailVerified
                          ? AppTheme.verifiedGreen(context)
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        user.isGuest
                            ? 'Local Temp Guest session'
                            : user.emailVerified
                            ? 'Verified Firebase Email Account'
                            : 'Email not yet verified',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('open_profile_from_dialog_button'),
                onPressed: () {
                  context.read<AuthCubit>().clearMessages();
                  final navigator = Navigator.of(context);
                  final reduce = MotionCubit.shouldReduceMotion(
                    context,
                    listen: false,
                  );
                  navigator.pop();
                  navigator.push(
                    SmoothSlideFadeRoute<void>(
                      reduceMotion: reduce,
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.manage_accounts_outlined, size: 18),
                label: const Text('Profile & Account Settings'),
              ),
              if (!user.isGuest && !user.emailVerified) ...[
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => context.read<AuthCubit>().sendVerificationEmail(),
                  icon: const Icon(Icons.send_outlined, size: 16),
                  label: const Text('Resend Verification Email'),
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ] else if (info != null) ...[
                const SizedBox(height: 8),
                Text(
                  info,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.intercalaryAccent(context),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              key: const Key('confirm_sign_out_button'),
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      context.read<AuthCubit>().logout();
                    },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}
