import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/wishlist_repository.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final SupabaseClient _supabaseClient;

  WishlistRepositoryImpl(this._supabaseClient);

  @override
  Future<List<dynamic>> getWishlist(String userId) async {
    try {
      // Mengambil data wishlist sekaligus menarik detail produknya menggunakan relasi
      final response = await _supabaseClient
          .from('wishlists')
          .select('*, products(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return response as List<dynamic>;
    } catch (e) {
      throw Exception('Gagal memuat wishlist: $e');
    }
  }

  @override
  Future<bool> checkIsWishlisted(String userId, dynamic productId) async {
    try {
      final response = await _supabaseClient
          .from('wishlists')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle(); // Cari 1 data, jika tidak ada kembalikan null

      return response != null; // Jika tidak null, berarti produk ada di wishlist
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> toggleWishlist(String userId, dynamic productId) async {
    try {
      final isExist = await checkIsWishlisted(userId, productId);

      if (isExist) {
        // Jika sudah ada, hapus dari wishlist (Unlike)
        await _supabaseClient
            .from('wishlists')
            .delete()
            .eq('user_id', userId)
            .eq('product_id', productId);
        return false; // Status sekarang: Tidak di-wishlist
      } else {
        // Jika belum ada, tambahkan ke wishlist (Like)
        await _supabaseClient
            .from('wishlists')
            .insert({
          'user_id': userId,
          'product_id': productId,
        });
        return true; // Status sekarang: Di-wishlist
      }
    } catch (e) {
      throw Exception('Gagal mengubah wishlist: $e');
    }
  }
}