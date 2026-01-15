import 'package:flutter/material.dart';

import '../../controllers/store_map/store_map_controller.dart';
import '../../dialogs/text_prompt_dialog.dart';

class StoreMapLeftPanel extends StatelessWidget {
  final StoreMapController ctrl;
  final VoidCallback onChanged;

  const StoreMapLeftPanel({
    super.key,
    required this.ctrl,
    required this.onChanged,
  });

  Future<void> _addFloor(BuildContext context) async {
    // crée un étage avec un nom par défaut via ctrl.addFloor()
    ctrl.addFloor();
    onChanged();
  }

  Future<void> _renameFloor(BuildContext context, String floorId, String current) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => TextPromptDialog(
        title: 'Renommer etage',
        hint: current,
      ),
    );
    if (name == null || name.trim().isEmpty) return;

    // tu as sûrement floor.name modifiable
    final f = ctrl.floors.firstWhere((e) => e.id == floorId);
    f.name = name.trim();
    onChanged();
  }

  Future<void> _addCategory(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const TextPromptDialog(
        title: 'Nouvelle categorie',
        hint: 'Ex: Produits laitiers',
      ),
    );
    if (name == null || name.trim().isEmpty) return;

    ctrl.addCategory(name.trim());
    onChanged();
  }

  Future<void> _renameCategory(BuildContext context, String catId, String current) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => TextPromptDialog(
        title: 'Renommer categorie',
        hint: current,
      ),
    );
    if (name == null || name.trim().isEmpty) return;

    ctrl.renameCategory(catId, name.trim());
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text('Etages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _addFloor(context),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter etage'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ...ctrl.floors.map((f) {
            final isActive = ctrl.activeFloorId == f.id;
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                onTap: () {
                  ctrl.setActiveFloor(f.id);
                  onChanged();
                },
                leading: Icon(isActive ? Icons.layers : Icons.layers_outlined),
                title: Text(f.name),
                subtitle: isActive ? const Text('Actif') : null,
                trailing: PopupMenuButton<String>(
                  onSelected: (action) async {
                    if (action == 'rename') {
                      await _renameFloor(context, f.id, f.name);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('Renommer')),
                  ],
                ),
              ),
            );
          }),

          const Divider(height: 24),

          const Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _addCategory(context),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ...ctrl.categories.map((c) {
            final isActive = ctrl.activeCategoryId == c.id;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                onTap: () {
                  ctrl.setActiveCategory(c.id);
                  onChanged();
                },
                leading: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: c.color,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(c.name),
                subtitle: isActive ? const Text('Selectionnee') : null,
                trailing: PopupMenuButton<String>(
                  onSelected: (action) async {
                    if (action == 'rename') {
                      await _renameCategory(context, c.id, c.name);
                    } else if (action == 'delete') {
                      final ok = ctrl.deleteCategory(c.id);
                      if (!ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Impossible de supprimer la derniere categorie.')),
                        );
                      }
                      onChanged();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('Renommer')),
                    PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
