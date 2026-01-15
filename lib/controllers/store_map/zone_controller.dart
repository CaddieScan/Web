import 'dart:math';

import '../../../models/store_map_models.dart';
import 'store_map_data.dart';
import 'store_map_state.dart';

class ZoneController {
  final StoreMapState state;
  final StoreMapData data;

  ZoneController(this.state, this.data);

  // --- Drawing state
  bool isDrawing = false;
  ZoneShape? drawingShape; // rect | circle
  double? _startX;
  double? _startY;

  StoreZone? previewZone;

  // --- Transform state
  bool isMoving = false;
  bool isResizing = false;
  ResizeHandle? activeHandle;

  double _moveDx = 0;
  double _moveDy = 0;

  double _origX = 0, _origY = 0, _origW = 0, _origH = 0;
  double _pointerStartX = 0, _pointerStartY = 0;

  // --- Data access
  List<StoreZone> get zones => data.zonesByFloor[state.activeFloorId] ?? const [];

  StoreZone? zoneById(String id) {
    for (final z in zones) {
      if (z.id == id) return z;
    }
    return null;
  }

  // --- Hit tests
  StoreZone? hitTestZone(double x, double y) {
    // last drawn on top
    for (int i = zones.length - 1; i >= 0; i--) {
      final z = zones[i];
      if (z.contains(x, y)) return z;
    }
    return null;
  }

  ResizeHandle? hitTestHandle({
    required StoreZone z,
    required double px,
    required double py,
    required double radiusWorld,
  }) {
    // Handles are on bounding box corners (works for rect & circle)
    final corners = <(ResizeHandle, double, double)>[
      (ResizeHandle.tl, z.x, z.y),
      (ResizeHandle.tr, z.x + z.w, z.y),
      (ResizeHandle.bl, z.x, z.y + z.h),
      (ResizeHandle.br, z.x + z.w, z.y + z.h),
    ];

    for (final c in corners) {
      final dx = px - c.$2;
      final dy = py - c.$3;
      if (sqrt(dx * dx + dy * dy) <= radiusWorld) return c.$1;
    }
    return null;
  }

  // --- Hover
  void updateHover(double x, double y) {
    final z = hitTestZone(x, y);
    state.hoveredZoneId = z?.id;
  }

  // --- Cancel helpers
  void cancelDrawing() {
    isDrawing = false;
    drawingShape = null;
    _startX = null;
    _startY = null;
    previewZone = null;
  }

  void cancelTransforms() {
    isMoving = false;
    isResizing = false;
    activeHandle = null;
  }

  // ============================================================
  // DRAW RECT
  // ============================================================
  void startRect(double x, double y) => _startShape(ZoneShape.rect, x, y);
  void updateRect(double x, double y) => _updateShape(x, y);
  StoreZone? finishRect({required String zoneName, required String newId}) =>
      _finishShape(zoneName: zoneName, newId: newId);

  // ============================================================
  // DRAW CIRCLE
  // ============================================================
  void startCircle(double x, double y) => _startShape(ZoneShape.circle, x, y);
  void updateCircle(double x, double y) => _updateShape(x, y);
  StoreZone? finishCircle({required String zoneName, required String newId}) =>
      _finishShape(zoneName: zoneName, newId: newId);

  // ============================================================
  // INTERNAL DRAW LOGIC
  // ============================================================
  void _startShape(ZoneShape shape, double x, double y) {
    final floorId = state.activeFloorId;
    final catId = state.activeCategoryId;
    if (floorId == null || catId == null) return;

    cancelTransforms();

    isDrawing = true;
    drawingShape = shape;

    _startX = state.snap(x);
    _startY = state.snap(y);

    previewZone = StoreZone(
      id: 'preview',
      floorId: floorId,
      name: '',
      categoryId: catId,
      x: _startX!,
      y: _startY!,
      w: 0,
      h: 0,
      shape: shape,
    );
  }

