import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/haptic_service.dart';
import '../services/native_photo_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_modal.dart';
import '../widgets/cards.dart';
import '../widgets/luxury_snackbar.dart';
import '../widgets/share_modal.dart';
import 'chat_screen.dart';
import 'checkout_screen.dart';
import 'store_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final String? heroTag;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.heroTag,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String _selectedReviewFilter = 'All';
  final PageController _photoPageController = PageController();
  int _currentPhotoIndex = 0;
  String _selectedColor = '';
  String _selectedSecondaryOption = '';

  @override
  void initState() {
    super.initState();
    // Do not auto-select variation so user is forced to choose (BUY-PDP-001)
    _selectedColor = '';
    _selectedSecondaryOption = '';
  }

  @override
  void dispose() {
    _photoPageController.dispose();
    super.dispose();
  }

  List<String> _getGalleryImages(Product p) {
    if (p.galleryImages.isNotEmpty) {
      return p.galleryImages;
    }
    if (p.imagePath != null && p.imagePath!.isNotEmpty) {
      return [p.imagePath!];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final auth = Provider.of<AuthProvider>(context);
    final wishlist = Provider.of<WishlistProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final isFav = auth.isLoggedIn && wishlist.isFavorite(p.id);
    final userCustomReviews = orderProvider.getReviewsForProduct(p);
    final staticReviews = MockData.getReviewsForProduct(p.id)
        .where((sr) => !userCustomReviews.any((ur) => ur.id == sr.id))
        .toList();
    final reviews = [...userCustomReviews, ...staticReviews];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, p, isFav, wishlist, () {
                HapticService.lightImpact();
                LuxuryShareModal.show(context, p);
              }),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProductHero(p),
                      const SizedBox(height: 20),
                      _buildHeaderInfo(p),
                      const SizedBox(height: 16),
                      _buildPriceSection(p),
                      const SizedBox(height: 18),
                      _buildVariationSelector(p),
                      const SizedBox(height: 20),
                      _buildFeatures(p),
                      const SizedBox(height: 20),
                      _buildDescription(p),
                      const SizedBox(height: 20),
                      _buildSpecifications(p),
                      const SizedBox(height: 20),
                      _buildShippingAndGuarantees(),
                      const SizedBox(height: 20),
                      _buildSellerStoreCard(context, p),
                      const SizedBox(height: 26),
                      _buildRatingsAndReviews(p, reviews),
                      const SizedBox(height: 26),
                      _buildYouMightAlsoLike(p),
                    ],
                  ),
                ),
              ),
              _buildBottomAction(context, p, auth),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    Product p,
    bool isFav,
    WishlistProvider wishlist,
    VoidCallback onShareTap,
  ) {
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
            onPressed: () {
              HapticService.lightImpact();
              Navigator.of(context).pop();
            },
          ),
          const Spacer(),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
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
                  size: 18,
                  color: isFav ? AppColors.rose : AppColors.plum,
                ),
              ),
            ),
            onPressed: () {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              if (!auth.isLoggedIn) {
                AuthModal.show(context, actionName: 'save this item to your wishlist');
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
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(
                Icons.share_outlined,
                size: 18,
                color: AppColors.plum,
              ),
            ),
            onPressed: onShareTap,
          ),
        ],
      ),
    );
  }

  Widget _buildProductHero(Product p) {
    final images = _getGalleryImages(p);

    return Container(
      height: 310,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF7ECE7),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.plum.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Multi-Angle Swipeable Photo Gallery
          images.isNotEmpty
              ? PageView.builder(
                  controller: _photoPageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: images.length,
                  onPageChanged: (idx) => setState(() => _currentPhotoIndex = idx),
                  itemBuilder: (context, idx) {
                    final imgPath = images[idx];
                    return GestureDetector(
                      onTap: () => _openFullScreenLightbox(context, images, idx),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          (idx == 0 && widget.heroTag != null)
                              ? Hero(
                                  tag: widget.heroTag!,
                                  child: Material(
                                    type: MaterialType.transparency,
                                    child: buildLumoraImage(
                                      imgPath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => _buildFallbackHero(p),
                                    ),
                                  ),
                                )
                              : buildLumoraImage(
                                  imgPath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildFallbackHero(p),
                                ),
                          // Subtle gradient at the bottom for dot contrast
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 60,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.35),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : (widget.heroTag != null
                  ? Hero(
                      tag: widget.heroTag!,
                      child: Material(
                        type: MaterialType.transparency,
                        child: _buildFallbackHero(p),
                      ),
                    )
                  : _buildFallbackHero(p)),

          // Discount Pill Badge
          if (p.discountLabel != null)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.terracotta.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  p.discountLabel!,
                  style: AppTextStyles.body(
                    size: 10.5,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),

          // Stock Status Pill Badge
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (p.stock > 10 ? AppColors.green : AppColors.orange).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 13, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    p.stock > 10 ? 'In Stock (${p.stock})' : 'Low Stock (${p.stock} left)',
                    style: AppTextStyles.body(
                      size: 10.5,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Left: Tap / Pinch to Zoom Pill
          Positioned(
            bottom: 14,
            left: 16,
            child: GestureDetector(
              onTap: () {
                if (images.isNotEmpty) {
                  _openFullScreenLightbox(context, images, _currentPhotoIndex);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Pinch to Zoom',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Right: 100% Authentic Badge
          Positioned(
            bottom: 14,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 13, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    '100% Authentic',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Center: Active Dot Indicator Pills
          if (images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (idx) {
                  final isActive = idx == _currentPhotoIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  void _openFullScreenLightbox(BuildContext context, List<String> images, int initialIndex) {
    HapticService.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (lightboxCtx) => _LuxuryLightboxViewer(
          images: images,
          initialIndex: initialIndex,
          productName: widget.product.name,
        ),
      ),
    );
  }

  Widget _buildFallbackHero(Product p) {
    final gradientColors = p.gradient ?? [AppColors.plumLight, AppColors.plum];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          p.icon,
          size: 88,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(Product p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            if (p.brand.isNotEmpty) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    p.brand.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppColors.plum,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.verified, size: 14, color: Color(0xFF6F8F78)),
                ],
              ),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.plum.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                p.category.toUpperCase(),
                style: AppTextStyles.body(
                  size: 10.5,
                  weight: FontWeight.w700,
                  color: AppColors.plum,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          p.name,
          style: AppTextStyles.heading(
            size: 22,
            weight: FontWeight.w700,
            color: AppColors.plum,
          ),
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final ratingSummary = Provider.of<OrderProvider>(context).getProductRatingSummary(p);
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: AppColors.gold),
                      const SizedBox(width: 4),
                      Text(
                        '${ratingSummary.averageRating}',
                        style: AppTextStyles.body(
                          size: 12,
                          weight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${ratingSummary.totalReviews} reviews',
                  style: AppTextStyles.body(size: 12.5, color: AppColors.muted),
                ),
                const SizedBox(width: 8),
                const Text('•', style: TextStyle(color: AppColors.muted)),
                const SizedBox(width: 8),
                Text(
                  '${p.soldCount} sold',
                  style: AppTextStyles.body(size: 12.5, color: AppColors.muted),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriceSection(Product p) {
    final activeColor = _selectedColor.isNotEmpty ? _selectedColor : p.defaultColorName;
    final activeOption = _selectedSecondaryOption.isNotEmpty
        ? _selectedSecondaryOption
        : p.defaultSecondaryOption;
    final formattedVariantPrice = p.formattedPriceForVariant(
      color: activeColor,
      secondaryOption: activeOption,
    );
    final formattedVariantOrigPrice = p.formattedOriginalPriceForVariant(
      color: activeColor,
      secondaryOption: activeOption,
    );
    final variantStock = p.stockForVariant(
      color: activeColor,
      secondaryOption: activeOption,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Text(
            formattedVariantPrice,
            style: AppTextStyles.body(
              size: 24,
              weight: FontWeight.w800,
              color: AppColors.plum,
            ),
          ),
          if (p.originalPrice != null && formattedVariantOrigPrice.isNotEmpty) ...[
            const SizedBox(width: 10),
            Text(
              formattedVariantOrigPrice,
              style: AppTextStyles.body(
                size: 15,
                color: AppColors.muted,
              ).copyWith(decoration: TextDecoration.lineThrough),
            ),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: variantStock > 0
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: variantStock > 0
                    ? const Color(0xFFA5D6A7)
                    : const Color(0xFFEF9A9A),
              ),
            ),
            child: Text(
              variantStock > 0 ? 'Stock: $variantStock' : 'Out of Stock',
              style: AppTextStyles.body(
                size: 11,
                weight: FontWeight.w700,
                color: variantStock > 0
                    ? const Color(0xFF2E7D32)
                    : Colors.redAccent,
              ),
            ),
          ),
          if (p.discountPercentage != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.plum.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                'Save ${p.discountPercentage}%',
                style: AppTextStyles.body(
                  size: 11.5,
                  weight: FontWeight.w700,
                  color: AppColors.plum,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVariationSelector(Product p) {
    if (p.colorOptions.isEmpty && p.secondaryOptions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Primary Variation (Color / Shade / Formula / Scent / Finish)
          if (p.colorOptions.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  '${p.primaryOptionLabel}: ',
                  style: AppTextStyles.body(
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                Flexible(
                  child: Text(
                    _selectedColor.isNotEmpty
                        ? _selectedColor
                        : 'Select ${p.primaryOptionLabel.toLowerCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(
                      size: 13.5,
                      weight: FontWeight.w700,
                      color: _selectedColor.isNotEmpty ? AppColors.plum : AppColors.rose,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: p.colorOptions.map((co) {
                final isSelected = co.name.toLowerCase() == _selectedColor.toLowerCase();
                return GestureDetector(
                  onTap: () {
                    HapticService.selection();
                    setState(() {
                      _selectedColor = co.name;
                      if (_selectedSecondaryOption.isNotEmpty &&
                          p.isVariantOutOfStock(
                            color: co.name,
                            secondaryOption: _selectedSecondaryOption,
                          )) {
                        _selectedSecondaryOption = '';
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.plum.withValues(alpha: 0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: isSelected ? AppColors.plum : AppColors.line,
                        width: isSelected ? 1.8 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.plum.withValues(alpha: 0.14),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: co.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.12),
                              width: 1,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 11,
                                  color: co.color.computeLuminance() > 0.5
                                      ? Colors.black87
                                      : Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            co.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body(
                              size: 12,
                              weight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? AppColors.plum : AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          if (p.colorOptions.isNotEmpty && p.secondaryOptions.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.line, height: 1),
            ),

          // 2. Secondary Options (Size / Storage / Volume / Edition)
          if (p.secondaryOptions.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: '${p.secondaryOptionLabel}: ',
                      style: AppTextStyles.body(
                        size: 13,
                        weight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                      children: [
                        TextSpan(
                          text: _selectedSecondaryOption.isNotEmpty ? _selectedSecondaryOption : 'Select option',
                          style: AppTextStyles.body(
                            size: 13.5,
                            weight: FontWeight.w700,
                            color: _selectedSecondaryOption.isNotEmpty ? AppColors.plum : AppColors.rose,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (p.hasSizeGuide) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      _showSizeGuideModal(context, p);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.straighten, size: 14, color: AppColors.rose),
                        const SizedBox(width: 4),
                        Text(
                          'Size Guide',
                          style: AppTextStyles.body(
                            size: 12,
                            weight: FontWeight.w700,
                            color: AppColors.rose,
                          ).copyWith(decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: p.secondaryOptions.map((opt) {
                final activeColor = _selectedColor.isNotEmpty
                    ? _selectedColor
                    : p.defaultColorName;
                final isOutOfStock = p.isVariantOutOfStock(
                  color: activeColor,
                  secondaryOption: opt,
                );
                final isSelected = !isOutOfStock && opt == _selectedSecondaryOption;
                return GestureDetector(
                  onTap: isOutOfStock
                      ? null
                      : () {
                          HapticService.selection();
                          setState(() => _selectedSecondaryOption = opt);
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? const Color(0xFFF3EFEA)
                          : (isSelected ? AppColors.plum : Colors.white),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isOutOfStock
                            ? AppColors.line
                            : (isSelected ? AppColors.plum : AppColors.line),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.plum.withValues(alpha: 0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      isOutOfStock ? '$opt (Out of Stock)' : opt,
                      style: AppTextStyles.body(
                        size: 12,
                        weight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isOutOfStock
                            ? AppColors.muted.withValues(alpha: 0.65)
                            : (isSelected ? Colors.white : AppColors.ink),
                      ).copyWith(
                        decoration: isOutOfStock ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showSizeGuideModal(BuildContext context, Product p) {
    final isFootwear = p.category.toLowerCase().contains('footwear') ||
        p.name.toLowerCase().contains('shoe') ||
        p.name.toLowerCase().contains('loafer') ||
        p.name.toLowerCase().contains('sneaker');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          const Icon(Icons.straighten, size: 20, color: AppColors.rose),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              isFootwear ? 'Shoe Size Guide' : 'Apparel & Fit Guide',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.heading(
                                size: 18,
                                weight: FontWeight.w700,
                                color: AppColors.plum,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.muted),
                      onPressed: () => Navigator.of(modalCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Measurements are provided in standard fashion sizing. If between sizes, we recommend sizing up for a relaxed fit.',
                  style: AppTextStyles.body(size: 12, color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Table(
                    border: TableBorder.symmetric(
                      inside: const BorderSide(color: AppColors.line, width: 0.8),
                    ),
                    children: isFootwear
                        ? [
                            _buildTableRow(['EU Size', 'US Men', 'UK', 'Foot Length'], isHeader: true),
                            _buildTableRow(['EU 40', '7.0', '6.5', '25.0 cm']),
                            _buildTableRow(['EU 41', '8.0', '7.5', '25.7 cm']),
                            _buildTableRow(['EU 42', '8.5', '8.0', '26.4 cm']),
                            _buildTableRow(['EU 43', '9.5', '9.0', '27.0 cm']),
                            _buildTableRow(['EU 44', '10.5', '10.0', '27.7 cm']),
                            _buildTableRow(['EU 45', '11.5', '11.0', '28.4 cm']),
                          ]
                        : [
                            _buildTableRow(['Size', 'Chest / Bust', 'Waist', 'Hips'], isHeader: true),
                            _buildTableRow(['XS', '32-34"', '26-28"', '34-36"']),
                            _buildTableRow(['S', '35-37"', '29-31"', '37-39"']),
                            _buildTableRow(['M', '38-40"', '32-34"', '40-42"']),
                            _buildTableRow(['L', '41-43"', '35-37"', '43-45"']),
                            _buildTableRow(['XL', '44-46"', '38-40"', '46-48"']),
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
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: () => Navigator.of(modalCtx).pop(),
                    child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  TableRow _buildTableRow(List<String> cells, {bool isHeader = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? AppColors.blush1 : Colors.white,
      ),
      children: cells.map((cell) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            cell,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isHeader ? 11.5 : 12,
              fontWeight: isHeader ? FontWeight.w800 : FontWeight.w500,
              color: isHeader ? AppColors.plum : AppColors.ink,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeatures(Product p) {
    if (p.features.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Highlights',
          style: AppTextStyles.body(
            size: 14.5,
            weight: FontWeight.w700,
            color: AppColors.plum,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: p.features.map((feat) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 14, color: AppColors.rose),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      feat,
                      style: AppTextStyles.body(size: 12, weight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescription(Product p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Details & Description',
          style: AppTextStyles.body(
            size: 14.5,
            weight: FontWeight.w700,
            color: AppColors.plum,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Text(
            p.description,
            style: AppTextStyles.body(
              size: 13,
              height: 1.6,
              color: AppColors.ink.withValues(alpha: 0.88),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecifications(Product p) {
    final specs = [
      {'label': 'Brand', 'value': p.brand.isNotEmpty ? p.brand : 'Lumora Atelier'},
      {'label': 'SKU', 'value': p.sku.isNotEmpty ? p.sku : 'LMR-${p.id.toUpperCase()}-01'},
      {'label': 'Category', 'value': p.category},
      if (p.materialCare.isNotEmpty) {'label': 'Material & Care', 'value': p.materialCare},
      {'label': 'Origin', 'value': 'Imported & Certified Authentic'},
      {'label': 'Warranty', 'value': '1-Year Official Lumora Warranty'},
      {'label': 'Condition', 'value': '100% Brand New, Sealed Boutique Packaging'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.tune_rounded, size: 18, color: AppColors.rose),
              const SizedBox(width: 8),
              Text(
                'Specifications & Authenticity',
                style: AppTextStyles.body(
                  size: 13.5,
                  weight: FontWeight.w700,
                  color: AppColors.plum,
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.line, height: 20),
          ...specs.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 105,
                    child: Text(
                      item['label']!,
                      style: AppTextStyles.body(
                        size: 12,
                        color: AppColors.muted,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item['value']!,
                      style: AppTextStyles.body(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: AppColors.plum,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildShippingAndGuarantees() {
    final now = DateTime.now();
    final startDelivery = now.add(const Duration(days: 2));
    final endDelivery = now.add(const Duration(days: 4));
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final startStr = '${months[startDelivery.month - 1]} ${startDelivery.day}';
    final endStr = '${months[endDelivery.month - 1]} ${endDelivery.day}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.rose.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_shipping_outlined, size: 18, color: AppColors.rose),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: 'Estimated Delivery: ',
                        style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700),
                        children: [
                          TextSpan(
                            text: '$startStr – $endStr',
                            style: AppTextStyles.body(
                              size: 12.5,
                              weight: FontWeight.w800,
                              color: AppColors.plum,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Express delivery nationwide. Free shipping on orders over ₱1,000.',
                      style: AppTextStyles.body(size: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.line, height: 1),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payments_outlined, size: 18, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cash on Delivery (COD) Available',
                      style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700),
                    ),
                    Text(
                      'Pay securely at your doorstep upon parcel inspection',
                      style: AppTextStyles.body(size: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.line, height: 1),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, size: 18, color: AppColors.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '15-Day Free Returns & 100% Authentic',
                      style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700),
                    ),
                    Text(
                      'Guaranteed genuine boutique goods with hassle-free returns',
                      style: AppTextStyles.body(size: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSellerStoreCard(BuildContext context, Product p) {
    final sellerName = p.sellerName.trim().isNotEmpty ? p.sellerName : 'Aura Luxury Manila';
    final shop = ShopItem(
      id: 'seller_${sellerName.toLowerCase().replaceAll(' ', '_')}',
      name: sellerName,
      avatar: 'assets/images/hero.jpg',
      isVerified: true,
      rating: 4.95,
      responseRate: '98% within 1 hr',
      productsCount: 24,
      joinedDate: 'Joined May 2024',
      category: 'Official Flagship Store',
      description: 'Curated high-grade formulations and authentic luxury aesthetics crafted for glowing skin.',
    );

    return Container(
      padding: const EdgeInsets.all(16),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF8EEE9),
                  border: Border.all(color: AppColors.line),
                ),
                child: Center(
                  child: Text(
                    sellerName.substring(0, 1).toUpperCase(),
                    style: AppTextStyles.heading(
                      size: 20,
                      weight: FontWeight.w700,
                      color: AppColors.plum,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            shop.name,
                            style: AppTextStyles.body(
                              size: 14,
                              weight: FontWeight.w700,
                              color: AppColors.plum,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(Icons.verified, size: 15, color: Color(0xFF6F8F78)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${shop.category} • 98% Response Rate',
                      style: AppTextStyles.body(size: 11, color: AppColors.muted),
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
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.line),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () {
                    HapticService.selection();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StoreScreen(shop: shop),
                      ),
                    );
                  },
                  child: Text(
                    'Visit Store',
                    style: AppTextStyles.body(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppColors.plum,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.plum,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                  onPressed: () {
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    if (!auth.isLoggedIn) {
                      AuthModal.show(context, actionName: 'chat directly with the verified seller');
                      return;
                    }
                    HapticService.selection();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          sellerName: shop.name,
                          sellerRole: 'Merchant Specialist',
                          productContext: p,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                  label: Text(
                    'Chat Seller',
                    style: AppTextStyles.body(
                      size: 12,
                      weight: FontWeight.w700,
                      color: Colors.white,
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

  Widget _buildRatingsAndReviews(Product p, List<ProductReview> reviews) {
    final auth = Provider.of<AuthProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final userId = auth.currentUser?.id ?? 'buyer-1';
    final canReview = auth.isLoggedIn && orderProvider.hasDeliveredOrderForProduct(p.id, p.name);
    final existingUserReview = orderProvider.getUserReviewForProduct(p.id, userId);

    final ratingSummary = orderProvider.getProductRatingSummary(p);

    final filteredReviews = reviews.where((r) {
      if (_selectedReviewFilter == '5 Stars') return r.rating >= 4.9;
      if (_selectedReviewFilter == 'With Photos') return r.images.isNotEmpty;
      if (_selectedReviewFilter == 'Verified Buyers') return r.isVerified;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Ratings & Reviews',
                style: AppTextStyles.heading(
                  size: 18,
                  weight: FontWeight.w700,
                  color: AppColors.plum,
                ),
              ),
            ),
            Text(
              '${ratingSummary.totalReviews} verified reviews',
              style: AppTextStyles.body(size: 12, color: AppColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Rating Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${ratingSummary.averageRating}',
                          style: AppTextStyles.heading(
                            size: 28,
                            weight: FontWeight.w800,
                            color: AppColors.plum,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '/ 5.0',
                          style: AppTextStyles.body(size: 13, color: AppColors.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        return const Icon(Icons.star_rounded, size: 16, color: AppColors.gold);
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '98% recommended',
                      style: AppTextStyles.body(size: 10, color: AppColors.green, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _buildRatingBar('5★', 0.88),
                    _buildRatingBar('4★', 0.08),
                    _buildRatingBar('3★', 0.03),
                    _buildRatingBar('2★', 0.01),
                    _buildRatingBar('1★', 0.00),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Verified Buyer Review Eligibility Banner / Action (`Buyer/ProductReviewController.php` Parity)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: canReview ? const Color(0xFFF1F8E9) : AppColors.blush1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: canReview ? const Color(0xFFA5D6A7) : AppColors.line,
            ),
          ),
          child: Row(
            children: [
              Icon(
                canReview ? Icons.verified_outlined : Icons.info_outline_rounded,
                size: 18,
                color: canReview ? const Color(0xFF2E7D32) : AppColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  canReview
                      ? (existingUserReview != null
                          ? 'You have already reviewed this delivered item. You can edit or delete your review.'
                          : 'Verified Buyer: You received this product! Share your review below.')
                      : 'Only buyers who have received this product can leave a review.',
                  style: AppTextStyles.body(
                    size: 11.5,
                    weight: canReview ? FontWeight.w600 : FontWeight.w500,
                    color: canReview ? const Color(0xFF2E7D32) : AppColors.muted,
                    height: 1.35,
                  ),
                ),
              ),
              if (canReview) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.plum,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  ),
                  onPressed: () => _showWriteOrEditReviewDialog(
                    context,
                    p,
                    existing: existingUserReview,
                  ),
                  child: Text(
                    existingUserReview != null ? 'Edit Review' : 'Write Review',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: ['All', '5 Stars', 'With Photos', 'Verified Buyers'].map((filter) {
              final isSelected = _selectedReviewFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticService.selection();
                    setState(() => _selectedReviewFilter = filter);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.plum : AppColors.cream,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: isSelected ? AppColors.plum : AppColors.line),
                    ),
                    child: Text(
                      filter,
                      style: AppTextStyles.body(
                        size: 11.5,
                        weight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.plum,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Review List Items (Dynamically Filtered)
        if (filteredReviews.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No customer reviews match "$_selectedReviewFilter"',
                style: AppTextStyles.body(size: 12.5, color: AppColors.muted),
              ),
            ),
          )
        else
          ...filteredReviews.map((rev) => _buildReviewCard(rev, p)),
      ],
    );
  }

  void _showWriteOrEditReviewDialog(
    BuildContext context,
    Product product, {
    ProductReview? existing,
  }) {
    int rating = existing != null ? existing.rating.round().clamp(1, 5) : 5;
    final cleanInitialComment = (existing?.comment ?? '').replaceAll(' • [Edited]', '');
    final commentController = TextEditingController(text: cleanInitialComment);
    final List<String> reviewPhotos = List<String>.from(existing?.images ?? const []);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final userId = auth.currentUser?.id ?? 'buyer-1';

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.cream,
          title: Text(
            existing != null ? 'Edit Your Verified Review' : 'Write a Verified Review',
            style: AppTextStyles.heading(size: 18, weight: FontWeight.w700, color: AppColors.plum),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: AppTextStyles.body(size: 13, weight: FontWeight.w600)),
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
                    hintText: 'Share your authentic experience with this product (optional, max 500 chars)...',
                    hintStyle: AppTextStyles.body(size: 12, color: AppColors.muted),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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
                              image: DecorationImage(image: _buildReviewImageProvider(img), fit: BoxFit.cover),
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
            if (existing != null)
              TextButton(
                onPressed: () async {
                  final res = await orderProvider.deleteReview(
                    productId: product.id,
                    reviewId: existing.id,
                    userId: userId,
                  );
                  if (!dlgCtx.mounted) return;
                  Navigator.of(dlgCtx).pop();
                  if (!context.mounted) return;
                  LuxurySnackBar.show(
                    context,
                    message: res.message,
                    icon: Icons.delete_outline,
                  );
                },
                child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
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
                final res = await orderProvider.submitOrUpdateReview(
                  product: product,
                  userId: userId,
                  userName: auth.currentUser?.fullName ?? 'Verified Buyer',
                  rating: rating,
                  comment: commentController.text,
                  images: reviewPhotos,
                );
                if (!dlgCtx.mounted) return;
                Navigator.of(dlgCtx).pop();
                HapticService.selection();
                if (!context.mounted) return;
                LuxurySnackBar.show(
                  context,
                  message: res.message,
                  icon: res.ok ? Icons.star_rounded : Icons.error_outline,
                  iconColor: res.ok ? AppColors.gold : Colors.redAccent,
                );
              },
              child: Text(existing != null ? 'Update Review' : 'Submit Review'),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _buildReviewImageProvider(String path) {
    if (path.startsWith('data:image/')) {
      final base64Str = path.split(',').last;
      return MemoryImage(base64Decode(base64Str));
    }
    return AssetImage(path);
  }

  Widget _buildRatingBar(String label, double fillFactor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              label,
              style: AppTextStyles.body(size: 9.5, color: AppColors.muted),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: fillFactor,
                minHeight: 4.5,
                backgroundColor: AppColors.line,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ProductReview rev, Product p) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.id ?? 'buyer-1';
    final isOwnReview = auth.isLoggedIn && rev.userId != null && rev.userId == userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOwnReview ? AppColors.plum.withValues(alpha: 0.4) : AppColors.line),
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.rose, AppColors.plum],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    rev.author.isNotEmpty ? rev.author[0].toUpperCase() : 'B',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            rev.author,
                            style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (rev.isVerified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, size: 10, color: AppColors.green),
                                SizedBox(width: 2),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    color: AppColors.green,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      rev.date,
                      style: AppTextStyles.body(size: 10.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rev.rating.floor() ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 14,
                    color: AppColors.gold,
                  );
                }),
              ),
            ],
          ),
          if (rev.variant != null) ...[
            const SizedBox(height: 8),
            Text(
              'Variation: ${rev.variant}',
              style: AppTextStyles.body(size: 11, color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            rev.comment,
            style: AppTextStyles.body(
              size: 12.5,
              height: 1.5,
              color: AppColors.ink.withValues(alpha: 0.88),
            ),
          ),
          if (rev.images.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: rev.images.map((img) {
                  return Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.line),
                      image: DecorationImage(
                        image: _buildReviewImageProvider(img),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          if (isOwnReview) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 14, color: AppColors.plum),
                  label: const Text('Edit', style: TextStyle(fontSize: 11.5, color: AppColors.plum, fontWeight: FontWeight.w600)),
                  onPressed: () => _showWriteOrEditReviewDialog(context, p, existing: rev),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                  label: const Text('Delete', style: TextStyle(fontSize: 11.5, color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  onPressed: () async {
                    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                    final res = await orderProvider.deleteReview(
                      productId: p.id,
                      reviewId: rev.id,
                      userId: userId,
                    );
                    if (!mounted) return;
                    LuxurySnackBar.show(context, message: res.message, icon: Icons.delete_outline);
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYouMightAlsoLike(Product p) {
    final related = MockData.allProducts
        .where((item) => item.id != p.id)
        .take(6)
        .toList();

    if (related.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You Might Also Like',
              style: AppTextStyles.heading(
                size: 18,
                weight: FontWeight.w700,
                color: AppColors.plum,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Curated recommendations based on this item',
              style: AppTextStyles.body(size: 11.5, color: AppColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 255,
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemCount: related.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              return ProductCard(product: related[idx]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(
    BuildContext context,
    Product p,
    AuthProvider auth,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
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
          GestureDetector(
            onTap: () {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              if (!auth.isLoggedIn) {
                AuthModal.show(context, actionName: 'chat directly with the verified seller');
                return;
              }
              HapticService.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    sellerName: p.sellerName.trim().isNotEmpty ? p.sellerName : 'Aura Luxury Manila',
                    sellerRole: 'Merchant Specialist',
                    productContext: p,
                  ),
                ),
              );
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.blush1,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 20,
                color: AppColors.plum,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cream,
                foregroundColor: AppColors.plum,
                side: const BorderSide(color: AppColors.plum, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              onPressed: () {
                HapticService.lightImpact();
                _showPurchaseModal(context, p, auth, isDirectCheckout: false);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Add to Cart',
                    style: AppTextStyles.body(
                      size: 13.5,
                      weight: FontWeight.w700,
                      color: AppColors.plum,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.plum,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              onPressed: () {
                HapticService.mediumImpact();
                _showPurchaseModal(context, p, auth, isDirectCheckout: true);
              },
              child: Text(
                'Buy Now',
                style: AppTextStyles.body(
                  size: 13.5,
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

  // Interactive Purchase Modal with Quantity & Variation Selector (Prompted when buying/adding)
  void _showPurchaseModal(
    BuildContext context,
    Product p,
    AuthProvider auth, {
    required bool isDirectCheckout,
  }) {
    int modalQuantity = 1;
    String? modalSelectedColor = _selectedColor.isNotEmpty ? _selectedColor : null;
    String? modalSelectedOption = _selectedSecondaryOption.isNotEmpty ? _selectedSecondaryOption : null;
    String? validationError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final variantUnitPrice = p.priceForVariant(
              color: modalSelectedColor,
              secondaryOption: modalSelectedOption,
            );
            final variantFormattedPrice = p.formattedPriceForVariant(
              color: modalSelectedColor,
              secondaryOption: modalSelectedOption,
            );
            final variantStock = p.stockForVariant(
              color: modalSelectedColor,
              secondaryOption: modalSelectedOption,
            );
            final subtotal = variantUnitPrice * modalQuantity;
            final rawInt = subtotal.toInt().toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (Match m) => '${m[1]},',
                );
            final formattedSubtotal = subtotal % 1 == 0
                ? '₱$rawInt'
                : '₱$rawInt.${(subtotal % 1).toStringAsFixed(2).substring(2)}';

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.82,
              ),
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
              decoration: const BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.line,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Product Preview Header
                    Row(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: AppColors.blush1,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: p.imagePath != null
                              ? buildLumoraImage(p.imagePath!, fit: BoxFit.cover, cacheWidth: 200)
                              : Icon(p.icon, color: AppColors.plum, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (p.brand.isNotEmpty)
                                Text(
                                  p.brand.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: AppColors.muted,
                                  ),
                                ),
                              Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body(
                                  size: 14,
                                  weight: FontWeight.w700,
                                  color: AppColors.plum,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                variantFormattedPrice,
                                style: AppTextStyles.price(
                                  size: 16,
                                  weight: FontWeight.w800,
                                  color: AppColors.rose,
                                ),
                              ),
                              Text(
                                'Selected: ${(modalSelectedColor ?? 'None chosen')} • ${(modalSelectedOption ?? 'None chosen')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: (modalSelectedColor != null && modalSelectedOption != null) ? AppColors.plum : AppColors.rose,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: AppColors.muted),
                          onPressed: () => Navigator.of(modalCtx).pop(),
                        ),
                      ],
                    ),
                    if (validationError != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE8E8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF8B4B4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Color(0xFF9B1C1C)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                validationError!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF9B1C1C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Divider(color: AppColors.line, height: 24),

                    // Modal Primary Variation Selection
                    if (p.colorOptions.isNotEmpty) ...[
                      Row(
                        children: [
                          Text(
                            '${p.primaryOptionLabel}: ',
                            style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600, color: AppColors.muted),
                          ),
                          Flexible(
                            child: Text(
                              modalSelectedColor ?? 'Please select ${p.primaryOptionLabel.toLowerCase()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body(
                                size: 13,
                                weight: FontWeight.w700,
                                color: modalSelectedColor != null ? AppColors.plum : AppColors.rose,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: p.colorOptions.map((co) {
                          final isSelected = modalSelectedColor != null && co.name.toLowerCase() == modalSelectedColor!.toLowerCase();
                          return GestureDetector(
                            onTap: () {
                              HapticService.selection();
                              setModalState(() {
                                modalSelectedColor = co.name;
                                if (modalSelectedOption != null &&
                                    p.isVariantOutOfStock(
                                      color: co.name,
                                      secondaryOption: modalSelectedOption,
                                    )) {
                                  modalSelectedOption = null;
                                }
                                validationError = null;
                              });
                              setState(() {
                                _selectedColor = co.name;
                                if (_selectedSecondaryOption.isNotEmpty &&
                                    p.isVariantOutOfStock(
                                      color: co.name,
                                      secondaryOption: _selectedSecondaryOption,
                                    )) {
                                  _selectedSecondaryOption = '';
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.plum.withValues(alpha: 0.08)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: isSelected ? AppColors.plum : AppColors.line,
                                  width: isSelected ? 1.8 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: co.color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black.withValues(alpha: 0.12),
                                        width: 1,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Icon(
                                            Icons.check,
                                            size: 10,
                                            color: co.color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      co.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                        color: isSelected ? AppColors.plum : AppColors.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Modal Secondary Option Selection (Size / Storage / Volume)
                    if (p.secondaryOptions.isNotEmpty) ...[
                      Row(
                        children: [
                          Text(
                            '${p.secondaryOptionLabel}: ',
                            style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600, color: AppColors.muted),
                          ),
                          Flexible(
                            child: Text(
                              modalSelectedOption ?? 'Please select option',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body(
                                size: 13,
                                weight: FontWeight.w700,
                                color: modalSelectedOption != null ? AppColors.plum : AppColors.rose,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: p.secondaryOptions.map((opt) {
                          final activeModalColor = modalSelectedColor ?? p.defaultColorName;
                          final isOutOfStock = p.isVariantOutOfStock(
                            color: activeModalColor,
                            secondaryOption: opt,
                          );
                          final isSelected = !isOutOfStock && opt == modalSelectedOption;
                          return GestureDetector(
                            onTap: isOutOfStock
                                ? null
                                : () {
                                    HapticService.selection();
                                    setModalState(() {
                                      modalSelectedOption = opt;
                                      final newStock = p.stockForVariant(
                                        color: activeModalColor,
                                        secondaryOption: opt,
                                      );
                                      if (newStock > 0 && modalQuantity > newStock) {
                                        modalQuantity = newStock;
                                      }
                                      validationError = null;
                                    });
                                    setState(() => _selectedSecondaryOption = opt);
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isOutOfStock
                                    ? const Color(0xFFF3EFEA)
                                    : (isSelected ? AppColors.plum : Colors.white),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isOutOfStock
                                      ? AppColors.line
                                      : (isSelected ? AppColors.plum : AppColors.line),
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                isOutOfStock ? '$opt (Out of Stock)' : opt,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isOutOfStock
                                      ? AppColors.muted.withValues(alpha: 0.65)
                                      : (isSelected ? Colors.white : AppColors.ink),
                                  decoration: isOutOfStock ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Interactive Quantity Counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quantity',
                              style: AppTextStyles.body(
                                size: 14,
                                weight: FontWeight.w700,
                                color: AppColors.plum,
                              ),
                            ),
                            Text(
                              variantStock > 0
                                  ? 'Stock: $variantStock available'
                                  : 'Out of Stock',
                              style: AppTextStyles.body(
                                size: 11,
                                color: variantStock > 10
                                    ? AppColors.green
                                    : (variantStock > 0 ? AppColors.orange : Colors.redAccent),
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 16, color: AppColors.plum),
                                onPressed: modalQuantity > 1
                                    ? () {
                                        HapticService.selection();
                                        setModalState(() => modalQuantity--);
                                      }
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  '$modalQuantity',
                                  style: AppTextStyles.body(
                                    size: 15,
                                    weight: FontWeight.w700,
                                    color: AppColors.plum,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16, color: AppColors.plum),
                                onPressed: modalQuantity < variantStock
                                    ? () {
                                        HapticService.selection();
                                        setModalState(() => modalQuantity++);
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Subtotal Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount:',
                          style: AppTextStyles.body(
                            size: 14,
                            weight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                        Text(
                          formattedSubtotal,
                          style: AppTextStyles.price(
                            size: 20,
                            weight: FontWeight.w800,
                            color: AppColors.plum,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.plum,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(99),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        onPressed: () {
                          // Enforce variation selection (BUY-PDP-001)
                          if (p.colorOptions.isNotEmpty && modalSelectedColor == null) {
                            HapticService.selection();
                            setModalState(() => validationError = 'Please choose a ${p.primaryOptionLabel.toLowerCase()} variation before proceeding.');
                            return;
                          }
                          if (p.secondaryOptions.isNotEmpty && modalSelectedOption == null) {
                            HapticService.selection();
                            setModalState(() => validationError = 'Please choose a ${p.secondaryOptionLabel} before proceeding.');
                            return;
                          }
                          if (variantStock <= 0) {
                            setModalState(() => validationError = 'This selected variation is currently out of stock.');
                            return;
                          }

                          HapticService.mediumImpact();
                          Navigator.of(modalCtx).pop();

                          final chosenColor = modalSelectedColor ?? p.defaultColorName;
                          final chosenOption = modalSelectedOption ?? p.defaultSecondaryOption;

                          if (!auth.isLoggedIn) {
                            AuthModal.show(
                              context,
                              actionName: isDirectCheckout
                                  ? 'purchase items instantly'
                                  : 'add items to your shopping cart',
                            );
                          } else {
                            if (isDirectCheckout) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CheckoutScreen(
                                    buyNowItem: CartItem(
                                      product: p,
                                      quantity: modalQuantity,
                                      selectedColor: chosenColor,
                                      selectedSizeOrOption: chosenOption,
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              final cart = Provider.of<CartProvider>(context, listen: false);
                              final added = cart.addToCart(
                                p,
                                quantity: modalQuantity,
                                selectedColor: chosenColor,
                                selectedSizeOrOption: chosenOption,
                              );
                              if (added) {
                                LuxurySnackBar.show(
                                  context,
                                  message: 'Added $modalQuantity "${p.name}" ($chosenColor • $chosenOption) to cart!',
                                  icon: Icons.shopping_bag_outlined,
                                );
                              } else {
                                LuxurySnackBar.show(
                                  context,
                                  message: 'Cannot exceed available stock (${p.stock} left).',
                                  icon: Icons.error_outline,
                                  iconColor: Colors.redAccent,
                                );
                              }
                            }
                          }
                        },
                        child: Text(
                          isDirectCheckout
                              ? 'Proceed to Checkout • $formattedSubtotal'
                              : 'Add to Cart • $formattedSubtotal',
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
              ),
            );
          },
        );
      },
    );
  }
}

class _LuxuryLightboxViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String productName;

  const _LuxuryLightboxViewer({
    required this.images,
    required this.initialIndex,
    required this.productName,
  });

  @override
  State<_LuxuryLightboxViewer> createState() => _LuxuryLightboxViewerState();
}

class _LuxuryLightboxViewerState extends State<_LuxuryLightboxViewer> {
  late final PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Swipeable Interactive Zoomable Photos
            PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.images.length,
              onPageChanged: (idx) {
                _resetZoom();
                setState(() => _currentIndex = idx);
              },
              itemBuilder: (context, idx) {
                final imgPath = widget.images[idx];
                return GestureDetector(
                  onDoubleTap: () {
                    HapticService.selection();
                    if (_transformController.value.getMaxScaleOnAxis() > 1.5) {
                      _resetZoom();
                    } else {
                      _transformController.value = Matrix4.diagonal3Values(2.5, 2.5, 1.0);
                    }
                  },
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 1.0,
                    maxScale: 4.5,
                    clipBehavior: Clip.none,
                    child: Center(
                      child: buildLumoraImage(
                        imgPath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white54,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Top Luxury Control Bar
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.refresh, color: Colors.white, size: 20),
                    ),
                    onPressed: _resetZoom,
                  ),
                ],
              ),
            ),

            // Bottom Product Caption and Hint
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pinch, size: 14, color: Colors.white70),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Pinch or double-tap anywhere to inspect fine luxury detail',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

