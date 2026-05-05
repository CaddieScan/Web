import 'package:flutter/material.dart';
import '../../models/store_map_models.dart';
import '../../models/store_poi_models.dart';
import 'store_map_state.dart';
import 'store_map_data.dart';
import 'poi_controller.dart';
import 'zone_controller.dart';
import 'undo/undo_manager.dart';
class StoreMapController {
  final StoreMapState state = StoreMapState();
  StoreMapData data = StoreMapData();
  late ZoneController zones;
  late PoiController pois;
  late UndoManager undoManager;
  bool initialized = false;
  void init(StoreMapData initialData) {
    data = initialData.deepCopy();
    // Default config if needed
    if (data.floors.isEmpty) {
      data.floors.add(StoreFloor(id: 'floor_rdc', name: 'RDC', order: 0));
    }
    if (data.categories.isEmpty) {
      data.categories.add(StoreCategory(id: 'cat_default', name: 'Defaut', color: Colors.grey));
    }
    state.activeFloorId = data.floors.first.id;
    zones = ZoneController(state, data);
    pois = PoiController(state, data);
    undoManager = UndoManager(this);
    undoManager.saveState();
    initialized = true;
  }
  void loadData(StoreMapData initialData) {
    init(initialData);
  }
  void setTool(EditorTool t) {
    state.tool = t;
    state.selectedZoneId = null;
    state.selectedPoiId = null;
  }
  EditorTool get tool => state.tool;
  String? get selectedZoneId => state.selectedZoneId;
  String? get selectedPoiId => state.selectedPoiId;
  // Delegates
  void undo() => undoManager.undo();
  bool get canUndo => undoManager.canUndo;
  void saveUndoState() => undoManager.saveState();
  StoreMapData exportData() => data.deepCopy();
  List<StoreFloor> get floors => data.floors;
  String get activeFloorId => state.activeFloorId;
  List<StoreCategory> get categories => data.categories;
  String get activeCategoryId => state.activeCategoryId;
  List<StoreZone> get activeZones => data.zonesByFloor[state.activeFloorId] ?? const [];
  List<StorePoi> get activePois => data.poisByFloor[state.activeFloorId] ?? const [];
  void addFloor() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final f = StoreFloor(id: id, name: 'Etage', order: data.floors.length);
    data.floors.add(f);
    data.zonesByFloor[id] = [];
    data.poisByFloor[id] = [];
    setActiveFloor(id);
    saveUndoState();
  }
  void setActiveFloor(String id) {
    if (data.floors.any((f) => f.id == id)) {
      state.activeFloorId = id;
      state.selectedPoiId = null;
      state.selectedZoneId = null;
    }
  }
  void addCategory(String name) {
    if (name.isEmpty) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final c = StoreCategory(id: id, name: name, color: Colors.primaries[data.categories.length % Colors.primaries.length]);
    data.categories.add(c);
    setActiveCategory(id);
    saveUndoState();
  }
  void setActiveCategory(String id) {
    if (data.categories.any((c) => c.id == id)) {
      state.activeCategoryId = id;
    }
  }
  void renameCategory(String id, String name) {
    if (name.isEmpty) return;
    final c = data.categories.firstWhere((c) => c.id == id);
    c.name = name;
    saveUndoState();
  }
  bool deleteCategory(String id) {
    if (data.categories.length <= 1) return false;
    final inUse = data.zonesByFloor.values.expand((z) => z).any((z) => z.categoryId == id);
    if (inUse) return false;
    data.categories.removeWhere((c) => c.id == id);
    if (state.activeCategoryId == id) {
      state.activeCategoryId = data.categories.first.id;
    }
    saveUndoState();
    return true;
  }
  // Hit tests
  StoreZone? hitTestZone(double x, double y) => zones.hitTest(x, y);
  StorePoi? hitTestPoi(double x, double y) => pois.hitTest(x, y);
  // Deletion
  void deleteSelected() {
    bool changed = false;
    if (state.selectedZoneId != null) {
      zones.deleteZone(state.selectedZoneId!);
      state.selectedZoneId = null;
      changed = true;
    }
    if (state.selectedPoiId != null) {
      pois.deletePoi(state.selectedPoiId!);
      state.selectedPoiId = null;
      changed = true;
    }
    if (changed) saveUndoState();
  }
  // Zone specific overrides
  void startMoveZone(StoreZone z, double px, double py) => zones.startMove(z, px, py);
  bool updateMoveZone(StoreZone z, double px, double py) => zones.updateMove(z, px, py);
  void finishMoveZone() { zones.finishMove(); saveUndoState(); }
  // Poi specific overrides
  StorePoi? poiById(String id) => pois.poiById(id);
  void startMovePoi(StorePoi p, double px, double py) => pois.startMove(p, px, py);
  bool updateMovePoi(StorePoi p, double px, double py) => pois.updateMove(p, px, py);
  void finishMovePoi() { pois.finishMove(); saveUndoState(); }
  StorePoi? placePoi(PoiType type, Offset world) {
    final res = pois.placePoi(type, world);
    if (res != null) saveUndoState();
    return res;
  }
  bool get isDrawingZone => zones.isDrawing;
  void startDrawZone(ZoneShape shape, Offset world) => zones.startDraw(shape, world.dx, world.dy);
  void updateDrawZone(Offset world) => zones.updateDraw(world.dx, world.dy);
  void finishDrawZone() {
    zones.finishDraw();
    saveUndoState();
    setTool(EditorTool.select);
  }
}
