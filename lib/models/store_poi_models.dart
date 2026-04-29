class StorePoi {
  final String id;
  final String floorId;
  final PoiType type;

  double x;
  double y;

  String label;

  CheckoutKind checkoutKind;
  PaymentMode paymentMode;
  bool isAccessible;

  StorePoi({
    required this.id,
    required this.floorId,
    required this.type,
    required this.x,
    required this.y,
    this.label = '',
    this.checkoutKind = CheckoutKind.selfCheckout,
    this.paymentMode = PaymentMode.cardOnly,
    this.isAccessible = false,
  });

  factory StorePoi.fromJson(Map<String, dynamic> json) => StorePoi(
        id: json['id'].toString(),
        floorId: json['floorId'].toString(),
        type: _poiTypeFromJson(json['type']?.toString()),
        x: _numFromJson(json['x']),
        y: _numFromJson(json['y']),
        label: (json['label'] as String?) ?? '',
        checkoutKind: _checkoutKindFromJson(json['checkoutKind']?.toString()),
        paymentMode: _paymentModeFromJson(json['paymentMode']?.toString()),
        isAccessible: (json['isAccessible'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'floorId': floorId,
        'type': type.name,
        'x': x,
        'y': y,
        'label': label,
        'checkoutKind': checkoutKind.name,
        'paymentMode': paymentMode.name,
        'isAccessible': isAccessible,
      };
}

enum PoiType { entry, exit, checkout }

enum CheckoutKind { selfCheckout, cashier }

enum PaymentMode { cardOnly, cardAndCash }

PoiType _poiTypeFromJson(String? value) {
  return PoiType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => PoiType.entry,
  );
}

CheckoutKind _checkoutKindFromJson(String? value) {
  return CheckoutKind.values.firstWhere(
    (kind) => kind.name == value,
    orElse: () => CheckoutKind.selfCheckout,
  );
}

PaymentMode _paymentModeFromJson(String? value) {
  return PaymentMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => PaymentMode.cardOnly,
  );
}

double _numFromJson(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
