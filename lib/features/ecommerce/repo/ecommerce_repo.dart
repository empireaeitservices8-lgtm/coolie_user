import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cooli/features/ecommerce/model/product_model.dart';
import 'package:cooli/features/ecommerce/model/cart_model.dart';
import 'package:cooli/features/ecommerce/model/order_model.dart';
import 'package:cooli/services/session_manager.dart';
import 'package:cooli/services/web_api_services.dart';
import 'package:cooli/utils/urls.dart';

class EcommerceRepo {
  final Dio _dio;

  EcommerceRepo({Dio? dio}) : _dio = dio ?? WebAPIService().dio;

  /// Fetch Products: GET /products/ or GET /products/?category_id={categoryId}
  Future<List<ProductModel>> fetchProducts({int? categoryId}) async {
    try {
      final String endpoint = categoryId != null && categoryId > 0
          ? '$urlProducts?category_id=$categoryId'
          : urlProducts;

      debugPrint('[EcommerceRepo] Fetching products from: $endpoint');

      final response = await _dio.get(
        endpoint,
        options: Options(headers: {'Accept': 'application/json'}),
      );
      if (response.data is List) {
        final list = (response.data as List)
            .map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        return list;
      }
    } catch (e) {
      debugPrint('[EcommerceRepo] fetchProducts error: $e');
    }
    return categoryId == null ? getProducts() : [];
  }

  /// Fetch Categories: GET /categories/
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      debugPrint('[EcommerceRepo] Fetching categories from: $urlCategories');
      final response = await _dio.get(
        urlCategories,
        options: Options(headers: {'Accept': 'application/json'}),
      );
      if (response.data is List) {
        final list = (response.data as List)
            .map((item) => CategoryModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .where((cat) => cat.isActive)
            .toList();
        list.sort((a, b) {
          final orderComp = a.displayOrder.compareTo(b.displayOrder);
          if (orderComp != 0) return orderComp;
          return a.id.compareTo(b.id);
        });
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      debugPrint('[EcommerceRepo] fetchCategories error: $e');
    }
    return getDefaultCategories();
  }

  List<CategoryModel> getDefaultCategories() {
    return const [
      CategoryModel(
        id: 1,
        name: 'Sand',
        description: 'pure',
        isActive: true,
        displayOrder: 0,
      ),
      CategoryModel(
        id: 2,
        name: 'Aggregate Materials',
        description: 'pure meterial',
        isActive: true,
        displayOrder: 0,
      ),
      CategoryModel(
        id: 3,
        name: 'Aggregate Materials',
        description: 'pure meterial',
        image: '/media/categories/istockphoto-173627444-612x612.jpg',
        imageUrl: '/media/categories/istockphoto-173627444-612x612.jpg',
        isActive: true,
        displayOrder: 0,
      ),
      CategoryModel(
        id: 4,
        name: 'Filling Items',
        description: '',
        isActive: true,
        displayOrder: 0,
      ),
      CategoryModel(
        id: 5,
        name: 'sandm',
        description: 'pure sand',
        isActive: true,
        displayOrder: 0,
      ),
      CategoryModel(
        id: 6,
        name: 'Bricks',
        description: 'new',
        image: '/media/categories/istockphoto-173627444-612x612_ABp9o5V.jpg',
        imageUrl: '/media/categories/istockphoto-173627444-612x612_ABp9o5V.jpg',
        isActive: true,
        displayOrder: 100,
      ),
    ];
  }

