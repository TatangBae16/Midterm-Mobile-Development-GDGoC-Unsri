abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested(this.email, this.password);
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  SignUpRequested(this.email, this.password, this.name);
}

class LogoutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class GoogleSignInRequested extends AuthEvent {}