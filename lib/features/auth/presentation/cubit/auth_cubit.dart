import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_repository.dart';
import '../../domain/auth_user.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(
    this._repo, {
    this.messageAutoHideDuration = const Duration(seconds: 4),
  }) : super(_initialState(_repo)) {
    _authSub = _repo.authStateChanges().listen(_onFirebaseAuthChanged);
  }

  final AuthRepository _repo;
  final Duration messageAutoHideDuration;
  late final StreamSubscription<AuthUser?> _authSub;
  Timer? _messageTimer;
  bool _suppressAuthStream = false;

  @override
  void emit(AuthState state) {
    _messageTimer?.cancel();
    final hasMessage = switch (state) {
      AuthUnauthenticated(:final infoMessage, :final errorMessage) =>
        infoMessage != null || errorMessage != null,
      AuthAuthenticated(:final infoMessage, :final errorMessage) =>
        infoMessage != null || errorMessage != null,
    };
    super.emit(state);
    if (hasMessage && messageAutoHideDuration > Duration.zero) {
      _messageTimer = Timer(messageAutoHideDuration, () {
        if (!isClosed) clearMessages();
      });
    }
  }

  static AuthState _initialState(AuthRepository repo) {
    final current = repo.getCurrentUser();
    return current != null
        ? AuthAuthenticated(current)
        : const AuthUnauthenticated();
  }

  bool get isFirebaseAvailable => _repo.isFirebaseAvailable;

  void _onFirebaseAuthChanged(AuthUser? firebaseUser) {
    if (_suppressAuthStream) return;
    if (firebaseUser != null) {
      final current = state;
      if (current is AuthAuthenticated && current.user == firebaseUser) {
        return;
      }
      emit(AuthAuthenticated(firebaseUser));
      return;
    }
    // Keep active local Temp Guest session intact when Firebase emits null.
    final current = state;
    if (current is AuthAuthenticated && !current.user.isGuest) {
      emit(const AuthUnauthenticated());
    }
  }

  void clearMessages() {
    final current = state;
    if (current is AuthUnauthenticated) {
      emit(AuthUnauthenticated(isLoading: current.isLoading));
    } else if (current is AuthAuthenticated) {
      emit(AuthAuthenticated(current.user, isLoading: current.isLoading));
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    if (username.trim().isEmpty || password.isEmpty) {
      emit(
        const AuthUnauthenticated(
          errorMessage: 'Please enter both username/email and password.',
        ),
      );
      return;
    }

    emit(const AuthUnauthenticated(isLoading: true));
    try {
      final user = await _repo.signIn(username: username, password: password);
      if (user == null) {
        emit(
          const AuthUnauthenticated(
            errorMessage: 'Invalid credentials. Use: Guest / guest',
          ),
        );
        return;
      }
      emit(AuthAuthenticated(user));
    } on AuthException catch (e) {
      emit(AuthUnauthenticated(errorMessage: e.message));
    } catch (_) {
      emit(
        const AuthUnauthenticated(
          errorMessage: 'Sign-in failed. Please try again.',
        ),
      );
    }
  }

  Future<bool> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    emit(const AuthUnauthenticated(isLoading: true));
    _suppressAuthStream = true;
    try {
      final user = await _repo.registerWithEmail(
        displayName: displayName,
        email: email,
        password: password,
      );
      emit(AuthAuthenticated(user));
      return true;
    } on AuthException catch (e) {
      emit(AuthUnauthenticated(errorMessage: e.message));
      return false;
    } catch (_) {
      emit(
        const AuthUnauthenticated(
          errorMessage: 'Could not create account. Please try again.',
        ),
      );
      return false;
    } finally {
      _suppressAuthStream = false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    emit(const AuthUnauthenticated(isLoading: true));
    try {
      await _repo.sendPasswordResetEmail(email);
      emit(
        AuthUnauthenticated(
          infoMessage:
              'Password reset email sent to ${email.trim()}. Check your inbox.',
        ),
      );
      return true;
    } on AuthException catch (e) {
      emit(AuthUnauthenticated(errorMessage: e.message));
      return false;
    } catch (_) {
      emit(
        const AuthUnauthenticated(
          errorMessage: 'Failed to send password reset email.',
        ),
      );
      return false;
    }
  }

  Future<void> sendVerificationEmail() async {
    final current = state;
    if (current is! AuthAuthenticated || current.user.isGuest) return;
    emit(AuthAuthenticated(current.user, isLoading: true));
    try {
      await _repo.sendEmailVerification();
      emit(
        AuthAuthenticated(
          current.user,
          infoMessage: 'Verification email sent to ${current.user.email}.',
        ),
      );
    } on AuthException catch (e) {
      emit(AuthAuthenticated(current.user, errorMessage: e.message));
    } catch (_) {
      emit(
        AuthAuthenticated(
          current.user,
          errorMessage: 'Could not send verification email.',
        ),
      );
    }
  }

  Future<bool> updateDisplayName(String displayName) async {
    final current = state;
    if (current is! AuthAuthenticated) return false;
    emit(AuthAuthenticated(current.user, isLoading: true));
    _suppressAuthStream = true;
    try {
      final updated = await _repo.updateProfile(displayName: displayName);
      emit(
        AuthAuthenticated(
          updated,
          infoMessage: 'Profile updated successfully.',
        ),
      );
      return true;
    } on AuthException catch (e) {
      emit(AuthAuthenticated(current.user, errorMessage: e.message));
      return false;
    } catch (_) {
      emit(
        AuthAuthenticated(
          current.user,
          errorMessage: 'Could not update profile.',
        ),
      );
      return false;
    } finally {
      _suppressAuthStream = false;
    }
  }

  Future<void> refreshProfile() async {
    final current = state;
    if (current is! AuthAuthenticated || current.user.isGuest) return;
    emit(AuthAuthenticated(current.user, isLoading: true));
    try {
      final refreshed = await _repo.reloadUser();
      if (refreshed != null) {
        emit(
          AuthAuthenticated(
            refreshed,
            infoMessage: refreshed.emailVerified
                ? 'Account verification confirmed.'
                : 'Account synced.',
          ),
        );
      } else {
        emit(const AuthUnauthenticated());
      }
    } on AuthException catch (e) {
      emit(AuthAuthenticated(current.user, errorMessage: e.message));
    } catch (_) {
      emit(
        AuthAuthenticated(
          current.user,
          errorMessage: 'Could not refresh account status.',
        ),
      );
    }
  }

  Future<void> sendPasswordResetForCurrentUser() async {
    final current = state;
    if (current is! AuthAuthenticated || current.user.email == null) return;
    emit(AuthAuthenticated(current.user, isLoading: true));
    try {
      await _repo.sendPasswordResetEmail(current.user.email!);
      emit(
        AuthAuthenticated(
          current.user,
          infoMessage: 'Password reset link sent to ${current.user.email}.',
        ),
      );
    } on AuthException catch (e) {
      emit(AuthAuthenticated(current.user, errorMessage: e.message));
    } catch (_) {
      emit(
        AuthAuthenticated(
          current.user,
          errorMessage: 'Could not send password reset link.',
        ),
      );
    }
  }

  Future<bool> deleteAccount({String? currentPassword}) async {
    final current = state;
    if (current is! AuthAuthenticated) return false;
    emit(AuthAuthenticated(current.user, isLoading: true));
    try {
      await _repo.deleteAccount(currentPassword: currentPassword);
      emit(
        const AuthUnauthenticated(
          infoMessage: 'Your account has been permanently deleted.',
        ),
      );
      return true;
    } on AuthException catch (e) {
      emit(AuthAuthenticated(current.user, errorMessage: e.message));
      return false;
    } catch (_) {
      emit(
        AuthAuthenticated(
          current.user,
          errorMessage: 'Failed to delete account. Please try again.',
        ),
      );
      return false;
    }
  }

  Future<void> loginAsGuest() async {
    await login(
      username: AuthRepository.tempGuestUsername,
      password: AuthRepository.tempGuestPassword,
    );
  }

  Future<void> logout() async {
    await _repo.signOut();
    emit(const AuthUnauthenticated());
  }

  @override
  Future<void> close() async {
    _messageTimer?.cancel();
    await _authSub.cancel();
    return super.close();
  }
}
