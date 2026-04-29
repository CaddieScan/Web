import 'package:flutter/material.dart';

import '../../controllers/store_map/store_map_controller.dart';
import '../../controllers/store_map/store_map_state.dart';

// ce widget affiche la barre d'outils pour choisir entre les différents outils d'édition du plan du magasin

class StoreMapToolbar extends StatelessWidget {
  final StoreMapController ctrl;
  final String storeName;
  final VoidCallback onChanged;
  final Future<void> Function()? onSave;

  const StoreMapToolbar({
    super.key,
    required this.ctrl,
    required this.storeName,
    required this.onChanged,
    this.onSave,
  });

  void _toggle(EditorTool t) {
    ctrl.setTool(t);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final selected = [
      ctrl.tool == EditorTool.select,
      ctrl.tool == EditorTool.drawRect,
      ctrl.tool == EditorTool.drawCircle,
      ctrl.tool == EditorTool.drawWall,

      ctrl.tool == EditorTool.drawAisle,

      ctrl.tool == EditorTool.placeEntry,
      ctrl.tool == EditorTool.placeExit,
      ctrl.tool == EditorTool.placeCheckout,
    ];

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          ToggleButtons(
            isSelected: selected,
            onPressed: (idx) {
              switch (idx) {
                case 0:
                  _toggle(EditorTool.select);
                  break;
                case 1:
                  _toggle(EditorTool.drawRect);
                  break;
                case 2:
                  _toggle(EditorTool.drawCircle);
                  break;
                case 3:
                  _toggle(EditorTool.drawWall);
                  break;
                case 4:
                  _toggle(EditorTool.drawAisle);
                  break;
                case 5:
                  _toggle(EditorTool.placeEntry);
                  break;
                case 6:
                  _toggle(EditorTool.placeExit);
                  break;
                case 7:
                  _toggle(EditorTool.placeCheckout);
                  break;
              }
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [Icon(Icons.mouse), SizedBox(width: 6), Text('Select')]),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [Icon(Icons.crop_square), SizedBox(width: 6), Text('Rect')]),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [Icon(Icons.circle_outlined), SizedBox(width: 6), Text('Rond')]),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [Icon(Icons.horizontal_rule), SizedBox(width: 6), Text('Mur')]),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [Icon(Icons.alt_route), SizedBox(width: 6), Text('Allee')]),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [Icon(Icons.login), SizedBox(width: 6), Text('Entree')]),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [Icon(Icons.logout), SizedBox(width: 6), Text('Sortie')]),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [Icon(Icons.point_of_sale), SizedBox(width: 6), Text('Caisse')]),
              ),
            ],
          ),
          const Spacer(),
          Text('Magasin: $storeName'),
          const SizedBox(width: 12),
          _SaveButton(onSave: onSave),
        ],
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  final Future<void> Function()? onSave;

  const _SaveButton({required this.onSave});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _saving = false;

  Future<void> _save() async {
    final onSave = widget.onSave;
    if (onSave == null || _saving) return;

    setState(() => _saving = true);
    try {
      await onSave();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carte sauvegardee')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur sauvegarde: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sauvegarder',
      onPressed: widget.onSave == null || _saving ? null : _save,
      icon: _saving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save),
    );
  }
}
