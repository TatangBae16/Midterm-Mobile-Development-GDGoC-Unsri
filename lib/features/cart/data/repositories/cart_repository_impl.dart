import 'dart:convert'; // Wajib untuk encode/decode JSON
import 'package:shared_preferences/shared_preferences.dart'; // Wajib untuk menyimpan data lokal

import 'package:md_midtermproject/core/network/dio_client.dart';
import 'package:md_midtermproject/features/cart/domain/repositories/cart_repository.dart';

// Kelas ini mengimplementasikan kontrak CartRepository
class CartRepositoryImpl implements CartRepository {
  final DioClient dioClient;

  CartRepositoryImpl({required this.dioClient});

  @override
  Future<List<dynamic>> fetchCartItems(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    // KUNCI RAHASIA: Gunakan userId sebagai bagian dari key agar keranjang tiap user aman dan tidak tertukar!
    final String cacheKey = 'CACHED_CART_ITEMS_$userId';

    try {
      // 1. Mencoba mengambil data terbaru dari server (Supabase)
      final response = await dioClient.dio.get('/carts?user_id=eq.$userId&select=*,products(*)');
      final List<dynamic> data = response.data as List<dynamic>;

      // 2. JIKA BERHASIL: Simpan (Cache) data tersebut ke memori lokal
      await prefs.setString(cacheKey, jsonEncode(data));

      return data;

    } catch (e) {
      // 3. JIKA GAGAL / OFFLINE: Cek apakah ada data keranjang terakhir yang tersimpan di HP
      final String? cachedData = prefs.getString(cacheKey);

      if (cachedData != null) {
        print("🌐 OFFLINE MODE: Memuat keranjang dari Cache lokal.");
        // Decode JSON kembali menjadi bentuk List
        return jsonDecode(cachedData) as List<dynamic>;
      }

      // 4. Jika offline DAN belum pernah buka keranjang sama sekali, lemparkan error
      throw Exception('Koneksi terputus dan tidak ada data lokal.');
    }
  }

  @override
  Future<void> addToCart(String userId, int productId, int quantity) async {
    try {
      // 1. CEK: Apakah komponen ini sudah pernah dimasukkan ke keranjang?
      // Menggunakan Dio GET untuk mengecek kombinasi user_id dan product_id
      final checkResponse = await dioClient.dio.get('/carts?user_id=eq.$userId&product_id=eq.$productId');

      // Response dari Supabase REST API selalu berupa List (Array)
      final List<dynamic> existingData = checkResponse.data as List<dynamic>;

      if (existingData.isNotEmpty) {
        // 2. JIKA SUDAH ADA: Ambil data pertama, hitung quantity baru, lalu UPDATE (PATCH)
        final existingItem = existingData.first;
        final int currentQuantity = existingItem['quantity'] ?? 0;
        final int cartId = existingItem['id'];

        await dioClient.dio.patch(
          '/carts?id=eq.$cartId',
          data: {
            'quantity': currentQuantity + quantity, // Kuantitas langsung tergabung!
          },
        );
      } else {
        // 3. JIKA BELUM ADA: Jalankan perintah INSERT (POST) seperti biasa
        await dioClient.dio.post(
          '/carts',
          data: {
            'user_id': userId,
            'product_id': productId,
            'quantity': quantity,
          },
        );
      }
    } catch (e) {
      throw Exception('Gagal memperbarui keranjang: $e');
    }
  }

  @override
  Future<void> updateQuantity(int cartId, int newQuantity) async {
    await dioClient.dio.patch('/carts?id=eq.$cartId', data: {'quantity': newQuantity});
  }

  @override
  Future<void> removeFromCart(int cartId) async {
    await dioClient.dio.delete('/carts?id=eq.$cartId');
  }

  @override
  Future<void> clearCart(String userId) async {
    // 1. Menghapus semua baris di tabel carts yang memiliki user_id di Supabase
    await dioClient.dio.delete('/carts?user_id=eq.$userId');

    // 2. PENTING: Hapus juga cache lokalnya agar saat offline keranjangnya benar-benar terlihat kosong setelah checkout
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('CACHED_CART_ITEMS_$userId');
    } catch (_) {
      // Abaikan jika gagal menghapus cache
    }
  }

  @override
  Future<void> checkout(String userId) async {
    try {
      // 1. Ambil data keranjang beserta detail produknya
      final response = await dioClient.dio.get('/carts?user_id=eq.$userId&select=*,products(*)');
      final List<dynamic> cartItems = response.data as List<dynamic>;

      if (cartItems.isEmpty) return;

      double totalPrice = 0;
      List<Map<String, dynamic>> orderSummaryList = [];

      // 2. Looping untuk potong stok dan siapkan ringkasan barang belanjaan
      for (var item in cartItems) {
        final productId = item['product_id'];
        final int quantityBought = item['quantity'];
        final product = item['products'];

        if (product != null) {
          final int currentStock = product['stock'] ?? 0;
          final int price = product['price'] ?? 0;
          totalPrice += (price * quantityBought);

          // Simpan ringkasan nama, jumlah, dan harga untuk disimpan di history
          orderSummaryList.add({
            'product_name': product['name'],
            'quantity': quantityBought,
            'price': price,
          });

          // Hitung sisa stok dan update ke tabel products
          final int finalStock = (currentStock - quantityBought) < 0 ? 0 : (currentStock - quantityBought);
          await dioClient.dio.patch('/products?id=eq.$productId', data: {'stock': finalStock});
        }
      }

      // 3. SEBELUM KERANJANG DIHAPUS: Kirim data transaksi ke tabel orders
      await dioClient.dio.post('/orders', data: {
        'user_id': userId,
        'total_price': totalPrice.toInt(),
        'status': 'Pending', // Status awal otomatis pending
        'items_json': orderSummaryList, // Menyimpan list dalam bentuk JSON
      });

      // 4. Bersihkan cache lokal produk & hapus keranjang di server
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('CACHED_PRODUCTS');
      await clearCart(userId);

    } catch (e) {
      print("🚨 ERROR SAAT CHECKOUT: $e");
      throw Exception('Gagal melakukan proses checkout dan pemotongan stok.');
    }
  }
}