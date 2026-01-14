import 'package:flutter/material.dart';

import '../models/store.dart';
import '../controllers/store_map/store_map_controller.dart';
import '../widgets/store_map/store_map_left_panel.dart';
import '../widgets/store_map/store_map_toolbar.dart';
import '../widgets/store_map/store_map_canvas.dart';

class StoreMapEditorPage extends StatefulWidget {
  final Store store;

  const StoreMapEditorPage({super.key, required this.store});

  @override
  State<StoreMapEditorPage> createState() => _StoreMapEditorPageState();
}

class _StoreMapEditorPageState extends State<StoreMapEditorPage> {
  final StoreMapController ctrl = StoreMapController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StoreMapLeftPanel(
          ctrl: ctrl,
          onChanged: () => setState(() {}),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFF6F7F9),
            child: Column(
              children: [
                StoreMapToolbar(
                  ctrl: ctrl,
                  storeName: widget.store.name,
                  onChanged: () => setState(() {}),
                ),
                Expanded(
                  child: StoreMapCanvas(
                    ctrl: ctrl,
                    onChanged: () => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
