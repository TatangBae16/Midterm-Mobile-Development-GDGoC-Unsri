abstract class QuantityEvent {}

class IncrementQuantity extends QuantityEvent {
  final int maxStock;
  IncrementQuantity(this.maxStock);
}

class DecrementQuantity extends QuantityEvent {}