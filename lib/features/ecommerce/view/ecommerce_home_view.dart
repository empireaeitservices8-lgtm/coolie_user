import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/ecommerce/view_model/ecommerce_view_model.dart';
import 'package:cooli/features/ecommerce/view/product_detail_view.dart';
import 'package:cooli/features/ecommerce/view/cart_view.dart';
import 'package:cooli/features/profile/view/profile_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cooli/features/ecommerce/model/product_model.dart';

class EcommerceHomeView extends StatefulWidget {
  static const String routeName = '/ecommerce';

  const EcommerceHomeView({super.key});

  @override
  State<EcommerceHomeView> createState() => _EcommerceHomeViewState();
}

class _EcommerceHomeViewState extends State<EcommerceHomeView> {
  late EcommerceViewModel _viewModel;
  int _selectedBottomNav = 0;
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel = context.read<EcommerceViewModel>();
    if (!_didInit) {
      _didInit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _viewModel.loadCategories();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Color(0xFF111827), size: 24),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'E-Commerce',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Consumer<EcommerceViewModel>(
            builder: (context, vm, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined,
                        color: Color(0xFF111827), size: 22),
                    onPressed: () {
                      Navigator.pushNamed(context, CartView.routeName);
                    },
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Center(
                        child: Text(
                          '${vm.cartItems.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<EcommerceViewModel>(
        builder: (context, vm, child) {
          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                vm.loadCategories(),
                vm.filterCategory(vm.selectedCategory,
                    categoryId: vm.selectedCategoryId),
              ]);
            },
            color: const Color(0xFF2563EB),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded,
                          color: Color(0xFF9CA3AF), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => vm.searchProducts(val),
                          decoration: const InputDecoration(
                            hintText: 'Search sand, bricks, cement...',
                            hintStyle: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            filled: false,
                            fillColor: Colors.transparent,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Hero Banner: "Quality Sand & Bricks for Your Construction"
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/images/ecom_hero_clean.png',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Categories Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (vm.liveCategories.isNotEmpty)
                      Text(
                        '${vm.liveCategories.length} categories',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Category Filter Pills from Live API (Avoiding "All" category)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: vm.liveCategories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final category = entry.value;
                      final isSelected = vm.selectedCategoryId != null
                          ? vm.selectedCategoryId == category.id
                          : vm.selectedCategory.toLowerCase() ==
                              category.name.toLowerCase();
                      final style = _getCategoryStyle(category.name);
                      return Padding(
                        padding: EdgeInsets.only(left: index == 0 ? 0 : 8.0),
                        child: _buildCategoryItem(
                          name: category.name,
                          assetPath: style.assetPath,
                          fallbackIcon: style.icon,
                          bgColor: style.bgColor,
                          borderColor: style.borderColor,
                          textColor: style.textColor,
                          isSelected: isSelected,
                          onTap: () => vm.filterCategory(category.name,
                              categoryId: category.id),
                          imageUrl: category.fullImageUrl,
                          iconUrl: category.fullIconUrl,
                          iconName: category.icon,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 22),

                // Popular Products Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      vm.selectedCategory.isNotEmpty
                          ? '${vm.selectedCategory} Products'
                          : 'Popular Products',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${vm.products.length} items',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 2-Column Product Grid, Skeleton Loading or Empty State
                if (vm.isLoadingProducts)
                  _buildProductGridSkeleton()
                else if (vm.products.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              size: 30,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No products found in "${vm.selectedCategory}"',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Products will be added soon for this category',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (vm.liveCategories.length > 1)
                            ElevatedButton(
                              onPressed: () {
                                final next = vm.liveCategories.firstWhere(
                                  (c) => c.id != vm.selectedCategoryId,
                                  orElse: () => vm.liveCategories.first,
                                );
                                vm.filterCategory(next.name,
                                    categoryId: next.id);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                              ),
                              child: const Text(
                                'Browse Other Categories',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.74,
                    ),
                    itemCount: vm.products.length,
                    itemBuilder: (context, index) {
                      final product = vm.products[index];
                      return _buildProductCard(context, vm, product);
                    },
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: const Border(top: BorderSide(color: Color(0xFFF3F4F6))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem(0, Icons.home_rounded, 'Home'),
                _buildBottomNavItem(1, Icons.grid_view_rounded, 'Categories'),
                Consumer<EcommerceViewModel>(
                  builder: (context, vm, _) => _buildBottomNavItem(
                    2,
                    Icons.shopping_bag_outlined,
                    'Cart',
                    badgeCount: vm.cartItems.length,
                  ),
                ),
                _buildBottomNavItem(3, Icons.person_outline_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(int index, IconData icon, String label,
      {int badgeCount = 0}) {
    final isSelected = _selectedBottomNav == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBottomNav = index;
        });
        if (index == 0) {
          // Home Tab
        } else if (index == 1) {
          // Categories Tab
        } else if (index == 2) {
          Navigator.pushNamed(context, CartView.routeName).then((_) {
            if (mounted) setState(() => _selectedBottomNav = 0);
          });
        } else if (index == 3) {
          Navigator.pushNamed(context, ProfileView.routeName).then((_) {
            if (mounted) setState(() => _selectedBottomNav = 0);
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFF9CA3AF),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Center(
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required String name,
    required String assetPath,
    required IconData fallbackIcon,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required bool isSelected,
    required VoidCallback onTap,
    String? imageUrl,
    double? width,
    String? iconUrl,
    String? iconName,
  }) {
    const primaryBlue = Color(0xFF2563EB);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: width ?? 96,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryBlue : borderColor,
            width: isSelected ? 2.2 : 1.2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: primaryBlue.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 28,
                  child: _buildCategoryIconWidget(
                    imageUrl: imageUrl,
                    iconUrl: iconUrl,
                    iconName: iconName,
                    assetPath: assetPath,
                    fallbackIcon: fallbackIcon,
                    iconColor: isSelected ? primaryBlue : textColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                    color: isSelected ? primaryBlue : textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: -6,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    color: primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 9,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIconWidget({
    String? imageUrl,
    String? iconUrl,
    String? iconName,
    required String assetPath,
    required IconData fallbackIcon,
    required Color iconColor,
  }) {
    // 1. Image URL from API
    final effectiveImg = imageUrl?.trim();
    if (effectiveImg != null &&
        effectiveImg.isNotEmpty &&
        effectiveImg.startsWith('http')) {
      if (effectiveImg.endsWith('.svg')) {
        return SvgPicture.network(
          effectiveImg,
          fit: BoxFit.contain,
          placeholderBuilder: (_) =>
              Icon(fallbackIcon, size: 24, color: iconColor),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: effectiveImg,
          fit: BoxFit.cover,
          width: 28,
          height: 28,
          placeholder: (_, __) => Icon(fallbackIcon,
              size: 24, color: iconColor.withValues(alpha: 0.5)),
          errorWidget: (_, __, ___) =>
              _buildCategoryFallback(assetPath, fallbackIcon, iconColor),
        ),
      );
    }

    // 2. Icon URL from API
    final effectiveIconUrl = iconUrl?.trim();
    if (effectiveIconUrl != null &&
        effectiveIconUrl.isNotEmpty &&
        effectiveIconUrl.startsWith('http')) {
      if (effectiveIconUrl.endsWith('.svg')) {
        return SvgPicture.network(
          effectiveIconUrl,
          fit: BoxFit.contain,
          placeholderBuilder: (_) =>
              Icon(fallbackIcon, size: 24, color: iconColor),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: effectiveIconUrl,
          fit: BoxFit.cover,
          width: 28,
          height: 28,
          placeholder: (_, __) => Icon(fallbackIcon,
              size: 24, color: iconColor.withValues(alpha: 0.5)),
          errorWidget: (_, __, ___) =>
              _buildCategoryFallback(assetPath, fallbackIcon, iconColor),
        ),
      );
    }

    // 3. Icon String Name from API
    final resolvedIcon = _resolveIconFromString(iconName);
    if (resolvedIcon != null) {
      return Icon(resolvedIcon, size: 24, color: iconColor);
    }

    // 4. Fallback to Asset Image or Material Icon
    return _buildCategoryFallback(assetPath, fallbackIcon, iconColor);
  }

  Widget _buildCategoryFallback(
      String assetPath, IconData fallbackIcon, Color iconColor) {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Icon(
        fallbackIcon,
        size: 24,
        color: iconColor,
      ),
    );
  }

  IconData? _resolveIconFromString(String? iconName) {
    if (iconName == null || iconName.trim().isEmpty) return null;
    final clean = iconName.trim().toLowerCase();
    switch (clean) {
      case 'sand':
      case 'waves':
        return Icons.waves_rounded;
      case 'brick':
      case 'bricks':
      case 'view_in_ar':
        return Icons.view_in_ar_rounded;
      case 'aggregate':
      case 'aggregates':
      case 'layers':
        return Icons.layers_outlined;
      case 'fill':
      case 'filling':
      case 'terrain':
        return Icons.terrain_rounded;
      case 'cement':
      case 'inventory':
        return Icons.inventory_2_outlined;
      case 'grain':
        return Icons.grain_rounded;
      case 'construction':
      case 'build':
        return Icons.construction_rounded;
      default:
        return null;
    }
  }

  _CategoryStyle _getCategoryStyle(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('sandm')) {
      return const _CategoryStyle(
        assetPath: 'assets/images/cat_sand_icon.png',
        icon: Icons.grain_rounded,
        bgColor: Color(0xFFFEF3C7),
        borderColor: Color(0xFFFDE68A),
        textColor: Color(0xFF92400E),
      );
    } else if (lower.contains('sand')) {
      return const _CategoryStyle(
        assetPath: 'assets/images/cat_sand_icon.png',
        icon: Icons.waves_rounded,
        bgColor: Color(0xFFFDF6EE),
        borderColor: Color(0xFFFDE68A),
        textColor: Color(0xFF78350F),
      );
    } else if (lower.contains('brick')) {
      return const _CategoryStyle(
        assetPath: 'assets/images/cat_bricks_icon.png',
        icon: Icons.view_in_ar_rounded,
        bgColor: Color(0xFFF3F4FD),
        borderColor: Color(0xFFE0E7FF),
        textColor: Color(0xFF4F46E5),
      );
    } else if (lower.contains('aggregat')) {
      return const _CategoryStyle(
        assetPath: 'assets/images/cat_aggregates_icon.png',
        icon: Icons.layers_outlined,
        bgColor: Color(0xFFF8FAFC),
        borderColor: Color(0xFFE2E8F0),
        textColor: Color(0xFF475569),
      );
    } else if (lower.contains('fill')) {
      return const _CategoryStyle(
        assetPath: 'assets/images/cat_cement_icon.png',
        icon: Icons.terrain_rounded,
        bgColor: Color(0xFFF0FDF4),
        borderColor: Color(0xFFDCFCE7),
        textColor: Color(0xFF15803D),
      );
    } else if (lower.contains('cement')) {
      return const _CategoryStyle(
        assetPath: 'assets/images/cat_cement_icon.png',
        icon: Icons.inventory_2_outlined,
        bgColor: Color(0xFFF8FAFC),
        borderColor: Color(0xFFE2E8F0),
        textColor: Color(0xFF475569),
      );
    }
    return const _CategoryStyle(
      assetPath: 'assets/images/ecom_hero_clean.png',
      icon: Icons.category_rounded,
      bgColor: Color(0xFFF8FAFC),
      borderColor: Color(0xFFE2E8F0),
      textColor: Color(0xFF334155),
    );
  }

  Widget _buildProductCard(
      BuildContext context, EcommerceViewModel vm, ProductModel product) {
    final bool isNetworkImage = product.imageUrl.startsWith('http://') ||
        product.imageUrl.startsWith('https://');

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          ProductDetailView.routeName,
          arguments: product,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product 3D Image
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: isNetworkImage
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) => Image.asset(
                            product.fallbackAssetPath,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Image.asset(
                          product.fallbackAssetPath,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) => Icon(
                            product.category.toLowerCase().contains('sand')
                                ? Icons.waves_rounded
                                : Icons.view_in_ar_rounded,
                            size: 44,
                            color: const Color(0xFF4F46E5),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Product Title
            Text(
              product.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            // Price & Unit
            Row(
              children: [
                Text(
                  '₹${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  product.unit,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Add to Cart Button
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                onPressed: () {
                  vm.addToCart(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.title} added to cart!'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: const Color(0xFF1E1B4B),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGridSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.74,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 14,
                width: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 12,
                width: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 36,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryStyle {
  final String assetPath;
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _CategoryStyle({
    required this.assetPath,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });
}
