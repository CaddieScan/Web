import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../controllers/store_map/store_map_controller.dart';
import '../../controllers/store_map/store_map_state.dart';
import '../../dialogs/text_prompt_dialog.dart';
import '../../dialogs/checkout_poi_dialog.dart';
import '../../models/store_poi_models.dart';
import '../../painters/store_map_painter.dart';
import 'store_map_tooltip.dart';

class StoreMapCanvas extends StatefulWidget {
  final StoreMapController ctrl;
  final VoidCallback onChanged;

  const StoreMapCanvas({
    super.key,
    required this.ctrl,
    required this.onChanged,
  });

  @override
  State<StoreMapCanvas> createState() => _StoreMapCanvasState();
}

class _StoreMapCanvasState extends State<StoreMapCanvas> {
  // camera
  double zoom = 1.0;
  Offset pan = Offset.zero;

  // hover tooltip
  String? hoverText;
  Offset? hoverPos;

  // middle pan
  bool isMiddlePanning = false;
  Offset? lastPanPos;

  // drag tracking
  bool didDrag = false;

  StoreMapController get ctrl => widget.ctrl;

  Offset screenToWorld(Offset screen) => (screen - pan) / zoom;

  Future<void> promptCreateZone() async {
    final zoneName = await showDialog<String>(
      context: context,
      builder: (_) => const TextPromptDialog(
        title: 'Nom de la zone',
        hint: 'Ex: Produits laitiers',
      ),
    );

    if (zoneName == null || zoneName.trim().isEmpty) {
      setState(() => ctrl.cancelDrawing());
      widget.onChanged();
      return;
    }

    setState(() => ctrl.finishRect(zoneName: zoneName.trim()));
    widget.onChanged();
  }

  void _openZonePopupIfAny(Offset localPos) {
    final world = screenToWorld(localPos);
    final z = ctrl.hitTestZone(world.dx, world.dy);
    if (z == null) return;

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(z.name.isEmpty ? 'Zone' : z.name),
        content: const Text('Popup vide pour l’instant.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _openPoiPopupIfAny(Offset localPos) async {
    final world = screenToWorld(localPos);
    final p = ctrl.hitTestPoi(world.dx, world.dy);
    if (p == null) return;

    if (p.type == PoiType.checkout) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => CheckoutPoiDialog(poi: p),
      );

      if (ok == true) widget.onChanged();
      return;
    }

