import 'package:flutter/material.dart';

import '../../controllers/store_map/store_map_controller.dart';
import '../../dialogs/text_prompt_dialog.dart';
import '../../models/store_map_models.dart';

class StoreMapLeftPanel extends StatelessWidget {
  final StoreMapController ctrl;
  final VoidCallback onChanged;

  const StoreMapLeftPanel({
    super.key,
    required this.ctrl,
    required this.onChanged,
  });

  Future<void> _addCategory(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const TextPromptDialog(
        title: 'Nouvelle categorie',
        hint: 'Nom',
      ),
    );

    if (name == null || name.trim().isEmpty) return;
    ctrl.addCategory(name.trim());
    onChanged();
  }

  Future<void> _renameCategory(BuildContext context, StoreCategory cat) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => TextPromptDialog(
        title: 'Renommer categorie',
        hint: 'Nom',
        initial: cat.name,
      ),
    );

    if (name == null || name.trim().isEmpty) return;
    ctrl.renameCategory(cat.id, name.trim());
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final activeFloorId = ctrl.activeFloorId;
    final activeCatId = ctrl.activeCategoryId;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Editeur de plan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Floors
            Row(
              children: [
                const Expanded(
                  child: Text('Etage', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  tooltip: 'Ajouter etage',
                  onPressed: () {
                    ctrl.addFloor();
                    onChanged();
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            DropdownButton<String>(
              isExpanded: true,
              value: activeFloorId,
              items: ctrl.floors
                  .map((f) => DropdownMenuItem(value: f.id, child: Text(f.name)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                ctrl.setActiveFloor(v);
                onChanged();
              },
            ),

            const SizedBox(height: 12),
            const Divider(),

            // Categories
            Row(
              children: [
                const Expanded(
                  child: Text('Categories', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  tooltip: 'Ajouter categorie',
                  onPressed: () => _addCategory(context),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            Expanded(
              child: ListView.separated(
                itemCount: ctrl.categories.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final c = ctrl.categories[i];
                  final isActive = c.id == activeCatId;

                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: c.color,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.black12),
                      ),
                    ),
                    title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    selected: isActive,
                    onTap: () {
                      ctrl.setActiveCategory(c.id);
                      onChanged();
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) async {
                        if (action == 'rename') {
                          await _renameCategory(context, c);
                        } else if (action == 'radius') {
                          final newRadius = await showDialog<double>(
                            context: context,
                            builder: (_) => _CornerRadiusDialog(initial: c.cornerRadius),
                          );
                          if (newRadius != null) {
                            ctrl.setCategoryCornerRadius(c.id, newRadius);
                            onChanged();
                          }
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
                        PopupMenuItem(value: 'radius', child: Text('Coins arrondis...')),
                        PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                      ],
                    ),

                  );
                },
              ),
            ),

            const Divider(),
            Row(
              children: [
                Switch(
                  value: ctrl.snapToGrid,
                  onChanged: (v) {
                    ctrl.snapToGrid = v;
                    onChanged();
                  },
                ),
                const Text('Snap grille'),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Clic molette = deplacer la vue / molette = zoom',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );

  }
}

class _CornerRadiusDialog extends StatefulWidget {
  final double initial;
  const _CornerRadiusDialog({required this.initial});

  @override
  State<_CornerRadiusDialog> createState() => _CornerRadiusDialogState();
}

class _CornerRadiusDialogState extends State<_CornerRadiusDialog> {
  late double value;

  @override
  void initState() {
    super.initState();
    value = widget.initial.clamp(0, 40);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Coins arrondis'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rayon: ${value.toStringAsFixed(0)}'),
            Slider(
              value: value,
              min: 0,
              max: 40,
              divisions: 40,
              onChanged: (v) => setState(() => value = v),
            ),
            const Text(
              '0 = rectangle, > 0 = arrondi',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(onPressed: () => Navigator.pop(context, value), child: const Text('OK')),
      ],
    );
  }
}
