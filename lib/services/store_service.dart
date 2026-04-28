import '../models/store.dart';
import '../repositories/store_repository.dart';

// sert à faire le liens entre les repositories et le reste de l'app, c'est lui qui va être utilisé par les controllers
// pour accéder aux données des magasins, il peut aussi faire du caching ou d'autres traitements si besoin

class StoreService {
  final StoreRepository repo;
  StoreService(this.repo);

  Future<List<Store>> fetchStores() => repo.getStores();
  Future<Store> addStore(Store store) => repo.createStore(store);
  // test
}
