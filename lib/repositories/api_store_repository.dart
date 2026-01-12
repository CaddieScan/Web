import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/store.dart';
import 'store_repository.dart';

class ApiStoreRepository implements StoreRepository {
  final String baseUrl; // faut mettre la vrai url quand on le saura
  final http.Client _client;

  ApiStoreRepository({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  Future<List<Store>> getStores() async {
    final uri = Uri.parse('$baseUrl/stores');
    final res = await _client.get(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to load stores (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body) as List<dynamic>;
    return decoded
        .map((e) => Store.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Store?> getStoreById(String id) async {
    final uri = Uri.parse('$baseUrl/stores/$id');
    final res = await _client.get(uri);

    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw Exception('Failed to load store (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return Store.fromJson(decoded);
  }

  @override
  Future<Store> createStore(Store store) async {
    final uri = Uri.parse('$baseUrl/stores');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(store.toJson()),
    );

    if (res.statusCode != 201) {
      throw Exception('Failed to create store (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return Store.fromJson(decoded);
  }

  @override
  Future<Store> updateStore(Store store) async {
    final uri = Uri.parse('$baseUrl/stores/${store.id}');
    final res = await _client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(store.toJson()),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update store (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return Store.fromJson(decoded);
  }

  @override
  Future<void> deleteStore(String id) {
    // TODO: implement deleteStore
    throw UnimplementedError();
  }
}
