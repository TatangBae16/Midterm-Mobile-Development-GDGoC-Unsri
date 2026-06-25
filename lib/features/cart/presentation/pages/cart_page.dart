import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../checkout/presentation/pages/checkout_page.dart';
import '../../../order/data/repositories/order_repository_impl.dart';
import '../../../order/presentation/bloc/order_bloc.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/presentation/bloc/product_event.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    context.read<CartBloc>().add(FetchCartRequested());
  }

  String _formatRupiah(num number) {
    return 'Rp ${number.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Keranjang Belanja', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartLoading || state is CartInitial) {
            return Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            );
          } else if (state is CartError) {
            final isAuthError = state.message.toLowerCase().contains('jwt') ||
                state.message.toLowerCase().contains('unauthorized') ||
                state.message.toLowerCase().contains('login');

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isAuthError ? Icons.lock_clock_rounded : Icons.wifi_off_rounded,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAuthError ? 'Sesi Telah Berakhir' : 'Oops, Terjadi Kendala!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAuthError ? 'Silakan login kembali untuk melihat keranjangmu.' : 'Pastikan koneksi internetmu stabil, ya.',
                    style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else if (state is CartLoaded) {
            final cartItems = state.cartItems;

            if (cartItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('Keranjangmu masih kosong', style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  ],
                ),
              );
            }

            double totalPrice = 0;
            for (var item in cartItems) {
              final product = item['products'];
              if (product != null) {
                totalPrice += (product['price'] * item['quantity']);
              }
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      final product = item['products'];

                      if (product == null) return const SizedBox.shrink();

                      return _buildCartItem(context, item, product);
                    },
                  ),
                ),
                _buildCheckoutBottomBar(context, totalPrice),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, dynamic cartItem, dynamic product) {
    final theme = Theme.of(context);
    final int cartId = cartItem['id'];
    final int quantity = cartItem['quantity'];

    // Ambil ID produk agar gambar bervariasi seperti di katalog
    final productId = product['id'] ?? 105;

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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              // 👇 SUDAH DIPERBAIKI: Menggunakan variabel $productId 👇
              imageUrl: (product['image_url'] != null && product['image_url'].toString().isNotEmpty)
                  ? product['image_url']
                  : 'https://picsum.photos/seed/${product['id']}/400',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 80,
                height: 80,
                color: theme.scaffoldBackgroundColor,
                child: const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 80,
                height: 80,
                color: theme.scaffoldBackgroundColor,
                child: const Icon(Icons.broken_image, color: Colors.grey, size: 30),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? 'Produk Tidak Dikenal',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatRupiah(product['price'] ?? 0),
                  style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove, size: 16, color: theme.colorScheme.onSurface),
                            onPressed: quantity > 1
                                ? () => context.read<CartBloc>().add(UpdateQuantityRequested(cartId: cartId, newQuantity: quantity - 1))
                                : null,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                          Text('$quantity', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                          IconButton(
                            icon: Icon(Icons.add, size: 16, color: theme.colorScheme.onSurface),
                            onPressed: () {
                              context.read<CartBloc>().add(UpdateQuantityRequested(cartId: cartId, newQuantity: quantity + 1));
                            },
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        context.read<CartBloc>().add(RemoveFromCartRequested(cartId: cartId));
                      },
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBottomBar(BuildContext context, double totalPrice) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total Belanja', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  _formatRupiah(totalPrice),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: theme.colorScheme.onSurface),
                ),
              ],
            ),

            ElevatedButton(
              onPressed: totalPrice > 0 ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider(
                      create: (context) => OrderBloc(OrderRepositoryImpl(Supabase.instance.client)),
                      child: const CheckoutPage(),
                    ),
                  ),
                );
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('CHECKOUT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}