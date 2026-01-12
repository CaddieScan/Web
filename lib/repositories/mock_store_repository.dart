import '../models/store.dart';
import 'store_repository.dart';

class MockStoreRepository implements StoreRepository {
  final List<Store> _stores = [
    const Store(id: '1', name: 'Carrefour Centre', latitude: 48.8566, longitude: 2.3522),
    const Store(id: '2', name: 'Auchan Nord', latitude: 48.8666, longitude: 2.3333),
    const Store(id: '3', name: 'Leclerc Sud', latitude: 48.8466, longitude: 2.3722),
  ];

  int _nextId = 4;

  @override
  Future<List<Store>> getStores() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_stores);
  }

  @override
  Future<Store?> getStoreById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _stores.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Store> createStore(Store store) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final created = Store(
      id: (_nextId++).toString(),
      name: store.name,
      latitude: store.latitude,
      longitude: store.longitude,
    );
    _stores.add(created);
    return created;
  }

  @override
  Future<void> deleteStore(String id) async {
    await Future.delayed(const Duration(milliseconds: 120));
    _stores.removeWhere((s) => s.id == id);
  }
}
