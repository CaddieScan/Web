import 'package:flutter/material.dart';

import '../models/store.dart';
import '../services/product_service.dart';
import '../services/store_map_service.dart';
import '../controllers/store_map/store_map_controller.dart';
import 'products_page.dart';
import 'store_map_editor_page.dart';

class StorePage extends StatefulWidget {
  final Store store;
  final ProductService productService;
  final StoreMapService storeMapService;

  const StorePage({
    super.key,
    required this.store,
    required this.productService,
    required this.storeMapService,
  });

  @override
  State<StorePage> createState() => StorePageState();
}

class StorePageState extends State<StorePage>
    with SingleTickerProviderStateMixin {
  late final TabController tabController = TabController(length: 2, vsync: this);
  final mapCtrl = StoreMapController();
  late final Future<void> mapFuture;

  @override
  void initState() {
    super.initState();
    mapFuture = widget.storeMapService
        .fetchMap(widget.store.id)
        .then(mapCtrl.loadData);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> saveMap() =>
      widget.storeMapService.saveMap(widget.store.id, mapCtrl.exportData());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.store.name),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'Produits'),
            Tab(icon: Icon(Icons.map), text: 'Carte magasin'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          ProductsPage(
            store: widget.store,
            productService: widget.productService,
          ),
          FutureBuilder(
            future: mapFuture,
            builder: (context, snapshot) => switch (snapshot.connectionState) {
              ConnectionState.done when snapshot.hasError =>
                  Center(child: Text('Erreur carte : ${snapshot.error}')),
              ConnectionState.done => StoreMapEditorPage(
                ctrl: mapCtrl,
                storeName: widget.store.name,
                onSave: saveMap,
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}