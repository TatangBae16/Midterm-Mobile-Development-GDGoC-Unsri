import 'dart:ui'; // 👇 Wajib ditambah untuk efek blur kaca
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:md_midtermproject/core/utils/biometric_helper.dart';

import '../../../admin/presentation/pages/admin_dashboard_page.dart';
import '../../../home/presentation/pages/main_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ ${state.message}'), backgroundColor: Colors.red),
                );
              } else if (state is Authenticated) {
                if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
                  SharedPreferences.getInstance().then((prefs) {
                    prefs.setString('saved_email', _emailController.text.trim());
                    prefs.setString('saved_password', _passwordController.text.trim());
                  });
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Login Berhasil!'), backgroundColor: Colors.green),
                );

                if (state.profile.role == 'admin') {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
                        (route) => false,
                  );
                } else {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainPage()),
                        (route) => false,
                  );
                }
              }
            },
            builder: (context, state) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Tingkat keburaman kaca
                      child: Container(
                        padding: const EdgeInsets.all(32.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05), // Warna dasar kaca (sangat transparan)
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5), // Pantulan cahaya di ujung kaca
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.15),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_person_rounded, size: 80, color: Color(0xFF36ADA3)),
                            const SizedBox(height: 16),
                            const Text(
                              'GearShift Login',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
                            ),
                            const Text(
                              'Welcome Back',
                              style: TextStyle(fontSize: 16, color: Colors.white70),
                            ),
                            const SizedBox(height: 32),

                            // Input Email
                            TextField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF36ADA3)),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.2), // Latar belakang kolom ketik
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(color: Colors.transparent),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(color: Color(0xFF36ADA3), width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Input Password
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF36ADA3)),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.2),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(color: Colors.transparent),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(color: Color(0xFF36ADA3), width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Tombol Login Manual
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: state is AuthLoading
                                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF36ADA3)))
                                  : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF36ADA3),
                                  elevation: 5,
                                  shadowColor: const Color(0xFF36ADA3).withOpacity(0.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                ),
                                onPressed: () {
                                  context.read<AuthBloc>().add(
                                    LoginRequested(_emailController.text.trim(), _passwordController.text.trim()),
                                  );
                                },
                                child: const Text('MASUK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // TOMBOL GOOGLE SIGN-IN
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.white.withOpacity(0.5)),
                                  backgroundColor: Colors.white.withOpacity(0.05),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                ),
                                icon: Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                  height: 24,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: Colors.white, size: 30),
                                ),
                                label: const Text('Masuk dengan Google', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                onPressed: () {
                                  context.read<AuthBloc>().add(GoogleSignInRequested());
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Tombol Register
                            TextButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
                              },
                              child: const Text('Belum punya akun? Daftar di sini', style: TextStyle(color: Colors.white)),
                            ),

                            // ==========================================
                            // BLOK UI AUTENTIKASI BIOMETRIK (SIDIK JARI)
                            // ==========================================
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Divider(color: Colors.white24, thickness: 1),
                            ),
                            const Text('Atau masuk cepat dengan', style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 8),

                            state is AuthLoading
                                ? const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: Color(0xFF36ADA3)))
                                : IconButton(
                              iconSize: 55,
                              icon: const Icon(Icons.fingerprint, color: Color(0xFF36ADA3)),
                              onPressed: () async {
                                final biometricHelper = BiometricHelper();
                                final isAuthenticated = await biometricHelper.authenticate();

                                if (!context.mounted) return;

                                if (isAuthenticated) {
                                  final prefs = await SharedPreferences.getInstance();
                                  final savedEmail = prefs.getString('saved_email');
                                  final savedPassword = prefs.getString('saved_password');

                                  if (savedEmail != null && savedEmail.isNotEmpty && savedPassword != null && savedPassword.isNotEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⏳ Memproses login...'), backgroundColor: Color(0xFF36ADA3)));
                                    context.read<AuthBloc>().add(LoginRequested(savedEmail, savedPassword));
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Gagal: Login manual dulu 1 kali.'), backgroundColor: Colors.orange));
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Autentikasi dibatalkan.'), backgroundColor: Colors.red));
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}