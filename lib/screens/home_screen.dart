import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_modal.dart';
import '../widgets/cards.dart';
import '../widgets/notification_center_modal.dart';
import 'categories_screen.dart';
import 'chat_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateToTab;
  final Function(String category)? onSelectCategory;

  const HomeScreen({super.key, this.onNavigateToTab, this.onSelectCategory});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _heroPageController = PageController();
  final ValueNotifier<int> _currentHeroIndex = ValueNotifier<int>(0);
  Timer? _heroTimer;
  String _activeCategoryTab = 'ALL';

  final List<String> _textCategories = [
    'ALL',
    'LUXURY',
    'WOMEN',
    'MEN',
    'BEAUTY',
    'ELECTRONICS',
    'HOME & LIVING',
    'SPORTS',
  ];

  @override
  void initState() {
    super.initState();
    MockData.catalogVersion.addListener(_onCatalogUpdated);
    _heroTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_heroPageController.hasClients) {
        final nextIndex = (_currentHeroIndex.value + 1) % MockData.heroSlides.length;
        _heroPageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 650),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  void _onCatalogUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    MockData.catalogVersion.removeListener(_onCatalogUpdated);
    _heroTimer?.cancel();
    _currentHeroIndex.dispose();
    _heroPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deals = MockData.flashDeals;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(child: _buildZaloraCategoryStrip(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(child: _buildHeroCarousel(context)),
              SliverToBoxAdapter(child: _buildTrendsCarousel(context)),
              SliverToBoxAdapter(child: _buildFlashDealsSection(deals)),
              SliverToBoxAdapter(child: _buildCuratedSection(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        children: [
          // Integrated Luxury Search Bar
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticService.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const CategoriesScreen(initialCategory: 'All'),
                  ),
                );
              },
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(99),
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
                    const Icon(Icons.search, size: 19, color: AppColors.rose),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search luxury, beauty, fashion...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(
                          size: 12.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Wishlist Action with live reactive badge (gated to logged in members)
          Consumer2<AuthProvider, WishlistProvider>(
            builder: (context, auth, wishlist, _) {
              final bool showWishlistBadge = auth.isLoggedIn && wishlist.count > 0;
              final bool isFavActive = auth.isLoggedIn && wishlist.count > 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  _iconBtn(
                    isFavActive
                        ? Icons.favorite
                        : Icons.favorite_border_rounded,
                    iconColor: isFavActive ? AppColors.rose : AppColors.plum,
                    onTap: () {
                      if (!auth.isLoggedIn) {
                        AuthModal.show(
                          context,
                          actionName: 'view and manage your luxury wishlist',
                        );
                      } else {
                        HapticService.lightImpact();
                        _showWishlistModal(context);
                      }
                    },
                  ),
                  if (showWishlistBadge)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.rose,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 17,
                          minHeight: 17,
                        ),
                        child: Text(
                          '${wishlist.count}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),

          // Live Chat Concierge
          _iconBtn(
            Icons.chat_bubble_outline_rounded,
            onTap: () {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              if (!auth.isLoggedIn) {
                AuthModal.show(
                  context,
                  actionName: 'connect with our live luxury concierge',
                );
              } else {
                HapticService.lightImpact();
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const ChatScreen()));
              }
            },
          ),
          const SizedBox(width: 8),

          // Shopee-Style Notification Center (gated to logged in members)
          Consumer3<AuthProvider, OrderProvider, WalletProvider>(
            builder: (context, auth, orderProvider, walletProvider, _) {
              final liveNotifs = NotificationCenterModal.buildNotificationsForOrders(
                orderProvider.orders,
                user: auth.currentUser,
                walletMethods: walletProvider.methods,
              );
              final liveUnread = liveNotifs.where((n) => !n.isRead).length;
              return ValueListenableBuilder<int>(
                valueListenable: NotificationCenterModal.unreadCountNotifier,
                builder: (context, _, _) {
                  final bool showNotifBadge = auth.isLoggedIn && liveUnread > 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _iconBtn(
                        Icons.notifications_none_rounded,
                        onTap: () {
                          if (!auth.isLoggedIn) {
                            AuthModal.show(
                              context,
                              actionName: 'view your order notifications and alerts',
                            );
                          } else {
                            HapticService.lightImpact();
                            NotificationCenterModal.show(context);
                          }
                        },
                      ),
                      if (showNotifBadge)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: const BoxDecoration(
                              color: AppColors.orange,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$liveUnread',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Zalora-Style Clean Text Category Navigation Strip (Directly Below Search Bar)
  Widget _buildZaloraCategoryStrip(BuildContext context) {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: _textCategories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final cat = _textCategories[index];
          final isSelected = cat == _activeCategoryTab;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticService.selection();
              setState(() {
                _activeCategoryTab = cat;
              });
              if (widget.onSelectCategory != null) {
                final targetCategory = cat == 'ALL'
                    ? 'All'
                    : cat == 'LUXURY'
                        ? 'Luxury'
                        : cat == 'WOMEN'
                            ? 'Women'
                            : cat == 'MEN'
                                ? 'Men'
                                : cat == 'BEAUTY'
                                    ? 'Beauty'
                                    : cat == 'ELECTRONICS'
                                        ? 'Electronics'
                                        : cat == 'HOME & LIVING'
                                            ? 'Home & Living'
                                            : 'Sports';
                widget.onSelectCategory!(targetCategory);
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cat,
                  style: AppTextStyles.body(
                    size: 12,
                    weight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.plum : AppColors.muted,
                  ).copyWith(letterSpacing: 1.3),
                ),
                const SizedBox(height: 4),
                // Minimalist Underline Indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.fastOutSlowIn,
                  height: 2,
                  width: isSelected ? 22 : 0,
                  decoration: BoxDecoration(
                    color: AppColors.rose,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroCarousel(BuildContext context) {
    final slides = MockData.heroSlides;

    return Column(
      children: [
        SizedBox(
          height: 195,
          child: PageView.builder(
            controller: _heroPageController,
            itemCount: slides.length,
            onPageChanged: (index) {
              _currentHeroIndex.value = index;
            },
            itemBuilder: (context, index) {
              final slide = slides[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.plum.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Slide Image
                      Image.asset(
                        slide.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: const BoxDecoration(
                            gradient: AppColors.heroGradient,
                          ),
                        ),
                      ),
                      // Gradient Overlay for Readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.72),
                              Colors.black.withValues(alpha: 0.25),
                              Colors.transparent,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                      // Text & CTA
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              slide.eyebrow,
                              style: AppTextStyles.body(
                                size: 10,
                                weight: FontWeight.w700,
                                color: AppColors.flowGold,
                              ).copyWith(letterSpacing: 1.8),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              slide.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.heading(
                                size: 20,
                                weight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.cream,
                                foregroundColor: AppColors.plum,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 9,
                                ),
                                elevation: 3,
                                shadowColor: Colors.black.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              onPressed: () {
                                HapticService.lightImpact();
                                if (index == 3 &&
                                    widget.onNavigateToTab != null) {
                                  widget.onNavigateToTab!(2);
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const CategoriesScreen(
                                        initialCategory: 'All',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    slide.ctaText,
                                    style: AppTextStyles.body(
                                      size: 11.5,
                                      weight: FontWeight.w700,
                                      color: AppColors.plum,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: AppColors.plum,
                                  ),
                                ],
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
        const SizedBox(height: 10),
        // Indicator dots
        ValueListenableBuilder<int>(
          valueListenable: _currentHeroIndex,
          builder: (context, activeIdx, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: activeIdx == index ? 18 : 6,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: activeIdx == index
                        ? AppColors.plum
                        : AppColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Zalora-Style Trends Carousel ("The Trend Edit")
  Widget _buildTrendsCarousel(BuildContext context) {
    final trends = MockData.trends;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THE TREND EDIT',
                      style: AppTextStyles.body(
                        size: 10,
                        weight: FontWeight.w700,
                        color: AppColors.rose,
                      ).copyWith(letterSpacing: 2.2),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Curated Directions',
                      style: AppTextStyles.heading(
                        size: 18,
                        weight: FontWeight.w700,
                        color: AppColors.plum,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    HapticService.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const CategoriesScreen(initialCategory: 'All'),
                      ),
                    );
                  },
                  child: Text(
                    'Explore All >',
                    style: AppTextStyles.body(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: AppColors.rose,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 205,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: trends.length,
              itemBuilder: (context, index) {
                final trend = trends[index];
                return GestureDetector(
                  onTap: () {
                    HapticService.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CategoriesScreen(
                          initialCategory: trend.categoryTarget,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 250,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.plum.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background Photo
                        Image.asset(
                          trend.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: AppColors.heroGradient,
                                ),
                              ),
                        ),
                        // Dark-to-Transparent Silk Vignette Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.15),
                                Colors.black.withValues(alpha: 0.4),
                                Colors.black.withValues(alpha: 0.85),
                              ],
                              stops: const [0.0, 0.45, 1.0],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        // Top Tag
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cream.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  size: 11,
                                  color: AppColors.rose,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  trend.tag,
                                  style: AppTextStyles.body(
                                    size: 9,
                                    weight: FontWeight.w800,
                                    color: AppColors.plum,
                                  ).copyWith(letterSpacing: 0.8),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Bottom Content
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                trend.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.heading(
                                  size: 16,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                trend.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body(
                                  size: 11,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'Shop Direction',
                                    style: AppTextStyles.body(
                                      size: 11,
                                      weight: FontWeight.w700,
                                      color: AppColors.flowGold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward,
                                    size: 12,
                                    color: AppColors.flowGold,
                                  ),
                                ],
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

  Widget _buildFlashDealsSection(List<Product> deals) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.plum,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: AppColors.flowGold,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIMITED PRIVILEGE',
                        style: AppTextStyles.body(
                          size: 9.5,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ).copyWith(letterSpacing: 0.8),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'UP TO 50% OFF',
                  style: AppTextStyles.body(
                    size: 11.5,
                    weight: FontWeight.w700,
                    color: AppColors.rose,
                  ).copyWith(letterSpacing: 0.5),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticService.lightImpact();
                    if (widget.onNavigateToTab != null) {
                      widget.onNavigateToTab!(2);
                    }
                  },
                  child: Text(
                    'See All',
                    style: AppTextStyles.body(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: AppColors.rose,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 206,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: deals.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: DealCard(
                    deal: deals[index],
                    heroTag: 'home_deal_${deals[index].id}',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuratedSection(BuildContext context) {
    final String mappedCategory = _activeCategoryTab == 'ALL'
        ? 'All'
        : _activeCategoryTab == 'LUXURY'
            ? 'Luxury'
            : _activeCategoryTab == 'WOMEN'
                ? 'Women'
                : _activeCategoryTab == 'MEN'
                    ? 'Men'
                    : _activeCategoryTab == 'BEAUTY'
                        ? 'Beauty'
                        : _activeCategoryTab == 'ELECTRONICS'
                            ? 'Electronics'
                            : _activeCategoryTab == 'HOME & LIVING'
                                ? 'Home & Living'
                                : 'Sports';

    final products = mappedCategory == 'All'
        ? MockData.allProducts
        : MockData.allProducts
            .where((p) => p.category.toLowerCase() == mappedCategory.toLowerCase())
            .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mappedCategory == 'All'
                        ? 'Curated Recommendations'
                        : '$mappedCategory Collection',
                    style: AppTextStyles.heading(
                      size: 18,
                      weight: FontWeight.w700,
                      color: AppColors.plum,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${products.length} exclusive ${products.length == 1 ? 'item' : 'items'} available',
                    style: AppTextStyles.body(
                      size: 11.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              if (mappedCategory != 'All')
                GestureDetector(
                  onTap: () {
                    HapticService.selection();
                    setState(() => _activeCategoryTab = 'ALL');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.rose.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.close, size: 12, color: AppColors.rose),
                        const SizedBox(width: 4),
                        Text(
                          'Clear Filter',
                          style: AppTextStyles.body(
                            size: 11,
                            weight: FontWeight.w700,
                            color: AppColors.rose,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          products.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.rose),
                      const SizedBox(height: 12),
                      Text(
                        'No items currently listed under $mappedCategory',
                        style: AppTextStyles.body(size: 13, color: AppColors.muted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.plum,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                        ),
                        onPressed: () => setState(() => _activeCategoryTab = 'ALL'),
                        child: const Text('Explore All Items'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.64,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                  ),
                  itemBuilder: (context, index) {
                    return ProductCard(
                      product: products[index],
                      heroTag: 'home_curated_${products[index].id}',
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _iconBtn(
    IconData icon, {
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.cream,
          border: Border.all(color: AppColors.line),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: iconColor ?? AppColors.plum),
      ),
    );
  }

  // Header Luxury Wishlist Modal
  void _showWishlistModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer<WishlistProvider>(
          builder: (context, liveWishlist, _) {
            final savedProducts = liveWishlist.getWishlistItems(
              MockData.unifiedCatalog,
            );

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: const BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
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
                          child: const Icon(
                            Icons.favorite,
                            size: 18,
                            color: AppColors.rose,
                          ),
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
                                '${savedProducts.length} items saved',
                                style: AppTextStyles.body(
                                  size: 11.5,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 20,
                            color: AppColors.muted,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.line, height: 20),
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
                                    'Tap the heart icon on any luxury piece to save it here for later.',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.body(
                                      size: 13,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            itemCount: savedProducts.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
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
                                      color: AppColors.plum.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: AppColors.blush1,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: p.imagePath != null
                                          ? buildLumoraImage(
                                              p.imagePath!,
                                              fit: BoxFit.cover,
                                            )
                                          : Icon(
                                              p.icon,
                                              color: AppColors.plum,
                                              size: 24,
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.plum,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            99,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ProductDetailScreen(product: p),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'View',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: AppColors.muted,
                                      ),
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
}
