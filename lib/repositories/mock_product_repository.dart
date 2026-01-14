import '../models/product.dart';
import 'product_repository.dart';

class MockProductRepository implements ProductRepository {
  static const String _placeholderImg = 'images/product_placeholder.png';

  final Map<String, List<Product>> _byStore = {
    // Store 1 (ex: Carrefour Centre)
    '1': [
      // Produits laitiers
      Product(
        id: 'p1',
        storeId: '1',
        name: 'Lait demi-écreme 1L',
        category: 'Produits laitiers',
        price: 1.15,
        quantity: 24,
        unit: 'pcs',
        barcode: '3560070000011',
        imageAssetPath: _placeholderImg,
      ),
      Product(
        id: 'p2',
        storeId: '1',
        name: 'Yaourt nature x12',
        category: 'Produits laitiers',
        price: 2.89,
        quantity: 18,
        unit: 'pcs',
        barcode: '3560070000028',
        imageAssetPath: _placeholderImg,
      ),
      Product(
        id: 'p3',
        storeId: '1',
        name: 'Beurre doux 250g',
        category: 'Produits laitiers',
        price: 2.49,
        quantity: 12,
        unit: 'pcs',
        barcode: '3560070000035',
        imageAssetPath: _placeholderImg,
      ),
      Product(
        id: 'p4',
        storeId: '1',
        name: 'Emmental rape 200g',
        category: 'Produits laitiers',
        price: 2.25,
        quantity: 9,
        unit: 'pcs',
        barcode: '3560070000042',
        imageAssetPath: _placeholderImg,
      ),

      // Boissons
      Product(
        id: 'p5',
        storeId: '1',
        name: 'Eau minerale 6x1.5L',
        category: 'Boissons',
        price: 2.10,
        quantity: 30,
        unit: 'packs',
        barcode: '3560070000103',
        imageAssetPath: _placeholderImg,
      ),
      Product(
        id: 'p6',
        storeId: '1',
        name: 'Jus d\'orange 1L',
        category: 'Boissons',
        price: 1.75,
        quantity: 14,
        unit: 'pcs',
        barcode: '3560070000110',
        imageAssetPath: _placeholderImg,
      ),
      Product(
        id: 'p7',
        storeId: '1',
        name: 'Soda cola 1.5L',
        category: 'Boissons',
        price: 1.59,
        quantity: 22,
        unit: 'pcs',
        barcode: '3560070000127',
        imageAssetPath: _placeholderImg,
      ),

      // Epicerie
      Product(
        id: 'p8',
        storeId: '1',
        name: 'Pates spaghetti 500g',
        category: 'Epicerie',
        price: 1.05,
        quantity: 40,
        unit: 'pcs',
        barcode: '3560070000202',
        imageAssetPath: _placeholderImg,
      ),
      Product(
        id: 'p9',
        storeId: '1',
        name: 'Riz basmati 1kg',
        category: 'Epicerie',
        price: 2.35,
        quantity: 16,
        unit: 'pcs',
        barcode: '3560070000219',
        imageAssetPath: _placeholderImg,
      ),
      Product(
        id: 'p10',
        storeId: '1',
        name: 'Sauce tomate 400g',
        category: 'Epicerie',
        price: 0.95,
        quantity: 28,
        unit: 'pcs',
        barcode: '3560070000226',
        imageAssetPath: _placeholderImg,
      ),
      Product(
        id: 'p11',
        storeId: '1',
        name: 'Cereales chocolat 375g',
        category: 'Epicerie',
        price: 3.49,
        quantity: 7,
        unit: 'pcs',
        barcode: '3560070000233',
        imageAssetPath: _placeholderImg,
      ),

      // Fruits & legumes
      Product(
        id: 'p12',
        storeId: '1',
        name: 'Pommes (1kg)',
        category: 'Fruits & legumes',
        price: 2.99,
        quantity: 35,
        unit: 'kg',
        barcode: null,
        imageAssetPath: _placeholderImg,
      ),
      Product(
        id: 'p13',
        storeId: '1',
        name: 'Bananes (1kg)',
        category: 'Fruits & legumes',
        price: 1.89,
        quantity: 28,
        unit: 'kg',
        barcode: null,
        imageAssetPath: _placeholderImg,
      ),
      Product(
        id: 'p14',
        storeId: '1',
        name: 'Tomates (1kg)',
        category: 'Fruits & legumes',
        price: 3.49,
        quantity: 12,
        unit: 'kg',
        barcode: null,
        imageAssetPath: _placeholderImg,
      ),

      // Surgeles
      Product(
        id: 'p15',
        storeId: '1',
        name: 'Frites 1kg',
        category: 'Surgeles',
        price: 2.69,
        quantity: 10,
        unit: 'pcs',
        barcode: '3560070000400',
        imageAssetPath: _placeholderImg,
      ),
      Product(
        id: 'p16',
        storeId: '1',
        name: 'Pizza margherita',
        category: 'Surgeles',
        price: 2.99,
        quantity: 6,
        unit: 'pcs',
        barcode: '3560070000417',
        imageAssetPath: _placeholderImg,
      ),

      // Hygiene
      Product(
        id: 'p17',
        storeId: '1',
        name: 'Shampooing 250ml',
        category: 'Hygiene',
        price: 3.20,
        quantity: 8,
        unit: 'pcs',
        barcode: '3560070000509',
        imageAssetPath: _placeholderImg,
      ),
      Product(
        id: 'p18',
        storeId: '1',
        name: 'Dentifrice 75ml',
        category: 'Hygiene',
        price: 1.95,
        quantity: 15,
        unit: 'pcs',
        barcode: '3560070000516',
        imageAssetPath: _placeholderImg,
      ),

      // Entretien
      Product(
        id: 'p19',
        storeId: '1',
        name: 'Lessive 2L',
        category: 'Entretien',
        price: 6.50,
        quantity: 5,
        unit: 'pcs',
        barcode: '3560070000608',
        imageAssetPath: _placeholderImg,
      ),
      Product(
        id: 'p20',
        storeId: '1',
        name: 'Liquide vaisselle 500ml',
        category: 'Entretien',
        price: 1.80,
        quantity: 11,
        unit: 'pcs',
        barcode: '3560070000615',
        imageAssetPath: _placeholderImg,
      ),

      // Boucherie
      Product(
        id: 'p21',
        storeId: '1',
        name: 'Steak hache x2',
        category: 'Boucherie',
        price: 5.20,
        quantity: 9,
        unit: 'pcs',
        barcode: null,
        imageAssetPath: _placeholderImg,
      ),
      Product(
        id: 'p22',
        storeId: '1',
        name: 'Blanc de poulet (500g)',
        category: 'Boucherie',
        price: 6.10,
        quantity: 6,
        unit: 'pcs',
        barcode: null,
        imageAssetPath: _placeholderImg,
      ),
    ],

    // Store 2 (ex: Auchan Nord)
    '2': [
      Product(
        id: 'a1',
        storeId: '2',
        name: 'Lait entier 1L',
        category: 'Produits laitiers',
        price: 1.10,
        quantity: 20,
        unit: 'pcs',
        barcode: '3456789000012',
        imageAssetPath: _placeholderImg,
      ),
      Product(
        id: 'a2',
        storeId: '2',
        name: 'Eau gazeuse 6x1.5L',
        category: 'Boissons',
        price: 2.40,
        quantity: 12,
        unit: 'packs',
        barcode: '3456789000029',
        imageAssetPath: _placeholderImg,
      ),
      Product(
        id: 'a3',
        storeId: '2',
        name: 'Farine 1kg',
        category: 'Epicerie',
        price: 1.25,
        quantity: 26,
        unit: 'pcs',
        barcode: '3456789000036',
        imageAssetPath: _placeholderImg,
      ),
      Product(
        id: 'a4',
        storeId: '2',
        name: 'Poulet roti',
        category: 'Boucherie',
        price: 8.90,
        quantity: 4,
        unit: 'pcs',
        barcode: null,
        imageAssetPath: _placeholderImg,
      ),
    ],

    // Store 3 (ex: Leclerc Sud)
    '3': [
      Product(
        id: 'l1',
        storeId: '3',
        name: 'Camembert',
        category: 'Produits laitiers',
        price: 2.15,
        quantity: 10,
        unit: 'pcs',
        barcode: '1234567890123',
        imageAssetPath: _placeholderImg,
      ),
      Product(
        id: 'l2',
        storeId: '3',
        name: 'Cafe moulu 250g',
        category: 'Epicerie',
        price: 2.80,
        quantity: 13,
        unit: 'pcs',
        barcode: '1234567890451',
        imageAssetPath: _placeholderImg,
      ),
      Product(
        id: 'l3',
        storeId: '3',
        name: 'Lessive 2L',
        category: 'Entretien',
        price: 6.50,
        quantity: 3,
        unit: 'pcs',
        barcode: '1234567890789',
        imageAssetPath: _placeholderImg,
      ),
    ],
  };

  int _nextId = 1000;

  @override
  Future<List<Product>> getProductsByStore(String storeId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_byStore[storeId] ?? []);
  }

  @override
  Future<Product> addProduct(Product product) async {
    await Future.delayed(const Duration(milliseconds: 120));

    // Si l'appelant ne donne pas d'image, on met le placeholder
    final created = product.copyWith(
      id: 'm${_nextId++}',
      imageAssetPath: product.imageAssetPath.isEmpty ? _placeholderImg : product.imageAssetPath,
    );

    final list = _byStore.putIfAbsent(created.storeId, () => []);
    list.add(created);
    return created;
  }

  @override
  Future<void> addManyProducts(List<Product> products) async {
    await Future.delayed(const Duration(milliseconds: 200));

    for (final p in products) {
      final created = p.copyWith(
        id: 'm${_nextId++}',
        imageAssetPath: p.imageAssetPath.isEmpty ? _placeholderImg : p.imageAssetPath,
      );

      final list = _byStore.putIfAbsent(created.storeId, () => []);
      list.add(created);
    }
  }
}
