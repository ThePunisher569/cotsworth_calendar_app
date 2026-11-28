import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';

import '../../../core/config/app_env.dart';
import '../../../core/storage/local_storage_service.dart';
import '../domain/auth_user.dart';

/// Domain exception raised on authentication failures with human-readable messaging.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Repository coordinating Firebase Email/Password authentication, optional
/// Firestore user profile seeding, and temporary offline Guest sessions.
class AuthRepository {
  AuthRepository(
    this._storage, {
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    bool Function()? isFirebaseInitialized,
  }) : _injectedAuth = firebaseAuth,
       _injectedFirestore = firestore,
       _isFirebaseInitialized =
           isFirebaseInitialized ?? (() => Firebase.apps.isNotEmpty);

  static String get tempGuestUsername => AppEnv.tempGuestUsername;
  static String get tempGuestPassword => AppEnv.tempGuestPassword;

  final LocalStorageService _storage;
  final fb.FirebaseAuth? _injectedAuth;
  final FirebaseFirestore? _injectedFirestore;
  final bool Function() _isFirebaseInitialized;

  bool get isFirebaseAvailable =>
      _injectedAuth != null || _isFirebaseInitialized();

  fb.FirebaseAuth? get _auth {
    if (_injectedAuth != null) return _injectedAuth;
    if (!_isFirebaseInitialized()) return null;
    return fb.FirebaseAuth.instance;
  }

  FirebaseFirestore? get _firestore {
    if (_injectedFirestore != null) return _injectedFirestore;
    if (!_isFirebaseInitialized()) return null;
    return FirebaseFirestore.instance;
  }

  /// Stream of Firebase user updates; emits nothing when Firebase isn't active.
  Stream<AuthUser?> authStateChanges() {
    final auth = _auth;
    if (auth == null) return const Stream<AuthUser?>.empty();
    return auth.userChanges().map(
      (user) => user == null ? null : _mapFirebaseUser(user),
    );
  }

  AuthUser? getCurrentUser() {
    final fbUser = _auth?.currentUser;
    if (fbUser != null) {
      return _mapFirebaseUser(fbUser);
    }
    if (AppEnv.allowGuestMode && _storage.isGuestLoggedIn) {
      return AuthUser(
        uid: 'local_guest',
        username: tempGuestUsername,
        isGuest: true,
      );
    }
    return null;
  }

