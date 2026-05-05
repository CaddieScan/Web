import 'package:flutter/material.dart';

import 'pages/login_page.dart';
import 'services/store_service.dart';
import 'services/store_map_service.dart';
import 'services/product_service.dart';

// point d'entrée principal de l'app
// on initialise les services avec l'URL de base de l'API
void main() {
  const baseUrl = 'http://localhost:8000/api';

  // les services sont créés directement sans passer par les repositories
  final storeService = StoreService(baseUrl: baseUrl);
  final productService = ProductService(baseUrl: baseUrl);
  final storeMapService = StoreMapService(baseUrl: baseUrl);

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
