import 'package:flutter/material.dart';
import '../models/store.dart';
import '../services/store_service.dart';
import 'add_store_map_page.dart';
import 'store_page.dart';

class StoresPage extends StatefulWidget {
  final StoreService storeService;
  const StoresPage({super.key, required this.storeService});

  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  bool _loading = true;
  List<Store> _stores = [];
  String? _error;

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
    // on attend le retour (true/false) puis on refresh la liste
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

  @override
  Widget build(BuildContext context) {
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
          : ListView.separated(
        itemCount: _stores.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final s = _stores[i];
          return ListTile(
            leading: const Icon(Icons.store),
            title: Text(s.name),
            subtitle: Text('${s.latitude}, ${s.longitude}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StorePage(store: s)),
              );
            },
          );
        },
      ),
    );
  }
}
