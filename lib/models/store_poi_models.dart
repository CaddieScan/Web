class StorePoi {
  final String id;
  final String floorId;
  final PoiType type;

  double x;
  double y;

  String label;

  StorePoi({
    required this.id,
    required this.floorId,
    required this.type,
    required this.x,
    required this.y,
    this.label = '',
  });

  factory StorePoi.fromJson(Map<String, dynamic> json) => StorePoi(
        id: json['id'].toString(),
        floorId: json['floorId'].toString(),
        type: poiTypeFromJson(json['type']?.toString()),
        x: numFromJson(json['x']),
        y: numFromJson(json['y']),
        label: (json['label'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'floorId': floorId,
        'type': type.name,
        'x': x,
        'y': y,
        'label': label,
      };
}

enum PoiType { entry, exit }

PoiType poiTypeFromJson(String? value) {
  return PoiType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => PoiType.entry,
  );
}

double numFromJson(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
