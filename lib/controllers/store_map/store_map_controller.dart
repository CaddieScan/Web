import 'dart:ui';

import '../../models/store_map_models.dart';
import '../../models/store_poi_models.dart';

import 'store_map_state.dart';
import 'store_map_data.dart';
import 'wall_controller.dart';
import 'aisle_controller.dart';
import 'poi_controller.dart';
import 'zone_controller.dart';
import 'undo/undo_manager.dart';

class StoreMapController {
  StoreMapState state = StoreMapState();
  StoreMapData data = StoreMapData();

  late ZoneController zones;
  late WallController walls;
  late AisleController aisles;
  late PoiController pois;

  final UndoManager undoManager = UndoManager(maxSize: 80);

  int _id = 2000;

  StoreMapController() {
    _rebindControllers();

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
    );
    data.categories.add(cat);
    state.activeCategoryId = cat.id;
  }

  void _rebindControllers() {
    zones = ZoneController(state, data);
    walls = WallController(state, data);
    aisles = AisleController(state, data);
    pois = PoiController(state, data);
  }

  String _newId(String prefix) => '${prefix}_${_id++}';

  // ---------------- UNDO ----------------
  void pushUndo() => undoManager.push(state, data);

  bool get canUndo => undoManager.canUndo;

  void undo() {
    final snap = undoManager.undo();
    if (snap == null) return;

    state = snap.state;
    data = snap.data;

    _rebindControllers();

    cancelAllInteractions();
    clearHover();
    // (on garde la sélection telle quelle, ou tu peux clearSelection si tu préfères)
  }


  // ---------------- GETTERS (state) ----------------
  EditorTool get tool => state.tool;

  double get gridSize => state.gridSize;

  String? get activeFloorId => state.activeFloorId;
  String? get activeCategoryId => state.activeCategoryId;

  String? get hoveredZoneId => state.hoveredZoneId;
  String? get selectedZoneId => state.selectedZoneId;

  String? get hoveredPoiId => state.hoveredPoiId;
  String? get selectedPoiId => state.selectedPoiId;

  int? get selectedWallIndex => state.selectedWallIndex;
  int? get selectedAisleNodeIndex => state.selectedAisleNodeIndex;
  int? get selectedAisleEdgeIndex => state.selectedAisleEdgeIndex;

  bool get snapToGrid => state.snapToGrid;

  // ---------------- GETTERS (data) ----------------
  List<StoreFloor> get floors => data.floors;
  List<StoreCategory> get categories => data.categories;

  List<StoreZone> get activeZones => data.zonesByFloor[state.activeFloorId] ?? const [];
  List<List<Offset>> get activeWalls => data.wallsByFloor[state.activeFloorId] ?? const [];

  List<Offset> get activeAisleNodes => data.aisleNodesByFloor[state.activeFloorId] ?? const [];
  List<AisleEdge> get activeAisleEdges => data.aisleEdgesByFloor[state.activeFloorId] ?? const [];

  List<StorePoi> get activePois => data.poisByFloor[state.activeFloorId] ?? const [];

  // ---------------- HELPERS ----------------
  StoreCategory categoryById(String id) => categories.firstWhere((c) => c.id == id);

  StoreZone? zoneById(String id) => zones.zoneById(id);

  StoreZone? get selectedZone =>
      (state.selectedZoneId == null) ? null : zones.zoneById(state.selectedZoneId!);

  StorePoi? poiById(String id) => pois.poiById(id);

  // ---------------- TOOL ----------------
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

    state.selectedWallIndex = null;
    state.selectedAisleNodeIndex = null;
    state.selectedAisleEdgeIndex = null;

    zones.cancelTransforms();
    pois.cancelMove();
  }

  // ---------------- FLOORS ----------------
  StoreFloor addFloor() {
    pushUndo();

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

  // ---------------- CATEGORIES ----------------
  StoreCategory addCategory(String name) {
    pushUndo();

    final cat = StoreCategory(
      id: _newId('cat'),
      name: name,
      color: _autoColor(data.categories.length),
    );
    data.categories.add(cat);
    state.activeCategoryId = cat.id;
    return cat;
  }

  void renameCategory(String id, String name) {
    pushUndo();
    final c = data.categories.firstWhere((e) => e.id == id);
    c.name = name;
  }

  bool deleteCategory(String id) {
    if (data.categories.length <= 1) return false;

    pushUndo();

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

  // ---------------- ZONES ----------------
  void selectZone(String? id) {
    state.selectedZoneId = id;
    if (id != null) {
      state.selectedPoiId = null;
      state.selectedWallIndex = null;
      state.selectedAisleNodeIndex = null;
      state.selectedAisleEdgeIndex = null;
    }
    zones.cancelTransforms();
  }

  StoreZone? hitTestZone(double x, double y) => zones.hitTestZone(x, y);

  bool get isDrawingRect => zones.isDrawing && zones.drawingShape == ZoneShape.rect;
  bool get isDrawingCircle => zones.isDrawing && zones.drawingShape == ZoneShape.circle;
  StoreZone? get previewZone => zones.previewZone;

  void cancelDrawing() => zones.cancelDrawing();

  void startRect(double x, double y) => zones.startRect(x, y);
  void updateRect(double x, double y) => zones.updateRect(x, y);

  StoreZone? finishRect({required String zoneName}) {
    pushUndo();
    return zones.finishRect(zoneName: zoneName, newId: _newId('zone'));
  }

  void startCircle(double x, double y) => zones.startCircle(x, y);
  void updateCircle(double x, double y) => zones.updateCircle(x, y);

  StoreZone? finishCircle({required String zoneName}) {
    pushUndo();
    return zones.finishCircle(zoneName: zoneName, newId: _newId('zone'));
  }

  ResizeHandle? hitTestHandle({
    required StoreZone z,
    required double px,
    required double py,
    required double radiusWorld,
  }) =>
      zones.hitTestHandle(z: z, px: px, py: py, radiusWorld: radiusWorld);

  bool get isMoving => zones.isMoving;
  bool get isResizing => zones.isResizing;

  void startMove(StoreZone z, double px, double py) {
    pushUndo();
    zones.startMove(z, px, py);
  }

  bool updateMove(StoreZone z, double px, double py) => zones.updateMove(z, px, py);
  void finishMove() => zones.finishMove();

  void startResize(StoreZone z, ResizeHandle h, double px, double py) {
    pushUndo();
    zones.startResize(z, h, px, py);
  }

  bool updateResize(StoreZone z, double px, double py) => zones.updateResize(z, px, py);
  void finishResize() => zones.finishResize();

  // ---------------- WALLS ----------------
  bool get isDrawingWall => walls.isDrawing;
  List<Offset> get currentWall => walls.current;
  Offset? get wallPreviewEnd => walls.previewEnd;

  void startWallPoint(Offset world) => walls.startPoint(world);
  void updateWallPreview(Offset world) => walls.updatePreview(world);

  void finishWall() {
    pushUndo();
    walls.finish();
  }

  void cancelWallDrawing() => walls.cancel();

  // ---------------- AISLES ----------------
  bool get isDrawingAisle => aisles.isDrawing;
  int? get lastAisleNodeIndex => aisles.lastNodeIndex;
  Offset? get aislePreviewEnd => aisles.previewEnd;

  void startAislePoint(Offset world) => aisles.startPoint(world);
  void updateAislePreview(Offset world) => aisles.updatePreview(world);

  void finishAisle() {
    pushUndo();
    aisles.finish();
  }

  void cancelAisleDrawing() => aisles.cancel();

  // ---------------- POI ----------------
  StorePoi? hitTestPoi(double x, double y) => pois.hitTest(x, y);

  void selectPoi(String? id) {
    state.selectedPoiId = id;
    if (id != null) {
      state.selectedZoneId = null;
      state.selectedWallIndex = null;
      state.selectedAisleNodeIndex = null;
      state.selectedAisleEdgeIndex = null;
    }
  }

  bool get isMovingPoi => pois.isMoving;

  void startMovePoi(StorePoi p, double px, double py) {
    pushUndo();
    pois.startMove(p, px, py);
  }

  bool updateMovePoi(StorePoi p, double px, double py) => pois.updateMove(p, px, py);
  void finishMovePoi() => pois.finishMove();

  StorePoi? placePoi(PoiType type, Offset world) {
    pushUndo();
    final f = state.activeFloorId;
    if (f == null) return null;
    return pois.addPoi(id: _newId('poi'), floorId: f, type: type, world: world);
  }

  // ---------------- HOVER ----------------
  void updateHover(double x, double y) {
    pois.updateHover(x, y);
    if (state.hoveredPoiId != null) {
      state.hoveredZoneId = null;
      return;
    }
    zones.updateHover(x, y);
  }

  // ---------------- HIT TESTS (WALL / AISLES) ----------------
  double _distPointToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;

    final abLen2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (abLen2 == 0) return (p - a).distance;

    double t = (ap.dx * ab.dx + ap.dy * ab.dy) / abLen2;
    t = t.clamp(0.0, 1.0);

    final proj = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (p - proj).distance;
  }

  int? hitTestWallIndex(Offset world, {required double thresholdWorld}) {
    final floorId = state.activeFloorId;
    if (floorId == null) return null;

    final wallsList = data.wallsByFloor[floorId] ?? const [];
    for (int i = wallsList.length - 1; i >= 0; i--) {
      final poly = wallsList[i];
      if (poly.length < 2) continue;

      for (int j = 0; j < poly.length - 1; j++) {
        final d = _distPointToSegment(world, poly[j], poly[j + 1]);
        if (d <= thresholdWorld) return i;
      }
    }
    return null;
  }

  int? hitTestAisleNodeIndex(Offset world, {required double radiusWorld}) {
    final floorId = state.activeFloorId;
    if (floorId == null) return null;

    final nodes = data.aisleNodesByFloor[floorId] ?? const [];
    for (int i = nodes.length - 1; i >= 0; i--) {
      if ((nodes[i] - world).distance <= radiusWorld) return i;
    }
    return null;
  }

  int? hitTestAisleEdgeIndex(Offset world, {required double thresholdWorld}) {
    final floorId = state.activeFloorId;
    if (floorId == null) return null;

    final nodes = data.aisleNodesByFloor[floorId] ?? const [];
    final edges = data.aisleEdgesByFloor[floorId] ?? const [];

    for (int i = edges.length - 1; i >= 0; i--) {
      final e = edges[i];
      if (e.a < 0 || e.a >= nodes.length) continue;
      if (e.b < 0 || e.b >= nodes.length) continue;

      final d = _distPointToSegment(world, nodes[e.a], nodes[e.b]);
      if (d <= thresholdWorld) return i;
    }
    return null;
  }

  // ---------------- SELECT (WALL / AISLES) ----------------
  void selectWall(int? index) {
    state.selectedWallIndex = index;
    if (index != null) {
      state.selectedZoneId = null;
      state.selectedPoiId = null;
      state.selectedAisleNodeIndex = null;
      state.selectedAisleEdgeIndex = null;
    }
  }

  void selectAisleNode(int? index) {
    state.selectedAisleNodeIndex = index;
    if (index != null) {
      state.selectedZoneId = null;
      state.selectedPoiId = null;
      state.selectedWallIndex = null;
      state.selectedAisleEdgeIndex = null;
    }
  }

  void selectAisleEdge(int? index) {
    state.selectedAisleEdgeIndex = index;
    if (index != null) {
      state.selectedZoneId = null;
      state.selectedPoiId = null;
      state.selectedWallIndex = null;
      state.selectedAisleNodeIndex = null;
    }
  }

  // ---------------- DELETE ----------------
  void deleteSelected() {
    final floorId = state.activeFloorId;
    if (floorId == null) return;

    // Zone
    if (state.selectedZoneId != null) {
      pushUndo();
      final list = data.zonesByFloor[floorId]!;
      list.removeWhere((z) => z.id == state.selectedZoneId);
      state.selectedZoneId = null;
      return;
    }

    // POI
    if (state.selectedPoiId != null) {
      pushUndo();
      final list = data.poisByFloor[floorId]!;
      list.removeWhere((p) => p.id == state.selectedPoiId);
      state.selectedPoiId = null;
      return;
    }

    // Wall polyline
    if (state.selectedWallIndex != null) {
      pushUndo();
      final wallsList = data.wallsByFloor[floorId]!;
      final idx = state.selectedWallIndex!;
      if (idx >= 0 && idx < wallsList.length) wallsList.removeAt(idx);
      state.selectedWallIndex = null;
      return;
    }

    // Aisle edge
    if (state.selectedAisleEdgeIndex != null) {
      pushUndo();
      final edges = data.aisleEdgesByFloor[floorId]!;
      final idx = state.selectedAisleEdgeIndex!;
      if (idx >= 0 && idx < edges.length) edges.removeAt(idx);
      state.selectedAisleEdgeIndex = null;
      return;
    }

    // Aisle node (remove node + rebuild edges with remapped indices)
    if (state.selectedAisleNodeIndex != null) {
      pushUndo();

      final nodes = data.aisleNodesByFloor[floorId]!;
      final edges = data.aisleEdgesByFloor[floorId]!;
      final idx = state.selectedAisleNodeIndex!;

      if (idx < 0 || idx >= nodes.length) {
        state.selectedAisleNodeIndex = null;
        return;
      }

      nodes.removeAt(idx);

      final newEdges = <AisleEdge>[];
      for (final e in edges) {
        // drop edges linked to deleted node
        if (e.a == idx || e.b == idx) continue;

        final na = (e.a > idx) ? e.a - 1 : e.a;
        final nb = (e.b > idx) ? e.b - 1 : e.b;

        if (na >= 0 && nb >= 0 && na < nodes.length && nb < nodes.length) {
          newEdges.add(AisleEdge(na, nb));
        }
      }

      data.aisleEdgesByFloor[floorId] = newEdges;
      state.selectedAisleNodeIndex = null;
      return;
    }
  }
}
