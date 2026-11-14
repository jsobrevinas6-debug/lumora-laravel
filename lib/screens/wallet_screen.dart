import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/wallet_provider.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/luxury_snackbar.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  void _showAddPaymentMethodModal(BuildContext context) {
    HapticService.selection();
    String selectedType = 'gcash';
    final nameCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    bool setAsDefault = true;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(22, 20, 22, MediaQuery.viewInsetsOf(ctx).bottom + 28),
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add Payment Method',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.plum,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Securely link your e-wallet or bank account for instant one-tap checkout.',
                    style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted),
                  ),
                  const SizedBox(height: 18),

                  // Wallet Type Pills (GCash, Maya, Bank Transfer)
                  Text(
                    'Wallet / Payment Type',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.plum),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypePill(
                          label: 'GCash',
                          isSelected: selectedType == 'gcash',
                          color: const Color(0xFF007DFE),
                          onTap: () => setModalState(() => selectedType = 'gcash'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTypePill(
                          label: 'Maya',
                          isSelected: selectedType == 'maya',
                          color: const Color(0xFF2EAA54),
                          onTap: () => setModalState(() => selectedType = 'maya'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTypePill(
                          label: 'Bank',
                          isSelected: selectedType == 'bank',
                          color: AppColors.plum,
                          onTap: () => setModalState(() => selectedType = 'bank'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Account Name
                  Text(
                    'Account Full Name *',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.plum),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nameCtrl,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText: 'e.g. Juan Dela Cruz',
                      hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFFB2A4A1)),
                      filled: true,
                      fillColor: const Color(0xFFFAF5F2),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE8D8D0)),
                      ),
                    ),
                    validator: (v) => v?.trim().isEmpty == true ? 'Account name is required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Account / Mobile Number
                  Text(
                    selectedType == 'bank' ? 'Bank Account Number *' : 'Registered Mobile Number *',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.plum),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: numberCtrl,
                    keyboardType: selectedType == 'bank' ? TextInputType.number : TextInputType.phone,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText: selectedType == 'bank' ? 'e.g. 1093 4819 2819' : '09XX XXX XXXX',
                      hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFFB2A4A1)),
                      filled: true,
                      fillColor: const Color(0xFFFAF5F2),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE8D8D0)),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Account number is required';
                      if (selectedType != 'bank' && !RegExp(r'^09\d{9}$').hasMatch(v.trim().replaceAll(' ', ''))) {
                        return 'Must use valid 09XXXXXXXXX format';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Default Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: setAsDefault,
                        activeColor: AppColors.plum,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) => setModalState(() => setAsDefault = val ?? false),
                      ),
                      Text(
                        'Set as default payment method',
                        style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.ink, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.plum,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (!formKey.currentState!.validate()) {
                          HapticService.error();
                          return;
                        }

                        final providerName = selectedType == 'gcash'
                            ? 'GCash'
                            : (selectedType == 'maya' ? 'Maya Wallet' : 'Bank Transfer');

                        final wallet = Provider.of<WalletProvider>(context, listen: false);
                        wallet.addMethod(
                          type: selectedType,
                          name: providerName,
                          accountName: nameCtrl.text.trim(),
                          accountNumber: numberCtrl.text.trim(),
                          isDefault: setAsDefault,
                        );

                        HapticService.success();
                        Navigator.of(ctx).pop();
                        LuxurySnackBar.show(
                          context,
                          message: '$providerName saved successfully!',
                          icon: Icons.check_circle_outline_rounded,
                        );
                      },
                      child: Text(
                        'Save Payment Method',
                        style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
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

  Widget _buildTypePill({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticService.selection();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : const Color(0xFFFAF5F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE8D8D0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? color : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blush1,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.plum),
          onPressed: () {
            HapticService.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Wallet & Payments',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.plum,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, _) {
          final methods = wallet.methods;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.plum, Color(0xFF5A2748)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.plum.withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LUMORA WALLET',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold,
                          ),
                        ),
                        const Icon(Icons.contactless_outlined, color: Colors.white, size: 22),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      methods.isNotEmpty ? methods.first.name : 'Digital Payments',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      methods.isNotEmpty ? methods.first.maskedNumber : 'No linked payment method',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section Header with Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saved Methods',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.plum,
                    ),
                  ),
                  InkWell(
                    onTap: () => _showAddPaymentMethodModal(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.add, size: 16, color: AppColors.rose),
                          const SizedBox(width: 4),
                          Text(
                            'Add Method',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.rose,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (methods.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8D8D0)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, size: 36, color: AppColors.muted),
                        const SizedBox(height: 10),
                        Text(
                          'No payment methods linked',
                          style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.plum),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add GCash, Maya, or bank account for faster checkouts.',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...methods.map((m) => _buildMethodItem(context, m, wallet)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMethodItem(BuildContext context, SavedPaymentMethod m, WalletProvider wallet) {
    Color badgeColor = AppColors.plum;
    if (m.type == 'gcash') badgeColor = const Color(0xFF007DFE);
    if (m.type == 'maya') badgeColor = const Color(0xFF2EAA54);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: m.isDefault ? AppColors.rose : const Color(0xFFE8D8D0),
          width: m.isDefault ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.plum.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              m.type == 'bank' ? Icons.account_balance_outlined : Icons.smartphone_rounded,
              color: badgeColor,
              size: 22,
            ),
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
                        m.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.plum,
                        ),
                      ),
                    ),
                    if (m.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF3EC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'DEFAULT',
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF385333),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${m.accountName} • ${m.maskedNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF9C8A8F)),
            onSelected: (val) {
              HapticService.selection();
              if (val == 'default') {
                wallet.setDefault(m.id);
                LuxurySnackBar.show(context, message: '${m.name} set as default payment method.');
              } else if (val == 'delete') {
                wallet.removeMethod(m.id);
                LuxurySnackBar.show(context, message: '${m.name} removed.');
              }
            },
            itemBuilder: (ctx) => [
              if (!m.isDefault)
                const PopupMenuItem(
                  value: 'default',
                  child: Text('Set as default'),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete method', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
