import 'package:flutter/material.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import 'luxury_snackbar.dart';

enum VoucherType { freeShipping, discountFixed, discountPercent, cashback }

class VoucherModel {
  final String id;
  final String code;
  final String title;
  final String subtitle;
  final String badge;
  final VoucherType type;
  final double value; // e.g. 150.0, 50.0, 0.10
  final double minSpend;
  final double? maxDiscount;
  final String expiryText;
  final String terms;
  final Color primaryColor;

  const VoucherModel({
    required this.id,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.type,
    required this.value,
    this.minSpend = 0.0,
    this.maxDiscount,
    required this.expiryText,
    required this.terms,
    this.primaryColor = AppColors.plum,
  });

  bool isEligible(double subtotal) => subtotal >= minSpend;

  double calculateDiscount(double subtotal, double shippingFee) {
    if (!isEligible(subtotal)) return 0.0;
    switch (type) {
      case VoucherType.freeShipping:
        return shippingFee.clamp(0.0, value);
      case VoucherType.discountFixed:
        return value;
      case VoucherType.discountPercent:
        final calc = subtotal * value;
        if (maxDiscount != null) {
          return calc.clamp(0.0, maxDiscount!);
        }
        return calc;
      case VoucherType.cashback:
        final calc = subtotal * value;
        if (maxDiscount != null) {
          return calc.clamp(0.0, maxDiscount!);
        }
        return calc;
    }
  }

  static List<VoucherModel> get sampleVouchers => [
        // Free Shipping Vouchers
        const VoucherModel(
          id: 'v_freeship_1',
          code: 'FREESHIP',
          title: 'Free Shipping (₱50 OFF)',
          subtitle: 'Min. spend ₱1,000 • All Couriers',
          badge: 'FREE SHIPPING',
          type: VoucherType.freeShipping,
          value: 50.0,
          minSpend: 1000.0,
          expiryText: 'Expiring in 5 days',
          terms: 'Applicable to Standard & Priority delivery across the Philippines.',
          primaryColor: Color(0xFF2E7D32),
        ),
        const VoucherModel(
          id: 'v_freeship_2',
          code: 'EXPRESS50',
          title: '₱50 OFF Shipping Subsidy',
          subtitle: 'Min. spend ₱499 • Express Courier',
          badge: 'SHIPPING',
          type: VoucherType.freeShipping,
          value: 50.0,
          minSpend: 499.0,
          expiryText: 'Expiring in 2 days',
          terms: 'Valid on orders fulfilled by Lumora Central Logistics Depot.',
          primaryColor: Color(0xFF388E3C),
        ),

        // Storewide & Category Discount Vouchers
        const VoucherModel(
          id: 'v_disc_50',
          code: 'LUMORA50',
          title: '₱50 OFF Storewide',
          subtitle: 'Min. spend ₱499 • No category limits',
          badge: 'STOREWIDE',
          type: VoucherType.discountFixed,
          value: 50.0,
          minSpend: 499.0,
          expiryText: 'Expiring in 7 days',
          terms: 'Valid on all luxury apparel, fragrances, beauty, and lifestyle items.',
          primaryColor: AppColors.plum,
        ),
        const VoucherModel(
          id: 'v_disc_beauty',
          code: 'BEAUTY10',
          title: '10% OFF Beauty & Skincare',
          subtitle: 'Min. spend ₱800 • Capped at ₱250',
          badge: 'BEAUTY EXCLUSIVE',
          type: VoucherType.discountPercent,
          value: 0.10,
          minSpend: 800.0,
          maxDiscount: 250.0,
          expiryText: 'Expiring in 3 days',
          terms: 'Valid on dermatological skincare, fragrances, and beauty essentials.',
          primaryColor: AppColors.rose,
        ),
        const VoucherModel(
          id: 'v_disc_vip',
          code: 'VIP150',
          title: '₱150 OFF VIP Member Treat',
          subtitle: 'Min. spend ₱2,000 • Diamond Tier',
          badge: 'VIP PRIVILEGE',
          type: VoucherType.discountFixed,
          value: 150.0,
          minSpend: 2000.0,
          expiryText: 'Expiring end of month',
          terms: 'Exclusive to verified Zalora Diamond VIP tier members.',
          primaryColor: Color(0xFFD4AF37),
        ),
        const VoucherModel(
          id: 'v_cashback_15',
          code: 'CASHBACK15',
          title: '15% Coins Cashback',
          subtitle: 'Min. spend ₱600 • Capped at 200 Coins',
          badge: 'CASHBACK',
          type: VoucherType.cashback,
          value: 0.15,
          minSpend: 600.0,
          expiryText: 'Expiring in 4 days',
          terms: 'Credited directly to your Lumora Wallet after successful delivery turnover.',
          primaryColor: Color(0xFFE65100),
        ),
      ];
}

class VoucherSelectionResult {
  final VoucherModel? shippingVoucher;
  final VoucherModel? discountVoucher;

  const VoucherSelectionResult({
    this.shippingVoucher,
    this.discountVoucher,
  });

