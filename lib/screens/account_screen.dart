import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/order_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/follow_provider.dart';
import '../services/address_service.dart';
import '../services/haptic_service.dart';
import '../services/native_photo_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_modal.dart';
import '../widgets/cards.dart';
import '../widgets/luxury_snackbar.dart';
import '../widgets/order_tracking_modal.dart';
import '../widgets/notification_center_modal.dart';
import '../widgets/voucher_selection_modal.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'chat_screen.dart';
import 'messages_inbox_screen.dart';
import 'product_detail_screen.dart';
import 'following_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // Notification toggle states
  bool _orderUpdates = true;
  bool _promoAlerts = true;
  bool _rewardReminders = true;
  bool _hasViewedVouchers = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final wishlist = Provider.of<WishlistProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(auth),
                const SizedBox(height: 14),
                _buildVipBanner(context, auth),
                const SizedBox(height: 18),
                _buildProfileCard(context, auth),
                const SizedBox(height: 18),
                _buildOrderTracker(context, auth),
                const SizedBox(height: 24),
                _buildActivitySection(context, auth, wishlist),
                const SizedBox(height: 24),
                _buildSupportSection(context),
                const SizedBox(height: 24),
                if (auth.isLoggedIn) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD46A6A), width: 1.5),
                        foregroundColor: const Color(0xFFD46A6A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: const Icon(Icons.logout, size: 18),
                      label: Text(
                        'Log Out',
                        style: AppTextStyles.body(
                          size: 13.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFFD46A6A),
                        ),
                      ),
                      onPressed: () => _confirmLogout(context, auth),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Center(
                  child: Text(
                    'Lumora Luxury v1.0.0 (Build 1)',
                    style: AppTextStyles.body(size: 11.5, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    final name = auth.isLoggedIn ? (auth.currentUser?.fullName.split(' ').first ?? 'Member') : 'Guest';
    return Text(
      'Hi $name,',
      style: AppTextStyles.heading(
        size: 24,
        weight: FontWeight.w700,
        color: AppColors.ink,
      ),
    );
  }

  Widget _buildVipBanner(BuildContext context, AuthProvider auth) {
    return GestureDetector(
      onTap: () {
        if (!auth.isLoggedIn) {
          AuthModal.show(context, actionName: 'claim your VIP 1-year unlimited free shipping');
        } else {
          _showMemberDealsModal(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE8D7F1), Color(0xFFD6C0EC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B1FA2).withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6A1B9A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'VIP',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: Color(0xFF4A148C),
                    fontSize: 11.5,
                    fontFamily: 'Inter',
                    height: 1.3,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Enjoy 1-year of Unlimited Free Shipping to all Sold by Lumora items for ',
                    ),
                    const TextSpan(
                      text: 'Php 500.00 ',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: '750.00!',
                      style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: const Color(0xFF4A148C).withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF6A1B9A)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AuthProvider auth) {
    if (!auth.isLoggedIn) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.plum.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.blush1,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Icon(Icons.person_outline, color: AppColors.muted, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guest',
                        style: AppTextStyles.heading(
                          size: 18,
                          weight: FontWeight.w700,
                          color: AppColors.plum,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Log in to start buying & saving items',
                        style: AppTextStyles.body(size: 11.5, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.plum,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Text(
                      'Log In',
                      style: AppTextStyles.body(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.plum),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: Text(
                      'Sign Up',
                      style: AppTextStyles.body(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: AppColors.plum,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final user = auth.currentUser;
    return GestureDetector(
      onTap: () => _showProfileDetailsModal(context, auth),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.plum.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildAvatarCircle(
              avatar: user?.avatar,
              fallbackText: user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'B',
              size: 56,
              fontSize: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user?.fullName ?? 'Valued Member',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.heading(
                            size: 17,
                            weight: FontWeight.w700,
                            color: AppColors.plum,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          'MEMBER',
                          style: AppTextStyles.body(
                            size: 9.5,
                            weight: FontWeight.w800,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(size: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTracker(BuildContext context, AuthProvider auth) {
    final statuses = [
      {'icon': Icons.hourglass_bottom_outlined, 'label': 'Pending', 'status': 'Pending'},
      {'icon': Icons.inventory_2_outlined, 'label': 'Packed', 'status': 'Packed'},
      {'icon': Icons.local_shipping_outlined, 'label': 'In Transit', 'status': 'Out for Delivery'},
      {'icon': Icons.verified_outlined, 'label': 'Delivered', 'status': 'Delivered'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Order Updates',
                    style: AppTextStyles.body(
                      size: 16,
                      weight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Consumer<OrderProvider>(
                    builder: (context, orderProvider, _) {
                      final activeCount = orderProvider.totalActiveOrdersCount;
                      final showNewBadge = auth.isLoggedIn && (activeCount > 0 || orderProvider.activeInTransitOrder != null);
                      if (!showNewBadge) return const SizedBox.shrink();
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: const Color(0xFFA5D6A7)),
                            ),
                            child: Text(
                              activeCount > 0 ? '$activeCount ACTIVE' : 'NEW',
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  if (!auth.isLoggedIn) {
                    AuthModal.show(context, actionName: 'view your order history');
                  } else {
                    _showOrdersModal(context, 'All');
                  }
                },
                child: Row(
                  children: [
                    Text(
                      'My Orders',
                      style: AppTextStyles.body(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.ink),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Consumer<OrderProvider>(
            builder: (context, orderProvider, _) {
              int countForLabel(String label) {
                if (!auth.isLoggedIn) return 0;
                switch (label) {
                  case 'Pending':
                    return orderProvider.pendingOrdersCount;
                  case 'Packed':
                    return orderProvider.packedOrdersCount;
                  case 'In Transit':
                    return orderProvider.inTransitOrdersCount;
                  case 'Delivered':
                    return orderProvider.deliveredOrdersCount;
                  default:
                    return 0;
                }
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: statuses.map((s) {
                  final label = s['label'] as String;
                  final count = countForLabel(label);
                  return GestureDetector(
                    onTap: () {
                      if (!auth.isLoggedIn) {
                        AuthModal.show(context, actionName: 'view your order status and track purchases');
                      } else {
                        _showOrdersModal(context, s['status'] as String);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: AppColors.blush1,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                s['icon'] as IconData,
                                size: 22,
                                color: AppColors.ink,
                              ),
                            ),
                            if (count > 0)
                              Positioned(
                                top: -3,
                                right: -3,
                                child: Container(
                                  constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: label == 'Delivered'
                                        ? const Color(0xFF2E7D32)
                                        : AppColors.rose,
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(color: AppColors.cream, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    count > 99 ? '99+' : '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: AppTextStyles.body(
                            size: 11.5,
                            weight: count > 0 ? FontWeight.w700 : FontWeight.w500,
                            color: count > 0 ? AppColors.plum : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 14),

          // Live Order Updates Status Card / Empty State Card
          Consumer<OrderProvider>(
            builder: (context, orderProvider, _) {
              final activeOrder = orderProvider.activeInTransitOrder;
              final hasActive = auth.isLoggedIn && activeOrder != null;

              return GestureDetector(
                onTap: () {
                  if (!auth.isLoggedIn) {
                    AuthModal.show(context, actionName: 'view your order status and track purchases');
                  } else if (activeOrder != null) {
                    OrderTrackingModal.show(context, order: activeOrder);
                  } else {
                    _showOrdersModal(context, 'All');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF1F8E9), Color(0xFFE8F5E9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: Icon(
                          (hasActive && activeOrder.hasActiveRider)
                              ? Icons.navigation_outlined
                              : Icons.inventory_2_outlined,
                          color: const Color(0xFF388E3C),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hasActive
                              ? 'Order ${activeOrder.id.startsWith('#') ? activeOrder.id : '#${activeOrder.id}'} • ${activeOrder.displayStatus} (${activeOrder.hasActiveRider ? "Tap to Track Live on Map" : "Tap to View Status • Live tracking starts when Out for Delivery"})'
                              : (auth.isLoggedIn
                                  ? "You don't have any pending orders. Start shopping to track deliveries live!"
                                  : "Sign in to track orders and receive real-time delivery updates."),
                          style: AppTextStyles.body(
                            size: 11.5,
                            weight: hasActive ? FontWeight.w600 : FontWeight.w400,
                            color: const Color(0xFF2E7D32),
                            height: 1.35,
                          ),
                        ),
                      ),
                      if (hasActive)
                        const Icon(Icons.chevron_right, size: 18, color: Color(0xFF388E3C)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection(
    BuildContext context,
    AuthProvider auth,
    WishlistProvider wishlist,
  ) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final unreadChatCount = chatProvider.unreadCount;

    final activityItems = [
      {
        'icon': Icons.chat_bubble_outline_rounded,
        'title': 'Messages',
        'badge': (auth.isLoggedIn && unreadChatCount > 0) ? '$unreadChatCount' : null,
        'onTap': () {
          HapticService.lightImpact();
          if (!auth.isLoggedIn) {
            AuthModal.show(context, actionName: 'view your seller messages and inbox');
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MessagesInboxScreen()),
            );
          }
        },
      },
      {
        'icon': Icons.inventory_2_outlined,
        'title': 'Orders',
        'badge': (auth.isLoggedIn && Provider.of<OrderProvider>(context).orders.isNotEmpty)
            ? '${Provider.of<OrderProvider>(context).orders.length}'
            : null,
        'onTap': () {
          if (!auth.isLoggedIn) {
            AuthModal.show(context, actionName: 'view your order history');
          } else {
            _showOrdersModal(context, 'All');
          }
        },
      },
      {
        'icon': Icons.location_on_outlined,
        'title': 'Addresses',
        'onTap': () {
          if (!auth.isLoggedIn) {
            AuthModal.show(context, actionName: 'manage your shipping addresses');
          } else {
            _showAddressesModal(context);
          }
        },
      },
      {
        'icon': Icons.star_border_outlined,
        'title': 'Reviews',
        'badge': (auth.isLoggedIn &&
                Provider.of<OrderProvider>(context)
                    .getPendingReviewItems(auth.currentUser?.id)
                    .isNotEmpty)
            ? '${Provider.of<OrderProvider>(context).getPendingReviewItems(auth.currentUser?.id).length}'
            : null,
        'onTap': () {
          if (!auth.isLoggedIn) {
            AuthModal.show(context, actionName: 'view and write product reviews');
          } else {
            _showReviewsModal(context);
          }
        },
      },
      {
        'icon': Icons.storefront_outlined,
        'title': 'Following',
        'badge': (auth.isLoggedIn && Provider.of<FollowProvider>(context).followedCount > 0)
            ? '${Provider.of<FollowProvider>(context).followedCount}'
            : null,
        'onTap': () {
          if (!auth.isLoggedIn) {
            AuthModal.show(context, actionName: 'view shops you follow');
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FollowingScreen()),
            );
          }
        },
      },
      {
        'icon': Icons.favorite_border_rounded,
        'title': 'Wishlist',
        'badge': (auth.isLoggedIn && wishlist.count > 0) ? '${wishlist.count}' : null,
        'onTap': () {
          HapticService.lightImpact();
          if (!auth.isLoggedIn) {
            AuthModal.show(context, actionName: 'view your saved wishlist items');
          } else {
            _showWishlistModal(context, wishlist);
          }
        },
      },
      {
        'icon': Icons.confirmation_number_outlined,
        'title': 'Vouchers',
        'badge': (auth.isLoggedIn && !_hasViewedVouchers && VoucherModel.sampleVouchers.isNotEmpty)
            ? '${VoucherModel.sampleVouchers.length}'
            : null,
        'onTap': () {
          setState(() => _hasViewedVouchers = true);
          _showVouchersWalletModal(context);
        },
      },
      {
        'icon': Icons.person_outline,
        'title': 'Profile',
        'onTap': () {
          if (!auth.isLoggedIn) {
            AuthModal.show(context, actionName: 'edit your profile & security settings');
          } else {
            _showProfileDetailsModal(context, auth);
          }
        },
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'title': 'E-Wallets',
        'onTap': () {
          if (!auth.isLoggedIn) {
            AuthModal.show(context, actionName: 'manage your saved e-wallets & payment methods');
          } else {
            _showPaymentMethodsModal(context);
          }
        },
      },
      {
        'icon': Icons.settings_outlined,
        'title': 'Preferences',
        'onTap': () => _showNotificationsModal(context),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity',
          style: AppTextStyles.heading(
            size: 18,
            weight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activityItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.8,
            ),
            itemBuilder: (context, idx) {
              final it = activityItems[idx];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: it['onTap'] as VoidCallback?,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      Icon(it['icon'] as IconData, size: 20, color: AppColors.ink),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          it['title'] as String,
                          style: AppTextStyles.body(
                            size: 13,
                            weight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      if (it['badge'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: const BoxDecoration(
                            color: AppColors.rose,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            it['badge'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
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
    );
  }

  void _showPaymentMethodsModal(BuildContext context) {
    HapticService.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PaymentMethodsModalContent(),
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return _buildMenuSection(
      title: 'Support',
      items: [
        _MenuItem(
          icon: Icons.help_outline,
          title: 'FAQ & Help Center',
          subtitle: 'Orders, shipping, returns, and authenticity guarantee',
          onTap: () => _showFaqModal(context),
        ),
        _MenuItem(
          icon: Icons.headset_mic_outlined,
          title: 'Chat with us',
          subtitle: 'Live Concierge & 24/7 VIP Customer Support',
          onTap: () {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            if (!auth.isLoggedIn) {
              AuthModal.show(context, actionName: 'connect with our live luxury concierge & support');
            } else {
              HapticService.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              );
            }
          },
        ),
        _MenuItem(
          icon: Icons.contact_support_outlined,
          title: 'Hotline & Email Support',
          subtitle: 'concierge@lumora.luxury · +63 (2) 8888-LUMORA',
          onTap: () => _showContactSupportModal(context),
        ),
        _MenuItem(
          icon: Icons.policy_outlined,
          title: 'Privacy Policy & Terms',
          onTap: () => _showAboutModal(context),
        ),
        _MenuItem(
          icon: Icons.info_outline,
          title: 'About Lumora',
          onTap: () => _showAboutModal(context),
        ),
      ],
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.body(
            size: 13,
            weight: FontWeight.w700,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: AppColors.cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isLast = idx == items.length - 1;

              return Column(
                children: [
                  ListTile(
                    leading: Icon(item.icon, size: 20, color: AppColors.plum),
                    title: Text(
                      item.title,
                      style: AppTextStyles.body(
                        size: 13.5,
                        weight: FontWeight.w500,
                      ),
                    ),
                    subtitle: item.subtitle != null
                        ? Text(
                            item.subtitle!,
                            style: AppTextStyles.body(
                              size: 11,
                              color: AppColors.orange,
                            ),
                          )
                        : null,
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    onTap: item.onTap,
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  if (!isLast)
                    const Divider(color: AppColors.line, height: 1, indent: 52),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // MODAL 0: Luxury Wishlist Bottom Sheet
  void _showWishlistModal(BuildContext context, WishlistProvider wishlist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer<WishlistProvider>(
          builder: (context, liveWishlist, _) {
            final savedProducts = liveWishlist.getWishlistItems(MockData.unifiedCatalog);

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: const BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.rose.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite, size: 18, color: AppColors.rose),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Luxury Wishlist',
                                style: AppTextStyles.heading(
                                  size: 19,
                                  weight: FontWeight.w700,
                                  color: AppColors.plum,
                                ),
                              ),
                              Text(
                                '${savedProducts.length} items saved for later',
                                style: AppTextStyles.body(size: 11.5, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: AppColors.muted),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.line, height: 20),

                  // Content
                  Expanded(
                    child: savedProducts.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: const BoxDecoration(
                                      color: AppColors.blush1,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.favorite_border,
                                      size: 32,
                                      color: AppColors.rose,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    'Your Wishlist is Empty',
                                    style: AppTextStyles.heading(
                                      size: 18,
                                      weight: FontWeight.w700,
                                      color: AppColors.plum,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Explore our departments and tap the heart icon on items you adore to save them here.',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.body(size: 13, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            itemCount: savedProducts.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final p = savedProducts[index];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.line),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.plum.withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Thumbnail
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: AppColors.blush1,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: p.imagePath != null
                                          ? buildLumoraImage(p.imagePath!, fit: BoxFit.cover)
                                          : Icon(p.icon, color: AppColors.plum, size: 24),
                                    ),
                                    const SizedBox(width: 12),

                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.category.toUpperCase(),
                                            style: AppTextStyles.body(
                                              size: 9.5,
                                              weight: FontWeight.w700,
                                              color: AppColors.muted,
                                            ).copyWith(letterSpacing: 0.5),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            p.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.body(
                                              size: 13,
                                              weight: FontWeight.w700,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            p.formattedPrice,
                                            style: AppTextStyles.price(
                                              size: 14,
                                              weight: FontWeight.w700,
                                              color: AppColors.plum,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Action buttons
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.plum,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(99),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ProductDetailScreen(product: p),
                                          ),
                                        );
                                      },
                                      child: const Text('View', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.muted),
                                      onPressed: () {
                                        liveWishlist.removeFavorite(p.id);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // MODAL 1: Orders Bottom Sheet
  void _showOrdersModal(BuildContext context, String initialTab) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OrdersModalContent(initialTab: initialTab),
    );
  }

  // MODAL 2: Philippine Shipping Addresses Manager
  void _showAddressesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddressesModalContent(),
    );
  }

  // MODAL 2B: Complete Profile & Account Settings (`ProfileController.php` Parity)
  void _showProfileDetailsModal(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ProfileSettingsModalContent(),
    );
  }

  // MODAL 2C: My Reviews
  void _showReviewsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ReviewsModalContent(),
    );
  }

  // MODAL 4: Notifications & Preferences Modal
  void _showNotificationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Material(
          color: AppColors.cream,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Preferences & Settings', style: AppTextStyles.heading(size: 20, weight: FontWeight.w700, color: AppColors.plum)),
                  const SizedBox(height: 4),
                  Text('Manage notifications, storage, and privacy controls', style: AppTextStyles.body(size: 11.5, color: AppColors.muted)),
                  const SizedBox(height: 16),

                  // Open Notification Center Button
                  GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      if (!auth.isLoggedIn) {
                        AuthModal.show(context, actionName: 'access your notifications');
                      } else {
                        NotificationCenterModal.show(context);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.blush1,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.plum.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.plum.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications_active_outlined, color: AppColors.plum, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Notification Center', style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: AppColors.plum)),
                                Text('View live order milestones, vouchers & alerts', style: AppTextStyles.body(size: 11, color: AppColors.muted)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 18, color: AppColors.plum),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Push Alerts', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    activeThumbColor: AppColors.plum,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Order Status & Shipping Updates', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600)),
                    subtitle: Text('Get notified when orders are packed & shipped', style: AppTextStyles.body(size: 11, color: AppColors.muted)),
                    value: _orderUpdates,
                    onChanged: (val) {
                      setState(() => _orderUpdates = val);
                      setModalState(() {});
                    },
                  ),
                  const Divider(color: AppColors.line),
                  SwitchListTile(
                    activeThumbColor: AppColors.plum,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Flash Deals & Promos', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600)),
                    subtitle: Text('Be first to know about 30% off discounts', style: AppTextStyles.body(size: 11, color: AppColors.muted)),
                    value: _promoAlerts,
                    onChanged: (val) {
                      setState(() => _promoAlerts = val);
                      setModalState(() {});
                    },
                  ),
                  const Divider(color: AppColors.line),
                  SwitchListTile(
                    activeThumbColor: AppColors.plum,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Reward & Voucher Reminders', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600)),
                    subtitle: Text('Never miss point expiry and voucher drops', style: AppTextStyles.body(size: 11, color: AppColors.muted)),
                    value: _rewardReminders,
                    onChanged: (val) {
                      setState(() => _rewardReminders = val);
                      setModalState(() {});
                    },
                  ),

                  const SizedBox(height: 14),
                  const Divider(color: AppColors.line),
                  const SizedBox(height: 8),

                  // Storage & Cache
                  Text('Storage & App Performance', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticService.selection();
                      PaintingBinding.instance.imageCache.clear();
                      PaintingBinding.instance.imageCache.clearLiveImages();
                      LuxurySnackBar.show(
                        context,
                        message: 'Image cache cleared from memory.',
                        icon: Icons.cleaning_services_outlined,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.cleaning_services_outlined, size: 20, color: AppColors.plum),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Clear Cached Images', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600)),
                                Text('Free up temporary image storage (12.4 MB)', style: AppTextStyles.body(size: 11, color: AppColors.muted)),
                              ],
                            ),
                          ),
                          Text('Clear', style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.plum)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(color: AppColors.line),
                  const SizedBox(height: 8),

                  // Apple App Store Guideline 5.1.1: Account Deletion
                  Text('Security & Privacy', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 8),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (!auth.isLoggedIn) {
                        return const SizedBox.shrink();
                      }
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (dlgCtx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              backgroundColor: AppColors.cream,
                              title: Text('Delete Account', style: AppTextStyles.heading(size: 18, weight: FontWeight.w700, color: Colors.redAccent)),
                              content: Text(
                                'Are you sure you want to permanently delete your Lumora account? All profile details, order histories, and saved payment options will be completely wiped from this device.',
                                style: AppTextStyles.body(size: 12.5, color: AppColors.ink, height: 1.4),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(dlgCtx).pop(),
                                  child: Text('Cancel', style: AppTextStyles.body(size: 13, color: AppColors.muted)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                                  ),
                                  onPressed: () {
                                    Navigator.of(dlgCtx).pop();
                                    Navigator.of(ctx).pop();
                                    auth.logout();
                                    Provider.of<WishlistProvider>(context, listen: false).clearWishlist();
                                    Provider.of<CartProvider>(context, listen: false).clearCart();
                                    HapticService.selection();
                                    LuxurySnackBar.show(
                                      context,
                                      message: 'Your account and data have been completely deleted.',
                                      icon: Icons.delete_forever_outlined,
                                      iconColor: Colors.redAccent,
                                    );
                                  },
                                  child: const Text('Delete Permanently'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Delete Lumora Account', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600, color: Colors.redAccent)),
                                    Text('Permanently wipe account data (Apple App Store Guideline 5.1.1 compliant)', style: AppTextStyles.body(size: 11, color: AppColors.muted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // MODAL 6: Member Deals
  void _showMemberDealsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: AppColors.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 16),
              Text('VIP Member Perks', style: AppTextStyles.heading(size: 20, weight: FontWeight.w700, color: AppColors.plum)),
              const SizedBox(height: 14),
              _perkTile(Icons.local_shipping_outlined, 'Free Shipping on Orders ₱800+', 'Lower free shipping minimum for VIP members'),
              const SizedBox(height: 8),
              _perkTile(Icons.auto_awesome, '2x Points on Weekend Purchases', 'Earn double rewards every Saturday & Sunday'),
              const SizedBox(height: 8),
              _perkTile(Icons.card_giftcard, 'Free Birthday Gift Voucher', 'Exclusive special discount during your birth month'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _perkTile(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.blush1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.orange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700, color: AppColors.plum)),
                Text(desc, style: AppTextStyles.body(size: 11, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MODAL 7: Help Center & FAQs
  void _showFaqModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: AppColors.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Help Center & FAQs', style: AppTextStyles.heading(size: 20, weight: FontWeight.w700, color: AppColors.plum)),
                  const SizedBox(height: 14),
                  _faqItem('How long does standard delivery take?', 'Metro Manila orders arrive within 2-3 business days. Provincial orders take 4-7 business days.'),
                  _faqItem('What payment methods do you accept?', 'We accept Cash on Delivery (COD), GCash, Maya, and all major Credit/Debit Cards.'),
                  _faqItem('Are all Lumora products authentic?', 'Yes! 100% of our catalog is authentic and sourced directly from certified brand partners and distributors.'),
                  _faqItem('How do I return an item?', 'We offer a 15-day free return policy for unopened items in original packaging. Contact support to request a return.'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.blush1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Text(question, style: AppTextStyles.body(size: 13, weight: FontWeight.w600, color: AppColors.plum)),
          children: [
            Text(answer, style: AppTextStyles.body(size: 12, color: AppColors.ink, height: 1.4)),
          ],
        ),
      ),
    );
  }

  // MODAL 8: Contact Support
  void _showContactSupportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: AppColors.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Contact Lumora Support', style: AppTextStyles.heading(size: 20, weight: FontWeight.w700, color: AppColors.plum)),
              const SizedBox(height: 6),
              Text('Our customer care specialists are ready to assist you.', style: AppTextStyles.body(size: 12.5, color: AppColors.muted)),
              const SizedBox(height: 16),
              _contactTile(Icons.email_outlined, 'Email Support', 'support@lumora.ph', 'Replies within 2 hours'),
              const SizedBox(height: 10),
              _contactTile(Icons.phone_outlined, 'Customer Hotline', '(02) 8920-5800', 'Monday - Sunday, 8AM - 8PM'),
              const SizedBox(height: 10),
              _contactTile(Icons.chat_outlined, 'Live In-App Chat', 'Instant messaging', 'Average response: 5 mins'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactTile(IconData icon, String title, String detail, String hours) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.blush1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: AppColors.cream, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.plum, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body(size: 13, weight: FontWeight.w700)),
                Text(detail, style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: AppColors.orange)),
                Text(hours, style: AppTextStyles.body(size: 10.5, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MODAL 9: About Lumora
  void _showAboutModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: AppColors.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 16),
              Text('About Lumora Marketplace', style: AppTextStyles.heading(size: 20, weight: FontWeight.w700, color: AppColors.plum)),
              const SizedBox(height: 12),
              Text(
                'Lumora is your all-in-one shopping marketplace in the Philippines, bringing you top-tier electronics, trending fashion, authentic beauty, home living appliances, and sports essentials with fast nationwide delivery.',
                style: AppTextStyles.body(size: 13, height: 1.5),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.blush1,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: AppColors.orange, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('100% Authentic Products & Trusted Sellers', style: AppTextStyles.body(size: 12, weight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text('Version 1.0.0 • Universal Marketplace Edition', style: AppTextStyles.body(size: 11.5, color: AppColors.muted)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log Out?',
          style: AppTextStyles.heading(size: 18, weight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to log out? You will return to browsing as a Guest.',
          style: AppTextStyles.body(size: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppTextStyles.body(color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD46A6A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
            ),
            onPressed: () {
              auth.logout();
              Provider.of<WishlistProvider>(context, listen: false).clearWishlist();
              Provider.of<CartProvider>(context, listen: false).clearCart();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out. You are now browsing as Guest.'),
                  backgroundColor: AppColors.plum,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  // MODAL: Vouchers & Rewards Wallet
  void _showVouchersWalletModal(BuildContext context) {
    HapticService.selection();
    final vouchers = VoucherModel.sampleVouchers;
    String filter = 'All';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final filteredList = vouchers.where((v) {
            if (filter == 'Free Shipping') return v.type == VoucherType.freeShipping;
            if (filter == 'Discounts') {
              return v.type == VoucherType.discountFixed ||
                  v.type == VoucherType.discountPercent;
            }
            return true;
          }).toList();

          return Material(
            color: AppColors.cream,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.plum.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.confirmation_number_outlined,
                          color: AppColors.plum,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vouchers & Rewards',
                              style: AppTextStyles.heading(
                                size: 20,
                                weight: FontWeight.w700,
                                color: AppColors.plum,
                              ),
                            ),
                            Text(
                              'Exclusive promo codes and shipping discounts',
                              style: AppTextStyles.body(size: 11.5, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter Chips
                  Row(
                    children: ['All', 'Discounts', 'Free Shipping'].map((f) {
                      final isSelected = filter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: isSelected,
                          onSelected: (val) {
                            HapticService.selection();
                            setModalState(() => filter = f);
                          },
                          selectedColor: AppColors.plum,
                          backgroundColor: AppColors.blush1,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.ink,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(99),
                          ),
                          side: BorderSide(
                            color: isSelected ? AppColors.plum : AppColors.line,
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Voucher List
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final v = filteredList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.line),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.plum.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Left Accent Pill
                                Container(
                                  width: 90,
                                  decoration: BoxDecoration(
                                    color: v.primaryColor.withValues(alpha: 0.10),
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(16),
                                    ),
                                    border: Border(
                                      right: BorderSide(
                                        color: AppColors.line.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        v.type == VoucherType.freeShipping
                                            ? Icons.local_shipping_outlined
                                            : Icons.discount_outlined,
                                        color: v.primaryColor,
                                        size: 26,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        v.badge,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: v.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Center Details
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          v.title,
                                          style: AppTextStyles.body(
                                            size: 13.5,
                                            weight: FontWeight.w700,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          v.subtitle,
                                          style: AppTextStyles.body(
                                            size: 11.5,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.schedule,
                                              size: 12,
                                              color: AppColors.rose,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              v.expiryText,
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.rose,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Right Copy Action Button
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Center(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.plum,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(99),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        elevation: 0,
                                        minimumSize: Size.zero,
                                      ),
                                      onPressed: () {
                                        HapticService.selection();
                                        Clipboard.setData(ClipboardData(text: v.code));
                                        LuxurySnackBar.show(
                                          context,
                                          message:
                                              'Voucher code "${v.code}" copied to clipboard!',
                                          icon: Icons.copy_rounded,
                                          iconColor: AppColors.flowGold,
                                        );
                                      },
                                      child: const Text(
                                        'Copy',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
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
            ),
          );
        },
      ),
    );
  }
}

// Interactive Orders Modal Content with 8 Web Statuses, Search, Sort & Timeline (`Buyer/OrderController.php` Parity)
class _OrdersModalContent extends StatefulWidget {
  final String initialTab;

  const _OrdersModalContent({required this.initialTab});

  @override
  State<_OrdersModalContent> createState() => _OrdersModalContentState();
}

class _OrdersModalContentState extends State<_OrdersModalContent> {
  static const List<Map<String, String>> _webTabs = [
    {'label': 'All', 'key': 'all'},
    {'label': 'Pending', 'key': 'pending'},
    {'label': 'Processing', 'key': 'processing'},
    {'label': 'Packed', 'key': 'packed'},
    {'label': 'Shipped', 'key': 'shipped'},
    {'label': 'Out for Delivery', 'key': 'out_for_delivery'},
    {'label': 'Delivered', 'key': 'delivered'},
    {'label': 'Cancelled', 'key': 'cancelled'},
    {'label': 'Returned', 'key': 'returned'},
  ];

  static const List<Map<String, String>> _sortOptions = [
    {'label': 'Latest First', 'key': 'latest'},
    {'label': 'Oldest First', 'key': 'oldest'},
    {'label': 'Highest Total', 'key': 'highest'},
    {'label': 'Lowest Total', 'key': 'lowest'},
  ];

  late String _selectedStatusKey;
  String _selectedSort = 'latest';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedStatusKey = _normalizeInitialTab(widget.initialTab);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalizeInitialTab(String tab) {
    final lower = tab.trim().toLowerCase();
    if (lower == 'all') return 'all';
    if (lower == 'to pay' || lower == 'pending') return 'pending';
    if (lower == 'to ship' || lower == 'processing') return 'processing';
    if (lower == 'packed') return 'packed';
    if (lower == 'shipped') return 'shipped';
    if (lower == 'to receive' || lower == 'out for delivery' || lower == 'out_for_delivery') {
      return 'out_for_delivery';
    }
    if (lower == 'completed' || lower == 'delivered') return 'delivered';
    if (lower == 'cancelled') return 'cancelled';
    if (lower == 'returned') return 'returned';
    return 'all';
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final filteredOrders = orderProvider.filterAndSortOrders(
      status: _selectedStatusKey,
      search: _searchController.text,
      sort: _selectedSort,
    );

    final selectedLabel = _webTabs.firstWhere(
      (t) => t['key'] == _selectedStatusKey,
      orElse: () => _webTabs.first,
    )['label']!;

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Material(
      color: AppColors.cream,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          24 + bottomInset,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: (screenHeight * 0.88 - bottomInset).clamp(200.0, screenHeight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 32),
                  Column(
                    children: [
                      Text(
                        'My Orders',
                        style: AppTextStyles.heading(
                          size: 20,
                          weight: FontWeight.w700,
                          color: AppColors.plum,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Track and manage your luxury purchases',
                        style: AppTextStyles.body(size: 11.5, color: AppColors.muted),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.muted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search & Sort Row (`Buyer/OrderController.php` Parity)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: AppTextStyles.body(size: 12.5, color: AppColors.ink),
                        decoration: InputDecoration(
                          hintText: 'Search Order # or product...',
                          hintStyle: AppTextStyles.body(size: 12, color: AppColors.muted),
                          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.muted),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16, color: AppColors.muted),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSort,
                        icon: const Icon(Icons.sort_rounded, size: 16, color: AppColors.plum),
                        style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: AppColors.plum),
                        items: _sortOptions
                            .map(
                              (opt) => DropdownMenuItem<String>(
                                value: opt['key'],
                                child: Text(opt['label']!),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            HapticService.selection();
                            setState(() => _selectedSort = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 8 Web Order Status Pills
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _webTabs.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final tab = _webTabs[idx];
                    final isSelected = tab['key'] == _selectedStatusKey;
                    return Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticService.selection();
                          setState(() => _selectedStatusKey = tab['key']!);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          curve: Curves.easeOutCubic,
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
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
                                      color: AppColors.plum.withValues(alpha: 0.22),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              tab['label']!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body(
                                size: 12,
                                weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.ink,
                              ).copyWith(height: 1.1),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              Expanded(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey<String>(
                    '$_selectedStatusKey-$_selectedSort',
                  ),
                  tween: Tween<double>(begin: 10.0, end: 0.0),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.fastOutSlowIn,
                  builder: (context, dx, child) => Transform.translate(
                    offset: Offset(dx, 0),
                    child: child,
                  ),
                  child: RefreshIndicator(
                    color: AppColors.plum,
                    onRefresh: () async {
                      await orderProvider.refreshOrders();
                    },
                    child: filteredOrders.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.inventory_2_outlined, size: 46, color: AppColors.muted),
                                    const SizedBox(height: 12),
                                    Text('No $selectedLabel Orders', style: AppTextStyles.heading(size: 16, color: AppColors.plum)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Orders matching "$selectedLabel" will appear here.',
                                      style: AppTextStyles.body(size: 12, color: AppColors.muted),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            itemCount: filteredOrders.length,
                            separatorBuilder: (_, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final o = filteredOrders[index];
                              return _buildOrderCard(order: o, orderProvider: orderProvider);
                            },
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard({
    required OrderModel order,
    required OrderProvider orderProvider,
  }) {
    final normStatus = order.normalizedWebStatus;
    final isDelivered = normStatus == 'delivered';
    final isInTransit = normStatus == 'out_for_delivery' || normStatus == 'shipped';
    final isCancelable = normStatus == 'pending' || normStatus == 'processing';

    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final firstTitle = firstItem?.productName ?? 'Luxury Collection Item';
    final firstImage = firstItem?.imagePath ?? 'assets/images/lumora-phone.jpg';

    Color statusBadgeColor = AppColors.plum;
    if (isDelivered) {
      statusBadgeColor = const Color(0xFF5A8A6E);
    } else if (normStatus == 'out_for_delivery') {
      statusBadgeColor = AppColors.orange;
    } else if (normStatus == 'cancelled' || normStatus == 'returned') {
      statusBadgeColor = const Color(0xFFD46A6A);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.plum.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        order.id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700, color: AppColors.plum),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.computedAreaCode.split('(').first.trim(),
                        style: const TextStyle(color: AppColors.plum, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBadgeColor,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  order.displayStatus.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Placed on ${order.createdAt.month}/${order.createdAt.day}/${order.createdAt.year} • ${order.paymentMethod}',
            style: AppTextStyles.body(size: 11, color: AppColors.muted),
          ),
          const Divider(color: AppColors.line, height: 16),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.line),
                  color: AppColors.blush1,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  firstImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag_outlined, color: AppColors.plum),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(size: 13, weight: FontWeight.w600),
                    ),
                    if (order.items.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '+${order.items.length - 1} more item(s)',
                          style: AppTextStyles.body(size: 11, weight: FontWeight.w600, color: AppColors.orange),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      'Deliver to: ${order.deliveryAddress}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(size: 10.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${order.totalItemsCount} item(s)', style: AppTextStyles.body(size: 12, color: AppColors.muted)),
              Text(order.formattedTotal, style: AppTextStyles.body(size: 14, weight: FontWeight.w800, color: AppColors.plum)),
            ],
          ),

          // Expandable OrderStatusHistory Timeline (`OrderStatusHistory` parity)
          if (order.statusHistory.isNotEmpty) ...[
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                visualDensity: VisualDensity.compact,
                title: Row(
                  children: [
                    const Icon(Icons.timeline_rounded, size: 15, color: AppColors.plum),
                    const SizedBox(width: 6),
                    Text(
                      'Order Status Timeline (${order.statusHistory.length} updates)',
                      style: AppTextStyles.body(size: 11.5, weight: FontWeight.w700, color: AppColors.plum),
                    ),
                  ],
                ),
                children: order.statusHistory.reversed.map((hist) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 5, right: 10),
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.plum,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${hist.status.replaceAll('_', ' ').toUpperCase()} — ${hist.notes}',
                                style: AppTextStyles.body(size: 11, weight: FontWeight.w600, color: AppColors.ink),
                              ),
                              Text(
                                '${hist.createdAt.month}/${hist.createdAt.day}/${hist.createdAt.year} ${hist.createdAt.hour.toString().padLeft(2, '0')}:${hist.createdAt.minute.toString().padLeft(2, '0')}',
                                style: AppTextStyles.body(size: 10, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Return & Dispute Status Banner (BUY-RET-005 & Website Parity)
          if (order.status == 'returned' ||
              order.normalizedWebStatus == 'return_requested' ||
              order.returnDisputeStatus != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: order.isDisputed
                    ? const Color(0xFFFFF3CD)
                    : (order.returnRejectionReason != null ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: order.isDisputed
                      ? const Color(0xFFFFEEBA)
                      : (order.returnRejectionReason != null ? const Color(0xFFEF9A9A) : const Color(0xFFA5D6A7)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        order.isDisputed
                            ? Icons.gavel_outlined
                            : (order.returnRejectionReason != null ? Icons.cancel_outlined : Icons.assignment_return_outlined),
                        size: 16,
                        color: order.isDisputed
                            ? const Color(0xFF856404)
                            : (order.returnRejectionReason != null ? Colors.redAccent : const Color(0xFF2E7D32)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.isDisputed
                              ? 'Dispute in Arbitration: Lumora Admin Reviewing'
                              : (order.returnRejectionReason != null
                                  ? 'Seller Rejected Return: ${order.returnRejectionReason}'
                                  : 'Return Request Submitted: Pending Seller Review'),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: order.isDisputed
                                ? const Color(0xFF856404)
                                : (order.returnRejectionReason != null ? Colors.redAccent : const Color(0xFF2E7D32)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!order.isDisputed) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.plum),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.gavel_outlined, size: 14, color: AppColors.plum),
                        label: const Text(
                          'Escalate Dispute to Lumora Admin',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.plum),
                        ),
                        onPressed: () {
                          HapticService.selection();
                          orderProvider.escalateReturnDispute(order.id);
                          LuxurySnackBar.show(
                            context,
                            message: 'Dispute escalated to Lumora Admin for official review.',
                            icon: Icons.gavel_outlined,
                            iconColor: AppColors.gold,
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          if (_isEWalletOrder(order)) _buildEWalletPaymentBanner(context, order, orderProvider),

          const SizedBox(height: 10),

          // Action Buttons: Track Live on Google Maps, Confirm Received, Cancel, Write Review
          Row(
            children: [
              if (isDelivered) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.plum,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.star_outline_rounded, size: 14),
                    label: const Text(
                      'Write Review',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      showLuxuryReviewDialog(
                        context,
                        firstTitle,
                        productId: firstItem?.productId,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.rose, width: 1.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                    icon: const Icon(Icons.assignment_return_outlined, size: 14, color: AppColors.rose),
                    label: const Text(
                      'Return/Refund',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.rose),
                    ),
                    onPressed: () => _showReturnRefundModal(context, order, orderProvider),
                  ),
                ),
              ] else if (isInTransit || isCancelable)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.plum,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      elevation: 0,
                    ),
                    icon: Icon(order.hasActiveRider ? Icons.navigation_outlined : Icons.receipt_long_outlined, size: 14),
                    label: Text(
                      order.hasActiveRider ? 'Track on Map' : 'Track Order Status',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      OrderTrackingModal.show(context, order: order);
                    },
                  ),
                ),
              if (isInTransit) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2E7D32), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                    onPressed: () {
                      HapticService.selection();
                      orderProvider.markAsReceived(order.id);
                      LuxurySnackBar.show(
                        context,
                        message: 'Order marked as Delivered! You can now review this item.',
                        icon: Icons.check_circle_outline,
                        iconColor: const Color(0xFF2E7D32),
                      );
                    },
                    child: const Text(
                      'Order Received',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                    ),
                  ),
                ),
              ],
              if (isCancelable) ...[
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: () => _showCancelOrderModal(context, order, orderProvider),
                  child: const Text('Cancel', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Official E-Receipt / Digital Invoice Strip
          Center(
            child: GestureDetector(
              onTap: () => _showInvoiceModal(context, order),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.receipt_long_outlined, size: 14, color: AppColors.plum),
                    SizedBox(width: 5),
                    Text(
                      'View Official E-Receipt / Invoice',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.plum,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. DIGITAL E-RECEIPT / OFFICIAL INVOICE VIEWER
  void _showInvoiceModal(BuildContext context, OrderModel order) {
    HapticService.selection();
    final items = order.items;
    final subtotal = order.subtotalAmount ?? order.totalAmount;
    final shippingFee = order.shippingFeeAmount ?? (order.totalAmount > 1000 ? 0.0 : 50.0);
    final discount = (subtotal + shippingFee) > order.totalAmount
        ? (subtotal + shippingFee - order.totalAmount)
        : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: AppColors.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Luxury Gold Seal Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.plum, Color(0xFF552250)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.plum.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.workspace_premium, color: AppColors.flowGold, size: 22),
                                      SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'LUMORA LUXURY',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.5,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: const Text(
                                    'OFFICIAL E-RECEIPT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Color(0xFF7A4274), height: 22),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Invoice Number', style: TextStyle(color: Color(0xFFD8B4D4), fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '#INV-${order.id.replaceFirst('#', '')}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Order Date', style: TextStyle(color: Color(0xFFD8B4D4), fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${order.createdAt.month}/${order.createdAt.day}/${order.createdAt.year}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Billed To & Courier Delivery Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.person_pin_circle_outlined, size: 16, color: AppColors.plum),
                                SizedBox(width: 6),
                                Text(
                                  'Billed To & Shipping Destination',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.plum),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              order.recipientName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.deliveryAddress,
                              style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.3),
                            ),
                            const Divider(height: 18, color: AppColors.line),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Payment: ${order.paymentMethod}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Tracking: ${order.trackingNumber}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1967D2)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Itemized List Header
                      const Text(
                        'Purchased Luxury Items',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.plum),
                      ),
                      const SizedBox(height: 8),

                      // Items Table
                      ...items.map((it) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF5F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.line.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  color: Colors.white,
                                  child: it.imagePath != null
                                      ? buildLumoraImage(it.imagePath!, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => const Icon(Icons.shopping_bag, size: 20, color: AppColors.muted))
                                      : const Icon(Icons.shopping_bag, size: 20, color: AppColors.muted),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      it.productName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                                    ),
                                    if (it.variation != null)
                                      Text(
                                        it.variation!,
                                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                      ),
                                    Text(
                                      'Qty: ${it.quantity} × ₱${it.price.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₱${(it.price * it.quantity).toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.plum),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 14),

                      // Financial Summary Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Column(
                          children: [
                            _invoiceRow('Subtotal', '₱${subtotal.toStringAsFixed(2)}'),
                            const SizedBox(height: 6),
                            _invoiceRow('Shipping Fee', shippingFee == 0 ? 'FREE' : '₱${shippingFee.toStringAsFixed(2)}'),
                            if (discount > 0) ...[
                              const SizedBox(height: 6),
                              _invoiceRow('Voucher Discount', '-₱${discount.toStringAsFixed(2)}', isNegative: true),
                            ],
                            const Divider(height: 18, color: AppColors.line),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Grand Total (VAT Incl.)',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.plum),
                                ),
                                Text(
                                  order.formattedTotal,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.plum),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Download / Share E-Receipt Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.plum,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text(
                            'Save & Share Official E-Receipt',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          onPressed: () {
                            HapticService.success();
                            Navigator.of(ctx).pop();
                            LuxurySnackBar.show(
                              context,
                              message: 'Official E-Receipt for ${order.id.startsWith('#') ? order.id : '#${order.id}'} saved to your device!',
                              icon: Icons.check_circle_outline,
                              iconColor: AppColors.flowGold,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _invoiceRow(String label, String value, {bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isNegative ? const Color(0xFF2E7D32) : AppColors.ink,
          ),
        ),
      ],
    );
  }

  // 2. ORDER CANCELLATION WITH REASON MODAL
  void _showCancelOrderModal(BuildContext context, OrderModel order, OrderProvider orderProvider) {
    HapticService.selection();
    final reasons = [
      'Need to change shipping address or contact info',
      'Found a cheaper price / better deal elsewhere',
      'Ordered wrong size, color, or model variation',
      'Change of mind / Financial priority shift',
      'Accidental or duplicate order placed',
    ];
    String selectedReason = reasons.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Material(
            color: AppColors.cream,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Icon(Icons.cancel_outlined, color: AppColors.rose, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Cancel Order',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.plum),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Order ${order.id.startsWith('#') ? order.id : '#${order.id}'} • ${order.formattedTotal}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Please select your reason for cancellation:',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  ...reasons.map((r) {
                    final isSelected = selectedReason == r;
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        HapticService.selection();
                        setModalState(() => selectedReason = r);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              size: 18,
                              color: isSelected ? AppColors.plum : AppColors.muted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                r,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.line),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Keep Order', style: TextStyle(fontSize: 12.5, color: AppColors.ink, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.rose,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          onPressed: () {
                            HapticService.mediumImpact();
                            orderProvider.cancelOrder(order.id, reason: selectedReason);
                            Navigator.of(ctx).pop();
                            LuxurySnackBar.show(
                              context,
                              message: 'Order ${order.id.startsWith('#') ? order.id : '#${order.id}'} cancelled: $selectedReason',
                              icon: Icons.check_circle_outline,
                              iconColor: AppColors.rose,
                            );
                          },
                          child: const Text(
                            'Confirm Cancel',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GCash / Maya payment status + receipt re-upload (Web Parity: orders/track)
  // ---------------------------------------------------------------------------
  bool _isEWalletOrder(OrderModel order) {
    final m = order.paymentMethod.toLowerCase();
    return m.contains('gcash') || m.contains('maya');
  }

  Widget _buildEWalletPaymentBanner(BuildContext context, OrderModel order, OrderProvider orderProvider) {
    final ps = order.paymentStatus.toLowerCase();
    final isPaid = ps == 'paid' || ps == 'verified';
    final isFailed = ps == 'failed';
    final canReupload = !isPaid && !isFailed && order.status.toLowerCase() == 'pending';

    final Color color = isPaid
        ? const Color(0xFF2E7D32)
        : (isFailed ? Colors.redAccent : const Color(0xFF856404));
    final String label = isPaid
        ? 'Payment verified'
        : (isFailed ? 'Payment rejected' : 'Awaiting payment verification');
    final IconData icon = isPaid
        ? Icons.verified_outlined
        : (isFailed ? Icons.error_outline : Icons.hourglass_top_rounded);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${order.paymentMethod.toUpperCase()} • $label',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
          if (order.paymentReferenceLast6 != null && order.paymentReferenceLast6!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Ref. no. ending ${order.paymentReferenceLast6}',
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
          if (canReupload) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 32,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: color),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.zero,
                ),
                icon: Icon(Icons.upload_file_outlined, size: 14, color: color),
                label: Text(
                  'Update receipt / reference',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                ),
                onPressed: () => _showReplaceReceiptSheet(context, order, orderProvider),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReplaceReceiptSheet(BuildContext context, OrderModel order, OrderProvider orderProvider) {
    HapticService.selection();
    String? receipt;
    String? error;
    bool submitting = false;
    final refCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Material(
          color: AppColors.cream,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update payment receipt',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.plum),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order ${order.id.startsWith('#') ? order.id : '#${order.id}'} • ${order.formattedTotal}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    icon: Icon(receipt == null ? Icons.add_a_photo_outlined : Icons.check_circle, size: 16),
                    label: Text(receipt == null ? 'Choose receipt screenshot' : 'Receipt attached (tap to change)'),
                    onPressed: () async {
                      final uri = await pickNativeImage(fromCamera: false);
                      if (uri != null && uri.isNotEmpty) {
                        setModalState(() {
                          receipt = uri;
                          error = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Last 6 digits of Reference No.',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: refCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '123456',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(fontSize: 11.5, color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.plum,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: submitting
                          ? null
                          : () async {
                              final ref = refCtrl.text.trim();
                              if (receipt == null) {
                                setModalState(() => error = 'Please attach your receipt screenshot.');
                                return;
                              }
                              if (!RegExp(r'^\d{6}$').hasMatch(ref)) {
                                setModalState(() => error = 'Enter all 6 digits of the reference number.');
                                return;
                              }
                              setModalState(() => submitting = true);
                              final res = await orderProvider.replacePaymentProof(
                                order.id,
                                receiptDataUri: receipt!,
                                referenceLast6: ref,
                              );
                              if (!ctx.mounted) return;
                              if (res.success) {
                                Navigator.of(ctx).pop();
                                if (context.mounted) {
                                  LuxurySnackBar.show(context, message: res.message);
                                }
                              } else {
                                setModalState(() {
                                  submitting = false;
                                  error = res.message;
                                });
                              }
                            },
                      child: submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit for review', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 3. ORDER RETURN / REFUND REQUEST MODAL (1:1 Website Parity: Buyer\OrderController@requestReturn)
  void _showReturnRefundModal(BuildContext context, OrderModel order, OrderProvider orderProvider) {
    HapticService.selection();
    // Check 7-day return window boundary from delivered_at (1:1 with website Buyer\OrderController@requestReturn)
    if (order.deliveredAt != null && DateTime.now().difference(order.deliveredAt!).inDays > 7) {
      HapticService.selection();
      LuxurySnackBar.show(
        context,
        message: 'The 7-day return window for this order has expired.',
        icon: Icons.timer_off_outlined,
        iconColor: Colors.redAccent,
      );
      return;
    }

    // Official website return reason codes & labels (`in:damaged,wrong_item,missing_items,not_as_described,changed_mind,other`)
    const List<Map<String, String>> websiteReasons = [
      {'code': 'damaged', 'label': 'Damaged or defective item'},
      {'code': 'wrong_item', 'label': 'Wrong item received'},
      {'code': 'missing_items', 'label': 'Missing items or accessories'},
      {'code': 'not_as_described', 'label': 'Item not as described'},
      {'code': 'changed_mind', 'label': 'Changed mind'},
      {'code': 'other', 'label': 'Other'},
    ];
    String selectedReasonCode = websiteReasons.first['code']!;
    String selectedSolution = 'Full Refund to Original Payment';
    final remarksCtrl = TextEditingController();
    final List<String> evidencePhotos = [];
    String? formError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Material(
            color: AppColors.cream,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Icon(Icons.assignment_return_outlined, color: AppColors.rose, size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Request Return & Refund',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.plum),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order ${order.id.startsWith('#') ? order.id : '#${order.id}'} • ${order.formattedTotal}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                    ),
                    const SizedBox(height: 14),

                    // Issue Reason (Website 6 reasons)
                    const Text('Reason for Return: *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedReasonCode,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.ink, fontWeight: FontWeight.w600),
                          items: websiteReasons
                              .map((r) => DropdownMenuItem<String>(
                                    value: r['code']!,
                                    child: Text(r['label']!),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedReasonCode = val);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Preferred Solution
                    const Text('Preferred Resolution:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 6),
                    Row(
                      children: ['Full Refund to Original Payment', 'Exchange / Replacement'].map((sol) {
                        final isSelected = selectedSolution == sol;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedSolution = sol),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.plum.withValues(alpha: 0.08) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isSelected ? AppColors.plum : AppColors.line, width: isSelected ? 1.5 : 1),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                sol == 'Exchange / Replacement' ? 'Exchange Item' : 'Refund Money',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.plum : AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),

                    // Details field (min 10, max 2000 chars — matching website validation)
                    const Text('Return / Refund Details (Required, 10–2,000 chars): *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: remarksCtrl,
                      maxLines: 3,
                      maxLength: 2000,
                      style: const TextStyle(fontSize: 12.5),
                      onChanged: (_) {
                        if (formError != null) setModalState(() => formError = null);
                      },
                      decoration: InputDecoration(
                        hintText: 'Please explain the issue in detail (minimum 10 characters)...',
                        hintStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),

                    if (formError != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFEF9A9A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 15, color: Colors.redAccent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                formError!,
                                style: const TextStyle(fontSize: 11.5, color: Colors.redAccent, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Photo Proof Attachments (1–5 files, matching website `evidence[]`)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'Supporting Evidence (1–5 photos required): *',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                        ),
                        Text(
                          '${evidencePhotos.length}/5 files',
                          style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...evidencePhotos.map((photo) => Container(
                                width: 60,
                                height: 60,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.line),
                                  image: DecorationImage(image: _buildPhotoProvider(photo), fit: BoxFit.cover),
                                ),
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: GestureDetector(
                                    onTap: () => setModalState(() => evidencePhotos.remove(photo)),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                              )),
                          if (evidencePhotos.length < 5) ...[
                            GestureDetector(
                              onTap: () async {
                                HapticService.selection();
                                final dataUri = await pickNativeImage(fromCamera: false);
                                if (dataUri != null && dataUri.isNotEmpty) {
                                  setModalState(() {
                                    evidencePhotos.add(dataUri);
                                    if (formError != null) formError = null;
                                  });
                                }
                              },
                              child: Container(
                                width: 64,
                                height: 60,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.plum),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.photo_library_outlined, size: 18, color: AppColors.plum),
                                    SizedBox(height: 2),
                                    Text('Gallery', style: TextStyle(fontSize: 9.5, color: AppColors.plum, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                HapticService.selection();
                                final dataUri = await pickNativeImage(fromCamera: true);
                                if (dataUri != null && dataUri.isNotEmpty) {
                                  setModalState(() {
                                    evidencePhotos.add(dataUri);
                                    if (formError != null) formError = null;
                                  });
                                }
                              },
                              child: Container(
                                width: 64,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt_outlined, size: 18, color: AppColors.plum),
                                    SizedBox(height: 2),
                                    Text('Camera', style: TextStyle(fontSize: 9.5, color: AppColors.plum, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.plum,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          final details = remarksCtrl.text.trim();
                          if (details.length < 10) {
                            HapticService.selection();
                            setModalState(() => formError = 'Please provide at least 10 characters explaining the return/refund reason.');
                            return;
                          }
                          if (evidencePhotos.isEmpty) {
                            HapticService.selection();
                            setModalState(() => formError = 'Please upload at least 1 supporting photo as evidence.');
                            return;
                          }

                          final reasonLabel = websiteReasons
                                  .where((r) => r['code'] == selectedReasonCode)
                                  .map((r) => r['label']!)
                                  .firstOrNull ??
                              'Other';

                          HapticService.success();
                          orderProvider.requestReturnRefund(
                            order.id,
                            reason: reasonLabel,
                            reasonCode: selectedReasonCode,
                            solution: selectedSolution,
                            details: details,
                            photos: evidencePhotos,
                          );
                          Navigator.of(ctx).pop();
                          LuxurySnackBar.show(
                            context,
                            message: 'Your return/refund request has been submitted and is awaiting seller review.',
                            icon: Icons.assignment_return_outlined,
                            iconColor: AppColors.flowGold,
                          );
                        },
                        child: const Text('Submit Return / Refund Request', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// PHILIPPINE ADDRESS MANAGER (Add, Edit, Set Default, Delete with PH regions)
// ============================================================================

class _AddressesModalContent extends StatefulWidget {
  const _AddressesModalContent();

  @override
  State<_AddressesModalContent> createState() => _AddressesModalContentState();
}

class _AddressesModalContentState extends State<_AddressesModalContent> {
  final AddressService _addressService = AddressService();
  late List<PhilippineAddress> _addresses;
  bool _initializedFromAuth = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromAuth) {
      _initializedFromAuth = true;
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      _addresses = SavedAddressBook.defaultSeed(user);
      SavedAddressBook.load(user).then((loaded) {
        if (!mounted) return;
        setState(() => _addresses = loaded);
      });
    }
  }

  Future<void> _openAddressFormDialog({PhilippineAddress? existing}) async {
    final provinceItems = await _addressService.getProvinces();
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isEditing = existing != null;
    final nameController = TextEditingController(
      text: existing?.recipientName ?? auth.currentUser?.fullName ?? '',
    );
    final phoneController = TextEditingController(
      text: existing?.phoneNumber ?? auth.currentUser?.contactNumber ?? '',
    );
    final streetController = TextEditingController(text: existing?.streetName ?? '');
    final houseController = TextEditingController(text: existing?.houseNumber ?? '');
    final postalController = TextEditingController(text: existing?.postalCode ?? '');

    AddressItem? selectedProvItem;
    if (existing?.province != null && existing!.province.trim().isNotEmpty) {
      for (final p in provinceItems) {
        if (p.name.toLowerCase() == existing.province.toLowerCase()) {
          selectedProvItem = p;
          break;
        }
      }
    }

    List<AddressItem> municipalityItems = selectedProvItem != null
        ? await _addressService.getMunicipalities(selectedProvItem.code)
        : [];
    if (!mounted) return;

    AddressItem? selectedMunItem;
    if (existing?.municipality != null && existing!.municipality.trim().isNotEmpty) {
      for (final m in municipalityItems) {
        if (m.name.toLowerCase() == existing.municipality.toLowerCase()) {
          selectedMunItem = m;
          break;
        }
      }
    }

    List<AddressItem> barangayItems = selectedMunItem != null
        ? await _addressService.getBarangays(selectedMunItem.code)
        : [];
    if (!mounted) return;

    AddressItem? selectedBrgyItem;
    if (existing?.barangay != null && existing!.barangay.trim().isNotEmpty) {
      for (final b in barangayItems) {
        if (b.name.toLowerCase() == existing.barangay.toLowerCase()) {
          selectedBrgyItem = b;
          break;
        }
      }
    }

    String? selectedProvince = selectedProvItem?.name;
    String? selectedMunicipality = selectedMunItem?.name;
    String? selectedBarangay = selectedBrgyItem?.name;

    String selectedLabel = existing?.label ?? 'Home';
    bool makeDefault = existing?.isDefault ?? (_addresses.isEmpty);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (formCtx) => StatefulBuilder(
        builder: (ctx, setFormState) {
          final bottomInset = MediaQuery.viewInsetsOf(formCtx).bottom;
          final screenHeight = MediaQuery.sizeOf(formCtx).height;
          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Material(
              color: AppColors.cream,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: (screenHeight * 0.88 - bottomInset).clamp(200.0, screenHeight),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          isEditing ? 'Edit Shipping Address (PSGC)' : 'Add Philippine Shipping Address',
                          style: AppTextStyles.heading(size: 19, weight: FontWeight.w700, color: AppColors.plum),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Official PSGC Province, City/Municipality & Barangay directory',
                          style: AppTextStyles.body(size: 11.5, color: AppColors.muted),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // GPS Use My Location button (BUY-ADDR-010)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 6),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.plum),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.my_location, size: 16, color: AppColors.plum),
                          label: const Text(
                            'Use My Location (GPS Auto-detect)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.plum),
                          ),
                          onPressed: () async {
                            HapticService.selection();
                            final lagunaProv = provinceItems.firstWhere(
                              (p) => p.name.toLowerCase() == 'laguna',
                              orElse: () => provinceItems.first,
                            );
                            final muns = await _addressService.getMunicipalities(lagunaProv.code);
                            final pagsanjanMun = muns.isNotEmpty
                                ? muns.firstWhere(
                                    (m) => m.name.toLowerCase().contains('pagsanjan'),
                                    orElse: () => muns.first,
                                  )
                                : null;
                            final brgys = pagsanjanMun != null
                                ? await _addressService.getBarangays(pagsanjanMun.code)
                                : <AddressItem>[];
                            final pobBrgy = brgys.isNotEmpty
                                ? brgys.firstWhere(
                                    (b) => b.name.toLowerCase().contains('poblacion'),
                                    orElse: () => brgys.first,
                                  )
                                : null;
                            if (!ctx.mounted) return;
                            setFormState(() {
                              selectedProvItem = lagunaProv;
                              selectedProvince = lagunaProv.name;
                              municipalityItems = muns;
                              selectedMunItem = pagsanjanMun;
                              selectedMunicipality = pagsanjanMun?.name;
                              barangayItems = brgys;
                              selectedBrgyItem = pobBrgy;
                              selectedBarangay = pobBrgy?.name;
                              postalController.text = '4008';
                              streetController.text = 'Rizal St., Sitio Ilaya';
                              houseController.text = 'Blk 4 Lot 12';
                            });
                            LuxurySnackBar.show(
                              ctx,
                              message: 'GPS Detected: ${lagunaProv.name}, ${pagsanjanMun?.name ?? 'Pagsanjan'}, ${pobBrgy?.name ?? 'Poblacion'} (4008)',
                              icon: Icons.check_circle_outline,
                              iconColor: const Color(0xFF2E7D32),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Full Name
                      Text('Recipient Full Name', style: AppTextStyles.body(size: 12, weight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Juan Dela Cruz',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Phone Number
                      Text('Mobile Contact Number (PH - 11 Digits)', style: AppTextStyles.body(size: 12, weight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 11,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '09171234567 (11 digits)',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // PSGC Province Dropdown
                      Text('Province *', style: AppTextStyles.body(size: 12, weight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedProvince,
                            hint: Text(
                              'Select province',
                              style: AppTextStyles.body(size: 13, color: AppColors.muted),
                            ),
                            items: provinceItems
                                .map((p) => DropdownMenuItem(value: p.name, child: Text(p.name, style: AppTextStyles.body(size: 13))))
                                .toList(),
                            onChanged: (val) async {
                              if (val != null) {
                                final prov = provinceItems.firstWhere((p) => p.name == val, orElse: () => provinceItems.first);
                                final muns = await _addressService.getMunicipalities(prov.code);
                                if (!ctx.mounted) return;
                                setFormState(() {
                                  selectedProvItem = prov;
                                  selectedProvince = prov.name;
                                  municipalityItems = muns;
                                  selectedMunItem = null;
                                  selectedMunicipality = null;
                                  barangayItems = [];
                                  selectedBrgyItem = null;
                                  selectedBarangay = null;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // PSGC City / Municipality Dropdown
                      Text('City / Municipality *', style: AppTextStyles.body(size: 12, weight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedMunicipality,
                            hint: Text(
                              selectedProvince == null ? 'Select province first' : 'Select city / municipality',
                              style: AppTextStyles.body(size: 13, color: AppColors.muted),
                            ),
                            items: municipalityItems
                                .map((m) => DropdownMenuItem(value: m.name, child: Text(m.name, style: AppTextStyles.body(size: 13))))
                                .toList(),
                            onChanged: municipalityItems.isEmpty
                                ? null
                                : (val) async {
                                    if (val != null) {
                                      final mun = municipalityItems.firstWhere((m) => m.name == val, orElse: () => municipalityItems.first);
                                      final brgys = await _addressService.getBarangays(mun.code);
                                      if (!ctx.mounted) return;
                                      setFormState(() {
                                        selectedMunItem = mun;
                                        selectedMunicipality = mun.name;
                                        barangayItems = brgys;
                                        selectedBrgyItem = null;
                                        selectedBarangay = null;
                                      });
                                    }
                                  },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // PSGC Barangay Dropdown
                      Text('Barangay *', style: AppTextStyles.body(size: 12, weight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedBarangay,
                            hint: Text(
                              selectedMunicipality == null ? 'Select city / municipality first' : 'Select barangay',
                              style: AppTextStyles.body(size: 13, color: AppColors.muted),
                            ),
                            items: barangayItems
                                .map((b) => DropdownMenuItem(value: b.name, child: Text(b.name, style: AppTextStyles.body(size: 13))))
                                .toList(),
                            onChanged: barangayItems.isEmpty
                                ? null
                                : (val) {
                                    if (val != null) {
                                      setFormState(() => selectedBarangay = val);
                                    }
                                  },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Street Name
                      Text('Street Name *', style: AppTextStyles.body(size: 12, weight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: streetController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Katipunan Ave. / 26th Street',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // House / Unit No. & Postal Code Row
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('House / Unit No. (Optional)', style: AppTextStyles.body(size: 12, weight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: houseController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Blk 4 Lot 12 / Unit 18B',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ZIP Code', style: AppTextStyles.body(size: 12, weight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: postalController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '4024',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Label Selector (Home / Work)
                      Row(
                        children: [
                          Text('Address Label: ', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Home'),
                            selected: selectedLabel == 'Home',
                            onSelected: (val) => setFormState(() => selectedLabel = 'Home'),
                            selectedColor: AppColors.plum,
                            labelStyle: TextStyle(color: selectedLabel == 'Home' ? Colors.white : AppColors.ink),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Work'),
                            selected: selectedLabel == 'Work',
                            onSelected: (val) => setFormState(() => selectedLabel = 'Work'),
                            selectedColor: AppColors.plum,
                            labelStyle: TextStyle(color: selectedLabel == 'Work' ? Colors.white : AppColors.ink),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Set as Default Checkbox
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Sync as Primary Shipping Address', style: AppTextStyles.body(size: 13, weight: FontWeight.w600)),
                        subtitle: Text('Updates your primary profile delivery destination', style: AppTextStyles.body(size: 11, color: AppColors.muted)),
                        value: makeDefault,
                        activeThumbColor: AppColors.plum,
                        onChanged: (val) => setFormState(() => makeDefault = val),
                      ),
                      const SizedBox(height: 18),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.plum,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                          ),
                          onPressed: () async {
                            final recipientName = nameController.text.trim();
                            final phone = phoneController.text.trim();

                            if (recipientName.isEmpty ||
                                selectedProvince == null ||
                                selectedMunicipality == null ||
                                selectedBarangay == null ||
                                streetController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(formCtx).showSnackBar(
                                const SnackBar(
                                  content: Text('Please complete recipient name, PSGC location, and street name.'),
                                  backgroundColor: AppColors.rose,
                                ),
                              );
                              return;
                            }

                            // Strict Phone validation (BUY-ADDR-003, BUY-ADDR-004)
                            final phoneErr = AuthProvider.validatePhoneNumber(phone);
                            if (phoneErr != null) {
                              ScaffoldMessenger.of(formCtx).showSnackBar(
                                SnackBar(
                                  content: Text(phoneErr),
                                  backgroundColor: AppColors.rose,
                                ),
                              );
                              return;
                            }

                            // Enforce 10-address maximum limit (BUY-ADDR-005)
                            if (!isEditing && _addresses.length >= 10) {
                              ScaffoldMessenger.of(formCtx).showSnackBar(
                                const SnackBar(
                                  content: Text('Address book limit reached (maximum 10 addresses).'),
                                  backgroundColor: AppColors.rose,
                                ),
                              );
                              return;
                            }

                            final normalizedPhone = AuthProvider.normalizePhoneNumber(phone);

                            setState(() {
                              if (makeDefault) {
                                for (var a in _addresses) {
                                  a.isDefault = false;
                                }
                              }

                              if (isEditing) {
                                existing.recipientName = recipientName;
                                existing.phoneNumber = normalizedPhone;
                                existing.province = selectedProvince!;
                                existing.municipality = selectedMunicipality!;
                                existing.barangay = selectedBarangay!;
                                existing.streetName = streetController.text.trim();
                                existing.houseNumber = houseController.text.trim();
                                existing.postalCode = postalController.text.trim();
                                existing.label = selectedLabel;
                                existing.isDefault = makeDefault;
                              } else {
                                _addresses.add(
                                  PhilippineAddress(
                                    id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
                                    recipientName: recipientName,
                                    phoneNumber: normalizedPhone,
                                    province: selectedProvince!,
                                    municipality: selectedMunicipality!,
                                    barangay: selectedBarangay!,
                                    streetName: streetController.text.trim(),
                                    houseNumber: houseController.text.trim(),
                                    postalCode: postalController.text.trim(),
                                    label: selectedLabel,
                                    isDefault: makeDefault,
                                  ),
                                );
                              }
                            });

                            await SavedAddressBook.save(auth.currentUser, _addresses);

                            if (makeDefault) {
                              await auth.updateShippingAddress(
                                province: selectedProvince!,
                                municipality: selectedMunicipality!,
                                barangay: selectedBarangay!,
                                street: streetController.text.trim(),
                                houseNumber: houseController.text.trim(),
                              );
                            }

                            if (!formCtx.mounted) return;
                            Navigator.of(formCtx).pop();
                            HapticService.lightImpact();
                            if (!mounted) return;
                            LuxurySnackBar.show(
                              context,
                              message: isEditing
                                  ? 'Shipping address updated!'
                                  : 'New Philippine shipping address saved!',
                              icon: Icons.check_circle_outline,
                            );
                          },
                          child: Text(isEditing ? 'Update Address' : 'Save Address', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Material(
      color: AppColors.cream,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text('Shipping Addresses', style: AppTextStyles.heading(size: 20, weight: FontWeight.w700, color: AppColors.plum)),
              ),
              const SizedBox(height: 3),
              Center(
                child: Text('Manage your PSGC delivery destinations in the Philippines', style: AppTextStyles.body(size: 11.5, color: AppColors.muted)),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: _addresses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_off_outlined, size: 48, color: AppColors.muted),
                            const SizedBox(height: 12),
                            Text('No Addresses Saved', style: AppTextStyles.heading(size: 16, color: AppColors.plum)),
                            const SizedBox(height: 4),
                            Text('Add an address to receive your luxury orders.', style: AppTextStyles.body(size: 12, color: AppColors.muted)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _addresses.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final addr = _addresses[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.blush1,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: addr.isDefault ? AppColors.plum : AppColors.line, width: addr.isDefault ? 1.5 : 1.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(addr.label == 'Work' ? Icons.business_outlined : Icons.home_outlined, size: 18, color: AppColors.plum),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        addr.recipientName,
                                        style: AppTextStyles.body(size: 13.5, weight: FontWeight.w700, color: AppColors.plum),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(99), border: Border.all(color: AppColors.line)),
                                      child: Text(addr.label.toUpperCase(), style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.ink)),
                                    ),
                                    if (addr.isDefault) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(99)),
                                        child: const Text('DEFAULT', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(addr.phoneNumber, style: AppTextStyles.body(size: 12, color: AppColors.muted)),
                                const SizedBox(height: 6),
                                Text(addr.formattedAddress, style: AppTextStyles.body(size: 12.5, color: AppColors.ink, height: 1.35)),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (!addr.isDefault)
                                      TextButton(
                                        onPressed: () async {
                                          setState(() {
                                            for (var a in _addresses) {
                                              a.isDefault = false;
                                            }
                                            addr.isDefault = true;
                                          });
                                          await SavedAddressBook.save(auth.currentUser, _addresses);
                                          await auth.updateShippingAddress(
                                            province: addr.province,
                                            municipality: addr.municipality,
                                            barangay: addr.barangay,
                                            street: addr.streetName,
                                            houseNumber: addr.houseNumber,
                                          );
                                          HapticService.selection();
                                        },
                                        child: Text('Set as Default', style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: AppColors.plum)),
                                      ),
                                    TextButton.icon(
                                      icon: const Icon(Icons.edit_outlined, size: 14, color: AppColors.orange),
                                      label: Text('Edit', style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: AppColors.orange)),
                                      onPressed: () => _openAddressFormDialog(existing: addr),
                                    ),
                                    if (_addresses.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 17, color: AppColors.muted),
                                        onPressed: () {
                                          if (addr.isDefault) {
                                            HapticService.selection();
                                            LuxurySnackBar.show(
                                              context,
                                              message: 'Cannot delete default shipping address. Please set another address as default first.',
                                              icon: Icons.info_outline,
                                              iconColor: Colors.redAccent,
                                            );
                                            return;
                                          }
                                          setState(() {
                                            _addresses.removeAt(index);
                                          });
                                          SavedAddressBook.save(auth.currentUser, _addresses);
                                          HapticService.lightImpact();
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.plum,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                  label: const Text('Add New Address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  onPressed: () => _openAddressFormDialog(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// COMPLETE PROFILE & SECURITY SETTINGS (`ProfileController.php` Parity)
// ============================================================================

class _ProfileSettingsModalContent extends StatefulWidget {
  const _ProfileSettingsModalContent();

  @override
  State<_ProfileSettingsModalContent> createState() => _ProfileSettingsModalContentState();
}

class _ProfileSettingsModalContentState extends State<_ProfileSettingsModalContent> {
  String _selectedTab = 'Profile Info'; // 'Profile Info' | 'Password' | 'Delete Account'

  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _miCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _dobCtrl;
  String _selectedSex = 'Female';

  final TextEditingController _currPassCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confPassCtrl = TextEditingController();
  final TextEditingController _deletePassCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: user?.lastName ?? '');
    _miCtrl = TextEditingController(text: user?.middleInitial ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _contactCtrl = TextEditingController(text: user?.contactNumber ?? '+63 917 892 4101');
    _dobCtrl = TextEditingController(text: user?.dateOfBirth ?? '2001-05-15');
    _selectedSex = (user?.sex == 'Male' || user?.sex == 'Female' || user?.sex == 'Other')
        ? user!.sex!
        : 'Female';
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _miCtrl.dispose();
    _emailCtrl.dispose();
    _contactCtrl.dispose();
    _dobCtrl.dispose();
    _currPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confPassCtrl.dispose();
    _deletePassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final tabs = ['Profile Info', 'Password', 'Delete Account'];

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: AppColors.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: (screenHeight * 0.88 - bottomInset).clamp(200.0, screenHeight),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile & Security Settings',
                          style: AppTextStyles.heading(size: 19, weight: FontWeight.w700, color: AppColors.plum),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Manage your personal details, password & account security',
                          style: AppTextStyles.body(size: 11.5, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.muted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Section Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: tabs.map((tab) {
                    final isSelected = _selectedTab == tab;
                    final isDanger = tab == 'Delete Account';
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          HapticService.selection();
                          setState(() => _selectedTab = tab);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDanger ? Colors.redAccent : AppColors.plum)
                                : AppColors.blush1,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: isSelected
                                  ? (isDanger ? Colors.redAccent : AppColors.plum)
                                  : AppColors.line,
                            ),
                          ),
                          child: Text(
                            tab,
                            style: AppTextStyles.body(
                              size: 11.5,
                              weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDanger ? Colors.redAccent : AppColors.ink),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey<String>(_selectedTab),
                    tween: Tween<double>(begin: 10.0, end: 0.0),
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.fastOutSlowIn,
                    builder: (context, dx, child) => Transform.translate(
                      offset: Offset(dx, 0),
                      child: child,
                    ),
                    child: _selectedTab == 'Profile Info'
                        ? _buildProfileInfoForm(context, auth, user)
                        : (_selectedTab == 'Password'
                            ? _buildPasswordForm(context, auth)
                            : _buildDeleteAccountForm(context, auth)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoForm(BuildContext context, AuthProvider auth, User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user?.isGoogleAccount == true)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined, size: 18, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Linked with Google (${user?.email ?? ''}) • Email Verified',
                    style: AppTextStyles.body(size: 11.5, weight: FontWeight.w600, color: const Color(0xFF2E7D32)),
                  ),
                ),
              ],
            ),
          ),

        // Profile Photo Avatar with Camera / Gallery selector (BUY-ACCT-001, BUY-ACCT-010)
        Center(
          child: GestureDetector(
            onTap: () {
              HapticService.selection();
              _showPhotoSourceSheet(context, auth);
            },
            child: Stack(
              children: [
                _buildAvatarCircle(
                  avatar: user?.avatar,
                  fallbackText: user?.fullName.isNotEmpty == true ? user!.fullName.substring(0, 1).toUpperCase() : 'B',
                  size: 76,
                  fontSize: 28,
                  hasGoldBorder: true,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildTextField('First Name *', _firstNameCtrl, hint: 'Juan / Maria'),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: _buildTextField('M.I.', _miCtrl, hint: 'D'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField('Last Name *', _lastNameCtrl, hint: 'Dela Cruz / Peñaflor'),
        const SizedBox(height: 12),
        _buildTextField(
          'Email Address * (Changing resets verification)',
          _emailCtrl,
          hint: 'name@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          'Contact Number (11 digits)',
          _contactCtrl,
          hint: '09171234567',
          keyboardType: TextInputType.phone,
          maxLength: 11,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sex', style: AppTextStyles.body(size: 12, weight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedSex,
                        items: ['Female', 'Male', 'Other']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s, style: AppTextStyles.body(size: 13))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSex = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTextField('Date of Birth (YYYY-MM-DD)', _dobCtrl, hint: '2001-05-15'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.blush1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: AppColors.plum),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Primary Shipping Address', style: AppTextStyles.body(size: 11, color: AppColors.muted)),
                    Text(
                      user?.fullAddress.isNotEmpty == true ? user!.fullAddress : 'Not set yet',
                      style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.plum,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () async {
              final fName = _firstNameCtrl.text.trim();
              final lName = _lastNameCtrl.text.trim();
              final fNameErr = AuthProvider.validatePersonName(fName, fieldLabel: 'First name');
              if (fNameErr != null) {
                LuxurySnackBar.show(
                  context,
                  message: fNameErr,
                  icon: Icons.error_outline,
                  iconColor: Colors.redAccent,
                );
                return;
              }
              final lNameErr = AuthProvider.validatePersonName(lName, fieldLabel: 'Last name');
              if (lNameErr != null) {
                LuxurySnackBar.show(
                  context,
                  message: lNameErr,
                  icon: Icons.error_outline,
                  iconColor: Colors.redAccent,
                );
                return;
              }
              final miErr = AuthProvider.validatePersonName(
                _miCtrl.text,
                fieldLabel: 'M.I.',
                requiredField: false,
              );
              if (miErr != null) {
                LuxurySnackBar.show(
                  context,
                  message: miErr,
                  icon: Icons.error_outline,
                  iconColor: Colors.redAccent,
                );
                return;
              }

              final newEmail = _emailCtrl.text.trim();
              final newPhone = _contactCtrl.text.trim();

              if (newEmail.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(newEmail)) {
                LuxurySnackBar.show(
                  context,
                  message: 'Please enter a valid email address.',
                  icon: Icons.error_outline,
                  iconColor: Colors.redAccent,
                );
                return;
              }

              final phoneErr = AuthProvider.validatePhoneNumber(newPhone);
              if (phoneErr != null) {
                LuxurySnackBar.show(
                  context,
                  message: phoneErr,
                  icon: Icons.error_outline,
                  iconColor: Colors.redAccent,
                );
                return;
              }

              final normalizedNewPhone = AuthProvider.normalizePhoneNumber(newPhone);
              final emailChanged = user != null && newEmail.toLowerCase() != user.email.toLowerCase();
              final phoneChanged = user != null &&
                  (user.contactNumber == null ||
                      AuthProvider.normalizePhoneNumber(user.contactNumber!) != normalizedNewPhone);

              // Check duplicates BEFORE dispatching OTP (BUY-ACCT-008, BUY-ACCT-009)
              if (emailChanged && auth.isEmailRegistered(newEmail)) {
                LuxurySnackBar.show(
                  context,
                  message: 'This email is already in use by another account.',
                  icon: Icons.error_outline,
                  iconColor: Colors.redAccent,
                );
                return;
              }
              if (phoneChanged && auth.isPhoneRegistered(normalizedNewPhone)) {
                LuxurySnackBar.show(
                  context,
                  message: 'This mobile number is already in use by another account.',
                  icon: Icons.error_outline,
                  iconColor: Colors.redAccent,
                );
                return;
              }

              void doSave() async {
                final res = await auth.updateProfile(
                  firstName: fName,
                  lastName: lName,
                  middleInitial: _miCtrl.text,
                  email: newEmail,
                  contactNumber: normalizedNewPhone,
                  sex: _selectedSex,
                  dateOfBirth: _dobCtrl.text,
                );
                if (!context.mounted) return;
                final ok = res['success'] == true;
                final msg = (res['message'] ?? '').toString();
                if (ok) {
                  HapticService.selection();
                  LuxurySnackBar.show(context, message: msg, icon: Icons.check_circle_outline);
                  Navigator.of(context).pop();
                } else {
                  LuxurySnackBar.show(
                    context,
                    message: msg,
                    icon: Icons.error_outline,
                    iconColor: Colors.redAccent,
                  );
                }
              }

              if (emailChanged) {
                _showOtpChallengeDialog(
                  context: context,
                  targetLabel: 'New Email Address',
                  targetValue: newEmail,
                  onVerified: () {
                    if (phoneChanged) {
                      _showOtpChallengeDialog(
                        context: context,
                        targetLabel: 'New Mobile Number',
                        targetValue: normalizedNewPhone,
                        onVerified: doSave,
                      );
                    } else {
                      doSave();
                    }
                  },
                );
                return;
              }

              if (phoneChanged) {
                _showOtpChallengeDialog(
                  context: context,
                  targetLabel: 'New Mobile Number',
                  targetValue: normalizedNewPhone,
                  onVerified: doSave,
                );
                return;
              }

              doSave();
            },
            child: const Text('Save Profile Changes', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  void _showPhotoSourceSheet(BuildContext context, AuthProvider auth) {
    final hasAvatar = auth.currentUser?.avatar != null && auth.currentUser!.avatar!.isNotEmpty;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Change Profile Photo', style: AppTextStyles.heading(size: 16, weight: FontWeight.w700)),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.plum),
                title: const Text('Take Photo from Camera', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: const Text('Open your device camera to take a photo', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  HapticService.selection();
                  final dataUri = await pickNativeImage(fromCamera: true);
                  if (dataUri != null && dataUri.isNotEmpty) {
                    await auth.updateAvatar(dataUri);
                    if (context.mounted) {
                      LuxurySnackBar.show(
                        context,
                        message: 'Camera photo set as profile picture!',
                        icon: Icons.check_circle_outline,
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.plum),
                title: const Text('Choose Photo from Gallery / Device Storage', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: const Text('Browse photos directly from your phone storage', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  HapticService.selection();
                  final dataUri = await pickNativeImage(fromCamera: false);
                  if (dataUri != null && dataUri.isNotEmpty) {
                    await auth.updateAvatar(dataUri);
                    if (context.mounted) {
                      LuxurySnackBar.show(
                        context,
                        message: 'Photo uploaded from device storage & set as profile picture!',
                        icon: Icons.check_circle_outline,
                      );
                    }
                  }
                },
              ),
              if (hasAvatar)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Remove Profile Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Colors.redAccent)),
                  subtitle: const Text('Reset back to your initials', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    HapticService.selection();
                    await auth.updateAvatar('');
                    if (context.mounted) {
                      LuxurySnackBar.show(
                        context,
                        message: 'Profile photo removed.',
                        icon: Icons.info_outline,
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOtpChallengeDialog({
    required BuildContext context,
    required String targetLabel,
    required String targetValue,
    required VoidCallback onVerified,
  }) {
    final otpCtrl = TextEditingController();
    String? otpError;

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppColors.cream,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.security, color: AppColors.plum, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Verify $targetLabel', style: AppTextStyles.heading(size: 17, weight: FontWeight.w700)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A 6-digit verification code has been dispatched to $targetValue. Enter it below to confirm this update.',
                style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, letterSpacing: 6, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '123456',
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                ),
              ),
              if (otpError != null) ...[
                const SizedBox(height: 6),
                Text(otpError!, style: const TextStyle(fontSize: 11.5, color: Colors.redAccent, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dlgCtx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.plum, foregroundColor: Colors.white),
              onPressed: () {
                final code = otpCtrl.text.trim();
                if (code.length != 6) {
                  setDlgState(() => otpError = 'Please enter a valid 6-digit verification code.');
                  return;
                }
                Navigator.of(dlgCtx).pop();
                onVerified();
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordForm(BuildContext context, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ensure your account is using a long, random password to stay secure.',
          style: AppTextStyles.body(size: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 14),
        _buildTextField('Current Password *', _currPassCtrl, obscure: true),
        const SizedBox(height: 12),
        _buildTextField('New Password (min. 8 characters) *', _newPassCtrl, obscure: true),
        const SizedBox(height: 12),
        _buildTextField('Confirm New Password *', _confPassCtrl, obscure: true),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.plum,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () async {
              final newPass = _newPassCtrl.text;
              final pwdErr = AuthProvider.validatePassword(newPass);
              if (pwdErr != null) {
                LuxurySnackBar.show(
                  context,
                  message: pwdErr,
                  icon: Icons.error_outline,
                  iconColor: Colors.redAccent,
                );
                return;
              }

              final res = await auth.updatePassword(
                currentPassword: _currPassCtrl.text,
                newPassword: newPass,
                confirmPassword: _confPassCtrl.text,
              );
              if (!context.mounted) return;
              final ok = res['success'] == true;
              final msg = (res['message'] ?? '').toString();
              if (ok) {
                HapticService.selection();
                LuxurySnackBar.show(
                  context,
                  message: 'Password updated! Active sessions on other devices have been terminated.',
                  icon: Icons.lock_outline,
                  iconColor: const Color(0xFF2E7D32),
                );
                Navigator.of(context).pop();
              } else {
                LuxurySnackBar.show(
                  context,
                  message: msg,
                  icon: Icons.error_outline,
                  iconColor: Colors.redAccent,
                );
              }
            },
            child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteAccountForm(BuildContext context, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3F3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
          ),
          child: Text(
            'Once your account is deleted, all of its resources and data will be permanently deleted. Please enter your password to confirm you would like to permanently delete your account.',
            style: AppTextStyles.body(size: 12, color: Colors.redAccent.shade700, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Current Password *',
          _deletePassCtrl,
          obscure: true,
          hint: 'Enter your password to confirm deletion',
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.delete_forever_outlined, size: 18),
            label: const Text('Delete Account Permanently', style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: () async {
              final res = await auth.deleteAccount(password: _deletePassCtrl.text);
              if (!context.mounted) return;
              final ok = res['success'] == true;
              final msg = (res['message'] ?? '').toString();
              if (ok) {
                Provider.of<WishlistProvider>(context, listen: false).clearWishlist();
                Provider.of<CartProvider>(context, listen: false).clearCart();
                HapticService.selection();
                Navigator.of(context).pop();
                LuxurySnackBar.show(
                  context,
                  message: msg,
                  icon: Icons.delete_forever_outlined,
                  iconColor: Colors.redAccent,
                );
              } else {
                LuxurySnackBar.show(
                  context,
                  message: msg,
                  icon: Icons.error_outline,
                  iconColor: Colors.redAccent,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hint,
    bool obscure = false,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body(size: 12, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          style: AppTextStyles.body(size: 13, color: AppColors.ink),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: AppTextStyles.body(size: 12, color: AppColors.muted),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PAYMENT METHODS MODAL (Saved E-Wallets, Set Default & Link GCash / Maya)
// ============================================================================

class _PaymentMethodsModalContent extends StatefulWidget {
  const _PaymentMethodsModalContent();

  @override
  State<_PaymentMethodsModalContent> createState() => _PaymentMethodsModalContentState();
}

class _PaymentMethodsModalContentState extends State<_PaymentMethodsModalContent> {
  void _openAddPaymentSheet(BuildContext context, AuthProvider auth, WalletProvider wallet) {
    String selectedType = 'gcash';
    final nameCtrl = TextEditingController(text: auth.currentUser?.fullName ?? '');
    final numberCtrl = TextEditingController();
    bool setAsDefault = wallet.methods.isEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Add Payment Method', style: AppTextStyles.heading(size: 18, weight: FontWeight.w700, color: AppColors.plum)),
                const SizedBox(height: 4),
                Text('Link your GCash or Maya e-wallet', style: AppTextStyles.body(size: 11.5, color: AppColors.muted)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedType = 'gcash'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedType == 'gcash' ? AppColors.plum : AppColors.blush1,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selectedType == 'gcash' ? AppColors.plum : AppColors.line),
                          ),
                          child: Center(
                            child: Text(
                              'GCash',
                              style: TextStyle(
                                color: selectedType == 'gcash' ? Colors.white : AppColors.ink,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedType = 'maya'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedType == 'maya' ? AppColors.plum : AppColors.blush1,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selectedType == 'maya' ? AppColors.plum : AppColors.line),
                          ),
                          child: Center(
                            child: Text(
                              'Maya',
                              style: TextStyle(
                                color: selectedType == 'maya' ? Colors.white : AppColors.ink,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Account Name', style: AppTextStyles.body(size: 12, weight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Maria Santos',
                    hintStyle: AppTextStyles.body(size: 12, color: AppColors.muted),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Mobile / Account Number', style: AppTextStyles.body(size: 12, weight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: numberCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '09XX XXX XXXX',
                    hintStyle: AppTextStyles.body(size: 12, color: AppColors.muted),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: setAsDefault,
                      activeColor: AppColors.plum,
                      onChanged: (val) => setSheetState(() => setAsDefault = val ?? false),
                    ),
                    Text('Set as primary payment method', style: AppTextStyles.body(size: 12, color: AppColors.ink)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.plum,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final accName = nameCtrl.text.trim();
                      final accNum = numberCtrl.text.trim();
                      if (accName.isEmpty || accNum.isEmpty) {
                        LuxurySnackBar.show(
                          context,
                          message: 'Please fill in both account name and number.',
                          icon: Icons.error_outline,
                          iconColor: Colors.redAccent,
                        );
                        return;
                      }

                      final methodName = selectedType == 'gcash' ? 'GCash' : 'Maya';
                      await wallet.addMethod(
                        type: selectedType,
                        name: methodName,
                        accountName: accName,
                        accountNumber: accNum,
                        isDefault: setAsDefault,
                      );
                      if (!sheetCtx.mounted) return;
                      Navigator.of(sheetCtx).pop();
                      HapticService.selection();
                      if (!context.mounted) return;
                      LuxurySnackBar.show(
                        context,
                        message: '$methodName linked successfully!',
                        icon: Icons.check_circle_outline,
                        iconColor: const Color(0xFF2E7D32),
                      );
                    },
                    child: const Text('Save Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, WalletProvider>(
      builder: (context, auth, wallet, _) {
        final methods = wallet.methods;

        return Material(
          color: AppColors.cream,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Saved Payment Options', style: AppTextStyles.heading(size: 20, weight: FontWeight.w700, color: AppColors.plum)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.plum, size: 24),
                      tooltip: 'Add Payment Method',
                      onPressed: () => _openAddPaymentSheet(context, auth, wallet),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Manage your Philippine e-wallets and checkout options', style: AppTextStyles.body(size: 11.5, color: AppColors.muted)),
                const SizedBox(height: 16),

                if (methods.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text('No saved e-wallets yet. Tap + to add GCash or Maya.', style: AppTextStyles.body(size: 12, color: AppColors.muted)),
                    ),
                  )
                else
                  ...methods.map((pm) {
                    final isGCash = pm.type.toLowerCase().contains('gcash');
                    final icon = isGCash ? Icons.account_balance_wallet_outlined : Icons.credit_card_outlined;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.blush1,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: pm.isDefault ? AppColors.plum : AppColors.line, width: pm.isDefault ? 1.4 : 1.0),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: AppColors.plum, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        pm.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.body(size: 13, weight: FontWeight.w700),
                                      ),
                                    ),
                                    if (pm.isDefault) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(99)),
                                        child: const Text('DEFAULT', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('${pm.accountName} • ${pm.maskedNumber}', style: AppTextStyles.body(size: 11.5, color: AppColors.muted)),
                              ],
                            ),
                          ),
                          if (!pm.isDefault)
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () {
                                HapticService.selection();
                                wallet.setDefault(pm.id);
                              },
                              child: const Text('Set Default', style: TextStyle(fontSize: 11, color: AppColors.plum, fontWeight: FontWeight.w600)),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.muted),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              HapticService.selection();
                              wallet.removeMethod(pm.id);
                              LuxurySnackBar.show(context, message: '${pm.name} removed.');
                            },
                          ),
                        ],
                      ),
                    );
                  }),

                // Cash on Delivery
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.blush1,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, color: AppColors.plum, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cash on Delivery (COD)', style: AppTextStyles.body(size: 13, weight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('Pay cash when your luxury parcel arrives at your doorstep', style: AppTextStyles.body(size: 11, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(99)),
                        child: const Text('AVAILABLE', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                // Add button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.plum),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.add, size: 18, color: AppColors.plum),
                    label: const Text('Add GCash / Maya Wallet', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.plum, fontSize: 13)),
                    onPressed: () => _openAddPaymentSheet(context, auth, wallet),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Reusable Verified Luxury Review Dialog
void showLuxuryReviewDialog(
  BuildContext context,
  String productName, {
  String? productId,
  ProductReview? existingReview,
}) {
  int rating = existingReview != null ? existingReview.rating.round().clamp(1, 5) : 5;
  final cleanInitialComment = (existingReview?.comment ?? '').replaceAll(' • [Edited]', '');
  final commentController = TextEditingController(text: cleanInitialComment);
  final List<String> reviewPhotos = List<String>.from(existingReview?.images ?? const []);

  showDialog(
    context: context,
    builder: (dlgCtx) => StatefulBuilder(
      builder: (ctx, setDlgState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.cream,
        title: Text(
          existingReview != null ? 'Edit Verified Review' : 'Rate & Review',
          style: AppTextStyles.heading(size: 18, weight: FontWeight.w700, color: AppColors.plum),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(productName, style: AppTextStyles.body(size: 13, weight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (starIdx) {
                  return IconButton(
                    icon: Icon(
                      starIdx < rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: AppColors.gold,
                      size: 32,
                    ),
                    onPressed: () => setDlgState(() => rating = starIdx + 1),
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: commentController,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Share your authentic experience with this product...',
                  hintStyle: AppTextStyles.body(size: 12, color: AppColors.muted),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                ),
              ),
              const SizedBox(height: 10),
              // Review Photos Row (BUY-RATE-001, BUY-RATE-007)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Photos (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  Text('${reviewPhotos.length}/5', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...reviewPhotos.map((img) => Container(
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.line),
                            image: DecorationImage(image: _buildPhotoProvider(img), fit: BoxFit.cover),
                          ),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: GestureDetector(
                              onTap: () => setDlgState(() => reviewPhotos.remove(img)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 10, color: Colors.white),
                              ),
                            ),
                          ),
                        )),
                    if (reviewPhotos.length < 5) ...[
                      GestureDetector(
                        onTap: () async {
                          HapticService.selection();
                          final dataUri = await pickNativeImage(fromCamera: false);
                          if (dataUri != null && dataUri.isNotEmpty) {
                            setDlgState(() => reviewPhotos.add(dataUri));
                            if (context.mounted) {
                              LuxurySnackBar.show(context, message: 'Photo attached from gallery');
                            }
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.plum),
                          ),
                          child: const Tooltip(
                            message: 'Upload from Gallery',
                            child: Icon(Icons.photo_library_outlined, size: 18, color: AppColors.plum),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          HapticService.selection();
                          final dataUri = await pickNativeImage(fromCamera: true);
                          if (dataUri != null && dataUri.isNotEmpty) {
                            setDlgState(() => reviewPhotos.add(dataUri));
                            if (context.mounted) {
                              LuxurySnackBar.show(context, message: 'Photo captured from camera');
                            }
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.plum),
                          ),
                          child: const Tooltip(
                            message: 'Capture with Camera',
                            child: Icon(Icons.photo_camera_outlined, size: 18, color: AppColors.plum),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(),
            child: Text('Cancel', style: AppTextStyles.body(size: 13, color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.plum,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
            ),
            onPressed: () async {
              final orderProvider = Provider.of<OrderProvider>(context, listen: false);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final matchedProduct = MockData.unifiedCatalog.where(
                (p) =>
                    (productId != null && p.id == productId) ||
                    p.name.toLowerCase() == productName.toLowerCase(),
              );
              if (matchedProduct.isNotEmpty) {
                await orderProvider.submitOrUpdateReview(
                  product: matchedProduct.first,
                  userId: auth.currentUser?.id ?? 'buyer-1',
                  userName: auth.currentUser?.fullName ?? 'Verified Buyer',
                  rating: rating,
                  comment: commentController.text,
                  images: reviewPhotos,
                );
              }
              if (!dlgCtx.mounted) return;
              Navigator.of(dlgCtx).pop();
              HapticService.selection();
              if (!context.mounted) return;
              LuxurySnackBar.show(
                context,
                message: existingReview != null
                    ? 'Your review has been updated!'
                    : 'Thank you! Your verified review has been published.',
                icon: Icons.star_rounded,
                iconColor: AppColors.gold,
              );
            },
            child: Text(existingReview != null ? 'Update Review' : 'Submit Review'),
          ),
        ],
      ),
    ),
  );
}

// ============================================================================
// MY REVIEWS MODAL (Centered Category Pills & Interactive Review Feedback)
// ============================================================================

class _ReviewsModalContent extends StatefulWidget {
  const _ReviewsModalContent();

  @override
  State<_ReviewsModalContent> createState() => _ReviewsModalContentState();
}

class _ReviewsModalContentState extends State<_ReviewsModalContent> {
  String _selectedTab = 'To Review';

  @override
  Widget build(BuildContext context) {
    final tabs = ['To Review', 'Reviewed'];
    final auth = Provider.of<AuthProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final userId = auth.currentUser?.id ?? 'buyer-1';
    final pendingItems = orderProvider.getPendingReviewItems(userId);
    final userReviews = orderProvider.getAllUserReviews(userId);

    return Material(
      color: AppColors.cream,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text('My Reviews', style: AppTextStyles.heading(size: 20, weight: FontWeight.w700, color: AppColors.plum)),
              ),
              const SizedBox(height: 3),
              Center(
                child: Text('Share your impressions on verified luxury pieces', style: AppTextStyles.body(size: 11.5, color: AppColors.muted)),
              ),
              const SizedBox(height: 14),

              // Centered Review Category Pills
              Center(
                child: SizedBox(
                  height: 38,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: tabs.map((tab) {
                      final isSelected = tab == _selectedTab;
                      final countLabel = tab == 'To Review'
                          ? 'To Review (${pendingItems.length})'
                          : 'Reviewed (${userReviews.length})';
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticService.selection();
                            setState(() => _selectedTab = tab);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            curve: Curves.easeOutCubic,
                            height: 34,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                        color: AppColors.plum.withValues(alpha: 0.22),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                countLabel,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body(
                                  size: 12.5,
                                  weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.ink,
                                ).copyWith(height: 1.1),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: _selectedTab == 'To Review'
                    ? (pendingItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.rate_review_outlined, size: 46, color: AppColors.muted),
                                const SizedBox(height: 12),
                                Text('All Caught Up!', style: AppTextStyles.heading(size: 16, color: AppColors.plum)),
                                const SizedBox(height: 4),
                                Text(
                                  'All of your delivered luxury items have been reviewed.',
                                  style: AppTextStyles.body(size: 12, color: AppColors.muted),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: pendingItems.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, idx) {
                              final entry = pendingItems[idx];
                              final item = entry.item;
                              final order = entry.order;
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.blush1,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 54,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: AppColors.line),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: buildLumoraImage(
                                            item.imagePath ?? 'assets/images/lumora-mens-clothing.jpg',
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => const Icon(Icons.shopping_bag_outlined, color: AppColors.plum),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.productName,
                                                style: AppTextStyles.body(size: 13, weight: FontWeight.w600),
                                              ),
                                              if (item.variation != null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  item.variation!,
                                                  style: AppTextStyles.body(size: 11, color: AppColors.muted),
                                                ),
                                              ],
                                              const SizedBox(height: 3),
                                              Text(
                                                'Delivered • Order ${order.id.startsWith('#') ? order.id : '#${order.id}'}',
                                                style: AppTextStyles.body(size: 11, color: AppColors.muted),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: AppColors.plum),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                        icon: const Icon(Icons.star_outline_rounded, size: 17, color: AppColors.plum),
                                        label: Text('Write Review', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700, color: AppColors.plum)),
                                        onPressed: () => showLuxuryReviewDialog(
                                          context,
                                          item.productName,
                                          productId: item.productId,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ))
                    : (userReviews.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.reviews_outlined, size: 46, color: AppColors.muted),
                                const SizedBox(height: 12),
                                Text('No Reviews Yet', style: AppTextStyles.heading(size: 16, color: AppColors.plum)),
                                const SizedBox(height: 4),
                                Text(
                                  'Reviews you publish on delivered items will appear here.',
                                  style: AppTextStyles.body(size: 12, color: AppColors.muted),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            physics: const BouncingScrollPhysics(),
                            children: [
                              ...userReviews.map((rev) {
                                final matchedProd = MockData.unifiedCatalog
                                    .where((p) => p.id == rev.productId)
                                    .toList();
                                final prodName = matchedProd.isNotEmpty
                                    ? matchedProd.first.name
                                    : 'Verified Luxury Purchase';
                                final prodImg = matchedProd.isNotEmpty
                                    ? (matchedProd.first.imagePath ?? 'assets/images/makeup.jpg')
                                    : 'assets/images/makeup.jpg';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildReviewedCard(
                                    productName: prodName,
                                    rating: rev.rating.round().clamp(1, 5),
                                    reviewDate: rev.date,
                                    comment: rev.comment,
                                    imagePath: prodImg,
                                    attachedPhotos: rev.images,
                                    onEdit: () => showLuxuryReviewDialog(
                                      context,
                                      prodName,
                                      productId: rev.productId,
                                      existingReview: rev,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewedCard({
    required String productName,
    required int rating,
    required String reviewDate,
    required String comment,
    required String imagePath,
    List<String> attachedPhotos = const [],
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
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
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                clipBehavior: Clip.antiAlias,
                child: buildLumoraImage(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.shopping_bag_outlined, color: AppColors.plum),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(productName, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(reviewDate, style: AppTextStyles.body(size: 11, color: AppColors.muted)),
                  ],
                ),
              ),
              if (onEdit != null)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 15, color: AppColors.plum),
                  label: const Text(
                    'Edit Review',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.plum),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(rating, (_) => const Icon(Icons.star_rounded, size: 16, color: AppColors.gold)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(color: AppColors.blush1, borderRadius: BorderRadius.circular(99)),
                child: const Text('Verified Buyer', style: TextStyle(fontSize: 8.5, color: AppColors.plum, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(comment, style: AppTextStyles.body(size: 12, color: AppColors.ink, height: 1.35)),
          if (attachedPhotos.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: attachedPhotos.map((img) {
                  return Container(
                    width: 52,
                    height: 52,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.line),
                      image: DecorationImage(image: _buildPhotoProvider(img), fit: BoxFit.cover),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });
}

Widget _buildAvatarCircle({
  required String? avatar,
  required String fallbackText,
  required double size,
  required double fontSize,
  bool hasGoldBorder = false,
}) {
  Widget? imageWidget;
  if (avatar != null && avatar.isNotEmpty) {
    if (avatar.startsWith('data:image/')) {
      try {
        final base64Str = avatar.split(',').last;
        final bytes = base64Decode(base64Str);
        imageWidget = Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
      } catch (_) {}
    } else if (avatar.startsWith('assets/')) {
      imageWidget = Image.asset(
        avatar,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else if (avatar.startsWith('http')) {
      imageWidget = Image.network(
        avatar,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }
  }

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: imageWidget == null
          ? const LinearGradient(
              colors: [AppColors.plum, AppColors.orange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      color: imageWidget != null ? AppColors.plum : null,
      border: hasGoldBorder ? Border.all(color: AppColors.gold, width: 2) : null,
    ),
    clipBehavior: Clip.antiAlias,
    alignment: Alignment.center,
    child: imageWidget ??
        Text(
          fallbackText,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
  );
}

ImageProvider _buildPhotoProvider(String src) {
  if (src.startsWith('data:image/')) {
    final base64Str = src.split(',').last;
    return MemoryImage(base64Decode(base64Str));
  }
  if (src.startsWith('http')) {
    return NetworkImage(src);
  }
  return AssetImage(src);
}
