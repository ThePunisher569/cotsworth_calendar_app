import 'package:equatable/equatable.dart';

import '../../domain/auth_user.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.errorMessage});
  final String? errorMessage;
  @override
  List<Object?> get props => [errorMessage];
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final AuthUser user;
  @override
  List<Object?> get props => [user];
}
