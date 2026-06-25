import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/models/product_model.dart';
import '../bloc/quantity_bloc.dart';
import '../bloc/quantity_event.dart';
import '../bloc/quantity_state.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';

// 👇 IMPORT BLOC WISHLIST 👇
import '../../../wishlist/presentation/bloc/wishlist_bloc.dart';
import '../../../wishlist/presentation/bloc/wishlist_event.dart';
import '../../../wishlist/presentation/bloc/wishlist_state.dart';

class ProductDetailPage extends StatefulWidget {
  final ProductModel product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  @override
  void initState() {
    super.initState();
    // Mengecek status Wishlist saat halaman Detail Produk dibuka
    context.read<WishlistBloc>().add(CheckWishlistStatus(widget.product.id));
  }

  String _formatRupiah(num number) {
    return 'Rp ${number.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // 1. HEADER DINAMIS
          SliverAppBar(
            expandedHeight: 400.0,
            pinned: true,
            elevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: CircleAvatar(
                backgroundColor: Colors.black38,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // 👇 WISH LIST COMPONENT (IKON HATI) DI SINI 👇
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black38,
                  child: BlocBuilder<WishlistBloc, WishlistState>(
                    builder: (context, state) {
                      bool isFavorite = false;

                      if (state is WishlistStatusLoaded) {
                        isFavorite = state.isWishlisted;
                      }

                      return IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          // Picu event toggle (Like / Unlike)
                          context.read<WishlistBloc>().add(ToggleWishlistEvent(widget.product.id));

                          // Notifikasi visual kecil untuk user
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isFavorite
                                  ? '💔 Dihapus dari Wishlist'
                                  : '❤️ Ditambahkan ke Wishlist'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: isFavorite ? Colors.red[100] : Colors.green[100],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
            // ==========================================

            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Hero(
                tag: 'piston-hero-${widget.product.id}',
                child: CachedNetworkImage(
                  // Mengubah ID Gambar agar dinamis sesuai ID produk
                  imageUrl: widget.product.imageUrl.isNotEmpty
                      ? widget.product.imageUrl
                      : 'https://picsum.photos/seed/${widget.product.id}/400',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: theme.cardColor,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: theme.cardColor,
                    child: const Icon(Icons.broken_image, color: Colors.grey, size: 100),
                  ),
                ),
              ),
            ),
          ),

          // 2. KONTEN DETAIL PRODUK
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.primaryColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          'Stok: ${widget.product.stock ?? 10}',
                          style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatRupiah(widget.product.price),
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Spesifikasi Teknis',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.product.description,
                    style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        height: 1.6
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // 3. AREA TOMBOL QUANTITY & KERANJANG
      bottomNavigationBar: BlocBuilder<QuantityBloc, QuantityState>(
        builder: (context, state) {
          final maxStock = widget.product.stock ?? 10;

          return Container(
            color: theme.cardColor,
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 16),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jumlah Pembelian',
                        style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => context.read<QuantityBloc>().add(DecrementQuantity()),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: state.value > 1 ? theme.primaryColor : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.remove, color: state.value > 1 ? Colors.white : Colors.grey, size: 20),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              '${state.value}',
                              style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => context.read<QuantityBloc>().add(IncrementQuantity(maxStock)),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: state.value < maxStock ? theme.primaryColor : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.add, color: state.value < maxStock ? Colors.white : Colors.grey, size: 20),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        context.read<CartBloc>().add(
                          AddToCartRequested(
                            productId: widget.product.id,
                            quantity: state.value,
                          ),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ ${state.value} buah ${widget.product.name} berhasil ditambahkan ke keranjang!'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );

                        Navigator.pop(context);
                      },
                      child: Text(
                        'Tambah ke Keranjang - ${_formatRupiah(widget.product.price * state.value)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}