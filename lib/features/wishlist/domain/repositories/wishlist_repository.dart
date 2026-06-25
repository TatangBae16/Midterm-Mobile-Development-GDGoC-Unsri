abstract class WishlistRepository {
  Future<List<dynamic>> getWishlist(String userId);
  Future<bool> checkIsWishlisted(String userId, dynamic productId);
  Future<bool> toggleWishlist(String userId, dynamic productId);
}