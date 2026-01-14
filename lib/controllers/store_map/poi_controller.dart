import 'dart:math';
import 'dart:ui';

import '../../models/store_poi_models.dart';
import 'store_map_data.dart';
import 'store_map_state.dart';

class PoiController {
  final StoreMapState state;
  final StoreMapData data;

  bool isMoving = false;
  double _dx = 0;
  double _dy = 0;

  PoiController(this.state, this.data);

  List<StorePoi> get pois => data.poisByFloor[state.activeFloorId] ?? const [];

  StorePoi? poiById(String id) {
    for (final p in pois) {
      if (p.id == id) return p;
    }
    return null;
  }

  StorePoi? hitTest(double x, double y, {double radius = 14}) {
    StorePoi? best;
    double bestD = double.infinity;

    for (final p in pois) {
      final dx = x - p.x;
      final dy = y - p.y;
      final d = sqrt(dx * dx + dy * dy);
      if (d <= radius && d < bestD) {
        bestD = d;
        best = p;
      }
    }
    return best;
  }

  StorePoi addPoi({
    required String id,
    required String floorId,
    required PoiType type,
    required Offset world,
  }) {
    final p = state.snapOffset(world);

    final poi = StorePoi(
      id: id,
      floorId: floorId,
      type: type,
      x: p.dx,
      y: p.dy,
      label: _defaultLabel(type),
    );

    data.poisByFloor[floorId]!.add(poi);

    state.selectedPoiId = poi.id;
    state.selectedZoneId = null;
    return poi;
  }

  String _defaultLabel(PoiType t) {
    switch (t) {
      case PoiType.entry:
        return 'Entree';
      case PoiType.exit:
        return 'Sortie';
      case PoiType.checkout:
        return 'Caisse';
    }
  }

  void updateHover(double x, double y) {
    final p = hitTest(x, y);
    state.hoveredPoiId = p?.id;
  }

  void selectPoi(String? id) {
    state.selectedPoiId = id;
    if (id != null) state.selectedZoneId = null;
    cancelMove();
  }

  void startMove(StorePoi p, double px, double py) {
    isMoving = true;
    _dx = px - p.x;
    _dy = py - p.y;
  }

  bool updateMove(StorePoi p, double px, double py) {
    if (!isMoving) return false;

    final nx = state.snapToGrid ? state.snap(px - _dx) : (px - _dx);
    final ny = state.snapToGrid ? state.snap(py - _dy) : (py - _dy);

    final changed = (nx != p.x) || (ny != p.y);
    p.x = nx;
    p.y = ny;
    return changed;
  }

  void finishMove() => isMoving = false;

  void cancelMove() => isMoving = false;
}
