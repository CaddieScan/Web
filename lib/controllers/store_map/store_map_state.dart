import 'dart:ui';

// sert à géré les outils qui sont utilisés pour la carte interactif

enum EditorTool {
  select,
  drawRect,
  drawCircle,
  drawWall,
  drawAisle,
  placeEntry,
  placeExit,
  placeCheckout,
}

enum ResizeHandle { tl, tr, bl, br }

class StoreMapState {
  EditorTool tool = EditorTool.select;

  String? activeFloorId;
  String? activeCategoryId;

  String? selectedZoneId;
  String? hoveredZoneId;

  String? selectedPoiId;
  String? hoveredPoiId;

  // NEW selections
  int? selectedWallIndex;        // index dans wallsByFloor[floor]
  int? selectedAisleNodeIndex;   // index dans nodes
  int? selectedAisleEdgeIndex;   // index dans edges

  bool snapToGrid = true;
  double gridSize = 20;

  double snap(double v) => (v / gridSize).round() * gridSize;

  Offset snapOffset(Offset p) => Offset(snap(p.dx), snap(p.dy));

  StoreMapState deepCopy() {
    final s = StoreMapState();
    s.tool = tool;
    s.activeFloorId = activeFloorId;
    s.activeCategoryId = activeCategoryId;

    s.selectedZoneId = selectedZoneId;
    s.hoveredZoneId = hoveredZoneId;

    s.selectedPoiId = selectedPoiId;
    s.hoveredPoiId = hoveredPoiId;

    s.selectedWallIndex = selectedWallIndex;
    s.selectedAisleNodeIndex = selectedAisleNodeIndex;
    s.selectedAisleEdgeIndex = selectedAisleEdgeIndex;

    s.snapToGrid = snapToGrid;
    s.gridSize = gridSize;
    return s;
  }
}
