class Product {
  final String id;
  final String storeId;

  final String name;
  final String category;

  final double? price;
  final int quantity; // stock
  final String unit; // "pcs", "kg", "L", etc.
  final String? barcode; // EAN optionnel

  final String imageAssetPath;

  const Product({
    required this.id,
    required this.storeId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.imageAssetPath,
    this.price,
    this.barcode,
  });

  Product copyWith({
    String? id,
    String? storeId,
    String? name,
    String? category,
    double? price,
    int? quantity,
    String? unit,
    String? barcode,
    String? imageAssetPath,
  }) {
    return Product(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      barcode: barcode ?? this.barcode,
      imageAssetPath: imageAssetPath ?? this.imageAssetPath,
    );
  }
}
