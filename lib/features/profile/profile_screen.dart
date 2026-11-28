import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/smooth_page_transitions.dart';
import '../auth/domain/auth_user.dart';
import '../auth/presentation/cubit/auth_cubit.dart';
import '../auth/presentation/cubit/auth_state.dart';
import '../auth/presentation/widgets/auth_feedback_banner.dart';

/// User profile page displaying account details, vibrant green verified badge,
/// display name editor, disabled email field, and account actions.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthCubit>().state;
    final initialName = state is AuthAuthenticated ? state.user.username : '';
    final initialEmail = state is AuthAuthenticated
        ? (state.user.email ?? 'Guest Session')
        : '';
    _nameCtrl = TextEditingController(text: initialName);
    _emailCtrl = TextEditingController(text: initialEmail);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await context.read<AuthCubit>().updateDisplayName(_nameCtrl.text);
  }

  Future<void> _confirmDeleteAccount(AuthUser user) async {
    final password = await showDialog<String?>(
      context: context,
      builder: (_) => _DeleteAccountDialog(isGuest: user.isGuest),
    );
    if (password == null || !mounted) return;
    final deleted = await context.read<AuthCubit>().deleteAccount(
      currentPassword: password.isEmpty ? null : password,
    );
    if (deleted && mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Account')),
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated && !state.isLoading) {
              if (_nameCtrl.text != state.user.username) {
                _nameCtrl.text = state.user.username;
              }
              final nextEmail = state.user.email ?? 'Guest Session';
              if (_emailCtrl.text != nextEmail) {
                _emailCtrl.text = nextEmail;
              }
            }
            if (state is AuthUnauthenticated &&
                Navigator.of(context).canPop()) {
              Navigator.of(context).popUntil((r) => r.isFirst);
            }
          },
          builder: (context, state) {
            if (state is! AuthAuthenticated) {
              return const SizedBox.shrink();
            }
            final user = state.user;
            final isLoading = state.isLoading;
            final info = state.infoMessage;
            final error = state.errorMessage;

            return SingleChildScrollView(
              padding: const EdgeInsetsDirectional.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Identity Header Card
                      StaggeredEntrance(
                        index: 0,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.all(20),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: theme.colorScheme.primary
                                      .withAlpha(32),
                                  foregroundColor: theme.colorScheme.primary,
                                  child: user.isGuest
                                      ? const Icon(
                                          Icons.person_outline_rounded,
                                          size: 28,
                                        )
                                      : Text(
                                          user.initials,
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              user.username,
                                              style: theme
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (!user.isGuest &&
                                              user.emailVerified)
                                            Padding(
                                              padding:
                                                  const EdgeInsetsDirectional.only(
                                                    start: 6,
                                                  ),
                                              child: Tooltip(
                                                message: 'Verified Account',
                                                child: Icon(
                                                  Icons.verified_rounded,
                                                  key: const Key(
                                                    'profile_verified_tick',
                                                  ),
                                                  size: 22,
                                                  color: AppTheme.verifiedGreen(
                                                    context,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        user.accountSubtitle,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding:
                                            const EdgeInsetsDirectional.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                        decoration: BoxDecoration(
                                          color: user.emailVerified
                                              ? AppTheme.verifiedGreen(context)
                                                    .withAlpha(28)
                                              : theme
                                                    .colorScheme
                                                    .surfaceContainerHigh,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: user.emailVerified
                                                ? AppTheme.verifiedGreen(
                                                    context,
                                                  ).withAlpha(110)
                                                : theme
                                                      .colorScheme
                                                      .outlineVariant,
                                          ),
                                        ),
                                        child: Text(
                                          user.isGuest
                                              ? 'Guest Session'
                                              : user.emailVerified
                                              ? 'Verified Firebase Account'
                                              : 'Verification Pending',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                fontSize: 10.5,
                                                color: user.emailVerified
                                                    ? AppTheme.verifiedGreen(
                                                        context,
                                                      )
                                                    : theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (error != null || info != null) ...[
                        const SizedBox(height: 10),
                        AuthFeedbackBanner(
                          infoMessage: info,
                          errorMessage: error,
                          infoKey: const Key('profile_info_banner'),
                          errorKey: const Key('profile_error_banner'),
                          onDismiss: () =>
                              context.read<AuthCubit>().clearMessages(),
                        ),
                      ],
                      const SizedBox(height: 14),
                      // Edit User Info Form
                      StaggeredEntrance(
                        index: 1,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.all(20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'EDIT PROFILE',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      letterSpacing: 0.8,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    key: const Key('profile_name_field'),
                                    controller: _nameCtrl,
                                    enabled: !user.isGuest && !isLoading,
                                    decoration: const InputDecoration(
                                      labelText: 'Display Name',
                                      prefixIcon: Icon(Icons.badge_outlined),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().length < 2) {
                                        return 'Enter at least 2 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    key: const Key('profile_email_field'),
                                    controller: _emailCtrl,
                                    enabled: false,
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Account Email',
                                      prefixIcon: Icon(Icons.email_outlined),
                                      helperText:
                                          'Account email cannot be edited.',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (user.isGuest)
                                    Text(
                                      'Sign out and register an email account to customize your cloud profile.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    )
                                  else
                                    FilledButton.icon(
                                      key: const Key('profile_save_button'),
                                      onPressed: isLoading ? null : _saveName,
                                      icon: const Icon(Icons.save_rounded),
                                      label: Text(
                                        isLoading
                                            ? 'Saving...'
                                            : 'Update Profile',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Danger Zone: Sign Out & Delete Account
                      StaggeredEntrance(
                        index: 2,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: theme.colorScheme.error.withAlpha(110),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'ACCOUNT ACTIONS',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    letterSpacing: 0.8,
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  key: const Key('profile_sign_out_button'),
                                  onPressed: isLoading
                                      ? null
                                      : () =>
                                            context.read<AuthCubit>().logout(),
                                  icon: const Icon(Icons.logout_rounded),
                                  label: const Text('Sign Out'),
                                ),
                                const SizedBox(height: 10),
                                FilledButton.icon(
                                  key: const Key('profile_delete_button'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: theme.colorScheme.error,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: isLoading
                                      ? null
                                      : () => _confirmDeleteAccount(user),
                                  icon: const Icon(
                                    Icons.delete_forever_rounded,
                                  ),
                                  label: Text(
                                    user.isGuest
                                        ? 'Clear Guest Session'
                                        : 'Delete Account Permanently',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.isGuest});
  final bool isGuest;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        widget.isGuest ? 'Clear Guest Session?' : 'Delete Account Permanently?',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isGuest
                ? 'This ends your current temporary Guest session and returns to Sign In.'
                : 'This permanently deletes your Firebase account and cloud profile. Enter your current password if re-authentication is required.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!widget.isGuest) ...[
            const SizedBox(height: 14),
            TextField(
              key: const Key('delete_account_password_field'),
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password (optional unless prompted)',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('confirm_delete_account_button'),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(_passCtrl.text),
          child: Text(widget.isGuest ? 'Clear Session' : 'Delete Forever'),
        ),
      ],
    );
  }
}