    // Entry/Exit simple popup
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(p.label.isEmpty ? 'Point' : p.label),
        content: Text(p.type == PoiType.entry ? 'Entree' : 'Sortie'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void onPointerDown(PointerDownEvent e) {
    if (e.buttons == kMiddleMouseButton) {
      setState(() {
        isMiddlePanning = true;
        lastPanPos = e.localPosition;
      });
      return;
    }

    final world = screenToWorld(e.localPosition);

    // --- placement POI
    if (ctrl.tool == EditorTool.placeEntry) {
      setState(() => ctrl.placePoi(PoiType.entry, world));
      widget.onChanged();
      return;
    }
    if (ctrl.tool == EditorTool.placeExit) {
      setState(() => ctrl.placePoi(PoiType.exit, world));
      widget.onChanged();
      return;
    }
    if (ctrl.tool == EditorTool.placeCheckout) {
      setState(() => ctrl.placePoi(PoiType.checkout, world));
      widget.onChanged();
      return;
    }

    // --- draw rect
    if (ctrl.tool == EditorTool.drawRect) {
      setState(() => ctrl.startRect(world.dx, world.dy));
      widget.onChanged();
      return;
    }

    // --- draw wall
    if (ctrl.tool == EditorTool.drawWall) {
      setState(() => ctrl.startWallPoint(world));
      widget.onChanged();
      return;
    }

    // --- draw aisle
    if (ctrl.tool == EditorTool.drawAisle) {
      setState(() => ctrl.startAislePoint(world));
      widget.onChanged();
      return;
    }

    // --- select mode
    didDrag = false;

    // POI first
    final poi = ctrl.hitTestPoi(world.dx, world.dy);
    if (poi != null) {
      setState(() => ctrl.selectPoi(poi.id));
      widget.onChanged();

      setState(() => ctrl.startMovePoi(poi, world.dx, world.dy));
      widget.onChanged();
      return;
    }

    // then zones
    final z = ctrl.hitTestZone(world.dx, world.dy);
    if (z == null) {
      setState(() => ctrl.clearSelection());
      widget.onChanged();
      return;
    }

    setState(() => ctrl.selectZone(z.id));
    widget.onChanged();

    final handleRadiusWorld = 10 / zoom;
    final handle = ctrl.hitTestHandle(
      z: z,
      px: world.dx,
      py: world.dy,
      radiusWorld: handleRadiusWorld,
    );

    if (handle != null) {
      setState(() => ctrl.startResize(z, handle, world.dx, world.dy));
      widget.onChanged();
      return;
    }

    setState(() => ctrl.startMove(z, world.dx, world.dy));
    widget.onChanged();
  }

  void onPointerMove(PointerMoveEvent e) {
    if (isMiddlePanning && lastPanPos != null) {
      final delta = e.localPosition - lastPanPos!;
      setState(() {
        pan += delta;
        lastPanPos = e.localPosition;
      });
      widget.onChanged();
      return;
    }

    final world = screenToWorld(e.localPosition);

    // preview wall/aisle
    if (ctrl.tool == EditorTool.drawWall && ctrl.isDrawingWall) {
      setState(() => ctrl.updateWallPreview(world));
      widget.onChanged();
      return;
    }
    if (ctrl.tool == EditorTool.drawAisle && ctrl.isDrawingAisle) {
      setState(() => ctrl.updateAislePreview(world));
      widget.onChanged();
      return;
    }

    // drawing zone
    if (ctrl.isDrawingRect) {
      setState(() => ctrl.updateRect(world.dx, world.dy));
      widget.onChanged();
      return;
    }

    // moving POI
    final poiId = ctrl.selectedPoiId;
    if (poiId != null && ctrl.isMovingPoi) {
      final poi = ctrl.poiById(poiId);
      if (poi != null) {
        final changed = ctrl.updateMovePoi(poi, world.dx, world.dy);
        if (changed) didDrag = true;
        setState(() {});
        widget.onChanged();
        return;
      }
    }

    // move/resize zones
    final z = ctrl.selectedZone;
    if (z != null && ctrl.isMoving) {
      final changed = ctrl.updateMove(z, world.dx, world.dy);
      if (changed) didDrag = true;
      setState(() {});
      widget.onChanged();
      return;
    }

    if (z != null && ctrl.isResizing) {
      final changed = ctrl.updateResize(z, world.dx, world.dy);
      if (changed) didDrag = true;
      setState(() {});
      widget.onChanged();
      return;
    }
  }

  Future<void> onPointerUp(PointerUpEvent e) async {
    if (isMiddlePanning) {
      setState(() {
        isMiddlePanning = false;
        lastPanPos = null;
      });
      widget.onChanged();
      return;
    }

    if (ctrl.tool == EditorTool.drawRect && ctrl.isDrawingRect) {
      if (ctrl.previewZone != null &&
          ctrl.previewZone!.w >= ctrl.gridSize &&
          ctrl.previewZone!.h >= ctrl.gridSize) {
        await promptCreateZone();
      } else {
        setState(() => ctrl.cancelDrawing());
        widget.onChanged();
      }
      return;
    }

    if (ctrl.isMovingPoi) {
      setState(() => ctrl.finishMovePoi());
      widget.onChanged();
    }

    if (ctrl.isMoving) {
      setState(() => ctrl.finishMove());
      widget.onChanged();
    }
    if (ctrl.isResizing) {
      setState(() => ctrl.finishResize());
      widget.onChanged();
    }
  }

  void onWheel(PointerSignalEvent e) {
    if (e is! PointerScrollEvent) return;

    final delta = e.scrollDelta.dy;
    final factor = (delta > 0) ? 0.9 : 1.1;
    final newZoom = (zoom * factor).clamp(0.4, 3.0);

    final mouse = e.localPosition;
    final worldBefore = screenToWorld(mouse);

    setState(() {
      zoom = newZoom;
      final worldAfter = screenToWorld(mouse);
      pan += (worldAfter - worldBefore) * zoom;
    });
    widget.onChanged();
  }

  void handleHover(Offset localPos) {
    final world = screenToWorld(localPos);

    setState(() {
      ctrl.updateHover(world.dx, world.dy);

      // tooltip POI
      final hp = ctrl.hoveredPoiId == null ? null : ctrl.poiById(ctrl.hoveredPoiId!);
      if (hp != null) {
        hoverText = _poiTooltip(hp);
        hoverPos = localPos;
        return;
      }

      // tooltip zone
      final hz = ctrl.hoveredZoneId == null ? null : ctrl.zoneById(ctrl.hoveredZoneId!);
      if (hz != null) {
        hoverText = '${hz.name} • ${ctrl.categoryById(hz.categoryId).name}';
        hoverPos = localPos;
      } else {
        hoverText = null;
        hoverPos = null;
      }
    });
  }

  String _poiTooltip(StorePoi p) {
    if (p.type == PoiType.entry) return 'Entree';
    if (p.type == PoiType.exit) return 'Sortie';

    // checkout
    final kind = p.checkoutKind == CheckoutKind.selfCheckout ? 'Auto' : 'Caissiere';
    final pay = p.paymentMode == PaymentMode.cardOnly ? 'CB' : 'CB+€';
    final pmr = p.isAccessible ? ' • PMR' : '';
    final title = p.label.isEmpty ? 'Caisse' : p.label;
    return '$title • $kind • $pay$pmr';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MouseRegion(
          onHover: (ev) => handleHover(ev.localPosition),
          onExit: (_) => setState(() {
            ctrl.clearHover();
            hoverText = null;
            hoverPos = null;
          }),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTapDown: (details) {
              if (ctrl.tool == EditorTool.select) {
                if (!didDrag) {
                  // POI priorité
                  _openPoiPopupIfAny(details.localPosition);
                  _openZonePopupIfAny(details.localPosition);
                }
                return;
              }
              if (ctrl.tool == EditorTool.drawWall) {
                setState(() => ctrl.finishWall());
                widget.onChanged();
                return;
              }
              if (ctrl.tool == EditorTool.drawAisle) {
                setState(() => ctrl.finishAisle());
                widget.onChanged();
                return;
              }
            },
            child: Listener(
              onPointerDown: onPointerDown,
              onPointerMove: onPointerMove,
              onPointerUp: (e) => onPointerUp(e),
              onPointerSignal: onWheel,
              child: CustomPaint(
                painter: StoreMapPainter(ctrl: ctrl, zoom: zoom, pan: pan),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),

        if (hoverText != null && hoverPos != null)
          StoreMapTooltip(
            left: 320 + hoverPos!.dx + 12,
            top: 56 + hoverPos!.dy + 12,
            text: hoverText!,
          ),
      ],
    );
  }
}
