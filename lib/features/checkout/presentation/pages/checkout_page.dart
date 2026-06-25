import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';

import '../../../order/presentation/bloc/order_bloc.dart';
import '../../../order/presentation/bloc/order_event.dart';
import '../../../order/presentation/bloc/order_state.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  String _formatRupiah(num number) {
    return 'Rp ${number.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? 'Pelanggan';
    final userEmail = user?.email ?? 'email@kosong.com';
    final userAddress = user?.userMetadata?['address'] ?? 'Belum diatur';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: theme.iconTheme,
      ),
      // BLoC Listener untuk menangkap aksi sukses/gagal dari OrderBloc
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) async {
          if (state is OrderCheckoutError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Gagal: ${state.message}'), backgroundColor: Colors.red));
          } else if (state is OrderCheckoutSuccess) {

            // 1. Buka URL Midtrans
            final Uri url = Uri.parse(state.redirectUrl);
            await launchUrl(url, mode: LaunchMode.externalApplication);

            // 2. Kosongkan keranjang & tutup halaman
            if (context.mounted) {
              context.read<CartBloc>().add(ClearCartRequested());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Pesanan Dibuat!'), backgroundColor: Colors.green),
              );
            }
          }
        },
        child: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            if (state is CartLoaded) {
              final cartItems = state.cartItems;
              num totalPrice = 0;
              for (var item in cartItems) totalPrice += (item['products']['price'] * item['quantity']);

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const Text('Alamat Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: theme.primaryColor),
                              const SizedBox(width: 16),
                              Expanded(child: Text(userAddress, style: TextStyle(color: theme.colorScheme.onSurface))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Ringkasan Pesanan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: cartItems.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text("${item['products']['name']} (x${item['quantity']})", style: TextStyle(color: theme.colorScheme.onSurface))),
                                    Text(_formatRupiah(item['products']['price'] * item['quantity']), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Pembayaran', style: TextStyle(fontSize: 16, color: Colors.grey)),
                            Text(_formatRupiah(totalPrice), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        BlocBuilder<OrderBloc, OrderState>(
                          builder: (context, orderState) {
                            final isLoading = orderState is OrderCheckoutLoading;

                            return SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                ),
                                onPressed: isLoading ? null : () {
                                  if (userAddress == 'Belum diatur') {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Harap isi alamat pengiriman di Profil terlebih dahulu!'), backgroundColor: Colors.red));
                                    return;
                                  }

                                  // Lempar Event ke BLoC
                                  context.read<OrderBloc>().add(ProcessCheckout(
                                    userId: user!.id,
                                    userName: userName,
                                    userEmail: userEmail,
                                    userAddress: userAddress,
                                    totalPrice: totalPrice,
                                    cartItems: cartItems,
                                  ));
                                },
                                child: isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('BAYAR SEKARANG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                ],
              );
            }
            return const Center(child: Text('Keranjang kosong'));
          },
        ),
      ),
    );
  }
}