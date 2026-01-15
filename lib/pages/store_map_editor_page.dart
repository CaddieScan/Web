import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/store_map/store_map_controller.dart';
import '../../widgets/store_map/store_map_left_panel.dart';
import '../../widgets/store_map/store_map_toolbar.dart';
import '../../widgets/store_map/store_map_canvas.dart';

class UndoIntent extends Intent {
  const UndoIntent();
}

class DeleteIntentX extends Intent {
  const DeleteIntentX();
}

class StoreMapEditorPage extends StatefulWidget {
  final StoreMapController ctrl;
  final String storeName;

  const StoreMapEditorPage({
    super.key,
    required this.ctrl,
    required this.storeName,
  });

  @override
  State<StoreMapEditorPage> createState() => _StoreMapEditorPageState();
}

class _StoreMapEditorPageState extends State<StoreMapEditorPage> {
  late final FocusNode _focusNode;

  StoreMapController get ctrl => widget.ctrl;

  bool _isTypingInTextField() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;
    final ctx = focus.context;
    if (ctx == null) return false;

    // Si le focus est dans un EditableText (TextField / TextFormField)
    return ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'StoreMapEditorFocus');

    // ✅ IMPORTANT: request focus after first frame (web needs it)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyZ, control: true): UndoIntent(),
        SingleActivator(LogicalKeyboardKey.delete): DeleteIntentX(),
        SingleActivator(LogicalKeyboardKey.backspace): DeleteIntentX(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          UndoIntent: CallbackAction<UndoIntent>(
            onInvoke: (_) {
              setState(() => ctrl.undo());
              return null;
            },
          ),
          DeleteIntentX: CallbackAction<DeleteIntentX>(
            onInvoke: (_) {
              if (_isTypingInTextField()) return null;
              setState(() => ctrl.deleteSelected());
              _focusNode.requestFocus();

              return null;
            },
          ),
          UndoIntent: CallbackAction<UndoIntent>(
            onInvoke: (_) {
              if (_isTypingInTextField()) return null;
              setState(() => ctrl.undo());
              _focusNode.requestFocus();
              return null;
            },
          ),

        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (_, __) => KeyEventResult.ignored,
          child: GestureDetector(
            // ✅ Click anywhere gives focus back (super important on web)
            behavior: HitTestBehavior.opaque,
            onTap: () => _focusNode.requestFocus(),
            child: Scaffold(
              body: Column(
                children: [
                  StoreMapToolbar(
                    ctrl: ctrl,
                    storeName: widget.storeName,
                    onChanged: _refresh,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        StoreMapLeftPanel(ctrl: ctrl, onChanged: _refresh),
                        Expanded(
                          child: Stack(
                            children: [
                              StoreMapCanvas(ctrl: ctrl, onChanged: _refresh),

                              // ✅ DEBUG (tu peux supprimer après)
                              Positioned(
                                left: 12,
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.65),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: DefaultTextStyle(
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Focus: ${_focusNode.hasFocus}'),
                                        Text('SelZone: ${ctrl.selectedZoneId ?? "-"}'),
                                        Text('SelPoi: ${ctrl.selectedPoiId ?? "-"}'),
                                        Text('SelWall: ${ctrl.selectedWallIndex?.toString() ?? "-"}'),
                                        Text('SelNode: ${ctrl.selectedAisleNodeIndex?.toString() ?? "-"}'),
                                        Text('SelEdge: ${ctrl.selectedAisleEdgeIndex?.toString() ?? "-"}'),
                                        Text('Undo: ${ctrl.canUndo}'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
