import 'package:flutter/material.dart';

import 'pages/login_page.dart';
import 'repositories/mock_store_repository.dart';
import 'repositories/mock_product_repository.dart';
import 'services/store_service.dart';
import 'services/product_service.dart';

void main() {
  final storeRepo = MockStoreRepository();
  final storeService = StoreService(storeRepo);

  final productRepo = MockProductRepository();
  final productService = ProductService(productRepo);

  runApp(MyApp(storeService: storeService, productService: productService));
}

class MyApp extends StatelessWidget {
  final StoreService storeService;
  final ProductService productService;

  const MyApp({
    super.key,
    required this.storeService,
    required this.productService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CaddieScan',
      home: LoginPage(storeService: storeService, productService: productService),
    );
  }
}
