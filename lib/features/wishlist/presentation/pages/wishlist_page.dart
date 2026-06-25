import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../product/data/models/product_model.dart';
import '../../../product/presentation/bloc/quantity_bloc.dart';
import '../../../product/presentation/pages/product_detail_page.dart';
import '../bloc/wishlist_bloc.dart';
import '../bloc/wishlist_event.dart';
import '../bloc/wishlist_state.dart';
import 'package:shimmer/shimmer.dart';


class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  @override
  void initState() {
    super.initState();
    // Ambil data wishlist terbaru saat halaman dibuka
    context.read<WishlistBloc>().add(FetchWishlist());
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
        title: Text('Wishlist Saya', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: theme.iconTheme,
      ),
      body: BlocBuilder<WishlistBloc, WishlistState>(
        builder: (context, state) {
          if (state is WishlistLoading) {
            final isDark = theme.brightness == Brightness.dark;

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.70, // Sedikit disesuaikan agar muat tombol
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 6, // Tampilkan 6 kotak kosong yang berkedip
              itemBuilder: (context, index) {
                return Shimmer.fromColors(
                  baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  highlightColor: isDark ? Colors.grey.shade600 : Colors.grey.shade100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            );
          } else if (state is WishlistError) {
            return Center(child: Text('Gagal memuat: ${state.message}'));
          } else if (state is WishlistLoaded) {
            final items = state.wishlists;

            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border_rounded, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('Belum ada komponen impianmu', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68, // Sedikit diperpanjang agar tidak overflow
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final wishlistData = items[index];
                final product = wishlistData['products'];
                if (product == null) return const SizedBox.shrink();

                final isDark = theme.brightness == Brightness.dark;

                // MENGGUNAKAN CARD & INKWELL AGAR BISA DIKLIK
                return Card(
                  elevation: 8,
                  shadowColor: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.05),
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      final productModel = ProductModel.fromJson(product);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (context) => QuantityBloc(),
                            child: ProductDetailPage(product: productModel),
                          ),
                        ),
                      ).then((_) {
                        // Perintahkan BLoC untuk memuat ulang daftar wishlist
                        // saat pengguna menekan tombol Back dari halaman Detail
                        if (context.mounted) {
                          context.read<WishlistBloc>().add(FetchWishlist());
                        }
                      });
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Gambar Produk
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: CachedNetworkImage(
                              imageUrl: (product['image_url'] != null && product['image_url'].toString().isNotEmpty)
                                  ? product['image_url']
                                  : 'https://picsum.photos/seed/${product['id']}/400',
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // Detail Produk & Tombol Action
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'] ?? 'Komponen',
                                style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatRupiah(product['price'] ?? 0),
                                style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 12),

                              // DUA TOMBOL BARU: KERANJANG DAN HAPUS
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // 1. Tombol Tambah ke Keranjang
                                  GestureDetector(
                                    onTap: () {
                                      // 1. Panggil CartBloc untuk menambah ke keranjang
                                      context.read<CartBloc>().add(AddToCartRequested(productId: product['id']));

                                      // 2. Panggil WishlistBloc untuk MENGHAPUS barang ini dari wishlist
                                      context.read<WishlistBloc>().add(ToggleWishlistEvent(product['id']));

                                      // 3. Refresh data wishlist di layar agar kotaknya langsung hilang
                                      Future.delayed(const Duration(milliseconds: 300), () {
                                        if (context.mounted) {
                                          context.read<WishlistBloc>().add(FetchWishlist());
                                        }
                                      });

                                      // 4. Notifikasi
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${product['name']} ditambahkan ke keranjang!'),
                                          backgroundColor: theme.primaryColor,
                                          duration: const Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.add_shopping_cart, size: 18, color: Colors.green),
                                    ),
                                  ),

                                  // 2. Tombol Hapus dari Wishlist
                                  GestureDetector(
                                    onTap: () {
                                      context.read<WishlistBloc>().add(ToggleWishlistEvent(product['id']));
                                      Future.delayed(const Duration(milliseconds: 300), () {
                                        if (context.mounted) {
                                          context.read<WishlistBloc>().add(FetchWishlist());
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}