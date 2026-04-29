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

  factory Product.fromJson(Map<String, dynamic> json) {
    final imagePath = json['imageAssetPath'] ?? json['imageUrl'] ?? '';

    return Product(
      id: json['id'].toString(),
      storeId: json['storeId'].toString(),
      name: json['name'] as String,
      category: (json['category'] as String?) ?? 'Autre',
      price: json['price'] == null ? null : (json['price'] as num).toDouble(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unit: (json['unit'] as String?) ?? 'pcs',
      barcode: json['barcode']?.toString(),
      imageAssetPath: imagePath.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'storeId': storeId,
        'name': name,
        'category': category,
        'price': price,
        'quantity': quantity,
        'unit': unit,
        'barcode': barcode,
        'imageAssetPath': imageAssetPath,
      };

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
