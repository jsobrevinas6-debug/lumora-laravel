import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../providers/order_provider.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cards.dart';

class CategoriesScreen extends StatefulWidget {
  final String? initialCategory;

  const CategoriesScreen({super.key, this.initialCategory});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late String _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'Latest'; // 'Latest', 'Top Sales', 'Price: Low to High', 'Price: High to Low', 'Top Rated'
  String _selectedLocation = 'All Regions';
  double? _minPrice;
  double? _maxPrice;

  String? _getTypoSuggestion(String query) {
    if (query.trim().isEmpty) return null;
    final keywords = ['Serum', 'Lipstick', 'Perfume', 'Cream', 'Noir', 'Toner', 'Blush', 'Velvet'];
    final q = query.toLowerCase();
    for (final kw in keywords) {
      final kl = kw.toLowerCase();
      if (kl == q) continue;
      if (kl.contains(q) || q.contains(kl) || (q.length >= 3 && kl.startsWith(q.substring(0, 3)))) {
        return kw;
      }
    }
    return 'Serum';
  }

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
  }

  @override
  void didUpdateWidget(CategoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory != null &&
        widget.initialCategory != _selectedCategory) {
      _selectedCategory = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _getProcessedProducts() {
    List<Product> products = [...MockData.allProducts];

    // Filter by Category
    if (_selectedCategory != 'All') {
      products = products
          .where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase())
          .toList();
    }

    // Filter by Search Query (name, category, description)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      products = products
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q))
          .toList();
    }

    // Filter by Location Region (BUY-SRCH-008)
    if (_selectedLocation != 'All Regions') {
      products = products
          .where((p) => p.sellerLocation.toLowerCase() == _selectedLocation.toLowerCase())
          .toList();
    }

    // Filter by Price Range (Buyer/ShopController min_price & max_price parity)
    if (_minPrice != null) {
      products = products.where((p) => p.price >= _minPrice!).toList();
    }
    if (_maxPrice != null) {
      products = products.where((p) => p.price <= _maxPrice!).toList();
    }

    // Sort Products (Buyer/ShopController sort parity: latest, price_asc, price_desc, top_sales)
    if (_sortBy == 'Price: Low to High') {
      products.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'Price: High to Low') {
      products.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'Top Rated') {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      products.sort((a, b) {
        final rA = orderProvider.getProductRatingSummary(a).averageRating;
        final rB = orderProvider.getProductRatingSummary(b).averageRating;
        return rB.compareTo(rA);
      });
    } else if (_sortBy == 'Top Sales' || _sortBy == 'Best Sellers') {
      products.sort((a, b) => b.soldCount.compareTo(a.soldCount));
    }

    return products;
  }

  void _showPriceFilterModal() {
    final minCtrl = TextEditingController(
      text: _minPrice != null ? _minPrice!.toStringAsFixed(0) : '',
    );
    final maxCtrl = TextEditingController(
      text: _maxPrice != null ? _maxPrice!.toStringAsFixed(0) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String? filterError;
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter by Price Range',
                        style: AppTextStyles.heading(
                          size: 18,
                          weight: FontWeight.w700,
                          color: AppColors.plum,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _minPrice = null;
                            _maxPrice = null;
                          });
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'Reset',
                          style: AppTextStyles.body(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (filterError != null) ...[
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
                              filterError!,
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minCtrl,
                          keyboardType: TextInputType.number,
                          style: AppTextStyles.body(size: 13.5),
                          onChanged: (_) {
                            if (filterError != null) setModalState(() => filterError = null);
                          },
                          decoration: InputDecoration(
                            labelText: 'Min Price (₱)',
                            hintText: '0',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.line),
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('—'),
                      ),
                      Expanded(
                        child: TextField(
                          controller: maxCtrl,
                          keyboardType: TextInputType.number,
                          style: AppTextStyles.body(size: 13.5),
                          onChanged: (_) {
                            if (filterError != null) setModalState(() => filterError = null);
                          },
                          decoration: InputDecoration(
                            labelText: 'Max Price (₱)',
                            hintText: 'Any',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.line),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.plum,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      onPressed: () {
                        final minRaw = minCtrl.text.trim();
                        final maxRaw = maxCtrl.text.trim();
                        final minVal = minRaw.isNotEmpty ? double.tryParse(minRaw) : null;
                        final maxVal = maxRaw.isNotEmpty ? double.tryParse(maxRaw) : null;

                        // Enforce non-negative and Min <= Max rules (BUY-SRCH-007)
                        if (minVal != null && minVal < 0) {
                          setModalState(() => filterError = 'Minimum price cannot be negative.');
                          return;
                        }
                        if (maxVal != null && maxVal < 0) {
                          setModalState(() => filterError = 'Maximum price cannot be negative.');
                          return;
                        }
                        if (minVal != null && maxVal != null && minVal > maxVal) {
                          setModalState(() => filterError = 'Minimum price cannot exceed Maximum price.');
                          return;
                        }

                        setState(() {
                          _minPrice = minVal;
                          _maxPrice = maxVal;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Apply Price Filter',
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...MockData.categories.map((c) => c.name)];
    final products = _getProcessedProducts();
    final double headerHeight = _searchQuery.isEmpty ? 176.0 : 142.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPersistentHeader(
                floating: true,
                pinned: false,
                delegate: _FoldingCategoryHeaderDelegate(
                  height: headerHeight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildSearchBar(),
                      if (_searchQuery.isEmpty) _buildTrendingChips(),
                      const SizedBox(height: 8),
                      _buildCategoryPills(categories),
                      const SizedBox(height: 8),
                      _buildFilterSortBar(products.length),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
              if (products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildNoResults(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.64,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return ProductCard(
                          product: products[index],
                          heroTag: 'cat_prod_${products[index].id}',
                        );
                      },
                      childCount: products.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (canPop) ...[
            GestureDetector(
              onTap: () {
                HapticService.lightImpact();
                Navigator.of(context).pop();
              },
              child: Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: AppColors.plum),
              ),
            ),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: AppColors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: AppTextStyles.body(size: 13.5),
                      decoration: const InputDecoration(
                        hintText: 'Search in catalog...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Icon(Icons.close, size: 16, color: AppColors.muted),
                    ),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildFilterSortBar(int itemCount) {
    final hasPriceFilter = _minPrice != null || _maxPrice != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$itemCount ${itemCount == 1 ? 'product' : 'products'} found',
            style: AppTextStyles.body(size: 12, color: AppColors.muted),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      _showPriceFilterModal();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: hasPriceFilter ? AppColors.plum : AppColors.cream,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: hasPriceFilter ? AppColors.plum : AppColors.line,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune,
                            size: 14,
                            color: hasPriceFilter ? Colors.white : AppColors.plum,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasPriceFilter ? 'Price Active' : 'Price',
                            style: AppTextStyles.body(
                              size: 11.5,
                              weight: FontWeight.w600,
                              color: hasPriceFilter ? Colors.white : AppColors.plum,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    initialValue: _selectedLocation,
                    onSelected: (val) => setState(() => _selectedLocation = val),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: AppColors.cream,
                    elevation: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _selectedLocation != 'All Regions' ? AppColors.plum : AppColors.cream,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _selectedLocation != 'All Regions' ? AppColors.plum : AppColors.line),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: _selectedLocation != 'All Regions' ? Colors.white : AppColors.plum),
                          const SizedBox(width: 4),
                          Text(
                            _selectedLocation != 'All Regions' ? _selectedLocation : 'Region',
                            style: AppTextStyles.body(
                              size: 11.5,
                              weight: FontWeight.w600,
                              color: _selectedLocation != 'All Regions' ? Colors.white : AppColors.plum,
                            ),
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      'All Regions',
                      'Metro Manila',
                      'Luzon',
                      'Visayas',
                      'Mindanao',
                    ].map((loc) => PopupMenuItem(value: loc, child: Text(loc, style: AppTextStyles.body(size: 13)))).toList(),
                  ),
                  PopupMenuButton<String>(
                    initialValue: _sortBy,
                    onSelected: (val) => setState(() => _sortBy = val),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: AppColors.cream,
                    elevation: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sort, size: 15, color: AppColors.plum),
                          const SizedBox(width: 6),
                          Text(
                            _sortBy,
                            style: AppTextStyles.body(
                              size: 11.5,
                              weight: FontWeight.w600,
                              color: AppColors.plum,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.muted),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      _buildPopupMenuItem('Latest'),
                      _buildPopupMenuItem('Top Sales'),
                      _buildPopupMenuItem('Price: Low to High'),
                      _buildPopupMenuItem('Price: High to Low'),
                      _buildPopupMenuItem('Top Rated'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String title) {
    final isSelected = _sortBy == title;
    return PopupMenuItem<String>(
      value: title,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.body(
              size: 13,
              weight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.orange : AppColors.ink,
            ),
          ),
          if (isSelected)
            const Icon(Icons.check, size: 16, color: AppColors.orange),
        ],
      ),
    );
  }

  Widget _buildTrendingChips() {
    final trending = ['Silk Gown', 'Cashmere', 'Amber Candle', '5G Phone', 'Sneakers', 'Blazer'];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 26,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: trending.length,
          separatorBuilder: (_, index) => const SizedBox(width: 6),
          itemBuilder: (context, idx) {
            final t = trending[idx];
            return GestureDetector(
              onTap: () {
                HapticService.selection();
                _searchController.text = t;
                setState(() => _searchQuery = t);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.plum.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, size: 12, color: AppColors.orange),
                    const SizedBox(width: 4),
                    Text(
                      t,
                      style: AppTextStyles.body(size: 11, weight: FontWeight.w600, color: AppColors.plum),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    final typoSuggestion = _getTypoSuggestion(_searchQuery);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              'No products found',
              style: AppTextStyles.heading(size: 18, color: AppColors.plum),
            ),
            const SizedBox(height: 6),
            if (_searchQuery.isNotEmpty && typoSuggestion != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Did you mean: ', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                    GestureDetector(
                      onTap: () {
                        HapticService.selection();
                        _searchController.text = typoSuggestion;
                        setState(() {
                          _searchQuery = typoSuggestion;
                        });
                      },
                      child: Text(
                        typoSuggestion,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.plum,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Text(
              'Try searching with another keyword or explore all collections',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(size: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.plum,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              onPressed: () {
                HapticService.selection();
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'All';
                  _selectedLocation = 'All Regions';
                  _minPrice = null;
                  _maxPrice = null;
                });
              },
              child: const Text('Reset All Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoldingCategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const _FoldingCategoryHeaderDelegate({
    required this.child,
    required this.height,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7F4).withValues(alpha: overlapsContent ? 0.98 : 1.0),
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: AppColors.plum.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _FoldingCategoryHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
