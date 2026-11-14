import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Configuration for Lumora Backend API & MySQL Connection
class ApiConfig {
  /// Toggle this to `true` when running your PHP / Laravel backend server
  static bool useLiveApi = true;

  /// Default local development URL
  /// For Android Emulator: 'http://10.0.2.2:8000/api'
  /// For Real Physical Device: 'http://192.168.x.x:8000/api' (your computer's Wi-Fi IP)
  /// For Production: 'https://lumora.party/api'
  static String baseUrl = 'https://lumora.party/api';

  /// Live Lumora Logistics System URL (lumora-logistics branch)
  static String logisticsBaseUrl = 'https://logistics.lumora.party';

  static const Duration timeout = Duration(seconds: 10);

  static const String _keyUseLiveApi = 'lumora_use_live_api';
  static const String _keyBaseUrl = 'lumora_api_base_url';

  /// Load persisted configuration from SharedPreferences
  static Future<void> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_keyUseLiveApi)) {
        useLiveApi = prefs.getBool(_keyUseLiveApi) ?? true;
      } else {
        useLiveApi = true;
      }
      if (prefs.containsKey(_keyBaseUrl)) {
        baseUrl = prefs.getString(_keyBaseUrl) ?? baseUrl;
      }
    } catch (e) {
      debugPrint('ApiConfig.loadConfig error: $e');
    }
  }

  /// Save configuration dynamically to SharedPreferences
  static Future<void> saveConfig({required bool live, required String url}) async {
    useLiveApi = live;
    baseUrl = url;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyUseLiveApi, live);
      await prefs.setString(_keyBaseUrl, url);
    } catch (e) {
      debugPrint('ApiConfig.saveConfig error: $e');
    }
  }
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Headers helper
  Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Async headers helper that includes both Bearer token and current buyer identity headers
  Future<Map<String, String>> _buyerHeaders({String? token, bool jsonContent = true}) async {
    final headers = <String, String>{
      if (jsonContent) 'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      final tok = (token != null && token.isNotEmpty)
          ? token
          : prefs.getString('lumora_auth_token');
      if (tok != null && tok.isNotEmpty) {
        headers['Authorization'] = 'Bearer $tok';
      }
      final userJson = prefs.getString('lumora_auth_user') ?? prefs.getString('lumora_current_user_v1');
      if (userJson != null && userJson.isNotEmpty) {
        final decoded = jsonDecode(userJson);
        if (decoded is Map<String, dynamic>) {
          final uid = (decoded['id'] ?? '').toString().trim();
          final email = (decoded['email'] ?? '').toString().trim();
          final name = (decoded['fullName'] ?? decoded['name'] ?? '').toString().trim();
          if (uid.isNotEmpty) headers['X-User-Id'] = uid;
          if (email.isNotEmpty) headers['X-User-Email'] = email;
          if (name.isNotEmpty) headers['X-User-Name'] = name;
        }
      }
    } catch (_) {}
    return headers;
  }

  /// Stored token helper
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('lumora_auth_token');
    } catch (_) {
      return null;
    }
  }

  /// 1. Health Check
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/health'))
          .timeout(ApiConfig.timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.checkHealth error: $e');
      return false;
    }
  }

  /// 2. Fetch Products from MySQL
  Future<List<Product>> fetchProducts({String? category, bool? isFlashDeal}) async {
    try {
      final queryParams = <String, String>{};
      if (category != null && category.toLowerCase() != 'all') {
        queryParams['category'] = category;
      }
      if (isFlashDeal == true) {
        queryParams['flash_deals'] = '1';
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/products').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers()).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List list = decoded['data'] ?? [];
        return list.map((item) => _mapJsonToProduct(item)).toList();
      }
    } catch (e) {
      debugPrint('ApiService.fetchProducts error: $e');
    }
    return [];
  }

  /// 3. User Login
  Future<({bool success, Map<String, dynamic>? data, String? message})> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/login'),
            headers: _headers(),
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(ApiConfig.timeout);

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
        return (success: true, data: decoded, message: null);
      } else if (decoded is Map<String, dynamic> && decoded['message'] != null) {
        return (success: false, data: null, message: decoded['message'].toString());
      }
    } catch (e) {
      debugPrint('ApiService.login error: $e');
      return (success: false, data: null, message: 'Could not connect to server.');
    }
    return (success: false, data: null, message: 'Invalid credentials.');
  }

  /// 4. User Registration
  Future<({bool success, Map<String, dynamic>? data, String? message})> register(
    String fullName,
    String email,
    String password, {
    Map<String, dynamic>? extra,
  }) async {
    try {
      final cleanExtra = Map<String, dynamic>.from(extra ?? {});
      final rawIdPhoto = cleanExtra.remove('valid_id_photo')?.toString();
      final validIdType = (cleanExtra['valid_id_type'] ?? cleanExtra['id_type'])?.toString();

      Uint8List? idBytes;
      String idFilename = 'valid_id.jpg';
      String idMimeSubType = 'jpeg';

      if (rawIdPhoto != null && rawIdPhoto.isNotEmpty) {
        try {
          final b64 = rawIdPhoto.contains(',') ? rawIdPhoto.split(',').last : rawIdPhoto;
          final decodedBytes = base64Decode(b64.replaceAll(RegExp(r'\s+'), ''));

          final isJpeg = decodedBytes.length >= 3 &&
              decodedBytes[0] == 0xFF &&
              decodedBytes[1] == 0xD8 &&
              decodedBytes[2] == 0xFF;
          final isPng = decodedBytes.length >= 4 &&
              decodedBytes[0] == 0x89 &&
              decodedBytes[1] == 0x50 &&
              decodedBytes[2] == 0x4E &&
              decodedBytes[3] == 0x47;

          if (isPng) {
            idBytes = decodedBytes;
            idFilename = 'valid_id.png';
            idMimeSubType = 'png';
          } else if (isJpeg) {
            idBytes = decodedBytes;
            idFilename = 'valid_id.jpg';
            idMimeSubType = 'jpeg';
          } else {
            // Convert WebP/BMP/other formats to PNG so Laravel's mimes:jpg,jpeg,png,pdf always passes
            try {
              final codec = await ui.instantiateImageCodec(decodedBytes, targetWidth: 1024);
              final frame = await codec.getNextFrame();
              final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
              if (byteData != null) {
                idBytes = byteData.buffer.asUint8List();
                idFilename = 'valid_id.png';
                idMimeSubType = 'png';
              } else {
                idBytes = decodedBytes;
              }
            } catch (_) {
              idBytes = decodedBytes;
            }
          }
        } catch (e) {
          debugPrint('ApiService.register decode ID photo error: $e');
        }
      }

      http.Response response;
      final registerUri = Uri.parse('${ApiConfig.baseUrl}/auth/register');

      if (idBytes != null && idBytes.isNotEmpty) {
        final request = http.MultipartRequest('POST', registerUri);
        request.headers['Accept'] = 'application/json';
        request.fields['full_name'] = fullName;
        request.fields['email'] = email;
        request.fields['password'] = password;
        request.fields['password_confirmation'] = password;
        if (validIdType != null && validIdType.trim().isNotEmpty) {
          request.fields['id_type'] = validIdType.trim();
          request.fields['valid_id_type'] = validIdType.trim();
        }
        for (final entry in cleanExtra.entries) {
          final val = entry.value;
          if (val != null && val.toString().trim().isNotEmpty) {
            request.fields[entry.key] = val.toString().trim();
          }
        }
        request.files.add(
          http.MultipartFile.fromBytes(
            'buyer_id_document',
            idBytes,
            filename: idFilename,
            contentType: MediaType('image', idMimeSubType),
          ),
        );
        final streamed = await request.send().timeout(const Duration(seconds: 25));
        response = await http.Response.fromStream(streamed);
      } else {
        response = await http
            .post(
              registerUri,
              headers: _headers(),
              body: jsonEncode({
                'full_name': fullName,
                'email': email,
                'password': password,
                'password_confirmation': password,
                if (validIdType != null && validIdType.trim().isNotEmpty) 'id_type': validIdType.trim(),
                ...cleanExtra,
              }),
            )
            .timeout(ApiConfig.timeout);
      }

      final decoded = jsonDecode(response.body);
      if ((response.statusCode == 200 ||
              response.statusCode == 201 ||
              response.statusCode == 202) &&
          decoded is Map<String, dynamic>) {
        return (success: true, data: decoded, message: decoded['message']?.toString());
      } else if (decoded is Map<String, dynamic> && decoded['message'] != null) {
        return (success: false, data: null, message: decoded['message'].toString());
      }
    } catch (e) {
      debugPrint('ApiService.register error: $e');
      return (success: false, data: null, message: 'Could not connect to server.');
    }
    return (success: false, data: null, message: 'Registration failed.');
  }

  /// 4b. Google OAuth Sign-In / Auto-Provision in MySQL Database
  Future<({bool success, Map<String, dynamic>? data, String? message})> googleAuth({
    required String fullName,
    required String email,
    required String googleId,
    String? avatar,
  }) async {
    try {
      // 1. Try dedicated /auth/google endpoint first
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/google'),
            headers: _headers(),
            body: jsonEncode({
              'full_name': fullName,
              'name': fullName,
              'email': email,
              'google_id': googleId,
              'avatar': avatar,
              'provider': 'google',
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return (success: true, data: decoded, message: null);
        }
      }
    } catch (_) {}

    // 2. Fallback: Auto-sync with standard /auth/login or /auth/register so Google accounts are stored in MySQL
    final oauthSecret = 'GAuth#${email.toLowerCase().hashCode.abs()}!Lm9';
    final loginRes = await login(email, oauthSecret);
    if (loginRes.success && loginRes.data != null) {
      return loginRes;
    }

    final parts = fullName.trim().split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : fullName;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : 'Buyer';

    final regRes = await register(
      fullName,
      email,
      oauthSecret,
      extra: {
        'first_name': firstName,
        'last_name': lastName,
        'google_id': googleId,
        'provider': 'google',
        'avatar': avatar,
      },
    );
    return regRes;
  }

  /// 5. Place Order in MySQL / Laravel Backend
  Future<({bool success, Map<String, dynamic>? data, String? message})> createOrder({
    required String userId,
    required double subtotal,
    required double shippingFee,
    required double discountAmount,
    required double totalAmount,
    required String paymentMethod,
    required String shippingAddress,
    required List<Map<String, dynamic>> items,
    String? noteToSeller,
    String? voucherCode,
    String? paymentProofPath,
    String? paymentReferenceLast6,
    String? paymentStatus,
    String? token,
  }) async {
    try {
      final tok = token ?? await _getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/orders');

      // The API only accepts the lowercase codes: cod, gcash, maya.
      final pmLower = paymentMethod.toLowerCase();
      if (pmLower.contains('gcash')) {
        paymentMethod = 'gcash';
      } else if (pmLower.contains('maya') || pmLower.contains('paymaya')) {
        paymentMethod = 'maya';
      } else {
        paymentMethod = 'cod';
      }

      List<int>? receiptBytes;
      String receiptExt = 'jpg';
      if (paymentProofPath != null && paymentProofPath.startsWith('data:image')) {
        try {
          receiptBytes = base64Decode(paymentProofPath.split(',').last);
          if (receiptBytes.length >= 4 &&
              receiptBytes[0] == 0x89 &&
              receiptBytes[1] == 0x50 &&
              receiptBytes[2] == 0x4E &&
              receiptBytes[3] == 0x47) {
            receiptExt = 'png';
          } else if (receiptBytes.length >= 4 &&
              receiptBytes[0] == 0x52 &&
              receiptBytes[1] == 0x49 &&
              receiptBytes[2] == 0x46 &&
              receiptBytes[3] == 0x46) {
            receiptExt = 'webp';
          }
        } catch (e) {
          debugPrint('Receipt decode error: $e');
        }
      } else if (paymentProofPath != null &&
          paymentProofPath.isNotEmpty &&
          File(paymentProofPath).existsSync()) {
        try {
          receiptBytes = await File(paymentProofPath).readAsBytes();
        } catch (_) {}
      }

      if (receiptBytes != null && receiptBytes.isNotEmpty) {
        try {
          final request = http.MultipartRequest('POST', uri);
          request.headers.addAll(await _buyerHeaders(token: tok, jsonContent: false));

          request.fields['payment_method'] = paymentMethod;
          request.fields['shipping_address'] = shippingAddress;
          if (noteToSeller != null && noteToSeller.isNotEmpty) {
            request.fields['note_to_seller'] = noteToSeller;
          }
          if (voucherCode != null && voucherCode.isNotEmpty) {
            request.fields['voucher_code'] = voucherCode;
          }
          if (paymentReferenceLast6 != null && paymentReferenceLast6.isNotEmpty) {
            request.fields['payment_reference_last6'] = paymentReferenceLast6;
          }
          for (var i = 0; i < items.length; i++) {
            final item = items[i];
            item.forEach((key, value) {
              if (value != null && value is! Map && value is! List) {
                request.fields['items[$i][$key]'] = value.toString();
              }
            });
          }

          request.files.add(http.MultipartFile.fromBytes(
            'payment_proof',
            receiptBytes,
            filename: 'receipt.$receiptExt',
          ));

          final streamed = await request.send().timeout(const Duration(seconds: 25));
          final response = await http.Response.fromStream(streamed);

          Map<String, dynamic> decoded = {};
          try {
            decoded = jsonDecode(response.body) as Map<String, dynamic>;
          } catch (_) {}

          if (response.statusCode == 200 || response.statusCode == 201) {
            return (
              success: true,
              data: decoded,
              message: decoded['message']?.toString() ?? 'Order placed successfully.',
            );
          }
        } catch (e) {
          debugPrint('Multipart createOrder fallback to JSON: $e');
        }
      }

      // JSON post (used for COD or as fallback if multipart upload is rejected)
      final response = await http
          .post(
            uri,
            headers: await _buyerHeaders(token: tok),
            body: jsonEncode({
              'payment_method': paymentMethod,
              'shipping_address': shippingAddress,
              if (noteToSeller != null && noteToSeller.isNotEmpty) 'note_to_seller': noteToSeller,
              if (voucherCode != null && voucherCode.isNotEmpty) 'voucher_code': voucherCode,
              if (paymentReferenceLast6 != null && paymentReferenceLast6.isNotEmpty)
                'payment_reference_last6': paymentReferenceLast6,
              'payment_status': paymentStatus ?? 'pending',
              'items': items,
            }),
          )
          .timeout(ApiConfig.timeout);

      Map<String, dynamic> decoded = {};
      try {
        decoded = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      if (response.statusCode == 200 || response.statusCode == 201) {
        return (
          success: true,
          data: decoded,
          message: decoded['message']?.toString() ?? 'Order placed successfully.',
        );
      } else {
        return (
          success: false,
          data: decoded,
          message: decoded['message']?.toString() ?? 'Failed to place order.',
        );
      }
    } catch (e) {
      debugPrint('ApiService.createOrder error: $e');
      return (success: false, data: null, message: 'Network error: $e');
    }
  }

  /// 6. Fetch Buyer Orders (Web Parity: Buyer/OrderController@index + Lumora Logistics Sync)
  Future<List<OrderModel>> fetchBuyerOrders({String? token}) async {
    try {
      final tok = token ?? await _getToken();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/buyer/orders'),
            headers: await _buyerHeaders(token: tok),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List list = decoded['data'] ?? decoded['orders'] ?? [];
        final parsed = list.map((item) => OrderModel.fromJson(item as Map<String, dynamic>)).toList();
        return await enrichOrdersWithLogistics(parsed);
      }
    } catch (e) {
      debugPrint('ApiService.fetchBuyerOrders error: $e');
    }
    return [];
  }

  /// 6b. Fetch Live Order Tracking Details (Web Parity: Buyer/OrderController@track + Lumora Logistics Sync)
  Future<OrderModel?> fetchOrderTracking({
    required String orderId,
    String? token,
  }) async {
    OrderModel? baseOrder;
    try {
      final tok = token ?? await _getToken();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/buyer/orders/$orderId/track'),
            headers: await _buyerHeaders(token: tok),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'] ?? decoded['order'];
        if (data is Map<String, dynamic>) {
          baseOrder = OrderModel.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('ApiService.fetchOrderTracking error: $e');
    }

    if (baseOrder != null) {
      return await enrichOrderWithLogistics(baseOrder);
    }
    return null;
  }

  /// Extracts numeric order ID (e.g. "24" from "LMR-2026-000024") for Logistics barcode lookup
  static String? _extractNumericOrderId(String rawId) {
    final trimmed = rawId.trim();
    if (RegExp(r'^\d+$').hasMatch(trimmed)) return trimmed;
    final lmrMatch = RegExp(r'^(?:LMR-\d{4}-0*|ORD-0*)(\d+)$', caseSensitive: false).firstMatch(trimmed);
    if (lmrMatch != null) return lmrMatch.group(1);
    return null;
  }

  /// Enriches a list of orders in parallel with live parcel state from https://logistics.lumora.party
  Future<List<OrderModel>> enrichOrdersWithLogistics(List<OrderModel> orders) async {
    if (orders.isEmpty) return orders;
    try {
      Map<String, Map<String, dynamic>> scannerByBarcode = {};
      try {
        final recentResp = await http
            .get(
              Uri.parse('${ApiConfig.logisticsBaseUrl}/api/v1/scanner/recent'),
              headers: {'Accept': 'application/json'},
            )
            .timeout(const Duration(seconds: 4));
        if (recentResp.statusCode == 200) {
          final decoded = jsonDecode(recentResp.body);
          final dataList = decoded['data'];
          if (dataList is List) {
            for (final item in dataList) {
              if (item is Map<String, dynamic>) {
                final bc = (item['barcode'] ?? '').toString().trim();
                final pNum = (item['parcel_number'] ?? '').toString().trim();
                if (bc.isNotEmpty && !scannerByBarcode.containsKey(bc)) {
                  scannerByBarcode[bc] = item;
                }
                if (pNum.isNotEmpty && !scannerByBarcode.containsKey(pNum)) {
                  scannerByBarcode[pNum] = item;
                }
              }
            }
          }
        }
      } catch (_) {}

      final enriched = await Future.wait(
        orders.map((o) => enrichOrderWithLogistics(o, cachedScannerMap: scannerByBarcode)),
      );
      return enriched;
    } catch (_) {
      return orders;
    }
  }

  /// Queries https://logistics.lumora.party/track/{id}?format=json to sync real-time delivery status,
  /// sorting hub, barangay area, assigned rider, vehicle unit, and scan timeline.
  Future<OrderModel> enrichOrderWithLogistics(
    OrderModel order, {
    Map<String, Map<String, dynamic>>? cachedScannerMap,
  }) async {
    try {
      final numericId = _extractNumericOrderId(order.id);
      final lookupCandidates = <String>{
        if (numericId != null && numericId.isNotEmpty) numericId,
        if (order.trackingNumber.startsWith('LM-TRK-')) order.trackingNumber,
        order.id,
      }.toList();

      Map<String, dynamic>? trackData;
      for (final candidate in lookupCandidates) {
        try {
          final resp = await http
              .get(
                Uri.parse('${ApiConfig.logisticsBaseUrl}/track/${Uri.encodeComponent(candidate)}?format=json'),
                headers: {'Accept': 'application/json'},
              )
              .timeout(const Duration(seconds: 4));
          if (resp.statusCode == 200) {
            final decoded = jsonDecode(resp.body);
            if (decoded is Map<String, dynamic> && decoded['found'] == true) {
              trackData = decoded;
              break;
            }
          }
        } catch (_) {}
      }

      final scannerEntry = cachedScannerMap != null
          ? (cachedScannerMap[numericId ?? ''] ??
              cachedScannerMap[order.trackingNumber] ??
              cachedScannerMap[order.id])
          : null;

      if (trackData == null && scannerEntry == null) {
        return order;
      }

      final effectiveStatus = (trackData?['effective_status'] ?? '').toString().trim().toLowerCase();
      final parcelStatus = (trackData?['parcel_status'] ?? scannerEntry?['status'] ?? '').toString().trim().toLowerCase();
      final scans = (trackData?['scans'] is List) ? (trackData!['scans'] as List) : const [];
      final events = (trackData?['events'] is List) ? (trackData!['events'] as List) : const [];

      final latestScan = scans.isNotEmpty && scans.first is Map ? (scans.first as Map) : null;
      final latestScanNote = (latestScan?['notes'] ?? latestScan?['note'] ?? '').toString();
      final latestScanType = (latestScan?['type'] ?? latestScan?['scan_type'] ?? '').toString().toLowerCase();

      String logisticsStage = parcelStatus.isNotEmpty ? parcelStatus : effectiveStatus;
      if (latestScanNote.toLowerCase().contains('parcel returned') ||
          latestScanNote.toLowerCase().contains('returned to')) {
        logisticsStage = 'returned';
      } else if (effectiveStatus == 'delivered' ||
          parcelStatus == 'delivered' ||
          latestScanType.contains('delivery') && !latestScanType.contains('out_for_delivery') ||
          latestScanNote.toLowerCase().contains('delivered to recipient')) {
        logisticsStage = 'delivered';
      } else if (effectiveStatus == 'out_for_delivery' ||
          parcelStatus == 'out_for_delivery' ||
          latestScanType.contains('out_for_delivery') ||
          latestScanType.contains('out for delivery') ||
          latestScanNote.toLowerCase().contains('out for delivery')) {
        logisticsStage = 'out_for_delivery';
      } else if (effectiveStatus == 'in_transit' ||
          parcelStatus == 'in_transit' ||
          parcelStatus == 'rider_received' ||
          latestScanType.contains('dispatch') ||
          latestScanNote.toLowerCase().contains('linehaul') ||
          latestScanNote.toLowerCase().contains('picked up by rider')) {
        logisticsStage = 'in_transit';
      } else if (parcelStatus == 'assigned' ||
          latestScanNote.toLowerCase().contains('assigned to')) {
        logisticsStage = 'assigned';
      } else if (parcelStatus == 'sorted' ||
          latestScanType.contains('sort') ||
          latestScanNote.toLowerCase().contains('parcel sorted')) {
        logisticsStage = 'sorted';
      } else if (parcelStatus == 'received' ||
          parcelStatus == 'scanned' ||
          latestScanType.contains('arrival') ||
          latestScanType.contains('verify') ||
          latestScanType.contains('scan')) {
        logisticsStage = 'scanned';
      }

      String mappedAppStatus = order.status;
      switch (logisticsStage) {
        case 'received':
        case 'scanned':
          mappedAppStatus = 'at_sorting_center';
          break;
        case 'sorted':
          mappedAppStatus = 'sorted';
          break;
        case 'assigned':
          mappedAppStatus = 'assigned_to_rider';
          break;
        case 'rider_received':
        case 'in_transit':
        case 'shipped':
          mappedAppStatus = 'shipped';
          break;
        case 'out_for_delivery':
          mappedAppStatus = 'out_for_delivery';
          break;
        case 'delivered':
        case 'completed':
          mappedAppStatus = 'delivered';
          break;
        case 'returned':
          mappedAppStatus = 'returned';
          break;
      }

      // Extract Hub Name
      String hubName = (trackData?['hub_name'] ?? '').toString().trim();
      if (hubName.isEmpty && scannerEntry != null) {
        final br = (scannerEntry['branch'] ?? '').toString().trim();
        if (br.isNotEmpty) {
          hubName = br.toLowerCase().contains('hub') ? br : '$br Hub';
        }
      }
      if (hubName.isEmpty && events.isNotEmpty && events.first is Map) {
        hubName = ((events.first as Map)['location'] ?? '').toString().trim();
      }
      if (hubName.isEmpty) {
        for (final s in scans) {
          if (s is Map) {
            final note = (s['notes'] ?? s['note'] ?? '').toString();
            final m = RegExp(r'(?:at|in|to)\s+([A-Za-z\s]+Hub)', caseSensitive: false).firstMatch(note);
            if (m != null && m.group(1) != null) {
              hubName = m.group(1)!.trim();
              break;
            }
          }
        }
      }
      if (hubName.isEmpty && latestScan != null) {
        final loc = (latestScan['location'] ?? '').toString().trim();
        if (loc.isNotEmpty) {
          hubName = loc.toLowerCase().contains('hub') ? loc : '$loc Hub';
        }
      }
      if (hubName.isEmpty) {
        hubName = order.sortingCenterName ?? 'Laguna Central Sorting Hub';
      }

      // Extract Barangay / Destination Area
      String areaName = (trackData?['area_name'] ?? scannerEntry?['area_name'] ?? '').toString().trim();
      if (areaName.isEmpty) {
        for (final s in scans) {
          if (s is Map) {
            final note = (s['notes'] ?? s['note'] ?? '').toString();
            final m = RegExp(r'into\s+(Brgy\.[^.]+?)(?:\s+and\s+assigned|\.)', caseSensitive: false).firstMatch(note);
            if (m != null && m.group(1) != null) {
              areaName = m.group(1)!.trim();
              break;
            }
          }
        }
      }
      if (areaName.isEmpty) {
        final dest = (trackData?['destination'] ?? '').toString().trim();
        if (dest.isNotEmpty) areaName = dest;
      }
      if (areaName.isEmpty) {
        areaName = order.destinationArea ?? 'Laguna District';
      }

      // Extract Courier Rider & Vehicle
      String riderName = (trackData?['courier_name'] ?? scannerEntry?['assigned_rider'] ?? '').toString().trim();
      if (riderName.isEmpty) {
        for (final s in scans) {
          if (s is Map) {
            final note = (s['notes'] ?? s['note'] ?? '').toString();
            final m = RegExp(r'assigned to (?:rider\s+)?([A-Za-z0-9\s._-]+?)(?:\.|,|$)', caseSensitive: false).firstMatch(note);
            if (m != null && m.group(1) != null) {
              riderName = m.group(1)!.trim();
              break;
            }
          }
        }
      }
      final String driverName = riderName.isNotEmpty ? riderName : order.driverName;
      final String courierName = riderName.isNotEmpty ? 'Lumora Logistics • $riderName' : 'Lumora Logistics';
      final String driverPhone = (trackData?['courier_phone'] ?? '').toString().trim().isNotEmpty
          ? (trackData!['courier_phone']).toString().trim()
          : order.driverPhone;

      String vehiclePlate = (trackData?['linehaul_truck'] ?? trackData?['courier_vehicle'] ?? '').toString().trim();
      for (final s in scans) {
        if (s is Map) {
          final note = (s['notes'] ?? s['note'] ?? '').toString();
          final m = RegExp(r'([A-Za-z\s]+Linehaul\s+Truck)', caseSensitive: false).firstMatch(note);
          if (m != null && m.group(1) != null && mappedAppStatus == 'shipped') {
            vehiclePlate = m.group(1)!.trim();
            break;
          }
        }
      }
      if (vehiclePlate.isEmpty) {
        vehiclePlate = order.vehiclePlate;
      }

      final String trackingNum = (trackData?['parcel_number'] ??
              trackData?['tracking_number'] ??
              scannerEntry?['parcel_number'] ??
              '')
          .toString()
          .trim();
      final String finalTrackingNumber =
          trackingNum.isNotEmpty ? trackingNum : order.trackingNumber;

      // Build merged status history from Logistics scans
      final List<OrderStatusHistoryItem> mergedHistory = [];
      for (final s in scans) {
        if (s is Map) {
          final sType = (s['type'] ?? s['scan_type'] ?? 'scanned').toString().toLowerCase();
          final sNote = (s['notes'] ?? s['note'] ?? '').toString();
          final sLocRaw = (s['location'] ?? hubName).toString().trim();
          final sLoc = sLocRaw.toLowerCase().contains('hub') ? sLocRaw : '$sLocRaw Hub';
          final sTime = (s['scanned_at'] ?? s['time'] ?? '').toString().trim();

          String histStatus = mappedAppStatus;
          String histLabel = 'Logistics Scan Update';
          if (sType.contains('arrival') || sType.contains('verify')) {
            histStatus = 'at_sorting_center';
            histLabel = 'Arrived & Verified at Sorting Hub';
          } else if (sType.contains('sort')) {
            if (sNote.toLowerCase().contains('assigned to')) {
              histStatus = 'assigned_to_rider';
              histLabel = 'Sorted & Assigned to Courier';
            } else {
              histStatus = 'sorted';
              histLabel = 'Sorted by Barangay Area';
            }
          } else if (sType.contains('dispatch')) {
            if (sNote.toLowerCase().contains('returned')) {
              histStatus = 'returned';
              histLabel = 'Parcel Returned to Hub';
            } else if (sNote.toLowerCase().contains('linehaul')) {
              histStatus = 'shipped';
              histLabel = 'Linehaul Truck Hub Transfer';
            } else {
              histStatus = 'shipped';
              histLabel = 'Dispatched in Transit';
            }
          } else if (sType.contains('out_for_delivery') || sType.contains('out for delivery')) {
            histStatus = 'out_for_delivery';
            histLabel = 'Out for Delivery';
          } else if (sType.contains('delivery')) {
            histStatus = 'delivered';
            histLabel = 'Delivered to Recipient';
          }

          mergedHistory.add(
            OrderStatusHistoryItem(
              status: histStatus,
              notes: sNote,
              location: sLoc,
              trackingStatus: histStatus,
              trackingLabel: histLabel,
              courierName: riderName.isNotEmpty ? riderName : 'Lumora Logistics',
              formattedTime: sTime.isNotEmpty ? '$sTime PHT' : null,
              createdAt: order.createdAt,
            ),
          );
        }
      }

      for (final existing in order.statusHistory) {
        final dup = mergedHistory.any(
          (m) => m.notes.trim().toLowerCase() == existing.notes.trim().toLowerCase(),
        );
        if (!dup) {
          mergedHistory.add(existing);
        }
      }

      final String headline = switch (mappedAppStatus) {
        'at_sorting_center' => 'Arrived at $hubName',
        'sorted' => 'Sorted for $areaName',
        'assigned_to_rider' => 'Assigned to Courier • $driverName',
        'shipped' => 'In Transit via Lumora Logistics',
        'out_for_delivery' => 'Out for Delivery with $driverName',
        'delivered' => 'Delivered by Lumora Logistics',
        'returned' => 'Parcel Returned ($hubName)',
        _ => order.statusHeadline ?? 'Order Status Updated',
      };

      final String explanation = latestScanNote.isNotEmpty
          ? latestScanNote
          : switch (mappedAppStatus) {
              'at_sorting_center' => 'Your parcel has been scanned and verified at $hubName.',
              'sorted' => 'Your parcel has been sorted at $hubName into $areaName.',
              'assigned_to_rider' => 'Assigned to rider $driverName ($vehiclePlate) for $areaName.',
              'shipped' => 'Your parcel is moving across the Laguna Logistics network toward $hubName.',
              'out_for_delivery' => 'Courier $driverName ($vehiclePlate) is on the way to your address.',
              'delivered' => 'Your parcel was successfully delivered and confirmed.',
              'returned' => 'Parcel was marked as returned in Lumora Logistics.',
              _ => order.statusExplanation ?? '',
            };

      final double progressVal = switch (mappedAppStatus) {
        'pending' || 'processing' => 0.15,
        'packed' => 0.30,
        'at_sorting_center' => 0.45,
        'sorted' => 0.55,
        'assigned_to_rider' => 0.65,
        'shipped' => 0.75,
        'out_for_delivery' => 0.90,
        'delivered' => 1.0,
        _ => order.progress,
      };

      return OrderModel(
        id: order.id,
        trackingNumber: finalTrackingNumber,
        createdAt: order.createdAt,
        status: mappedAppStatus,
        items: order.items,
        totalAmount: order.totalAmount,
        subtotalAmount: order.subtotalAmount,
        shippingFeeAmount: order.shippingFeeAmount,
        deliveryAddress: order.deliveryAddress,
        recipientName: order.recipientName,
        paymentMethod: order.paymentMethod,
        courierName: courierName,
        driverName: driverName,
        driverPhone: driverPhone,
        vehiclePlate: vehiclePlate,
        sortingCenterName: hubName,
        destinationArea: areaName,
        assignedRiderId: riderName.isNotEmpty ? riderName : order.assignedRiderId,
        statusHistory: mergedHistory.isNotEmpty ? mergedHistory : order.statusHistory,
        progress: progressVal,
        noteToSeller: order.noteToSeller,
        voucherCode: order.voucherCode,
        deliveredAt: order.deliveredAt,
        isAutoCompleted: order.isAutoCompleted,
        isDisputed: order.isDisputed,
        returnRejectionReason: order.returnRejectionReason,
        returnDisputeStatus: order.returnDisputeStatus,
        returnEvidencePhotos: order.returnEvidencePhotos,
        returnReason: order.returnReason,
        paymentProofPath: order.paymentProofPath,
        paymentReferenceLast6: order.paymentReferenceLast6,
        paymentStatus: order.paymentStatus,
        estimatedDelivery: order.estimatedDelivery,
        statusHeadline: headline,
        statusExplanation: explanation,
        statusLabel: (trackData?['status_label'] ?? order.statusLabel)?.toString(),
      );
    } catch (e) {
      debugPrint('ApiService.enrichOrderWithLogistics error: $e');
      return order;
    }
  }

  /// 7. Cancel Order (Web Parity: Buyer/OrderController@cancel)
  Future<bool> cancelOrder({
    required String orderId,
    required String reason,
    String? token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/buyer/orders/$orderId/cancel'),
            headers: await _buyerHeaders(token: token),
            body: jsonEncode({'reason': reason}),
          )
          .timeout(ApiConfig.timeout);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.cancelOrder error: $e');
      return false;
    }
  }

  /// Maps any reason label/code to the official website code (`in:damaged,wrong_item,missing_items,not_as_described,changed_mind,other`)
  static String normalizeWebsiteReturnReasonCode(String rawReason) {
    final s = rawReason.trim().toLowerCase();
    if (s == 'damaged' || s.contains('damaged') || s.contains('defective') || s.contains('faulty')) {
      return 'damaged';
    }
    if (s == 'wrong_item' || s.contains('wrong item') || s.contains('incorrect')) {
      return 'wrong_item';
    }
    if (s == 'missing_items' || s.contains('missing')) {
      return 'missing_items';
    }
    if (s == 'not_as_described' || s.contains('not as described') || s.contains('counterfeit')) {
      return 'not_as_described';
    }
    if (s == 'changed_mind' || s.contains('changed mind')) {
      return 'changed_mind';
    }
    return 'other';
  }

  /// 8. Return & Refund Request (1:1 Web Parity: Buyer/OrderController@requestReturn)
  Future<bool> requestReturnRefund({
    required String orderId,
    required String reason,
    required String solution,
    String? details,
    List<String> photos = const [],
    String? token,
  }) async {
    final tok = token ?? await _getToken();
    final reasonCode = normalizeWebsiteReturnReasonCode(reason);
    final effectiveDetails = (details != null && details.trim().length >= 10)
        ? details.trim()
        : '${details?.trim() ?? ''} — Buyer requested return/refund ($reason).'.trim();

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/buyer/orders/$orderId/return'),
      );
      request.headers.addAll(await _buyerHeaders(token: tok, jsonContent: false));
      request.fields['reason'] = reasonCode;
      request.fields['details'] = effectiveDetails;
      request.fields['description'] = effectiveDetails;
      request.fields['preferred_solution'] = solution;

      for (int i = 0; i < photos.length && i < 5; i++) {
        final photo = photos[i];
        if (photo.startsWith('data:image')) {
          final rawBase64 = photo.split(',').last.replaceAll(RegExp(r'\s+'), '');
          final bytes = base64Decode(rawBase64);
          String ext = 'jpg';
          if (bytes.length >= 4 &&
              bytes[0] == 0x89 &&
              bytes[1] == 0x50 &&
              bytes[2] == 0x4E &&
              bytes[3] == 0x47) {
            ext = 'png';
          }
          request.files.add(
            http.MultipartFile.fromBytes(
              'evidence[]',
              bytes,
              filename: 'return_evidence_${i + 1}.$ext',
            ),
          );
        } else if (File(photo).existsSync()) {
          request.files.add(await http.MultipartFile.fromPath('evidence[]', photo));
        }
      }

      final streamed = await request.send().timeout(const Duration(seconds: 20));
      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        return true;
      }
    } catch (e) {
      debugPrint('ApiService.requestReturnRefund multipart error: $e');
    }

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/buyer/orders/$orderId/return'),
            headers: await _buyerHeaders(token: tok),
            body: jsonEncode({
              'reason': reasonCode,
              'details': effectiveDetails,
              'preferred_solution': solution,
              'description': effectiveDetails,
              'evidence_photos': photos,
            }),
          )
          .timeout(ApiConfig.timeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('ApiService.requestReturnRefund error: $e');
      return false;
    }
  }

  /// 9. Escalate Return Dispute to Admin (Web Parity: Buyer/DisputeController@store)
  Future<bool> escalateDispute({
    required String orderId,
    String? disputeNotes,
    String? token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/buyer/orders/$orderId/dispute'),
            headers: await _buyerHeaders(token: token),
            body: jsonEncode({
              'dispute_notes': disputeNotes,
              'escalated_at': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(ApiConfig.timeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('ApiService.escalateDispute error: $e');
      return false;
    }
  }

  /// Re-upload GCash/Maya receipt for a pending order (Web Parity: Buyer/OrderController@replacePaymentProof)
  Future<({bool success, String message})> replacePaymentProof({
    required String orderId,
    required String receiptDataUri,
    required String referenceLast6,
    String? token,
  }) async {
    try {
      final tok = token ?? await _getToken();
      final mime = RegExp(r'data:image/(\w+)').firstMatch(receiptDataUri)?.group(1) ?? 'jpeg';
      final ext = mime == 'jpeg' ? 'jpg' : mime;
      final bytes = base64Decode(receiptDataUri.split(',').last);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/buyer/orders/$orderId/payment-proof'),
      );
      request.headers.addAll(await _buyerHeaders(token: tok, jsonContent: false));
      request.fields['payment_reference_last6'] = referenceLast6;
      request.files.add(http.MultipartFile.fromBytes(
        'payment_proof',
        bytes,
        filename: 'receipt.$ext',
      ));

      final streamed = await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamed);
      Map<String, dynamic> decoded = {};
      try {
        decoded = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      final ok = response.statusCode == 200 || response.statusCode == 201;
      return (
        success: ok,
        message: decoded['message']?.toString() ??
            (ok ? 'Receipt submitted for review.' : 'Could not submit receipt.'),
      );
    } catch (e) {
      debugPrint('ApiService.replacePaymentProof error: $e');
      return (success: false, message: 'Network error: $e');
    }
  }

  /// 10. Submit Product Review (Web Parity: Buyer/ProductReviewController@store)
  Future<bool> submitProductReview({
    required String productId,
    required int rating,
    String? comment,
    List<String> images = const [],
    String? token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/buyer/products/$productId/reviews'),
            headers: await _buyerHeaders(token: token),
            body: jsonEncode({
              'rating': rating,
              'comment': comment ?? '',
              'images': images,
            }),
          )
          .timeout(ApiConfig.timeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('ApiService.submitProductReview error: $e');
      return false;
    }
  }

  /// 10.5. Mark Order as Received (Buyer Turnover)
  Future<bool> markOrderReceived({
    required String orderId,
    String? token,
  }) async {
    try {
      final tok = token ?? await _getToken();
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/buyer/orders/$orderId/receive'),
            headers: _headers(token: tok),
          )
          .timeout(ApiConfig.timeout);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.markOrderReceived error: $e');
      return false;
    }
  }

  /// 10.6. Reset Password with OTP
  Future<({bool success, String? message})> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/password/reset'),
            headers: _headers(),
            body: jsonEncode({
              'email': email,
              'code': code,
              'password': password,
            }),
          )
          .timeout(ApiConfig.timeout);

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return (success: true, message: decoded['message']?.toString() ?? 'Password reset successfully.');
      } else {
        return (success: false, message: decoded['message']?.toString() ?? 'Failed to reset password.');
      }
    } catch (e) {
      debugPrint('ApiService.resetPassword error: $e');
      return (success: false, message: 'Network error: $e');
    }
  }

  /// 10.7. Update Buyer Profile
  Future<bool> updateProfile({
    required Map<String, dynamic> data,
    String? token,
  }) async {
    try {
      final tok = token ?? await _getToken();
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
            headers: _headers(token: tok),
            body: jsonEncode(data),
          )
          .timeout(ApiConfig.timeout);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.updateProfile error: $e');
      return false;
    }
  }

  /// 10.8. Update Password
  Future<({bool success, String? message})> updatePassword({
    required String currentPassword,
    required String newPassword,
    String? token,
  }) async {
    try {
      final tok = token ?? await _getToken();
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/auth/profile/password'),
            headers: _headers(token: tok),
            body: jsonEncode({
              'current_password': currentPassword,
              'new_password': newPassword,
            }),
          )
          .timeout(ApiConfig.timeout);

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return (success: true, message: decoded['message']?.toString() ?? 'Password updated successfully.');
      } else {
        return (success: false, message: decoded['message']?.toString() ?? 'Failed to update password.');
      }
    } catch (e) {
      debugPrint('ApiService.updatePassword error: $e');
      return (success: false, message: 'Network error: $e');
    }
  }

  /// 11. Request & Verify OTP
  Future<Map<String, dynamic>> requestOtp({required String target, required String type}) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/otp/send'),
            headers: _headers(),
            body: jsonEncode({'target': target, 'email': target, 'type': type}),
          )
          .timeout(ApiConfig.timeout);

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Verification code sent.'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to send verification code.'};
      }
    } catch (e) {
      debugPrint('ApiService.requestOtp error: $e');
      return {'success': false, 'message': 'Network error: Unable to contact mail server.'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp({required String target, required String code, required String type}) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/otp/verify'),
            headers: _headers(),
            body: jsonEncode({'target': target, 'email': target, 'code': code, 'type': type}),
          )
          .timeout(ApiConfig.timeout);

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Email verified.'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Incorrect or expired code.'};
      }
    } catch (e) {
      debugPrint('ApiService.verifyOtp error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Helper to convert JSON row from MySQL to Flutter Product model
  Product _mapJsonToProduct(Map<String, dynamic> json) {
    final gallery = (json['images'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final imagePath = json['image_path']?.toString() ?? (gallery.isNotEmpty ? gallery.first : null);
    final sellerName = json['seller_name']?.toString() ?? 'LUMORA Official Store';
    final rawCategory = (json['category_id'] ?? json['category_name'] ?? 'Luxury').toString();

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      brand: sellerName,
      price: (json['price'] != null) ? double.tryParse(json['price'].toString()) ?? 0.0 : 0.0,
      originalPrice: json['original_price'] != null
          ? double.tryParse(json['original_price'].toString())
          : null,
      category: _mapToDepartment(rawCategory),
      description: json['description']?.toString() ?? '',
      rating: (json['rating'] != null) ? double.tryParse(json['rating'].toString()) ?? 4.8 : 4.8,
      reviewsCount: int.tryParse(json['reviews_count']?.toString() ?? '0') ?? 0,
      soldCount: int.tryParse(json['sold_count']?.toString() ?? '0') ?? 0,
      discountLabel: json['discount_label']?.toString(),
      isFlashDeal: json['is_flash_deal'] == 1 || json['is_flash_deal'] == true,
      stock: int.tryParse(json['stock']?.toString() ?? '25') ?? 25,
      imagePath: imagePath,
      galleryImages: gallery,
      sellerId: json['seller_id']?.toString() ?? 'store_lumora_official',
      sellerName: sellerName,
      sellerLocation: json['seller_location']?.toString() ?? 'Metro Manila',
      features: (json['features'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  /// Maps Laravel leaf category slugs/labels to the mobile app's top-level departments.
  String _mapToDepartment(String raw) {
    final s = raw.toLowerCase();
    if (s.startsWith('womens-') || s == 'women') return 'Women';
    if (s.startsWith('mens-') || s == 'men' || s == 'shavers-trimmers') return 'Men';
    if (const {
      'electronics', 'phones-tablets', 'smartphones', 'apple', 'samsung', 'xiaomi',
      'oppo', 'tablets', 'electronics-accessories', 'computers', 'appliances', 'audio', 'cameras',
    }.contains(s)) {
      return 'Electronics';
    }
    if (const {
      'beauty', 'beauty-personal-care', 'skincare', 'makeup', 'hair-care',
      'personal-care', 'bath-essentials', 'kid-bath-baby-care', 'fragrance',
    }.contains(s)) {
      return 'Beauty';
    }
    if (const {'home-living', 'home & living', 'furniture', 'kitchen', 'home', 'home-decor'}.contains(s)) {
      return 'Home & Living';
    }
    if (const {'sports', 'sports-outdoors', 'running', 'basketball', 'football', 'hiking', 'fitness'}.contains(s)) {
      return 'Sports';
    }
    return raw.isEmpty ? 'Luxury' : raw;
  }
}
