import '../controllers/store_map/store_map_data.dart';
import 'store_map_repository.dart';

class MockStoreMapRepository implements StoreMapRepository {
  final Map<String, StoreMapData> _maps = {};

  @override
  Future<StoreMapData> getMap(String storeId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _maps[storeId]?.deepCopy() ?? StoreMapData();
  }

  @override
  Future<StoreMapData> saveMap(String storeId, StoreMapData data) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _maps[storeId] = data.deepCopy();
    return data.deepCopy();
  }

  @override
  Future<void> deleteMap(String storeId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    _maps.remove(storeId);
  }
}
