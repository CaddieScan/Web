import 'dart:math';
import 'dart:ui';

class StoreFloor {
  final String id;
  String name;
  int order;

  StoreFloor({required this.id, required this.name, required this.order});

  factory StoreFloor.fromJson(Map<String, dynamic> json) => StoreFloor(
        id: json['id'].toString(),
        name: json['name'] as String,
        order: (json['order'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'order': order,
      };
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

  factory StoreCategory.fromJson(Map<String, dynamic> json) => StoreCategory(
        id: json['id'].toString(),
        name: json['name'] as String,
        color: colorFromHex(json['color']?.toString() ?? '#4CAF50'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': colorToHex(color),
      };
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

  factory StoreZone.fromJson(Map<String, dynamic> json) => StoreZone(
        id: json['id'].toString(),
        floorId: json['floorId'].toString(),
        name: (json['name'] as String?) ?? '',
        categoryId: json['categoryId'].toString(),
        x: numFromJson(json['x']),
        y: numFromJson(json['y']),
        w: numFromJson(json['w']),
        h: numFromJson(json['h']),
        shape: zoneShapeFromJson(json['shape']?.toString()),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'floorId': floorId,
        'name': name,
        'categoryId': categoryId,
        'x': x,
        'y': y,
        'w': w,
        'h': h,
        'shape': shape.name,
      };

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

Color colorFromHex(String value) {
  var hex = value.replaceFirst('#', '').trim();
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}

String colorToHex(Color color) {
  final value = color.toARGB32() & 0xFFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0')}';
}

ZoneShape zoneShapeFromJson(String? value) {
  return value == ZoneShape.circle.name ? ZoneShape.circle : ZoneShape.rect;
}

double numFromJson(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
