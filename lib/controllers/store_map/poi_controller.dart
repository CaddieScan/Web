import 'package:flutter/material.dart';
import '../../models/store_poi_models.dart';
import 'store_map_data.dart';
import 'store_map_state.dart';
class PoiController {
  final StoreMapState state;
  final StoreMapData data;
  StorePoi? movingPoi;
  double hoverX = 0;
  double hoverY = 0;
  PoiController(this.state, this.data);
  StorePoi? poiById(String id) {
    for (final list in data.poisByFloor.values) {
      final idx = list.indexWhere((p) => p.id == id);
      if (idx >= 0) return list[idx];
    }
    return null;
  }
  StorePoi? hitTest(double x, double y) {
    if (state.activeFloorId.isEmpty) return null;
    final pois = data.poisByFloor[state.activeFloorId];
    if (pois == null) return null;
    final threshold = 20.0;
    for (final p in pois) {
      final dx = p.x - x;
      final dy = p.y - y;
      if (dx * dx + dy * dy <= threshold * threshold) {
        return p;
      }
    }
    return null;
  }
  void updateHover(double px, double py) {
    final p = hitTest(px, py);
    hoverX = px;
    hoverY = py;
  }
  StorePoi? addPoi({
    required String id,
    required String floorId,
    required PoiType type,
    required Offset world,
  }) {
    data.poisByFloor.putIfAbsent(floorId, () => []);
    final nx = world.dx;
    final ny = world.dy;
    final newPoi = StorePoi(
      id: id,
      floorId: floorId,
      type: type,
      x: nx,
      y: ny,
      label: type == PoiType.entry ? 'Entrée' : 'Sortie',
    );
    data.poisByFloor[floorId]!.add(newPoi);
    state.selectedPoiId = id;
    state.selectedZoneId = null;
    return newPoi;
  }
  void deletePoi(String id) {
    for (final floorId in data.poisByFloor.keys) {
      data.poisByFloor[floorId]!.removeWhere((p) => p.id == id);
    }
  }
  bool get isMoving => movingPoi != null;
  void startMove(StorePoi p, double px, double py) {
    movingPoi = p;
  }
  bool updateMove(StorePoi p, double px, double py) {
    if (movingPoi != p) return false;
    p.x = px;
    p.y = py;
    return true;
  }
  void finishMove() {
    movingPoi = null;
  }
  void cancelMove() {
    movingPoi = null;
  }
  StorePoi? placePoi(PoiType type, Offset world) {
    if (state.activeFloorId.isEmpty) return null;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    return addPoi(id: id, floorId: state.activeFloorId, type: type, world: world);
  }
}