  /// Signs in using either the temporary Guest credentials or Firebase Email/Password.
  Future<AuthUser?> signIn({
    required String username,
    required String password,
  }) async {
    final trimmed = username.trim();

    if (AppEnv.allowGuestMode &&
        trimmed == tempGuestUsername &&
        password == tempGuestPassword) {
      await _storage.setGuestLoggedIn(true);
      return AuthUser(
        uid: 'local_guest',
        username: tempGuestUsername,
        isGuest: true,
      );
    }

    final auth = _auth;
    if (auth == null) {
      if (_looksLikeEmail(trimmed)) {
        throw const AuthException(
          'Firebase is not initialized. Provide .env config or continue as Guest.',
        );
      }
      return null;
    }

    if (!_looksLikeEmail(trimmed)) {
      throw const AuthException(
        'Enter a valid email address or use Temp Credentials: Guest / guest.',
      );
    }

    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: trimmed,
        password: password,
      );
      final fbUser = credential.user;
      if (fbUser == null) {
        throw const AuthException('Sign-in failed. Please try again.');
      }
      await _storage.setGuestLoggedIn(false);
      unawaited(_touchUserProfile(fbUser));
      return _mapFirebaseUser(fbUser);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message));
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message));
    }
  }

  /// Registers a new Firebase Email/Password account and seeds its user profile.
  Future<AuthUser> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw const AuthException(
        'Firebase is not initialized. Provide .env credentials to register an account.',
      );
    }

    final cleanName = displayName.trim();
    final cleanEmail = email.trim();

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      var fbUser = credential.user;
      if (fbUser == null) {
        throw const AuthException('Account creation failed. Please try again.');
      }

      if (cleanName.isNotEmpty) {
        await fbUser.updateDisplayName(cleanName);
        try {
          await fbUser.reload();
        } catch (_) {
          // Best-effort refresh; updated displayName is preserved via fallbackName.
        }
        fbUser = auth.currentUser ?? fbUser;
      }

      await _storage.setGuestLoggedIn(false);
      unawaited(_seedUserProfile(fbUser, fallbackDisplayName: cleanName));
      return _mapFirebaseUser(fbUser, fallbackName: cleanName);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message));
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message));
    }
  }

  /// Sends a Firebase password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    final auth = _auth;
    if (auth == null) {
      throw const AuthException(
        'Firebase is not initialized. Password reset requires Firebase.',
      );
    }
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message));
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message));
    }
  }

  /// Sends an email verification link to the current signed-in Firebase user.
  Future<void> sendEmailVerification() async {
    final fbUser = _auth?.currentUser;
    if (fbUser == null) {
      throw const AuthException('No signed-in Firebase account found.');
    }
    try {
      await fbUser.sendEmailVerification();
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message));
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message));
    }
  }

  /// Reloads the active Firebase user to pick up updated displayName or emailVerified.
  Future<AuthUser?> reloadUser() async {
    final fbUser = _auth?.currentUser;
    if (fbUser == null) return getCurrentUser();
    try {
      await fbUser.reload();
      final refreshed = _auth?.currentUser ?? fbUser;
      return _mapFirebaseUser(refreshed);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message));
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message));
    }
  }

  /// Updates the signed-in user's display name in Firebase Auth & Firestore.
  Future<AuthUser> updateProfile({required String displayName}) async {
    final cleanName = displayName.trim();
    if (cleanName.length < 2) {
      throw const AuthException('Display name must be at least 2 characters.');
    }
    final fbUser = _auth?.currentUser;
    if (fbUser == null) {
      throw const AuthException(
        'Sign in with a Firebase account to update profile details.',
      );
    }
    try {
      await fbUser.updateDisplayName(cleanName);
      try {
        await fbUser.reload();
      } catch (_) {
        // Best-effort refresh; local state and Firestore still receive cleanName.
      }
      final refreshed = _auth?.currentUser ?? fbUser;
      unawaited(_updateUserProfile(refreshed, displayName: cleanName));
      return _mapFirebaseUser(refreshed, fallbackName: cleanName);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message));
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message));
    }
  }

  /// Permanently deletes the signed-in Firebase account (and Firestore profile).
  Future<void> deleteAccount({String? currentPassword}) async {
    final fbUser = _auth?.currentUser;
    if (fbUser == null) {
      await _storage.setGuestLoggedIn(false);
      return;
    }
    try {
      if (currentPassword != null &&
          currentPassword.isNotEmpty &&
          fbUser.email != null) {
        final cred = fb.EmailAuthProvider.credential(
          email: fbUser.email!,
          password: currentPassword,
        );
        await fbUser.reauthenticateWithCredential(cred);
      }

      final db = _firestore;
      if (db != null) {
        try {
          await db
              .collection(AppEnv.firestoreUsersCollection)
              .doc(fbUser.uid)
              .delete();
        } catch (_) {
          // Best-effort cleanup if rules or offline state reject.
        }
      }

      await fbUser.delete();
      await _storage.setGuestLoggedIn(false);
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw const AuthException(
          'Please enter your current password to confirm account deletion.',
        );
      }
      throw AuthException(_mapFirebaseError(e.code, e.message));
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message));
    }
  }

  Future<void> signOut() async {
    await _storage.setGuestLoggedIn(false);
    final auth = _auth;
    if (auth != null && auth.currentUser != null) {
      await auth.signOut();
    }
  }

  Future<void> _seedUserProfile(
    fb.User fbUser, {
    required String fallbackDisplayName,
  }) async {
    final db = _firestore;
    if (db == null) return;
    try {
      await db.collection(AppEnv.firestoreUsersCollection).doc(fbUser.uid).set({
        'uid': fbUser.uid,
        'displayName': (fbUser.displayName?.trim().isNotEmpty ?? false)
            ? fbUser.displayName!.trim()
            : fallbackDisplayName,
        'email': fbUser.email,
        'calendarSystem': 'cotsworth_13x28',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Do not fail registration if offline or rules aren't deployed yet.
    }
  }

  Future<void> _updateUserProfile(
    fb.User fbUser, {
    required String displayName,
  }) async {
    final db = _firestore;
    if (db == null) return;
    try {
      await db.collection(AppEnv.firestoreUsersCollection).doc(fbUser.uid).set({
        'uid': fbUser.uid,
        'displayName': displayName,
        'email': fbUser.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Non-fatal profile sync error when offline or rules reject.
    }
  }

  Future<void> _touchUserProfile(fb.User fbUser) async {
    final db = _firestore;
    if (db == null) return;
    try {
      await db.collection(AppEnv.firestoreUsersCollection).doc(fbUser.uid).set({
        'uid': fbUser.uid,
        'email': fbUser.email,
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Non-fatal metadata update.
    }
  }

  static bool _looksLikeEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  static AuthUser _mapFirebaseUser(fb.User user, {String? fallbackName}) {
    final rawName = user.displayName?.trim();
    final emailName = user.email?.split('@').first;
    final resolvedName = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (fallbackName != null && fallbackName.isNotEmpty)
        ? fallbackName
        : (emailName != null && emailName.isNotEmpty)
        ? emailName
        : tempGuestUsername;

    return AuthUser(
      uid: user.uid,
      username: resolvedName,
      email: user.email,
      isGuest: user.isAnonymous,
      emailVerified: user.emailVerified,
    );
  }

  static String _mapFirebaseError(String code, String? message) {
    return switch (code) {
      'invalid-email' => 'Please enter a valid email address.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'invalid-login-credentials' =>
        'Invalid email or password. Make sure you registered an account first.',
      'user-disabled' => 'This account has been disabled.',
      'email-already-in-use' =>
        'An account already exists for this email address.',
      'weak-password' =>
        'Password is too weak. Choose at least ${AppEnv.minPasswordLength} characters.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment before trying again.',
      'network-request-failed' =>
        'Network error. Check your connection and try again.',
      'operation-not-allowed' =>
        'Email/Password sign-in is not enabled in Firebase Console yet.',
      'unauthorized-domain' || 'app-not-authorized' =>
        'This domain is not authorized in Firebase Authentication settings.',
      'requires-recent-login' || 'user-token-expired' =>
        'Session expired. Sign out and sign back in before retrying.',
      'internal-error' => 'Authentication request rejected by Firebase. Check Firebase Auth & API key referrer settings.',
      _ =>
        (message != null && message.trim().isNotEmpty)
            ? message
            : 'Authentication failed. Please try again.',
    };
  }
}
