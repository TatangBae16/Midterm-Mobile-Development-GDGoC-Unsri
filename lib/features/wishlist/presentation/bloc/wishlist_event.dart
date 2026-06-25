import 'package:equatable/equatable.dart';

abstract class WishlistEvent extends Equatable {
  const WishlistEvent();

  @override
  List<Object?> get props => [];
}

class FetchWishlist extends WishlistEvent {}

class CheckWishlistStatus extends WishlistEvent {
  final dynamic productId;
  const CheckWishlistStatus(this.productId);

  @override
  List<Object?> get props => [productId];
}

class ToggleWishlistEvent extends WishlistEvent {
  final dynamic productId;
  const ToggleWishlistEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}