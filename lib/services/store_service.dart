import '../models/store.dart';
import '../repositories/store_repository.dart';

class StoreService {
  final StoreRepository repo;
  StoreService(this.repo);

  Future<List<Store>> fetchStores() => repo.getStores();
  Future<Store> addStore(Store store) => repo.createStore(store);
}
