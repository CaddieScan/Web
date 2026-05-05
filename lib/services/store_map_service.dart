import 'dart:convert';
import 'package:http/http.dart' as http;
import '../controllers/store_map/store_map_data.dart';
import '../utils/error_handler.dart';

// service pour les cartes/plans des magasins
// même chose: HTTP direct + Toasts pour les erreurs et succès
// tu sauvegardes ta carte d'un magasin, ça s'envoie direct à l'API
class StoreMapService {
  final String baseUrl;
  final http.Client client;

  StoreMapService({
    required this.baseUrl,
    http.Client? httpClient,
  }) : client = httpClient ?? http.Client();

  Future<StoreMapData> fetchMap(String storeId) async {
    try {
      final uri = Uri.parse('$baseUrl/stores/$storeId/map');
      final res = await client.get(uri);

      if (res.statusCode != 200) {
        throw Exception('Erreur lors du chargement de la carte (${res.statusCode})');
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      return StoreMapData.fromJson(decoded);
    } catch (e) {
      ErrorHandler.showError(e.toString());
      rethrow;
    }
  }

  Future<StoreMapData> saveMap(String storeId, StoreMapData data) async {
    try {
      final uri = Uri.parse('$baseUrl/stores/$storeId/map');
      final res = await client.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data.toJson()),
      );

      if (res.statusCode != 200) {
        throw Exception('Erreur lors de la sauvegarde de la carte (${res.statusCode}): ${res.body}');
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      ErrorHandler.showSuccess('Carte sauvegardée avec succès');
      return StoreMapData.fromJson(decoded);
    } catch (e) {
      ErrorHandler.showError(e.toString());
      rethrow;
    }
  }

  Future<void> deleteMap(String storeId) async {
    try {
      final uri = Uri.parse('$baseUrl/stores/$storeId/map');
      final res = await client.delete(uri);

      if (res.statusCode != 204) {
        throw Exception('Erreur lors de la suppression de la carte (${res.statusCode})');
      }
      ErrorHandler.showSuccess('Carte supprimée avec succès');
    } catch (e) {
      ErrorHandler.showError(e.toString());
      rethrow;
    }
  }
}
