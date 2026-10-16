class ProductModel {
  final String id;
  final int? categoryId;
  final String title;
  final String category;
  final double price;
  final String unit;
  final double rating;
  final int reviewCount;
  final bool inStock;
  final String description;
  final String imageUrl;
  final int? stockQuantity;
  final bool isAvailable;
  final bool isFeatured;

  const ProductModel({
    required this.id,
    this.categoryId,
    required this.title,
    required this.category,
    required this.price,
    required this.unit,
    required this.rating,
    required this.reviewCount,
    required this.inStock,
    required this.description,
    required this.imageUrl,
    this.stockQuantity,
    this.isAvailable = true,
    this.isFeatured = false,
  });

  /// Smart asset image fallback based on category and title
  String get fallbackAssetPath {
    final cat = category.toLowerCase();
    final name = title.toLowerCase();
    if (cat.contains('brick') || name.contains('brick') || name.contains('brik') || name.contains('chenkallu') || name.contains('eshtika')) {
      return 'assets/images/ecom_bricks_clean.png';
    }
    if (cat.contains('cement') || name.contains('cement')) {
      return 'assets/images/ecom_cement_clean.png';
    }
    if (cat.contains('aggregate') || cat.contains('crusher') || cat.contains('gravel') || cat.contains('filling') || name.contains('mm')) {
      return 'assets/images/ecom_aggregates_clean.png';
    }
    if (cat.contains('sand') || name.contains('sand') || name.contains('murrum')) {
      return 'assets/images/ecom_sand_clean.png';
    }
    return 'assets/images/ecom_hero_clean.png';
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final priceParsed = double.tryParse(json['price_per_unit']?.toString() ?? '') ??
        (json['price'] is num ? (json['price'] as num).toDouble() : 1200.0);

    final rawImg = (json['image_url'] != null && json['image_url'].toString().isNotEmpty && json['image_url'].toString() != 'null')
        ? json['image_url']?.toString()
        : json['image']?.toString();
    String formattedImg = '';
    if (rawImg != null && rawImg.isNotEmpty && rawImg != 'null') {
      final trimmed = rawImg.trim();
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        formattedImg = trimmed;
      } else {
        final clean = trimmed.startsWith('/') ? trimmed : '/$trimmed';
        formattedImg = 'http://coolie.pythonanywhere.com$clean';
      }
    }

    final catId = json['category'] is int
        ? json['category'] as int
        : int.tryParse(json['category']?.toString() ?? '');

    final catName = json['category_name']?.toString() ??
        json['category']?.toString() ??
        'Materials';

    final stock = json['stock_quantity'] is int
        ? json['stock_quantity'] as int
        : int.tryParse(json['stock_quantity']?.toString() ?? '');

    final isAvail = json['is_available'] == true || (stock != null && stock > 0);

    return ProductModel(
      id: json['id']?.toString() ?? 'prod_1',
      categoryId: catId,
      title: json['name']?.toString() ?? json['title']?.toString() ?? 'Building Material',
      category: catName,
      price: priceParsed,
      unit: json['unit'] != null && json['unit'].toString().isNotEmpty
          ? '/${json['unit']}'
          : '/unit',
      rating: 4.7,
      reviewCount: 95,
      inStock: isAvail,
      stockQuantity: stock,
      isAvailable: isAvail,
      isFeatured: json['is_featured'] == true,
      description: json['description']?.toString() ?? 'High quality construction and building materials.',
      imageUrl: formattedImg,
    );
  }
}

class CategoryModel {
  final int id;
  final String name;
  final String description;
  final String? icon;
  final String? image;
  final String? imageUrl;
  final bool isActive;
  final int displayOrder;
  final String? createdAt;
  final String? updatedAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    this.icon,
    this.image,
    this.imageUrl,
    this.isActive = true,
    this.displayOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Formatted image URL from backend (handles relative path or full URL)
  String? get fullImageUrl {
    final raw = (imageUrl != null && imageUrl!.trim().isNotEmpty && imageUrl != 'null')
        ? imageUrl
        : image;
    if (raw == null || raw.trim().isEmpty || raw == 'null') return null;
    final trimmed = raw.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return 'http://coolie.pythonanywhere.com$cleanPath';
  }

  /// Formatted icon URL if icon from backend is a web URL or file path
  String? get fullIconUrl {
    if (icon == null || icon!.trim().isEmpty || icon == 'null') return null;
    final trimmed = icon!.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.contains('/') ||
        trimmed.endsWith('.png') ||
        trimmed.endsWith('.jpg') ||
        trimmed.endsWith('.jpeg') ||
        trimmed.endsWith('.svg') ||
        trimmed.endsWith('.webp')) {
      final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
      return 'http://coolie.pythonanywhere.com$cleanPath';
    }
    return null;
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Category',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString(),
      image: json['image']?.toString(),
      imageUrl: json['image_url']?.toString(),
      isActive: json['is_active'] != false,
      displayOrder: json['display_order'] is int
          ? json['display_order'] as int
          : int.tryParse(json['display_order']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon': icon,
    'image': image,
    'is_active': isActive,
    'display_order': displayOrder,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}
