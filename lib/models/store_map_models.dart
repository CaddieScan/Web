import 'dart:math';
import 'dart:ui';

class StoreFloor {
  final String id;
  String name;
  int order;

  StoreFloor({required this.id, required this.name, required this.order});
}



class StoreCategory {
  final String id;
  String name;
  Color color;

  StoreCategory({
    required this.id,
    required this.name,
    required this.color,
  });
}


enum ZoneShape { rect, circle }

class StoreZone {
  final String id;
  final String floorId;

  String name;
  String categoryId;

  double x;
  double y;
  double w;
  double h;

  ZoneShape shape;

  StoreZone({
    required this.id,
    required this.floorId,
    required this.name,
    required this.categoryId,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.shape = ZoneShape.rect,
  });

  bool contains(double px, double py) {
    if (shape == ZoneShape.rect) {
      return px >= x && px <= x + w && py >= y && py <= y + h;
    }

    // circle: based on bounding box
    final cx = x + w / 2;
    final cy = y + h / 2;
    final r = min(w, h) / 2;

    final dx = px - cx;
    final dy = py - cy;
    return (dx * dx + dy * dy) <= (r * r);
  }
}
