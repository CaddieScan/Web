import 'dart:ui';

import '../../models/store_map_models.dart';
import '../../models/store_poi_models.dart';

import 'store_map_state.dart';
import 'store_map_data.dart';
import 'wall_controller.dart';
import 'aisle_controller.dart';
import 'poi_controller.dart';
import 'zone_controller.dart';


class StoreMapController {
  final StoreMapState state = StoreMapState();
  final StoreMapData data = StoreMapData();

  late final ZoneController zones;
  late final WallController walls;
  late final AisleController aisles;
  late final PoiController pois;

  int _id = 2000;

  StoreMapController() {
    zones = ZoneController(state, data);
    walls = WallController(state, data);
    aisles = AisleController(state, data);
    pois = PoiController(state, data);

    // init default floor
    final floor = StoreFloor(id: _newId('floor'), name: 'RDC', order: 0);
    data.floors.add(floor);
    data.ensureFloor(floor.id);
    state.activeFloorId = floor.id;

    // init default category
    final cat = StoreCategory(
      id: _newId('cat'),
      name: 'Par defaut',
      color: const Color(0xFF4CAF50),
      cornerRadius: 0, // rectangle
    );
    data.categories.add(cat);
    state.activeCategoryId = cat.id;
  }

  String _newId(String prefix) => '${prefix}_${_id++}';

  // --- Expose state-like properties
  EditorTool get tool => state.tool;
  set tool(EditorTool t) => setTool(t);

  double get gridSize => state.gridSize;

  bool get snapToGrid => state.snapToGrid;
  set snapToGrid(bool v) => state.snapToGrid = v;

  String? get activeFloorId => state.activeFloorId;
  String? get activeCategoryId => state.activeCategoryId;

  String? get hoveredZoneId => state.hoveredZoneId;
  String? get selectedZoneId => state.selectedZoneId;

  String? get hoveredPoiId => state.hoveredPoiId;
  String? get selectedPoiId => state.selectedPoiId;

  // --- collections
  List<StoreFloor> get floors => data.floors;
  List<StoreCategory> get categories => data.categories;

  List<StoreZone> get activeZones => zones.zones;
  StoreZone? get selectedZone => zones.zoneById(state.selectedZoneId ?? '');

  List<List<Offset>> get activeWalls => walls.walls;
  List<Offset> get activeAisleNodes => aisles.nodes;
  List<AisleEdge> get activeAisleEdges => aisles.edges;

  List<StorePoi> get activePois => data.poisByFloor[state.activeFloorId] ?? const [];

  // helpers
  StoreCategory categoryById(String id) => categories.firstWhere((c) => c.id == id);
  StoreZone? zoneById(String id) => zones.zoneById(id);
  StorePoi? poiById(String id) => pois.poiById(id);

  // --- state actions
  void setTool(EditorTool t) {
    state.tool = t;
    cancelAllInteractions();
  }

  void cancelAllInteractions() {
    zones.cancelDrawing();
    zones.cancelTransforms();
    walls.cancel();
    aisles.cancel();
    pois.cancelMove();
  }

  void clearHover() {
    state.hoveredZoneId = null;
    state.hoveredPoiId = null;
  }

  void clearSelection() {
    state.selectedZoneId = null;
    state.selectedPoiId = null;
    zones.cancelTransforms();
    pois.cancelMove();
  }

  // --- floors
  StoreFloor addFloor() {
    final f = StoreFloor(
      id: _newId('floor'),
      name: 'Etage ${data.floors.length}',
      order: data.floors.length,
    );
    data.floors.add(f);
    data.ensureFloor(f.id);
    setActiveFloor(f.id);
    return f;
  }

  void setActiveFloor(String id) {
    state.activeFloorId = id;
    clearHover();
    clearSelection();
    cancelAllInteractions();
  }

  // --- categories
  StoreCategory addCategory(String name) {
    final cat = StoreCategory(
      id: _newId('cat'),
      name: name,
      color: _autoColor(data.categories.length),
      cornerRadius: 0,
    );
    data.categories.add(cat);
    state.activeCategoryId = cat.id;
    return cat;
  }

  void renameCategory(String id, String name) {
    final c = data.categories.firstWhere((e) => e.id == id);
    c.name = name;
  }

  void setCategoryCornerRadius(String id, double radius) {
    final c = data.categories.firstWhere((e) => e.id == id);
    c.cornerRadius = radius.clamp(0, 40);
  }

