import '../controllers/store_map/store_map_data.dart';

abstract class StoreMapRepository {
  Future<StoreMapData> getMap(String storeId);
  Future<StoreMapData> saveMap(String storeId, StoreMapData data);
  Future<void> deleteMap(String storeId);
}
