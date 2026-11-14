import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/order_provider.dart';
import '../services/api_service.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import 'live_map_tracker.dart';
import 'luxury_snackbar.dart';

class OrderTrackingModal {
  static Future<void> show(
    BuildContext context, {
    OrderModel? order,
    String orderId = 'LUM-94821',
    String trackingNumber = 'PH-LMR-948210',
    String status = 'pending',
    String? address,
    Product? sampleProduct,
  }) {
    final effectiveOrder = order ??
        OrderModel(
          id: orderId,
          trackingNumber: trackingNumber,
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          status: status,
          totalAmount: 1879.00,
          deliveryAddress: address ?? 'Unit 18B, Two Serendra, 26th St., Bonifacio Global City, Taguig City 1634',
          recipientName: 'Customer',
          paymentMethod: 'Cash on Delivery (COD)',
          items: [],
          progress: status.toLowerCase() == 'completed' || status.toLowerCase() == 'delivered'
              ? 1.0
              : (status.toLowerCase() == 'out_for_delivery' || status.toLowerCase() == 'out for delivery' ? 0.80 : 0.15),
        );

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _OrderTrackingContent(order: effectiveOrder),
    );
  }
}

class _OrderTrackingContent extends StatefulWidget {
  final OrderModel order;

  const _OrderTrackingContent({required this.order});

  @override
  State<_OrderTrackingContent> createState() => _OrderTrackingContentState();
}

