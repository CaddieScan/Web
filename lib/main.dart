import 'package:flutter/material.dart';

import 'pages/login_page.dart';
import 'repositories/api_product_repository.dart';
import 'repositories/api_store_map_repository.dart';
import 'repositories/api_store_repository.dart';
import 'services/store_service.dart';
import 'services/store_map_service.dart';
import 'services/product_service.dart';

void main() {
  const baseUrl = 'http://localhost:8000/api';

  final storeRepo = ApiStoreRepository(baseUrl: baseUrl);
  final storeService = StoreService(storeRepo);

  final productRepo = ApiProductRepository(baseUrl: baseUrl);
  final productService = ProductService(productRepo);

  final storeMapRepo = ApiStoreMapRepository(baseUrl: baseUrl);
  final storeMapService = StoreMapService(storeMapRepo);

  runApp(
    MyApp(
      storeService: storeService,
      productService: productService,
      storeMapService: storeMapService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final StoreService storeService;
  final ProductService productService;
  final StoreMapService storeMapService;

  const MyApp({
    super.key,
    required this.storeService,
    required this.productService,
    required this.storeMapService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CaddieScan',
      home: LoginPage(
        storeService: storeService,
        productService: productService,
        storeMapService: storeMapService,
      ),
    );
  }
}
