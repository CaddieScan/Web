import 'package:caddiescan_web/models/product.dart';
import 'package:caddiescan_web/repositories/mock_product_repository.dart';
import 'package:caddiescan_web/services/product_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductService - tests unitaires', () {
    test('fetchProducts retourne les produits d un magasin', () async {
      // Quoi: verifier la recuperation des produits par identifiant magasin
      // Comment: on appelle fetchProducts("1") puis on controle le contenu
      // Pourquoi:  pour éviter les erreurs de filtrage ou de données mal associés au magasin
      final service = ProductService(MockProductRepository());

      final products = await service.fetchProducts('1');

      expect(products, isNotEmpty);
      expect(products.first.storeId, '1');
    });

    test('addProduct ajoute un produit dans le magasin cible', () async {
      // Quoi: verifier l'ajout d'un produit dans un magasin
      // Comment: on compare la taille avant/apres puis on cherche le nom ajoute
      // Pourquoi: confirmer que le service ecrit bien dans le bon magasin
      final service = ProductService(MockProductRepository());

      final before = await service.fetchProducts('1');

      await service.addProduct(
        const Product(
          id: '',
          storeId: '1',
          name: 'Test Produit',
          category: 'Tests',
          quantity: 2,
          unit: 'pcs',
          imageAssetPath: 'images/product_placeholder.png',
          price: 1.99,
        ),
      );

      final after = await service.fetchProducts('1');

      expect(after.length, before.length + 1);
      expect(after.any((p) => p.name == 'Test Produit'), isTrue);
    });

    test('addMany ajoute plusieurs produits en lot', () async {
      // Quoi: verifier l'ajout de plusieurs produits dans un magasin en une seule opération
      // Comment: on injecte deux produits puis on valide l increment et leur presence
      // Pourquoi: securiser qu'on puisse bien faire des imports de catalogue ou des mises à jour en masse sans erreurs
      final service = ProductService(MockProductRepository());

      final before = await service.fetchProducts('2');

      await service.addMany([
        const Product(
          id: '',
          storeId: '2',
          name: 'Batch A',
          category: 'Batch',
          quantity: 1,
          unit: 'pcs',
          imageAssetPath: 'images/product_placeholder.png',
        ),
        const Product(
          id: '',
          storeId: '2',
          name: 'Batch B',
          category: 'Batch',
          quantity: 1,
          unit: 'pcs',
          imageAssetPath: 'images/product_placeholder.png',
        ),
      ]);

      final after = await service.fetchProducts('2');

      expect(after.length, before.length + 2);
      expect(after.any((p) => p.name == 'Batch A'), isTrue);
      expect(after.any((p) => p.name == 'Batch B'), isTrue);
    });
  });
}
