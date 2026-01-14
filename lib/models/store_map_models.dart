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

  // 0 = rectangle, > 0 = coins arrondis
  double cornerRadius;

  StoreCategory({
    required this.id,
    required this.name,
    required this.color,
    this.cornerRadius = 0,
  });
}


class StoreZone {
  final String id;
  final String floorId;

  String name; // ex: "Rayon frais"
  String categoryId;

  // Rectangle en coords du plan
  double x;
  double y;
  double w;
  double h;

  StoreZone({
    required this.id,
    required this.floorId,
    required this.name,
    required this.categoryId,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  bool contains(double px, double py) {
    return px >= x && px <= x + w && py >= y && py <= y + h;
  }
}
