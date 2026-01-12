import 'package:flutter/material.dart';
import '../models/store.dart';

class StorePage extends StatelessWidget {
  final Store store;
  const StorePage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(store.name)),
      body: const Center(
        child: Text('Page magasin (vide pour le moment)'),
      ),
    );
  }
}
