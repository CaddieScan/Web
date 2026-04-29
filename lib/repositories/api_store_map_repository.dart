import 'dart:convert';

import 'package:http/http.dart' as http;

import '../controllers/store_map/store_map_data.dart';
import 'store_map_repository.dart';

class ApiStoreMapRepository implements StoreMapRepository {
  final String baseUrl;
  final http.Client _client;

  ApiStoreMapRepository({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  Future<StoreMapData> getMap(String storeId) async {
    final uri = Uri.parse('$baseUrl/stores/$storeId/map');
    final res = await _client.get(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to load store map (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return StoreMapData.fromJson(decoded);
  }

  @override
  Future<StoreMapData> saveMap(String storeId, StoreMapData data) async {
    final uri = Uri.parse('$baseUrl/stores/$storeId/map');
    final res = await _client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data.toJson()),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to save store map (${res.statusCode}): ${res.body}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return StoreMapData.fromJson(decoded);
  }

  @override
  Future<void> deleteMap(String storeId) async {
    final uri = Uri.parse('$baseUrl/stores/$storeId/map');
    final res = await _client.delete(uri);

    if (res.statusCode != 204) {
      throw Exception('Failed to delete store map (${res.statusCode})');
    }
  }
}
