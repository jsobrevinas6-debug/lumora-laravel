import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mock_data.dart';
import '../models/models.dart';

class CartProvider extends ChangeNotifier {
  static const String _cartPrefKey = 'lumora_cart_items';
  static const int maxPerBuyerLimit = 5;

  final Map<String, CartItem> _items = {};
  bool _isOffline = false;
  bool _hasPendingSync = false;

  bool get isOffline => _isOffline;
  bool get hasPendingSync => _hasPendingSync;

  void setOfflineMode(bool offline) {
    _isOffline = offline;
    if (!offline) {
      _hasPendingSync = false;
    }
    notifyListeners();
  }

  Map<String, CartItem> get items => {..._items};

  List<CartItem> get itemList => _items.values.toList();

  int get totalItemsCount {
    int total = 0;
    _items.forEach((key, item) {
      total += item.quantity;
    });
    return total;
  }

  double get subtotal {
    double total = 0.0;
    _items.forEach((key, item) {
      total += item.totalPrice;
    });
    return total;
  }

  double get shippingFee => _items.isEmpty ? 0.0 : 50.0;

  double get grandTotal => subtotal + shippingFee;

  int get selectedItemsCount {
    int count = 0;
    for (final item in _items.values) {
      if (item.isSelected) {
        count += item.quantity;
      }
    }
    return count;
  }

  double get selectedSubtotal {
    double total = 0.0;
    for (final item in _items.values) {
      if (item.isSelected) {
        total += item.totalPrice;
      }
    }
    return total;
  }

  double get selectedShippingFee => selectedItemsCount == 0 ? 0.0 : 50.0;

  double get selectedGrandTotal => selectedSubtotal + selectedShippingFee;

  bool get isAllSelected => _items.isNotEmpty && _items.values.every((i) => i.isSelected);

  List<CartItem> get selectedItemList => _items.values.where((i) => i.isSelected).toList();

  bool isInCart(String productId) =>
      _items.values.any((i) => i.product.id == productId);

  int getQuantity(String productId) {
    int count = 0;
    for (final it in _items.values) {
      if (it.product.id == productId) count += it.quantity;
    }
    return count;
  }

  String? _activeUserEmail;

  CartProvider() {
    _loadCartFromPrefs();
  }

  /// Automatically reloads or clears the in-memory cart when the authenticated user changes (`BUY-CART-008`).
  void syncWithAuth(String? userEmail) {
    final normalized = userEmail?.trim().toLowerCase();
    if (_activeUserEmail == normalized) return;
    _activeUserEmail = normalized;
    _loadCartFromPrefs();
  }

  String _userScopedCartKey(String? userJson) {
    if (userJson == null || userJson.isEmpty) return _cartPrefKey;
    try {
      final decoded = jsonDecode(userJson);
      if (decoded is Map) {
        final email = (decoded['email'] ?? '').toString().trim().toLowerCase();
        if (email.isNotEmpty) {
          return '${_cartPrefKey}_$email';
        }
      }
    } catch (_) {}
    return _cartPrefKey;
  }

  /// Reloads the cart for the currently logged-in user (`BUY-CART-008`).
  Future<void> reloadCartForCurrentUser() => _loadCartFromPrefs();

  Future<void> _loadCartFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // If user is guest (not logged in), clear in-memory cart but keep per-user saved cart in storage
      final userJson = prefs.getString('lumora_auth_user');
      if (userJson == null) {
        _items.clear();
        notifyListeners();
        return;
      }

