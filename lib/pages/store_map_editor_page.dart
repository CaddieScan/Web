import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/store_map/store_map_controller.dart';
import '../../widgets/store_map/store_map_toolbar.dart';
import '../../widgets/store_map/store_map_left_panel.dart';
import '../../widgets/store_map/store_map_canvas.dart';

// intents pour les raccourcis clavier (Ctrl+Z pour undo, Delete/Backspace pour supprimer)
class UndoIntent extends Intent {
  const UndoIntent();
}

class DeleteIntentX extends Intent {
  const DeleteIntentX();
}

// c'est là où tu peux éditer la carte/plan du magasin
// tu peux dessiner des zones, des rayons, des points de caisse, des murs, des allées, etc.
// bref toute la structure du magasin
class StoreMapEditorPage extends StatefulWidget {
  final StoreMapController ctrl;
  final String storeName;
  final Future<void> Function()? onSave;

  const StoreMapEditorPage({
    super.key,
    required this.ctrl,
    required this.storeName,
    this.onSave,
  });

  @override
  State<StoreMapEditorPage> createState() => StoreMapEditorPageState();
}

class StoreMapEditorPageState extends State<StoreMapEditorPage> {
  StoreMapController get ctrl => widget.ctrl;
  final FocusNode focusNode = FocusNode();

  // vérifie si l'utilisateur est en train de taper dans un TextField
  // utile pour pas déclencher les raccourcis clavier (Ctrl+Z, Delete) pendant qu'on tape
  bool isTypingInTextField() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;
    final ctx = focus.context;
    if (ctx == null) return false;

    return ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  @override
  void initState() {
    super.initState();
    requestEditorFocus();
  }

  @override
  void dispose() {
    focusNode.unfocus();
    focusNode.dispose();
    super.dispose();
  }

  void requestEditorFocus() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!mounted) return;
      focusNode.requestFocus();
    });
  }

  void refresh() => setState(() {});

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
          DeleteIntentX: CallbackAction<DeleteIntentX>(
            onInvoke: (intent) {
              if (isTypingInTextField()) return null;
              setState(() => ctrl.deleteSelected());
              requestEditorFocus();
              return null;
            },
          ),
          UndoIntent: CallbackAction<UndoIntent>(
            onInvoke: (intent) {
              if (isTypingInTextField()) return null;
              setState(() => ctrl.undo());
              requestEditorFocus();
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: focusNode,
          autofocus: false,
          onKeyEvent: (node, event) => KeyEventResult.ignored,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Scaffold(
              body: Column(
                children: [
                  StoreMapToolbar(
                    ctrl: ctrl,
                    storeName: widget.storeName,
                    onChanged: refresh,
                    onSave: widget.onSave,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        StoreMapLeftPanel(ctrl: ctrl, onChanged: refresh),
                        Expanded(
                          child: Stack(
                            children: [
                              StoreMapCanvas(ctrl: ctrl, onChanged: refresh),
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
