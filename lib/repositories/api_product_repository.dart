import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';
import 'product_repository.dart';

class ApiProductRepository implements ProductRepository {
  final String baseUrl;
  final http.Client _client;

  ApiProductRepository({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  Future<List<Product>> getProductsByStore(String storeId) async {
    final uri = Uri.parse('$baseUrl/stores/$storeId/products');
    final res = await _client.get(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to load products (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body) as List<dynamic>;
    return decoded
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Product?> getProductById(String storeId, String productId) async {
    final uri = Uri.parse('$baseUrl/stores/$storeId/products/$productId');
    final res = await _client.get(uri);

    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw Exception('Failed to load product (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return Product.fromJson(decoded);
  }

  @override
  Future<Product> addProduct(Product product) async {
    final uri = Uri.parse('$baseUrl/stores/${product.storeId}/products');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_productBody(product, requirePrice: true)),
    );

    if (res.statusCode != 201) {
      throw Exception('Failed to create product (${res.statusCode}): ${res.body}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return Product.fromJson(decoded);
  }

  @override
  Future<void> addManyProducts(List<Product> products) async {
    if (products.isEmpty) return;

    final storeId = products.first.storeId;
    final uri = Uri.parse('$baseUrl/stores/$storeId/products/bulk');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'products': products.map((product) => _productBody(product, requirePrice: true)).toList(),
      }),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Failed to create products (${res.statusCode}): ${res.body}');
    }
  }

  @override
  Future<Product> updateProduct(Product product) async {
    final uri = Uri.parse('$baseUrl/stores/${product.storeId}/products/${product.id}');
    final res = await _client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_productBody(product)),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update product (${res.statusCode}): ${res.body}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return Product.fromJson(decoded);
  }

  @override
  Future<void> deleteProduct(String storeId, String productId) async {
    final uri = Uri.parse('$baseUrl/stores/$storeId/products/$productId');
    final res = await _client.delete(uri);

    if (res.statusCode != 204) {
      throw Exception('Failed to delete product (${res.statusCode})');
    }
  }

  Map<String, dynamic> _productBody(Product product, {bool requirePrice = false}) => {
        'name': product.name,
        'category': product.category,
        'price': requirePrice ? (product.price ?? 0) : product.price,
        'quantity': product.quantity,
        'unit': product.unit,
        'barcode': product.barcode,
        'imageAssetPath': product.imageAssetPath,
        'imageUrl': product.imageAssetPath,
      };
}
