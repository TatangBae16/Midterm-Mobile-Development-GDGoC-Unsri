import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/profile_model.dart';

class AuthRepository {
  // Menggunakan 'get' agar aman dari crash saat aplikasi baru menyala
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<AuthResponse> signUp({required String email, required String password, required String name}) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      return response;
    } catch (e) {
      throw Exception('Gagal mendaftar: ${e.toString()}');
    }
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Email atau password salah!');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Gagal logout: ${e.toString()}');
    }
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // ==========================================
  // 2. FUNGSI BARU UNTUK MENGAMBIL ROLE ADMIN/USER
  // ==========================================
  Future<ProfileModel> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single(); // .single() digunakan karena kita hanya mencari 1 profil spesifik

      return ProfileModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal memuat profil pengguna: $e');
    }
  }
}