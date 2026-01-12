import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/store.dart';

class MapView extends StatelessWidget {
  final List<Store> stores;
  final Store? selectedStore;
  final ValueChanged<Store> onStoreSelected;

  const MapView({
    super.key,
    required this.stores,
    required this.selectedStore,
    required this.onStoreSelected,
  });

  @override
  Widget build(BuildContext context) {
    final center = selectedStore != null
        ? LatLng(selectedStore!.latitude, selectedStore!.longitude)
        : const LatLng(48.8566, 2.3522);

    return FlutterMap(
      options: MapOptions(
        center: center,
        zoom: 13,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.caddiescan.web',
        ),
        MarkerLayer(
          markers: stores.map((store) {
            final isSelected = selectedStore?.id == store.id;

            return Marker(
              point: LatLng(store.latitude, store.longitude),
              width: 46,
              height: 46,
              child: GestureDetector(
                onTap: () => onStoreSelected(store),
                child: Icon(
                  Icons.location_on,
                  size: 46,
                  color: isSelected ? Colors.red : Colors.blue,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
