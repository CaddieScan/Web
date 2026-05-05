import '../../models/store_map_models.dart';
import 'store_map_data.dart';
import 'store_map_state.dart';
class ZoneController {
  final StoreMapState state;
  final StoreMapData data;
  bool isDrawing = false;
  ZoneShape drawShape = ZoneShape.rect;
  double startX = 0;
  double startY = 0;
  double currX = 0;
  double currY = 0;
  StoreZone? movingZone;
  double moveStartX = 0;
  double moveStartY = 0;
  ZoneController(this.state, this.data);
  StoreZone? hitTest(double x, double y) {
    if (state.activeFloorId.isEmpty) return null;
    final zones = data.zonesByFloor[state.activeFloorId];
    if (zones == null) return null;
    for (final z in zones.reversed) {
      if (z.contains(x, y)) return z;
    }
    return null;
  }
  void startDraw(ZoneShape shape, double x, double y) {
    isDrawing = true;
    drawShape = shape;
    startX = x;
    startY = y;
    currX = x;
    currY = y;
  }
  void updateDraw(double x, double y) {
    if (!isDrawing) return;
    currX = x;
    currY = y;
  }
  void finishDraw() {
    if (!isDrawing) return;
    isDrawing = false;
    if (state.activeFloorId.isEmpty) return;
    final catId = data.categories.isNotEmpty ? data.categories.first.id : 'cat_default';
    final left = startX < currX ? startX : currX;
    final top = startY < currY ? startY : currY;
    final w = (currX - startX).abs();
    final h = (currY - startY).abs();
    if (w < 10 || h < 10) return;
    data.zonesByFloor.putIfAbsent(state.activeFloorId, () => []);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newZone = StoreZone(
      id: id,
      floorId: state.activeFloorId,
      name: 'Nouvelle zone',
      categoryId: catId,
      x: left,
      y: top,
      w: w,
      h: h,
      shape: drawShape,
    );
    data.zonesByFloor[state.activeFloorId]!.add(newZone);
    state.selectedZoneId = id;
    state.selectedPoiId = null;
  }
  void deleteZone(String id) {
    for (final floorId in data.zonesByFloor.keys) {
      data.zonesByFloor[floorId]!.removeWhere((z) => z.id == id);
    }
  }
  void startMove(StoreZone z, double px, double py) {
    movingZone = z;
    moveStartX = z.x;
    moveStartY = z.y;
  }
  bool updateMove(StoreZone z, double px, double py) {
    if (movingZone != z) return false;
    z.x = px;
    z.y = py;
    return true;
  }
  void finishMove() {
    movingZone = null;
  }
}