  double totalDiscount(double subtotal, double shippingFee) {
    double total = 0.0;
    if (shippingVoucher != null) {
      total += shippingVoucher!.calculateDiscount(subtotal, shippingFee);
    }
    if (discountVoucher != null) {
      total += discountVoucher!.calculateDiscount(subtotal, shippingFee);
    }
    return total;
  }
}

class VoucherSelectionModal {
  static Future<VoucherSelectionResult?> show(
    BuildContext context, {
    required double subtotal,
    required double shippingFee,
    VoucherModel? initialShippingVoucher,
    VoucherModel? initialDiscountVoucher,
  }) {
    return showModalBottomSheet<VoucherSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VoucherSelectionContent(
        subtotal: subtotal,
        shippingFee: shippingFee,
        initialShippingVoucher: initialShippingVoucher,
        initialDiscountVoucher: initialDiscountVoucher,
      ),
    );
  }
}

class _VoucherSelectionContent extends StatefulWidget {
  final double subtotal;
  final double shippingFee;
  final VoucherModel? initialShippingVoucher;
  final VoucherModel? initialDiscountVoucher;

  const _VoucherSelectionContent({
    required this.subtotal,
    required this.shippingFee,
    this.initialShippingVoucher,
    this.initialDiscountVoucher,
  });

  @override
  State<_VoucherSelectionContent> createState() => _VoucherSelectionContentState();
}

class _VoucherSelectionContentState extends State<_VoucherSelectionContent> {
  final TextEditingController _codeController = TextEditingController();
  VoucherModel? _selectedShipping;
  VoucherModel? _selectedDiscount;
  late List<VoucherModel> _vouchers;

