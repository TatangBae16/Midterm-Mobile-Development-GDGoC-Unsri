import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/product_repository.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;

  ProductBloc({required this.repository}) : super(ProductInitial()) {

    // ==========================================
    // 1. HANDLER USER & PENCARIAN (BACA DATA)
    // ==========================================
    on<FetchProductsEvent>((event, emit) async {
      emit(ProductLoading());
      try {
        final products = await repository.getProducts(
          query: event.query,
          category: event.category,
        );
        emit(ProductLoaded(products));
      } catch (e) {
        emit(ProductError(e.toString()));
      }
    });

    // ==========================================
    // 👇 3 HANDLER KHUSUS ADMIN (CRUD) 👇
    // ==========================================

    // 2. HANDLER TAMBAH PRODUK
    on<AddProductEvent>((event, emit) async {
      emit(ProductLoading());
      try {
        await repository.addProduct(event.product);
        // Setelah sukses ditambah, ambil ulang data terbaru dari awal
        add(const FetchProductsEvent(category: 'Semua'));
      } catch (e) {
        emit(ProductError(e.toString()));
      }
    });

    // 3. HANDLER EDIT PRODUK
    on<UpdateProductEvent>((event, emit) async {
      emit(ProductLoading());
      try {
        await repository.updateProduct(event.product);
        add(const FetchProductsEvent(category: 'Semua'));
      } catch (e) {
        emit(ProductError(e.toString()));
      }
    });

    // 4. HANDLER HAPUS PRODUK
    on<DeleteProductEvent>((event, emit) async {
      emit(ProductLoading());
      try {
        await repository.deleteProduct(event.productId);
        add(const FetchProductsEvent(category: 'Semua'));
      } catch (e) {
        emit(ProductError(e.toString()));
      }
    });

  } // <-- Penutup Constructor BLoC
}