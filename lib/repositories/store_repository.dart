import '../models/store.dart';

abstract class StoreRepository {
  Future<List<Store>> getStores();
  Future<Store?> getStoreById(String id);

  Future<Store> createStore(Store store);
  Future<void> deleteStore(String id);
}
