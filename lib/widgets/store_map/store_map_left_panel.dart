import 'package:flutter/material.dart';
import '../../controllers/store_map/store_map_controller.dart';
import '../../controllers/store_map/store_map_state.dart';
class StoreMapLeftPanel extends StatelessWidget {
  final StoreMapController ctrl;
  final VoidCallback onChanged;
  const StoreMapLeftPanel({
    super.key,
    required this.ctrl,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          ListTile(
            title: const Text('Étages', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                ctrl.addFloor();
                onChanged();
              },
            ),
          ),
          ...ctrl.floors.map((f) {
            final isActive = ctrl.activeFloorId == f.id;
            return ListTile(
              selected: isActive,
              title: Text(f.name),
              onTap: () {
                ctrl.setActiveFloor(f.id);
                onChanged();
              },
            );
          }),
          const Divider(),
          ListTile(
            title: const Text('Catégories', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                ctrl.addCategory('Nouvelle Catégorie');
                onChanged();
              },
            ),
          ),
          Expanded(
            child: ListView(
              children: ctrl.categories.map((c) {
                final isActive = ctrl.activeCategoryId == c.id;
                return ListTile(
                  selected: isActive,
                  leading: CircleAvatar(backgroundColor: c.color, radius: 10),
                  title: Text(c.name),
                  onTap: () {
                    ctrl.setActiveCategory(c.id);
                    onChanged();
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, size: 16),
                    onPressed: () {
                      if (ctrl.deleteCategory(c.id)) {
                        onChanged();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
