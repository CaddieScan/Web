import 'package:caddiescan_web/models/store.dart';
import 'package:caddiescan_web/repositories/mock_store_repository.dart';
import 'package:caddiescan_web/services/store_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoreService - tests unitaires', () {
    test('fetchStores retourne les magasins mocks initiaux', () async {
      // Quoi: verifier la lecture de la liste des magasins
      // Comment: on appelle fetchStores() sur un repository mock puis on vérifie qu'on retrouve notre test
      // Pourquoi: valider qu'on peut lire les données de magasins et que le service fait bien le lien avec le repository
      final service = StoreService(MockStoreRepository());

      final stores = await service.fetchStores();

      expect(stores.length, 3);
      expect(stores.first.name, 'Carrefour Centre');
    });

    test('addStore ajoute un nouveau magasin', () async {
      // Quoi: verifier l'ajout d un magasin via le service
      // Comment: on ajoute une entite puis on relit la liste complete
      // Pourquoi: garantir que la creation est bien propagee cote service
      final service = StoreService(MockStoreRepository());

      await service.addStore(
        const Store(
          id: '',
          name: 'Nouveau Magasin',
          latitude: 10.5,
          longitude: 20.5,
        ),
      );

      final stores = await service.fetchStores();
      expect(stores.length, 4);
      expect(stores.any((s) => s.name == 'Nouveau Magasin'), isTrue);
    });
  });
}
