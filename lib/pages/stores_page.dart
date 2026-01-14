import 'package:flutter/material.dart';

import '../models/store.dart';
import '../services/store_service.dart';
import '../services/product_service.dart';
import 'add_store_map_page.dart';
import 'store_page.dart';

class StoresPage extends StatefulWidget {
  final StoreService storeService;
  final ProductService productService;

  const StoresPage({
    super.key,
    required this.storeService,
    required this.productService,
  });

  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  bool _loading = true;
  List<Store> _stores = [];
  String? _error;

  // ✅ recherche
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.storeService.fetchStores();
      setState(() {
        _stores = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _goAddStore() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddStoreMapPage(storeService: widget.storeService),
      ),
    );
    if (created == true) {
      await _load();
    }
  }

  // ✅ liste filtrée
  List<Store> get _filteredStores {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _stores;

    return _stores.where((s) {
      final name = s.name.toLowerCase();
      final lat = s.latitude.toString();
      final lng = s.longitude.toString();

      return name.contains(q) || lat.contains(q) || lng.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final stores = _filteredStores;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Magasins'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _goAddStore,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un magasin'),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Erreur: $_error'))
          : Column(
        children: [
          // ✅ barre de recherche
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Rechercher un magasin...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          const Divider(height: 1),

          // ✅ liste
          Expanded(
            child: stores.isEmpty
                ? const Center(child: Text('Aucun magasin trouvé'))
                : ListView.separated(
              itemCount: stores.length,
              separatorBuilder: (_, __) =>
              const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = stores[i];
                return ListTile(
                  leading: const Icon(Icons.store),
                  title: Text(s.name),
                  subtitle:
                  Text('${s.latitude}, ${s.longitude}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StorePage(
                          store: s,
                          productService: widget.productService,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
