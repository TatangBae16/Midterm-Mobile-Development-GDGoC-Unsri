# 🏍️ GearShift - E-Commerce Komponen Otomotif

**GearShift** adalah aplikasi *mobile* berbasis Flutter yang dirancang untuk memudahkan mekanik dan penggemar otomotif dalam mencari, mendiagnosa, dan membeli komponen mesin sepeda motor secara cepat dan akurat.

Proyek ini dibangun menggunakan pendekatan **Feature-First Clean Architecture** yang dikombinasikan dengan pola **BLoC (Business Logic Component)** untuk *state management*, serta **Supabase** sebagai *backend-as-a-service* (BaaS).

---

## 📑 Daftar Isi
1. [Fitur Utama](#-fitur-utama)
2. [Teknologi & Arsitektur](#-teknologi--arsitektur)
3. [Struktur Folder Lengkap](#-struktur-folder-lengkap)
4. [Dokumentasi API](#-dokumentasi-api--backend)
5. [Cara Menjalankan Proyek](#-cara-menjalankan-proyek)
6. [Cuplikan Aplikasi](#-cuplikan-aplikasi-screenshots)
7. [Standar Kontribusi](#-standar-kontribusi-conventional-commits)

---

## ✨ Fitur Utama

Aplikasi GearShift memiliki berbagai fitur fungsional yang mensimulasikan platform *e-commerce* dunia nyata:

* **🔐 Keamanan & Otentikasi**
    * Terintegrasi dengan **Google Sign-In** dan **Supabase Auth**.
    * Dilengkapi modul *Biometric Helper* untuk dukungan keamanan tambahan.
    * *Splash Screen* dengan animasi transisi *gradient* yang mulus.
* **📦 Katalog & Detail Produk**
    * Menampilkan etalase suku cadang secara *real-time*.
    * Dilengkapi **Shimmer Effect** saat memuat data agar UI terasa responsif.
    * Halaman spesifikasi detail dengan pengaturan *Quantity* (jumlah barang) menggunakan BLoC.
* **❤️ Wishlist Interaktif**
    * Penyimpanan daftar komponen impian menggunakan *query* relasi database (`*, products(*)`).
    * Kartu *wishlist* dapat diklik dan memiliki tombol aksi cepat (Hapus atau Pindahkan langsung ke Keranjang).
* **🛒 Keranjang Belanja Pintar (Smart Cart)**
    * **Logika Upsert:** Otomatis menggabungkan (*update quantity*) barang yang sama, atau membuat baris baru (*insert*) jika barang belum ada.
    * **Offline Support:** Menyimpan status keranjang belanja terakhir di memori lokal menggunakan `SharedPreferences`.
* **💳 Checkout & Manajemen Pesanan**
    * Pemotongan stok otomatis di *database* pusat saat proses *checkout* berhasil.
    * Perekaman dan tampilan Riwayat Transaksi (*Order History*).
* **🛡️ Panel Admin Khusus**
    * Terdapat fitur *dashboard* admin untuk menambah atau mengedit stok dan produk ke dalam sistem.

---

## 🛠️ Teknologi & Arsitektur

* **Framework:** Flutter (Dart)
* **State Management:** `flutter_bloc` & `equatable`
* **Backend:** Supabase (PostgreSQL)
* **Networking (REST API):** `dio`
* **Local Storage:** `shared_preferences`
* **Image Caching:** `cached_network_image`
* **Design Pattern:** Feature-First Clean Architecture

---

## 📂 Struktur Folder Lengkap

Berikut adalah pohon struktur direktori lengkap dari pengerjaan proyek **md_midtermproject**:

```text
md_midtermproject/
├── assets/
│   └── images/
│       ├── Logoku.png                     # File logo utama aplikasi
│       └── Logoku1.png                    # Alternatif/variasi logo aplikasi
├── lib/
│   ├── core/                              # Komponen global (Shared/Reusable)
│   │   ├── config/                        # Pengaturan konfigurasi app
│   │   ├── constants/                     # Nilai konstan (Warna, teks statis, ukuran)
│   │   ├── error/                         # Penanganan error (Exceptions & Failures)
│   │   ├── network/
│   │   │   └── dio_client.dart            # HTTP Client menggunakan Dio
│   │   ├── security/                      # Keamanan data tambahan
│   │   ├── theme/
│   │   │   └── app_theme.dart             # Konfigurasi ThemeData Terang/Gelap
│   │   └── utils/
│   │       ├── biometric_helper.dart      # Autentikasi Sidik Jari / FaceID
│   │       └── theme_helper.dart          # Helper manipulasi UI/Tema
│   │
│   ├── features/                          # Direktori Fitur Berbasis Modul
│   │   ├── admin/                         # Modul Pengelolaan Konten (Admin)
│   │   │   └── presentation/
│   │   │       └── pages/
│   │   │           ├── admin_dashboard_page.dart
│   │   │           └── form_product_page.dart
│   │   │
│   │   ├── auth/                          # Modul Keamanan & Sesi Pengguna
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── profile_model.dart
│   │   │   │   └── auth_repository.dart
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── auth_bloc.dart
│   │   │       │   ├── auth_event.dart
│   │   │       │   └── auth_state.dart
│   │   │       └── pages/
│   │   │           ├── login_page.dart
│   │   │           ├── register_page.dart
│   │   │           └── splash_page.dart
│   │   │
│   │   ├── cart/                          # Modul Manajemen Keranjang
│   │   │   ├── data/
│   │   │   │   └── repositories/
│   │   │   │       └── cart_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   └── repositories/
│   │   │   │       └── cart_repository.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── cart_bloc.dart
│   │   │       │   ├── cart_event.dart
│   │   │       │   └── cart_state.dart
│   │   │       └── pages/
│   │   │           └── cart_page.dart
│   │   │
│   │   ├── checkout/                      # Modul Transaksi Pembayaran
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       └── pages/
│   │   │           └── checkout_page.dart
│   │   │
│   │   ├── home/                          # Modul Navigasi Utama
│   │   │   └── presentation/
│   │   │       └── pages/
│   │   │           └── main_page.dart
│   │   │
│   │   ├── order/                         # Modul Riwayat Belanja
│   │   │   ├── data/
│   │   │   │   └── repositories/
│   │   │   │       └── order_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   └── repositories/
│   │   │   │       └── order_repository.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── order_bloc.dart
│   │   │       │   ├── order_event.dart
│   │   │       │   └── order_state.dart
│   │   │       └── pages/
│   │   │           └── order_history_page.dart
│   │   │
│   │   ├── product/                       # Modul Manajemen Suku Cadang
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── product_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── product_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   └── repositories/
│   │   │   │       └── product_repository.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── product_bloc.dart
│   │   │       │   ├── product_event.dart
│   │   │       │   ├── product_state.dart
│   │   │       │   ├── quantity_bloc.dart
│   │   │       │   ├── quantity_event.dart
│   │   │       │   └── quantity_state.dart
│   │   │       └── pages/
│   │   │           ├── catalog_page.dart
│   │   │           └── product_detail_page.dart
│   │   │       └── widgets/
│   │   │           └── product_shimmer.dart
│   │   │
│   │   ├── profile/                       # Modul Manajemen Akun Pengguna
│   │   │   ├── data/
│   │   │   │   └── repositories/
│   │   │   │       └── profile_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   └── repositories/
│   │   │   │       └── profile_repository.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── profile_bloc.dart
│   │   │       │   ├── profile_event.dart
│   │   │       │   └── profile_state.dart
│   │   │       └── pages/
│   │   │           └── profile_page.dart
│   │   │
│   │   └── wishlist/                      # Modul Barang Impian
│   │       ├── data/
│   │       │   └── repositories/
│   │       │       └── wishlist_repository_impl.dart
│   │       ├── domain/
│   │       │   └── repositories/
│   │       │       └── wishlist_repository.dart
│   │       └── presentation/
│   │           ├── bloc/
│   │           │   ├── wishlist_bloc.dart
│   │           │   ├── wishlist_event.dart
│   │           │   └── wishlist_state.dart
│   │           └── pages/
│   │               └── wishlist_page.dart
│   │
│   └── main.dart                          # Inisialisasi awal & Registrasi BLoC global
│
├── .env                                   # Konfigurasi lokal kredensial API (Hidden)
└── .gitignore                             # Daftar pengecualian upload git