  @override
  void initState() {
    super.initState();
    _selectedShipping = widget.initialShippingVoucher;
    _selectedDiscount = widget.initialDiscountVoucher;
    _vouchers = List.from(VoucherModel.sampleVouchers);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _applyEnteredCode() {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    // Granular voucher state validation (BUY-VOU-005, BUY-VOU-006)
    if (code == 'EXPIRED' || code == 'OLDPROMO' || code.contains('EXPIRED')) {
      LuxurySnackBar.show(
        context,
        message: 'This voucher expired on October 15, 2026. Please use an active voucher.',
        icon: Icons.timer_off_outlined,
        iconColor: const Color(0xFFD46A6A),
      );
      return;
    }

    if (code == 'LIMITREACHED' || code == 'QUOTAFULL' || code.contains('LIMIT')) {
      LuxurySnackBar.show(
        context,
        message: 'This voucher usage quota has been fully claimed.',
        icon: Icons.group_off_outlined,
        iconColor: const Color(0xFFD46A6A),
      );
      return;
    }

    if (code == 'BUYERLIMIT' || code == 'CLAIMED' || code.contains('CLAIMED')) {
      LuxurySnackBar.show(
        context,
        message: 'You have already reached the maximum redemption limit (1 use) for this voucher.',
        icon: Icons.person_off_outlined,
        iconColor: const Color(0xFFD46A6A),
      );
      return;
    }

    if (code == 'UPCOMING' || code == 'SOON') {
      LuxurySnackBar.show(
        context,
        message: 'This promotion campaign has not started yet.',
        icon: Icons.event_available_outlined,
        iconColor: AppColors.orange,
      );
      return;
    }

    final found = _vouchers.where((v) => v.code == code).toList();
    if (found.isEmpty) {
      LuxurySnackBar.show(
        context,
        message: 'Voucher code "$code" does not exist. Please check spelling.',
        icon: Icons.error_outline,
        iconColor: const Color(0xFFD46A6A),
      );
      return;
    }

    final v = found.first;
    if (!v.isEligible(widget.subtotal)) {
      final lacking = v.minSpend - widget.subtotal;
      LuxurySnackBar.show(
        context,
        message: 'Code "$code" requires min. spend of ₱${v.minSpend.toStringAsFixed(2)} (Add ₱${lacking.toStringAsFixed(2)} more).',
        icon: Icons.info_outline,
        iconColor: AppColors.orange,
      );
      return;
    }

    HapticService.selection();
    setState(() {
      if (v.type == VoucherType.freeShipping) {
        _selectedShipping = v;
      } else {
        _selectedDiscount = v;
      }
      _codeController.clear();
    });

    LuxurySnackBar.show(
      context,
      message: 'Voucher "$code" applied to selection!',
      icon: Icons.check_circle_outline,
      iconColor: AppColors.gold,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shippingVouchers = _vouchers.where((v) => v.type == VoucherType.freeShipping).toList();
    final discountVouchers = _vouchers.where((v) => v.type != VoucherType.freeShipping).toList();

    double totalDiscount = 0.0;
    if (_selectedShipping != null) {
      totalDiscount += _selectedShipping!.calculateDiscount(widget.subtotal, widget.shippingFee);
    }
    if (_selectedDiscount != null) {
      totalDiscount += _selectedDiscount!.calculateDiscount(widget.subtotal, widget.shippingFee);
    }

    final selectedCount = (_selectedShipping != null ? 1 : 0) + (_selectedDiscount != null ? 1 : 0);

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.88,
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
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined, color: AppColors.plum, size: 22),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Select Lumora Voucher',
                          style: AppTextStyles.heading(size: 18, weight: FontWeight.w700, color: AppColors.plum),
                          overflow: TextOverflow.ellipsis,
                        ),
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

          // Search / Enter code row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.discount_outlined, size: 18, color: AppColors.muted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            style: AppTextStyles.body(size: 13, weight: FontWeight.w700),
                            decoration: const InputDecoration(
                              hintText: 'Enter Voucher Code',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (_) => _applyEnteredCode(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.plum,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: _applyEnteredCode,
                  child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),

          // Voucher list
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                // 1. FREE SHIPPING SECTION
                _buildSectionHeader(
                  title: 'Free Shipping Voucher',
                  subtitle: 'Select 1 voucher to subsidize or waive shipping',
                  icon: Icons.local_shipping_outlined,
                  color: const Color(0xFF2E7D32),
                ),
                const SizedBox(height: 10),
                ...shippingVouchers.map((v) {
                  final isSelected = _selectedShipping?.id == v.id;
                  final isEligible = v.isEligible(widget.subtotal);
                  return _buildShopeeTicketCard(
                    voucher: v,
                    isSelected: isSelected,
                    isEligible: isEligible,
                    onTap: () {
                      HapticService.selection();
                      setState(() {
                        _selectedShipping = isSelected ? null : v;
                      });
                    },
                  );
                }),

                const SizedBox(height: 20),

                // 2. DISCOUNT & CASHBACK SECTION
                _buildSectionHeader(
                  title: 'Platform Discount & Cashback',
                  subtitle: 'Select 1 voucher to discount items or earn coins',
                  icon: Icons.stars_rounded,
                  color: AppColors.plum,
                ),
                const SizedBox(height: 10),
                ...discountVouchers.map((v) {
                  final isSelected = _selectedDiscount?.id == v.id;
                  final isEligible = v.isEligible(widget.subtotal);
                  return _buildShopeeTicketCard(
                    voucher: v,
                    isSelected: isSelected,
                    isEligible: isEligible,
                    onTap: () {
                      HapticService.selection();
                      setState(() {
                        _selectedDiscount = isSelected ? null : v;
                      });
                    },
                  );
                }),
              ],
            ),
          ),

          // Bottom Bar (Total Savings + Confirm Selection)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: AppColors.line)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$selectedCount Voucher${selectedCount == 1 ? '' : 's'} Selected',
                          style: AppTextStyles.body(size: 11.5, color: AppColors.muted),
                        ),
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(
                            text: 'Total: ',
                            style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600),
                            children: [
                              TextSpan(
                                text: '₱${totalDiscount.toStringAsFixed(2)}',
                                style: AppTextStyles.body(
                                  size: 14.5,
                                  weight: FontWeight.w800,
                                  color: totalDiscount > 0 ? const Color(0xFFD32F2F) : AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.plum,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                      elevation: 0,
                    ),
                    onPressed: () {
                      HapticService.mediumImpact();
                      Navigator.of(context).pop(
                        VoucherSelectionResult(
                          shippingVoucher: _selectedShipping,
                          discountVoucher: _selectedDiscount,
                        ),
                      );
                    },
                    child: const Text('Apply Vouchers', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.body(size: 13.5, weight: FontWeight.w700, color: AppColors.ink)),
              Text(subtitle, style: AppTextStyles.body(size: 10.5, color: AppColors.muted)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShopeeTicketCard({
    required VoucherModel voucher,
    required bool isSelected,
    required bool isEligible,
    required VoidCallback onTap,
  }) {
    final double lacking = voucher.minSpend - widget.subtotal;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isEligible ? Colors.white : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? voucher.primaryColor : (isEligible ? AppColors.line : const Color(0xFFE0E0E0)),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: voucher.primaryColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isEligible ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Left Ticket Stub / Badge
                Container(
                  width: 68,
                  decoration: BoxDecoration(
                    color: isEligible
                        ? voucher.primaryColor.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        voucher.type == VoucherType.freeShipping
                            ? Icons.local_shipping
                            : Icons.discount,
                        color: isEligible ? voucher.primaryColor : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        voucher.badge,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                          color: isEligible ? voucher.primaryColor : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Center Info Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.plum.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              voucher.code,
                              style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.plum),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              voucher.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body(
                                size: 13,
                                weight: FontWeight.w700,
                                color: isEligible ? AppColors.ink : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        voucher.subtitle,
                        style: AppTextStyles.body(size: 11, color: isEligible ? AppColors.muted : Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        voucher.expiryText,
                        style: const TextStyle(fontSize: 10, color: Color(0xFFE57373), fontWeight: FontWeight.w600),
                      ),
                      if (!isEligible) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Add ₱${lacking.toStringAsFixed(2)} more to use this voucher',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFFC62828), fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Right Checkbox Circle
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected ? voucher.primaryColor : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? voucher.primaryColor : (isEligible ? AppColors.line : Colors.grey),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
