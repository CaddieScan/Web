import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/store.dart';
import '../services/store_service.dart';

class AddStoreMapPage extends StatefulWidget {
  final StoreService storeService;
  const AddStoreMapPage({super.key, required this.storeService});

  @override
  State<AddStoreMapPage> createState() => _AddStoreMapPageState();
}

class _AddStoreMapPageState extends State<AddStoreMapPage> {
  final MapController _mapController = MapController();

  // centre par défaut (Paris)
  LatLng _center = const LatLng(48.8566, 2.3522);

  Future<void> _openCreateForm({LatLng? latLng}) async {
    final created = await showDialog<Store>(
      context: context,
      builder: (_) => _CreateStoreDialog(
        initialLat: latLng?.latitude,
        initialLng: latLng?.longitude,
      ),
    );

    if (created == null) return;

    try {
      await widget.storeService.addStore(created);
      if (!mounted) return;
      Navigator.pop(context, true); // ✅ dit à StoresPage : refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur création: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un magasin (Map)'),
        actions: [
          IconButton(
            tooltip: 'Saisie manuelle',
            onPressed: () => _openCreateForm(latLng: null),
            icon: const Icon(Icons.edit_location_alt),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: _center,
          zoom: 13,
          onTap: (tapPosition, latLng) {
            // ✅ clic sur la map => ouvre formulaire pré-rempli
            _openCreateForm(latLng: latLng);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.caddiescan.web',
          ),
        ],
      ),
    );
  }
}

class _CreateStoreDialog extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const _CreateStoreDialog({
    this.initialLat,
    this.initialLng,
  });

  @override
  State<_CreateStoreDialog> createState() => _CreateStoreDialogState();
}

class _CreateStoreDialogState extends State<_CreateStoreDialog> {
  final _nameCtrl = TextEditingController();
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;

  String? _error;

  @override
  void initState() {
    super.initState();
    _latCtrl = TextEditingController(
      text: widget.initialLat?.toStringAsFixed(6) ?? '',
    );
    _lngCtrl = TextEditingController(
      text: widget.initialLng?.toStringAsFixed(6) ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final lat = double.tryParse(_latCtrl.text.replaceAll(',', '.'));
    final lng = double.tryParse(_lngCtrl.text.replaceAll(',', '.'));

    if (name.isEmpty) {
      setState(() => _error = 'Le nom est obligatoire');
      return;
    }
    if (lat == null || lng == null) {
      setState(() => _error = 'Latitude/Longitude invalides');
      return;
    }

    // id vide => sera généré par Mock / API
    Navigator.pop(context, Store(id: '', name: name, latitude: lat, longitude: lng));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer un magasin'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latCtrl,
                    decoration: const InputDecoration(labelText: 'Latitude'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lngCtrl,
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ],
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Astuce: tu peux cliquer sur la map pour pré-remplir lat/lng.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(onPressed: _submit, child: const Text('Créer')),
      ],
    );
  }
}
