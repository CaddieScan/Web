import '../models/product.dart';

// interface pour accéder aux produits

abstract class ProductRepository {
  Future<List<Product>> getProductsByStore(String storeId);
  Future<Product?> getProductById(String storeId, String productId);
  Future<Product> addProduct(Product product);
  Future<void> addManyProducts(List<Product> products);
  Future<Product> updateProduct(Product product);
  Future<void> deleteProduct(String storeId, String productId);
}
