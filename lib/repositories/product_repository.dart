import '../models/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProductsByStore(String storeId);
  Future<Product> addProduct(Product product);
  Future<void> addManyProducts(List<Product> products);
}
