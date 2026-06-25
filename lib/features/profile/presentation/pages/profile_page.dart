import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../main.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Memicu pengambilan data profil pertama kali saat halaman dibuka
    context.read<ProfileBloc>().add(LoadProfile());
  }

  // Fungsi untuk Memilih dan Mengunggah Foto melalui BLoC
  Future<void> _uploadFotoProfil(String userId) async {
    final picker = ImagePicker();

    // 1. Buka galeri HP
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return; // Batal pilih foto

    final bytes = await image.readAsBytes();
    final fileExt = image.path.split('.').last;

    if (mounted) {
      // 2. Kirim data gambar ke BLoC untuk diproses oleh Repository
      context.read<ProfileBloc>().add(UploadAvatar(userId, fileExt, bytes));
    }
  }

  // Fungsi untuk memunculkan dialog input alamat
  void _editAlamat(String alamatSekarang) {
    final TextEditingController alamatController = TextEditingController(
        text: alamatSekarang == 'Belum diatur' ? '' : alamatSekarang
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
              'Edit Alamat Pengiriman',
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)
          ),
          content: TextField(
            controller: alamatController,
            maxLines: 3,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Alamat Lengkap',
              labelStyle: const TextStyle(color: Colors.grey),
              hintText: 'Contoh: Jl. Jenderal Sudirman No. 123, Palembang',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primaryColor, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final newAddress = alamatController.text.trim();
                if (newAddress.isNotEmpty) {
                  Navigator.pop(dialogContext); // Tutup dialog input
                  // Kirim data alamat baru ke BLoC
                  context.read<ProfileBloc>().add(UpdateAddress(newAddress));
                }
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          // Menampilkan pesan sukses dari BLoC (misal saat sukses ganti foto/alamat)
          if (state is ProfileActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
          }
          // Menampilkan pesan error dari BLoC
          else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          // Menampilkan indikator loading saat mengambil data atau mengunggah
          if (state is ProfileLoading) {
            return Center(child: CircularProgressIndicator(color: theme.primaryColor));
          }

          if (state is ProfileLoaded) {
            final user = state.user;

            final userName = user.userMetadata?['full_name'] ?? 'Pengguna GearShift';
            final userEmail = user.email ?? 'pengguna@email.com';
            final avatarUrl = user.userMetadata?['avatar_url'];
            final userAddress = user.userMetadata?['address'] ?? 'Belum diatur';

            final isDark = theme.brightness == Brightness.dark;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Info Pengguna
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
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
                      GestureDetector(
                        onTap: () => _uploadFotoProfil(user.id),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: theme.primaryColor.withOpacity(0.2),
                              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                              child: avatarUrl == null
                                  ? Icon(Icons.person, size: 40, color: theme.primaryColor)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userEmail,
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text('Alamat Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.location_on, color: theme.primaryColor),
                  title: Text('Rumah', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                  subtitle: Text(userAddress, style: const TextStyle(color: Colors.grey)),
                  trailing: const Icon(Icons.edit, size: 18, color: Colors.grey),
                  onTap: () => _editAlamat(userAddress),
                ),
                const Divider(height: 32),

                const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),

                // 🌗 TOMBOL DARK MODE
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                      theme.brightness == Brightness.dark ? Icons.dark_mode : Icons.light_mode,
                      color: theme.colorScheme.onSurface
                  ),
                  title: Text('Mode Gelap', style: TextStyle(color: theme.colorScheme.onSurface)),
                  trailing: Switch(
                    value: theme.brightness == Brightness.dark,
                    onChanged: (bool isDark) {
                      themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.setBool('is_dark_mode', isDark);
                      });
                    },
                    activeColor: theme.primaryColor,
                  ),
                ),

                // 🚪 TOMBOL LOGOUT
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Keluar (Logout)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) Navigator.pop(context);

                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                              (route) => false,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal Logout: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}