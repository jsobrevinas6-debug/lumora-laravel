import '../data/mock_data.dart';
import '../models/models.dart';

/// Abstract contract for product and catalog data retrieval.
/// Allows swapping between local mock data and live Laravel REST API.
abstract class IProductRepository {
  Future<List<Product>> getFeaturedProducts();
  Future<List<Product>> getFlashDeals();
  Future<List<Product>> getProductsByCategory(String category);
  Future<List<Product>> searchProducts(String query);
  Future<Product?> getProductById(String id);
  Future<List<CategoryItem>> getCategories();
  Future<List<HeroSlide>> getHeroSlides();
}

/// Production-ready mock implementation using Lumora curated assets.
/// Can be replaced with `LaravelProductRepository` connecting to Dio/HTTP endpoints.
class ProductRepository implements IProductRepository {
  static final ProductRepository _instance = ProductRepository._internal();
  factory ProductRepository() => _instance;
  ProductRepository._internal();

  @override
  Future<List<Product>> getFeaturedProducts() async {
    // Simulate instantaneous local luxury cache
    return List.unmodifiable(MockData.allProducts);
  }

  @override
  Future<List<Product>> getFlashDeals() async {
    return List.unmodifiable(MockData.flashDeals);
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    if (category.isEmpty || category.toLowerCase() == 'all') {
      return List.unmodifiable(MockData.allProducts);
    }
    return MockData.allProducts
        .where((p) => p.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return List.unmodifiable(MockData.allProducts);

    return MockData.allProducts.where((p) {
      final matchName = p.name.toLowerCase().contains(cleanQuery);
      final matchCat = p.category.toLowerCase().contains(cleanQuery);
      final matchDesc = p.description.toLowerCase().contains(cleanQuery);
      return matchName || matchCat || matchDesc;
    }).toList();
  }

  @override
  Future<Product?> getProductById(String id) async {
    try {
      return MockData.unifiedCatalog.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<CategoryItem>> getCategories() async {
    return List.unmodifiable(MockData.categories);
  }

  @override
  Future<List<HeroSlide>> getHeroSlides() async {
    return List.unmodifiable(MockData.heroSlides);
  }
}
