import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../services/haptic_service.dart';
import 'luxury_snackbar.dart';
import 'order_tracking_modal.dart';
import 'voucher_selection_modal.dart';

class LumoraNotification {
  final String id;
  final String title;
  final String message;
  final String category; // 'Orders', 'Promos', 'Account'
  final String timestamp;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final OrderModel? order;
  final String? voucherCode;
  bool isRead;

  LumoraNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.timestamp,
    required this.icon,
    this.iconBg = const Color(0xFFF7ECE7),
    this.iconColor = AppColors.plum,
    this.order,
    this.voucherCode,
    this.isRead = false,
  });
}

class NotificationCenterModal {
  static final Set<String> _readNotificationIds = {};

  static String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  static LumoraNotification _buildOrderNotification(OrderModel order) {
    final norm = order.normalizedWebStatus;
    final cleanId = order.id.startsWith('#') ? order.id : '#${order.id}';
    final notifId = 'order-notif-${order.id}-$norm';
    final isRead = _readNotificationIds.contains(notifId);

    String title;
    String message;
    IconData icon;
    Color iconBg;
    Color iconColor;

    switch (norm) {
      case 'pending':
        title = 'Order Placed (Pending Seller) • $cleanId';
        message =
            'Your order is awaiting seller confirmation. Live rider tracking is not active yet and will only start once Out for Delivery.';
        icon = Icons.hourglass_top_rounded;
        iconBg = const Color(0xFFFFF8E1);
        iconColor = const Color(0xFFF57F17);
        break;
      case 'processing':
        title = 'Seller Processing Order • $cleanId';
        message =
            'The seller is preparing and inspecting your items. Live rider tracking will activate once the parcel is Out for Delivery.';
        icon = Icons.inventory_2_outlined;
        iconBg = const Color(0xFFFCE4EC);
        iconColor = AppColors.rose;
        break;
      case 'packed':
      case 'shipped':
      case 'at_sorting_center':
      case 'sorted':
        title = 'Order Packed & At Sorting Hub • $cleanId';
        message =
            'Seller has packed your order and forwarded it to the sorting center. Live map tracking will start once Out for Delivery.';
        icon = Icons.warehouse_outlined;
        iconBg = const Color(0xFFE3F2FD);
        iconColor = const Color(0xFF1565C0);
        break;
      case 'assigned_to_rider':
        title = 'Courier Rider Assigned • $cleanId';
        message =
            'A rider has been assigned at the hub. Live GPS tracking will activate as soon as the rider is Out for Delivery.';
        icon = Icons.two_wheeler_outlined;
        iconBg = const Color(0xFFE8EAF6);
        iconColor = const Color(0xFF3949AB);
        break;
      case 'out_for_delivery':
        title = 'Out for Delivery (Live Tracking) • $cleanId';
        message =
            'Your parcel is now Out for Delivery with ${order.driverName}! Tap to open Live GPS Rider Tracking.';
        icon = Icons.local_shipping_outlined;
        iconBg = const Color(0xFFE8F5E9);
        iconColor = const Color(0xFF2E7D32);
        break;
      case 'delivered':
        title = 'Order Delivered • $cleanId';
        message =
            'Your parcel has been safely delivered to ${order.deliveryAddress}. Tap to view order summary.';
        icon = Icons.verified_outlined;
        iconBg = const Color(0xFFE8F5E9);
        iconColor = const Color(0xFF2E7D32);
        break;
      case 'cancelled':
        title = 'Order Cancelled • $cleanId';
        message = 'This order was cancelled. Tap to view cancellation details.';
        icon = Icons.cancel_outlined;
        iconBg = const Color(0xFFFFEBEE);
        iconColor = Colors.redAccent;
        break;
      case 'returned':
      case 'return_requested':
        title = 'Return / Refund Update • $cleanId';
        message = 'Your return/refund request for $cleanId is being processed.';
        icon = Icons.assignment_return_outlined;
        iconBg = const Color(0xFFFFF3E0);
        iconColor = AppColors.orange;
        break;
      default:
        title = 'Order Update (${order.displayStatus}) • $cleanId';
        message =
            'Status: ${order.displayStatus}. Live tracking activates only when Out for Delivery.';
        icon = Icons.receipt_long_outlined;
        iconBg = const Color(0xFFF7ECE7);
        iconColor = AppColors.plum;
        break;
    }

    return LumoraNotification(
      id: notifId,
      title: title,
      message: message,
      category: 'Orders',
      timestamp: _formatRelativeTime(order.createdAt),
      icon: icon,
      iconBg: iconBg,
      iconColor: iconColor,
      order: order,
      isRead: isRead,
    );
  }

