import 'package:equatable/equatable.dart';

import '../../data/models/product_model.dart';

// Induk Event
abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

// Anak Event
class FetchProductsEvent extends ProductEvent {
  final String? query;
  final String? category;

  const FetchProductsEvent({this.query, this.category});

  @override
  // 👇 Masukkan KEDUA properti ke dalam props 👇
  List<Object?> get props => [query, category];
}

// EVENT UNTUK ADMIN
class AddProductEvent extends ProductEvent {
  final ProductModel product;
  const AddProductEvent(this.product);

  @override
  List<Object?> get props => [product];
}

class UpdateProductEvent extends ProductEvent {
  final ProductModel product;
  const UpdateProductEvent(this.product);

  @override
  List<Object?> get props => [product];
}

class DeleteProductEvent extends ProductEvent {
  final int productId;
  const DeleteProductEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}