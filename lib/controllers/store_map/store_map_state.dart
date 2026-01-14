import 'package:flutter/material.dart';

enum EditorTool {
  select,
  drawRect,
  drawWall,
  drawAisle,
  placeEntry,
  placeExit,
  placeCheckout,
}

enum ResizeHandle { tl, tr, bl, br }

class StoreMapState {
  EditorTool tool = EditorTool.drawRect;

  double gridSize = 20;
  bool snapToGrid = true;

  String? activeFloorId;
  String? activeCategoryId;

  // Hover/selection zones
  String? hoveredZoneId;
  String? selectedZoneId;

  // Hover/selection POI
  String? hoveredPoiId;
  String? selectedPoiId;

  double snap(double v) {
    if (!snapToGrid) return v;
    return (v / gridSize).roundToDouble() * gridSize;
  }

  Offset snapOffset(Offset p) => Offset(snap(p.dx), snap(p.dy));
}
