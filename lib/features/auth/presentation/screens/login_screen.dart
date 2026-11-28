import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/config/app_env.dart';
import '../../../../core/theme/motion_cubit.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../shared/widgets/cotsworth_logo.dart';
import '../../../../shared/widgets/guest_account_badge.dart';
import '../../../../shared/widgets/smooth_page_transitions.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_feedback_banner.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthCubit>().login(
      username: _userCtrl.text,
      password: _passCtrl.text,
    );
  }

  void _openRegister() {
    context.read<AuthCubit>().clearMessages();
    final reduce = MotionCubit.shouldReduceMotion(context, listen: false);
    Navigator.of(context).push(
      SmoothSlideFadeRoute<void>(
        reduceMotion: reduce,
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final initialEmail = _userCtrl.text.contains('@')
        ? _userCtrl.text.trim()
        : '';
    final submittedEmail = await showDialog<String>(
      context: context,
      builder: (_) => _ForgotPasswordDialog(initialEmail: initialEmail),
    );
    if (submittedEmail != null && mounted) {
      await context.read<AuthCubit>().sendPasswordReset(submittedEmail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.select<ThemeCubit, bool>((c) => c.isDarkMode);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: const CotsworthLogo(size: 32, showWordmark: true),
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () => context.read<ThemeCubit>().toggleTheme(),
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: StaggeredEntrance(
                index: 0,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(28),
                    child: BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, authState) {
                        final isLoading =
                            authState is AuthUnauthenticated &&
                            authState.isLoading;
                        final error = authState is AuthUnauthenticated
                            ? authState.errorMessage
                            : null;
                        final info = authState is AuthUnauthenticated
                            ? authState.infoMessage
                            : null;

                        return Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Center(child: CotsworthLogo(size: 72)),
                              const SizedBox(height: 16),
                              Semantics(
                                header: true,
                                child: Text(
                                  'Cotsworth Calendar',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '13 Months · 28 Days · Natural Cycle Aligned',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const GuestAccountBadge(username: 'Guest'),
                              const SizedBox(height: 20),
                              TextFormField(
                                key: const Key('login_username'),
                                controller: _userCtrl,
                                enabled: !isLoading,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'you@example.com or Guest',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                key: const Key('login_password'),
                                controller: _passCtrl,
                                enabled: !isLoading,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Password or guest',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: TextButton(
                                  key: const Key('forgot_password_button'),
                                  onPressed: isLoading
                                      ? null
                                      : _showForgotPasswordDialog,
                                  child: const Text('Forgot Password?'),
                                ),
                              ),
                              if (info != null || error != null) ...[
                                AuthFeedbackBanner(
                                  infoMessage: info,
                                  errorMessage: error,
                                  infoKey: const Key('login_info_banner'),
                                  errorKey: const Key('login_error_banner'),
                                  onDismiss: () =>
                                      context.read<AuthCubit>().clearMessages(),
                                ),
                                const SizedBox(height: 10),
                              ],
                              FilledButton.icon(
                                key: const Key('login_submit'),
                                onPressed: isLoading ? null : _submit,
                                icon: isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.login_rounded),
                                label: Text(
                                  isLoading ? 'Signing In...' : 'Sign In',
                                ),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                key: const Key('go_to_register_button'),
                                onPressed: isLoading ? null : _openRegister,
                                icon: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                ),
                                label: const Text('Create Account'),
                              ),
                              if (AppEnv.allowGuestMode) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Expanded(child: Divider()),
                                    Padding(
                                      padding:
                                          const EdgeInsetsDirectional.symmetric(
                                            horizontal: 10,
                                          ),
                                      child: Text(
                                        'OR',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                    const Expanded(child: Divider()),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding:
                                      const EdgeInsetsDirectional.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                  decoration: BoxDecoration(
                                    color:
                                        theme.colorScheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Temp Credentials: ${AppEnv.tempGuestUsername} / ${AppEnv.tempGuestPassword}',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: isLoading
                                            ? null
                                            : () {
                                                _userCtrl.text =
                                                    AppEnv.tempGuestUsername;
                                                _passCtrl.text =
                                                    AppEnv.tempGuestPassword;
                                              },
                                        child: const Text('Auto-fill'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  key: const Key('login_guest_shortcut'),
                                  onPressed: isLoading
                                      ? null
                                      : () => context
                                            .read<AuthCubit>()
                                            .loginAsGuest(),
                                  icon: const Icon(Icons.flash_on_rounded),
                                  label: const Text('Continue as Temp Guest'),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
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
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Reset Password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your registered email address and Firebase will send a reset link.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('forgot_password_email'),
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                final clean = v?.trim() ?? '';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(clean)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('forgot_password_submit'),
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.of(context).pop(_emailCtrl.text.trim());
          },
          child: const Text('Send Link'),
        ),
      ],
    );
  }
}
