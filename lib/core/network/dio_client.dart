import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    // 1. Membaca URL dan Key dari file .env
    final String rawUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final String anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    // FIX 404: Tambahkan /rest/v1 ke akhir URL dasar agar langsung menembus tabel database
    final String baseUrl = rawUrl.endsWith('/') ? '${rawUrl}rest/v1' : '$rawUrl/rest/v1';

    // 2. Konfigurasi Dasar Dio
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl, // Sekarang otomatis menjadi https://[proyek].supabase.co/rest/v1
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        responseType: ResponseType.json,
      ),
    );

    // 3. Menambahkan Interceptor (Syarat Wajib Supabase & Keamanan JWT)
    _dio.interceptors.add(
      InterceptorsWrapper(

        // ---------------------------------------------------------
        // A. SAAT REQUEST BERANGKAT (Suntik Headers & Token)
        // ---------------------------------------------------------
        onRequest: (options, handler) async {
          // Menyisipkan API Key & Accept secara otomatis
          options.headers['apikey'] = anonKey;
          options.headers['Accept'] = 'application/json';

          // Cek apakah user sedang login di aplikasi
          final session = Supabase.instance.client.auth.currentSession;

          if (session != null && session.accessToken.isNotEmpty) {
            // Jika sudah login, gunakan Token JWT Asli milik user tersebut
            options.headers['Authorization'] = 'Bearer ${session.accessToken}';
          } else {
            // Jika belum login (misal saat buka halaman Register/Login), gunakan Anon Key
            options.headers['Authorization'] = 'Bearer $anonKey';
          }

          return handler.next(options); // Lanjutkan request ke internet
        },

        // ---------------------------------------------------------
        // B. SAAT MENERIMA RESPONSE NORMAL
        // ---------------------------------------------------------
        onResponse: (response, handler) {
          return handler.next(response);
        },

        // ---------------------------------------------------------
        // C. SAAT TERJADI ERROR (Sistem Auto-Renew Token JWT)
        // ---------------------------------------------------------
        onError: (DioException e, handler) async {
          // Jika server menolak karena Token Basi / Kedaluwarsa (401 Unauthorized)
          if (e.response?.statusCode == 401) {
            try {
              // Diam-diam minta token JWT baru ke Supabase di belakang layar
              final AuthResponse res = await Supabase.instance.client.auth.refreshSession();
              final String? newToken = res.session?.accessToken;

              if (newToken != null) {
                print('🔄 [JWT Interceptor] Berhasil memperbarui token yang kedaluwarsa!');

                // Perbarui header request lama dengan token yang baru
                e.requestOptions.headers['Authorization'] = 'Bearer $newToken';

                // Kloning request yang tadi ditolak, lalu tembak ulang!
                final cloneReq = await _dio.fetch(e.requestOptions);
                return handler.resolve(cloneReq); // Kembalikan seolah-olah tidak pernah ada error
              }
            } catch (refreshError) {
              // Jika token benar-benar mati (misal user diblokir/ganti password di device lain)
              print('❌ [JWT Interceptor] Sesi mati total, gagal perbarui token.');
              // Lanjutkan errornya agar UI (BlocListener) bisa menendang user ke halaman Login
              return handler.next(e);
            }
          }

          // Jika errornya bukan masalah token (misal offline atau 404), biarkan lewat
          return handler.next(e);
        },
      ),
    );
  }

  // Getter untuk memanggil instance Dio dari luar
  Dio get dio => _dio;
}