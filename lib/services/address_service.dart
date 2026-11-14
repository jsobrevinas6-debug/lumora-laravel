import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AddressItem {
  final String code;
  final String name;

  const AddressItem({required this.code, required this.name});

  /// Fix double-encoded UTF-8 (mojibake) from PSGC API.
  /// e.g. "City of BiÃ±an" → "City of Biñan", "Los BaÃ±os" → "Los Baños"
  static String _fixMojibake(String input) {
    // Quick check: if no high-byte Latin-1 characters exist, nothing to fix
    if (!input.codeUnits.any((c) => c >= 0xC0 && c <= 0xFF)) return input;
    try {
      final latin1Bytes = latin1.encode(input);
      final fixed = utf8.decode(latin1Bytes);
      // Only use the fixed version if decoding actually changed something
      if (fixed != input) return fixed;
    } catch (_) {
      // Not a valid double-encoded string, return as-is
    }
    return input;
  }

  factory AddressItem.fromJson(Map<String, dynamic> json) {
    return AddressItem(
      code: (json['code'] ?? json['id'] ?? '').toString(),
      name: _fixMojibake((json['name'] ?? '').toString().trim()),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressItem && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => name;
}

class AddressService {
  static final AddressService _instance = AddressService._internal();
  factory AddressService() => _instance;
  AddressService._internal();

  static const String _primaryBase = 'https://lumora.party/address';
  static const String _psgcBase = 'https://psgc.cloud/api/v2';
  static const Duration _timeout = Duration(seconds: 12);

  // In-memory caches for instant responsiveness
  List<AddressItem>? _cachedProvinces;
  final Map<String, List<AddressItem>> _cachedMunicipalities = {};
  final Map<String, List<AddressItem>> _cachedBarangays = {};

  /// 1. Fetch all Philippine Provinces
  Future<List<AddressItem>> getProvinces() async {
    if (_cachedProvinces != null && _cachedProvinces!.isNotEmpty) {
      return _cachedProvinces!;
    }

    try {
      final res = await _fetchJson('$_primaryBase/provinces', fallbackUrl: '$_psgcBase/provinces');
      if (res.isNotEmpty) {
        final list = res.map((e) => AddressItem.fromJson(e)).toList();
        list.sort((a, b) => a.name.compareTo(b.name));
        _cachedProvinces = list;
        return list;
      }
    } catch (e) {
      debugPrint('AddressService.getProvinces error: $e');
    }

    // Fallback static provinces if offline
    return _fallbackProvinces;
  }

  /// 2. Fetch Municipalities / Cities for a province
  Future<List<AddressItem>> getMunicipalities(String provinceCode) async {
    if (_cachedMunicipalities.containsKey(provinceCode)) {
      return _cachedMunicipalities[provinceCode]!;
    }

    try {
      final res = await _fetchJson(
        '$_primaryBase/provinces/$provinceCode/municipalities',
        fallbackUrl: '$_psgcBase/provinces/$provinceCode/cities-municipalities',
      );
      if (res.isNotEmpty) {
        final list = res.map((e) => AddressItem.fromJson(e)).toList();
        list.sort((a, b) => a.name.compareTo(b.name));
        _cachedMunicipalities[provinceCode] = list;
        return list;
      }
    } catch (e) {
      debugPrint('AddressService.getMunicipalities error: $e');
    }

    return _fallbackMunicipalities(provinceCode);
  }

  /// 3. Fetch Barangays for a municipality / city
  Future<List<AddressItem>> getBarangays(String municipalityCode) async {
    if (_cachedBarangays.containsKey(municipalityCode)) {
      return _cachedBarangays[municipalityCode]!;
    }

    try {
      final res = await _fetchJson(
        '$_primaryBase/municipalities/$municipalityCode/barangays',
        fallbackUrl: '$_psgcBase/cities-municipalities/$municipalityCode/barangays',
      );
      if (res.isNotEmpty) {
        final list = res.map((e) => AddressItem.fromJson(e)).toList();
        list.sort((a, b) => a.name.compareTo(b.name));
        _cachedBarangays[municipalityCode] = list;
        return list;
      }
    } catch (e) {
      debugPrint('AddressService.getBarangays error: $e');
    }

    return _fallbackBarangays;
  }

  /// Helper to fetch JSON from primary URL with secondary fallback
  Future<List<Map<String, dynamic>>> _fetchJson(String primaryUrl, {String? fallbackUrl}) async {
    try {
      final response = await http.get(Uri.parse(primaryUrl), headers: {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Lumora-Mobile)',
      }).timeout(_timeout);

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is Map && decoded.containsKey('data') && decoded['data'] is List) {
          return List<Map<String, dynamic>>.from(decoded['data']);
        } else if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }
      }
    } catch (_) {}

    if (fallbackUrl != null) {
      try {
        final response = await http.get(Uri.parse(fallbackUrl), headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Lumora-Mobile)',
        }).timeout(_timeout);

        if (response.statusCode == 200) {
          final dynamic decoded = json.decode(utf8.decode(response.bodyBytes));
          if (decoded is Map && decoded.containsKey('data') && decoded['data'] is List) {
            return List<Map<String, dynamic>>.from(decoded['data']);
          } else if (decoded is List) {
            return List<Map<String, dynamic>>.from(decoded);
          }
        }
      } catch (_) {}
    }

    return [];
  }

  static const List<AddressItem> _fallbackProvinces = [
    AddressItem(code: '0403400000', name: 'Laguna'),
    AddressItem(code: '1300000000', name: 'Metro Manila'),
    AddressItem(code: '0402100000', name: 'Cavite'),
    AddressItem(code: '0401000000', name: 'Batangas'),
    AddressItem(code: '0405800000', name: 'Rizal'),
    AddressItem(code: '0702200000', name: 'Cebu'),
    AddressItem(code: '1102400000', name: 'Davao del Sur'),
    AddressItem(code: '0102800000', name: 'Ilocos Norte'),
    AddressItem(code: '0301400000', name: 'Bulacan'),
    AddressItem(code: '0305400000', name: 'Pampanga'),
  ];

  List<AddressItem> _fallbackMunicipalities(String provCode) {
    return const [
      AddressItem(code: '0403417000', name: 'Nagcarlan'),
      AddressItem(code: '0403419000', name: 'Pagsanjan'),
      AddressItem(code: '0403426000', name: 'Santa Cruz'),
      AddressItem(code: '0403405000', name: 'Calamba'),
      AddressItem(code: '0403404000', name: 'Cabuyao'),
      AddressItem(code: '0403403000', name: 'Biñan'),
      AddressItem(code: '0403425000', name: 'San Pedro'),
      AddressItem(code: '0403411000', name: 'Los Baños'),
    ];
  }

  static const List<AddressItem> _fallbackBarangays = [
    AddressItem(code: 'brgy_1', name: 'Poblacion'),
    AddressItem(code: 'brgy_2', name: 'Ilaya'),
    AddressItem(code: 'brgy_3', name: 'Abo'),
    AddressItem(code: 'brgy_4', name: 'Alibungbungan'),
    AddressItem(code: 'brgy_5', name: 'Balayong'),
    AddressItem(code: 'brgy_6', name: 'Bambang'),
    AddressItem(code: 'brgy_7', name: 'Buboy'),
    AddressItem(code: 'brgy_8', name: 'Buenavista'),
  ];
}
