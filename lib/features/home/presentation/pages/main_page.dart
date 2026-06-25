import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:md_midtermproject/features/profile/presentation/pages/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../order/data/repositories/order_repository_impl.dart';
import '../../../order/presentation/bloc/order_bloc.dart';
import '../../../order/presentation/pages/order_history_page.dart';
import '../../../product/presentation/pages/catalog_page.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  // Daftar halaman yang akan ditampilkan
  final List<Widget> _pages = [
    const CatalogPage(),

    BlocProvider(
      create: (context) => OrderBloc(
        OrderRepositoryImpl(Supabase.instance.client),
      ),
      child: const OrderHistoryPage(),
    ),

    BlocProvider(
      create: (context) => ProfileBloc(ProfileRepositoryImpl(Supabase.instance.client)),
      child: const ProfilePage(),
    ),

    const ProfilePage(), // Placeholder
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: theme.cardColor,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: theme.primaryColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront_rounded),
              label: 'Katalog',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}