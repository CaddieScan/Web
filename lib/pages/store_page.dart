import 'package:flutter/material.dart';

import '../models/store.dart';
import '../services/product_service.dart';
import 'products_page.dart';
import 'store_map_editor_page.dart';

class StorePage extends StatefulWidget {
  final Store store;
  final ProductService productService;

  const StorePage({
    super.key,
    required this.store,
    required this.productService,
  });

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ProductsPage(store: widget.store, productService: widget.productService),
      StoreMapEditorPage(store: widget.store),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(widget.store.name)),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Produits'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Carte magasin'),
        ],
      ),
    );
  }
}
