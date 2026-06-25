import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:shared_preferences/shared_preferences.dart';

// --- Imports fitur ---
import 'core/network/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/presentation/pages/admin_dashboard_page.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/home/presentation/pages/main_page.dart';
import 'features/order/data/repositories/order_repository_impl.dart';
import 'features/order/presentation/bloc/order_bloc.dart';
import 'features/product/presentation/bloc/product_bloc.dart';
import 'features/product/presentation/bloc/product_event.dart';
import 'features/product/presentation/pages/catalog_page.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/cart/data/repositories/cart_repository_impl.dart';
import 'features/product/data/repositories/product_repository_impl.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/wishlist/data/repositories/wishlist_repository_impl.dart';
import 'features/wishlist/presentation/bloc/wishlist_bloc.dart';

// Pastikan ini diletakkan di paling atas, di luar class MyApp
ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      publishableKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );


    // 2. Ambil preferensi tema yang disimpan terakhir kali
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_mode') ?? false;
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

    runApp(const MyApp());
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text("🚨 Gagal Menyalakan Mesin:\n$e", style: const TextStyle(color: Colors.red))),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final orderRepository = OrderRepositoryImpl(Supabase.instance.client);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ProductBloc(
            repository: ProductRepositoryImpl(dioClient: DioClient()),
          )..add(FetchProductsEvent()),
        ),
        BlocProvider(
          create: (context) => AuthBloc(authRepository: AuthRepository())
            ..add(AuthCheckRequested()),
        ),
        BlocProvider(
          create: (context) => CartBloc(
            repository: CartRepositoryImpl(dioClient: DioClient()),
          ),
        ),
        BlocProvider(
          create: (context) => WishlistBloc(WishlistRepositoryImpl(Supabase.instance.client)),
        ),
        BlocProvider<OrderBloc>(
          create: (context) => OrderBloc(orderRepository),
          // Pastikan 'orderRepository' sudah didefinisikan/di-inject sebelumnya
        ),
      ],

      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentMode, _) {
          return MaterialApp(
            title: 'GearShift',
            debugShowCheckedModeBanner: false,
            themeMode: currentMode,

            // 2. Panggil file tema khusus secara ringkas di sini:
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,

            home: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                // 1. Aplikasi baru bangun tidur, sedang ngecek database
                if (state is AuthInitial || state is AuthLoading) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                // 2. Berhasil tahu siapa yang login
                else if (state is Authenticated) {
                  // Ambil data role-nya dari profil yang berhasil didapatkan BLoC
                  final role = state.profile.role;

                  if (role == 'admin') {
                    return const AdminDashboardPage(); // Jalur khusus Admin
                  } else {
                    return const MainPage(); // Jalur khusus User biasa
                  }
                }
                // 3. Kalau belum login, lempar ke halaman login
                return const SplashPage();
              },
            ),
          );
        },
      ),
    );
  }
}