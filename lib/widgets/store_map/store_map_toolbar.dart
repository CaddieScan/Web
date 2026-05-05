import 'package:flutter/material.dart';
import '../../controllers/store_map/store_map_controller.dart';
import '../../controllers/store_map/store_map_state.dart';
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
  void toggle(EditorTool t) {
    ctrl.setTool(t);
    onChanged();
  }
  @override
  Widget build(BuildContext context) {
    final selected = [
      ctrl.tool == EditorTool.select,
      ctrl.tool == EditorTool.drawRect,
      ctrl.tool == EditorTool.drawCircle,
      ctrl.tool == EditorTool.placeEntry,
      ctrl.tool == EditorTool.placeExit,
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
                  toggle(EditorTool.select);
                  break;
                case 1:
                  toggle(EditorTool.drawRect);
                  break;
                case 2:
                  toggle(EditorTool.drawCircle);
                  break;
                case 3:
                  toggle(EditorTool.placeEntry);
                  break;
                case 4:
                  toggle(EditorTool.placeExit);
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
                child: Row(children: [Icon(Icons.login), SizedBox(width: 6), Text('Entree')]),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [Icon(Icons.logout), SizedBox(width: 6), Text('Sortie')]),
              ),
            ],
          ),
          const Spacer(),
          Text('Magasin: '),
          const SizedBox(width: 12),
          SaveButton(onSave: onSave),
        ],
      ),
    );
  }
}
class SaveButton extends StatefulWidget {
  final Future<void> Function()? onSave;
  const SaveButton({super.key, this.onSave});
  @override
  State<SaveButton> createState() => SaveButtonState();
}
class SaveButtonState extends State<SaveButton> {
  bool saving = false;
  Future<void> save() async {
    final onSave = widget.onSave;
    if (onSave == null || saving) return;
    setState(() => saving = true);
    try {
      await onSave();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carte sauvegardee')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur sauvegarde: ')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sauvegarder',
      onPressed: widget.onSave == null || saving ? null : save,
      icon: saving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save),
    );
  }
}
