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
}

enum PoiType { entry, exit, checkout }

enum CheckoutKind { selfCheckout, cashier }

enum PaymentMode { cardOnly, cardAndCash }
