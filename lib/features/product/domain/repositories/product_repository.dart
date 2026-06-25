import '../../data/models/product_model.dart';

abstract class ProductRepository {
  // 👇 Ganti nama menjadi getProducts dan terima 2 parameter 👇
  Future<List<ProductModel>> getProducts({String? query, String? category});

  // ==========================================
  // 👇 3 FUNGSI BARU KHUSUS ADMIN 👇
  // ==========================================
  Future<void> addProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(int productId);
}