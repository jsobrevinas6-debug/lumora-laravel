import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class WalletProvider extends ChangeNotifier {
  static const String _prefsKey = 'lumora_wallet_payment_methods';

  final List<SavedPaymentMethod> _methods = [];

  WalletProvider() {
    _loadFromPrefs();
  }

  List<SavedPaymentMethod> get methods => List.unmodifiable(_methods);

  SavedPaymentMethod? get defaultMethod {
    try {
      return _methods.firstWhere((m) => m.isDefault);
    } catch (_) {
      return _methods.isNotEmpty ? _methods.first : null;
    }
  }

  Future<void> addMethod({
    required String type, // 'gcash', 'maya', 'bank'
    required String name, // 'GCash', 'Maya', 'BDO Unibank', etc.
    required String accountName,
    required String accountNumber,
    bool isDefault = false,
  }) async {
    final shouldBeDefault = isDefault || _methods.isEmpty;

    if (shouldBeDefault) {
      for (int i = 0; i < _methods.length; i++) {
        _methods[i] = SavedPaymentMethod(
          id: _methods[i].id,
          type: _methods[i].type,
          name: _methods[i].name,
          accountName: _methods[i].accountName,
          accountNumber: _methods[i].accountNumber,
          isDefault: false,
        );
      }
    }

    final newMethod = SavedPaymentMethod(
      id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      name: name,
      accountName: accountName.trim(),
      accountNumber: accountNumber.trim(),
      isDefault: shouldBeDefault,
    );

    _methods.insert(0, newMethod);
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> setDefault(String id) async {
    for (int i = 0; i < _methods.length; i++) {
      _methods[i] = SavedPaymentMethod(
        id: _methods[i].id,
        type: _methods[i].type,
        name: _methods[i].name,
        accountName: _methods[i].accountName,
        accountNumber: _methods[i].accountNumber,
        isDefault: _methods[i].id == id,
      );
    }
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> removeMethod(String id) async {
    final wasDefault = _methods.any((m) => m.id == id && m.isDefault);
    _methods.removeWhere((m) => m.id == id);
    if (wasDefault && _methods.isNotEmpty) {
      _methods[0] = SavedPaymentMethod(
        id: _methods[0].id,
        type: _methods[0].type,
        name: _methods[0].name,
        accountName: _methods[0].accountName,
        accountNumber: _methods[0].accountNumber,
        isDefault: true,
      );
    }
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> list = json.decode(jsonString);
        _methods.clear();
        for (final item in list) {
          final m = item as Map<String, dynamic>;
          _methods.add(SavedPaymentMethod(
            id: m['id'] ?? 'pay_1',
            type: m['type'] ?? 'gcash',
            name: m['name'] ?? 'GCash',
            accountName: m['accountName'] ?? 'Valued Member',
            accountNumber: m['accountNumber'] ?? '0917 888 9999',
            isDefault: m['isDefault'] ?? false,
          ));
        }
        notifyListeners();
      } else {
        notifyListeners();
      }

    } catch (e) {
      debugPrint('WalletProvider._loadFromPrefs error: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _methods
          .map((m) => {
                'id': m.id,
                'type': m.type,
                'name': m.name,
                'accountName': m.accountName,
                'accountNumber': m.accountNumber,
                'isDefault': m.isDefault,
              })
          .toList();
      await prefs.setString(_prefsKey, json.encode(list));
    } catch (e) {
      debugPrint('WalletProvider._saveToPrefs error: $e');
    }
  }
}
