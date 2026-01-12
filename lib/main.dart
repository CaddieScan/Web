import 'package:flutter/material.dart';

import 'pages/login_page.dart';
import 'repositories/mock_store_repository.dart';
import 'services/store_service.dart';

void main() {
  final repo = MockStoreRepository();
  final storeService = StoreService(repo);

  runApp(MyApp(storeService: storeService));
}

class MyApp extends StatelessWidget {
  final StoreService storeService;

  const MyApp({
    super.key,
    required this.storeService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CaddieScan',
      home: LoginPage(storeService: storeService),
    );
  }
}