  void _updateShape(double x, double y) {
    if (!isDrawing || previewZone == null || _startX == null || _startY == null) return;

    final sx = _startX!;
    final sy = _startY!;
    final ex = state.snap(x);
    final ey = state.snap(y);

    if (drawingShape == ZoneShape.rect) {
      final left = min(sx, ex);
      final top = min(sy, ey);
      final w = (sx - ex).abs();
      final h = (sy - ey).abs();

      previewZone!
        ..x = left
        ..y = top
        ..w = w
        ..h = h
        ..shape = ZoneShape.rect;
      return;
    }

    // circle => bounding square
    final left = min(sx, ex);
    final top = min(sy, ey);
    final wRaw = (sx - ex).abs();
    final hRaw = (sy - ey).abs();
    final size = max(wRaw, hRaw);

    previewZone!
      ..x = left
      ..y = top
      ..w = size
      ..h = size
      ..shape = ZoneShape.circle;
  }

  StoreZone? _finishShape({required String zoneName, required String newId}) {
    if (!isDrawing || previewZone == null) return null;

    final minSize = state.gridSize;
    if (previewZone!.w < minSize || previewZone!.h < minSize) {
      cancelDrawing();
      return null;
    }

    final z = StoreZone(
      id: newId,
      floorId: previewZone!.floorId,
      name: zoneName,
      categoryId: previewZone!.categoryId,
      x: previewZone!.x,
      y: previewZone!.y,
      w: previewZone!.w,
      h: previewZone!.h,
      shape: previewZone!.shape,
    );

    data.zonesByFloor[z.floorId]!.add(z);

    cancelDrawing();
    state.selectedZoneId = z.id;
    return z;
  }

  // ============================================================
  // MOVE / RESIZE
  // ============================================================
  void startMove(StoreZone z, double px, double py) {
    cancelDrawing();
    cancelTransforms();

    isMoving = true;
    _moveDx = px - z.x;
    _moveDy = py - z.y;
  }

  bool updateMove(StoreZone z, double px, double py) {
    if (!isMoving) return false;

    final nx = state.snapToGrid ? state.snap(px - _moveDx) : (px - _moveDx);
    final ny = state.snapToGrid ? state.snap(py - _moveDy) : (py - _moveDy);

    final changed = nx != z.x || ny != z.y;
    z.x = nx;
    z.y = ny;
    return changed;
  }

  void finishMove() => isMoving = false;

  void startResize(StoreZone z, ResizeHandle handle, double px, double py) {
    cancelDrawing();
    cancelTransforms();

    isResizing = true;
    activeHandle = handle;

    _origX = z.x;
    _origY = z.y;
    _origW = z.w;
    _origH = z.h;

    _pointerStartX = px;
    _pointerStartY = py;
  }

  bool updateResize(StoreZone z, double px, double py) {
    if (!isResizing || activeHandle == null) return false;

    final dx = px - _pointerStartX;
    final dy = py - _pointerStartY;

    double x = _origX, y = _origY, w = _origW, h = _origH;

    switch (activeHandle!) {
      case ResizeHandle.tl:
        x = _origX + dx;
        y = _origY + dy;
        w = _origW - dx;
        h = _origH - dy;
        break;
      case ResizeHandle.tr:
        y = _origY + dy;
        w = _origW + dx;
        h = _origH - dy;
        break;
      case ResizeHandle.bl:
        x = _origX + dx;
        w = _origW - dx;
        h = _origH + dy;
        break;
      case ResizeHandle.br:
        w = _origW + dx;
        h = _origH + dy;
        break;
    }

    final minSize = state.gridSize;
    w = max(w, minSize);
    h = max(h, minSize);

    // circle must stay square
    if (z.shape == ZoneShape.circle) {
      final size = max(w, h);
      w = size;
      h = size;
    }

    if (state.snapToGrid) {
      x = state.snap(x);
      y = state.snap(y);
      w = state.snap(w);
      h = state.snap(h);
    }

    final changed = x != z.x || y != z.y || w != z.w || h != z.h;
    z.x = x;
    z.y = y;
    z.w = w;
    z.h = h;
    return changed;
  }

  void finishResize() {
    isResizing = false;
    activeHandle = null;
  }
}
