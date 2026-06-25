import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../home/presentation/pages/main_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

// TODO: Sesuaikan import halaman ini dengan letak file aslinya di projectmu
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Beri jeda visual 2 detik agar logonya sempat terlihat, lalu suruh BLoC cek sesi
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.read<AuthBloc>().add(AuthCheckRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      // Listener ini menunggu hasil cek sesi dari AuthBloc
      listener: (context, state) {
        if (state is Authenticated) {
          // Jika sudah login, lempar ke MainPage
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainPage()),
          );
        } else if (state is Unauthenticated || state is AuthError) {
          // Jika belum login atau error, lempar ke LoginPage
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      },
      child: Scaffold(
        // Scaffold tidak lagi menggunakan backgroundColor solid,
        // melainkan dibungkus Container dengan BoxDecoration di bawah ini
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F2027), // Tema gelap otomotif
                Color(0xFF203A43),
                Color(0xFF2C5364), // Warna paling gelap di sudut kanan bawah
                // Note: Kalau mau disamakan persis dengan LoginPage,
                // tinggal ganti ketiga kode Hex di atas ya!
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 👇 LOGO APLIKASI 👇
                Image.asset(
                  'assets/images/Logoku.png', // Sesuai dengan file gambarmu
                  width: 450,
                  height: 450,
                ),
                const SizedBox(height: 24),

                // 👇 NAMA APLIKASI 👇
                const Text(
                  'Powering Every Ride',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    // fontStyle: FontStyle.italic,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 40),

                // 👇 LOADING ANIMATOR 👇
                const CircularProgressIndicator(
                  color: Colors.white, // Diubah jadi putih agar kontras dengan gradient
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}