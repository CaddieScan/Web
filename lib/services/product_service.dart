import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductService {
  final ProductRepository repo;
  ProductService(this.repo);

  Future<List<Product>> fetchProducts(String storeId) => repo.getProductsByStore(storeId);
  Future<Product> addProduct(Product product) => repo.addProduct(product);
  Future<void> addMany(List<Product> products) => repo.addManyProducts(products);
}
