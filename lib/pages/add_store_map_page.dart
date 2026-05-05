import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/store.dart';
import '../services/store_service.dart';

// page pour créer un magasin en cliquant sur une carte
// soit tu cliques directement sur la carte à la position souhaitée
// soit tu appuies sur le bouton pour saisir manuellement les coordonnées
class AddStoreMapPage extends StatefulWidget {
  final StoreService storeService;

  const AddStoreMapPage({
    super.key,
    required this.storeService,
  });

  @override
  State<AddStoreMapPage> createState() => AddStoreMapPageState();
}

class AddStoreMapPageState extends State<AddStoreMapPage> {
  LatLng center = const LatLng(48.8566, 2.3522);

  // ouvre un dialog pour créer le magasin avec les coordonnées optionnelles
  // si tu cliques sur la carte, il pré-remplit avec tes coordonnées
  Future<void> openCreateForm({LatLng? latLng}) async {
    final created = await showDialog<Store>(
      context: context,
      builder: (dialogContext) => CreateStoreDialog(
        initialLat: latLng?.latitude,
        initialLng: latLng?.longitude,
      ),
    );

    if (created == null) return;

    try {
      await widget.storeService.addStore(created);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
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
            onPressed: () => openCreateForm(latLng: null),
            icon: const Icon(Icons.edit_location_alt),
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 13,
          onTap: (tapPosition, latLng) => openCreateForm(latLng: latLng),
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

class CreateStoreDialog extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const CreateStoreDialog({this.initialLat, this.initialLng});

  // dialog avec un formulaire pour remplir le nom du magasin et ses coordonnées GPS
  // si tu cliquais sur la carte, il pré-remplit lat/lng
  @override
  State<CreateStoreDialog> createState() => CreateStoreDialogState();
}

class CreateStoreDialogState extends State<CreateStoreDialog> {
  TextEditingController nameCtrl = TextEditingController();
  late TextEditingController latCtrl;
  late TextEditingController lngCtrl;
  String error = '';

  @override
  void initState() {
    super.initState();
    latCtrl = TextEditingController(text: widget.initialLat?.toStringAsFixed(6) ?? '');
    lngCtrl = TextEditingController(text: widget.initialLng?.toStringAsFixed(6) ?? '');
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
    super.dispose();
  }

  void submit() {
    // valide et envoie le formulaire de création du magasin à l'API
    final name = nameCtrl.text.trim();
    final lat = double.tryParse(latCtrl.text.replaceAll(',', '.'));
    final lng = double.tryParse(lngCtrl.text.replaceAll(',', '.'));

    if (name.isEmpty) {
      setState(() => error = 'Le nom est obligatoire');
      return;
    }
    if (lat == null || lng == null) {
      setState(() => error = 'Latitude/Longitude invalides');
      return;
    }

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
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: latCtrl,
                    decoration: const InputDecoration(labelText: 'Latitude'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: lngCtrl,
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(error, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(onPressed: submit, child: const Text('Créer')),
      ],
    );
  }
}
