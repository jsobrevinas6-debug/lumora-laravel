import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_modal.dart';
import '../widgets/cards.dart';
import '../widgets/luxury_snackbar.dart';
import '../widgets/voucher_selection_modal.dart';
import 'checkout_screen.dart';
import 'login_screen.dart';
import 'product_detail_screen.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onBrowseProducts;

  const CartScreen({super.key, this.onBrowseProducts});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isVipShippingEnabled = false;
  String _selectedAddress = 'Sitio, Ilaya, Pagsanjan, Laguna, 4008';
  VoucherModel? _appliedVoucher;
  bool _isOrderSummaryExpanded = false;

  final List<String> _philippineAddresses = [
    'Sitio, Ilaya, Pagsanjan, Laguna, 4008',
    'Unit 402, Acacia Residences, Katipunan Ave., Quezon City, Metro Manila 1108',
    'Two Serendra, 26th St., BGC, Taguig City, Metro Manila 1634',
    'Tower 2, Ayala Center, Cebu Business Park, Cebu City, 6000',
  ];
  bool _addressSyncedFromAuth = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userAddr = Provider.of<AuthProvider>(context).currentUser?.fullAddress ?? '';
    if (userAddr.isNotEmpty) {
      if (!_philippineAddresses.contains(userAddr)) {
        _philippineAddresses.insert(0, userAddr);
      }
      if (!_addressSyncedFromAuth) {
        _addressSyncedFromAuth = true;
        _selectedAddress = userAddr;
      }
    }
  }

  int _getStockForProduct(Product p) {
    if (p.stock <= 3) return p.stock;
    // Provide realistic low stock urgency like in Zalora (1 left, 2 left, etc.)
    final hash = p.name.hashCode.abs();
    final modulo = (hash % 4) + 1;
    return modulo;
  }

  double _getOriginalPriceForProduct(Product p) {
    if (p.originalPrice != null && p.originalPrice! > p.price) {
      return p.originalPrice!;
    }
    return p.price * 1.15;
  }

  int _getDiscountPercentage(Product p) {
    final original = _getOriginalPriceForProduct(p);
    return (((original - p.price) / original) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final items = cart.itemList;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, cart, auth),
              Expanded(
                child: !auth.isLoggedIn
                    ? _buildGuestCartPrompt(context)
                    : (items.isEmpty
                        ? _buildEmptyCart(context)
                        : _buildCartContent(context, cart, items)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. TOP HEADER — matches Deals / Categories luxury header style
  Widget _buildTopBar(BuildContext context, CartProvider cart, AuthProvider auth) {
    final count = auth.isLoggedIn ? cart.totalItemsCount : 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        children: [
          if (Navigator.of(context).canPop()) ...[
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.plum),
            ),
            const SizedBox(width: 10),
          ],
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.rose.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.rose, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Bag',
                  style: AppTextStyles.heading(
                    size: 22,
                    weight: FontWeight.w700,
                    color: AppColors.plum,
                  ),
                ),
                Text(
                  count > 0
                      ? '$count ${count == 1 ? 'item' : 'items'} ready for checkout'
                      : 'Your curated luxury selections',
                  style: AppTextStyles.body(size: 11.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          if (auth.isLoggedIn && cart.itemList.isNotEmpty)
            GestureDetector(
              onTap: () => _confirmClearCart(context, cart),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.line),
                ),
                child: Text(
                  'Clear',
                  style: AppTextStyles.body(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppColors.rose,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 3. MAIN CART SCROLLABLE CONTENT
  Widget _buildCartContent(
    BuildContext context,
    CartProvider cart,
    List<CartItem> items,
  ) {
    // Dynamic store grouping (BUY-CART-003)
    final Map<String, List<CartItem>> itemsByStore = {};
    for (final it in items) {
      final sName = it.product.sellerName;
      itemsByStore.putIfAbsent(sName, () => []).add(it);
    }

    final subtotal = cart.selectedSubtotal;
    final baseShipping = _isVipShippingEnabled
        ? 0.0
        : (cart.selectedItemsCount == 0 ? 0.0 : cart.selectedShippingFee);
    final voucherDiscount = _appliedVoucher?.calculateDiscount(subtotal, baseShipping) ?? 0.0;
    final effectiveShipping = max(0.0, baseShipping - (_appliedVoucher?.type == VoucherType.freeShipping ? voucherDiscount : 0.0));
    final effectiveTotal = max(0.0, subtotal + effectiveShipping - (_appliedVoucher?.type != VoucherType.freeShipping ? voucherDiscount : 0.0));

    // Calculate total product discount + voucher savings
    double originalSubtotal = 0.0;
    for (final it in cart.selectedItemList) {
      originalSubtotal += _getOriginalPriceForProduct(it.product) * it.quantity;
    }
    final productSavings = max(0.0, originalSubtotal - subtotal);
    final totalSavings = productSavings + voucherDiscount + (_isVipShippingEnabled ? 50.0 : 0.0);

    return Column(
      children: [
        if (cart.isOffline || cart.hasPendingSync)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFFFF3CD),
            child: Row(
              children: [
                const Icon(Icons.cloud_queue_outlined, size: 16, color: Color(0xFF856404)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cart.hasPendingSync
                        ? 'Offline changes pending sync once reconnected.'
                        : 'Offline Mode: Browsing cached bag items.',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF856404), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              const SizedBox(height: 10),

              // Delivery Address Card
              _buildAddressCard(context),

              const SizedBox(height: 8),

              // VIP Unlimited Free Shipping Banner with Switch
              _buildVipShippingBanner(context),

              const SizedBox(height: 12),

              // Dynamic Store Group Sections (BUY-CART-003)
              ...itemsByStore.entries.map((entry) {
                final isIntl = entry.key.toLowerCase().contains('international');
                final badge = isIntl ? 'LI' : 'L';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildStoreSection(
                    context: context,
                    cart: cart,
                    storeName: entry.key,
                    storeItems: entry.value,
                    badgeText: badge,
                    isInternational: isIntl,
                  ),
                );
              }),
            ],
          ),
        ),

        // Floating Voucher Selector Strip
        _buildFloatingVoucherBar(context, subtotal, baseShipping),

        // Bottom Sticky Checkout Bar
        _buildBottomCheckoutBar(
          context: context,
          cart: cart,
          effectiveGrandTotal: effectiveTotal,
          effectiveShippingFee: effectiveShipping,
          totalSavings: totalSavings,
        ),
      ],
    );
  }

  // 4. DELIVERY ADDRESS CARD
  Widget _buildAddressCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showAddressSelectionModal(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 20, color: AppColors.ink),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(
                      size: 13,
                      weight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 5. VIP UNLIMITED FREE SHIPPING BANNER
  Widget _buildVipShippingBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEADBFF), Color(0xFFD3C2FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC7B1F5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    const Text(
                      'Get Unlimited Free Shipping with',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C1E4A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5E35B1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        'VIP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      '1 year of free shipping for just ₱500 ',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF4A3B66),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showVipInfoDialog(context),
                      child: const Text(
                        'Learn more',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF5E35B1),
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isVipShippingEnabled,
            activeTrackColor: const Color(0xFF5E35B1),
            onChanged: (val) {
              HapticService.selection();
              setState(() => _isVipShippingEnabled = val);
              LuxurySnackBar.show(
                context,
                message: val
                    ? 'VIP Unlimited Free Shipping activated! ₱50 shipping waived.'
                    : 'VIP Free Shipping turned off.',
                icon: val ? Icons.verified : Icons.info_outline,
                iconColor: const Color(0xFF5E35B1),
              );
            },
          ),
        ],
      ),
    );
  }

  // 6. STORE GROUP SECTION
  Widget _buildStoreSection({
    required BuildContext context,
    required CartProvider cart,
    required String storeName,
    required List<CartItem> storeItems,
    required String badgeText,
    required bool isInternational,
  }) {
    final allStoreSelected = storeItems.isNotEmpty && storeItems.every((item) => item.isSelected);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cream,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildCustomCheckbox(
                  isSelected: allStoreSelected,
                  onTap: () {
                    HapticService.selection();
                    final target = !allStoreSelected;
                    for (final it in storeItems) {
                      cart.setItemSelection(it.itemKey, target);
                    }
                  },
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.ink, width: 1.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
              ],
            ),
          ),

          // International Shipping Badge (if applicable)
          if (isInternational) ...[
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: const [
                  Icon(Icons.flight_takeoff, size: 15, color: Color(0xFF1967D2)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'International Shipping. Get by 14-22 Sep.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1967D2),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Items inside this store
          ...storeItems.map((cartItem) {
            return Dismissible(
              key: ValueKey('cart_item_${cartItem.itemKey}'),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.rose,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Text(
                      'Remove',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.delete_outline, color: Colors.white, size: 22),
                  ],
                ),
              ),
              confirmDismiss: (direction) async {
                HapticService.lightImpact();
                return true;
              },
              onDismissed: (direction) {
                HapticService.mediumImpact();
                final removedName = cartItem.product.name;
                cart.removeFromCart(cartItem.itemKey);
                LuxurySnackBar.show(
                  context,
                  message: 'Removed "$removedName" from bag',
                  icon: Icons.delete_outline,
                  iconColor: AppColors.rose,
                );
              },
              child: _buildProductCard(context, cartItem, cart),
            );
          }),
        ],
      ),
    );
  }

  // 7. PRODUCT ITEM CARD (Matching Zalora / luxury reference)
  Widget _buildProductCard(
    BuildContext context,
    CartItem cartItem,
    CartProvider cart,
  ) {
    final p = cartItem.product;
    final stockLeft = _getStockForProduct(p);
    final originalPrice = _getOriginalPriceForProduct(p);
    final discountPercent = _getDiscountPercentage(p);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF0EBE9), width: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Checkbox
              Padding(
                padding: const EdgeInsets.only(top: 36, right: 12),
                child: _buildCustomCheckbox(
                  isSelected: cartItem.isSelected,
                  onTap: () {
                    HapticService.selection();
                    cart.toggleItemSelection(cartItem.itemKey);
                  },
                ),
              ),

              // Product Image
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: p),
                    ),
                  );
                },
                child: Container(
                  width: 86,
                  height: 106,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: p.imagePath != null
                      ? buildLumoraImage(
                          p.imagePath!,
                          fit: BoxFit.cover,
                          cacheWidth: 240,
                          errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(p),
                        )
                      : _buildFallbackThumbnail(p),
                ),
              ),

              const SizedBox(width: 12),

              // Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand & More Options Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (p.brand.isNotEmpty ? p.brand : p.category).toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.muted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body(
                                  size: 13.5,
                                  weight: FontWeight.w600,
                                  color: AppColors.ink,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert, size: 18, color: AppColors.muted),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _showItemMoreOptions(context, cartItem, cart),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Variant, Quantity, and Stock Badges Row
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Variation Pill (Zalora Style)
                        GestureDetector(
                          onTap: () => _showVariantPicker(context, cartItem, cart),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFD0D0D0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 130),
                                  child: Text(
                                    cartItem.variationLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.muted),
                              ],
                            ),
                          ),
                        ),

                        // Quantity Pill
                        GestureDetector(
                          onTap: () => _showQuantityPicker(context, cartItem, cart),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFD0D0D0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'x${cartItem.quantity}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
                                ),
                                const SizedBox(width: 3),
                                const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.muted),
                              ],
                            ),
                          ),
                        ),

                        // Stock Urgency Badge (1 left / 2 left)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: stockLeft <= 2
                                ? const Color(0xFFFFEBEE)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            stockLeft <= 2 ? '$stockLeft left' : 'In Stock',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: stockLeft <= 2
                                  ? const Color(0xFFD32F2F)
                                  : const Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Free Return Guarantee Notice
                    const Text(
                      '30 Days Free Return | T&C Apply',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Price Line
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Icon(Icons.confirmation_number_outlined, size: 14, color: Color(0xFFD32F2F)),
                          const SizedBox(width: 3),
                          Text(
                            '₱${cartItem.unitPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD32F2F),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '₱${originalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-$discountPercent%',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFD32F2F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Item Promo / Voucher Strip
          GestureDetector(
            onTap: () => _openVoucherSelector(context, cart),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFDBC9)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_outlined, size: 14, color: Color(0xFFD32F2F)),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      '₱150 off with Lumora Voucher',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2426),
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackThumbnail(Product p) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: p.gradient ?? [AppColors.plumLight, AppColors.plum],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        p.icon,
        color: Colors.white.withValues(alpha: 0.9),
        size: 28,
      ),
    );
  }

  // 8. FLOATING VOUCHER CODE STRIP
  Widget _buildFloatingVoucherBar(
    BuildContext context,
    double subtotal,
    double shippingFee,
  ) {
    final hasVoucher = _appliedVoucher != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasVoucher ? const Color(0xFF2E7D32) : AppColors.line,
          width: hasVoucher ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openVoucherSelector(context, Provider.of<CartProvider>(context, listen: false)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  size: 18,
                  color: hasVoucher ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasVoucher
                        ? 'Voucher Applied: ${_appliedVoucher!.code} (${_appliedVoucher!.badge})'
                        : 'Enter voucher code or gift card',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: hasVoucher ? FontWeight.w700 : FontWeight.w500,
                      color: hasVoucher ? const Color(0xFF2E7D32) : AppColors.ink,
                    ),
                  ),
                ),
                if (hasVoucher)
                  GestureDetector(
                    onTap: () {
                      setState(() => _appliedVoucher = null);
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.close, size: 16, color: AppColors.muted),
                    ),
                  ),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 9. BOTTOM STICKY CHECKOUT BAR (Exact styling from user's image)
  Widget _buildBottomCheckoutBar({
    required BuildContext context,
    required CartProvider cart,
    required double effectiveGrandTotal,
    required double effectiveShippingFee,
    required double totalSavings,
  }) {
    final selectedCount = cart.selectedItemsCount;
    final isEmbeddedInMainTab = !Navigator.of(context).canPop();
    final floatingNavClearance = isEmbeddedInMainTab ? 84.0 : 0.0;

    return Container(
      margin: isEmbeddedInMainTab
          ? const EdgeInsets.fromLTRB(12, 0, 12, 86)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isEmbeddedInMainTab ? BorderRadius.circular(18) : null,
        border: isEmbeddedInMainTab
            ? Border.all(color: const Color(0xFFE5E5E5))
            : const Border(top: BorderSide(color: Color(0xFFE5E5E5))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: !isEmbeddedInMainTab,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            isEmbeddedInMainTab ? 10 : (12 + floatingNavClearance),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Expandable order breakdown details (if user toggled chevron)
              if (_isOrderSummaryExpanded) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Selected Items Subtotal', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                          Text('₱${cart.selectedSubtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Shipping Fee', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                          Text(effectiveShippingFee == 0 ? 'FREE' : '₱${effectiveShippingFee.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: effectiveShippingFee == 0 ? const Color(0xFF2E7D32) : AppColors.ink)),
                        ],
                      ),
                      if (_appliedVoucher != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Voucher (${_appliedVoucher!.code})', style: const TextStyle(fontSize: 12, color: Color(0xFFD32F2F))),
                            Text('-₱${_appliedVoucher!.calculateDiscount(cart.selectedSubtotal, effectiveShippingFee).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFD32F2F))),
                          ],
                        ),
                      ],
                      const Divider(color: Color(0xFFE5E5E5), height: 16),
                    ],
                  ),
                ),
              ],

              // Main Bottom Bar Row
              Row(
                children: [
                  // Select All Checkbox
                  _buildCustomCheckbox(
                    isSelected: cart.isAllSelected,
                    onTap: () {
                      HapticService.selection();
                      cart.setAllSelected(!cart.isAllSelected);
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Total & Savings Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() => _isOrderSummaryExpanded = !_isOrderSummaryExpanded);
                              },
                              child: Icon(
                                _isOrderSummaryExpanded
                                    ? Icons.keyboard_arrow_down
                                    : Icons.keyboard_arrow_up,
                                size: 18,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                '₱${effectiveGrandTotal.toStringAsFixed(2)}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              const Icon(Icons.local_shipping_outlined, size: 12, color: AppColors.muted),
                              const SizedBox(width: 3),
                              Text(
                                effectiveShippingFee == 0 ? '₱0.00' : '₱${effectiveShippingFee.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.muted),
                              ),
                              const Text(' | Saved ', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                              Text(
                                '₱${totalSavings.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFD32F2F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Solid Black Checkout Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedCount > 0 ? const Color(0xFF381535) : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      elevation: 0,
                    ),
                    onPressed: selectedCount > 0
                        ? () {
                            HapticService.selection();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CheckoutScreen(
                                  initialAddress: _selectedAddress,
                                  initialShippingVoucher: _appliedVoucher?.type == VoucherType.freeShipping ? _appliedVoucher : null,
                                  initialDiscountVoucher: _appliedVoucher?.type != VoucherType.freeShipping ? _appliedVoucher : null,
                                  isVipShippingActive: _isVipShippingEnabled,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: Text(
                      'Checkout ($selectedCount)',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // CUSTOM LUXURY CHECKBOX (Square with rounded corners)
  Widget _buildCustomCheckbox({
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF381535) : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? const Color(0xFF381535) : const Color(0xFFB0B0B0),
            width: 1.5,
          ),
        ),
        child: isSelected
            ? const Center(
                child: Icon(Icons.check, size: 14, color: Colors.white),
              )
            : null,
      ),
    );
  }

  // 10. INTERACTIVE MODALS & DIALOGS
  Future<void> _openVoucherSelector(BuildContext context, CartProvider cart) async {
    final result = await VoucherSelectionModal.show(
      context,
      subtotal: cart.selectedSubtotal,
      shippingFee: cart.selectedShippingFee,
      initialShippingVoucher: _appliedVoucher?.type == VoucherType.freeShipping ? _appliedVoucher : null,
      initialDiscountVoucher: _appliedVoucher?.type != VoucherType.freeShipping ? _appliedVoucher : null,
    );
    if (result != null) {
      setState(() {
        _appliedVoucher = result.discountVoucher ?? result.shippingVoucher;
      });
    }
  }

  void _showVariantPicker(BuildContext context, CartItem cartItem, CartProvider cart) {
    final p = cartItem.product;
    String selectedColor = cartItem.selectedColor;
    String selectedOption = cartItem.selectedSizeOrOption;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
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
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Change Variation',
                        style: AppTextStyles.heading(size: 17, weight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(modalCtx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Product info header
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.blush1,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: p.imagePath != null
                            ? buildLumoraImage(p.imagePath!, fit: BoxFit.cover, cacheWidth: 150)
                            : Icon(p.icon, color: AppColors.plum, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Selected: $selectedColor • $selectedOption',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.plum,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.line, height: 24),

                  // Color Swatches
                  if (p.colorOptions.isNotEmpty) ...[
                    Row(
                      children: [
                        const Text(
                          'Color: ',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                        ),
                        Flexible(
                          child: Text(
                            selectedColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.plum),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.colorOptions.map((co) {
                        final isSelected = co.name.toLowerCase() == selectedColor.toLowerCase();
                        return GestureDetector(
                          onTap: () {
                            HapticService.selection();
                            setSheetState(() => selectedColor = co.name);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.plum : AppColors.line,
                                width: isSelected ? 2.0 : 1.0,
                              ),
                            ),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: co.color,
                                shape: BoxShape.circle,
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      size: 14,
                                      color: co.color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Secondary Options
                  if (p.secondaryOptions.isNotEmpty) ...[
                    Row(
                      children: [
                        Text(
                          '${p.secondaryOptionLabel}: ',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                        ),
                        Flexible(
                          child: Text(
                            selectedOption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.plum),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.secondaryOptions.map((opt) {
                        final isSelected = opt == selectedOption;
                        return ChoiceChip(
                          label: Text(opt),
                          selected: isSelected,
                          selectedColor: AppColors.plum,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.ink,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected ? AppColors.plum : AppColors.line,
                            ),
                          ),
                          onSelected: (_) {
                            HapticService.selection();
                            setSheetState(() => selectedOption = opt);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.plum,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: () {
                        HapticService.selection();
                        cart.updateVariation(
                          cartItem.itemKey,
                          selectedColor: selectedColor,
                          selectedSizeOrOption: selectedOption,
                        );
                        Navigator.of(modalCtx).pop();
                        LuxurySnackBar.show(
                          context,
                          message: 'Updated to $selectedColor • $selectedOption',
                          icon: Icons.check_circle_outline,
                        );
                      },
                      child: const Text(
                        'Apply Changes',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
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

  void _showQuantityPicker(BuildContext context, CartItem cartItem, CartProvider cart) {
    final maxLimit = min(cartItem.product.stock > 0 ? cartItem.product.stock : 5, CartProvider.maxPerBuyerLimit);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Quantity', style: AppTextStyles.heading(size: 16, weight: FontWeight.w700)),
                  Text('Limit: $maxLimit per item', style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: List.generate(maxLimit, (i) => i + 1).map((qty) {
                  final isCurrent = qty == cartItem.quantity;
                  return LuxuryTapScale(
                    onTap: () {
                      HapticService.selection();
                      cart.setQuantity(cartItem.itemKey, qty);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      width: 52,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isCurrent ? const Color(0xFF381535) : const Color(0xFFF3F3F4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isCurrent ? const Color(0xFF381535) : const Color(0xFFE0E0E0)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$qty',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isCurrent ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemMoreOptions(BuildContext context, CartItem cartItem, CartProvider cart) {
    final wishlist = Provider.of<WishlistProvider>(context, listen: false);
    final p = cartItem.product;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFD0D0D0), borderRadius: BorderRadius.circular(99)),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border, color: AppColors.plum),
              title: const Text('Move to Wishlist', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                if (!auth.isLoggedIn) {
                  Navigator.of(ctx).pop();
                  AuthModal.show(context, actionName: 'save items to your wishlist');
                  return;
                }
                wishlist.toggleFavorite(p);
                cart.removeFromCart(cartItem.itemKey);
                Navigator.of(ctx).pop();
                LuxurySnackBar.show(context, message: 'Moved "${p.name}" to Wishlist');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: AppColors.plum),
              title: const Text('Share Item', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.of(ctx).pop();
                LuxurySnackBar.show(context, message: 'Link to ${p.name} copied to clipboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFB85E68)),
              title: const Text('Remove from Bag', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFB85E68))),
              onTap: () {
                cart.removeFromCart(cartItem.itemKey);
                Navigator.of(ctx).pop();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAddressSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Delivery Address', style: AppTextStyles.heading(size: 16, weight: FontWeight.w700)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                ],
              ),
              const SizedBox(height: 12),
              ..._philippineAddresses.map((addr) {
                final isSelected = addr == _selectedAddress;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.location_on,
                    color: isSelected ? const Color(0xFF381535) : AppColors.muted,
                  ),
                  title: Text(
                    addr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF381535) : AppColors.ink,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Color(0xFF381535), size: 20)
                      : null,
                  onTap: () {
                    setState(() => _selectedAddress = addr);
                    Navigator.of(ctx).pop();
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showVipInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF5E35B1), borderRadius: BorderRadius.circular(6)),
              child: const Text('VIP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Unlimited Free Shipping',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: const Text(
          'Join Lumora VIP Club for only ₱500 per year and enjoy zero delivery fees on all orders across the Philippines with no minimum spend required.',
          style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.ink),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E35B1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _confirmClearCart(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear Bag?',
          style: AppTextStyles.heading(size: 18, weight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to remove all items from your bag?',
          style: AppTextStyles.body(size: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppTextStyles.body(color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB85E68),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
            ),
            onPressed: () {
              cart.clearCart();
              Navigator.of(ctx).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  // 11. GUEST & EMPTY STATES
  Widget _buildGuestCartPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 44,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sign In to View Cart',
              style: AppTextStyles.heading(
                size: 20,
                weight: FontWeight.w700,
                color: AppColors.plum,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You are currently browsing as a Guest. Log in to manage your bag, claim exclusive member vouchers, and checkout.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(size: 13.5, color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.plum,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: Text(
                'Log In / Sign Up',
                style: AppTextStyles.body(
                  size: 14,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: widget.onBrowseProducts,
              child: Text(
                'Continue Browsing Catalog',
                style: AppTextStyles.body(size: 13, color: AppColors.muted),
              ),
            ),
            if (!Navigator.of(context).canPop()) const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Bag is Empty',
              style: AppTextStyles.heading(
                size: 22,
                weight: FontWeight.w700,
                color: AppColors.plum,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore our luxury catalog and discover elevated essentials curated for you.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(size: 14, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF381535),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              onPressed: widget.onBrowseProducts,
              child: Text(
                'Explore Collections',
                style: AppTextStyles.body(
                  size: 14,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            if (!Navigator.of(context).canPop()) const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
