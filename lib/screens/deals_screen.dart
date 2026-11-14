import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_modal.dart';
import '../widgets/cards.dart';
import '../widgets/luxury_snackbar.dart';
import 'product_detail_screen.dart';

class DealsScreen extends StatefulWidget {
  final VoidCallback? onBrowseCatalog;

  const DealsScreen({super.key, this.onBrowseCatalog});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  String _selectedCategory = 'All';
  late Timer _timer;
  final ValueNotifier<Duration> _remainingTime = ValueNotifier<Duration>(
    const Duration(hours: 4, minutes: 28, seconds: 15),
  );

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.value.inSeconds > 0) {
        _remainingTime.value = _remainingTime.value - const Duration(seconds: 1);
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _remainingTime.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$hours : $minutes : $seconds';
  }

  List<Product> _getDeals() {
    // Collect all products with originalPrice > price or isFlashDeal
    final deals = [
      ...MockData.flashDeals,
      ...MockData.allProducts.where((p) => p.originalPrice != null && p.originalPrice! > p.price),
    ];

    if (_selectedCategory == 'All') return deals;
    return deals.where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...MockData.categories.map((c) => c.name)];
    final deals = _getDeals();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildCountdownBanner()),
              SliverToBoxAdapter(child: _buildVouchersCarousel()),
              SliverToBoxAdapter(child: _buildCategoryPills(categories)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
                sliver: SliverToBoxAdapter(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey<String>(_selectedCategory),
                    tween: Tween<double>(begin: 10.0, end: 0.0),
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.fastOutSlowIn,
                    builder: (context, dy, child) => Transform.translate(
                      offset: Offset(0, dy),
                      child: child,
                    ),
                    child: Column(
                      children: [
                        for (final deal in deals) _buildDealListItem(context, deal),
                      ],
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.rose.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.rose, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flash Sale Hub',
                  style: AppTextStyles.heading(
                    size: 22,
                    weight: FontWeight.w700,
                    color: AppColors.plum,
                  ),
                ),
                Text(
                  'Curated discounts across all departments',
                  style: AppTextStyles.body(size: 11.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Flash Sale Reminder',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.plum.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active_outlined, color: AppColors.plum, size: 18),
            ),
            onPressed: () {
              HapticService.selection();
              LuxurySnackBar.show(
                context,
                message: 'Flash Sale Reminder active! You will be notified 15 minutes before the sale.',
                icon: Icons.notifications_active_outlined,
                iconColor: AppColors.gold,
              );
            },
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            decoration: BoxDecoration(
              color: AppColors.plum,
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text(
              'UP TO 50% OFF',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      'LIMITED TIME SALE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(
                        size: 11.5,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ).copyWith(letterSpacing: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<Duration>(
              valueListenable: _remainingTime,
              builder: (context, d, _) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    _formatDuration(d),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVouchersCarousel() {
    final vouchers = [
      {'code': 'LUMORA50', 'desc': '₱50 OFF on orders over ₱499', 'badge': 'STOREWIDE'},
      {'code': 'BEAUTY10', 'desc': '10% OFF on all Skincare items', 'badge': 'CATEGORY'},
      {'code': 'FREESHIP', 'desc': 'Free Shipping on orders ₱1,000+', 'badge': 'SHIPPING'},
    ];

    return SizedBox(
      height: 78,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: vouchers.length,
        separatorBuilder: (_, index) => const SizedBox(width: 10),
        itemBuilder: (context, idx) {
          final v = vouchers[idx];
          return GestureDetector(
            onTap: () async {
              HapticService.selection();
              await Clipboard.setData(ClipboardData(text: v['code']!));
              if (context.mounted) {
                LuxurySnackBar.show(
                  context,
                  message: 'Voucher "${v['code']}" copied! Apply at Checkout for discounts.',
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.gold,
                );
              }
            },
            child: Container(
              width: 240,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.plum.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.blush1,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.discount_outlined, size: 16, color: AppColors.terracotta),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Text(
                                v['code']!,
                                style: AppTextStyles.body(
                                  size: 11.5,
                                  weight: FontWeight.w800,
                                  color: AppColors.plum,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.plum.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  v['badge']!,
                                  style: const TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.plum,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.orange.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'TAP TO COPY',
                                  style: TextStyle(
                                    fontSize: 6.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          v['desc']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body(size: 10, color: AppColors.muted),
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
    );
  }

  Widget _buildCategoryPills(List<String> categories) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
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
                height: 34,
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
                            color: AppColors.plum.withValues(alpha: 0.22),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    cat,
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
        },
      ),
    );
  }

  Widget _buildDealListItem(BuildContext context, Product p) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cart = Provider.of<CartProvider>(context, listen: false);

    final discountPercent = p.originalPrice != null && p.originalPrice! > p.price
        ? (((p.originalPrice! - p.price) / p.originalPrice!) * 100).round()
        : 35;
    final badgeLabel = (p.discountLabel != null && p.discountLabel!.trim().isNotEmpty)
        ? p.discountLabel!
        : '-$discountPercent%';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LuxuryTapScale(
        onTap: () {
          HapticService.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: AppColors.plum.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Product Visual with real photography
              Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7ECE7),
                      gradient: p.imagePath == null
                          ? LinearGradient(
                              colors: p.gradient ?? [AppColors.plumLight, AppColors.plum],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: p.imagePath != null
                        ? buildLumoraImage(
                            p.imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              p.icon,
                              color: AppColors.plum,
                              size: 32,
                            ),
                          )
                        : Icon(
                            p.icon,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 36,
                          ),
                  ),
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.rose,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.rose.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        badgeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Product Info
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
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Text(
                            p.formattedPrice,
                            style: AppTextStyles.body(
                              size: 15,
                              weight: FontWeight.w800,
                              color: AppColors.plum,
                            ),
                          ),
                          if (p.originalPrice != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              p.formattedOriginalPrice,
                              style: AppTextStyles.body(
                                size: 11,
                                color: AppColors.muted,
                              ).copyWith(decoration: TextDecoration.lineThrough),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Progress Bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: 0.75,
                              backgroundColor: AppColors.blush1,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.terracotta),
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${p.soldCount} sold',
                          style: AppTextStyles.body(size: 10, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Add to Cart Action
              GestureDetector(
                onTap: () {
                  if (!auth.isLoggedIn) {
                    AuthModal.show(context, actionName: 'add this flash deal to your cart');
                  } else {
                    HapticService.selection();
                    cart.addToCart(p);
                    LuxurySnackBar.show(
                      context,
                      message: 'Added "${p.name}" to your bag!',
                      icon: Icons.shopping_bag_outlined,
                    );
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.plum,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_shopping_cart,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
