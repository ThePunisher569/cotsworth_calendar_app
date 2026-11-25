import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo)
      : super(_repo.getCurrentUser() != null
            ? AuthAuthenticated(_repo.getCurrentUser()!)
            : const AuthUnauthenticated());

  final AuthRepository _repo;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    if (username.trim().isEmpty || password.isEmpty) {
      emit(const AuthUnauthenticated(
        errorMessage: 'Please enter both username and password.',
      ));
      return;
    }
    final user = await _repo.signIn(username: username, password: password);
    if (user == null) {
      emit(const AuthUnauthenticated(
        errorMessage: 'Invalid credentials. Use: Guest / guest',
      ));
      return;
    }
    emit(AuthAuthenticated(user));
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
}