  bool deleteCategory(String id) {
    if (data.categories.length <= 1) return false;

    final fallback = data.categories.firstWhere((c) => c.id != id);

    for (final entry in data.zonesByFloor.entries) {
      for (final z in entry.value) {
        if (z.categoryId == id) z.categoryId = fallback.id;
      }
    }

    data.categories.removeWhere((c) => c.id == id);
    if (state.activeCategoryId == id) state.activeCategoryId = fallback.id;
    return true;
  }

  void setActiveCategory(String id) => state.activeCategoryId = id;

  Color _autoColor(int index) {
    const palette = [
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFFFF9800),
      Color(0xFFE91E63),
      Color(0xFF9C27B0),
      Color(0xFF00BCD4),
      Color(0xFFFFC107),
      Color(0xFF607D8B),
    ];
    return palette[index % palette.length];
  }

  // --- Zones
  void selectZone(String? id) {
    state.selectedZoneId = id;
    if (id != null) state.selectedPoiId = null;
    zones.cancelTransforms();
  }

  StoreZone? hitTestZone(double x, double y) => zones.hitTestZone(x, y);

  void startRect(double x, double y) => zones.startRect(x, y);
  void updateRect(double x, double y) => zones.updateRect(x, y);

  StoreZone? finishRect({required String zoneName}) =>
      zones.finishRect(zoneName: zoneName, newId: _newId('zone'));

  bool get isDrawingRect => zones.isDrawing;
  StoreZone? get previewZone => zones.previewZone;

  void cancelDrawing() => zones.cancelDrawing();

  ResizeHandle? hitTestHandle({
    required StoreZone z,
    required double px,
    required double py,
    required double radiusWorld,
  }) =>
      zones.hitTestHandle(z: z, px: px, py: py, radiusWorld: radiusWorld);

  bool get isMoving => zones.isMoving;
  bool get isResizing => zones.isResizing;

  void startMove(StoreZone z, double px, double py) => zones.startMove(z, px, py);
  bool updateMove(StoreZone z, double px, double py) => zones.updateMove(z, px, py);
  void finishMove() => zones.finishMove();

  void startResize(StoreZone z, ResizeHandle h, double px, double py) => zones.startResize(z, h, px, py);
  bool updateResize(StoreZone z, double px, double py) => zones.updateResize(z, px, py);
  void finishResize() => zones.finishResize();

  void cancelTransforms() => zones.cancelTransforms();

  // --- Walls
  bool get isDrawingWall => walls.isDrawing;
  List<Offset> get currentWall => walls.current;
  Offset? get wallPreviewEnd => walls.previewEnd;

  void startWallPoint(Offset world) => walls.startPoint(world);
  void updateWallPreview(Offset world) => walls.updatePreview(world);
  void finishWall() => walls.finish();
  void cancelWallDrawing() => walls.cancel();

  // --- Aisles
  bool get isDrawingAisle => aisles.isDrawing;
  int? get lastAisleNodeIndex => aisles.lastNodeIndex;
  Offset? get aislePreviewEnd => aisles.previewEnd;

  void startAislePoint(Offset world) => aisles.startPoint(world);
  void updateAislePreview(Offset world) => aisles.updatePreview(world);
  void finishAisle() => aisles.finish();
  void cancelAisleDrawing() => aisles.cancel();

  // --- POI
  StorePoi? hitTestPoi(double x, double y) => pois.hitTest(x, y);

  void selectPoi(String? id) => pois.selectPoi(id);

  bool get isMovingPoi => pois.isMoving;
  void startMovePoi(StorePoi p, double px, double py) => pois.startMove(p, px, py);
  bool updateMovePoi(StorePoi p, double px, double py) => pois.updateMove(p, px, py);
  void finishMovePoi() => pois.finishMove();

  StorePoi? placePoi(PoiType type, Offset world) {
    final f = state.activeFloorId;
    if (f == null) return null;
    return pois.addPoi(id: _newId('poi'), floorId: f, type: type, world: world);
  }

  // --- Hover (zones + poi)
  void updateHover(double x, double y) {
    // POI d'abord (au dessus)
    pois.updateHover(x, y);
    if (state.hoveredPoiId != null) {
      state.hoveredZoneId = null;
      return;
    }
    zones.updateHover(x, y);
  }
}
