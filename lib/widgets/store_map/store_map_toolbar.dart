import 'package:flutter/material.dart';

import '../../controllers/store_map/store_map_controller.dart';
import '../../controllers/store_map/store_map_state.dart';

class StoreMapToolbar extends StatelessWidget {
  final StoreMapController ctrl;
  final String storeName;
  final VoidCallback onChanged;

  const StoreMapToolbar({
    super.key,
    required this.ctrl,
    required this.storeName,
    required this.onChanged,
  });

  void _toggle(EditorTool t) {
    ctrl.setTool(t);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
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
            isSelected: [
              ctrl.tool == EditorTool.select,
              ctrl.tool == EditorTool.drawRect,
              ctrl.tool == EditorTool.drawWall,
              ctrl.tool == EditorTool.drawAisle,
              ctrl.tool == EditorTool.placeEntry,
              ctrl.tool == EditorTool.placeExit,
              ctrl.tool == EditorTool.placeCheckout,
            ],
            onPressed: (idx) {
              if (idx == 0) _toggle(EditorTool.select);
              if (idx == 1) _toggle(EditorTool.drawRect);
              if (idx == 2) _toggle(EditorTool.drawWall);
              if (idx == 3) _toggle(EditorTool.drawAisle);
              if (idx == 4) _toggle(EditorTool.placeEntry);
              if (idx == 5) _toggle(EditorTool.placeExit);
              if (idx == 6) _toggle(EditorTool.placeCheckout);
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [Icon(Icons.mouse), SizedBox(width: 6), Text('Select')]),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [Icon(Icons.crop_square), SizedBox(width: 6), Text('Zone')]),
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
        ],
      ),
    );
  }
}
