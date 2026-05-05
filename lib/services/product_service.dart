import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../utils/error_handler.dart';

// service pour gérer les produits
// pareil que pour les stores, c'est du HTTP direct avec gestion d'erreurs Toast
// quand tu ajoutes/modifies/supprimesun produit, tu vois le message directement
class ProductService {
  final String baseUrl;
  final http.Client client;

  ProductService({
    required this.baseUrl,
    http.Client? httpClient,
  }) : client = httpClient ?? http.Client();

  Future<List<Product>> fetchProducts(String storeId) async {
    try {
      final uri = Uri.parse('$baseUrl/stores/$storeId/products');
      final res = await client.get(uri);

      if (res.statusCode != 200) {
        throw Exception('Erreur lors du chargement des produits (${res.statusCode})');
      }

      final decoded = jsonDecode(res.body) as List<dynamic>;
      return decoded
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      ErrorHandler.showError(e.toString());
      rethrow;
    }
  }

  Future<Product?> fetchProduct(String storeId, String productId) async {
    try {
      final uri = Uri.parse('$baseUrl/stores/$storeId/products/$productId');
      final res = await client.get(uri);

      if (res.statusCode == 404) return null;
      if (res.statusCode != 200) {
        throw Exception('Erreur lors du chargement du produit (${res.statusCode})');
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      return Product.fromJson(decoded);
    } catch (e) {
      ErrorHandler.showError(e.toString());
      rethrow;
    }
  }

  Future<Product> addProduct(Product product) async {
    try {
      final uri = Uri.parse('$baseUrl/stores/${product.storeId}/products');
      final res = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(productBody(product, requirePrice: true)),
      );

      if (res.statusCode != 201) {
        throw Exception('Erreur lors de la création du produit (${res.statusCode}): ${res.body}');
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      ErrorHandler.showSuccess('Produit créé avec succès');
      return Product.fromJson(decoded);
    } catch (e) {
      ErrorHandler.showError(e.toString());
      rethrow;
    }
  }

  Future<void> addMany(List<Product> products) async {
    try {
      if (products.isEmpty) return;

      final storeId = products.first.storeId;
      final uri = Uri.parse('$baseUrl/stores/$storeId/products/bulk');
      final res = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'products': products.map((product) => productBody(product, requirePrice: true)).toList(),
        }),
      );

      if (res.statusCode != 201 && res.statusCode != 200) {
        throw Exception('Erreur lors de la création des produits (${res.statusCode}): ${res.body}');
      }
      ErrorHandler.showSuccess('Produits importés avec succès');
    } catch (e) {
      ErrorHandler.showError(e.toString());
      rethrow;
    }
  }

  Future<Product> updateProduct(Product product) async {
    try {
      final uri = Uri.parse('$baseUrl/stores/${product.storeId}/products/${product.id}');
      final res = await client.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(productBody(product)),
      );

      if (res.statusCode != 200) {
        throw Exception('Erreur lors de la mise à jour du produit (${res.statusCode}): ${res.body}');
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      ErrorHandler.showSuccess('Produit mis à jour avec succès');
      return Product.fromJson(decoded);
    } catch (e) {
      ErrorHandler.showError(e.toString());
      rethrow;
    }
  }

  Future<void> deleteProduct(String storeId, String productId) async {
    try {
      final uri = Uri.parse('$baseUrl/stores/$storeId/products/$productId');
      final res = await client.delete(uri);

      if (res.statusCode != 204) {
        throw Exception('Erreur lors de la suppression du produit (${res.statusCode})');
      }
      ErrorHandler.showSuccess('Produit supprimé avec succès');
    } catch (e) {
      ErrorHandler.showError(e.toString());
      rethrow;
    }
  }

  Map<String, dynamic> productBody(Product product, {bool requirePrice = false}) => {
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
