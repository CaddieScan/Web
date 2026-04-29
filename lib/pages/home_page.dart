import 'package:flutter/material.dart';

import '../services/store_service.dart';
import '../services/product_service.dart';
import '../services/store_map_service.dart';
import 'stores_page.dart';

// page d'accueil pour choisir entre les différentes fonctionnalités

class HomePage extends StatelessWidget {
  final StoreService storeService;
  final ProductService productService;
  final StoreMapService storeMapService;

  const HomePage({
    super.key,
    required this.storeService,
    required this.productService,
    required this.storeMapService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: SizedBox(
          width: 240,
          height: 52,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.store),
            label: const Text('Magasin'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoresPage(
                    storeService: storeService,
                    productService: productService,
                    storeMapService: storeMapService,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
