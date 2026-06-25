import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

// 👇 Package google_sign_in dan dotenv sudah DIHAPUS agar tidak ada lagi error! 👇

import '../../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final supabaseEvent = data.event;
      // Jika Supabase mendeteksi ada login yang sukses (dari browser)
      if (supabaseEvent == AuthChangeEvent.signedIn) {
        // Kita beri jeda 500ms agar trigger di database Supabase selesai membuat profil
        Future.delayed(const Duration(milliseconds: 500), () {
          // Perintahkan BLoC untuk cek sesi dan ambil profil!
          add(AuthCheckRequested());
        });
      }
    });
    // 1. Saat aplikasi baru dibuka (Cek Sesi)
    on<AuthCheckRequested>((event, emit) async {
      final user = authRepository.getCurrentUser();
      if (user != null) {
        try {
          final profile = await authRepository.getUserProfile(user.id);
          emit(Authenticated(user, profile));
        } catch (e) {
          emit(Unauthenticated());
        }
      } else {
        emit(Unauthenticated());
      }
    });

    // 2. Saat klik tombol Login Manual
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await authRepository.signIn(email: event.email, password: event.password);
        if (response.user != null) {
          final profile = await authRepository.getUserProfile(response.user!.id);
          emit(Authenticated(response.user!, profile));
        } else {
          emit(AuthError("Gagal login, user tidak ditemukan."));
        }
      } catch (e) {
        emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      }
    });

    // 3. Saat klik tombol Google Sign In
    on<GoogleSignInRequested>(_onGoogleSignInRequested);

    // 4. Saat klik tombol Daftar (Sign Up)
    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await authRepository.signUp(email: event.email, password: event.password, name: event.name);
        if (response.user != null) {
          await Future.delayed(const Duration(milliseconds: 500));
          final profile = await authRepository.getUserProfile(response.user!.id);
          emit(Authenticated(response.user!, profile));
        } else {
          emit(AuthError("Gagal mendaftar."));
        }
      } catch (e) {
        emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      }
    });

    // 5. Saat Logout
    on<LogoutRequested>((event, emit) async {
      await Supabase.instance.client.auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      emit(Unauthenticated());
    });
  }

  // =================================================================
  // METHOD GOOGLE SIGN IN - VERSI SUPABASE OAUTH (DIJAMIN ANTI ERROR)
  // =================================================================
  Future<void> _onGoogleSignInRequested(
      GoogleSignInRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      // Menggunakan fitur bawaan Supabase tanpa package eksternal
      final isSuccess = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'gearshift://login-callback',
      );

      // Jika gagal memanggil halaman Google
      if (!isSuccess) {
        emit(AuthError('Proses Google Login dibatalkan atau gagal dipanggil.'));
      }

      // Catatan: Jika sukses (isSuccess == true), Supabase akan otomatis
      // membuka browser untuk login, lalu me-redirect kembali ke aplikasi
      // dan AuthCheckRequested akan otomatis mendeteksi sesinya saat aplikasi terbuka lagi.

    } catch (e) {
      emit(AuthError('Terjadi kesalahan: ${e.toString()}'));
    }
  }
}