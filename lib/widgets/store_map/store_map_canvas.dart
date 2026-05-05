import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../controllers/store_map/store_map_controller.dart';
import '../../controllers/store_map/store_map_state.dart';
import '../../models/store_map_models.dart';
import '../../models/store_poi_models.dart';
import '../../painters/store_map_painter.dart';
class StoreMapCanvas extends StatefulWidget {
  final StoreMapController ctrl;
  final VoidCallback onChanged;
  const StoreMapCanvas({
    super.key,
    required this.ctrl,
    required this.onChanged,
  });
  @override
  State<StoreMapCanvas> createState() => StoreMapCanvasState();
}
class StoreMapCanvasState extends State<StoreMapCanvas> {
  StoreMapController get ctrl => widget.ctrl;
  double scale = 1.0;
  Offset pan = Offset.zero;
  bool isPanning = false;
  Offset screenToWorld(Offset screen) {
    return Offset(
      (screen.dx - pan.dx) / scale,
      (screen.dy - pan.dy) / scale,
    );
  }
  void onPointerSignal(PointerSignalEvent e) {
    if (e is PointerScrollEvent) {
      final zoomDelta = e.scrollDelta.dy > 0 ? -0.1 : 0.1;
      final newScale = (scale + zoomDelta).clamp(0.1, 3.0);
      final focal = e.localPosition;
      final pBefore = Offset(
        (focal.dx - pan.dx) / scale,
        (focal.dy - pan.dy) / scale,
      );
      setState(() {
        scale = newScale;
        pan = Offset(
          focal.dx - pBefore.dx * scale,
          focal.dy - pBefore.dy * scale,
        );
      });
    }
  }
  void onPointerDown(PointerDownEvent e) {
    if (e.buttons == kMiddleMouseButton) {
      isPanning = true;
      return;
    }
    if (e.buttons == kSecondaryMouseButton) {
      return;
    }
    final world = screenToWorld(e.localPosition);
    if (ctrl.tool == EditorTool.placeEntry) {
      setState(() => ctrl.placePoi(PoiType.entry, world));
      widget.onChanged();
      return;
    } else if (ctrl.tool == EditorTool.placeExit) {
      setState(() => ctrl.placePoi(PoiType.exit, world));
      widget.onChanged();
      return;
    }
    if (ctrl.tool == EditorTool.select) {
      final p = ctrl.hitTestPoi(world.dx, world.dy);
      if (p != null) {
        setState(() {
          ctrl.state.selectedPoiId = p.id;
          ctrl.state.selectedZoneId = null;
          ctrl.startMovePoi(p, world.dx, world.dy);
        });
        widget.onChanged();
        return;
      }
      final z = ctrl.hitTestZone(world.dx, world.dy);
      if (z != null) {
        setState(() {
          ctrl.state.selectedZoneId = z.id;
          ctrl.state.selectedPoiId = null;
          ctrl.startMoveZone(z, world.dx, world.dy);
        });
        widget.onChanged();
        return;
      }
      setState(() {
        ctrl.state.selectedPoiId = null;
        ctrl.state.selectedZoneId = null;
      });
      widget.onChanged();
      return;
    }
    if (ctrl.tool == EditorTool.drawRect) {
      setState(() => ctrl.startDrawZone(ZoneShape.rect, world));
    } else if (ctrl.tool == EditorTool.drawCircle) {
      setState(() => ctrl.startDrawZone(ZoneShape.circle, world));
    }
  }
  void onPointerMove(PointerMoveEvent e) {
    if (isPanning) {
      setState(() {
        pan += e.delta;
      });
      return;
    }
    final world = screenToWorld(e.localPosition);
    if (ctrl.tool == EditorTool.select) {
      if (ctrl.pois.isMoving && ctrl.state.selectedPoiId != null) {
        final p = ctrl.poiById(ctrl.state.selectedPoiId!);
        if (p != null && ctrl.updateMovePoi(p, world.dx, world.dy)) {
          setState(() {});
          widget.onChanged();
        }
      } else if (ctrl.zones.movingZone != null) {
        final z = ctrl.zones.movingZone!;
        if (ctrl.updateMoveZone(z, world.dx, world.dy)) {
          setState(() {});
          widget.onChanged();
        }
      }
      return;
    }
    if (ctrl.isDrawingZone) {
      setState(() => ctrl.updateDrawZone(world));
    }
  }
  void onPointerUp(PointerUpEvent e) {
    isPanning = false;
    if (ctrl.tool == EditorTool.select) {
      if (ctrl.pois.isMoving) {
        setState(() => ctrl.finishMovePoi());
        widget.onChanged();
      } else if (ctrl.zones.movingZone != null) {
        setState(() => ctrl.finishMoveZone());
        widget.onChanged();
      }
    }
    if (ctrl.isDrawingZone) {
      setState(() => ctrl.finishDrawZone());
      widget.onChanged();
    }
  }
  void onPointerHover(PointerHoverEvent e) {
    final world = screenToWorld(e.localPosition);
    ctrl.pois.updateHover(world.dx, world.dy);
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    final painter = StoreMapPainter(
      ctrl: ctrl,
      scale: scale,
      pan: pan,
    );
    return Listener(
      onPointerSignal: onPointerSignal,
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      onPointerHover: onPointerHover,
      child: MouseRegion(
        cursor: isPanning ? SystemMouseCursors.grabbing : SystemMouseCursors.precise,
        child: Container(
          color: Colors.grey.shade50,
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              CustomPaint(
                painter: painter,
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
