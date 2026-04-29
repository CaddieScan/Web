import '../models/product.dart';
import '../repositories/product_repository.dart';

// sert à faire le lien entre le repository et le reste de l'app, c'est lui qui va faire les appels au repository et éventuellement faire du traitement sur les données avant de les renvoyer aux pages


class ProductService {
  final ProductRepository repo;
  ProductService(this.repo);

  Future<List<Product>> fetchProducts(String storeId) => repo.getProductsByStore(storeId);
  Future<Product?> fetchProduct(String storeId, String productId) => repo.getProductById(storeId, productId);
  Future<Product> addProduct(Product product) => repo.addProduct(product);
  Future<void> addMany(List<Product> products) => repo.addManyProducts(products);
  Future<Product> updateProduct(Product product) => repo.updateProduct(product);
  Future<void> deleteProduct(String storeId, String productId) => repo.deleteProduct(storeId, productId);
}
