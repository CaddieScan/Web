import 'dart:ui';

import 'package:caddiescan_web/controllers/store_map/store_map_controller.dart';
import 'package:caddiescan_web/models/store_poi_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoreMapController - tests unitaires', () {
    test('initialise un etage et une categorie par defaut', () {
      // Quoi: verifier l'état initial du controller d'édition de carte de magasin
      // Comment: on instancie le controleur puis on controle les collections et selections actives
      // Pourquoi: garantir un demarrage stable de l'outil d'édition de carte
      final ctrl = StoreMapController();

      expect(ctrl.floors.length, 1);
      expect(ctrl.categories.length, 1);
      expect(ctrl.activeFloorId, isNotNull);
      expect(ctrl.activeCategoryId, isNotNull);
    });

    test('addCategory et deleteCategory fonctionne bien ', () {
      // Quoi: verifier ajout, suppression et protection de la derniere categorie
      // Comment: on ajoute une categorie, on la supprime, puis on tente de supprimer la derniere
      // Pourquoi: eviter les etats invalides dans la carte genre aucune categorie pour les zones, ce qui casserait l'édition et l'affichage
      final ctrl = StoreMapController();
      final initialCategoryId = ctrl.activeCategoryId;

      final added = ctrl.addCategory('Boissons');

      expect(ctrl.categories.length, 2);
      expect(ctrl.activeCategoryId, added.id);

      final deleted = ctrl.deleteCategory(added.id);
      expect(deleted, isTrue);
      expect(ctrl.categories.length, 1);
      expect(ctrl.activeCategoryId, initialCategoryId);

      final cannotDeleteLast = ctrl.deleteCategory(ctrl.categories.first.id);
      expect(cannotDeleteLast, isFalse);
      expect(ctrl.categories.length, 1);
    });

    test('placePoi ajoute et selectionne un POI sur l etage actif', () {
      // Quoi: verifier le placement d'un point d'intéret
      // Comment: on place un POI puis on verifie sa presence et la selection courante
      // Pourquoi: valider qu'on peut ajouter des POI et que on suit bien ce qu'on sélectionne pour l'édition et les propriétés affichées
      final ctrl = StoreMapController();

      final poi = ctrl.placePoi(PoiType.entry, const Offset(100, 150));

      expect(poi, isNotNull);
      expect(ctrl.activePois.length, 1);
      expect(ctrl.selectedPoiId, poi!.id);
      expect(ctrl.selectedZoneId, isNull);
    });

    test('undo annule la derniere modification', () {
      // Quoi: on vérifie la liste des dernières actions et la capacité à revenir en arrière
      // Comment: on ajotue un POI puis on appelle undo et on vérifie que le POI est supprimé
      // Pourquoi: assurer que le undo fonctionne pour corriger les erreurs d'édition sans devoir tout refaire
      final ctrl = StoreMapController();

      ctrl.placePoi(PoiType.checkout, const Offset(120, 220));
      expect(ctrl.activePois.length, 1);
      expect(ctrl.canUndo, isTrue);

      ctrl.undo();
      expect(ctrl.activePois.length, 0);
    });
  });
}
