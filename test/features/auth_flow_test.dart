import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:cotsworth_calendar_app/core/storage/local_storage_service.dart';
import 'package:cotsworth_calendar_app/core/theme/app_theme.dart';
import 'package:cotsworth_calendar_app/core/theme/motion_cubit.dart';
import 'package:cotsworth_calendar_app/core/theme/theme_cubit.dart';
import 'package:cotsworth_calendar_app/features/auth/data/auth_repository.dart';
import 'package:cotsworth_calendar_app/features/auth/domain/auth_user.dart';
import 'package:cotsworth_calendar_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:cotsworth_calendar_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:cotsworth_calendar_app/features/auth/presentation/screens/login_screen.dart';
import 'package:cotsworth_calendar_app/features/calendar/data/calendar_cache_repository.dart';
import 'package:cotsworth_calendar_app/features/calendar/presentation/bloc/calendar_bloc.dart';
import 'package:cotsworth_calendar_app/features/calendar/presentation/bloc/sky_cubit.dart';
import 'package:cotsworth_calendar_app/features/converter/data/converter_history_repository.dart';
import 'package:cotsworth_calendar_app/features/converter/presentation/bloc/converter_cubit.dart';
import 'package:cotsworth_calendar_app/shared/navigation/navigation_cubit.dart';
import 'package:cotsworth_calendar_app/shared/widgets/adaptive_scaffold.dart';

class _FakeFirebaseAuthRepository extends AuthRepository {
  _FakeFirebaseAuthRepository(super.storage)
    : super(isFirebaseInitialized: () => false);

  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _activeUser;
  String? lastResetEmail;
  bool deleted = false;
  bool failNextUpdate = false;

  @override
  bool get isFirebaseAvailable => true;

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  @override
  AuthUser? getCurrentUser() => _activeUser ?? super.getCurrentUser();

  @override
  Future<AuthUser?> signIn({
    required String username,
    required String password,
  }) async {
    if (username.trim() == AuthRepository.tempGuestUsername &&
        password == AuthRepository.tempGuestPassword) {
      return super.signIn(username: username, password: password);
    }
    if (username.trim() == 'aatif@example.com' && password == 'Secret123') {
      _activeUser = const AuthUser(
        uid: 'uid-123',
        username: 'Aatif Khan',
        email: 'aatif@example.com',
        isGuest: false,
        emailVerified: true,
      );
      return _activeUser;
    }
    throw const AuthException('Invalid email or password.');
  }

  @override
  Future<AuthUser> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    _activeUser = AuthUser(
      uid: 'uid-new',
      username: displayName.trim(),
      email: email.trim(),
      isGuest: false,
      emailVerified: false,
    );
    return _activeUser!;
  }

  @override
  Future<AuthUser> updateProfile({required String displayName}) async {
    if (failNextUpdate) {
      failNextUpdate = false;
      throw const AuthException('Simulated update failure.');
    }
    final current = _activeUser!;
    _activeUser = AuthUser(
      uid: current.uid,
      username: displayName.trim(),
      email: current.email,
      isGuest: current.isGuest,
      emailVerified: current.emailVerified,
    );
    return _activeUser!;
  }

  @override
  Future<void> deleteAccount({String? currentPassword}) async {
    deleted = true;
    _activeUser = null;
    await super.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    lastResetEmail = email.trim();
  }

  @override
  Future<void> signOut() async {
    _activeUser = null;
    await super.signOut();
  }
}

