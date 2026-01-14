import 'dart:ui';

import '../../models/store_map_models.dart';
import '../../models/store_poi_models.dart';
import 'aisle_controller.dart';

class StoreMapData {
  final List<StoreFloor> floors = [];
  final List<StoreCategory> categories = [];

  final Map<String, List<StoreZone>> zonesByFloor = {};
  final Map<String, List<List<Offset>>> wallsByFloor = {};

  final Map<String, List<Offset>> aisleNodesByFloor = {};
  final Map<String, List<AisleEdge>> aisleEdgesByFloor = {};

  final Map<String, List<StorePoi>> poisByFloor = {};

  void ensureFloor(String floorId) {
    zonesByFloor.putIfAbsent(floorId, () => []);
    wallsByFloor.putIfAbsent(floorId, () => []);
    aisleNodesByFloor.putIfAbsent(floorId, () => []);
    aisleEdgesByFloor.putIfAbsent(floorId, () => []);
    poisByFloor.putIfAbsent(floorId, () => []);
  }
}
