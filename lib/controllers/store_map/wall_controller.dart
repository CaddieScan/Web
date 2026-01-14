import 'dart:ui';

import 'store_map_data.dart';
import 'store_map_state.dart';

class WallController {
  final StoreMapState state;
  final StoreMapData data;

  bool isDrawing = false;
  final List<Offset> current = [];
  Offset? previewEnd;

  WallController(this.state, this.data);

  List<List<Offset>> get walls => data.wallsByFloor[state.activeFloorId] ?? const [];

  void startPoint(Offset world) {
    final f = state.activeFloorId;
    if (f == null) return;

    isDrawing = true;
    final p = state.snapOffset(world);
    current.add(p);
  }

  void updatePreview(Offset world) {
    if (!isDrawing) return;
    previewEnd = state.snapOffset(world);
  }

  void finish() {
    final f = state.activeFloorId;
    if (f == null) return;

    if (current.length >= 2) {
      data.wallsByFloor[f]!.add(List.of(current));
    }
    cancel();
  }

  void cancel() {
    isDrawing = false;
    current.clear();
    previewEnd = null;
  }
}
