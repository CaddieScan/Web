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

  StoreMapData deepCopy() {
    final d = StoreMapData();

    // floors
    for (final f in floors) {
      d.floors.add(StoreFloor(id: f.id, name: f.name, order: f.order));
    }

    // categories
    for (final c in categories) {
      d.categories.add(StoreCategory(id: c.id, name: c.name, color: c.color));
    }

    // zones
    for (final e in zonesByFloor.entries) {
      d.zonesByFloor[e.key] = e.value
          .map((z) => StoreZone(
        id: z.id,
        floorId: z.floorId,
        name: z.name,
        categoryId: z.categoryId,
        x: z.x,
        y: z.y,
        w: z.w,
        h: z.h,
        shape: z.shape,
      ))
          .toList();
    }

    // walls
    for (final e in wallsByFloor.entries) {
      d.wallsByFloor[e.key] = e.value
          .map((poly) => poly.map((p) => Offset(p.dx, p.dy)).toList())
          .toList();
    }

    // aisles
    for (final e in aisleNodesByFloor.entries) {
      d.aisleNodesByFloor[e.key] = e.value.map((p) => Offset(p.dx, p.dy)).toList();
    }
    for (final e in aisleEdgesByFloor.entries) {
      d.aisleEdgesByFloor[e.key] = e.value.map((ed) => AisleEdge(ed.a, ed.b)).toList();
    }

    // POI
    for (final e in poisByFloor.entries) {
      d.poisByFloor[e.key] = e.value
          .map((p) => StorePoi(
        id: p.id,
        floorId: p.floorId,
        type: p.type,
        x: p.x,
        y: p.y,
        label: p.label,
        checkoutKind: p.checkoutKind,
        paymentMode: p.paymentMode,
        isAccessible: p.isAccessible,
      ))
          .toList();
    }

    return d;
  }
}
