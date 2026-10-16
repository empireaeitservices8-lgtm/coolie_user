import 'package:cooli/features/ecommerce/model/product_model.dart';

class CartResponseModel {
  final int id;
  final int user;
  final List<CartItemModel> items;
  final double totalAmount;
  final int totalItems;
  final String? createdAt;
  final String? updatedAt;

  CartResponseModel({
    required this.id,
    required this.user,
    required this.items,
    required this.totalAmount,
    required this.totalItems,
    this.createdAt,
    this.updatedAt,
  });

  factory CartResponseModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    List<CartItemModel> itemList = [];
    if (rawItems is List) {
      itemList = rawItems
          .map((item) =>
              CartItemModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    final double parsedTotal =
        double.tryParse(json['total_amount']?.toString() ?? '') ??
            (json['total_amount'] is num
                ? (json['total_amount'] as num).toDouble()
                : itemList.fold<double>(0.0, (sum, i) => sum + i.totalPrice));

    final int parsedTotalItems = json['total_items'] is int
        ? json['total_items'] as int
        : int.tryParse(json['total_items']?.toString() ?? '') ??
            itemList.fold<int>(0, (sum, i) => sum + i.quantity);

    return CartResponseModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 1,
      user: json['user'] is int
          ? json['user'] as int
          : int.tryParse(json['user']?.toString() ?? '0') ?? 1,
      items: itemList,
      totalAmount: parsedTotal,
      totalItems: parsedTotalItems,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  static CartResponseModel getSampleCartResponse() {
    return CartResponseModel(
      id: 1,
      user: 1,
      totalAmount: 227050.0,
      totalItems: 19,
      createdAt: '2026-10-05T06:47:51.408936Z',
      updatedAt: '2026-10-14T08:21:57.671786Z',
      items: [
        CartItemModel(
          id: 7,
          cartId: 1,
          productId: 17,
          productName: 'Crusher',
          unitPrice: 50000.0,
          quantity: 4,
          itemTotalPrice: 200000.0,
          createdAt: '2026-10-13T06:23:57.316408Z',
          updatedAt: '2026-10-14T08:21:57.671786Z',
        ),
        CartItemModel(
          id: 6,
          cartId: 1,
          productId: 3,
          productName: 'Dry Sand',
          unitPrice: 3000.0,
          quantity: 2,
          itemTotalPrice: 6000.0,
          createdAt: '2026-10-13T06:20:10.769076Z',
          updatedAt: '2026-10-14T08:17:06.941397Z',
        ),
        CartItemModel(
          id: 5,
          cartId: 1,
          productId: 1,
          productName: 'P sand',
          unitPrice: 1000.0,
          quantity: 2,
          itemTotalPrice: 2000.0,
          createdAt: '2026-10-13T05:59:26.512948Z',
          updatedAt: '2026-10-13T05:59:26.512983Z',
        ),
        CartItemModel(
          id: 4,
          cartId: 1,
          productId: 7,
          productName: '20mm',
          unitPrice: 1000.0,
          quantity: 1,
          itemTotalPrice: 1000.0,
          createdAt: '2026-10-13T05:58:40.218702Z',
          updatedAt: '2026-10-13T05:58:40.218727Z',
        ),
        CartItemModel(
          id: 3,
          cartId: 1,
          productId: 8,
          productName: '12mm',
          unitPrice: 2000.0,
          quantity: 9,
          itemTotalPrice: 18000.0,
          createdAt: '2026-10-13T05:58:26.960993Z',
          updatedAt: '2026-10-14T08:08:47.327201Z',
        ),
        CartItemModel(
          id: 2,
          cartId: 1,
          productId: 19,
          productName: 'red brik',
          unitPrice: 50.0,
          quantity: 1,
          itemTotalPrice: 50.0,
          createdAt: '2026-10-08T11:17:54.594325Z',
          updatedAt: '2026-10-08T11:17:54.594374Z',
        ),
      ],
    );
  }
}

class CartItemModel {
  final int? id;
  final int? cartId;
  final int? productId;
  final String productName;
  final String? productImage;
  final double unitPrice;
  int quantity;
  double? itemTotalPrice;
  final String? createdAt;
  final String? updatedAt;
  final ProductModel? _customProduct;

  CartItemModel({
    this.id,
    this.cartId,
    this.productId,
    String? productName,
    this.productImage,
    double? unitPrice,
    this.quantity = 1,
    this.itemTotalPrice,
    this.createdAt,
    this.updatedAt,
    ProductModel? product,
  })  : _customProduct = product,
        productName = productName ?? product?.title ?? 'Product',
        unitPrice = unitPrice ?? product?.price ?? 0.0;

  double get totalPrice => itemTotalPrice ?? (unitPrice * quantity);

  String? get fullProductImageUrl {
    if (productImage == null ||
        productImage!.trim().isEmpty ||
        productImage == 'null') {
      return _customProduct?.imageUrl;
    }
    final trimmed = productImage!.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return 'http://coolie.pythonanywhere.com$cleanPath';
  }

  static String _inferCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('sand')) return 'Sand';
    if (lower.contains('brik') || lower.contains('brick')) return 'Bricks';
    if (lower.contains('cement')) return 'Cement';
    if (lower.contains('crusher') ||
        lower.contains('mm') ||
        lower.contains('aggregat')) {
      return 'Aggregates';
    }
    return 'Materials';
  }

  ProductModel get product {
    final custom = _customProduct;
    if (custom != null) return custom;
    return ProductModel(
      id: productId?.toString() ?? id?.toString() ?? '1',
      title: productName,
      category: _inferCategory(productName),
      price: unitPrice,
      unit: '',
      rating: 4.8,
      reviewCount: 45,
      inStock: true,
      description: productName,
      imageUrl: fullProductImageUrl ?? '',
    );
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final parsedPrice =
        double.tryParse(json['unit_price']?.toString() ?? '') ?? 0.0;
    final int qty = json['quantity'] is int
        ? json['quantity'] as int
        : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1;
    final parsedTotal =
        double.tryParse(json['total_price']?.toString() ?? '') ??
            (parsedPrice * qty);

    return CartItemModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? ''),
      cartId: json['cart'] is int
          ? json['cart'] as int
          : int.tryParse(json['cart']?.toString() ?? ''),
      productId: json['product'] is int
          ? json['product'] as int
          : int.tryParse(json['product']?.toString() ?? ''),
      productName: json['product_name']?.toString() ?? 'Product',
      productImage: json['product_image']?.toString(),
      unitPrice: parsedPrice,
      quantity: qty,
      itemTotalPrice: parsedTotal,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cart': cartId,
        'product': productId,
        'product_name': productName,
        'product_image': productImage,
        'unit_price': unitPrice,
        'quantity': quantity,
        'total_price': totalPrice,
      };
}
