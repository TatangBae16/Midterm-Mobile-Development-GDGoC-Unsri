import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../main.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/pages/login_page.dart';

// 👇 TAMBAHKAN IMPORT BLOC PRODUK DI SINI 👇
import '../../../order/presentation/bloc/order_bloc.dart';
import '../../../order/presentation/bloc/order_event.dart';
import '../../../order/presentation/bloc/order_state.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/presentation/bloc/product_event.dart';
import '../../../product/presentation/bloc/product_state.dart';
import 'form_product_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          bottom: TabBar(
            labelColor: theme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.primaryColor,
            tabs: const [
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Kelola Komponen'),
              Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Semua Transaksi'),
            ],
          ),
          actions: [
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, _) {
                final isDark = currentMode == ThemeMode.dark;
                return IconButton(
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: isDark ? Colors.amber : Colors.grey),
                  onPressed: () async {
                    final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
                    themeNotifier.value = newMode;

                    // Simpan preferensi ke memori HP
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('is_dark_mode', newMode == ThemeMode.dark);
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () {
                context.read<AuthBloc>().add(LogoutRequested());
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                );
              },
            )
          ],
        ),
        body: const TabBarView(
          children: [
            _ManageProductsTab(),
            _AllTransactionsTab(),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// KONTEN TAB 1: KELOLA PRODUK (CRUD ADMIN)
// ==========================================
class _ManageProductsTab extends StatefulWidget {
  const _ManageProductsTab();

  @override
  State<_ManageProductsTab> createState() => _ManageProductsTabState();
}

class _ManageProductsTabState extends State<_ManageProductsTab> {
  // Variabel untuk fitur Search & Filter
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  Timer? _debounce;

  final List<String> _categories = ['Semua', 'Mesin', 'Pengabutan', 'Transmisi',
    'Kelistrikan', 'Pengereman', 'Kaki-kaki', 'Pelumas', 'Aksesoris'];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // Fungsi memanggil BLoC dengan parameter saat ini
  void _fetchData() {
    context.read<ProductBloc>().add(FetchProductsEvent(
      query: _searchQuery.isNotEmpty ? _searchQuery : null,
      category: _selectedCategory,
    ));
  }

  // Fungsi pencarian dengan penundaan (Debounce) agar aman untuk server
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      _fetchData();
    });
  }

  String _formatRupiah(num number) {
    return 'Rp ${number.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Komponen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FormProductPage()),
          );
        },
      ),
      body: Column(
        children: [
          // --- 1. SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari komponen (Cth: Piston, Busi)...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // --- 2. KATEGORI FILTER CHIPS ---
          SizedBox(
            height: 55,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(category, style: TextStyle(color: isSelected ? Colors.white : theme.colorScheme.onSurface)),
                    selected: isSelected,
                    selectedColor: theme.primaryColor,
                    backgroundColor: theme.cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                        _fetchData();
                      }
                    },
                  ),
                );
              },
            ),
          ),

          const Divider(height: 10),

          // --- 3. DAFTAR KOMPONEN (BLOC BUILDER) ---
          Expanded(
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading || state is ProductInitial) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ProductLoaded) {
                  final products = state.products;

                  if (products.isEmpty) {
                    return const Center(child: Text('Komponen tidak ditemukan.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16).copyWith(bottom: 80),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];

                      return Card(
                        color: theme.cardColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.build_circle_outlined, color: theme.primaryColor),
                          ),
                          title: Text(
                            product.name,
                            style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(_formatRupiah(product.price), style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w600)),
                              Text('Stok: ${product.stock ?? 0} | Kategori: ${product.category ?? "Uncategorized"}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => FormProductPage(product: product)),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: theme.cardColor,
                                      title: const Text('Hapus Komponen?'),
                                      content: Text('Apakah Anda yakin ingin menghapus "${product.name}"?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            context.read<ProductBloc>().add(DeleteProductEvent(product.id));
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Komponen dihapus!'), backgroundColor: Colors.red));
                                          },
                                          child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else if (state is ProductError) {
                  return Center(child: Text('Gagal memuat produk: ${state.message}'));
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// KONTEN TAB 2: PANTAU SEMUA TRANSAKSI
// 1. Ini class "Induk"
class _AllTransactionsTab extends StatefulWidget {
  const _AllTransactionsTab();

  @override
  State<_AllTransactionsTab> createState() => _AllTransactionsTabState();
}

// 2. Ini class "Anak"
class _AllTransactionsTabState extends State<_AllTransactionsTab> {
  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(FetchAllOrders());
  }

  // Helper untuk format Rupiah
  String _formatRupiah(num number) {
    return 'Rp ${number.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // 👇 HELPER BARU UNTUK WARNA STATUS 👇
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'payment success':
      case 'settlement':
      case 'success':
        return Colors.green;
      case 'pending payment':
      case 'pending':
        return Colors.orange;
      case 'cancelled':
      case 'cancel':
      case 'expire':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is OrderLoaded) {
          final orders = state.orders;

          if (orders.isEmpty) {
            return const Center(child: Text("Belum ada transaksi sama sekali."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final items = (order['items_json'] as List<dynamic>? ?? []);
              final String userName = order['profiles'] != null
                  ? order['profiles']['full_name']
                  : 'User Tanpa Nama';

              // Ambil status untuk pewarnaan
              final String orderStatus = order['status'] ?? 'Unknown';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text("ID: ${order['id']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  // 👇 SUBTITLE DIUBAH AGAR BISA WARNA-WARNI 👇
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("User ID: ${order['user_id']}"),
                        Text("Total: ${_formatRupiah(order['total_price'])}"),
                        Row(
                          children: [
                            const Text("Status: "),
                            Text(
                              orderStatus,
                              style: TextStyle(
                                color: _getStatusColor(orderStatus),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.info_outline),
                  onTap: () => _showOrderDetail(context, order, items),
                ),
              );
            },
          );
        } else if (state is OrderError) {
          return Center(child: Text("Error: ${state.message}"));
        }
        return const SizedBox();
      },
    );
  }

  void _showOrderDetail(BuildContext context, Map<String, dynamic> order, List<dynamic> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Detail Pesanan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              Text("User ID: ${order['user_id']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text("Nama User: ${order['profiles']['full_name']}"),
              Text("Alamat: ${order['shipping_address'] ?? '-'}"),
              const SizedBox(height: 10),
              const Text("Barang Dibeli:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final product = item['products'];
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.build, color: Theme.of(context).primaryColor),
                      title: Text(product['name'] ?? 'Barang'),
                      subtitle: Text("Jumlah: ${item['quantity']}"),
                      trailing: Text(_formatRupiah(product['price'] * (item['quantity'] ?? 1))),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}