import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';
import '../../../../core/network/dio_client.dart';

class ProductRepositoryImpl implements ProductRepository {
  final DioClient dioClient;
  static const String _cacheKey = 'CACHED_PRODUCTS';

  ProductRepositoryImpl({required this.dioClient});

  @override
  Future<List<ProductModel>> getProducts({String? query, String? category}) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final queryParameters = <String, dynamic>{};

      if (query != null && query.isNotEmpty) {
        queryParameters['name'] = 'ilike.%$query%';
      }

      if (category != null && category != 'Semua') {
        queryParameters['category'] = 'eq.$category';
      }

      final response = await dioClient.dio.get(
        '/products',
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );

      final products = (response.data as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();

      if ((query == null || query.isEmpty) && (category == null || category == 'Semua')) {
        final String jsonString = jsonEncode(products.map((p) => p.toJson()).toList());
        await prefs.setString(_cacheKey, jsonString);
      }

      return products;

    } on DioException catch (_) {
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        var cachedProducts = jsonList.map((json) => ProductModel.fromJson(json)).toList();

        if (category != null && category != 'Semua') {
          cachedProducts = cachedProducts.where((p) => p.category == category).toList();
        }

        if (query != null && query.isNotEmpty) {
          cachedProducts = cachedProducts.where((p) =>
              p.name.toLowerCase().contains(query.toLowerCase())
          ).toList();
        }

        return cachedProducts;
      } else {
        throw Exception('Tidak ada koneksi internet dan tidak ada data tersimpan.');
      }
    }
  }
  // ==========================================
  // IMPLEMENTASI FUNGSI ADMIN
  // ==========================================

  @override
  Future<void> addProduct(ProductModel product) async {
    try {
      final data = product.toJson();
      data.remove('id');

      await dioClient.dio.post('/products', data: data);
    } catch (e) {
      throw Exception('Gagal menambah komponen: $e');
    }
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    try {
      final data = product.toJson();
      data.remove('id'); // ID digunakan di URL, jadi tidak perlu ikut di-update isinya

      // Menggunakan PATCH untuk meng-update baris data yang ID-nya sama dengan product.id
      await dioClient.dio.patch('/products?id=eq.${product.id}', data: data);
    } catch (e) {
      throw Exception('Gagal memperbarui komponen: $e');
    }
  }

  @override
  Future<void> deleteProduct(int productId) async {
    try {
      // Menggunakan DELETE untuk menghapus baris data berdasarkan ID
      await dioClient.dio.delete('/products?id=eq.$productId');
    } catch (e) {
      throw Exception('Gagal menghapus komponen: $e');
    }
  }
}