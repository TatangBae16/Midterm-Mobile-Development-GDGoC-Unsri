import 'package:equatable/equatable.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}
class OrderLoading extends OrderState {}

class OrderLoaded extends OrderState {
  final List<dynamic> orders;
  const OrderLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class OrderError extends OrderState {
  final String message;
  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}

class OrderCheckoutLoading extends OrderState {}

class OrderCheckoutSuccess extends OrderState {
  final String redirectUrl;
  const OrderCheckoutSuccess(this.redirectUrl);

  @override
  List<Object?> get props => [redirectUrl];
}

class OrderCheckoutError extends OrderState {
  final String message;
  const OrderCheckoutError(this.message);

  @override
  List<Object?> get props => [message];
}