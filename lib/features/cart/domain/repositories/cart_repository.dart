// Ini adalah "KONTRAK" (Abstraksi).
// BLoC hanya akan melihat ini, tanpa peduli bagaimana data diambil (lewat internet atau lokal).

abstract class CartRepository {
  Future<List<dynamic>> fetchCartItems(String userId);
  Future<void> addToCart(String userId, int productId, int quantity);
  Future<void> updateQuantity(int cartId, int newQuantity);
  Future<void> removeFromCart(int cartId);

  Future<void> clearCart(String userId);
  Future<void> checkout(String userId);
}