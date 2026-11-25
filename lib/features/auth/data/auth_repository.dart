import '../../../core/storage/local_storage_service.dart';
import '../domain/auth_user.dart';

class AuthRepository {
  AuthRepository(this._storage);

  static const tempGuestUsername = 'Guest';
  static const tempGuestPassword = 'guest';

  final LocalStorageService _storage;

  AuthUser? getCurrentUser() {
    if (!_storage.isGuestLoggedIn) return null;
    return const AuthUser(username: tempGuestUsername, isGuest: true);
  }

  Future<AuthUser?> signIn({
    required String username,
    required String password,
  }) async {
    if (username.trim() == tempGuestUsername && password == tempGuestPassword) {
      await _storage.setGuestLoggedIn(true);
      return const AuthUser(username: tempGuestUsername, isGuest: true);
    }
    return null;
  }

  Future<void> signOut() => _storage.setGuestLoggedIn(false);
}
