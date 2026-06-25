import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:md_midtermproject/features/cart/domain/repositories/cart_repository.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  // DIP: Bekerja berdasarkan Abstraksi, BUKAN implementasi konkret
  final CartRepository repository;

  CartBloc({required this.repository}) : super(CartInitial()) {

    on<FetchCartRequested>((event, emit) async {
      emit(CartLoading());
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) throw Exception("User belum login");

        // BLoC sekarang bersih, ia hanya menyuruh repository mengambil data
        final items = await repository.fetchCartItems(user.id);
        emit(CartLoaded(items));
      } catch (e) {
        emit(CartError(e.toString()));
      }
    });

    on<AddToCartRequested>((event, emit) async {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) throw Exception("User belum login");

        await repository.addToCart(user.id, event.productId, event.quantity);
        add(FetchCartRequested()); // Segarkan keranjang
      } catch (e) {
        emit(CartError(e.toString()));
      }
    });

    on<UpdateQuantityRequested>((event, emit) async {
      // Kita cek apakah layar saat ini sedang menampilkan keranjang (CartLoaded)
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;

        // Buat duplikat dari daftar keranjang yang sekarang
        final updatedItems = List<Map<String, dynamic>>.from(
            currentState.cartItems.map((item) => Map<String, dynamic>.from(item))
        );

        // Cari posisi barang yang sedang dipencet tombol + atau - nya
        final index = updatedItems.indexWhere((item) => item['id'] == event.cartId);

        if (index != -1) {
          // Ubah kuantitasnya langsung di memori HP
          updatedItems[index]['quantity'] = event.newQuantity;

          // Pancarkan data terbaru ke layar SEKARANG JUGA (Tanpa loading!)
          emit(CartLoaded(updatedItems));
        }
      }

      // 2. PROSES BACKGROUND KE SUPABASE
      try {
        // Biarkan HP mengabari Supabase secara diam-diam di balik layar
        await repository.updateQuantity(event.cartId, event.newQuantity);


      } catch (e) {
        // Jika internet tiba-tiba putus, kembalikan error
        emit(CartError(e.toString()));
      }
    });

    on<RemoveFromCartRequested>((event, emit) async {
      try {
        await repository.removeFromCart(event.cartId);
        add(FetchCartRequested());
      } catch (e) {
        emit(CartError(e.toString()));
      }
    });

    on<CheckoutRequested>((event, emit) async {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) throw Exception("User belum login");

        // PRINT INI UNTUK BUKTI
        print("🚨 BLOC BERJALAN: Memanggil fungsi checkout!");

        await repository.checkout(user.id);

        add(FetchCartRequested());
      } catch (e) {
        emit(CartError(e.toString()));
      }
    });

    on<ClearCartRequested>((event, emit) async {
      emit(CartLoading());
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        // Hapus semua isi keranjang user ini di Supabase
        await Supabase.instance.client.from('carts').delete().eq('user_id', userId);
        emit(const CartLoaded([])); // Keranjang jadi kosong
      } catch (e) {
        emit(CartError(e.toString()));
      }
    });
  }
}