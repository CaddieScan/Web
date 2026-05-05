import 'package:flutter/material.dart';
import '../models/store.dart';
import '../services/store_service.dart';
import '../services/product_service.dart';
import '../services/store_map_service.dart';
import 'add_store_map_page.dart';
import 'store_page.dart';

// page où on peut voir tous les magasins
// on peut rechercher, créer, et cliquer pour gérer un magasin
// tu tapes un nom ou une localisation, ça filtre la liste en direct
class StoresPage extends StatefulWidget {
  final StoreService storeService;
  final ProductService productService;
  final StoreMapService storeMapService;

  const StoresPage({
    super.key,
    required this.storeService,
    required this.productService,
    required this.storeMapService,
  });

  @override
  State<StoresPage> createState() => StoresPageState();
}

class StoresPageState extends State<StoresPage> {
  bool loading = true;
  List<Store> stores = [];
  String error = '';
  String search = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  // charge la liste des magasins depuis l'API au démarrage
  Future<void> load() async {
    try {
      final data = await widget.storeService.fetchStores();
      setState(() { stores = data; loading = false; });
    } catch (e) {
      setState(() { error = '$e'; loading = false; });
    }
  }

  List<Store> get filtered {
    final q = search.trim().toLowerCase();
    if (q.isEmpty) return stores;
    return stores.where((s) =>
    s.name.toLowerCase().contains(q) ||
        s.latitude.toString().contains(q) ||
        s.longitude.toString().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Magasins'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => AddStoreMapPage(storeService: widget.storeService)),
              );
              if (created == true) load();
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(child: Text('Erreur : $error'))
          : Column(
        children: [
          // juste une barre de recherche pour filtrer les magasins par nom ou localisation
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher un magasin...',
              ),
              onChanged: (v) => setState(() => search = v),
            ),
          ),
          // la liste avec les magasins qu'on peut cliquer pour entrer dedans
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Aucun magasin trouvé'))
                : ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              // un seul magasin dans la liste avec son nom et pos
              itemBuilder: (_, i) => ListTile(
                leading: const Icon(Icons.store),
                title: Text(filtered[i].name),
                subtitle: Text('${filtered[i].latitude}, ${filtered[i].longitude}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StorePage(
                      store: filtered[i],
                      productService: widget.productService,
                      storeMapService: widget.storeMapService,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}