import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/wishlist_repository.dart';
import 'wishlist_event.dart';
import 'wishlist_state.dart';

class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  final WishlistRepository repository;

  WishlistBloc(this.repository) : super(WishlistInitial()) {

    // Fungsi memuat semua daftar wishlist
    on<FetchWishlist>((event, emit) async {
      emit(WishlistLoading());
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final items = await repository.getWishlist(userId);
        emit(WishlistLoaded(items));
      } catch (e) {
        emit(WishlistError(e.toString()));
      }
    });

    // Fungsi mengecek status 1 produk (untuk ikon Hati)
    on<CheckWishlistStatus>((event, emit) async {
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final isWishlisted = await repository.checkIsWishlisted(userId, event.productId);
        emit(WishlistStatusLoaded(isWishlisted));
      } catch (_) {
        emit(const WishlistStatusLoaded(false));
      }
    });

    // Fungsi klik tombol Hati (Toggle)
    on<ToggleWishlistEvent>((event, emit) async {
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final newStatus = await repository.toggleWishlist(userId, event.productId);

        // Perbarui state ikon hati ke status yang baru
        emit(WishlistStatusLoaded(newStatus));
      } catch (e) {
        emit(WishlistError(e.toString()));
      }
    });
  }
}