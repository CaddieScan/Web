import '../controllers/store_map/store_map_data.dart';
import '../repositories/store_map_repository.dart';

class StoreMapService {
  final StoreMapRepository repo;

  StoreMapService(this.repo);

  Future<StoreMapData> fetchMap(String storeId) => repo.getMap(storeId);
  Future<StoreMapData> saveMap(String storeId, StoreMapData data) => repo.saveMap(storeId, data);
  Future<void> deleteMap(String storeId) => repo.deleteMap(storeId);
}
