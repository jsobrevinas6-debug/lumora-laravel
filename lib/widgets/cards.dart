import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/wishlist_provider.dart';
import '../screens/product_detail_screen.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import 'auth_modal.dart';
import 'luxury_snackbar.dart';

/// Renders a product/order image whether the path is a remote URL, a data URI, or a bundled asset.
Widget buildLumoraImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  int? cacheWidth,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return Image.network(
      path,
      fit: fit,
      cacheWidth: cacheWidth,
      errorBuilder: errorBuilder,
    );
  }
  return Image.asset(
    path,
    fit: fit,
    cacheWidth: cacheWidth,
    errorBuilder: errorBuilder,
  );
}

class ProductCard extends StatelessWidget {
  final Product product;
  final String? heroTag;

  const ProductCard({
    super.key,
    required this.product,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;
    final wishlist = Provider.of<WishlistProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final isFav = auth.isLoggedIn && wishlist.isFavorite(p.id);
    final liveRating = orderProvider.getProductRatingSummary(p).averageRating.toStringAsFixed(1);

    final imageWidget = p.imagePath != null
        ? buildLumoraImage(
            p.imagePath!,
            fit: BoxFit.cover,
            cacheWidth: 380,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(p),
          )
        : _buildPlaceholder(p);

    return RepaintBoundary(
      child: LuxuryTapScale(
        onTap: () {
          HapticService.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(
                product: p,
                heroTag: heroTag,
              ),
            ),
          );
        },
        child: SizedBox(
        width: 156,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.cream,
            border: Border.all(color: AppColors.line),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.plum.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image or Gradient fallback
                  Container(
                    height: 126,
                    width: double.infinity,
                    color: const Color(0xFFF7ECE7),
                    child: heroTag != null
                        ? Hero(
                            tag: heroTag!,
                            child: Material(
                              type: MaterialType.transparency,
                              child: imageWidget,
                            ),
                          )
                        : imageWidget,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (p.brand.isNotEmpty) ...[
                          Text(
                            p.brand.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          p.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body(
                            size: 12.0,
                            weight: FontWeight.w600,
                            color: AppColors.ink,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.formattedPrice,
                          style: AppTextStyles.price(
                            size: 14.5,
                            weight: FontWeight.w700,
                            color: AppColors.plum,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 11.5, color: AppColors.gold),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '$liveRating · ${p.soldCount} sold',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body(
                                  size: 10.5,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (p.colorOptions.isNotEmpty || p.secondaryOptions.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (p.colorOptions.isNotEmpty) ...[
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: p.colorOptions.take(3).map((co) {
                                    return Container(
                                      margin: const EdgeInsets.only(right: 3),
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: co.color,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.line, width: 0.75),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                if (p.colorOptions.length > 3)
                                  Text(
                                    '+${p.colorOptions.length - 3}',
                                    style: const TextStyle(fontSize: 8.5, color: AppColors.muted),
                                  ),
                                const SizedBox(width: 4),
                              ],
                              if (p.secondaryOptions.isNotEmpty)
                                Expanded(
                                  child: Text(
                                    '${p.secondaryOptions.length} ${p.secondaryOptionLabel.toLowerCase() == "size" ? "sizes" : "options"}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.plumLight,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // Discount pill badge
              if (p.discountLabel != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.rose,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.rose.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      p.discountLabel!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              // Wishlist Heart Button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    if (!auth.isLoggedIn) {
                      AuthModal.show(context, actionName: 'save items to your luxury wishlist');
                      return;
                    }
                    HapticService.selection();
                    wishlist.toggleFavorite(p);
                    LuxurySnackBar.show(
                      context,
                      message: isFav
                          ? 'Removed from your Wishlist'
                          : 'Saved "${p.name}" to Wishlist',
                      icon: isFav ? Icons.favorite_border : Icons.favorite,
                      iconColor: isFav ? AppColors.muted : AppColors.rose,
                    );
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.cream.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.plum.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                        child: child,
                      ),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey<bool>(isFav),
                        size: 15,
                        color: isFav ? AppColors.rose : AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildPlaceholder(Product p) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: p.gradient ?? [AppColors.plumLight, AppColors.plum],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          p.icon,
          color: Colors.white.withValues(alpha: 0.9),
          size: 28,
        ),
      ),
    );
  }
}

class DealCard extends StatelessWidget {
  final Product deal;
  final String? heroTag;

  const DealCard({super.key, required this.deal, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final p = deal;
    final wishlist = Provider.of<WishlistProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isFav = auth.isLoggedIn && wishlist.isFavorite(p.id);

    final imageWidget = p.imagePath != null
        ? buildLumoraImage(
            p.imagePath!,
            fit: BoxFit.cover,
            cacheWidth: 380,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(p),
          )
        : _buildPlaceholder(p);

    return RepaintBoundary(
      child: LuxuryTapScale(
        onTap: () {
          HapticService.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(
                product: p,
                heroTag: heroTag,
              ),
            ),
          );
        },
        child: Container(
        width: 172,
        decoration: BoxDecoration(
          color: AppColors.cream,
          border: Border.all(color: AppColors.line),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.plum.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 112,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  heroTag != null
                      ? Hero(
                          tag: heroTag!,
                          child: Material(
                            type: MaterialType.transparency,
                            child: imageWidget,
                          ),
                        )
                      : imageWidget,
                  if (p.discountLabel != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7.5,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.rose,
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.rose.withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          p.discountLabel!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  // Deal Wishlist Heart Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        if (!auth.isLoggedIn) {
                          AuthModal.show(context, actionName: 'save items to your luxury wishlist');
                          return;
                        }
                        HapticService.selection();
                        wishlist.toggleFavorite(p);
                        LuxurySnackBar.show(
                          context,
                          message: isFav
                              ? 'Removed from your Wishlist'
                              : 'Saved "${p.name}" to Wishlist',
                          icon: isFav ? Icons.favorite_border : Icons.favorite,
                          iconColor: isFav ? AppColors.muted : AppColors.rose,
                        );
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.cream.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.plum.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, anim) => ScaleTransition(
                            scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                            child: child,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey<bool>(isFav),
                            size: 15,
                            color: isFav ? AppColors.rose : AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.brand.isNotEmpty) ...[
                    Text(
                      p.brand.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(
                      size: 12.5,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          p.formattedPrice,
                          style: AppTextStyles.price(
                            size: 14,
                            weight: FontWeight.w700,
                            color: AppColors.plum,
                          ),
                        ),
                        if (p.originalPrice != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            p.formattedOriginalPrice,
                            style: AppTextStyles.body(
                              size: 11.5,
                              color: AppColors.muted,
                            ).copyWith(decoration: TextDecoration.lineThrough),
                          ),
                        ],
                      ],
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

  Widget _buildPlaceholder(Product p) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: p.gradient ?? [AppColors.plumLight, AppColors.plum],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          p.icon,
          color: Colors.white.withValues(alpha: 0.9),
          size: 28,
        ),
      ),
    );
  }
}
