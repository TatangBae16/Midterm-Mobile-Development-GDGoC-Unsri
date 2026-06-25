import 'package:equatable/equatable.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class FetchCartRequested extends CartEvent {}

class AddToCartRequested extends CartEvent {
  final int productId;
  final int quantity;

  const AddToCartRequested({required this.productId, this.quantity = 1});

  @override
  List<Object?> get props => [productId, quantity];
}

class UpdateQuantityRequested extends CartEvent {
  final int cartId;
  final int newQuantity;

  const UpdateQuantityRequested({required this.cartId, required this.newQuantity});

  @override
  List<Object?> get props => [cartId, newQuantity];
}

class RemoveFromCartRequested extends CartEvent {
  final int cartId;

  const RemoveFromCartRequested({required this.cartId});

  @override
  List<Object?> get props => [cartId];
}

class CheckoutRequested extends CartEvent {}
class ClearCartRequested extends CartEvent {}