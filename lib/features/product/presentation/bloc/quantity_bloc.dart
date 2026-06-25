import 'package:flutter_bloc/flutter_bloc.dart';
import 'quantity_event.dart';
import 'quantity_state.dart';

class QuantityBloc extends Bloc<QuantityEvent, QuantityState> {
  QuantityBloc() : super(const QuantityState(1)) { // Nilai awal selalu 1
    on<IncrementQuantity>((event, emit) {
      if (state.value < event.maxStock) {
        emit(QuantityState(state.value + 1));
      }
    });

    on<DecrementQuantity>((event, emit) {
      if (state.value > 1) {
        emit(QuantityState(state.value - 1));
      }
    });
  }
}