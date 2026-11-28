import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/config/app_env.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../shared/widgets/cotsworth_logo.dart';
import '../../../../shared/widgets/smooth_page_transitions.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_feedback_banner.dart';

/// Registration screen for creating a new Firebase Email & Password account.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String _passwordDraft = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _passwordDraft.length >= AppEnv.minPasswordLength;
  bool get _hasUpperOrDigit => RegExp(r'[A-Z0-9]').hasMatch(_passwordDraft);

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthCubit>().register(
      displayName: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.select<ThemeCubit, bool>((c) => c.isDarkMode);

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (_, curr) => curr is AuthAuthenticated,
      listener: (context, state) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back to Sign In',
            onPressed: () {
              context.read<AuthCubit>().clearMessages();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const CotsworthLogo(size: 30, showWordmark: true),
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
                constraints: const BoxConstraints(maxWidth: 460),
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

                          return Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Center(child: CotsworthLogo(size: 60)),
                                const SizedBox(height: 16),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    'Create Account',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Sync your 13-month Cotsworth schedule across devices',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                TextFormField(
                                  key: const Key('register_name'),
                                  controller: _nameCtrl,
                                  enabled: !isLoading,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Full Name',
                                    hintText: 'Aatif Khan',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().length < 2) {
                                      return 'Enter at least 2 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  key: const Key('register_email'),
                                  controller: _emailCtrl,
                                  enabled: !isLoading,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Email Address',
                                    hintText: 'you@example.com',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  validator: (v) {
                                    final clean = v?.trim() ?? '';
                                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                        .hasMatch(clean)) {
                                      return 'Enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  key: const Key('register_password'),
                                  controller: _passCtrl,
                                  enabled: !isLoading,
                                  obscureText: _obscurePass,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (v) =>
                                      setState(() => _passwordDraft = v),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () => _obscurePass = !_obscurePass,
                                      ),
                                      icon: Icon(
                                        _obscurePass
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null ||
                                        v.length < AppEnv.minPasswordLength) {
                                      return 'Use at least ${AppEnv.minPasswordLength} characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _RequirementPill(
                                      met: _hasMinLength,
                                      label:
                                          '${AppEnv.minPasswordLength}+ chars',
                                    ),
                                    _RequirementPill(
                                      met: _hasUpperOrDigit,
                                      label: 'Uppercase or number',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  key: const Key('register_confirm_password'),
                                  controller: _confirmCtrl,
                                  enabled: !isLoading,
                                  obscureText: _obscureConfirm,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    prefixIcon: const Icon(
                                      Icons.verified_user_outlined,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () =>
                                            _obscureConfirm = !_obscureConfirm,
                                      ),
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v != _passCtrl.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                                if (error != null) ...[
                                  const SizedBox(height: 14),
                                  AuthFeedbackBanner(
                                    errorMessage: error,
                                    errorKey: const Key(
                                      'register_error_banner',
                                    ),
                                    onDismiss: () => context
                                        .read<AuthCubit>()
                                        .clearMessages(),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                  key: const Key('register_submit'),
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
                                      : const Icon(
                                          Icons.person_add_alt_1_rounded,
                                        ),
                                  label: Text(
                                    isLoading
                                        ? 'Creating Account...'
                                        : 'Create Account',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 4,
                                  children: [
                                    Text(
                                      'Already have an account?',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                    TextButton(
                                      key: const Key('back_to_signin_button'),
                                      onPressed: isLoading
                                          ? null
                                          : () {
                                              context
                                                  .read<AuthCubit>()
                                                  .clearMessages();
                                              Navigator.of(context).pop();
                                            },
                                      child: const Text('Sign In'),
                                    ),
                                  ],
                                ),
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
      ),
    );
  }
}

class _RequirementPill extends StatelessWidget {
  const _RequirementPill({required this.met, required this.label});

  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = AppTheme.intercalaryAccent(context);
    final color = met ? activeColor : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: met
            ? activeColor.withAlpha(24)
            : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: met
              ? activeColor.withAlpha(90)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
