import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class FollowProvider extends ChangeNotifier {
  static const String _basePrefsKey = 'lumora_followed_shops_v2';
  String? _currentUserKey;

  final Map<String, ShopItem> _followedShops = {};

  FollowProvider() {
    _loadFromPrefs();
  }

  String get _prefsKey => (_currentUserKey != null && _currentUserKey!.isNotEmpty)
      ? '${_basePrefsKey}_$_currentUserKey'
      : '${_basePrefsKey}_guest';

  Future<void> syncWithAuth(String? userEmail) async {
    final normalized = userEmail?.trim().toLowerCase();
    if (_currentUserKey == normalized) return;
    _currentUserKey = normalized;
    await _loadFromPrefs();
  }

  List<ShopItem> get followedShops => _followedShops.values.toList();
  int get followedCount => _followedShops.length;

  bool isFollowing(String shopIdOrName) {
    if (_followedShops.containsKey(shopIdOrName)) return true;
    final norm = shopIdOrName.trim().toLowerCase();
    return _followedShops.values.any(
      (s) => s.id.toLowerCase() == norm || s.name.trim().toLowerCase() == norm,
    );
  }

  Future<bool> toggleFollow(ShopItem shop) async {
    final normName = shop.name.trim().toLowerCase();
    String? existingKey;
    for (final entry in _followedShops.entries) {
      if (entry.key == shop.id || entry.value.name.trim().toLowerCase() == normName) {
        existingKey = entry.key;
        break;
      }
    }
    final nowFollowing = existingKey == null;
    if (nowFollowing) {
      _followedShops[shop.id] = shop;
    } else {
      _followedShops.remove(existingKey);
    }
    notifyListeners();
    await _saveToPrefs();
    return nowFollowing;
  }

  Future<void> unfollow(String shopId) async {
    if (_followedShops.containsKey(shopId)) {
      _followedShops.remove(shopId);
      notifyListeners();
      await _saveToPrefs();
    }
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      _followedShops.clear();
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> list = json.decode(jsonString);
        for (final item in list) {
          final shop = ShopItem.fromJson(item as Map<String, dynamic>);
          _followedShops[shop.id] = shop;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('FollowProvider._loadFromPrefs error: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _followedShops.values.map((s) => s.toJson()).toList();
      await prefs.setString(_prefsKey, json.encode(list));
    } catch (e) {
      debugPrint('FollowProvider._saveToPrefs error: $e');
    }
  }
}
