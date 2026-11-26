import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/theme_cubit.dart';
import '../../../../shared/widgets/cotsworth_logo.dart';
import '../../../../shared/widgets/guest_account_badge.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.watch<ThemeCubit>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
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
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      final error = authState is AuthUnauthenticated
                          ? authState.errorMessage
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
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
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
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                hintText: 'Guest',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              key: const Key('login_password'),
                              controller: _passCtrl,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'guest',
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
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                            if (error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  error,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHigh,
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
                                      'Temp Credentials: Guest / guest',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _userCtrl.text = 'Guest';
                                      _passCtrl.text = 'guest';
                                    },
                                    child: const Text('Auto-fill'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              key: const Key('login_submit'),
                              onPressed: _submit,
                              icon: const Icon(Icons.login_rounded),
                              label: const Text('Sign In'),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              key: const Key('login_guest_shortcut'),
                              onPressed: () =>
                                  context.read<AuthCubit>().loginAsGuest(),
                              icon: const Icon(Icons.flash_on_rounded),
                              label: const Text('Continue as Temp Guest'),
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
    );
  }
}
