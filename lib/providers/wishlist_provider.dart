import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../services/haptic_service.dart';

class WishlistProvider with ChangeNotifier {
  static const String _basePrefKey = 'lumora_wishlist_ids';
  String? _currentUserKey;
  final Set<String> _favoriteIds = {};

  WishlistProvider() {
    _loadFromPreferences();
  }

  String get _prefKey => (_currentUserKey != null && _currentUserKey!.isNotEmpty)
      ? '${_basePrefKey}_$_currentUserKey'
      : _basePrefKey;

  Future<void> syncWithAuth(String? userEmail) async {
    final normalized = userEmail?.trim().toLowerCase();
    if (_currentUserKey == normalized) return;
    _currentUserKey = normalized;
    await _loadFromPreferences();
  }

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  int get count => _favoriteIds.length;
  bool get isEmpty => _favoriteIds.isEmpty;

  bool isFavorite(String productId) {
    return _favoriteIds.contains(productId);
  }

  void toggleFavorite(Product product) {
    HapticService.mediumImpact();
    if (_favoriteIds.contains(product.id)) {
      _favoriteIds.remove(product.id);
    } else {
      _favoriteIds.add(product.id);
    }
    _saveToPreferences();
    notifyListeners();
  }

  void addFavorite(Product product) {
    if (!_favoriteIds.contains(product.id)) {
      HapticService.mediumImpact();
      _favoriteIds.add(product.id);
      _saveToPreferences();
      notifyListeners();
    }
  }

  void removeFavorite(String productId) {
    if (_favoriteIds.contains(productId)) {
      HapticService.lightImpact();
      _favoriteIds.remove(productId);
      _saveToPreferences();
      notifyListeners();
    }
  }

  List<Product> getWishlistItems([List<Product>? allProducts]) {
    final catalog = (allProducts != null && allProducts.isNotEmpty)
        ? allProducts
        : MockData.unifiedCatalog;
    return catalog.where((p) => _favoriteIds.contains(p.id)).toList();
  }

  void clearWishlist() {
    _favoriteIds.clear();
    _saveToPreferences();
    notifyListeners();
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_prefKey);
      _favoriteIds.clear();
      if (ids != null) {
        // Prune any orphaned IDs that do not exist in the active catalog
        final validCatalogIds = MockData.unifiedCatalog.map((p) => p.id).toSet();
        final validIds = ids.where((id) => validCatalogIds.contains(id)).toSet();
        _favoriteIds.addAll(validIds);
        if (validIds.length != ids.length) {
          // Sync cleansed list back to preferences
          await prefs.setStringList(_prefKey, validIds.toList());
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading wishlist from preferences: $e');
    }
  }

  Future<void> _saveToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, _favoriteIds.toList());
    } catch (e) {
      debugPrint('Error saving wishlist to preferences: $e');
    }
  }
}
