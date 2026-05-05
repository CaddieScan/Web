import '../store_map_controller.dart';
import '../store_map_data.dart';
import '../store_map_state.dart';
class UndoState {
  final StoreMapState state;
  final StoreMapData data;
  UndoState({required this.state, required this.data});
}
class UndoManager {
  final StoreMapController ctrl;
  final int maxSize;
  final List<UndoState> _history = [];
  UndoManager(this.ctrl, {this.maxSize = 60});
  bool get canUndo => _history.length > 1;
  void saveState() {
    _history.add(UndoState(
      state: ctrl.state.deepCopy(),
      data: ctrl.data.deepCopy(),
    ));
    if (_history.length > maxSize) {
      _history.removeAt(0);
    }
  }
  void undo() {
    if (!canUndo) return;
    _history.removeLast();
    final last = _history.last;
    ctrl.state.loadFrom(last.state);
    ctrl.data = last.data.deepCopy();
    ctrl.zones.isDrawing = false;
    ctrl.zones.movingZone = null;
    ctrl.pois.movingPoi = null;
    ctrl.selectedZoneId == null;
    ctrl.selectedPoiId == null;
  }
}
