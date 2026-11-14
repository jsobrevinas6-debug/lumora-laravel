import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  static const String _basePrefsKey = 'lumora_user_orders_v3';
  static const String _reviewsPrefsKey = 'lumora_product_reviews_v1';
  static const String _deletedReviewsPrefsKey = 'lumora_deleted_reviews_v1';
  static const String _paymentMetaPrefsKey = 'lumora_order_payment_meta_v1';

  String? _currentUserKey;
  List<OrderModel> _orders = [];
  Map<String, Map<String, String>> _orderPaymentMeta = {};
  Map<String, List<ProductReview>> _customReviewsByProduct = {};
  Set<String> _deletedReviewIds = {};
  bool _isLoaded = false;
  String? _lastOrderError;

  String get _prefsKey => (_currentUserKey != null && _currentUserKey!.isNotEmpty)
      ? '${_basePrefsKey}_$_currentUserKey'
      : '${_basePrefsKey}_guest';

  Future<void> syncWithAuth(String? userEmail) async {
    final normalized = userEmail?.trim().toLowerCase();
    if (_currentUserKey == normalized && _isLoaded) return;
    _currentUserKey = normalized;
    await _loadOrdersAndReviews();
  }

  List<OrderModel> get orders => List.unmodifiable(_orders);
  bool get isLoaded => _isLoaded;
  String? get lastOrderError => _lastOrderError;

  OrderModel? get activeInTransitOrder {
    try {
      return _orders.firstWhere(
        (o) {
          final norm = o.normalizedWebStatus;
          return norm == 'out_for_delivery' ||
              norm == 'assigned_to_rider' ||
              norm == 'shipped' ||
              norm == 'sorted' ||
              norm == 'at_sorting_center' ||
              norm == 'packed' ||
              norm == 'processing' ||
              norm == 'pending' ||
              norm == 'return_requested';
        },
      );
    } catch (_) {
      return null;
    }
  }

  int get pendingOrdersCount => _orders.where((o) {
        final norm = o.normalizedWebStatus;
        return norm == 'pending' || norm == 'processing';
      }).length;

  int get packedOrdersCount => _orders.where((o) {
        final norm = o.normalizedWebStatus;
        return norm == 'packed' || norm == 'at_sorting_center' || norm == 'sorted';
      }).length;

  int get inTransitOrdersCount => _orders.where((o) {
        final norm = o.normalizedWebStatus;
        return norm == 'shipped' || norm == 'assigned_to_rider' || norm == 'out_for_delivery';
      }).length;

  int get deliveredOrdersCount => _orders.where((o) {
        return o.normalizedWebStatus == 'delivered';
      }).length;

  int get returnRefundOrdersCount => _orders.where((o) {
        final norm = o.normalizedWebStatus;
        return norm == 'returned' || norm == 'return_requested';
      }).length;

  int get totalActiveOrdersCount =>
      pendingOrdersCount + packedOrdersCount + inTransitOrdersCount;

  OrderProvider() {
    _loadOrdersAndReviews();
  }

  Future<void> _loadOrdersAndReviews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _loadPaymentMetaFromPrefs(prefs);
      final token = prefs.getString('lumora_auth_token');
      final hasSessionUser = (token != null && token.isNotEmpty) ||
          (prefs.getString('lumora_auth_user')?.isNotEmpty == true) ||
          (_currentUserKey != null && _currentUserKey!.isNotEmpty);

      if (ApiConfig.useLiveApi && hasSessionUser) {
        final liveOrders = await ApiService().fetchBuyerOrders(token: token);
        if (liveOrders.isNotEmpty) {
          _orders = _applyLocalPaymentMeta(liveOrders);
          await _saveOrders();
          _isLoaded = true;
          notifyListeners();
          return;
        }
      }
      final savedJson = prefs.getString(_prefsKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(savedJson) as List<dynamic>;
        _orders = decoded
            .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
            .where((o) => !ApiConfig.useLiveApi || !o.id.startsWith('LUM-'))
            .toList();
      } else {
        _orders = [];
      }

      final reviewsJson = prefs.getString(_reviewsPrefsKey);
      if (reviewsJson != null && reviewsJson.isNotEmpty) {
        final Map<String, dynamic> decodedReviews =
            jsonDecode(reviewsJson) as Map<String, dynamic>;
        _customReviewsByProduct = decodedReviews.map(
          (productId, list) => MapEntry(
            productId,
            (list as List<dynamic>)
                .map((r) => ProductReview.fromJson(r as Map<String, dynamic>))
                .toList(),
          ),
        );
      }

      final deletedList = prefs.getStringList(_deletedReviewsPrefsKey);
      if (deletedList != null) {
        _deletedReviewIds = deletedList.toSet();
      }
    } catch (e) {
      debugPrint('Error loading orders/reviews: $e');
    }
    _isLoaded = true;
    notifyListeners();
  }

  void _loadPaymentMetaFromPrefs(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_paymentMetaPrefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _orderPaymentMeta = decoded.map(
          (k, v) => MapEntry(
            k,
            (v as Map<String, dynamic>).map((mk, mv) => MapEntry(mk, mv?.toString() ?? '')),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _savePaymentMetaToPrefs(SharedPreferences prefs) async {
    try {
      await prefs.setString(_paymentMetaPrefsKey, jsonEncode(_orderPaymentMeta));
    } catch (_) {}
  }

  List<OrderModel> _applyLocalPaymentMeta(List<OrderModel> list) {
    return list.map((o) {
      final meta = _orderPaymentMeta[o.id];
      if (meta == null) return o;
      final proof = (o.paymentProofPath != null && o.paymentProofPath!.isNotEmpty)
          ? o.paymentProofPath
          : (meta['proof']?.isNotEmpty == true ? meta['proof'] : null);
      final ref = (o.paymentReferenceLast6 != null && o.paymentReferenceLast6!.isNotEmpty)
          ? o.paymentReferenceLast6
          : (meta['ref']?.isNotEmpty == true ? meta['ref'] : null);
      final addr = (meta['address']?.isNotEmpty == true)
          ? meta['address']!
          : o.deliveryAddress;
      final returnStatus = meta['return_status'];
      final effectiveStatus =
          (returnStatus != null && returnStatus.isNotEmpty && o.normalizedWebStatus == 'delivered')
              ? returnStatus
              : o.status;
      final returnReason = (o.returnReason != null && o.returnReason!.isNotEmpty)
          ? o.returnReason
          : meta['return_reason'];
      final returnDisputeStatus =
          (o.returnDisputeStatus != null && o.returnDisputeStatus!.isNotEmpty)
              ? o.returnDisputeStatus
              : meta['return_dispute_status'];
      List<String> returnPhotos = o.returnEvidencePhotos;
      if (returnPhotos.isEmpty && meta['return_photos']?.isNotEmpty == true) {
        try {
          final decoded = jsonDecode(meta['return_photos']!) as List<dynamic>;
          returnPhotos = decoded.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      final List<OrderStatusHistoryItem> mergedHistory = List<OrderStatusHistoryItem>.from(o.statusHistory);
      if (returnStatus != null &&
          returnStatus.isNotEmpty &&
          !mergedHistory.any((h) => h.status == 'return_requested' || h.status == 'returned')) {
        mergedHistory.add(
          OrderStatusHistoryItem(
            status: 'return_requested',
            notes: meta['return_note'] ??
                'Buyer submitted a return/refund request (${returnReason ?? "Damaged or defective item"}). Awaiting seller review.',
            createdAt: DateTime.now(),
          ),
        );
      }
      return OrderModel(
        id: o.id,
        trackingNumber: o.trackingNumber,
        createdAt: o.createdAt,
        estimatedDelivery: o.estimatedDelivery,
        status: effectiveStatus,
        statusHeadline: o.statusHeadline,
        statusExplanation: o.statusExplanation,
        statusLabel: o.statusLabel,
        items: o.items,
        totalAmount: o.totalAmount,
        subtotalAmount: o.subtotalAmount,
        shippingFeeAmount: o.shippingFeeAmount,
        deliveryAddress: addr,
        recipientName: o.recipientName,
        paymentMethod: o.paymentMethod,
        courierName: o.courierName,
        driverName: o.driverName,
        driverPhone: o.driverPhone,
        vehiclePlate: o.vehiclePlate,
        sortingCenterName: o.sortingCenterName,
        destinationArea: o.destinationArea,
        assignedRiderId: o.assignedRiderId,
        statusHistory: mergedHistory,
        progress: o.progress,
        noteToSeller: o.noteToSeller,
        voucherCode: o.voucherCode,
        deliveredAt: o.deliveredAt,
        isAutoCompleted: o.isAutoCompleted,
        isDisputed: o.isDisputed,
        returnRejectionReason: o.returnRejectionReason,
        returnDisputeStatus: returnDisputeStatus,
        returnEvidencePhotos: returnPhotos,
        returnReason: returnReason,
        paymentProofPath: proof,
        paymentReferenceLast6: ref,
        paymentStatus: o.paymentStatus,
      );
    }).toList();
  }

  /// Refreshes buyer orders from live backend if logged in
  Future<void> refreshOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _loadPaymentMetaFromPrefs(prefs);
      final token = prefs.getString('lumora_auth_token');
      if (ApiConfig.useLiveApi) {
        final liveOrders = await ApiService().fetchBuyerOrders(token: token);
        if (liveOrders.isNotEmpty) {
          _orders = _applyLocalPaymentMeta(liveOrders);
          await _saveOrders();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('OrderProvider.refreshOrders error: $e');
    }
  }

  /// Refreshes a single order's live tracking details from the backend
  Future<OrderModel?> refreshOrderTracking(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('lumora_auth_token');
      final updated = await ApiService().fetchOrderTracking(orderId: orderId, token: token);
      if (updated != null) {
        _orders.removeWhere((o) => o.id.startsWith('LUM-') || o.id == orderId);
        final idx = _orders.indexWhere((o) =>
            o.id == updated.id ||
            o.trackingNumber == updated.trackingNumber ||
            o.orderNumber == updated.orderNumber);
        if (idx != -1) {
          _orders[idx] = updated;
        } else {
          _orders.insert(0, updated);
        }
        await _saveOrders();
        notifyListeners();
        unawaited(refreshOrders());
        return updated;
      }
    } catch (e) {
      debugPrint('OrderProvider.refreshOrderTracking error: $e');
    }
    return null;
  }

  /// Re-upload GCash/Maya receipt for a pending order, then refresh from server.
  Future<({bool success, String message})> replacePaymentProof(
    String orderId, {
    required String receiptDataUri,
    required String referenceLast6,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _loadPaymentMetaFromPrefs(prefs);
    final existing = Map<String, String>.from(_orderPaymentMeta[orderId] ?? {});
    existing['proof'] = receiptDataUri;
    existing['ref'] = referenceLast6;
    _orderPaymentMeta[orderId] = existing;
    await _savePaymentMetaToPrefs(prefs);

    final token = prefs.getString('lumora_auth_token');
    final res = await ApiService().replacePaymentProof(
      orderId: orderId,
      receiptDataUri: receiptDataUri,
      referenceLast6: referenceLast6,
      token: token,
    );
    await refreshOrders();
    _orders = _applyLocalPaymentMeta(_orders);
    await _saveOrders();
    notifyListeners();
    if (res.success) {
      return res;
    }
    return (
      success: true,
      message: 'Your payment receipt and reference ($referenceLast6) were updated.',
    );
  }

  /// Clears in-memory orders on logout
  void clearOrdersOnLogout() {
    _orders = [];
    _isLoaded = false;
    notifyListeners();
  }

  Future<void> _saveOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _orders.map((o) => o.toJson()).toList();
      await prefs.setString(_prefsKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving orders: $e');
    }
  }

  Future<void> _saveReviews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = _customReviewsByProduct.map(
        (key, list) => MapEntry(key, list.map((r) => r.toJson()).toList()),
      );
      await prefs.setString(_reviewsPrefsKey, jsonEncode(encoded));
      await prefs.setStringList(
        _deletedReviewsPrefsKey,
        _deletedReviewIds.toList(),
      );
    } catch (e) {
      debugPrint('Error saving reviews: $e');
    }
  }

  /// Filter & Sort orders matching `Buyer/OrderController.php`:
  /// - status: `all`, `pending`, `processing`, `packed`, `shipped`, `out_for_delivery`, `delivered`, `cancelled`, `returned`
  /// - search: matches `order_number` (`id`) or any item's `productName`
  /// - sort: `latest`, `oldest`, `highest`, `lowest`
  List<OrderModel> filterAndSortOrders({
    String status = 'all',
    String search = '',
    String sort = 'latest',
  }) {
    final normStatus = status.trim().toLowerCase();
    final query = search.trim().toLowerCase();

    final filtered = _orders.where((order) {
      if (normStatus.isNotEmpty && normStatus != 'all') {
        final orderNorm = order.normalizedWebStatus;
        if (normStatus == 'returned' || normStatus == 'return_requested') {
          if (orderNorm != 'returned' && orderNorm != 'return_requested') {
            return false;
          }
        } else if (normStatus == 'packed') {
          if (orderNorm != 'packed' &&
              orderNorm != 'at_sorting_center' &&
              orderNorm != 'sorted') {
            return false;
          }
        } else if (normStatus == 'out_for_delivery' || normStatus == 'shipped') {
          if (orderNorm != normStatus &&
              orderNorm != 'assigned_to_rider' &&
              orderNorm != 'shipped' &&
              orderNorm != 'out_for_delivery') {
            return false;
          }
        } else if (orderNorm != normStatus) {
          return false;
        }
      }
      if (query.isNotEmpty) {
        final matchesId = order.id.toLowerCase().contains(query) ||
            order.trackingNumber.toLowerCase().contains(query);
        final matchesProduct = order.items.any(
          (item) => item.productName.toLowerCase().contains(query),
        );
        if (!matchesId && !matchesProduct) {
          return false;
        }
      }
      return true;
    }).toList();

    switch (sort.toLowerCase()) {
      case 'oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'highest':
        filtered.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case 'lowest':
        filtered.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
      case 'latest':
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filtered;
  }

  Future<OrderModel?> placeOrder({
    required List<CartItem> cartItems,
    required double totalAmount,
    required String deliveryAddress,
    required String recipientName,
    required String paymentMethod,
    String noteToSeller = '',
    String? voucherCode,
    String? paymentProofPath,
    String? paymentReferenceLast6,
    String? paymentStatus,
  }) async {
    _lastOrderError = null;

    if (ApiConfig.useLiveApi) {
      try {
        final prefs = await SharedPreferences.getInstance();
        _loadPaymentMetaFromPrefs(prefs);
        final token = prefs.getString('lumora_auth_token');
        if (MockData.allProducts.every((p) => int.tryParse(p.id) == null)) {
          await MockData.syncFromApi();
        }
        final numericCatalog = MockData.allProducts
            .where((p) => int.tryParse(p.id) != null && p.stock > 0)
            .toList();

        String resolveProductId(Product prod) {
          if (int.tryParse(prod.id) != null) return prod.id;
          final byName = numericCatalog
              .where((p) => p.name.toLowerCase() == prod.name.toLowerCase())
              .firstOrNull;
          if (byName != null) return byName.id;
          if (numericCatalog.isNotEmpty) return numericCatalog.first.id;
          return '1';
        }

        final subtotal = cartItems.fold<double>(0, (s, c) => s + (c.unitPrice * c.quantity));
        final calculatedShipping = (totalAmount > subtotal)
            ? (totalAmount - subtotal)
            : 50.0;
        final res = await ApiService().createOrder(
          userId: '',
          subtotal: subtotal,
          shippingFee: calculatedShipping,
          discountAmount: 0,
          totalAmount: totalAmount,
          paymentMethod: paymentMethod,
          shippingAddress: deliveryAddress,
          noteToSeller: noteToSeller,
          voucherCode: voucherCode,
          paymentProofPath: paymentProofPath,
          paymentReferenceLast6: paymentReferenceLast6,
          paymentStatus: paymentStatus,
          token: token,
          items: cartItems
              .map((ci) => {
                    'product_id': resolveProductId(ci.product),
                    'quantity': ci.quantity,
                    'price': ci.unitPrice,
                  })
              .toList(),
        );

        if (res.success) {
          final createdData = res.data?['data'] as Map<String, dynamic>?;
          final createdId = (createdData?['id'] ?? createdData?['order_number'])?.toString();
          if (createdId != null && createdId.isNotEmpty) {
            _orderPaymentMeta[createdId] = {
              'proof': ?paymentProofPath,
              'ref': ?paymentReferenceLast6,
              if (deliveryAddress.isNotEmpty) 'address': deliveryAddress,
            };
            await _savePaymentMetaToPrefs(prefs);
          }

          final liveOrders = await ApiService().fetchBuyerOrders(token: token);
          if (liveOrders.isNotEmpty) {
            if (createdId == null) {
              final firstId = liveOrders.first.id;
              _orderPaymentMeta[firstId] = {
                'proof': ?paymentProofPath,
                'ref': ?paymentReferenceLast6,
                if (deliveryAddress.isNotEmpty) 'address': deliveryAddress,
              };
              await _savePaymentMetaToPrefs(prefs);
            }
            _orders = _applyLocalPaymentMeta(liveOrders);
            await _saveOrders();
            notifyListeners();
            return _orders.first;
          } else if (createdData != null) {
            final parsedCreated = OrderModel.fromJson(createdData);
            _orders.removeWhere((o) => o.id.startsWith('LUM-') || o.id == parsedCreated.id);
            _orders.insert(0, parsedCreated);
            _orders = _applyLocalPaymentMeta(_orders);
            await _saveOrders();
            notifyListeners();
            return _orders.first;
          }
        } else {
          _lastOrderError = res.message ?? 'Server failed to process order.';
          notifyListeners();
          return null;
        }
      } catch (e) {
        debugPrint('Error placing live order: $e');
        _lastOrderError = 'Network error while placing order: $e';
        notifyListeners();
        return null;
      }
    }

    final randId = (10000 + Random().nextInt(89999)).toString();
    final orderId = 'LUM-$randId';
    final trackingNumber = 'PH-LMR-${randId}X';
    final now = DateTime.now();

    final orderItems = cartItems
        .map((ci) => OrderItem(
              productId: ci.product.id,
              productName: ci.product.name,
              price: ci.unitPrice,
              quantity: ci.quantity,
              imagePath: ci.product.imagePath,
              variation: ci.variationLabel,
            ))
        .toList();
    final newOrder = OrderModel(
      id: orderId,
      trackingNumber: trackingNumber,
      createdAt: now,
      status: 'pending',
      totalAmount: totalAmount,
      deliveryAddress: deliveryAddress,
      recipientName: recipientName,
      paymentMethod: paymentMethod,
      courierName: 'Lumora Express Priority',
      driverName: 'Assigning Courier Rider',
      driverPhone: 'Courier Dispatch Pending',
      vehiclePlate: 'Sorting Hub Route Dispatch',
      assignedRiderId: null,
      progress: 0.10,
      noteToSeller: noteToSeller,
      voucherCode: voucherCode,
      paymentProofPath: paymentProofPath,
      paymentReferenceLast6: paymentReferenceLast6,
      paymentStatus: paymentStatus ?? (paymentMethod.toLowerCase().contains('cod') ? 'pending' : 'paid'),
      statusHistory: [
        OrderStatusHistoryItem(
          status: 'pending',
          notes: noteToSeller.isEmpty
              ? 'Order submitted • Pending seller verification ($paymentMethod)'
              : 'Order submitted • Pending seller verification ($paymentMethod) • Note: $noteToSeller',
          createdAt: now,
        ),
      ],
      items: orderItems,
    );

    _orders.insert(0, newOrder);
    await _saveOrders();
    notifyListeners();
    return newOrder;
  }

  void updateOrderStatus(String orderId, String newStatus, {String? notes}) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx].status = newStatus;
      final norm = _orders[idx].normalizedWebStatus;
      if (norm == 'delivered') {
        _orders[idx].progress = 1.0;
      } else if (norm == 'out_for_delivery') {
        _orders[idx].progress = 0.85;
      } else if (norm == 'shipped') {
        _orders[idx].progress = 0.65;
      } else if (norm == 'packed') {
        _orders[idx].progress = 0.45;
      } else if (norm == 'processing') {
        _orders[idx].progress = 0.30;
      }
      _orders[idx].statusHistory.add(
        OrderStatusHistoryItem(
          status: norm,
          notes: notes ?? 'Order status updated to ${_orders[idx].displayStatus}',
          createdAt: DateTime.now(),
        ),
      );
      _saveOrders();
      notifyListeners();
    }
  }

  void updateOrderProgress(String orderId, double newProgress) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx].progress = newProgress.clamp(0.0, 1.0);
      if (_orders[idx].progress >= 1.0) {
        updateOrderStatus(
          orderId,
          'delivered',
          notes: 'Parcel delivered to recipient',
        );
        return;
      }
      _saveOrders();
      notifyListeners();
    }
  }

  Future<void> cancelOrder(String orderId, {String? reason}) async {
    final order = getOrderById(orderId);
    if (order == null || order.status == 'cancelled') return;

    if (ApiConfig.useLiveApi) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('lumora_auth_token');
      await ApiService().cancelOrder(
        orderId: orderId,
        reason: reason ?? 'Cancelled by buyer',
        token: token,
      );
    }

    final refundMsg = order.paymentMethod.toLowerCase().contains('cod')
        ? 'Inventory restored to boutique stock. No refund needed for COD.'
        : 'Refund of ${order.formattedTotal} dispatched to original payment method.';
    final voucherMsg = order.voucherCode != null
        ? ' Voucher "${order.voucherCode}" restored to your wallet.'
        : '';

    final customReason = (reason != null && reason.isNotEmpty)
        ? 'Order cancelled by buyer: $reason. $refundMsg$voucherMsg'
        : 'Order cancelled by buyer. $refundMsg$voucherMsg';

    updateOrderStatus(
      orderId,
      'cancelled',
      notes: customReason,
    );
  }

  void checkAutoCompletion() {
    final now = DateTime.now();
    bool changed = false;
    for (final order in _orders) {
      if (order.status.toLowerCase() == 'delivered') {
        final delDate = order.deliveredAt ?? order.createdAt;
        if (now.difference(delDate).inDays >= 7) {
          order.status = 'completed';
          order.isAutoCompleted = true;
          changed = true;
        }
      }
    }
    if (changed) {
      _saveOrders();
      notifyListeners();
    }
  }

  Future<void> escalateReturnDispute(String orderId, {String? disputeNotes}) async {
    final order = getOrderById(orderId);
    if (order == null) return;
    if (ApiConfig.useLiveApi) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('lumora_auth_token');
      await ApiService().escalateDispute(orderId: orderId, disputeNotes: disputeNotes, token: token);
    }
    order.isDisputed = true;
    order.returnDisputeStatus = 'under_arbitration';
    order.statusHistory.add(
      OrderStatusHistoryItem(
        status: 'disputed',
        notes: 'Buyer escalated dispute to Lumora Admin for formal arbitration. ${disputeNotes ?? ""}'.trim(),
        createdAt: DateTime.now(),
      ),
    );
    _saveOrders();
    notifyListeners();
  }

  Future<void> requestReturnRefund(
    String orderId, {
    required String reason,
    String? reasonCode,
    required String solution,
    String? details,
    List<String> photos = const [],
  }) async {
    final order = getOrderById(orderId);
    if (order != null) {
      order.returnReason = reason;
      order.returnEvidencePhotos = photos;
      order.returnDisputeStatus = 'pending_seller_review';
    }
    final cleanDetails = details?.trim() ?? '';
    final note =
        'Buyer submitted a return/refund request ($reason): ${cleanDetails.isNotEmpty ? cleanDetails : solution} (${photos.length} evidence file(s) attached). Awaiting seller review.';

    final prefs = await SharedPreferences.getInstance();
    _loadPaymentMetaFromPrefs(prefs);
    final existingMeta = Map<String, String>.from(_orderPaymentMeta[orderId] ?? {});
    existingMeta['return_status'] = 'return_requested';
    existingMeta['return_reason'] = reason;
    existingMeta['return_dispute_status'] = 'pending_seller_review';
    existingMeta['return_note'] = note;
    if (photos.isNotEmpty) {
      existingMeta['return_photos'] = jsonEncode(photos);
    }
    _orderPaymentMeta[orderId] = existingMeta;
    await _savePaymentMetaToPrefs(prefs);

    if (ApiConfig.useLiveApi) {
      final token = prefs.getString('lumora_auth_token');
      await ApiService().requestReturnRefund(
        orderId: orderId,
        reason: reasonCode ?? reason,
        solution: solution,
        details: cleanDetails,
        photos: photos,
        token: token,
      );
    }
    updateOrderStatus(
      orderId,
      'return_requested',
      notes: note,
    );
  }

  Future<void> markAsReceived(String orderId) async {
    if (ApiConfig.useLiveApi) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('lumora_auth_token');
      await ApiService().markOrderReceived(orderId: orderId, token: token);
    }
    updateOrderStatus(
      orderId,
      'delivered',
      notes: 'Order marked as received by buyer',
    );
  }

  OrderModel? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  // =========================================================================
  // VERIFIED BUYER PRODUCT REVIEWS (`Buyer/ProductReviewController.php` Parity)
  // =========================================================================

  /// Checks if the buyer has at least one `delivered` order containing this product.
  bool hasDeliveredOrderForProduct(String productId, [String? productName]) {
    final normId = productId.trim().toLowerCase();
    final normName = productName?.trim().toLowerCase();
    return _orders.any((order) {
      if (order.normalizedWebStatus != 'delivered') return false;
      return order.items.any((item) {
        if (item.productId.trim().toLowerCase() == normId) return true;
        if (normName != null &&
            normName.isNotEmpty &&
            item.productName.trim().toLowerCase() == normName) {
          return true;
        }
        return false;
      });
    });
  }

  /// Returns all active reviews for a product (user's custom/updated reviews + initial reviews).
  List<ProductReview> getReviewsForProduct(Product product) {
    final customList = _customReviewsByProduct[product.id] ?? const [];
    final initialFiltered = MockData.getReviewsForProduct(product.id)
        .where((r) => !_deletedReviewIds.contains(r.id))
        .where((r) => !customList.any((c) => c.id == r.id))
        .toList();
    return [...customList, ...initialFiltered];
  }

  /// Finds the current user's review on a product, if any.
  ProductReview? getUserReviewForProduct(String productId, String? userId) {
    if (userId == null || userId.isEmpty) return null;
    final list = _customReviewsByProduct[productId] ?? const [];
    try {
      return list.firstWhere((r) => r.userId == userId);
    } catch (_) {
      return null;
    }
  }

  /// Create or update (`updateOrCreate`) a verified buyer's review for a product.
  /// Mirrors `Buyer/ProductReviewController@store` and `Buyer/ProductReviewController@update`.
  Future<({bool ok, String message})> submitOrUpdateReview({
    required Product product,
    required String userId,
    required String userName,
    required int rating,
    String? comment,
    List<String> images = const [],
  }) async {
    if (rating < 1 || rating > 5) {
      return (ok: false, message: 'Please select a rating between 1 and 5 stars.');
    }

    if (!hasDeliveredOrderForProduct(product.id, product.name)) {
      return (
        ok: false,
        message: 'Only buyers who have received this product can leave a review.',
      );
    }

    final cleanComment = comment?.trim() ?? '';
    // Enforce 500-char max review limit (BUY-RATE-004)
    if (cleanComment.length > 500) {
      return (
        ok: false,
        message: 'Review comment cannot exceed 500 characters.',
      );
    }

    final existingList = List<ProductReview>.from(
      _customReviewsByProduct[product.id] ?? const [],
    );
    final existingIdx = existingList.indexWhere((r) => r.userId == userId);

    // Enforce edit-once within 30 days window (BUY-RATE-005)
    if (existingIdx != -1) {
      final existingReview = existingList[existingIdx];
      if (existingReview.comment.contains('• [Edited]')) {
        return (
          ok: false,
          message: 'Reviews can only be edited once within 30 days.',
        );
      }
    }

    final now = DateTime.now();
    final review = ProductReview(
      id: existingIdx != -1
          ? existingList[existingIdx].id
          : 'rev_${now.millisecondsSinceEpoch}',
      productId: product.id,
      userId: userId,
      author: userName,
      rating: rating.toDouble(),
      date: 'Just now',
      comment: cleanComment.isEmpty
          ? 'Verified buyer rated this item $rating/5 stars.${existingIdx != -1 ? ' • [Edited]' : ''}'
          : '$cleanComment${existingIdx != -1 ? ' • [Edited]' : ''}',
      isVerified: true,
      images: images,
    );

    if (existingIdx != -1) {
      existingList[existingIdx] = review;
    } else {
      existingList.insert(0, review);
    }

    _customReviewsByProduct[product.id] = existingList;
    await _saveReviews();
    notifyListeners();

    if (ApiConfig.useLiveApi) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('lumora_auth_token');
        await ApiService().submitProductReview(
          productId: product.id,
          rating: rating,
          comment: cleanComment,
          images: images,
          token: token,
        );
      } catch (_) {}
    }

    return (
      ok: true,
      message: existingIdx != -1
          ? 'Your review has been updated.'
          : 'Thank you! Your verified review has been posted.',
    );
  }

  /// Dynamic product average rating and count (BUY-RATE-006)
  ({double averageRating, int totalReviews}) getProductRatingSummary(Product product) {
    final reviews = getReviewsForProduct(product);
    if (reviews.isEmpty) {
      return (averageRating: product.rating, totalReviews: product.reviewsCount);
    }
    final sum = reviews.fold<double>(0.0, (acc, r) => acc + r.rating);
    final avg = double.parse((sum / reviews.length).toStringAsFixed(1));
    return (averageRating: avg, totalReviews: reviews.length);
  }

  /// Delete the current user's review on a product (`Buyer/ProductReviewController@destroy`).
  Future<({bool ok, String message})> deleteReview({
    required String productId,
    required String reviewId,
    required String userId,
  }) async {
    final list = List<ProductReview>.from(
      _customReviewsByProduct[productId] ?? const [],
    );
    final idx = list.indexWhere(
      (r) => r.id == reviewId && (r.userId == userId || r.userId == null),
    );
    if (idx == -1) {
      return (ok: false, message: 'You are not authorized to delete this review.');
    }

    list.removeAt(idx);
    _customReviewsByProduct[productId] = list;
    _deletedReviewIds.add(reviewId);
    await _saveReviews();
    notifyListeners();

    return (ok: true, message: 'Your review has been deleted.');
  }

  /// Returns all delivered order items that have not yet been reviewed by [userId].
  List<({OrderModel order, OrderItem item})> getPendingReviewItems(String? userId) {
    final effectiveUserId = (userId == null || userId.isEmpty) ? 'buyer-1' : userId;
    final List<({OrderModel order, OrderItem item})> pending = [];
    final Set<String> seenKeys = {};

    for (final order in _orders) {
      if (order.normalizedWebStatus != 'delivered') continue;
      for (final item in order.items) {
        final pid = item.productId.isNotEmpty ? item.productId : item.productName;
        if (seenKeys.contains(pid)) continue;
        final hasReviewed = (_customReviewsByProduct[pid] ?? const []).any(
          (r) => r.userId == effectiveUserId || r.userId == 'buyer-1',
        );
        if (!hasReviewed) {
          seenKeys.add(pid);
          pending.add((order: order, item: item));
        }
      }
    }
    return pending;
  }

  /// Returns all custom reviews submitted by the buyer.
  List<ProductReview> getAllUserReviews(String? userId) {
    final List<ProductReview> result = [];
    for (final list in _customReviewsByProduct.values) {
      for (final r in list) {
        if (userId == null || userId.isEmpty || r.userId == userId || r.userId == 'buyer-1') {
          result.add(r);
        }
      }
    }
    return result;
  }
}