      final scopedKey = _userScopedCartKey(userJson);
      final cartJson = prefs.getString(scopedKey) ?? prefs.getString(_cartPrefKey);
      if (cartJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(cartJson);
        final allProducts = [...MockData.flashDeals, ...MockData.allProducts];
        final productMap = {for (var p in allProducts) p.id: p};

        _items.clear();
        decoded.forEach((key, val) {
          String prodId = key;
          if (val is Map && val['productId'] != null) {
            prodId = val['productId'] as String;
          } else if (key.contains('_')) {
            prodId = key.split('_').first;
          }

          if (productMap.containsKey(prodId)) {
            final prod = productMap[prodId]!;
            if (val is int && val > 0) {
              final it = CartItem(
                product: prod,
                quantity: val.clamp(1, maxPerBuyerLimit),
              );
              _items[it.itemKey] = it;
            } else if (val is Map) {
              final qty = (val['quantity'] as num?)?.toInt() ?? 1;
              if (qty > 0) {
                final it = CartItem(
                  product: prod,
                  quantity: qty.clamp(1, maxPerBuyerLimit),
                  selectedColor: val['selectedColor'] as String?,
                  selectedSizeOrOption: val['selectedSizeOrOption'] as String?,
                  isSelected: val['isSelected'] as bool? ?? true,
                );
                _items[it.itemKey] = it;
              }
            }
          }
        });
        notifyListeners();
      } else {
        _items.clear();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveCartToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('lumora_auth_user');
      final scopedKey = _userScopedCartKey(userJson);
      final cartMap = <String, dynamic>{};
      _items.forEach((key, item) {
        cartMap[item.itemKey] = {
          'productId': item.product.id,
          'quantity': item.quantity,
          'selectedColor': item.selectedColor,
          'selectedSizeOrOption': item.selectedSizeOrOption,
          'isSelected': item.isSelected,
        };
      });
      final encoded = jsonEncode(cartMap);
      await prefs.setString(_cartPrefKey, encoded);
      if (scopedKey != _cartPrefKey) {
        await prefs.setString(scopedKey, encoded);
      }
    } catch (_) {}
  }

  bool addToCart(
    Product product, {
    int quantity = 1,
    String? selectedColor,
    String? selectedSizeOrOption,
  }) {
    final chosenColor = selectedColor ?? product.defaultColorName;
    final chosenOption = selectedSizeOrOption ?? product.defaultSecondaryOption;
    final variantStock = product.stockForVariant(
      color: chosenColor,
      secondaryOption: chosenOption,
    );
    if (variantStock <= 0) return false;
    final maxStock = variantStock.clamp(1, maxPerBuyerLimit);
    final itemKey = '${product.id}_${chosenColor}_$chosenOption';

    if (_items.containsKey(itemKey)) {
      final existing = _items[itemKey]!;
      if (existing.quantity + quantity > maxStock) {
        existing.quantity = maxStock;
        _saveCartToPrefs();
        notifyListeners();
        return false;
      }
      existing.quantity = (existing.quantity + quantity).clamp(1, maxStock);
    } else {
      final exceeded = quantity > maxStock;
      final it = CartItem(
        product: product,
        quantity: quantity.clamp(1, maxStock),
        selectedColor: chosenColor,
        selectedSizeOrOption: chosenOption,
      );
      _items[itemKey] = it;
      if (exceeded) {
        _saveCartToPrefs();
        notifyListeners();
        return false;
      }
    }
    _saveCartToPrefs();
    notifyListeners();
    return true;
  }

  void updateVariation(
    String keyOrProductId, {
    String? selectedColor,
    String? selectedSizeOrOption,
  }) {
    final entry = _findItemEntry(keyOrProductId);
    if (entry == null) return;
    final item = entry.value;
    final oldKey = entry.key;

    if (selectedColor != null && selectedColor.isNotEmpty) {
      item.selectedColor = selectedColor;
    }
    if (selectedSizeOrOption != null && selectedSizeOrOption.isNotEmpty) {
      item.selectedSizeOrOption = selectedSizeOrOption;
    }

    _items.remove(oldKey);
    final newKey = item.itemKey;
    if (_items.containsKey(newKey)) {
      final existing = _items[newKey]!;
      final maxStock = item.product.stock > 0
          ? item.product.stock.clamp(1, maxPerBuyerLimit)
          : maxPerBuyerLimit;
      existing.quantity = (existing.quantity + item.quantity).clamp(1, maxStock);
      existing.isSelected = existing.isSelected || item.isSelected;
    } else {
      _items[newKey] = item;
    }
    _saveCartToPrefs();
    notifyListeners();
  }

  void updateQuantity(String keyOrProductId, int delta) {
    if (_isOffline) {
      _hasPendingSync = true;
    }
    final entry = _findItemEntry(keyOrProductId);
    if (entry == null) return;

    final key = entry.key;
    final item = entry.value;
    final maxStock = item.product.stock > 0
        ? item.product.stock.clamp(1, maxPerBuyerLimit)
        : maxPerBuyerLimit;
    final currentQty = item.quantity;
    final newQty = currentQty + delta;

    if (newQty <= 0) {
      _items.remove(key);
    } else {
      item.quantity = newQty.clamp(1, maxStock);
    }
    _saveCartToPrefs();
    notifyListeners();
  }

  void setQuantity(String keyOrProductId, int quantity) {
    if (_isOffline) {
      _hasPendingSync = true;
    }
    final entry = _findItemEntry(keyOrProductId);
    if (entry == null) return;

    final key = entry.key;
    final item = entry.value;
    final maxStock = item.product.stock > 0
        ? item.product.stock.clamp(1, maxPerBuyerLimit)
        : maxPerBuyerLimit;
    if (quantity <= 0) {
      _items.remove(key);
    } else {
      item.quantity = quantity.clamp(1, maxStock);
    }
    _saveCartToPrefs();
    notifyListeners();
  }

  void toggleItemSelection(String keyOrProductId) {
    final entry = _findItemEntry(keyOrProductId);
    if (entry != null) {
      entry.value.isSelected = !entry.value.isSelected;
      _saveCartToPrefs();
      notifyListeners();
    }
  }

  void setItemSelection(String keyOrProductId, bool isSelected) {
    final entry = _findItemEntry(keyOrProductId);
    if (entry != null) {
      entry.value.isSelected = isSelected;
      _saveCartToPrefs();
      notifyListeners();
    }
  }

  void setAllSelected(bool isSelected) {
    for (final item in _items.values) {
      item.isSelected = isSelected;
    }
    _saveCartToPrefs();
    notifyListeners();
  }

  void removeFromCart(String keyOrProductId) {
    final entry = _findItemEntry(keyOrProductId);
    if (entry != null) {
      _items.remove(entry.key);
      _saveCartToPrefs();
      notifyListeners();
    }
  }

  MapEntry<String, CartItem>? _findItemEntry(String keyOrProductId) {
    if (_items.containsKey(keyOrProductId)) {
      return MapEntry(keyOrProductId, _items[keyOrProductId]!);
    }
    for (final e in _items.entries) {
      if (e.value.product.id == keyOrProductId || e.value.itemKey == keyOrProductId) {
        return e;
      }
    }
    return null;
  }

  void clearCart() {
    _items.clear();
    _saveCartToPrefs();
    notifyListeners();
  }

  void removeSelectedItems() {
    _items.removeWhere((_, item) => item.isSelected);
    _saveCartToPrefs();
    notifyListeners();
  }
}
