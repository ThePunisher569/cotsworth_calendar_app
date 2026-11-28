import 'package:equatable/equatable.dart';

/// Authenticated domain user supporting both Firebase Email/Password accounts
/// and local temporary Guest sessions.
class AuthUser extends Equatable {
  const AuthUser({
    required this.username,
    required this.isGuest,
    this.uid = 'local_guest',
    this.email,
    this.emailVerified = false,
  });

  final String uid;
  final String username;
  final String? email;
  final bool isGuest;
  final bool emailVerified;

  /// Two-character or single-character initials for avatars.
  String get initials {
    final source = username.trim().isNotEmpty
        ? username.trim()
        : (email ?? 'G').trim();
    final parts = source
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return source.isNotEmpty ? source[0].toUpperCase() : 'G';
  }

  /// Descriptive subtitle displayed in account badges and sign-out cards.
  String get accountSubtitle =>
      isGuest ? 'Temp Guest Account' : (email ?? 'Firebase Account');

  @override
  List<Object?> get props => [uid, username, email, isGuest, emailVerified];
}
