import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({required this.username, required this.isGuest});
  final String username;
  final bool isGuest;

  @override
  List<Object?> get props => [username, isGuest];
}
