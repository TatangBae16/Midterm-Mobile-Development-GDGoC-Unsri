import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ProfileRepository {
  User? getCurrentUser();
  Future<void> updateAddress(String newAddress);
  Future<void> uploadProfilePicture(String userId, String fileExt, Uint8List bytes);
}