class _OrderTrackingContentState extends State<_OrderTrackingContent> {
  late OrderModel _order;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _refreshLiveTracking(silent: true);
  }

  Future<void> _refreshLiveTracking({bool silent = false}) async {
    if (!silent) {
      setState(() => _isRefreshing = true);
      HapticService.selection();
    }
    try {
      final oldId = _order.id;
      OrderModel? updated;
      try {
        final prov = Provider.of<OrderProvider>(context, listen: false);
        updated = await prov.refreshOrderTracking(oldId);
      } catch (_) {
        updated = await ApiService().fetchOrderTracking(orderId: oldId);
      }
      if (updated != null && mounted) {
        setState(() {
          _order = updated!;
        });
        if (!silent) {
          LuxurySnackBar.show(
            context,
            message: 'Tracking status synchronized (${updated.displayStatus}).',
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF2E7D32),
          );
        }
      }
    } catch (e) {
      debugPrint('OrderTrackingModal refresh error: $e');
    } finally {
      if (mounted && !silent) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  String _monthName(int month) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return m[month - 1];
    return '';
  }

  Widget _buildStatusBadge(OrderModel o) {
    final norm = o.normalizedWebStatus;
    Color bg;
    Color border;
    Color dot;
    String label;

    switch (norm) {
      case 'out_for_delivery':
        bg = const Color(0xFFE8F5E9);
        border = const Color(0xFFA5D6A7);
        dot = const Color(0xFF2E7D32);
        label = 'LIVE GPS';
        break;
      case 'delivered':
        bg = const Color(0xFFE8F5E9);
        border = const Color(0xFFA5D6A7);
        dot = const Color(0xFF2E7D32);
        label = 'DELIVERED';
        break;
      case 'shipped':
        bg = const Color(0xFFE0F2F1);
        border = const Color(0xFF80CBC4);
        dot = const Color(0xFF00796B);
        label = 'IN TRANSIT';
        break;
      case 'packed':
      case 'processing':
        bg = const Color(0xFFE3F2FD);
        border = const Color(0xFF90CAF9);
        dot = const Color(0xFF1976D2);
        label = 'PACKED';
        break;
      case 'cancelled':
      case 'returned':
        bg = const Color(0xFFFFEBEE);
        border = const Color(0xFFFFCDD2);
        dot = const Color(0xFFD32F2F);
        label = norm == 'returned' ? 'RETURNED' : 'CANCELLED';
        break;
      case 'pending':
      default:
        bg = const Color(0xFFFFF8E1);
        border = const Color(0xFFFFE082);
        dot = const Color(0xFFF57F17);
        label = 'IN PREPARATION';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: dot,
            ),
          ),
        ],
      ),
    );
  }

  void _openCallDriverDialog(BuildContext context) {
    HapticService.mediumImpact();
    showDialog(
      context: context,
      builder: (dialogCtx) => _DriverCallDialog(
        driverName: _order.driverName,
        driverPhone: _order.driverPhone,
        vehiclePlate: _order.vehiclePlate,
      ),
    );
  }

  void _openChatDriverDialog(BuildContext context) {
    HapticService.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _DriverChatModal(
        driverName: _order.driverName,
        orderId: _order.id,
        deliveryAddress: _order.deliveryAddress,
      ),
    );
  }

  Widget _buildLogisticsInfoBadge({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.gold.withValues(alpha: 0.08) : AppColors.cream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlight
              ? AppColors.gold.withValues(alpha: 0.35)
              : AppColors.line.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: isHighlight ? AppColors.gold : AppColors.plum),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1.5),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isHighlight ? AppColors.plum : const Color(0xFF2D2429),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreparationCard(OrderModel o) {
    final norm = o.normalizedWebStatus;
    final isCancelled = norm == 'cancelled' || norm == 'returned';

    final headline = o.statusHeadline ??
        (norm == 'packed'
            ? 'Order Packed & Ready for Handover'
            : (norm == 'pending' || norm == 'processing'
                ? 'Your order is being prepared'
                : (norm == 'shipped'
                    ? 'Your order is on its way'
                    : (norm == 'out_for_delivery'
                        ? 'Your order is out for delivery'
                        : (norm == 'delivered'
                            ? 'Delivered'
                            : (norm == 'cancelled'
                                ? 'Order cancelled'
                                : (norm == 'returned' ? 'Order returned' : o.displayStatus)))))));

    final explanation = o.statusExplanation ??
        (norm == 'packed'
            ? 'Order has been packed by the seller and is ready for handoff to Lumora Logistics.'
            : (norm == 'pending'
                ? 'The seller is getting your order ready.'
                : (norm == 'processing'
                    ? 'Your order is being prepared for handoff to Lumora Logistics.'
                    : (norm == 'shipped'
                        ? 'Lumora Logistics is moving your parcel toward its destination.'
                        : (norm == 'out_for_delivery'
                            ? 'Your parcel is with the courier and should arrive soon.'
                            : (norm == 'delivered'
                                ? 'Your parcel has been delivered to the address on your order.'
                                : (norm == 'cancelled'
                                    ? 'This order has been cancelled.'
                                    : (norm == 'returned'
                                        ? 'This order has been returned.'
                                        : 'We will keep your order status up to date here.'))))))));

    IconData icon;
    Color accentColor;

    if (isCancelled) {
      icon = Icons.cancel_outlined;
      accentColor = const Color(0xFFD32F2F);
    } else if (norm == 'delivered') {
      icon = Icons.check_circle_outline;
      accentColor = const Color(0xFF2E7D32);
    } else if (norm == 'shipped' || norm == 'out_for_delivery') {
      icon = Icons.local_shipping_outlined;
      accentColor = const Color(0xFF00796B);
    } else if (norm == 'packed' || norm == 'processing' || norm == 'at_sorting_center' || norm == 'sorted') {
      icon = Icons.inventory_2_outlined;
      accentColor = AppColors.rose;
    } else {
      icon = Icons.storefront_outlined;
      accentColor = AppColors.plum;
    }

    final hasPaymentRef = o.paymentReferenceLast6 != null && o.paymentReferenceLast6!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.plum.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: AppTextStyles.body(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: AppColors.plum,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      explanation,
                      style: AppTextStyles.body(
                        size: 11,
                        color: AppColors.muted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (o.estimatedDelivery != null && !isCancelled && norm != 'delivered') ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEAD8CE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'EST. DELIVERY',
                        style: TextStyle(
                          fontSize: 8,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_monthName(o.estimatedDelivery!.month)} ${o.estimatedDelivery!.day}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.plum,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (!isCancelled && norm != 'delivered') ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line.withValues(alpha: 0.7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.plum),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Live GPS map and rider tracking will only activate once the seller processes your order and the rider is Out for Delivery.',
                      style: AppTextStyles.body(size: 10.5, color: AppColors.plum),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (hasPaymentRef) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 14, color: Color(0xFF007DFE)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'InstaPay / GCash Ref: •••• ${o.paymentReferenceLast6}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF007DFE),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: const Text(
                    'Pending Verification',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFFF57F17)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWebProgressBar(OrderModel o) {
    final norm = o.normalizedWebStatus;
    if (norm == 'cancelled' || norm == 'returned') return const SizedBox.shrink();

    // 0: Placed, 1: Packed, 2: Shipped, 3: Out for delivery, 4: Delivered
    int currentRank = 0;
    if (norm == 'delivered') {
      currentRank = 4;
    } else if (norm == 'out_for_delivery') {
      currentRank = 3;
    } else if (norm == 'shipped') {
      currentRank = 2;
    } else if (norm == 'packed' ||
        norm == 'processing' ||
        norm == 'sorted' ||
        norm == 'at_sorting_center' ||
        norm == 'assigned_to_rider') {
      currentRank = 1;
    }

    final steps = [
      {'label': 'Placed', 'key': 'pending'},
      {'label': 'Packed', 'key': 'packed'},
      {'label': 'Shipped', 'key': 'shipped'},
      {'label': 'Out for delivery', 'key': 'out_for_delivery'},
      {'label': 'Delivered', 'key': 'delivered'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ORDER PROGRESS',
                style: AppTextStyles.body(size: 10, weight: FontWeight.w700, color: AppColors.rose),
              ),
              Text(
                '${currentRank + 1} of 5 Completed',
                style: AppTextStyles.body(size: 10, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                final stepIndex = index ~/ 2;
                final isPassed = stepIndex < currentRank;
                return Expanded(
                  child: Container(
                    height: 2.5,
                    color: isPassed ? AppColors.rose : AppColors.line,
                  ),
                );
              }
              final stepIndex = index ~/ 2;
              final isPassed = stepIndex < currentRank;
              final isCurrent = stepIndex == currentRank;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isPassed
                          ? AppColors.rose
                          : (isCurrent ? AppColors.plum : Colors.white),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isPassed
                            ? AppColors.rose
                            : (isCurrent ? AppColors.plum : AppColors.line),
                        width: 2,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: AppColors.plum.withValues(alpha: 0.25),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isPassed
                          ? const Icon(Icons.check, size: 13, color: Colors.white)
                          : Text(
                              '${stepIndex + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCurrent ? Colors.white : AppColors.muted,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 54,
                    child: Text(
                      steps[stepIndex]['label']!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrent ? AppColors.plum : AppColors.muted,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryUpdates(OrderModel o) {
    if (o.statusHistory.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Delivery Updates',
              style: AppTextStyles.heading(
                size: 16,
                weight: FontWeight.w700,
                color: AppColors.plum,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.rose.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${o.statusHistory.length} Recorded',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.plum,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: AppColors.plum.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: o.statusHistory.asMap().entries.map((entry) {
              final idx = entry.key;
              final hist = entry.value;
              final isLatest = idx == 0;
              final isLast = idx == o.statusHistory.length - 1;

              final title = hist.trackingLabel ??
                  (hist.status.replaceAll('_', ' ').toUpperCase());

              final timeStr = hist.formattedTime ??
                  '${hist.createdAt.month}/${hist.createdAt.day}/${hist.createdAt.year} ${hist.createdAt.hour.toString().padLeft(2, '0')}:${hist.createdAt.minute.toString().padLeft(2, '0')} PHT';

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isLatest ? AppColors.plum : const Color(0xFFF8E9E1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isLatest ? AppColors.plum : AppColors.rose,
                              width: 1.5,
                            ),
                            boxShadow: isLatest
                                ? [
                                    BoxShadow(
                                      color: AppColors.plum.withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Icon(
                              isLatest ? Icons.circle : Icons.check,
                              size: isLatest ? 7 : 11,
                              color: isLatest ? Colors.white : AppColors.plum,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: const Color(0xFFE8DDD6),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: AppTextStyles.body(
                                      size: 12.5,
                                      weight: isLatest ? FontWeight.w700 : FontWeight.w600,
                                      color: AppColors.plum,
                                    ),
                                  ),
                                ),
                                if (isLatest)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1E7ED),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: const Text(
                                      'Latest update',
                                      style: TextStyle(
                                        color: AppColors.plum,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (hist.notes.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                hist.notes,
                                style: AppTextStyles.body(size: 11, color: const Color(0xFF53494B), height: 1.3),
                              ),
                            ],
                            if (hist.location != null && hist.location!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.place_outlined, size: 12, color: AppColors.muted),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      hist.location!,
                                      style: AppTextStyles.body(size: 10.5, color: AppColors.muted),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (hist.courierName != null && hist.courierName!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.delivery_dining_outlined, size: 12, color: AppColors.muted),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Courier: ${hist.courierName}',
                                      style: AppTextStyles.body(size: 10.5, color: AppColors.muted),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              timeStr,
                              style: AppTextStyles.body(size: 9.5, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderId = _order.id;
    final trackingNumber = _order.trackingNumber;
    final normalized = _order.normalizedWebStatus;
    final isCompleted = normalized == 'delivered';
    final isOutForDelivery = normalized == 'out_for_delivery';
    final isAssignedToRider = normalized == 'assigned_to_rider';
    final isSorted = normalized == 'sorted';
    final isAtSortingCenter = normalized == 'at_sorting_center';
    final isPacked = normalized == 'packed' || normalized == 'shipped';

    final doneStep1 = true;
    final doneStep2 = isPacked || isAtSortingCenter || isSorted || isAssignedToRider || isOutForDelivery || isCompleted;
    final doneStep3 = isAtSortingCenter || isSorted || isAssignedToRider || isOutForDelivery || isCompleted;
    final doneStep4 = isSorted || isAssignedToRider || isOutForDelivery || isCompleted;
    final doneStep5 = isAssignedToRider || isOutForDelivery || isCompleted;
    final doneStep6 = isOutForDelivery || isCompleted;
    final doneStep7 = isCompleted;

    final steps = [
      {
        'title': 'Order Placed & Confirmed',
        'time': 'Stage 1 • Confirmed',
        'desc': 'Payment confirmed. Verified order transmitted to boutique atelier.',
        'done': doneStep1,
        'current': normalized == 'pending' || normalized == 'processing',
      },
      {
        'title': 'Packed & Inspected by Atelier',
        'time': 'Stage 2 • Quality Assured',
        'desc': 'Passed quality inspection & packaged with signature Lumora luxury seal.',
        'done': doneStep2,
        'current': isPacked,
      },
      {
        'title': 'Arrived at Central Sorting Hub',
        'time': 'Stage 3 • ${_order.computedSortingHub}',
        'desc': 'Transferred to automated barcode scanner & parcel weight verifier.',
        'done': doneStep3,
        'current': isAtSortingCenter,
      },
      {
        'title': 'Sorted by Destination Area',
        'time': 'Stage 4 • ${_order.computedAreaCode}',
        'desc': 'Dispatched into designated Laguna delivery channel for regional transit.',
        'done': doneStep4,
        'current': isSorted,
      },
      {
        'title': 'Assigned to Dedicated Courier',
        'time': doneStep5
            ? 'Stage 5 • ${_order.computedAssignedRider} (${_order.driverName})'
            : 'Stage 5 • Pending Rider Assignment',
        'desc': doneStep5
            ? 'Parcel handed over to designated delivery officer for dispatch loadout.'
            : 'Courier rider will be assigned after seller processing and hub sorting.',
        'done': doneStep5,
        'current': isAssignedToRider,
      },
      {
        'title': 'Out for Delivery (Live Tracking)',
        'time': doneStep6 ? 'Stage 6 • Active Transit (Live GPS)' : 'Stage 6 • Activates When Out for Delivery',
        'desc': doneStep6
            ? '${_order.driverName} (${_order.vehiclePlate}) is navigating to your address.'
            : 'Live GPS map tracking will start once the rider is Out for Delivery.',
        'done': doneStep6,
        'current': isOutForDelivery,
      },
      {
        'title': 'Delivered to Recipient',
        'time': isCompleted ? 'Completed' : 'Estimated Arrival Today',
        'desc': isCompleted
            ? 'Package safely received and signed for at ${_order.deliveryAddress}.'
            : 'Recipient contactless signature turnover upon arrival.',
        'done': doneStep7,
        'current': false,
      },
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),

          // Modal Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _order.hasActiveRider ? 'Live Order Tracking' : 'Order Status & Tracking',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.heading(
                                size: 19,
                                weight: FontWeight.w700,
                                color: AppColors.plum,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(_order),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Order ${orderId.startsWith('#') ? orderId : '#$orderId'} • ${_order.recipientName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(size: 11.5, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                // ↻ Live Refresh Button
                IconButton(
                  tooltip: 'Sync tracking with website',
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.plum),
                        )
                      : const Icon(Icons.refresh, color: AppColors.plum, size: 20),
                  onPressed: _isRefreshing ? null : () => _refreshLiveTracking(),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.plum),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.line, height: 1),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_order.hasActiveRider) ...[
                    // 1. GENUINE LIVE GOOGLE MAPS TRACKER (Natural Pinch-to-Zoom & Pan)
                    LiveMapTracker(
                      order: _order,
                      height: 290,
                    ),

                    const SizedBox(height: 16),

                    // 2. ASSIGNED COURIER DRIVER VIP CARD (Call & Message Actions)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.line),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.plum.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Driver Avatar with Verified Badge
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppColors.plum, AppColors.rose],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.person, color: Colors.white, size: 26),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.verified, size: 14, color: Color(0xFF2E7D32)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _order.driverName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.body(size: 13.5, weight: FontWeight.w700, color: AppColors.plum),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: AppColors.gold.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.star_rounded, size: 11, color: AppColors.gold),
                                              SizedBox(width: 2),
                                              Text('4.9', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.plum)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_order.courierName} • ${_order.vehiclePlate}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.body(size: 11, color: AppColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              // Call Driver Button
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.plum,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.phone, size: 15),
                                  label: const Text('Call Driver', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  onPressed: () => _openCallDriverDialog(context),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Message Driver Button
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.plum, width: 1.2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  icon: const Icon(Icons.chat_bubble_outline, size: 15, color: AppColors.plum),
                                  label: const Text('Message', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.plum)),
                                  onPressed: () => _openChatDriverDialog(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    _buildPreparationCard(_order),
                    const SizedBox(height: 16),
                  ],

                  // 2.3 WEB 5-STEP ORDER PROGRESS BAR
                  _buildWebProgressBar(_order),
                  const SizedBox(height: 16),

                  // 2.5 LAGUNA LOGISTICS & SORTING HUB ROUTING CARD (ERP Document 1 Compliance)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.line),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.plum.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.hub_outlined, size: 16, color: AppColors.gold),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Laguna Logistics & Sorting Center',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.body(
                                      size: 12.5,
                                      weight: FontWeight.w700,
                                      color: AppColors.plum,
                                    ),
                                  ),
                                  Text(
                                    'ERP Smart Routing & Destination Area',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.body(
                                      size: 10,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: doneStep3
                                    ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                                    : const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: doneStep3
                                      ? const Color(0xFF2E7D32).withValues(alpha: 0.3)
                                      : const Color(0xFFFFE082),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    doneStep3 ? Icons.check_circle_outline : Icons.schedule,
                                    size: 11,
                                    color: doneStep3 ? const Color(0xFF2E7D32) : const Color(0xFFF57F17),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    doneStep3 ? 'Verified Hub' : 'Awaiting Seller',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: doneStep3 ? const Color(0xFF2E7D32) : const Color(0xFFF57F17),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: AppColors.line, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildLogisticsInfoBadge(
                                icon: Icons.warehouse_outlined,
                                label: 'Central Hub',
                                value: doneStep2 ? _order.computedSortingHub : 'Pending Seller Handover',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildLogisticsInfoBadge(
                                icon: Icons.place_outlined,
                                label: 'Destination Area',
                                value: _order.computedAreaCode,
                                isHighlight: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildLogisticsInfoBadge(
                                icon: Icons.delivery_dining_outlined,
                                label: 'Rider Designation',
                                value: doneStep5
                                    ? '${_order.computedAssignedRider} • Regional Specialist'
                                    : 'Assigned When Out for Delivery',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildLogisticsInfoBadge(
                                icon: Icons.local_shipping_outlined,
                                label: 'Vehicle Unit',
                                value: doneStep5
                                    ? _order.vehiclePlate.split('(').first.trim()
                                    : 'Pending Rider Dispatch',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. TRACKING NUMBER BANNER
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.plum, Color(0xFF5A2748)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.plum.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.qr_code_2, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tracking Number',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10.5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                trackingNumber,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            HapticService.selection();
                            await Clipboard.setData(ClipboardData(text: trackingNumber));
                            if (context.mounted) {
                              LuxurySnackBar.show(
                                context,
                                message: 'Tracking number copied to clipboard!',
                                icon: Icons.check,
                                iconColor: AppColors.gold,
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.copy, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Copy',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3.5 REAL DELIVERY UPDATES FROM WEBSITE DATABASE
                  _buildDeliveryUpdates(_order),

                  const SizedBox(height: 22),

                  // 4. DELIVERY TIMELINE (LOGISTICS MILESTONES)
                  Text(
                    'Logistics Milestones',
                    style: AppTextStyles.heading(
                      size: 16,
                      weight: FontWeight.w700,
                      color: AppColors.plum,
                    ),
                  ),
                  const SizedBox(height: 14),

                  ...steps.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final step = entry.value;
                    final isDone = step['done'] == true;
                    final isCurrent = step['current'] == true;
                    final isLast = idx == steps.length - 1;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppColors.orange
                                      : (isDone ? AppColors.plum : AppColors.line),
                                  shape: BoxShape.circle,
                                  boxShadow: isCurrent
                                      ? [
                                          BoxShadow(
                                            color: AppColors.orange.withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Icon(
                                    isDone ? Icons.check : (isCurrent ? Icons.circle : Icons.circle_outlined),
                                    size: isDone ? 13 : 8,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: isDone ? AppColors.plum : AppColors.line,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          step['title'] as String,
                                          style: AppTextStyles.body(
                                            size: 13,
                                            weight: isCurrent ? FontWeight.w700 : (isDone ? FontWeight.w600 : FontWeight.w500),
                                            color: isCurrent ? AppColors.orange : (isDone ? AppColors.ink : AppColors.muted),
                                          ),
                                        ),
                                      ),
                                      if (isCurrent)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.orange.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'CURRENT',
                                            style: TextStyle(
                                              color: AppColors.orange,
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    step['time'] as String,
                                    style: AppTextStyles.body(size: 10.5, color: AppColors.muted),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    step['desc'] as String,
                                    style: AppTextStyles.body(size: 11.5, color: AppColors.ink, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DRIVER CALL SIMULATION DIALOG
// ============================================================================

class _DriverCallDialog extends StatefulWidget {
  final String driverName;
  final String driverPhone;
  final String vehiclePlate;

  const _DriverCallDialog({
    required this.driverName,
    required this.driverPhone,
    required this.vehiclePlate,
  });

  @override
  State<_DriverCallDialog> createState() => _DriverCallDialogState();
}

class _DriverCallDialogState extends State<_DriverCallDialog> {
  bool _isAnswered = false;
  bool _isMuted = false;
  bool _isSpeaker = true;
  int _callSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Simulate rider picking up after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _isAnswered = true);
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _callSeconds++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCallTime(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1020),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Driver Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.plum, AppColors.rose],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 3),
              ),
              child: const Center(
                child: Icon(Icons.person, color: Colors.white, size: 44),
              ),
            ),
            const SizedBox(height: 18),

            Text(
              widget.driverName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.driverPhone,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isAnswered
                  ? 'Connected • ${_formatCallTime(_callSeconds)}'
                  : 'Calling Lumora VIP Courier...',
              style: TextStyle(
                color: _isAnswered ? const Color(0xFF81C784) : AppColors.gold,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 32),

            // In-call buttons (Mute, Speaker)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _callOptionButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  label: _isMuted ? 'Muted' : 'Mute',
                  isActive: _isMuted,
                  onTap: () => setState(() => _isMuted = !_isMuted),
                ),
                _callOptionButton(
                  icon: _isSpeaker ? Icons.volume_up : Icons.volume_off,
                  label: 'Speaker',
                  isActive: _isSpeaker,
                  onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // End Call Button
            GestureDetector(
              onTap: () {
                HapticService.mediumImpact();
                Navigator.of(context).pop();
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.call_end, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _callOptionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isActive ? AppColors.plum : Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DRIVER DIRECT CHAT MODAL
// ============================================================================

class _DriverChatModal extends StatefulWidget {
  final String driverName;
  final String orderId;
  final String deliveryAddress;

  const _DriverChatModal({
    required this.driverName,
    required this.orderId,
    required this.deliveryAddress,
  });

  @override
  State<_DriverChatModal> createState() => _DriverChatModalState();
}

class _DriverChatModalState extends State<_DriverChatModal> {
  final TextEditingController _msgController = TextEditingController();
  late final List<Map<String, dynamic>> _messages;

  @override
  void initState() {
    super.initState();
    _messages = [
      {
        'sender': 'driver',
        'text': 'Magandang araw po ma\'am/sir! Papunta na po ako sa ${widget.deliveryAddress} with your Lumora package. Estimated 14 minutes po.',
        'time': '5:22 PM',
      },
    ];
  }

  final List<String> _quickReplies = [
    'Kuya, paki-iwan na lang sa lobby guard / concierge.',
    'Pakitawagan po ako pagdating ninyo.',
    'Nandito na po ako sa baba naghihintay.',
    'Sige po Kuya, ingat sa biyahe!',
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    HapticService.lightImpact();
    setState(() {
      _messages.add({
        'sender': 'user',
        'text': text.trim(),
        'time': 'Just now',
      });
      _msgController.clear();
    });

    // Auto driver response
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'sender': 'driver',
            'text': 'Noted po Ma\'am/Sir! Safe delivery po agad. Salamat po!',
            'time': 'Just now',
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.75,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.plum,
                  radius: 18,
                  child: Icon(Icons.two_wheeler, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.driverName, style: AppTextStyles.heading(size: 15, weight: FontWeight.w700, color: AppColors.plum)),
                      Text(
                        'Order ${widget.orderId.startsWith('#') ? widget.orderId : '#${widget.orderId}'} • Lumora Express',
                        style: AppTextStyles.body(size: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.plum),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.line, height: 1),

          // Messages list
          Expanded(
            child: ListView.separated(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final m = _messages[idx];
                final isMe = m['sender'] == 'user';
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.plum : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: isMe ? null : Border.all(color: AppColors.line),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['text'] as String,
                          style: TextStyle(
                            color: isMe ? Colors.white : AppColors.ink,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          m['time'] as String,
                          style: TextStyle(
                            color: isMe ? Colors.white70 : AppColors.muted,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Quick replies carousel
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              itemCount: _quickReplies.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final q = _quickReplies[idx];
                return ActionChip(
                  label: Text(q, style: const TextStyle(fontSize: 10.5, color: AppColors.plum)),
                  backgroundColor: AppColors.blush1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  side: const BorderSide(color: AppColors.line),
                  onPressed: () => _sendMessage(q),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Message input bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'Type a message to courier rider...',
                      hintStyle: AppTextStyles.body(size: 12, color: AppColors.muted),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(99),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.plum,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.send, size: 18),
                  onPressed: () => _sendMessage(_msgController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
