import 'package:caddiescan_web/repositories/mock_product_repository.dart';
import 'package:caddiescan_web/repositories/mock_store_map_repository.dart';
import 'package:caddiescan_web/repositories/mock_store_repository.dart';
import 'package:caddiescan_web/pages/home_page.dart';
import 'package:caddiescan_web/services/product_service.dart';
import 'package:caddiescan_web/services/store_map_service.dart';
import 'package:caddiescan_web/services/store_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomePage affiche le bouton d entree magasin', (
    WidgetTester tester,
  ) async {
    // Quoi: verifier que l'ecran d'accueil principal se construit correctement et qu'on as bien les pages d'entrée
    // Comment: on construit la page d'accueil avec un services de mock et on cherche les textes clés à l'écran
    // Pourquoi: ce test detecte les champs manquant ou autre pour tester le front
    final storeService = StoreService(MockStoreRepository());
    final productService = ProductService(MockProductRepository());
    final storeMapService = StoreMapService(MockStoreMapRepository());

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          storeService: storeService,
          productService: productService,
          storeMapService: storeMapService,
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Magasin'), findsOneWidget);
  });
}
