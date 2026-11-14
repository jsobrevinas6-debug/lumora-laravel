import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';

/// Lumora Signature Floating Capsule Navigation Bar
/// Features:
/// - True frosted glassmorphism (BackdropFilter blur)
/// - Pure floating elevation without scaffold border traces
/// - Smooth sliding champagne-silk highlight dome with moving shadow
/// - Bespoke Lumora Maison Medallion & Haute Luxury Icons
class FloatingCapsuleNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartCount;

  const FloatingCapsuleNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            // Primary soft ambient luxury shadow
            BoxShadow(
              color: AppColors.plum.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
            // Subtle secondary ground shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
            decoration: BoxDecoration(
              // Translucent luxury cream glass
              color: AppColors.cream.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.line.withValues(alpha: 0.9),
                width: 1.0,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double padding = 4.0;
                final double availableWidth = constraints.maxWidth - (padding * 2);
                final double itemWidth = availableWidth / 5;

                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Smooth Sliding Champagne-Silk Highlight Dome with Moving Shadow
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      left: padding + (itemWidth * currentIndex),
                      top: padding,
                      width: itemWidth,
                      height: constraints.maxHeight - (padding * 2),
                      child: Container(
                        decoration: BoxDecoration(
                          // Warm champagne-silk highlight
                          color: const Color(0xFFF5EBE6),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.rose.withValues(alpha: 0.18),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.plum.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 5 Bespoke Nav Items Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: padding),
                      child: Row(
                        children: [
                          _LumoraNavItem(
                            index: 0,
                            currentIndex: currentIndex,
                            label: 'Home',
                            isHome: true,
                            itemWidth: itemWidth,
                            onTap: onTap,
                          ),
                          _LumoraNavItem(
                            index: 1,
                            currentIndex: currentIndex,
                            label: 'Categories',
                            icon: Icons.grid_view_outlined,
                            activeIcon: Icons.grid_view_rounded,
                            itemWidth: itemWidth,
                            onTap: onTap,
                          ),
                          _LumoraNavItem(
                            index: 2,
                            currentIndex: currentIndex,
                            label: 'Deals',
                            icon: Icons.diamond_outlined,
                            activeIcon: Icons.diamond_rounded,
                            itemWidth: itemWidth,
                            onTap: onTap,
                          ),
                          _LumoraNavItem(
                            index: 3,
                            currentIndex: currentIndex,
                            label: 'Bag',
                            icon: Icons.shopping_bag_outlined,
                            activeIcon: Icons.shopping_bag_rounded,
                            badgeCount: cartCount,
                            badgeColor: AppColors.rose,
                            itemWidth: itemWidth,
                            onTap: onTap,
                          ),
                          _LumoraNavItem(
                            index: 4,
                            currentIndex: currentIndex,
                            label: 'Account',
                            icon: Icons.person_outline_rounded,
                            activeIcon: Icons.person_rounded,
                            itemWidth: itemWidth,
                            onTap: onTap,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
}

class _LumoraNavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final String label;
  final IconData? icon;
  final IconData? activeIcon;
  final bool isHome;
  final int badgeCount;
  final Color badgeColor;
  final double itemWidth;
  final ValueChanged<int> onTap;

  const _LumoraNavItem({
    required this.index,
    required this.currentIndex,
    required this.label,
    this.icon,
    this.activeIcon,
    this.isHome = false,
    this.badgeCount = 0,
    this.badgeColor = AppColors.rose,
    required this.itemWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = currentIndex == index;

    return SizedBox(
      width: itemWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          splashColor: AppColors.rose.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          onTap: () {
            HapticService.selection();
            onTap(index);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    if (isHome)
                      // Lumora Signature Maison Medallion
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [AppColors.plum, Color(0xFF5A2748)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : AppColors.blush1,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.gold.withValues(alpha: 0.65)
                                : AppColors.line,
                            width: 1.1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.plum.withValues(alpha: 0.28),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'L',
                            style: GoogleFonts.playfairDisplay(
                              color: isSelected ? AppColors.cream : AppColors.muted,
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                              height: 1.05,
                            ),
                          ),
                        ),
                      )
                    else
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          isSelected ? activeIcon : icon,
                          key: ValueKey(isSelected),
                          size: 22.5,
                          color: isSelected ? AppColors.plum : AppColors.muted,
                        ),
                      ),

                    // Live Cart Badge with Spring Pop Animation
                    Positioned(
                      top: -5,
                      right: -9,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                          child: child,
                        ),
                        child: badgeCount > 0
                            ? Container(
                                key: ValueKey<int>(badgeCount),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: badgeColor,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: badgeColor.withValues(alpha: 0.45),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  badgeCount > 99 ? '99+' : '$badgeCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey<int>(0)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.plum : AppColors.muted,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
