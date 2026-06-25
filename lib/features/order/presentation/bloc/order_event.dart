import 'package:equatable/equatable.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class FetchOrderHistory extends OrderEvent {
  final String userId;
  const FetchOrderHistory(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ProcessCheckout extends OrderEvent {
  final String userId;
  final String userName;
  final String userEmail;
  final String userAddress;
  final num totalPrice;
  final List<dynamic> cartItems;

  const ProcessCheckout({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userAddress,
    required this.totalPrice,
    required this.cartItems,
  });

  @override
  List<Object?> get props => [userId, userName, userEmail, userAddress, totalPrice, cartItems];
}

class CheckOrderPayment extends OrderEvent {
  final String orderId;
  const CheckOrderPayment(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class FetchAllOrders extends OrderEvent {}