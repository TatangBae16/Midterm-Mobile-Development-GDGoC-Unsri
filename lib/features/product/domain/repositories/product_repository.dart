import '../../data/models/product_model.dart';

abstract class ProductRepository {
  Future<List<ProductModel>> getProducts({String? query, String? category});

  // ==========================================
  // FUNGSI BARU KHUSUS ADMIN
  // ==========================================
  Future<void> addProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(int productId);
}