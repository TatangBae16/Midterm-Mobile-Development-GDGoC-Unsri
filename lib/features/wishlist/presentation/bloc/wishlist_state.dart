import 'package:equatable/equatable.dart';

abstract class WishlistState extends Equatable {
  const WishlistState();

  @override
  List<Object?> get props => [];
}

class WishlistInitial extends WishlistState {}
class WishlistLoading extends WishlistState {}

// State untuk halaman daftar Wishlist
class WishlistLoaded extends WishlistState {
  final List<dynamic> wishlists;
  const WishlistLoaded(this.wishlists);

  @override
  List<Object?> get props => [wishlists];
}

// State untuk status ikon Hati (menyala atau mati) di halaman Detail
class WishlistStatusLoaded extends WishlistState {
  final bool isWishlisted;
  const WishlistStatusLoaded(this.isWishlisted);

  @override
  List<Object?> get props => [isWishlisted];
}

class WishlistError extends WishlistState {
  final String message;
  const WishlistError(this.message);

  @override
  List<Object?> get props => [message];
}