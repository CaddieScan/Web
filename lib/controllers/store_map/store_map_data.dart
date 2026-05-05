import 'package:flutter/material.dart';
import 'store_map_state.dart';
import '../../models/store_map_models.dart';
import '../../models/store_poi_models.dart';
class StoreMapData {
  final List<StoreFloor> floors = [];
  final List<StoreCategory> categories = [];
  final Map<String, List<StoreZone>> zonesByFloor = {};
  final Map<String, List<StorePoi>> poisByFloor = {};
  StoreMapData();
  factory StoreMapData.fromJson(Map<String, dynamic> json) {
    final d = StoreMapData();
    for (final item in (json['floors'] as List<dynamic>? ?? const [])) {
      d.floors.add(StoreFloor.fromJson(item));
    }
    for (final item in (json['categories'] as List<dynamic>? ?? const [])) {
      d.categories.add(StoreCategory.fromJson(item));
    }
    for (final f in d.floors) {
      d.zonesByFloor.putIfAbsent(f.id, () => []);
      d.poisByFloor.putIfAbsent(f.id, () => []);
    }
    for (final item in (json['zones'] as List<dynamic>? ?? const [])) {
      final zone = StoreZone.fromJson(item);
      d.zonesByFloor.putIfAbsent(zone.floorId, () => []);
      d.zonesByFloor[zone.floorId]!.add(zone);
    }
    for (final item in (json['pois'] as List<dynamic>? ?? const [])) {
      final poi = StorePoi.fromJson(item);
      d.poisByFloor.putIfAbsent(poi.floorId, () => []);
      d.poisByFloor[poi.floorId]!.add(poi);
    }
    return d;
  }
  Map<String, dynamic> toJson() {
    return {
      'floors': floors.map((f) => f.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'zones': zonesByFloor.values.expand((zs) => zs).map((z) => z.toJson()).toList(),
      'pois': poisByFloor.values.expand((pois) => pois).map((p) => p.toJson()).toList(),
    };
  }
  StoreMapData deepCopy() {
    final jsonDict = toJson();
    return StoreMapData.fromJson(jsonDict);
  }
}
