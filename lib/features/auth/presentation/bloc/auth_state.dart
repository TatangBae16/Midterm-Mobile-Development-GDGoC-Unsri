import 'package:supabase_flutter/supabase_flutter.dart';
// 👇 Sesuaikan lokasi import modelmu
import '../../data/models/profile_model.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  final ProfileModel profile; // 👇 Tambahan properti profil

  Authenticated(this.user, this.profile); // 👇 Tambahkan di konstruktor
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}