  static List<LumoraNotification> buildNotificationsForOrders(
    List<OrderModel> orders, {
    User? user,
    List<SavedPaymentMethod> walletMethods = const [],
  }) {
    final orderNotifs = orders.map(_buildOrderNotification).toList();

    final List<LumoraNotification> promoNotifs = VoucherModel.sampleVouchers
        .take(2)
        .map((v) {
      final id = 'promo-${v.code}';
      return LumoraNotification(
        id: id,
        title: '🎟️ ${v.title} (${v.code})',
        message: '${v.subtitle} • ${v.expiryText}. Tap to copy voucher code "${v.code}".',
        category: 'Promos',
        timestamp: 'Active Promo',
        icon: v.type == VoucherType.freeShipping
            ? Icons.local_shipping_outlined
            : Icons.confirmation_num_outlined,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: AppColors.orange,
        voucherCode: v.code,
        isRead: _readNotificationIds.contains(id),
      );
    }).toList();

    final List<LumoraNotification> accountNotifs = [];
    if (user != null) {
      final accId = 'acct-verified-${user.id}';
      accountNotifs.add(
        LumoraNotification(
          id: accId,
          title: 'Verified Buyer Account • ${user.fullName}',
          message:
              'Signed in as ${user.email}${user.fullAddress != "Philippines" ? " • Default address: ${user.fullAddress}" : ""}.',
          category: 'Account',
          timestamp: _formatRelativeTime(user.joinedDate),
          icon: Icons.verified_user_outlined,
          iconBg: const Color(0xFFE8F5E9),
          iconColor: const Color(0xFF2E7D32),
          isRead: _readNotificationIds.contains(accId),
        ),
      );
    }
    for (final m in walletMethods) {
      final mId = 'acct-wallet-${m.id}';
      accountNotifs.add(
        LumoraNotification(
          id: mId,
          title: '${m.name} Linked (${m.maskedNumber})',
          message: 'Saved payment method for ${m.accountName} is active for checkout.',
          category: 'Account',
          timestamp: 'Saved',
          icon: Icons.account_balance_wallet_outlined,
          iconBg: const Color(0xFFE0F2F1),
          iconColor: const Color(0xFF00695C),
          isRead: _readNotificationIds.contains(mId),
        ),
      );
    }

    return [...orderNotifs, ...promoNotifs, ...accountNotifs];
  }

  static void markRead(LumoraNotification n) {
    n.isRead = true;
    _readNotificationIds.add(n.id);
    syncUnreadCount();
  }

  static void markAllRead(List<LumoraNotification> list) {
    for (final n in list) {
      n.isRead = true;
      _readNotificationIds.add(n.id);
    }
    syncUnreadCount();
  }

  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  static void syncUnreadCount([
    List<OrderModel>? orders,
    User? user,
    List<SavedPaymentMethod>? walletMethods,
  ]) {
    if (orders != null) {
      final all = buildNotificationsForOrders(
        orders,
        user: user,
        walletMethods: walletMethods ?? const [],
      );
      unreadCountNotifier.value = all.where((n) => !n.isRead).length;
    }
  }

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _NotificationCenterSheet(),
    );
  }
}

class _NotificationCenterSheet extends StatefulWidget {
  const _NotificationCenterSheet();

  @override
  State<_NotificationCenterSheet> createState() =>
      _NotificationCenterSheetState();
}

class _NotificationCenterSheetState extends State<_NotificationCenterSheet> {
  String _selectedCategory = 'All';

  void _markAllAsRead(
    List<LumoraNotification> list,
    List<OrderModel> orders,
    User? user,
    List<SavedPaymentMethod> walletMethods,
  ) {
    HapticService.selection();
    setState(() {
      NotificationCenterModal.markAllRead(list);
    });
    NotificationCenterModal.syncUnreadCount(orders, user, walletMethods);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Orders', 'Promos', 'Account'];
    final auth = Provider.of<AuthProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final walletProvider = Provider.of<WalletProvider>(context);
    final allNotifications =
        NotificationCenterModal.buildNotificationsForOrders(
      orderProvider.orders,
      user: auth.currentUser,
      walletMethods: walletProvider.methods,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationCenterModal.syncUnreadCount(
        orderProvider.orders,
        auth.currentUser,
        walletProvider.methods,
      );
    });

