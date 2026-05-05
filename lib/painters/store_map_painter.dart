import 'dart:math';
import 'package:flutter/material.dart';
import '../../controllers/store_map/store_map_controller.dart';
import '../../controllers/store_map/store_map_state.dart';
import '../../models/store_map_models.dart';
import '../../models/store_poi_models.dart';
class StoreMapPainter extends CustomPainter {
  final StoreMapController ctrl;
  final double scale;
  final Offset pan;
  StoreMapPainter({
    required this.ctrl,
    required this.scale,
    required this.pan,
  });
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(pan.dx, pan.dy);
    canvas.scale(scale);
    drawGrid(canvas, size);
    drawZones(canvas);
    drawDrawingZone(canvas);
    drawPois(canvas);
    canvas.restore();
  }
  void drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1 / scale;
    final gridSize = 20.0;
    final viewRect = Rect.fromLTWH(
      -pan.dx / scale,
      -pan.dy / scale,
      size.width / scale,
      size.height / scale,
    );
    final startX = (viewRect.left / gridSize).floor() * gridSize;
    final endX = (viewRect.right / gridSize).ceil() * gridSize;
    final startY = (viewRect.top / gridSize).floor() * gridSize;
    final endY = (viewRect.bottom / gridSize).ceil() * gridSize;
    for (var x = startX; x <= endX; x += gridSize) {
      canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
    }
    for (var y = startY; y <= endY; y += gridSize) {
      canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
    }
  }
  void drawZones(Canvas canvas) {
    final activeFloor = ctrl.state.activeFloorId;
    if (activeFloor.isEmpty) return;
    final zones = ctrl.data.zonesByFloor[activeFloor] ?? [];
    for (final z in zones) {
      final isSelected = z.id == ctrl.selectedZoneId;
      final cat = ctrl.data.categories.firstWhere(
        (c) => c.id == z.categoryId,
        orElse: () => StoreCategory(id: '', name: 'Inconnu', color: Colors.grey),
      );
      final paint = Paint()
        ..color = cat.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = isSelected ? Colors.blue : cat.color
        ..strokeWidth = isSelected ? 2 / scale : 1 / scale
        ..style = PaintingStyle.stroke;
      if (z.shape == ZoneShape.rect) {
        final r = Rect.fromLTWH(z.x, z.y, z.w, z.h);
        canvas.drawRect(r, paint);
        canvas.drawRect(r, borderPaint);
      } else {
        final cx = z.x + z.w / 2;
        final cy = z.y + z.h / 2;
        final radius = min(z.w, z.h) / 2;
        canvas.drawCircle(Offset(cx, cy), radius, paint);
        canvas.drawCircle(Offset(cx, cy), radius, borderPaint);
      }
    }
  }
  void drawDrawingZone(Canvas canvas) {
    if (!ctrl.isDrawingZone) return;
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1 / scale
      ..style = PaintingStyle.stroke;
    final zc = ctrl.zones;
    final left = min(zc.startX, zc.currX);
    final top = min(zc.startY, zc.currY);
    final w = (zc.currX - zc.startX).abs();
    final h = (zc.currY - zc.startY).abs();
    if (zc.drawShape == ZoneShape.rect) {
      final r = Rect.fromLTWH(left, top, w, h);
      canvas.drawRect(r, paint);
      canvas.drawRect(r, borderPaint);
    } else {
      final cx = left + w / 2;
      final cy = top + h / 2;
      final radius = min(w, h) / 2;
      canvas.drawCircle(Offset(cx, cy), radius, paint);
      canvas.drawCircle(Offset(cx, cy), radius, borderPaint);
    }
  }
  void drawPois(Canvas canvas) {
    for (final p in ctrl.activePois) {
      final isSelected = p.id == ctrl.selectedPoiId;
      var color = Colors.green;
      if (p.type == PoiType.exit) color = Colors.red;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final border = Paint()
        ..color = isSelected ? Colors.yellow : Colors.white
        ..strokeWidth = 2 / scale
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(p.x, p.y), 10, paint);
      canvas.drawCircle(Offset(p.x, p.y), 10, border);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
