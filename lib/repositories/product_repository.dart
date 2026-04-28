import '../models/product.dart';

// interface pour accéder aux produits

abstract class ProductRepository {
  Future<List<Product>> getProductsByStore(String storeId);
  Future<Product> addProduct(Product product);
  Future<void> addManyProducts(List<Product> products);
}
