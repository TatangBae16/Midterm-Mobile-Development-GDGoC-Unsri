import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/order_repository.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository orderRepository;

  OrderBloc(this.orderRepository) : super(OrderInitial()) {
    on<FetchOrderHistory>((event, emit) async {
      emit(OrderLoading());
      try {
        final orders = await orderRepository.getOrderHistory(event.userId);
        emit(OrderLoaded(orders));
      } catch (e) {
        emit(OrderError(e.toString()));
      }
    });

    on<ProcessCheckout>((event, emit) async {
      emit(OrderCheckoutLoading());
      try {
        final url = await orderRepository.createOrderAndGetPaymentUrl(
          userId: event.userId,
          userName: event.userName,
          userEmail: event.userEmail,
          userAddress: event.userAddress,
          totalPrice: event.totalPrice,
          cartItems: event.cartItems,
        );
        emit(OrderCheckoutSuccess(url));
      } catch (e) {
        emit(OrderCheckoutError(e.toString()));
      }
    });

    on<CheckOrderPayment>((event, emit) async {
      try {
        // Jalankan fungsi cek status
        await orderRepository.checkPaymentStatus(event.orderId);

        // Setelah diupdate, panggil lagi riwayat terbaru agar UI refresh otomatis
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final updatedOrders = await orderRepository.getOrderHistory(userId);
        emit(OrderLoaded(updatedOrders));
      } catch (_) {
        // Abaikan error atau handle sesuai kebutuhan
      }
    });

    on<FetchAllOrders>((event, emit) async {
      emit(OrderLoading());
      try {
        final orders = await orderRepository.getAllOrders();
        emit(OrderLoaded(orders)); // Reuse state yang sudah ada
      } catch (e) {
        emit(OrderError(e.toString()));
      }
    });
  }
}