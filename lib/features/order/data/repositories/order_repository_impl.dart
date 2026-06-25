import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final SupabaseClient _supabaseClient;

  // MASUKKAN SERVER KEY-MU DI SINI
  String get _midtransServerKey => dotenv.env['MIDTRANS_SERVER_KEY'] ?? '';

  OrderRepositoryImpl(this._supabaseClient);

  @override
  Future<List<dynamic>> getOrderHistory(String userId) async {
    try {
      final response = await _supabaseClient
          .from('orders')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return response as List<dynamic>;
    } catch (e) {
      throw Exception('Gagal mengambil data riwayat: $e');
    }
  }

  // IMPLEMENTASI FUNGSI CHECKOUT
  @override
  Future<String> createOrderAndGetPaymentUrl({
    required String userId,
    required String userName,
    required String userEmail,
    required String userAddress,
    required num totalPrice,
    required List<dynamic> cartItems,
  }) async {
    try {
      if (_midtransServerKey.isEmpty) {
        throw Exception('Server Key Midtrans belum dikonfigurasi di .env');
      }

      final orderId = 'GEARSHIFT-${DateTime.now().millisecondsSinceEpoch}';

      // 1. Simpan pesanan ke Supabase
      await _supabaseClient.from('orders').insert({
        'id': orderId,
        'user_id': userId,
        'total_price': totalPrice,
        'status': 'Pending Payment',
        'shipping_address': userAddress,
        'items_json': cartItems,
      });

      // 2. Kurangi Stok Produk di Supabase
      for (var item in cartItems) {
        final productId = item['products']['id'];
        final currentStock = item['products']['stock'] ?? 0;
        final int quantityBought = item['quantity'] ?? 1;
        final newStock = currentStock - quantityBought;

        await _supabaseClient.from('products').update({'stock': newStock < 0 ? 0 : newStock}).eq('id', productId);
      }

      // 3. Tembak API Midtrans
      final String basicAuth = base64Encode(utf8.encode('$_midtransServerKey:'));
      final dio = Dio();

      final response = await dio.post(
        'https://app.sandbox.midtrans.com/snap/v1/transactions',
        options: Options(
          headers: {
            'Authorization': 'Basic $basicAuth',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "transaction_details": {
            "order_id": orderId,
            "gross_amount": totalPrice.toInt()
          },
          "customer_details": {
            "first_name": userName,
            "email": userEmail,
            "shipping_address": {"address": userAddress}
          }
        },
      );

      // Kembalikan URL Midtrans ke BLoC
      return response.data['redirect_url'];
    } catch (e) {
      throw Exception('Gagal memproses pembayaran: $e');
    }
  }

  @override
  Future<String> checkPaymentStatus(String orderId) async {
    try {
      final String basicAuth = base64Encode(utf8.encode('$_midtransServerKey:'));
      final dio = Dio();

      // 1. Tanya ke Midtrans mengenai status orderId ini
      final response = await dio.get(
        'https://api.sandbox.midtrans.com/v2/$orderId/status',
        options: Options(
          headers: {
            'Authorization': 'Basic $basicAuth',
            'Content-Type': 'application/json',
          },
        ),
      );

      final String midtransStatus = response.data['transaction_status'];

      // 2. Jika di Midtrans statusnya 'settlement', artinya pembayaran sukses!
      if (midtransStatus == 'settlement') {
        // Update status di Supabase menjadi 'Payment Success'
        await _supabaseClient
            .from('orders')
            .update({'status': 'Payment Success'})
            .eq('id', orderId);

        return 'Payment Success';
      } else if (midtransStatus == 'pending') {
        return 'Pending Payment';
      } else if (midtransStatus == 'expire' || midtransStatus == 'cancel') {
        await _supabaseClient.from('orders').update({'status': 'Cancelled'}).eq('id', orderId);
        return 'Cancelled';
      }

      return midtransStatus;
    } catch (e) {
      throw Exception('Gagal mengecek status: $e');
    }
  }

  @override
  Future<List<dynamic>> getAllOrders() async {
    try {
      // Mengambil SEMUA data tanpa .eq('user_id', ...)
      final response = await _supabaseClient
          .from('orders')
          .select('* , profiles(full_name)')
          .order('created_at', ascending: false);
      return response as List<dynamic>;
    } catch (e) {
      throw Exception('Gagal mengambil semua data transaksi: $e');
    }
  }
}