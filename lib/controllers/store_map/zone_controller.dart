import 'dart:math';
import 'dart:ui';

import 'store_map_state.dart';
import 'store_map_data.dart';
import '../../models/store_map_models.dart';

class ZoneController {
  final StoreMapState state;
  final StoreMapData data;

  bool isDrawing = false;
  double? startX;
  double? startY;
  StoreZone? previewZone;

  // move/resize
  bool isMoving = false;
  bool isResizing = false;
  ResizeHandle? activeHandle;

  double _moveDx = 0;
  double _moveDy = 0;

  double _startX = 0, _startY = 0, _startW = 0, _startH = 0;
  double _startPointerX = 0, _startPointerY = 0;

  ZoneController(this.state, this.data);

  List<StoreZone> get zones => data.zonesByFloor[state.activeFloorId] ?? const [];

  StoreZone? zoneById(String id) {
    for (final z in zones) {
      if (z.id == id) return z;
    }
    return null;
  }

  StoreZone? hitTestZone(double x, double y) {
    final z = zones.reversed.cast<StoreZone?>().firstWhere(
          (zone) => zone != null && zone.contains(x, y),
      orElse: () => null,
    );
    return z;
  }

  void startRect(double x, double y) {
    final f = state.activeFloorId;
    final c = state.activeCategoryId;
    if (f == null || c == null) return;

    cancelTransforms();
    state.selectedZoneId = null;

    isDrawing = true;
    startX = state.snap(x);
    startY = state.snap(y);

    previewZone = StoreZone(
      id: 'preview',
      floorId: f,
      name: '',
      categoryId: c,
      x: startX!,
      y: startY!,
      w: 0,
      h: 0,
    );
  }

  void updateRect(double x, double y) {
    if (!isDrawing || previewZone == null) return;

    final sx = startX ?? 0;
    final sy = startY ?? 0;

    final ex = state.snap(x);
    final ey = state.snap(y);

    final left = min(sx, ex);
    final top = min(sy, ey);
    final w = (sx - ex).abs();
    final h = (sy - ey).abs();

    previewZone!
      ..x = left
      ..y = top
      ..w = w
      ..h = h;
  }

  StoreZone? finishRect({required String zoneName, required String newId}) {
    if (!isDrawing || previewZone == null) return null;

    if (previewZone!.w < state.gridSize || previewZone!.h < state.gridSize) {
      cancelDrawing();
      return null;
    }

    final zone = StoreZone(
      id: newId,
      floorId: previewZone!.floorId,
      name: zoneName,
      categoryId: previewZone!.categoryId,
      x: previewZone!.x,
      y: previewZone!.y,
      w: previewZone!.w,
      h: previewZone!.h,
    );

    data.zonesByFloor[zone.floorId]!.add(zone);

    cancelDrawing();
    state.selectedZoneId = zone.id;
    return zone;
  }

  void cancelDrawing() {
    isDrawing = false;
    startX = null;
    startY = null;
    previewZone = null;
  }

  // handles
  List<(ResizeHandle, Offset)> getHandles(StoreZone z) {
    return [
      (ResizeHandle.tl, Offset(z.x, z.y)),
      (ResizeHandle.tr, Offset(z.x + z.w, z.y)),
      (ResizeHandle.bl, Offset(z.x, z.y + z.h)),
      (ResizeHandle.br, Offset(z.x + z.w, z.y + z.h)),
    ];
  }

  ResizeHandle? hitTestHandle({
    required StoreZone z,
    required double px,
    required double py,
    required double radiusWorld,
  }) {
    for (final (h, p) in getHandles(z)) {
      final dx = px - p.dx;
      final dy = py - p.dy;
      if (sqrt(dx * dx + dy * dy) <= radiusWorld) return h;
    }
    return null;
  }

  // move
  void startMove(StoreZone z, double px, double py) {
    cancelDrawing();
    isMoving = true;
    isResizing = false;
    activeHandle = null;

    _moveDx = px - z.x;
    _moveDy = py - z.y;
  }

  bool updateMove(StoreZone z, double px, double py) {
    if (!isMoving) return false;

    final nx = state.snapToGrid ? state.snap(px - _moveDx) : (px - _moveDx);
    final ny = state.snapToGrid ? state.snap(py - _moveDy) : (py - _moveDy);

    final changed = (nx != z.x) || (ny != z.y);
    z.x = nx;
    z.y = ny;
    return changed;
  }

  void finishMove() => isMoving = false;

  // resize
  void startResize(StoreZone z, ResizeHandle handle, double px, double py) {
    cancelDrawing();
    isResizing = true;
    isMoving = false;
    activeHandle = handle;

    _startX = z.x;
    _startY = z.y;
    _startW = z.w;
    _startH = z.h;

    _startPointerX = px;
    _startPointerY = py;
  }

  bool updateResize(StoreZone z, double px, double py) {
    if (!isResizing || activeHandle == null) return false;

    final dx = px - _startPointerX;
    final dy = py - _startPointerY;

    double x = _startX, y = _startY, w = _startW, h = _startH;

    switch (activeHandle!) {
      case ResizeHandle.tl:
        x = _startX + dx;
        y = _startY + dy;
        w = _startW - dx;
        h = _startH - dy;
        break;
      case ResizeHandle.tr:
        y = _startY + dy;
        w = _startW + dx;
        h = _startH - dy;
        break;
      case ResizeHandle.bl:
        x = _startX + dx;
        w = _startW - dx;
        h = _startH + dy;
        break;
      case ResizeHandle.br:
        w = _startW + dx;
        h = _startH + dy;
        break;
    }

    final minSize = state.gridSize;
    if (w < minSize) w = minSize;
    if (h < minSize) h = minSize;

    if (state.snapToGrid) {
      x = state.snap(x);
      y = state.snap(y);
      w = state.snap(w);
      h = state.snap(h);
    }

    final changed = (x != z.x) || (y != z.y) || (w != z.w) || (h != z.h);
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

  void cancelTransforms() {
    isMoving = false;
    isResizing = false;
    activeHandle = null;
  }

  void updateHover(double x, double y) {
    final z = hitTestZone(x, y);
    state.hoveredZoneId = z?.id;
  }
}
