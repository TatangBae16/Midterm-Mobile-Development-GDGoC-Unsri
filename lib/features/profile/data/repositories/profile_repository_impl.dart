import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final SupabaseClient _supabaseClient;

  ProfileRepositoryImpl(this._supabaseClient);

  @override
  User? getCurrentUser() => _supabaseClient.auth.currentUser;

  @override
  Future<void> updateAddress(String newAddress) async {
    await _supabaseClient.auth.updateUser(
      UserAttributes(data: {'address': newAddress}),
    );
  }

  @override
  Future<void> uploadProfilePicture(String userId, String fileExt, Uint8List bytes) async {
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    // 1. Upload ke Storage
    await _supabaseClient.storage.from('avatars').uploadBinary(fileName, bytes);

    // 2. Dapatkan URL
    final imageUrl = _supabaseClient.storage.from('avatars').getPublicUrl(fileName);

    // 3. Simpan URL ke Metadata
    await _supabaseClient.auth.updateUser(
      UserAttributes(data: {'avatar_url': imageUrl}),
    );
  }
}