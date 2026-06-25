import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      context.read<OrderBloc>().add(FetchOrderHistory(user.id));
    }
  }

  String _formatRupiah(num number) {
    return 'Rp ${number.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // 👇 Sedikit penyesuaian agar mengenali status dari Midtrans 👇
  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('pending')) return Colors.orange;
    if (s.contains('success')) return Colors.green;
    if (s.contains('cancel') || s.contains('gagal')) return Colors.red;

    if (s.contains('dikemas')) return Colors.blue;
    if (s.contains('dikirim')) return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadOrders();
        },
        child: BlocBuilder<OrderBloc, OrderState>(
          builder: (context, state) {
            if (state is OrderLoading) {
              return Center(child: CircularProgressIndicator(color: theme.primaryColor));
            } else if (state is OrderError) {
              return Center(child: Text('Gagal memuat riwayat: ${state.message}'));
            } else if (state is OrderLoaded) {
              final orders = state.orders;

              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Belum ada riwayat transaksi', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final List<dynamic> items = order['items_json'] ?? [];
                  final String status = order['status'] ?? 'Pending';

                  // 👇 1. Tambahkan detektor tema di sini 👇
                  final isDark = theme.brightness == Brightness.dark;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    // 👇 2. GANTI BOX DECORATION-NYA MENJADI INI 👇
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.transparent,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order['created_at'].toString().substring(0, 10),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (context, itemIndex) {
                            final item = items[itemIndex];

                            // ==========================================
                            // LOGIKA PEMBACAAN JSON YANG BARU
                            // ==========================================
                            final productData = item['products'] ?? {};
                            final String productName = productData['name'] ?? item['product_name'] ?? 'Produk';
                            final num productPrice = productData['price'] ?? item['price'] ?? 0;
                            final num quantity = item['quantity'] ?? 1;
                            // ==========================================

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "$productName x$quantity",
                                      style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Text(
                                    _formatRupiah(productPrice * quantity),
                                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              _formatRupiah(order['total_price']),
                              style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),

                        // ==========================================
                        // 👇 TOMBOL CEK STATUS DITAMBAHKAN DI SINI 👇
                        // ==========================================
                        if (status.toLowerCase().contains('pending')) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 35,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: theme.primaryColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: Icon(Icons.refresh, size: 16, color: theme.primaryColor),
                              label: Text('CEK STATUS PEMBAYARAN', style: TextStyle(fontSize: 12, color: theme.primaryColor, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                // Memicu BLoC untuk mengecek status ke Midtrans
                                context.read<OrderBloc>().add(CheckOrderPayment(order['id']));
                              },
                            ),
                          ),
                        ],
                        // ==========================================
                      ],
                    ),
                  );
                },
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}