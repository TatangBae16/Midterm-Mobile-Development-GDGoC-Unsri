import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../main.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../../wishlist/presentation/pages/wishlist_page.dart';
import '../../data/models/product_model.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_state.dart';
import '../bloc/product_event.dart';
import '../widgets/product_shimmer.dart';
import 'product_detail_page.dart';
import '../bloc/quantity_bloc.dart';
import '../../../cart/presentation/pages/cart_page.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  // Deklarasi Controller dan Timer untuk fitur pencarian
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Daftar Kategori dan Status Aktif
  final List<String> categories = [
    'Semua', 'Mesin', 'Pengabutan', 'Transmisi',
    'Kelistrikan', 'Pengereman', 'Kaki-kaki', 'Pelumas', 'Aksesoris'
  ];
  String selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    // Panggil event pertama kali dengan kategori 'Semua'
    context.read<ProductBloc>().add(const FetchProductsEvent(category: 'Semua'));
    context.read<CartBloc>().add(FetchCartRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Fungsi pencarian pintar (Debounce)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Kirim query pencarian DAN kategori yang sedang aktif
      context.read<ProductBloc>().add(FetchProductsEvent(
          query: query,
          category: selectedCategory
      ));
    });
  }

  String _formatRupiah(num number) {
    return 'Rp ${number.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
              'GearShift Catalog',
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)
          ),
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          iconTheme: theme.iconTheme,
          actions: [
            IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WishlistPage()),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20.0, top: 4.0),
              child: BlocBuilder<CartBloc, CartState>(
                builder: (context, state) {
                  int cartItemCount = 0;

                  if (state is CartLoaded) {
                    cartItemCount = state.cartItems.length;
                  }

                  if (cartItemCount == 0) {
                    return IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined, size: 28),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage())),
                    );
                  }

                  return Badge(
                    label: Text(
                        '$cartItemCount',
                        style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined, size: 28),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage())),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // SEARCH BAR COMPONENT
            // ==========================================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Cari komponen (Cth: Piston, Rantai...)',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                      setState(() {});
                    },
                  )
                      : null,
                  filled: true,
                  fillColor: theme.cardColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: theme.primaryColor, width: 2),
                  ),
                ),
              ),
            ),

            // ==========================================
            // FILTER KATEGORI (HORIZONTAL SCROLL)
            // ==========================================
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category;

                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                        // Panggil BLoC dengan kategori baru & query pencarian yang mungkin sedang aktif
                        context.read<ProductBloc>().add(FetchProductsEvent(
                            query: _searchController.text,
                            category: category
                        ));
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.primaryColor : theme.cardColor,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected
                                ? theme.primaryColor
                                : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            category,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // ==========================================

            // ==========================================
            // GRID PRODUK
            // ==========================================
            Expanded(
              child: BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state is ProductLoading || state is ProductInitial) {
                    return _buildGrid(itemCount: 6, itemBuilder: (_, __) => const ProductShimmer());
                  } else if (state is ProductLoaded) {
                    if (state.products.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text('Komponen tidak ditemukan', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                          ],
                        ),
                      );
                    }

                    return _buildGrid(
                      itemCount: state.products.length,
                      itemBuilder: (context, index) => _buildProductCard(context, state.products[index]),
                    );
                  } else if (state is ProductError) {
                    return Center(child: Text('Gagal memuat katalog: ${state.message}'));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid({required int itemCount, required Widget Function(BuildContext, int) itemBuilder}) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16), // Padding atas/bawah dikurangi agar dekat dengan kategori
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => QuantityBloc(),
            child: ProductDetailPage(product: product),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
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
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl.isNotEmpty
                      ? product.imageUrl
                      : 'https://picsum.photos/seed/${product.id}/400',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatRupiah(product.price),
                    style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}