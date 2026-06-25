abstract class CartRepository {
  Future<List<dynamic>> fetchCartItems(String userId);
  Future<void> addToCart(String userId, int productId, int quantity);
  Future<void> updateQuantity(int cartId, int newQuantity);
  Future<void> removeFromCart(int cartId);

  Future<void> clearCart(String userId);
  Future<void> checkout(String userId);
}