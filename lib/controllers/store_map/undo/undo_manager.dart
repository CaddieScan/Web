import '../store_map_data.dart';
import '../store_map_state.dart';

class StoreMapSnapshot {
  final StoreMapState state;
  final StoreMapData data;

  StoreMapSnapshot({required this.state, required this.data});
}

class UndoManager {
  final List<StoreMapSnapshot> _undo = [];
  final int maxSize;

  UndoManager({this.maxSize = 60});

  bool get canUndo => _undo.isNotEmpty;

  void clear() => _undo.clear();

  void push(StoreMapState state, StoreMapData data) {
    _undo.add(
      StoreMapSnapshot(
        state: state.deepCopy(),
        data: data.deepCopy(),
      ),
    );

    if (_undo.length > maxSize) {
      _undo.removeAt(0);
    }
  }

  StoreMapSnapshot? undo() {
    if (_undo.isEmpty) return null;
    return _undo.removeLast();
  }
}
