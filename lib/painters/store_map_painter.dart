import 'dart:ui';

import 'package:flutter/material.dart';

import '../controllers/store_map/store_map_controller.dart';
import '../models/store_poi_models.dart';

class StoreMapPainter extends CustomPainter {
  final StoreMapController ctrl;
  final double zoom;
  final Offset pan;

  StoreMapPainter({
    required this.ctrl,
    required this.zoom,
    required this.pan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(pan.dx, pan.dy);
    canvas.scale(zoom);

    _drawGrid(canvas, size);
    _drawWalls(canvas);
    _drawAisles(canvas);
    _drawZones(canvas);
    _drawPois(canvas);

    canvas.restore();
  }

  void _drawGrid(Canvas canvas, Size size) {
    final grid = ctrl.gridSize;

    final paint = Paint()
      ..color = const Color(0xFF000000).withOpacity(0.05)
      ..strokeWidth = 1;

    final w = size.width / zoom;
    final h = size.height / zoom;

    for (double x = -w; x < w * 2; x += grid) {
      canvas.drawLine(Offset(x, -h), Offset(x, h * 2), paint);
    }
    for (double y = -h; y < h * 2; y += grid) {
      canvas.drawLine(Offset(-w, y), Offset(w * 2, y), paint);
    }
  }

  void _drawWalls(Canvas canvas) {
    final walls = ctrl.activeWalls;

    final wallPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final poly in walls) {
      if (poly.length < 2) continue;
      final path = Path()..moveTo(poly.first.dx, poly.first.dy);
      for (int i = 1; i < poly.length; i++) {
        path.lineTo(poly[i].dx, poly[i].dy);
      }
      canvas.drawPath(path, wallPaint);
    }

    if (ctrl.isDrawingWall && ctrl.currentWall.isNotEmpty) {
      final pts = ctrl.currentWall;
      final preview = ctrl.wallPreviewEnd;

      final p = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < pts.length; i++) {
        p.lineTo(pts[i].dx, pts[i].dy);
      }
      if (preview != null) p.lineTo(preview.dx, preview.dy);

      final previewPaint = Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(p, previewPaint);
    }
  }

  void _drawAisles(Canvas canvas) {
    final nodes = ctrl.activeAisleNodes;
    final edges = ctrl.activeAisleEdges;

    final edgePaint = Paint()
      ..color = Colors.blueGrey.withOpacity(0.75)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final e in edges) {
      if (e.a < 0 || e.a >= nodes.length) continue;
      if (e.b < 0 || e.b >= nodes.length) continue;
      canvas.drawLine(nodes[e.a], nodes[e.b], edgePaint);
    }

    final nodeRadius = 4 / zoom;
    final nodePaint = Paint()..color = Colors.blueGrey.withOpacity(0.9);
    for (final n in nodes) {
      canvas.drawCircle(n, nodeRadius, nodePaint);
    }

    if (ctrl.isDrawingAisle && ctrl.lastAisleNodeIndex != null && ctrl.aislePreviewEnd != null) {
      final a = ctrl.lastAisleNodeIndex!;
      if (a >= 0 && a < nodes.length) {
        final previewPaint = Paint()
          ..color = Colors.blueGrey.withOpacity(0.35)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(nodes[a], ctrl.aislePreviewEnd!, previewPaint);
      }
    }
  }

  void _drawZones(Canvas canvas) {
    for (final z in ctrl.activeZones) {
      final cat = ctrl.categoryById(z.categoryId);
      final isHover = ctrl.hoveredZoneId == z.id;
      final isSelected = ctrl.selectedZoneId == z.id;

      final fill = Paint()
        ..color = cat.color.withOpacity(isHover ? 0.35 : 0.22)
        ..style = PaintingStyle.fill;

      final stroke = Paint()
        ..color = cat.color.withOpacity(isSelected ? 1.0 : (isHover ? 0.95 : 0.75))
        ..strokeWidth = isSelected ? 3.5 : (isHover ? 3 : 2)
        ..style = PaintingStyle.stroke;

      final rect = Rect.fromLTWH(z.x, z.y, z.w, z.h);

      if (cat.cornerRadius <= 0) {
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, stroke);
      } else {
        final rr = RRect.fromRectAndRadius(rect, Radius.circular(cat.cornerRadius));
        canvas.drawRRect(rr, fill);
        canvas.drawRRect(rr, stroke);
      }

      // handles si sélection
      if (isSelected) {
        final handleWorld = 7 / zoom;
        final handleFill = Paint()..color = Colors.white;
        final handleStroke = Paint()
          ..color = Colors.black.withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

        final pts = [
          Offset(z.x, z.y),
          Offset(z.x + z.w, z.y),
          Offset(z.x, z.y + z.h),
          Offset(z.x + z.w, z.y + z.h),
        ];

        for (final p in pts) {
          final r = Rect.fromCenter(center: p, width: handleWorld * 2, height: handleWorld * 2);
          canvas.drawRect(r, handleFill);
          canvas.drawRect(r, handleStroke);
        }
      }
    }

    // preview zone
    final pz = ctrl.previewZone;
    if (ctrl.isDrawingRect && pz != null) {
      final cat = ctrl.categoryById(pz.categoryId);

      final fill = Paint()
        ..color = cat.color.withOpacity(0.18)
        ..style = PaintingStyle.fill;

      final stroke = Paint()
        ..color = cat.color.withOpacity(0.9)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final rect = Rect.fromLTWH(pz.x, pz.y, pz.w, pz.h);

      if (cat.cornerRadius <= 0) {
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, stroke);
      } else {
        final rr = RRect.fromRectAndRadius(rect, Radius.circular(cat.cornerRadius));
        canvas.drawRRect(rr, fill);
        canvas.drawRRect(rr, stroke);
      }
    }
  }

  void _drawPois(Canvas canvas) {
    final radius = 12 / zoom;

    for (final p in ctrl.activePois) {
      final isHover = ctrl.hoveredPoiId == p.id;
      final isSelected = ctrl.selectedPoiId == p.id;

      final baseColor = _poiColor(p.type);

      final fill = Paint()
        ..color = baseColor.withOpacity(isHover ? 0.95 : 0.85)
        ..style = PaintingStyle.fill;

      final stroke = Paint()
        ..color = Colors.black.withOpacity(isSelected ? 0.65 : 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 / zoom : 2 / zoom;

      final center = Offset(p.x, p.y);
      canvas.drawCircle(center, radius, fill);
      canvas.drawCircle(center, radius, stroke);

      final text = _poiLetter(p.type);
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14 / zoom,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  Color _poiColor(PoiType type) {
    switch (type) {
      case PoiType.entry:
        return const Color(0xFF2E7D32);
      case PoiType.exit:
        return const Color(0xFFC62828);
      case PoiType.checkout:
        return const Color(0xFF1565C0);
    }
  }

  String _poiLetter(PoiType type) {
    switch (type) {
      case PoiType.entry:
        return 'E';
      case PoiType.exit:
        return 'S';
      case PoiType.checkout:
        return 'C';
    }
  }

  @override
  bool shouldRepaint(covariant StoreMapPainter oldDelegate) => true;
}