    final filtered = allNotifications.where((n) {
      if (_selectedCategory == 'All') return true;
      return n.category == _selectedCategory;
    }).toList();

    final unreadCount = allNotifications.where((n) => !n.isRead).length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 42,
            height: 4.5,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 14),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.plum.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    size: 20,
                    color: AppColors.plum,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Notifications',
                            style: AppTextStyles.heading(
                              size: 18,
                              weight: FontWeight.w700,
                              color: AppColors.plum,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.orange,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '$unreadCount NEW',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Live order milestones, vouchers & account updates',
                        style: AppTextStyles.body(
                          size: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: () => _markAllAsRead(
                      allNotifications,
                      orderProvider.orders,
                      auth.currentUser,
                      walletProvider.methods,
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      'Mark read',
                      style: AppTextStyles.body(
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppColors.plum,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Centered Category Pills
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final cat = categories[idx];
                final isSelected = cat == _selectedCategory;
                return Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticService.selection();
                      setState(() => _selectedCategory = cat);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOutCubic,
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.plum : AppColors.cream,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: isSelected ? AppColors.plum : AppColors.line,
                          width: 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.plum.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        cat,
                        style: AppTextStyles.body(
                          size: 12,
                          weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.ink,
                        ).copyWith(height: 1.1),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.line),

          // Notifications List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_off_outlined,
                          size: 42,
                          color: AppColors.muted,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No $_selectedCategory notifications',
                          style: AppTextStyles.heading(
                            size: 15,
                            color: AppColors.plum,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You are all caught up with your updates.',
                          style: AppTextStyles.body(
                            size: 11.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final item = filtered[idx];
                      return GestureDetector(
                        onTap: () {
                          HapticService.selection();
                          setState(() => NotificationCenterModal.markRead(item));
                          NotificationCenterModal.syncUnreadCount(
                            orderProvider.orders,
                            auth.currentUser,
                            walletProvider.methods,
                          );
                          // Route to specific order tracking screen with the actual order status (BUY-TRK-007)
                          if (item.category == 'Orders') {
                            Navigator.of(context).pop();
                            final targetOrder = item.order ??
                                (orderProvider.orders.isNotEmpty
                                    ? orderProvider.orders.first
                                    : null);
                            if (targetOrder != null) {
                              OrderTrackingModal.show(
                                context,
                                order: targetOrder,
                                orderId: targetOrder.id,
                                trackingNumber: targetOrder.trackingNumber,
                                status: targetOrder.status,
                              );
                            }
                          } else if (item.voucherCode != null &&
                              item.voucherCode!.isNotEmpty) {
                            Clipboard.setData(
                              ClipboardData(text: item.voucherCode!),
                            );
                            LuxurySnackBar.show(
                              context,
                              message:
                                  'Voucher code "${item.voucherCode}" copied to clipboard!',
                              icon: Icons.copy_rounded,
                              iconColor: AppColors.flowGold,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: item.isRead
                                ? AppColors.blush1
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: item.isRead
                                  ? AppColors.line
                                  : AppColors.plum.withValues(alpha: 0.25),
                              width: item.isRead ? 1.0 : 1.2,
                            ),
                            boxShadow: item.isRead
                                ? null
                                : [
                                    BoxShadow(
                                      color: AppColors.plum.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: item.iconBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  item.icon,
                                  color: item.iconColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: AppTextStyles.body(
                                              size: 13,
                                              weight: item.isRead
                                                  ? FontWeight.w600
                                                  : FontWeight.w700,
                                              color: AppColors.plum,
                                            ),
                                          ),
                                        ),
                                        if (!item.isRead) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppColors.orange,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.message,
                                      style: AppTextStyles.body(
                                        size: 11.5,
                                        color: AppColors.ink,
                                      ).copyWith(height: 1.35),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.timestamp,
                                      style: AppTextStyles.body(
                                        size: 10.5,
                                        color: AppColors.muted,
                                        weight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