void main() {
  Future<void> pumpWithRepo(
    WidgetTester tester,
    AuthRepository repo,
    LocalStorageService storage, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit(storage)),
          BlocProvider(create: (_) => MotionCubit(storage)),
          BlocProvider(
            create: (ctx) =>
                SkyCubit(storage: storage, themeCubit: ctx.read<ThemeCubit>()),
          ),
          BlocProvider(create: (_) => AuthCubit(repo)),
          BlocProvider(create: (_) => NavigationCubit()),
          BlocProvider(
            create: (_) => CalendarBloc(CalendarCacheRepository(storage)),
          ),
          BlocProvider(
            create: (_) => ConverterCubit(ConverterHistoryRepository(storage)),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.dark,
          home: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              return authState is AuthAuthenticated
                  ? const AdaptiveScaffold(enableAutoSkyFetch: false)
                  : const LoginScreen();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Firebase Email/Password Auth & Profile Flows', () {
    testWidgets(
      'navigates to RegisterScreen, validates inputs, registers user, and signs out via dialog',
      (tester) async {
        final storage = InMemoryLocalStorageService(
          darkMode: true,
          reduceMotion: true,
        );
        final repo = _FakeFirebaseAuthRepository(storage);

        await pumpWithRepo(tester, repo, storage, size: const Size(390, 844));

        // Open Register screen
        await tester.ensureVisible(
          find.byKey(const Key('go_to_register_button')),
        );
        await tester.tap(find.byKey(const Key('go_to_register_button')));
        await tester.pumpAndSettle();
        expect(find.text('Create Account'), findsAtLeastNWidgets(1));

        // Mismatched passwords validation
        await tester.enterText(
          find.byKey(const Key('register_name')),
          'Aatif Khan',
        );
        await tester.enterText(
          find.byKey(const Key('register_email')),
          'aatif@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('register_password')),
          'Secret123',
        );
        await tester.enterText(
          find.byKey(const Key('register_confirm_password')),
          'Different123',
        );
        await tester.ensureVisible(find.byKey(const Key('register_submit')));
        await tester.tap(find.byKey(const Key('register_submit')));
        await tester.pumpAndSettle();
        expect(find.text('Passwords do not match'), findsOneWidget);

        // Fix confirmation and register
        await tester.enterText(
          find.byKey(const Key('register_confirm_password')),
          'Secret123',
        );
        await tester.tap(find.byKey(const Key('register_submit')));
        await tester.pumpAndSettle();

        // Lands inside AdaptiveScaffold
        expect(find.text('Cotsworth 13-Month Calendar'), findsOneWidget);

        // Open endDrawer & inspect signed-in profile + sign out dialog
        await tester.tap(find.byKey(const Key('drawer_menu_button')));
        await tester.pumpAndSettle();
        expect(find.text('Aatif Khan'), findsOneWidget);
        expect(find.text('aatif@example.com'), findsOneWidget);

        await tester.tap(find.text('Aatif Khan'));
        await tester.pumpAndSettle();
        expect(find.text('Email not yet verified'), findsOneWidget);

        await tester.tap(find.byKey(const Key('confirm_sign_out_button')));
        await tester.pumpAndSettle();
        expect(find.text('Cotsworth Calendar'), findsOneWidget);
      },
    );

    testWidgets(
      'signs in with verified account, opens Profile Page with green verified tick, updates name, and deletes account',
      (tester) async {
        final storage = InMemoryLocalStorageService(
          darkMode: true,
          reduceMotion: true,
        );
        final repo = _FakeFirebaseAuthRepository(storage);

        await pumpWithRepo(tester, repo, storage, size: const Size(1440, 900));

        // Password reset flow
        await tester.tap(find.byKey(const Key('forgot_password_button')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('forgot_password_email')),
          'reset@example.com',
        );
        await tester.tap(find.byKey(const Key('forgot_password_submit')));
        await tester.pumpAndSettle();
        expect(repo.lastResetEmail, equals('reset@example.com'));

        // Email sign-in flow with verified account
        await tester.enterText(
          find.byKey(const Key('login_username')),
          'aatif@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('login_password')),
          'Secret123',
        );
        await tester.tap(find.byKey(const Key('login_submit')));
        await tester.pumpAndSettle();

        expect(find.text('Cotsworth 13-Month Calendar'), findsOneWidget);
        expect(find.byKey(const Key('verified_account_tick')), findsOneWidget);

        // Open Profile Page from compact badge dialog
        await tester.tap(find.byKey(const Key('account_badge_compact')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('open_profile_from_dialog_button')),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('profile_verified_tick')), findsOneWidget);
        final tickIcon = tester.widget<Icon>(
          find.byKey(const Key('profile_verified_tick')),
        );
        expect(tickIcon.color, equals(const Color(0xFF00E676)));

        // Security & Verification section is removed from ProfileScreen
        expect(find.text('SECURITY & VERIFICATION'), findsNothing);
        expect(find.text('Send Verification Link'), findsNothing);
        expect(find.text('Send Password Reset Email'), findsNothing);

        // Email field is disabled in View Profile
        final emailField = tester.widget<TextFormField>(
          find.byKey(const Key('profile_email_field')),
        );
        expect(emailField.enabled, isFalse);

        // Error banner shows on failed display name update
        repo.failNextUpdate = true;
        await tester.enterText(
          find.byKey(const Key('profile_name_field')),
          'Fail Name',
        );
        await tester.tap(find.byKey(const Key('profile_save_button')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('profile_error_banner')), findsOneWidget);
        expect(find.text('Simulated update failure.'), findsOneWidget);

        // Update display name successfully
        await tester.enterText(
          find.byKey(const Key('profile_name_field')),
          'Aatif V2',
        );
        await tester.tap(find.byKey(const Key('profile_save_button')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('profile_error_banner')), findsNothing);
        expect(find.byKey(const Key('profile_info_banner')), findsOneWidget);
        expect(find.text('Aatif V2'), findsAtLeastNWidgets(2));

        // Permanently delete account
        await tester.ensureVisible(
          find.byKey(const Key('profile_delete_button')),
        );
        await tester.tap(find.byKey(const Key('profile_delete_button')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('confirm_delete_account_button')),
        );
        await tester.pumpAndSettle();

        expect(repo.deleted, isTrue);
        expect(find.text('Cotsworth Calendar'), findsOneWidget);
      },
    );

    test('AuthCubit auto-hides info and error feedback messages', () async {
      final storage = InMemoryLocalStorageService();
      final repo = _FakeFirebaseAuthRepository(storage);
      final cubit = AuthCubit(
        repo,
        messageAutoHideDuration: const Duration(milliseconds: 50),
      );

      await cubit.sendPasswordReset('reset@example.com');
      final withInfo = cubit.state as AuthUnauthenticated;
      expect(withInfo.infoMessage, isNotNull);

      await Future<void>.delayed(const Duration(milliseconds: 90));
      final cleared = cubit.state as AuthUnauthenticated;
      expect(cleared.infoMessage, isNull);
      expect(cleared.errorMessage, isNull);

      await cubit.close();
    });
  });
}
