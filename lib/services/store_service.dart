import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/store.dart';
import '../utils/error_handler.dart';

// service pour gérer les magasins
// les appels HTTP à l'API sont intégrés directement ici
// les erreurs s'affichent automatiquement en Toast pour l'utilisateur
class StoreService {
  final String baseUrl;
  final http.Client client;

  StoreService({
    required this.baseUrl,
    http.Client? httpClient,
  }) : client = httpClient ?? http.Client();

  Future<List<Store>> fetchStores() async {
    try {
      final uri = Uri.parse('$baseUrl/stores');
      final res = await client.get(uri);

      if (res.statusCode != 200) {
        throw Exception('Erreur lors du chargement des magasins (${res.statusCode})');
      }

      final decoded = jsonDecode(res.body) as List<dynamic>;
      return decoded
          .map((e) => Store.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      ErrorHandler.showError(e.toString());
      rethrow;
    }
  }

  Future<Store?> fetchStore(String id) async {
    try {
      final uri = Uri.parse('$baseUrl/stores/$id');
      final res = await client.get(uri);

      if (res.statusCode == 404) return null;
      if (res.statusCode != 200) {
        throw Exception('Erreur lors du chargement du magasin (${res.statusCode})');
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      return Store.fromJson(decoded);
    } catch (e) {
      ErrorHandler.showError(e.toString());
      rethrow;
    }
  }

  Future<Store> addStore(Store store) async {
    try {
      final uri = Uri.parse('$baseUrl/stores');
      final res = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': store.name,
          'latitude': store.latitude,
          'longitude': store.longitude,
        }),
      );

      if (res.statusCode != 201) {
        throw Exception('Erreur lors de la création du magasin (${res.statusCode})');
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      ErrorHandler.showSuccess('Magasin créé avec succès');
      return Store.fromJson(decoded);
    } catch (e) {
      ErrorHandler.showError(e.toString());
      rethrow;
    }
  }

  Future<Store> updateStore(Store store) async {
    try {
      final uri = Uri.parse('$baseUrl/stores/${store.id}');
      final res = await client.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(store.toJson()),
      );

      if (res.statusCode != 200) {
        throw Exception('Erreur lors de la mise à jour du magasin (${res.statusCode})');
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      ErrorHandler.showSuccess('Magasin mis à jour avec succès');
      return Store.fromJson(decoded);
    } catch (e) {
      ErrorHandler.showError(e.toString());
      rethrow;
    }
  }

  Future<void> deleteStore(String id) async {
    try {
      final uri = Uri.parse('$baseUrl/stores/$id');
      final res = await client.delete(uri);

      if (res.statusCode != 204) {
        throw Exception('Erreur lors de la suppression du magasin (${res.statusCode})');
      }
      ErrorHandler.showSuccess('Magasin supprimé avec succès');
    } catch (e) {
      ErrorHandler.showError(e.toString());
      rethrow;
    }
  }
}
