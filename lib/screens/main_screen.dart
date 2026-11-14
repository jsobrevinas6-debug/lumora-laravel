import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_capsule_nav_bar.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'deals_screen.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String? _selectedCategoryForTab;
  late final PageController _pageController;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _switchTab(int index, {String? category}) {
    if (index < 0 || index >= 5) return;
    if (category != null) {
      _selectedCategoryForTab = category;
    } else if (index != 1) {
      _selectedCategoryForTab = null;
    }
    if (index == _currentIndex && category == null) return;

    HapticService.selection();
    setState(() {
      _currentIndex = index;
    });

    if (!_pageController.hasClients) return;

    final int currentPage = _pageController.page?.round() ?? _currentIndex;
    final int diff = (index - currentPage).abs();

    if (diff > 1) {
      // Non-adjacent tab jump: instant jump eliminates multi-screen layout thrashing and OOM crash
      _pageController.jumpToPage(index);
    } else {
      // Adjacent tab: smooth hardware-accelerated cubic slide
      _isAnimating = true;
      _pageController
          .animateToPage(
            index,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          )
          .then((_) {
        if (mounted) _isAnimating = false;
      });
    }
  }

  void _navigateToTab(int index) {
    _switchTab(index);
  }

  void _navigateToCategory(String category) {
    _switchTab(1, category: category);
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return HomeScreen(
          onNavigateToTab: _navigateToTab,
          onSelectCategory: _navigateToCategory,
        );
      case 1:
        return CategoriesScreen(
          initialCategory: _selectedCategoryForTab,
        );
      case 2:
        return DealsScreen(
          onBrowseCatalog: () => _navigateToTab(1),
        );
      case 3:
        return CartScreen(
          onBrowseProducts: () => _navigateToTab(1),
        );
      case 4:
      default:
        return const AccountScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.blush1,
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Stack(
          children: [
            // High-Performance Swipeable PageView with zero frame drops and zero re-entrancy crash
            PageView.builder(
              controller: _pageController,
              itemCount: 5,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                if (index != _currentIndex && !_isAnimating) {
                  HapticService.selection();
                  setState(() {
                    _currentIndex = index;
                  });
                }
              },
              itemBuilder: (context, index) {
                return _KeepAliveTab(
                  child: _buildScreen(index),
                );
              },
            ),

            // Isolated floating navigation island so keyboard animations never rebuild MainScreen or re-blur BackdropFilter
            _FloatingNavIsland(
              currentIndex: _currentIndex,
              cartCount: auth.isLoggedIn ? cart.totalItemsCount : 0,
              onTap: _switchTab,
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingNavIsland extends StatelessWidget {
  final int currentIndex;
  final int cartCount;
  final ValueChanged<int> onTap;

  const _FloatingNavIsland({
    required this.currentIndex,
    required this.cartCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final isKeyboardOpen = isCurrentRoute && MediaQuery.viewInsetsOf(context).bottom > 0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      left: 18,
      right: 18,
      bottom: isKeyboardOpen ? -(90 + bottomPadding) : (bottomPadding + 12),
      child: IgnorePointer(
        ignoring: isKeyboardOpen,
        child: RepaintBoundary(
          child: FloatingCapsuleNavBar(
            currentIndex: currentIndex,
            cartCount: cartCount,
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

/// Keeps tab state, scroll positions, and isolates repaint layers to prevent memory leaks and crashes
class _KeepAliveTab extends StatefulWidget {
  final Widget child;
  const _KeepAliveTab({required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RepaintBoundary(child: widget.child);
  }
}
