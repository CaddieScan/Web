import 'package:flutter/material.dart';
import '../services/store_service.dart';
import '../services/product_service.dart';
import '../services/store_map_service.dart';
import 'stores_page.dart';

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
      appBar: AppBar(title: const Text('Accueil')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('Mes magasins'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoresPage(
                  storeService: storeService,
                  productService: productService,
                  storeMapService: storeMapService,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}