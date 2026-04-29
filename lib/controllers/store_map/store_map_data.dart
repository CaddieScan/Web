import 'dart:ui';

import '../../models/store_map_models.dart';
import '../../models/store_poi_models.dart';
import 'aisle_controller.dart';

// ici on stock toutes les données des zones, murs, rayons, POI,
// gros conteneur de données pour éviter d'avoir des données éparpillées dans les différents controllers,
// et pour faciliter la sauvegarde / chargement / export / import

class StoreMapData {
  final List<StoreFloor> floors = [];
  final List<StoreCategory> categories = [];

  final Map<String, List<StoreZone>> zonesByFloor = {};
  final Map<String, List<List<Offset>>> wallsByFloor = {};

  final Map<String, List<Offset>> aisleNodesByFloor = {};
  final Map<String, List<AisleEdge>> aisleEdgesByFloor = {};

  final Map<String, List<StorePoi>> poisByFloor = {};

  StoreMapData();

  void ensureFloor(String floorId) {
    zonesByFloor.putIfAbsent(floorId, () => []);
    wallsByFloor.putIfAbsent(floorId, () => []);
    aisleNodesByFloor.putIfAbsent(floorId, () => []);
    aisleEdgesByFloor.putIfAbsent(floorId, () => []);
    poisByFloor.putIfAbsent(floorId, () => []);
  }

  factory StoreMapData.fromJson(Map<String, dynamic> json) {
    final d = StoreMapData();

    for (final item in (json['floors'] as List<dynamic>? ?? const [])) {
      final floor = StoreFloor.fromJson(item as Map<String, dynamic>);
      d.floors.add(floor);
      d.ensureFloor(floor.id);
    }

    for (final item in (json['categories'] as List<dynamic>? ?? const [])) {
      d.categories.add(StoreCategory.fromJson(item as Map<String, dynamic>));
    }

    for (final item in (json['zones'] as List<dynamic>? ?? const [])) {
      final zone = StoreZone.fromJson(item as Map<String, dynamic>);
      d.ensureFloor(zone.floorId);
      d.zonesByFloor[zone.floorId]!.add(zone);
    }

    for (final item in (json['walls'] as List<dynamic>? ?? const [])) {
      final wall = item as Map<String, dynamic>;
      final floorId = wall['floorId'].toString();
      d.ensureFloor(floorId);
      final points = (wall['points'] as List<dynamic>? ?? const [])
          .map((p) => _offsetFromJson(p as Map<String, dynamic>))
          .toList();
      d.wallsByFloor[floorId]!.add(points);
    }

    for (final aisle in (json['aisles'] as List<dynamic>? ?? const [])) {
      final aisleMap = aisle as Map<String, dynamic>;
      String? aisleFloorId;
      for (final item in (aisleMap['nodes'] as List<dynamic>? ?? const [])) {
        final node = item as Map<String, dynamic>;
        final floorId = node['floorId'].toString();
        aisleFloorId ??= floorId;
        d.ensureFloor(floorId);
        d.aisleNodesByFloor[floorId]!.add(_offsetFromJson(node));
      }
      for (final item in (aisleMap['edges'] as List<dynamic>? ?? const [])) {
        final edge = item as Map<String, dynamic>;
        final floorId = edge['floorId']?.toString() ?? aisleFloorId;
        if (floorId == null) continue;
        d.ensureFloor(floorId);
        final fromNodeId = edge['fromNodeId']?.toString();
        final toNodeId = edge['toNodeId']?.toString();
        final a = fromNodeId == null ? _nullableIntFromJson(edge['a']) : _nodeIndexFromId(fromNodeId);
        final b = toNodeId == null ? _nullableIntFromJson(edge['b']) : _nodeIndexFromId(toNodeId);
        if (a == null || b == null) continue;
        d.aisleEdgesByFloor[floorId]!.add(
          AisleEdge(a, b),
        );
      }
    }

    for (final item in (json['pois'] as List<dynamic>? ?? const [])) {
      final poi = StorePoi.fromJson(item as Map<String, dynamic>);
      d.ensureFloor(poi.floorId);
      d.poisByFloor[poi.floorId]!.add(poi);
    }

    return d;
  }

  Map<String, dynamic> toJson() => {
        'floors': floors.map((f) => f.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'zones': zonesByFloor.values.expand((zones) => zones).map((z) => z.toJson()).toList(),
        'walls': wallsByFloor.entries
            .expand(
              (entry) => entry.value.map(
                (points) => {
                  'floorId': entry.key,
                  'points': points.map(_offsetToJson).toList(),
                },
              ),
            )
            .toList(),
        'aisles': _aislesToJson(),
        'pois': poisByFloor.values.expand((pois) => pois).map((p) => p.toJson()).toList(),
      };

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

  List<Map<String, dynamic>> _aislesToJson() {
    final floorIds = {
      ...aisleNodesByFloor.keys,
      ...aisleEdgesByFloor.keys,
    };

    return floorIds
        .map(
          (floorId) => {
            'nodes': (aisleNodesByFloor[floorId] ?? const [])
                .asMap()
                .entries
                .map(
                  (entry) => {
                    'id': 'node-${entry.key}',
                    'floorId': floorId,
                    ..._offsetToJson(entry.value),
                  },
                )
                .toList(),
            'edges': (aisleEdgesByFloor[floorId] ?? const [])
                .map(
                  (edge) => {
                    'fromNodeId': 'node-${edge.a}',
                    'toNodeId': 'node-${edge.b}',
                  },
                )
                .toList(),
          },
        )
        .toList();
  }
}

Offset _offsetFromJson(Map<String, dynamic> json) => Offset(
      _numFromJson(json['x']),
      _numFromJson(json['y']),
    );

Map<String, dynamic> _offsetToJson(Offset offset) => {
      'x': offset.dx,
      'y': offset.dy,
    };

int _nodeIndexFromId(String id) {
  final rawIndex = id.split('-').last;
  return int.tryParse(rawIndex) ?? 0;
}

double _numFromJson(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int? _nullableIntFromJson(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
