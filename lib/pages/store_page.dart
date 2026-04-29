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
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  int _index = 0;

  late final StoreMapController _mapCtrl;
  bool _mapLoading = true;
  String? _mapError;

  @override
  void initState() {
    super.initState();
    _mapCtrl = StoreMapController();
    _loadMap();
  }

  Future<void> _loadMap() async {
    try {
      final data = await widget.storeMapService.fetchMap(widget.store.id);
      if (!mounted) return;
      setState(() {
        _mapCtrl.loadData(data);
        _mapLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mapError = '$e';
        _mapLoading = false;
      });
    }
  }

  Future<void> _saveMap() async {
    await widget.storeMapService.saveMap(widget.store.id, _mapCtrl.exportData());
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ProductsPage(store: widget.store, productService: widget.productService),
      _mapLoading
          ? const Center(child: CircularProgressIndicator())
          : _mapError != null
              ? Center(child: Text('Erreur carte: $_mapError'))
              : StoreMapEditorPage(
                  ctrl: _mapCtrl,
                  storeName: widget.store.name,
                  onSave: _saveMap,
                ),
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
