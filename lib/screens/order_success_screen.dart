import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/order_tracking_modal.dart';

class OrderSuccessScreen extends StatelessWidget {
  final OrderModel? order;
  final String orderId;
  final String paymentMethod;
  final double totalAmount;
  final String deliveryAddress;

  const OrderSuccessScreen({
    super.key,
    this.order,
    this.orderId = 'LUM-88291',
    this.paymentMethod = 'Cash on Delivery (COD)',
    this.totalAmount = 0.0,
    this.deliveryAddress = 'Metro Manila, Philippines',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAnimatedBadge(),
                  const SizedBox(height: 24),
                  Text(
                    'Order Confirmed!',
                    style: AppTextStyles.heading(
                      size: 26,
                      weight: FontWeight.w700,
                      color: AppColors.plum,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thank you for your purchase! Your order has been placed and transmitted to the seller for packing.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(
                      size: 13.5,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildReceiptCard(),
                  const SizedBox(height: 28),
                  _buildActions(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBadge() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, val, child) {
        return Transform.scale(
          scale: val,
          child: child,
        );
      },
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: AppColors.cream,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.orange, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.check_rounded,
          color: AppColors.orange,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildReceiptCard() {
    final displayOrderId = order?.id ?? orderId;
    final displayPayment = order?.paymentMethod ?? paymentMethod;
    final displayTotal = order?.totalAmount ?? totalAmount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.plum.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order Number', style: AppTextStyles.body(size: 12.5, color: AppColors.muted)),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  displayOrderId,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.plum,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.line, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Payment Method', style: AppTextStyles.body(size: 12.5, color: AppColors.muted)),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  displayPayment,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.line, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estimated Delivery', style: AppTextStyles.body(size: 12.5, color: AppColors.muted)),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  '2-3 Business Days (Standard Local)',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppColors.plum,
                  ),
                ),
              ),
            ],
          ),
          if (order?.paymentReferenceLast6 != null && order!.paymentReferenceLast6!.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: AppColors.line, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('E-Wallet Reference', style: AppTextStyles.body(size: 12.5, color: AppColors.muted)),
                Text(
                  '•••• ${order!.paymentReferenceLast6}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
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
                'Total Paid',
                style: AppTextStyles.heading(
                  size: 16,
                  weight: FontWeight.w700,
                  color: AppColors.plum,
                ),
              ),
              Text(
                '₱${displayTotal.toStringAsFixed(2)}',
                style: AppTextStyles.body(
                  size: 18,
                  weight: FontWeight.w800,
                  color: AppColors.plum,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // 1. Primary Order Status & Stage Timeline Action
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.plum,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
              elevation: 0,
            ),
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text(
              'View Order Status & Timeline',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () {
              OrderTrackingModal.show(
                context,
                order: order,
                orderId: order?.id ?? orderId,
                trackingNumber: order?.trackingNumber ?? 'PH-LMR-882910',
                status: order?.status ?? 'pending',
                address: order?.deliveryAddress ?? deliveryAddress,
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // 2. Secondary Continue Shopping Action
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.plum,
              side: const BorderSide(color: AppColors.plum, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(
              'Continue Shopping',
              style: AppTextStyles.body(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.plum,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
