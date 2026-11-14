import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/haptic_service.dart';
import '../services/native_photo_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_modal.dart';
import '../widgets/cards.dart';
import '../widgets/luxury_snackbar.dart';
import '../widgets/voucher_selection_modal.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final CartItem? buyNowItem;
  final String? initialAddress;
  final VoucherModel? initialShippingVoucher;
  final VoucherModel? initialDiscountVoucher;
  final bool isVipShippingActive;

  const CheckoutScreen({
    super.key,
    this.buyNowItem,
    this.initialAddress,
    this.initialShippingVoucher,
    this.initialDiscountVoucher,
    this.isVipShippingActive = false,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPayment = 'Cash on Delivery (COD)';
  VoucherModel? _appliedShippingVoucher;
  VoucherModel? _appliedDiscountVoucher;
  String _address = 'Blk 4 Lot 12, San Antonio, City of Biñan, Laguna';
  String? _customRecipientName;
  String? _customContactNumber;
  String _selectedAddressLabel = 'Home';
  List<PhilippineAddress> _savedAddresses = [];
  bool _addressInitialized = false;
  bool _isSubmittingOrder = false;
  static const int _noteMaxLength = 200;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _appliedShippingVoucher = widget.initialShippingVoucher;
    _appliedDiscountVoucher = widget.initialDiscountVoucher;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// Optional "Note to Seller" field, limited to 200 characters (BUY-CHK-005).
  Widget _buildNoteToSeller() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note to Seller (optional)',
          style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: AppColors.plum),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          maxLength: _noteMaxLength,
          maxLines: 3,
          minLines: 2,
          style: AppTextStyles.body(size: 13),
          decoration: InputDecoration(
            hintText: 'e.g. Please wrap as a gift',
            filled: true,
            fillColor: Colors.white,
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_addressInitialized) {
      _addressInitialized = true;
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (widget.initialAddress != null && widget.initialAddress!.trim().isNotEmpty) {
        _address = widget.initialAddress!.trim();
      } else if (user != null && user.fullAddress.trim().isNotEmpty) {
        _address = user.fullAddress;
      }

      SavedAddressBook.load(user).then((loaded) {
        if (!mounted) return;
        setState(() {
          _savedAddresses = loaded;
          final def = loaded.where((a) => a.isDefault).firstOrNull ?? loaded.firstOrNull;
          if (def != null) {
            if (widget.initialAddress == null && def.formattedAddress.trim().isNotEmpty) {
              _address = def.formattedAddress;
            }
            _customRecipientName = def.recipientName;
            _customContactNumber = def.phoneNumber;
            _selectedAddressLabel = def.label;
          }
        });
      });

      final defaultWallet = Provider.of<WalletProvider>(context, listen: false).defaultMethod;
      if (defaultWallet != null) {
        if (defaultWallet.type == 'gcash') {
          _selectedPayment = 'GCash';
        } else if (defaultWallet.type == 'maya') {
          _selectedPayment = 'Maya';
        } else if (defaultWallet.type == 'bank') {
          _selectedPayment = 'Credit / Debit Card';
        }
      }
    }
  }

  Future<void> _openVoucherModal(double subtotal, double shippingFee) async {
    final result = await VoucherSelectionModal.show(
      context,
      subtotal: subtotal,
      shippingFee: shippingFee,
      initialShippingVoucher: _appliedShippingVoucher,
      initialDiscountVoucher: _appliedDiscountVoucher,
    );
    if (result != null) {
      setState(() {
        _appliedShippingVoucher = result.shippingVoucher;
        _appliedDiscountVoucher = result.discountVoucher;
      });
    }
  }

  void _removeVouchers() {
    setState(() {
      _appliedShippingVoucher = null;
      _appliedDiscountVoucher = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final recipientName = (_customRecipientName?.trim().isNotEmpty == true)
        ? _customRecipientName!.trim()
        : (auth.currentUser?.fullName ?? 'Valued Member');
    final contactNumber = (_customContactNumber?.trim().isNotEmpty == true)
        ? _customContactNumber!.trim()
        : ((auth.currentUser?.contactNumber?.trim().isNotEmpty == true)
            ? auth.currentUser!.contactNumber!.trim()
            : '+63 917 890 1234');

    final isBuyNow = widget.buyNowItem != null;
    final checkoutItems = isBuyNow
        ? <CartItem>[widget.buyNowItem!]
        : (cart.selectedItemList.isNotEmpty ? cart.selectedItemList : cart.itemList);
    final itemsCount = checkoutItems.fold<int>(0, (sum, item) => sum + item.quantity);

    final Map<String, List<CartItem>> storeGroups = {};
    for (final item in checkoutItems) {
      storeGroups.putIfAbsent(item.product.sellerName, () => []).add(item);
    }

    final subtotal = isBuyNow
        ? widget.buyNowItem!.totalPrice
        : (cart.selectedItemList.isNotEmpty ? cart.selectedSubtotal : cart.subtotal);

    // Confirmed standard shipping fee of ₱50.0
    final double shippingFee = (checkoutItems.isEmpty || widget.isVipShippingActive)
        ? 0.0
        : 50.0;
    const double weightSurcharge = 0.0;

    final shippingDiscount = _appliedShippingVoucher?.calculateDiscount(subtotal, shippingFee) ?? 0.0;
    final discountVoucherValue = _appliedDiscountVoucher?.calculateDiscount(subtotal, shippingFee) ?? 0.0;
    final totalVoucherDiscount = shippingDiscount + discountVoucherValue;
    final effectiveShippingFee = max(0.0, shippingFee - shippingDiscount);
    final finalTotal = max(0.0, subtotal + effectiveShippingFee - discountVoucherValue);

    // Unserviceable address detection (BUY-CHK-004)
    final addrLower = _address.toLowerCase();
    final bool isUnserviceable = addrLower.contains('unserviceable') ||
        addrLower.contains('remote island') ||
        addrLower.contains('po box') ||
        addrLower.contains('outpost') ||
        addrLower.contains('islet');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAddressCard(recipientName, contactNumber, isUnserviceable: isUnserviceable),
                      const SizedBox(height: 18),
                      _buildOrderItemsCard(checkoutItems),
                      const SizedBox(height: 14),
                      _buildNoteToSeller(),
                      const SizedBox(height: 20),
                      _buildPaymentMethods(),
                      const SizedBox(height: 20),
                      _buildVoucherCard(subtotal, shippingFee, shippingDiscount, discountVoucherValue),
                      const SizedBox(height: 20),
                      _buildOrderSummary(
                        itemsCount: itemsCount,
                        subtotal: subtotal,
                        shippingFee: shippingFee,
                        weightSurcharge: weightSurcharge,
                        shippingDiscount: shippingDiscount,
                        discountVoucherValue: discountVoucherValue,
                        finalTotal: finalTotal,
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(
                context: context,
                cart: cart,
                checkoutItems: checkoutItems,
                isBuyNow: isBuyNow,
                finalTotal: finalTotal,
                totalSavings: totalVoucherDiscount,
                isUnserviceable: isUnserviceable,
                voucherCode: _appliedDiscountVoucher?.code ?? _appliedShippingVoucher?.code,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(Icons.arrow_back, size: 18, color: AppColors.plum),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Text(
            'Order Checkout',
            style: AppTextStyles.heading(
              size: 20,
              weight: FontWeight.w700,
              color: AppColors.plum,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(String recipientName, String contactNumber, {bool isUnserviceable = false}) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 20, color: AppColors.orange),
              const SizedBox(width: 8),
              Text(
                'Delivery Address',
                style: AppTextStyles.body(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppColors.plum,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.plum.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.line),
                ),
                child: Text(
                  _selectedAddressLabel.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.plum,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  _showEditAddressDialog();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Change / Manage',
                      style: AppTextStyles.body(
                        size: 12,
                        weight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.orange),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$recipientName • $contactNumber',
            style: AppTextStyles.body(size: 13, weight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            _address,
            style: AppTextStyles.body(size: 12.5, color: AppColors.muted, height: 1.4),
          ),
          if (isUnserviceable) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEF9A9A)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, size: 16, color: Colors.redAccent),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Unserviceable Address: Outside courier serviceable area. Please update your address.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderItemsCard(List<CartItem> items) {
    final Map<String, List<CartItem>> storeGroups = {};
    for (final item in items) {
      storeGroups.putIfAbsent(item.product.sellerName, () => []).add(item);
    }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 20, color: AppColors.plum),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Order Items (${items.length}) • ${storeGroups.length} Store${storeGroups.length > 1 ? "s" : ""}',
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.plum,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'LUMORA Guaranteed',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6F8F78),
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.line, height: 22),
          ...storeGroups.entries.map((entry) {
            final storeName = entry.key;
            final storeItems = entry.value;
            final storeSubtotal = storeItems.fold<double>(0.0, (s, i) => s + i.totalPrice);

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.blush1,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_outlined, size: 16, color: AppColors.plum),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            storeName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.plum),
                          ),
                        ),
                        Text(
                          '₱${storeSubtotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: storeItems.length,
                    separatorBuilder: (_, _) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Divider(color: AppColors.line, height: 1),
                    ),
                    itemBuilder: (context, idx) {
                      final item = storeItems[idx];
                      final p = item.product;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F3F4),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.line),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: p.imagePath != null
                                ? buildLumoraImage(p.imagePath!, fit: BoxFit.cover, cacheWidth: 160)
                                : Icon(p.icon, color: AppColors.plum, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.body(
                                    size: 12.5,
                                    weight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.variationLabel,
                                  style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                item.formattedTotalPrice,
                                style: AppTextStyles.price(
                                  size: 13.5,
                                  weight: FontWeight.w800,
                                  color: AppColors.plum,
                                ),
                              ),
                              Text(
                                'Qty: ${item.quantity}',
                                style: const TextStyle(fontSize: 11, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final wallet = Provider.of<WalletProvider>(context);
    final savedGcash = wallet.methods.where((m) => m.type == 'gcash').firstOrNull;
    final savedMaya = wallet.methods.where((m) => m.type == 'maya').firstOrNull;
    final savedBank = wallet.methods.where((m) => m.type == 'bank').firstOrNull;

    final methods = [
      {'title': 'Cash on Delivery (COD)', 'icon': Icons.local_shipping_outlined, 'desc': 'Pay when items arrive'},
      {
        'title': 'GCash',
        'icon': Icons.account_balance_wallet_outlined,
        'desc': savedGcash != null
            ? 'Linked: ${savedGcash.accountName} (${savedGcash.maskedNumber})'
            : 'Fast & secure e-wallet',
      },
      {
        'title': 'Maya',
        'icon': Icons.credit_card_outlined,
        'desc': savedMaya != null
            ? 'Linked: ${savedMaya.accountName} (${savedMaya.maskedNumber})'
            : 'Digital wallet & bank',
      },
      {
        'title': 'Credit / Debit Card',
        'icon': Icons.payment_outlined,
        'desc': savedBank != null
            ? 'Linked: ${savedBank.accountName} (${savedBank.maskedNumber})'
            : 'Visa, Mastercard, JCB',
      },
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
          Text(
            'Payment Method',
            style: AppTextStyles.body(
              size: 14,
              weight: FontWeight.w700,
              color: AppColors.plum,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: methods.map((m) {
              final isSelected = m['title'] == _selectedPayment;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPayment = m['title'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.plum.withValues(alpha: 0.05)
                          : AppColors.blush1,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.plum : AppColors.line,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          m['icon'] as IconData,
                          size: 22,
                          color: isSelected ? AppColors.plum : AppColors.muted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['title'] as String,
                                style: AppTextStyles.body(
                                  size: 13,
                                  weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: AppColors.plum,
                                ),
                              ),
                              Text(
                                m['desc'] as String,
                                style: AppTextStyles.body(size: 11, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          size: 18,
                          color: isSelected ? AppColors.plum : AppColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(
    double subtotal,
    double shippingFee,
    double shippingDiscount,
    double discountVoucherValue,
  ) {
    final hasVouchers = _appliedShippingVoucher != null || _appliedDiscountVoucher != null;
    final totalSavings = shippingDiscount + discountVoucherValue;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasVouchers ? AppColors.orange.withValues(alpha: 0.35) : AppColors.line,
          width: hasVouchers ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (hasVouchers ? AppColors.orange : AppColors.plum).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openVoucherModal(subtotal, shippingFee),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasVouchers
                            ? AppColors.orange.withValues(alpha: 0.12)
                            : AppColors.blush1,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.confirmation_number_outlined,
                        size: 20,
                        color: hasVouchers ? AppColors.orange : AppColors.plum,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              Text(
                                'Lumora Vouchers',
                                style: AppTextStyles.body(
                                  size: 14,
                                  weight: FontWeight.w700,
                                  color: AppColors.plum,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.orange.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'STACKABLE',
                                  style: AppTextStyles.caption(
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
                            hasVouchers
                                ? 'Total savings: -₱${totalSavings.toStringAsFixed(2)}'
                                : 'Select Free Shipping & Discount vouchers',
                            style: AppTextStyles.body(
                              size: 11.5,
                              color: hasVouchers ? const Color(0xFF2E7D32) : AppColors.muted,
                              weight: hasVouchers ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasVouchers) ...[
                          GestureDetector(
                            onTap: _removeVouchers,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                'Clear',
                                style: AppTextStyles.body(
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFFD46A6A),
                                ),
                              ),
                            ),
                          ),
                        ],
                        Text(
                          hasVouchers ? 'Change' : 'Select code',
                          style: AppTextStyles.body(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: hasVouchers ? AppColors.plum : AppColors.orange,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ],
                ),
                if (hasVouchers) ...[
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.line, height: 1),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (_appliedShippingVoucher != null)
                        _buildAppliedVoucherTag(
                          label: 'Free Shipping: -₱${shippingDiscount.toStringAsFixed(0)}',
                          color: const Color(0xFF2E7D32),
                          onRemove: () {
                            setState(() => _appliedShippingVoucher = null);
                          },
                        ),
                      if (_appliedDiscountVoucher != null)
                        _buildAppliedVoucherTag(
                          label: '${_appliedDiscountVoucher!.code}: -₱${discountVoucherValue.toStringAsFixed(0)}',
                          color: AppColors.orange,
                          onRemove: () {
                            setState(() => _appliedDiscountVoucher = null);
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppliedVoucherTag({
    required String label,
    required Color color,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption(
              size: 11,
              weight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 13, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary({
    required int itemsCount,
    required double subtotal,
    required double shippingFee,
    double weightSurcharge = 0.0,
    required double shippingDiscount,
    required double discountVoucherValue,
    required double finalTotal,
  }) {
    final totalSavings = shippingDiscount + discountVoucherValue;

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
          Text(
            'Order Breakdown ($itemsCount items)',
            style: AppTextStyles.body(
              size: 14,
              weight: FontWeight.w700,
              color: AppColors.plum,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Items Subtotal', style: AppTextStyles.body(size: 13, color: AppColors.muted)),
              Text('₱${subtotal.toStringAsFixed(2)}', style: AppTextStyles.body(size: 13, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Shipping Subtotal', style: AppTextStyles.body(size: 13, color: AppColors.muted)),
              Text(
                shippingFee == 0 ? 'FREE' : '₱${shippingFee.toStringAsFixed(2)}',
                style: AppTextStyles.body(
                  size: 13,
                  weight: FontWeight.w600,
                  color: shippingFee == 0 ? AppColors.orange : AppColors.ink,
                ),
              ),
            ],
          ),
          if (weightSurcharge > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Weight Surcharge (> 1.0 kg)', style: AppTextStyles.body(size: 13, color: AppColors.muted)),
                Text('+₱${weightSurcharge.toStringAsFixed(2)}', style: AppTextStyles.body(size: 13, weight: FontWeight.w600, color: AppColors.orange)),
              ],
            ),
          ],
          if (shippingDiscount > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 14, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Shipping Subsidy (${_appliedShippingVoucher?.code ?? "FREESHIP"})',
                          style: AppTextStyles.body(size: 13, color: const Color(0xFF2E7D32)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '-₱${shippingDiscount.toStringAsFixed(2)}',
                  style: AppTextStyles.body(
                    size: 13,
                    weight: FontWeight.w700,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ],
          if (discountVoucherValue > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer_outlined, size: 14, color: AppColors.orange),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Voucher Discount (${_appliedDiscountVoucher?.code})',
                          style: AppTextStyles.body(size: 13, color: AppColors.orange),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '-₱${discountVoucherValue.toStringAsFixed(2)}',
                  style: AppTextStyles.body(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.line, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Payment',
                style: AppTextStyles.heading(
                  size: 16,
                  weight: FontWeight.w700,
                  color: AppColors.plum,
                ),
              ),
              Text(
                '₱${finalTotal.toStringAsFixed(2)}',
                style: AppTextStyles.body(
                  size: 18,
                  weight: FontWeight.w800,
                  color: AppColors.plum,
                ),
              ),
            ],
          ),
          if (totalSavings > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.savings_outlined, size: 16, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You are saving ₱${totalSavings.toStringAsFixed(2)} on this order!',
                      style: AppTextStyles.caption(
                        size: 12,
                        weight: FontWeight.w700,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar({
    required BuildContext context,
    required CartProvider cart,
    required List<CartItem> checkoutItems,
    required bool isBuyNow,
    required double finalTotal,
    required double totalSavings,
    bool isUnserviceable = false,
    String? voucherCode,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: const Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (totalSavings > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Saved ₱${totalSavings.toStringAsFixed(0)}',
                      style: AppTextStyles.caption(
                        size: 10,
                        weight: FontWeight.w800,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ),
              Text('Total Amount', style: AppTextStyles.body(size: 11, color: AppColors.muted)),
              Text(
                '₱${finalTotal.toStringAsFixed(2)}',
                style: AppTextStyles.body(
                  size: 18,
                  weight: FontWeight.w800,
                  color: AppColors.plum,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isUnserviceable ? Colors.grey : AppColors.plum,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              onPressed: (_isSubmittingOrder || isUnserviceable)
                  ? null
                  : () {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (!authProvider.isLoggedIn) {
                        AuthModal.show(context, actionName: 'complete checkout and place your order');
                        return;
                      }

                      // Pre-submission stock verification (BUY-CHK-009)
                      for (final ci in checkoutItems) {
                        if (ci.product.stock <= 0) {
                          LuxurySnackBar.show(
                            context,
                            message: 'Item "${ci.product.name}" is currently out of stock.',
                            icon: Icons.error_outline,
                            iconColor: Colors.redAccent,
                          );
                          return;
                        }
                      }

                      if (_selectedPayment != 'Cash on Delivery (COD)') {
                        _showPaymentGatewayModal(
                          context: context,
                          finalTotal: finalTotal,
                          onSuccess: (proofPath, refLast6) => _executeOrderPlacement(
                            context: context,
                            cart: cart,
                            checkoutItems: checkoutItems,
                            isBuyNow: isBuyNow,
                            finalTotal: finalTotal,
                            voucherCode: voucherCode,
                            paymentProofPath: proofPath,
                            paymentReferenceLast6: refLast6,
                            paymentStatus: 'pending',
                          ),
                        );
                        return;
                      }

                      _executeOrderPlacement(
                        context: context,
                        cart: cart,
                        checkoutItems: checkoutItems,
                        isBuyNow: isBuyNow,
                        finalTotal: finalTotal,
                        voucherCode: voucherCode,
                        paymentStatus: 'pending',
                      );
                    },
              child: _isSubmittingOrder
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      isUnserviceable ? 'Address Unserviceable' : 'Place Order',
                      style: AppTextStyles.body(
                        size: 14,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeOrderPlacement({
    required BuildContext context,
    required CartProvider cart,
    required List<CartItem> checkoutItems,
    required bool isBuyNow,
    required double finalTotal,
    String? voucherCode,
    String? paymentProofPath,
    String? paymentReferenceLast6,
    String? paymentStatus,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _isSubmittingOrder = true);
    HapticService.mediumImpact();
    final recipient = (_customRecipientName?.trim().isNotEmpty == true)
        ? _customRecipientName!.trim()
        : (authProvider.currentUser?.fullName ?? 'Valued Member');
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final placedOrder = await orderProvider.placeOrder(
      cartItems: checkoutItems,
      totalAmount: finalTotal,
      deliveryAddress: _address,
      recipientName: recipient,
      paymentMethod: _selectedPayment,
      noteToSeller: _noteController.text.trim(),
      voucherCode: voucherCode,
      paymentProofPath: paymentProofPath,
      paymentReferenceLast6: paymentReferenceLast6,
      paymentStatus: paymentStatus,
    );
    if (!mounted) return;
    if (placedOrder == null) {
      setState(() => _isSubmittingOrder = false);
      LuxurySnackBar.show(
        this.context,
        message: orderProvider.lastOrderError ?? 'Failed to place order. Please try again.',
        icon: Icons.error_outline,
        iconColor: Colors.redAccent,
      );
      return;
    }
    if (!isBuyNow) {
      if (cart.selectedItemList.isNotEmpty) {
        cart.removeSelectedItems();
      } else {
        cart.clearCart();
      }
    }
    Navigator.of(this.context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(
          order: placedOrder,
        ),
      ),
    );
  }

  void _showPaymentGatewayModal({
    required BuildContext context,
    required double finalTotal,
    required void Function(String? proofPath, String? referenceLast6) onSuccess,
  }) {
    final isEWallet = _selectedPayment == 'GCash' || _selectedPayment == 'Maya';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (gwCtx) => PopScope(
        canPop: false,
        child: _EWalletPaymentSheet(
          paymentMethod: _selectedPayment,
          finalTotal: finalTotal,
          isEWallet: isEWallet,
          onSuccess: (proof, ref) {
            Navigator.of(gwCtx).pop();
            onSuccess(proof, ref);
          },
          onCancel: () {
            Navigator.of(gwCtx).pop();
            LuxurySnackBar.show(
              context,
              message: 'Payment cancelled. Order was not placed.',
              icon: Icons.info_outline,
            );
          },
        ),
      ),
    );
  }

  /// Opens a full Saved Address Book manager where the buyer can:
  /// - Select any previously saved address (updating recipient name, phone & address)
  /// - Edit an existing saved address (pencil icon)
  /// - Delete an existing saved address (trash icon)
  /// - Set any address as Default (`★ Default`)
  /// - Add a new address with 1-Tap GPS / Quick Regional Presets
  Future<void> _showEditAddressDialog() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    _savedAddresses = await SavedAddressBook.load(user);
    if (!mounted) return;

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final houseCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final brgyCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final provCtrl = TextEditingController();
    final postalCtrl = TextEditingController();
    String selectedLabel = 'Home';
    bool makeDefault = true;
    bool isFormOpen = false;
    PhilippineAddress? editingTarget;
    String? error;

    void prepareForm({PhilippineAddress? target}) {
      editingTarget = target;
      nameCtrl.text = target?.recipientName ??
          (_customRecipientName ?? (user?.fullName.isNotEmpty == true ? user!.fullName : 'Recipient'));
      phoneCtrl.text = target?.phoneNumber ??
          (_customContactNumber ??
              (user?.contactNumber?.isNotEmpty == true ? user!.contactNumber! : '+63 917 892 4101'));
      houseCtrl.text = target?.houseNumber ?? '';
      streetCtrl.text = target?.streetName ?? '';
      brgyCtrl.text = target?.barangay ?? '';
      cityCtrl.text = target?.municipality ?? '';
      provCtrl.text = target?.province ?? '';
      postalCtrl.text = target?.postalCode ?? '';
      selectedLabel = target?.label ?? 'Home';
      makeDefault = target?.isDefault ?? true;
      error = null;
      isFormOpen = true;
    }

    const quickPresets = [
      {
        'badge': '📍 GPS: Biñan, Laguna',
        'prov': 'Laguna',
        'city': 'City of Biñan',
        'brgy': 'San Antonio',
        'street': 'Katipunan St.',
        'zip': '4024',
      },
      {
        'badge': '🏛️ Sta. Cruz, Laguna',
        'prov': 'Laguna',
        'city': 'Santa Cruz',
        'brgy': 'Poblacion III',
        'street': 'P. Guevarra Ave.',
        'zip': '4009',
      },
      {
        'badge': '🌿 Los Baños, Laguna',
        'prov': 'Laguna',
        'city': 'Los Baños',
        'brgy': 'Batong Malake',
        'street': 'Lopez Ave.',
        'zip': '4030',
      },
      {
        'badge': '🏙️ BGC, Taguig',
        'prov': 'Metro Manila',
        'city': 'City of Taguig',
        'brgy': 'Fort Bonifacio',
        'street': '26th St., BGC',
        'zip': '1634',
      },
    ];

    Widget field(String label, TextEditingController c, {String? hint, IconData? icon}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            controller: c,
            style: AppTextStyles.body(size: 13),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: icon != null ? Icon(icon, size: 17, color: AppColors.plum) : null,
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Material(
              color: AppColors.cream,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                  child: SingleChildScrollView(
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
                            Expanded(
                              child: Text(
                                isFormOpen
                                    ? (editingTarget != null ? 'Edit Saved Address' : 'Add New Delivery Address')
                                    : 'Saved Address Book (${_savedAddresses.length})',
                                style: AppTextStyles.heading(size: 18, weight: FontWeight.w700, color: AppColors.plum),
                              ),
                            ),
                            if (isFormOpen)
                              TextButton.icon(
                                onPressed: () => setSheetState(() {
                                  isFormOpen = false;
                                  editingTarget = null;
                                  error = null;
                                }),
                                icon: const Icon(Icons.arrow_back_ios_new, size: 12, color: AppColors.plum),
                                label: const Text(
                                  'Saved List',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.plum),
                                ),
                              )
                            else
                              IconButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                icon: const Icon(Icons.close, size: 20, color: AppColors.muted),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isFormOpen
                              ? 'Fill in recipient & location details or tap a quick GPS preset below.'
                              : 'Tap an address to use it for this order, or edit/delete any saved address.',
                          style: AppTextStyles.body(size: 11.5, color: AppColors.muted),
                        ),
                        const SizedBox(height: 14),
                        if (!isFormOpen) ...[
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.sizeOf(ctx).height * 0.48,
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _savedAddresses.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (_, index) {
                                final addr = _savedAddresses[index];
                                final formatted = addr.formattedAddress;
                                final isSelected = _address.trim().toLowerCase() == formatted.trim().toLowerCase() ||
                                    (_address.contains(addr.barangay) &&
                                        _address.contains(addr.municipality) &&
                                        _selectedAddressLabel == addr.label);
                                return InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () async {
                                    HapticService.selection();
                                    await auth.updateShippingAddress(
                                      province: addr.province,
                                      municipality: addr.municipality,
                                      barangay: addr.barangay,
                                      street: addr.streetName,
                                      houseNumber: addr.houseNumber,
                                    );
                                    if (!mounted) return;
                                    setState(() {
                                      _address = formatted;
                                      _customRecipientName = addr.recipientName;
                                      _customContactNumber = addr.phoneNumber;
                                      _selectedAddressLabel = addr.label;
                                    });
                                    if (ctx.mounted) Navigator.of(ctx).pop();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.plum.withValues(alpha: 0.07) : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected ? AppColors.plum : AppColors.line,
                                        width: isSelected ? 1.6 : 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Icon(
                                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                                size: 20,
                                                color: isSelected ? AppColors.plum : AppColors.muted,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Wrap(
                                                    crossAxisAlignment: WrapCrossAlignment.center,
                                                    spacing: 6,
                                                    runSpacing: 4,
                                                    children: [
                                                      Text(
                                                        addr.recipientName,
                                                        style: AppTextStyles.body(
                                                          size: 13,
                                                          weight: FontWeight.w700,
                                                          color: AppColors.plum,
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.cream,
                                                          borderRadius: BorderRadius.circular(99),
                                                          border: Border.all(color: AppColors.line),
                                                        ),
                                                        child: Text(
                                                          addr.label.toUpperCase(),
                                                          style: const TextStyle(
                                                            fontSize: 8.5,
                                                            fontWeight: FontWeight.w700,
                                                            color: AppColors.ink,
                                                          ),
                                                        ),
                                                      ),
                                                      if (addr.isDefault)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.gold.withValues(alpha: 0.18),
                                                            borderRadius: BorderRadius.circular(99),
                                                          ),
                                                          child: const Text(
                                                            '★ DEFAULT',
                                                            style: TextStyle(
                                                              fontSize: 8.5,
                                                              fontWeight: FontWeight.w800,
                                                              color: AppColors.plum,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    addr.phoneNumber,
                                                    style: AppTextStyles.body(size: 11, color: AppColors.muted),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    formatted,
                                                    style: AppTextStyles.body(
                                                      size: 12,
                                                      color: AppColors.ink,
                                                      height: 1.35,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Edit & Delete Action Icons
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  visualDensity: VisualDensity.compact,
                                                  tooltip: 'Edit address',
                                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.plum),
                                                  onPressed: () {
                                                    HapticService.selection();
                                                    setSheetState(() => prepareForm(target: addr));
                                                  },
                                                ),
                                                if (_savedAddresses.length > 1)
                                                  IconButton(
                                                    visualDensity: VisualDensity.compact,
                                                    tooltip: 'Delete address',
                                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                                    onPressed: () async {
                                                      HapticService.selection();
                                                      // BUY-ADDR-007: Block deleting default address directly
                                                      if (addr.isDefault && _savedAddresses.length > 1) {
                                                        LuxurySnackBar.show(
                                                          context,
                                                          message:
                                                              'Cannot delete your default shipping address. Please set another address as default first.',
                                                          icon: Icons.warning_amber_rounded,
                                                          iconColor: AppColors.gold,
                                                        );
                                                        return;
                                                      }
                                                      final updated = await SavedAddressBook.deleteAddress(user, addr.id);
                                                      final fallback = updated.where((a) => a.isDefault).firstOrNull ?? updated.first;
                                                      setSheetState(() => _savedAddresses = updated);
                                                      if (mounted) {
                                                        setState(() {
                                                          _savedAddresses = updated;
                                                          if (isSelected) {
                                                            _address = fallback.formattedAddress;
                                                            _customRecipientName = fallback.recipientName;
                                                            _customContactNumber = fallback.phoneNumber;
                                                            _selectedAddressLabel = fallback.label;
                                                          }
                                                        });
                                                        LuxurySnackBar.show(
                                                          context,
                                                          message: 'Address removed from your address book.',
                                                          icon: Icons.delete_outline,
                                                        );
                                                      }
                                                    },
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        if (!addr.isDefault) ...[
                                          const SizedBox(height: 6),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: GestureDetector(
                                              onTap: () async {
                                                HapticService.selection();
                                                final updated = await SavedAddressBook.setDefaultAddress(user, addr.id);
                                                setSheetState(() => _savedAddresses = updated);
                                                if (mounted) {
                                                  setState(() => _savedAddresses = updated);
                                                }
                                              },
                                              child: const Text(
                                                'Set as Default Address',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.orange,
                                                  decoration: TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.plum, width: 1.3),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.add_location_alt_outlined, size: 18, color: AppColors.plum),
                              label: const Text(
                                '+ Add New Address',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.plum),
                              ),
                              onPressed: () {
                                HapticService.selection();
                                if (_savedAddresses.length >= 10) {
                                  LuxurySnackBar.show(
                                    context,
                                    message:
                                        'Maximum limit of 10 saved addresses reached. Please edit or delete an existing address.',
                                    icon: Icons.warning_amber_rounded,
                                    iconColor: AppColors.gold,
                                  );
                                  return;
                                }
                                setSheetState(() => prepareForm());
                              },
                            ),
                          ),
                        ] else ...[
                          // Quick GPS / Area Auto-Fill Chips
                          Text(
                            'Quick Location Auto-Fill:',
                            style: AppTextStyles.body(size: 11.5, weight: FontWeight.w700, color: AppColors.plum),
                          ),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: quickPresets.map((preset) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ActionChip(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: AppColors.line),
                                    label: Text(
                                      preset['badge']!,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.plum),
                                    ),
                                    onPressed: () {
                                      HapticService.selection();
                                      setSheetState(() {
                                        provCtrl.text = preset['prov']!;
                                        cityCtrl.text = preset['city']!;
                                        brgyCtrl.text = preset['brgy']!;
                                        if (streetCtrl.text.trim().isEmpty) {
                                          streetCtrl.text = preset['street']!;
                                        }
                                        postalCtrl.text = preset['zip']!;
                                        error = null;
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text('Label: ', style: AppTextStyles.body(size: 12, weight: FontWeight.w600)),
                              const SizedBox(width: 6),
                              for (final lbl in ['Home', 'Work', 'Other']) ...[
                                ChoiceChip(
                                  label: Text(lbl),
                                  selected: selectedLabel == lbl,
                                  onSelected: (_) => setSheetState(() => selectedLabel = lbl),
                                  selectedColor: AppColors.plum,
                                  labelStyle: TextStyle(
                                    fontSize: 11.5,
                                    color: selectedLabel == lbl ? Colors.white : AppColors.ink,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          field('Recipient Full Name *', nameCtrl, hint: 'e.g. Arron Ivan Balonzo', icon: Icons.person_outline),
                          field('Contact Mobile Number *', phoneCtrl, hint: 'e.g. +63 917 892 4101', icon: Icons.phone_outlined),
                          field('House / Unit / Bldg No.', houseCtrl, hint: 'e.g. Blk 4 Lot 12'),
                          field('Street / Subdivision *', streetCtrl, hint: 'e.g. Katipunan St.'),
                          field('Barangay *', brgyCtrl, hint: 'e.g. San Antonio'),
                          field('City / Municipality *', cityCtrl, hint: 'e.g. City of Biñan'),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: field('Province *', provCtrl, hint: 'e.g. Laguna'),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: field('ZIP Code', postalCtrl, hint: '4024'),
                              ),
                            ],
                          ),
                          CheckboxListTile(
                            value: makeDefault,
                            onChanged: (v) => setSheetState(() => makeDefault = v ?? true),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            activeColor: AppColors.plum,
                            title: Text(
                              'Set as my default shipping address',
                              style: AppTextStyles.body(size: 12, weight: FontWeight.w600),
                            ),
                          ),
                          if (error != null) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                error!,
                                style: const TextStyle(fontSize: 11.5, color: Colors.redAccent, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.line),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () => setSheetState(() {
                                    isFormOpen = false;
                                    editingTarget = null;
                                    error = null;
                                  }),
                                  child: Text('Back', style: AppTextStyles.body(color: AppColors.muted, weight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.plum,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () async {
                                    if (editingTarget == null && _savedAddresses.length >= 10) {
                                      setSheetState(() => error = 'Maximum limit of 10 saved addresses reached. Please edit or delete an existing address.');
                                      return;
                                    }
                                    if (nameCtrl.text.trim().isEmpty ||
                                        phoneCtrl.text.trim().isEmpty ||
                                        brgyCtrl.text.trim().isEmpty ||
                                        cityCtrl.text.trim().isEmpty ||
                                        provCtrl.text.trim().isEmpty) {
                                      setSheetState(() => error = 'Recipient name, phone, barangay, city and province are required.');
                                      return;
                                    }
                                    final phoneErr = AuthProvider.validatePhoneNumber(phoneCtrl.text.trim());
                                    if (phoneErr != null) {
                                      setSheetState(() => error = phoneErr);
                                      return;
                                    }
                                    final savedEntry = PhilippineAddress(
                                      id: editingTarget?.id ?? 'addr-${DateTime.now().millisecondsSinceEpoch}',
                                      recipientName: nameCtrl.text.trim(),
                                      phoneNumber: phoneCtrl.text.trim(),
                                      province: provCtrl.text.trim(),
                                      municipality: cityCtrl.text.trim(),
                                      barangay: brgyCtrl.text.trim(),
                                      streetName: streetCtrl.text.trim(),
                                      houseNumber: houseCtrl.text.trim(),
                                      postalCode: postalCtrl.text.trim(),
                                      label: selectedLabel,
                                      isDefault: makeDefault,
                                    );
                                    final updated = await SavedAddressBook.upsertAddress(user, savedEntry);
                                    await auth.updateShippingAddress(
                                      province: savedEntry.province,
                                      municipality: savedEntry.municipality,
                                      barangay: savedEntry.barangay,
                                      street: savedEntry.streetName,
                                      houseNumber: savedEntry.houseNumber,
                                    );
                                    if (!mounted) return;
                                    setState(() {
                                      _savedAddresses = updated;
                                      _address = savedEntry.formattedAddress;
                                      _customRecipientName = savedEntry.recipientName;
                                      _customContactNumber = savedEntry.phoneNumber;
                                      _selectedAddressLabel = savedEntry.label;
                                    });
                                    if (ctx.mounted) Navigator.of(ctx).pop();
                                  },
                                  child: Text(
                                    editingTarget != null ? 'Update & Use Address' : 'Save & Use Address',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EWalletPaymentSheet extends StatefulWidget {
  final String paymentMethod;
  final double finalTotal;
  final bool isEWallet;
  final void Function(String? proofPath, String? referenceLast6) onSuccess;
  final VoidCallback onCancel;

  const _EWalletPaymentSheet({
    required this.paymentMethod,
    required this.finalTotal,
    required this.isEWallet,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<_EWalletPaymentSheet> createState() => _EWalletPaymentSheetState();
}

class _EWalletPaymentSheetState extends State<_EWalletPaymentSheet> {
  String? _receiptDataUri;
  final List<TextEditingController> _referenceControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _referenceFocusNodes =
      List.generate(6, (_) => FocusNode());
  String? _errorMessage;
  bool _isUploading = false;

  @override
  void dispose() {
    for (final c in _referenceControllers) {
      c.dispose();
    }
    for (final f in _referenceFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _pickReceipt({bool fromCamera = false}) async {
    HapticService.selection();
    setState(() => _isUploading = true);
    final result = await pickNativeImage(fromCamera: fromCamera);
    if (!mounted) return;
    setState(() {
      _isUploading = false;
      if (result != null && result.isNotEmpty) {
        _receiptDataUri = result;
        _errorMessage = null;
      }
    });
  }

  void _showImageSourceChooser() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: AppColors.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Upload Payment Receipt',
                  style: AppTextStyles.heading(size: 16, weight: FontWeight.w700, color: AppColors.plum),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: AppColors.plum),
                  title: const Text('Take a Photo with Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickReceipt(fromCamera: true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppColors.plum),
                  title: const Text('Choose from Photo Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickReceipt(fromCamera: false);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (int i = 0; i < digits.length && (index + i) < 6; i++) {
        _referenceControllers[index + i].text = digits[i];
      }
      final nextIndex = (index + digits.length).clamp(0, 5);
      _referenceFocusNodes[nextIndex].requestFocus();
      return;
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        _referenceFocusNodes[index + 1].requestFocus();
      } else {
        _referenceFocusNodes[index].unfocus();
      }
    }
  }

  void _confirmPayment() {
    if (widget.isEWallet) {
      if (_receiptDataUri == null) {
        HapticService.error();
        setState(() {
          _errorMessage = 'Please upload your payment receipt screenshot.';
        });
        return;
      }

      final ref = _referenceControllers.map((c) => c.text.trim()).join();
      if (ref.length != 6 || !RegExp(r'^\d{6}$').hasMatch(ref)) {
        HapticService.error();
        setState(() {
          _errorMessage = 'Enter all 6 digits of your reference number.';
        });
        return;
      }

      HapticService.success();
      widget.onSuccess(_receiptDataUri, ref);
    } else {
      HapticService.success();
      widget.onSuccess(null, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Material(
          color: AppColors.cream,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isEWallet ? 'Pay with ${widget.paymentMethod}' : '${widget.paymentMethod} Payment',
                              style: AppTextStyles.heading(size: 20, weight: FontWeight.w700, color: AppColors.plum),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.isEWallet
                                  ? 'Scan this InstaPay QR code to complete your payment.'
                                  : 'Complete checkout transaction authorization.',
                              style: AppTextStyles.body(size: 12, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onCancel,
                        icon: const Icon(Icons.close, size: 20, color: AppColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.line, height: 1),
                  const SizedBox(height: 14),

                  // QR Code Container (Web Parity 1:1)
                  if (widget.isEWallet) ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.line),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/images/instapay-gcash.png',
                                width: 200,
                                height: 200,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Official Lumora InstaPay QR',
                              style: AppTextStyles.caption(size: 11, weight: FontWeight.w700, color: AppColors.plum),
                            ),
                            Text(
                              'Account: LUMORA BOUTIQUE • Transfer fees may apply.',
                              style: AppTextStyles.caption(size: 10, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Amount Due Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F1EB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE8D4C8)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Amount Due', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600, color: AppColors.ink)),
                          Text(
                            '₱${widget.finalTotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.plum),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Receipt Upload Section
                    Text('Payment receipt screenshot', style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.plum)),
                    const SizedBox(height: 6),
                    _receiptDataUri == null
                        ? InkWell(
                            onTap: _isUploading ? null : _showImageSourceChooser,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.line, width: 1.2),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _isUploading
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.plum))
                                      : const Icon(Icons.file_upload_outlined, size: 20, color: AppColors.plum),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isUploading ? 'Loading image...' : 'Upload receipt screenshot (Camera / Gallery)',
                                    style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600, color: AppColors.plum),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF2E7D32), width: 1.2),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.line),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: _receiptDataUri!.startsWith('data:image')
                                      ? Image.memory(
                                          base64Decode(_receiptDataUri!.split(',').last),
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(Icons.receipt_outlined, color: AppColors.plum),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF2E7D32)),
                                          const SizedBox(width: 4),
                                          Text('Receipt attached', style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: const Color(0xFF2E7D32))),
                                        ],
                                      ),
                                      Text('Screenshot ready to submit with order', style: AppTextStyles.body(size: 11, color: AppColors.muted)),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: _showImageSourceChooser,
                                  child: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.plum)),
                                ),
                              ],
                            ),
                          ),
                    const SizedBox(height: 4),
                    Text('JPG, PNG, or WEBP, up to 5 MB. Attached to order for admin verification.', style: AppTextStyles.caption(size: 10.5, color: AppColors.muted)),
                    const SizedBox(height: 16),

                    // 6-digit reference slots (Web Parity 1:1)
                    Text('Input the last 6 digits of Reference Number', style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.plum)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return Container(
                          width: 46,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _referenceControllers[index].text.isNotEmpty ? AppColors.plum : AppColors.line,
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: TextField(
                              controller: _referenceControllers[index],
                              focusNode: _referenceFocusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.plum,
                              ),
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (val) => _onDigitChanged(index, val),
                            ),
                          ),
                        );
                      }),
                    ),
                  ] else ...[
                    // Non-EWallet simulation notice
                    Text(
                      'Complete your ${widget.paymentMethod} transaction. Session valid for 15 minutes.',
                      style: AppTextStyles.body(size: 13, color: AppColors.muted),
                    ),
                  ],

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBE9E7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEF9A9A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: Color(0xFFC62828)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFC62828)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.line),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          onPressed: widget.onCancel,
                          child: const Text('Cancel', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.plum,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            elevation: 0,
                          ),
                          onPressed: _confirmPayment,
                          child: const Text(
                            'Confirm Payment',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
