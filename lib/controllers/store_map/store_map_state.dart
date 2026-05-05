import 'package:flutter/material.dart';
class StoreMapState {
  EditorTool tool = EditorTool.select;
  String activeFloorId = '';
  String? selectedZoneId;
  String? selectedPoiId;
  bool snapToGrid = true;
  double gridSize = 20.0;
  double snap(double val) {
    if (!snapToGrid) return val;
    return (val / gridSize).roundToDouble() * gridSize;
  }
  Offset snapOffset(Offset o) {
    if (!snapToGrid) return o;
    return Offset(
      (o.dx / gridSize).roundToDouble() * gridSize,
      (o.dy / gridSize).roundToDouble() * gridSize,
    );
  }
  StoreMapState();
  StoreMapState deepCopy() {
    final s = StoreMapState();
    s.tool = tool;
    s.activeFloorId = activeFloorId;
    s.selectedZoneId = selectedZoneId;
    s.selectedPoiId = selectedPoiId;
    s.snapToGrid = snapToGrid;
    s.gridSize = gridSize;
    return s;
  }
  void loadFrom(StoreMapState other) {
    tool = other.tool;
    activeFloorId = other.activeFloorId;
    selectedZoneId = other.selectedZoneId;
    selectedPoiId = other.selectedPoiId;
    snapToGrid = other.snapToGrid;
    gridSize = other.gridSize;
  }
}
enum EditorTool {
  select,
  drawRect,
  drawCircle,
  placeEntry,
  placeExit,
}
