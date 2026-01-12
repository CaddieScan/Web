import 'package:flutter/material.dart';
import '../services/store_service.dart';
import 'stores_page.dart';

class HomePage extends StatelessWidget {
  final StoreService storeService;
  const HomePage({super.key, required this.storeService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: SizedBox(
          width: 220,
          height: 48,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.store),
            label: const Text('Magasin'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoresPage(storeService: storeService),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
