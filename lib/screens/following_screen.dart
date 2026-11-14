import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/follow_provider.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/luxury_snackbar.dart';
import 'store_screen.dart';

class FollowingScreen extends StatelessWidget {
  const FollowingScreen({super.key});

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
          'Following',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.plum,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<FollowProvider>(
        builder: (context, follow, _) {
          final shops = follow.followedShops;

          if (shops.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.rose.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront_outlined, size: 38, color: AppColors.rose),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No followed shops yet',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.plum,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "Follow Shop" on any merchant page or product detail to follow your favorite sellers.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.muted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            itemCount: shops.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final shop = shops[index];
              return _buildShopCard(context, shop, follow);
            },
          );
        },
      ),
    );
  }

  Widget _buildShopCard(BuildContext context, ShopItem shop, FollowProvider follow) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D8D0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.plum.withValues(alpha: 0.04),
            blurRadius: 10,
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF8EEE9),
                  border: Border.all(color: const Color(0xFFE8D8D0)),
                ),
                child: Center(
                  child: Text(
                    shop.name.isNotEmpty ? shop.name.substring(0, 1).toUpperCase() : 'L',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
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
                            shop.name,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.plum,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (shop.isVerified) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.verified, size: 16, color: Color(0xFF6F8F78)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${shop.category} • ${shop.productsCount} Items',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0xFFF3E9E6)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE8D8D0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    HapticService.lightImpact();
                    follow.unfollow(shop.id);
                    LuxurySnackBar.show(
                      context,
                      message: 'Unfollowed ${shop.name}',
                      icon: Icons.check_circle_outline_rounded,
                    );
                  },
                  child: Text(
                    'Unfollow',
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.plum,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
                    'Visit Shop',
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
