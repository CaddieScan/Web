import 'dart:ui';

import 'store_map_data.dart';
import 'store_map_state.dart';

class AisleEdge {
  final int a;
  final int b;
  AisleEdge(this.a, this.b);
}

class AisleController {
  final StoreMapState state;
  final StoreMapData data;

  bool isDrawing = false;
  int? lastNodeIndex;
  Offset? previewEnd;

  AisleController(this.state, this.data);

  List<Offset> get nodes => data.aisleNodesByFloor[state.activeFloorId] ?? const [];
  List<AisleEdge> get edges => data.aisleEdgesByFloor[state.activeFloorId] ?? const [];

  int _getOrCreateNode(String floorId, Offset p) {
    final list = data.aisleNodesByFloor[floorId]!;
    const eps = 0.001;
    for (int i = 0; i < list.length; i++) {
      if ((list[i].dx - p.dx).abs() < eps && (list[i].dy - p.dy).abs() < eps) {
        return i;
      }
    }
    list.add(p);
    return list.length - 1;
  }

  void startPoint(Offset world) {
    final f = state.activeFloorId;
    if (f == null) return;

    isDrawing = true;

    final p = state.snapOffset(world);
    final idx = _getOrCreateNode(f, p);

    if (lastNodeIndex != null && lastNodeIndex != idx) {
      data.aisleEdgesByFloor[f]!.add(AisleEdge(lastNodeIndex!, idx));
    }

    lastNodeIndex = idx;
  }

  void updatePreview(Offset world) {
    if (!isDrawing) return;
    previewEnd = state.snapOffset(world);
  }

  void finish() {
    isDrawing = false;
    lastNodeIndex = null;
    previewEnd = null;
  }

  void cancel() => finish();
}
