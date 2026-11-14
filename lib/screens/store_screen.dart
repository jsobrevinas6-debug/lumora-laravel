import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/follow_provider.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_modal.dart';
import '../widgets/cards.dart';
import '../widgets/luxury_snackbar.dart';
import 'chat_screen.dart';

class StoreScreen extends StatefulWidget {
  final ShopItem shop;

  const StoreScreen({super.key, required this.shop});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  String _selectedCategory = 'All';
  String _selectedSubcategory = 'All Products';

  static const Map<String, List<String>> _storeCategoryTree = {
    'All': ['All Products', 'Best Sellers', 'New Arrivals'],
    'Beauty': ['All Beauty', 'Skincare & Serums', 'Fragrance', 'Makeup & Lipsticks'],
    'Luxury': ['All Luxury', 'Timepieces & Jewelry', 'Leather Goods', 'Couture'],
    'Fashion': ['All Fashion', 'Women', 'Men', 'Active & Sports'],
    'Lifestyle': ['All Lifestyle', 'Electronics', 'Home & Living'],
  };

  List<Product> _getFilteredStoreProducts() {
    final allProducts = [...MockData.allProducts];
    // Prioritize products sold by this shop first
    allProducts.sort((a, b) {
      final aIsShop = a.sellerName.toLowerCase() == widget.shop.name.toLowerCase() ? 0 : 1;
      final bIsShop = b.sellerName.toLowerCase() == widget.shop.name.toLowerCase() ? 0 : 1;
      return aIsShop.compareTo(bIsShop);
    });

    List<Product> results = allProducts.where((p) {
      final cat = p.category.toLowerCase();
      final name = p.name.toLowerCase();
      final desc = p.description.toLowerCase();

      // Level 1 Category Filter
      if (_selectedCategory == 'Beauty') {
        if (cat != 'beauty' && !name.contains('serum') && !name.contains('parfum') && !name.contains('lip')) {
          return false;
        }
      } else if (_selectedCategory == 'Luxury') {
        if (cat != 'luxury' && p.price < 3000) {
          return false;
        }
      } else if (_selectedCategory == 'Fashion') {
        if (cat != 'women' && cat != 'men' && cat != 'sports') {
          return false;
        }
      } else if (_selectedCategory == 'Lifestyle') {
        if (cat != 'electronics' && cat != 'home & living') {
          return false;
        }
      }

      // Level 2 Subcategory Filter
      if (_selectedSubcategory == 'All Products' ||
          _selectedSubcategory.startsWith('All ') ||
          _selectedSubcategory == 'Best Sellers' ||
          _selectedSubcategory == 'New Arrivals') {
        return true;
      }

      final sub = _selectedSubcategory.toLowerCase();
      if (sub.contains('skincare')) {
        return name.contains('serum') || name.contains('cream') || name.contains('toner') || desc.contains('skin');
      }
      if (sub.contains('fragrance')) {
        return name.contains('parfum') || name.contains('scent') || name.contains('mist') || desc.contains('fragrance') || desc.contains('notes');
      }
      if (sub.contains('makeup') || sub.contains('lipstick')) {
        return name.contains('lip') || name.contains('velvet') || name.contains('blush') || desc.contains('matte');
      }
      if (sub.contains('timepieces') || sub.contains('jewelry')) {
        return name.contains('watch') || name.contains('pearl') || name.contains('gold') || desc.contains('dial') || desc.contains('pearl');
      }
      if (sub.contains('leather') || sub.contains('couture')) {
        return name.contains('tote') || name.contains('bag') || name.contains('silk') || desc.contains('leather') || desc.contains('atelier');
      }
      if (sub == 'women') return cat == 'women';
      if (sub == 'men') return cat == 'men';
      if (sub.contains('active') || sub.contains('sports')) return cat == 'sports';
      if (sub == 'electronics') return cat == 'electronics';
      if (sub == 'home & living') return cat == 'home & living';

      return name.contains(sub) || desc.contains(sub) || cat.contains(sub);
    }).toList();

    if (_selectedSubcategory == 'Best Sellers') {
      results.sort((a, b) => b.soldCount.compareTo(a.soldCount));
    } else if (_selectedSubcategory == 'New Arrivals') {
      results = results.reversed.toList();
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _getFilteredStoreProducts();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F1EC),
      body: CustomScrollView(
        slivers: [
          // App Bar with Cover Banner
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.plum,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
              ),
              onPressed: () {
                HapticService.lightImpact();
                Navigator.of(context).pop();
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    widget.shop.coverImage ?? 'assets/images/hero/hero-1.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.20),
                          const Color(0xFF351128).withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OFFICIAL MERCHANT',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.shop.name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Store Profile Card & Actions
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8D8D0)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.plum.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF8EEE9),
                          border: Border.all(color: const Color(0xFFE8D8D0), width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            widget.shop.name.isNotEmpty ? widget.shop.name.substring(0, 1).toUpperCase() : 'L',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.plum,
                            ),
                          ),
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
                                    widget.shop.name,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.plum,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.shop.isVerified) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified, size: 17, color: Color(0xFF6F8F78)),
                                ],
                                if (widget.shop.isOnVacation) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3CD),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFFFEEBA)),
                                    ),
                                    child: const Text(
                                      'On Vacation',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF856404),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.shop.category,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.shop.joinedDate,
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9C8A8F)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.shop.description,
                    style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF5C4A52), height: 1.45),
                  ),
                  const SizedBox(height: 16),

                  // Store Stats Grid (Matching Web .stats)
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.star_rounded,
                          title: '${widget.shop.rating}',
                          subtitle: 'Rating',
                          iconColor: AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.inventory_2_outlined,
                          title: '${widget.shop.productsCount}',
                          subtitle: 'Products',
                          iconColor: AppColors.rose,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: '98%',
                          subtitle: 'Response',
                          iconColor: const Color(0xFF6F8F78),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons (Follow & Chat Seller)
                  Consumer2<AuthProvider, FollowProvider>(
                    builder: (context, auth, follow, _) {
                      final isFollowing = auth.isLoggedIn && follow.isFollowing(widget.shop.id);

                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isFollowing ? const Color(0xFFE8D8D0) : AppColors.rose,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: isFollowing ? const Color(0xFFF8F4F1) : Colors.white,
                              ),
                              onPressed: () async {
                                if (!auth.isLoggedIn) {
                                  AuthModal.show(
                                    context,
                                    actionName: 'follow ${widget.shop.name}',
                                  );
                                  return;
                                }
                                HapticService.selection();
                                final nowFollowing = await follow.toggleFollow(widget.shop);
                                if (!context.mounted) return;
                                LuxurySnackBar.show(
                                  context,
                                  message: nowFollowing
                                      ? 'You are now following ${widget.shop.name}!'
                                      : 'Unfollowed ${widget.shop.name}',
                                  icon: nowFollowing
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  iconColor: AppColors.rose,
                                );
                              },
                              icon: Icon(
                                isFollowing ? Icons.check_rounded : Icons.favorite_border_rounded,
                                size: 17,
                                color: isFollowing ? AppColors.plum : AppColors.rose,
                              ),
                              label: Text(
                                isFollowing ? 'Following' : 'Follow Shop',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isFollowing ? AppColors.plum : AppColors.rose,
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                if (!auth.isLoggedIn) {
                                  AuthModal.show(
                                    context,
                                    actionName: 'chat with ${widget.shop.name}',
                                  );
                                  return;
                                }
                                HapticService.selection();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      sellerName: widget.shop.name,
                                      sellerRole: 'Merchant',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chat_outlined, size: 17),
                              label: Text(
                                'Chat Seller',
                                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Multi-level Category Tabs for Seller Store (BUY-SRCH-002)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _storeCategoryTree.keys.map((cat) {
                        final selected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: selected,
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedCategory = cat;
                                  _selectedSubcategory = _storeCategoryTree[cat]!.first;
                                });
                              }
                            },
                            selectedColor: AppColors.plum,
                            backgroundColor: Colors.white,
                            labelStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : AppColors.ink,
                            ),
                            side: BorderSide(
                              color: selected ? AppColors.plum : const Color(0xFFE8D8D0),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Level 2 Subcategory Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: (_storeCategoryTree[_selectedCategory] ?? []).map((sub) {
                        final isSubSelected = _selectedSubcategory == sub;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(sub),
                            selected: isSubSelected,
                            onSelected: (val) {
                              if (val) setState(() => _selectedSubcategory = sub);
                            },
                            selectedColor: AppColors.plum.withValues(alpha: 0.15),
                            backgroundColor: Colors.transparent,
                            labelStyle: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: isSubSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSubSelected ? AppColors.plum : AppColors.muted,
                            ),
                            side: BorderSide(
                              color: isSubSelected ? AppColors.plum : Colors.transparent,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Seller Products Grid
          if (filteredProducts.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8D8D0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.rose),
                      const SizedBox(height: 10),
                      Text(
                        'No items found in $_selectedSubcategory',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.plum,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedCategory = 'All';
                            _selectedSubcategory = 'All Products';
                          });
                        },
                        child: const Text('View All Store Products'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = filteredProducts[index % filteredProducts.length];
                    return ProductCard(
                      product: product,
                      heroTag: 'store_prod_${widget.shop.id}_${product.id}_$index',
                    );
                  },
                  childCount: filteredProducts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8D8D0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.plum,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
