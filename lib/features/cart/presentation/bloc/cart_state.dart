import 'package:equatable/equatable.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<dynamic> cartItems;

  const CartLoaded(this.cartItems);

  // KUNCI EFISIENSI: Flutter sekarang bisa membandingkan isi List ini.
  // Jika isinya persis sama, proses re-render akan dibatalkan secara otomatis!
  @override
  List<Object?> get props => [cartItems];
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}