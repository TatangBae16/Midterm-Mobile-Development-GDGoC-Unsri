class ProductModel {
  final int id;
  final String name;
  final String description;
  final num price; // Menggunakan num agar aman untuk integer maupun double
  final int? stock;
  final String imageUrl;
  final String? category;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.stock,
    this.category,
    required this.imageUrl,
  });

  // Fungsi yang sudah kamu miliki (Mengubah JSON dari internet menjadi Objek Flutter)
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? 0,
      stock: json['stock'],
      imageUrl: json['image_url'] ?? '',
      category: json['category'],
    );
  }

  // Fungsi baru (Mengubah Objek Flutter menjadi JSON untuk disimpan di memori HP)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'image_url': imageUrl,
      'category': category,
    };
  }
}