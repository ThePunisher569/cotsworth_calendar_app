import 'package:equatable/equatable.dart';

import '../../domain/auth_user.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({
    this.errorMessage,
    this.infoMessage,
    this.isLoading = false,
  });

  final String? errorMessage;
  final String? infoMessage;
  final bool isLoading;

  @override
  List<Object?> get props => [errorMessage, infoMessage, isLoading];
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(
    this.user, {
    this.isLoading = false,
    this.infoMessage,
    this.errorMessage,
  });

  final AuthUser user;
  final bool isLoading;
  final String? infoMessage;
  final String? errorMessage;

  @override
  List<Object?> get props => [user, isLoading, infoMessage, errorMessage];
}
