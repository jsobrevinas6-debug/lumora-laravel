import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_modal.dart';
import '../widgets/cards.dart';
import 'categories_screen.dart';
import 'product_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final wishlist = Provider.of<WishlistProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'Wishlist',
                      style: AppTextStyles.heading(
                        size: 24,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (auth.isLoggedIn && wishlist.count > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC62828),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${wishlist.count}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: !auth.isLoggedIn
                    ? _buildGuestState(context)
                    : wishlist.count == 0
                        ? _buildEmptyState(context)
                        : _buildWishlistGrid(context, wishlist),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.blush1,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 38,
                color: AppColors.rose,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Save Items You Love',
              style: AppTextStyles.heading(
                size: 20,
                weight: FontWeight.w700,
                color: AppColors.plum,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Create an account to save your favourite luxury finds, get personalised recommendations, and never lose track of pieces you adore.',
              style: AppTextStyles.body(size: 13.5, color: AppColors.muted, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Feature bullets
            ...['Synced across all your devices', 'Notified on price drops & restocks', 'Share collections with friends'].map(
              (f) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 16, color: AppColors.orange),
                    const SizedBox(width: 7),
                    Text(f, style: AppTextStyles.body(size: 12.5, color: AppColors.ink)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => AuthModal.show(context, actionName: 'save items to your wishlist'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.plum,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Sign In or Create Account',
                  style: AppTextStyles.body(size: 14, weight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                HapticService.selection();
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CategoriesScreen(initialCategory: 'All'),
                    ),
                  );
                }
              },
              child: Text(
                'Browse as Guest',
                style: AppTextStyles.body(size: 13, color: AppColors.muted, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.blush1,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(Icons.favorite_border_rounded, size: 32, color: AppColors.rose),
            ),
            const SizedBox(height: 18),
            Text(
              'Your wishlist is empty',
              style: AppTextStyles.heading(size: 18, weight: FontWeight.w700, color: AppColors.plum),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the ♡ heart on any product to save it here.',
              style: AppTextStyles.body(size: 13, color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                HapticService.selection();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CategoriesScreen(initialCategory: 'All'),
                  ),
                );
              },
              icon: const Icon(Icons.diamond_outlined, size: 16),
              label: const Text('Discover Curated Catalog'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.plum,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistGrid(BuildContext context, WishlistProvider wishlist) {
    final savedProducts = wishlist.getWishlistItems(MockData.unifiedCatalog);

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.70,
      ),
      itemCount: savedProducts.length,
      itemBuilder: (context, index) {
        final product = savedProducts[index];
        return _WishlistProductCard(product: product);
      },
    );
  }
}

class _WishlistProductCard extends StatelessWidget {
  final Product product;
  const _WishlistProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final wishlist = Provider.of<WishlistProvider>(context, listen: false);

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          HapticService.selection();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: AppColors.plum.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image / icon
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Container(
                      height: 148,
                      width: double.infinity,
                      color: AppColors.blush1,
                      child: product.imagePath != null
                          ? buildLumoraImage(
                              product.imagePath!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Icon(product.icon, size: 52, color: AppColors.plum),
                              ),
                            )
                          : Center(
                              child: Icon(product.icon, size: 52, color: AppColors.plum),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        HapticService.mediumImpact();
                        wishlist.removeFavorite(product.id);
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 16,
                          color: Color(0xFFC62828),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Info
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.category.toUpperCase(),
                      style: AppTextStyles.body(
                        size: 9,
                        weight: FontWeight.w700,
                        color: AppColors.muted,
                      ).copyWith(letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.formattedPrice,
                      style: AppTextStyles.price(
                        size: 13,
                        weight: FontWeight.w700,
                        color: AppColors.plum,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
