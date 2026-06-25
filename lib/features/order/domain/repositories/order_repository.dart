abstract class OrderRepository {
  Future<List<dynamic>> getOrderHistory(String userId);

  Future<String> createOrderAndGetPaymentUrl({
    required String userId,
    required String userName,
    required String userEmail,
    required String userAddress,
    required num totalPrice,
    required List<dynamic> cartItems,
  });

  Future<String> checkPaymentStatus(String orderId);

  Future<List<dynamic>> getAllOrders();
}