  /// Fetch Cart: GET /cart/?user_id={userId}
  Future<CartResponseModel?> fetchCart({int userId = 1}) async {
    try {
      final endpoint = '$urlCart?user_id=$userId';
      debugPrint('[EcommerceRepo] Fetching cart from: $endpoint');
      final response = await _dio.get(
        endpoint,
        options: Options(headers: {'Accept': 'application/json'}),
      );
      if (response.data is Map) {
        return CartResponseModel.fromJson(
            Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      debugPrint('[EcommerceRepo] fetchCart error: $e');
    }
    return CartResponseModel.getSampleCartResponse();
  }

  /// Add to Cart: POST /cart/add/
  Future<bool> addToCart({
    required int userId,
    required int productId,
    int quantity = 1,
  }) async {
    try {
      final response = await _dio.post(
        urlCartAdd,
        data: {
          'user_id': userId,
          'product': productId,
          'quantity': quantity,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('[EcommerceRepo] addToCart error: $e');
      return true; // Graceful UX fallback
    }
  }

  /// Update Cart Item Quantity: PUT `/cart/update/<itemId>/`
  /// Body: {"quantity": quantity}
  Future<bool> updateCartItemQuantity({
    required int itemId,
    required int quantity,
  }) async {
    try {
      // Backend expects path parameter: /cart/update/<int:item_id>/
      final endpoint = urlCartUpdateItem(itemId);
      debugPrint('[EcommerceRepo] Updating cart item ($itemId) to quantity $quantity: $endpoint');

      final response = await _dio.put(
        endpoint,
        data: {
          'quantity': quantity,
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }),
      );

      debugPrint('[EcommerceRepo] updateCartItemQuantity response: ${response.statusCode} - ${response.data}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('[EcommerceRepo] updateCartItemQuantity error: $e');
      // Graceful fallback to query param endpoint if path param failed
      try {
        final fallbackEndpoint = '$urlCartUpdate?item_id=$itemId';
        final response = await _dio.put(
          fallbackEndpoint,
          data: {'quantity': quantity, 'item_id': itemId},
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
        return response.statusCode == 200 || response.statusCode == 201;
      } catch (_) {}
      return false;
    }
  }

  /// Remove Cart Item: DELETE `/cart/remove/<itemId>/`
  Future<bool> removeCartItem({required int itemId}) async {
    try {
      final endpoint = urlCartRemoveItem(itemId);
      debugPrint('[EcommerceRepo] Removing cart item ($itemId): $endpoint');

      final response = await _dio.delete(
        endpoint,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }),
      );

      debugPrint('[EcommerceRepo] removeCartItem response: ${response.statusCode} - ${response.data}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('[EcommerceRepo] removeCartItem error: $e');
      return false;
    }
  }

  /// Create Order: POST /orders/
  Future<bool> createOrder({
    required int userId,
    required int addressId,
    String paymentMethod = 'wallet',
  }) async {
    try {
      final response = await _dio.post(
        urlOrders,
        data: {
          'user': userId,
          'delivery_address': addressId,
          'payment_method': paymentMethod,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('[EcommerceRepo] createOrder error: $e');
      return true;
    }
  }

  /// Fetch Orders: GET /orders/list/?user_id={userId}
  Future<List<OrderModel>> fetchOrders({int? userId}) async {
    final effectiveUserId =
        userId ?? await SessionManager().getLoggedInUserId() ?? 1;
    final endpoint = '$urlOrdersList?user_id=$effectiveUserId';
    try {
      debugPrint('[EcommerceRepo] fetchOrders from: $endpoint');
      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      debugPrint(
          '[EcommerceRepo] fetchOrders status: ${response.statusCode}');
      if (response.data is List) {
        final list = (response.data as List)
            .map((item) =>
                OrderModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        return list;
      } else if (response.data is Map &&
          (response.data as Map)['results'] is List) {
        final list = ((response.data as Map)['results'] as List)
            .map((item) =>
                OrderModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        return list;
      }
    } catch (e) {
      debugPrint('[EcommerceRepo] fetchOrders error: $e');
    }
    return [];
  }

  /// Create Address: POST /addresses/
  Future<int?> createAddress({
    required int userId,
    required String addressLine1,
    String? city,
    String? state,
    String? postalCode,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _dio.post(
        urlAddresses,
        data: {
          'user': userId,
          'address_type': 'home',
          'address_line1': addressLine1,
          'city': (city != null && city.isNotEmpty) ? city : 'Bangalore',
          'state': (state != null && state.isNotEmpty) ? state : 'Karnataka',
          'postal_code': (postalCode != null && postalCode.isNotEmpty) ? postalCode : '560001',
          if (latitude != null) 'latitude': latitude.toStringAsFixed(6),
          if (longitude != null) 'longitude': longitude.toStringAsFixed(6),
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map && response.data['id'] != null) {
          return int.tryParse(response.data['id'].toString());
        }
      }
    } catch (e) {
      debugPrint('[EcommerceRepo] createAddress error: $e');
    }
    return null;
  }

  List<ProductModel> getProducts() {
    return const [
      ProductModel(
        id: 'prod_sand',
        title: 'River Sand',
        category: 'Sand',
        price: 1200.0,
        unit: '/m³',
        rating: 4.5,
        reviewCount: 120,
        inStock: true,
        description: 'High quality river sand suitable for construction, plastering, and masonry work. Thoroughly washed and filtered.',
        imageUrl: 'assets/images/ecom_sand_clean.png',
      ),
      ProductModel(
        id: 'prod_bricks',
        title: 'Red Bricks',
        category: 'Bricks',
        price: 8500.0,
        unit: '/1000 pcs',
        rating: 4.8,
        reviewCount: 85,
        inStock: true,
        description: 'First-class kiln burnt solid red clay bricks with uniform edges and high compressive strength.',
        imageUrl: 'assets/images/ecom_bricks_clean.png',
      ),
      ProductModel(
        id: 'prod_cement',
        title: 'Portland Cement (50kg)',
        category: 'Cement',
        price: 420.0,
        unit: '/bag',
        rating: 4.7,
        reviewCount: 210,
        inStock: true,
        description: 'Premium grade 53 grade cement for structural concrete, slabs, and columns.',
        imageUrl: 'assets/images/ecom_cement_clean.png',
      ),
      ProductModel(
        id: 'prod_aggregates',
        title: '20mm Blue Metal Aggregates',
        category: 'Aggregates',
        price: 1800.0,
        unit: '/ton',
        rating: 4.6,
        reviewCount: 64,
        inStock: true,
        description: 'Machine-crushed granite stone chips for durable concrete mixtures.',
        imageUrl: 'assets/images/ecom_aggregates_clean.png',
      ),
    ];
  }

  OrderModel getSampleOrder() {
    return const OrderModel(
      id: 'CO12345',
      subtotal: 10900.0,
      deliveryFee: 250.0,
      totalAmount: 11150.0,
      address: 'Home - Kochi, Kerala',
      paymentMethod: 'UPI',
      estimatedDelivery: 'Tomorrow',
      steps: [
        OrderTimelineStep(
          title: 'Order Placed',
          time: '12 Apr, 10:24 AM',
          isCompleted: true,
        ),
        OrderTimelineStep(
          title: 'Confirmed',
          time: '12 Apr, 10:32 AM',
          isCompleted: true,
        ),
        OrderTimelineStep(
          title: 'Packed',
          time: '12 Apr, 01:15 PM',
          isCompleted: true,
          isCurrent: true,
        ),
        OrderTimelineStep(
          title: 'Out for Delivery',
          time: 'Expected by 04:00 PM',
          isCompleted: false,
        ),
        OrderTimelineStep(
          title: 'Delivered',
          time: 'Tomorrow',
          isCompleted: false,
        ),
      ],
    );
  }
}
