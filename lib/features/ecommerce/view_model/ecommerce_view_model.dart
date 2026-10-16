import 'package:cooli/features/ecommerce/model/product_model.dart';
import 'package:cooli/features/ecommerce/model/cart_model.dart';
import 'package:cooli/features/ecommerce/model/order_model.dart';
import 'package:cooli/features/address/model/address_model.dart';
import 'package:cooli/features/ecommerce/repo/ecommerce_repo.dart';
import 'package:cooli/providers/view_model.dart';
import 'package:cooli/services/session_manager.dart';
import 'package:flutter/material.dart';

class EcommerceViewModel extends ViewModel {
  final EcommerceRepo _repo;

  EcommerceViewModel({EcommerceRepo? repo}) : _repo = repo ?? EcommerceRepo() {
    _liveCategories = _repo.getDefaultCategories();
    if (_liveCategories.isNotEmpty) {
      _selectedCategory = _liveCategories.first.name;
      _selectedCategoryId = _liveCategories.first.id;
    }
    loadProducts();
    loadCart();
  }

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  List<ProductModel> get products => _filteredProducts;

  List<CategoryModel> _liveCategories = [];
  List<CategoryModel> get liveCategories => _liveCategories.isNotEmpty
      ? _liveCategories
      : _repo.getDefaultCategories();

  bool _isLoadingCategories = false;
  bool get isLoadingCategories => _isLoadingCategories;

  bool _isLoadingProducts = false;
  bool get isLoadingProducts => _isLoadingProducts;

  final Map<int, List<ProductModel>> _categoryCache = {};

  String _selectedCategory = 'Sand';
  String get selectedCategory => _selectedCategory;

  int? _selectedCategoryId = 1;
  int? get selectedCategoryId => _selectedCategoryId;

  List<String> get categories => _liveCategories.map((c) => c.name).toList();

  // Cart
  List<CartItemModel> _cartItems = [];
  List<CartItemModel> get cartItems => _cartItems;

  CartResponseModel? _cartResponse;
  CartResponseModel? get cartResponse => _cartResponse;

  bool _isLoadingCart = false;
  bool get isLoadingCart => _isLoadingCart;

  int get totalCartItems =>
      _cartResponse?.totalItems ??
      _cartItems.fold<int>(0, (sum, i) => sum + i.quantity);

  int _productQuantity = 1;
  int get productQuantity => _productQuantity;

  // Checkout
  String _selectedPaymentMethod = 'Wallet';
  String get selectedPaymentMethod => _selectedPaymentMethod;

  int _checkoutStep = 3; // Step 3: Payment
  int get checkoutStep => _checkoutStep;

  // Delivery Address from Map (initially empty)
  String? _deliveryAddressTitle;
  String? _deliveryAddressSubtitle;
  String? _deliveryAddressFull;
  double? _deliveryLatitude;
  double? _deliveryLongitude;
  int? _deliveryAddressId;

  String? get deliveryAddressTitle => _deliveryAddressTitle;
  String? get deliveryAddressSubtitle => _deliveryAddressSubtitle;
  String? get deliveryAddressFull => _deliveryAddressFull;
  double? get deliveryLatitude => _deliveryLatitude;
  double? get deliveryLongitude => _deliveryLongitude;
  int? get deliveryAddressId => _deliveryAddressId;

  bool get hasDeliveryAddress =>
      _deliveryAddressTitle != null && _deliveryAddressTitle!.trim().isNotEmpty;

  OrderModel? _currentOrder;
  OrderModel? get currentOrder => _currentOrder;

  double get subtotal {
    if (_cartResponse != null && _cartResponse!.totalAmount > 0) {
      return _cartResponse!.totalAmount;
    }
    return _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get deliveryFee => _cartItems.isEmpty ? 0.0 : 250.0;
  double get totalAmount => subtotal + deliveryFee;

  Future<void> loadCart() async {
    _isLoadingCart = true;
    notifyListeners();
    try {
      final userId = await SessionManager().getUserId(fallback: 1);
      final response = await _repo.fetchCart(userId: userId);
      if (response != null) {
        _cartResponse = response;
        _cartItems = List.from(response.items);
      }
    } catch (e) {
      debugPrint('[EcommerceViewModel] loadCart error: $e');
    } finally {
      _isLoadingCart = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    _isLoadingCategories = true;
    notifyListeners();
    try {
      final cats = await _repo.fetchCategories();
      if (cats.isNotEmpty) {
        _liveCategories = cats;
        if (_selectedCategoryId == null ||
            !_liveCategories.any((c) => c.id == _selectedCategoryId)) {
          final first = _liveCategories.first;
          _selectedCategory = first.name;
          _selectedCategoryId = first.id;
          filterCategory(first.name, categoryId: first.id);
        }
      }
    } catch (e) {
      debugPrint('[EcommerceViewModel] loadCategories error: $e');
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  void loadProducts() async {
    _isLoadingProducts = true;
    _isLoadingCategories = true;
    _allProducts = _repo.getProducts();
    _filteredProducts = List.from(_allProducts);
    _currentOrder = _repo.getSampleOrder();
    _liveCategories = _repo.getDefaultCategories();
    if (_selectedCategoryId == null && _liveCategories.isNotEmpty) {
      _selectedCategory = _liveCategories.first.name;
      _selectedCategoryId = _liveCategories.first.id;
    }
    notifyListeners();

    try {
      final cats = await _repo.fetchCategories();
      if (cats.isNotEmpty) {
        _liveCategories = cats;
        if (_selectedCategoryId == null ||
            !_liveCategories.any((c) => c.id == _selectedCategoryId)) {
          _selectedCategory = _liveCategories.first.name;
          _selectedCategoryId = _liveCategories.first.id;
        }
      }
    } catch (e) {
      debugPrint('[EcommerceViewModel] loadCategories error: $e');
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }

    try {
      final live = await _repo.fetchProducts(categoryId: _selectedCategoryId);
      if (live.isNotEmpty) {
        if (_selectedCategoryId != null) {
          _categoryCache[_selectedCategoryId!] = live;
        }
        _filteredProducts = List.from(live);
      }
    } catch (e) {
      debugPrint('[EcommerceViewModel] loadProducts error: $e');
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  Future<void> filterCategory(String category, {int? categoryId}) async {
    int? effectiveId = categoryId;
    if (effectiveId == null) {
      final matches = _liveCategories.where(
        (c) => c.name.toLowerCase() == category.toLowerCase(),
      );
      if (matches.isNotEmpty) {
        effectiveId = matches.first.id;
      } else if (_liveCategories.isNotEmpty) {
        effectiveId = _liveCategories.first.id;
      }
    }

    _selectedCategory = category;
    _selectedCategoryId = effectiveId;

    // Specific category selected: show cached list if available immediately
    if (effectiveId != null && _categoryCache.containsKey(effectiveId)) {
      _filteredProducts = List.from(_categoryCache[effectiveId]!);
      _isLoadingProducts = false;
      notifyListeners();
    } else {
      _isLoadingProducts = true;
      notifyListeners();
    }

    try {
      // Call API: GET https://coolie.pythonanywhere.com/api/products/?category_id=$categoryId
      final liveCategoryProducts =
          await _repo.fetchProducts(categoryId: effectiveId);
      if (effectiveId != null) {
        _categoryCache[effectiveId] = liveCategoryProducts;
      }
      if (_selectedCategoryId == effectiveId) {
        _filteredProducts = List.from(liveCategoryProducts);
      }
    } catch (e) {
      debugPrint('[EcommerceViewModel] filterCategory $effectiveId error: $e');
    } finally {
      if (_selectedCategoryId == effectiveId) {
        _isLoadingProducts = false;
      }
      notifyListeners();
    }
  }

  void searchProducts(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      if (_selectedCategoryId != null && _categoryCache.containsKey(_selectedCategoryId!)) {
        _filteredProducts = List.from(_categoryCache[_selectedCategoryId!]!);
      } else {
        _filteredProducts = List.from(_allProducts);
      }
      notifyListeners();
      return;
    }
    final source = _allProducts.isNotEmpty ? _allProducts : _filteredProducts;
    _filteredProducts = source.where((p) {
      return p.title.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();
    notifyListeners();
  }

  void setProductQuantity(int quantity) {
    if (quantity >= 1) {
      _productQuantity = quantity;
      notifyListeners();
    }
  }

  Future<void> addToCart(ProductModel product, {int quantity = 1}) async {
    final existingIndex = _cartItems.indexWhere(
      (item) => item.productId?.toString() == product.id || item.product.id == product.id,
    );
    if (existingIndex >= 0) {
      _cartItems[existingIndex].quantity += quantity;
      _cartItems[existingIndex].itemTotalPrice =
          _cartItems[existingIndex].unitPrice * _cartItems[existingIndex].quantity;
    } else {
      _cartItems.add(CartItemModel(
        productId: int.tryParse(product.id),
        productName: product.title,
        productImage: product.imageUrl,
        unitPrice: product.price,
        quantity: quantity,
        itemTotalPrice: product.price * quantity,
        product: product,
      ));
    }
    notifyListeners();

    try {
      final userId = await SessionManager().getUserId(fallback: 1);
      final prodId = int.tryParse(product.id) ?? 1;
      await _repo.addToCart(
        userId: userId,
        productId: prodId,
        quantity: quantity,
      );
      // Refresh cart directly from backend API: /cart/?user_id=$userId
      await loadCart();
    } catch (e) {
      debugPrint('[EcommerceViewModel] addToCart API sync error: $e');
    }
  }

  Future<void> updateCartItemQuantity(CartItemModel item, int delta) async {
    final int newQuantity = item.quantity + delta;
    await setCartItemQuantity(item, newQuantity);
  }

  Future<bool> setCartItemQuantity(CartItemModel item, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeCartItem(item);
      return true;
    }

    item.quantity = newQuantity;
    item.itemTotalPrice = item.unitPrice * newQuantity;
    notifyListeners();

    try {
      if (item.id != null && item.id! > 0) {
        // PUT http://coolie.pythonanywhere.com/api/cart/update/<itemId>/ with body {"quantity": newQuantity}
        final success = await _repo.updateCartItemQuantity(
          itemId: item.id!,
          quantity: newQuantity,
        );
        debugPrint(
            '[EcommerceViewModel] updateCartItemQuantity PUT success: $success');
      } else {
        final userId = await SessionManager().getUserId(fallback: 1);
        final prodId = item.productId ?? int.tryParse(item.product.id) ?? 1;
        await _repo.addToCart(
          userId: userId,
          productId: prodId,
          quantity: newQuantity,
        );
      }
      await loadCart();
      return true;
    } catch (e) {
      debugPrint('[EcommerceViewModel] setCartItemQuantity API error: $e');
      return false;
    }
  }

  Future<void> removeCartItem(CartItemModel item) async {
    _cartItems.remove(item);
    notifyListeners();

    try {
      if (item.id != null && item.id! > 0) {
        await _repo.removeCartItem(itemId: item.id!);
        await loadCart();
      }
    } catch (e) {
      debugPrint('[EcommerceViewModel] removeCartItem error: $e');
    }
  }

  Future<void> setDeliveryAddress({
    required String title,
    String? subtitle,
    double? latitude,
    double? longitude,
    int? addressId,
  }) async {
    _deliveryAddressTitle = title;
    _deliveryAddressSubtitle = subtitle;
    _deliveryAddressFull = (subtitle != null && subtitle.trim().isNotEmpty)
        ? '$title, $subtitle'
        : title;
    _deliveryLatitude = latitude;
    _deliveryLongitude = longitude;
    if (addressId != null) {
      _deliveryAddressId = addressId;
      notifyListeners();
      return;
    }
    notifyListeners();

    // Auto-sync address to backend /api/addresses/
    try {
      final userId = await SessionManager().getUserId(fallback: 1);
      final newId = await _repo.createAddress(
        userId: userId,
        addressLine1: _deliveryAddressFull ?? title,
        latitude: latitude,
        longitude: longitude,
      );
      if (newId != null) {
        _deliveryAddressId = newId;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[EcommerceViewModel] setDeliveryAddress API sync error: $e');
    }
  }

  void selectSavedAddress(AddressModel address) {
    _deliveryAddressTitle = address.addressLine1;
    _deliveryAddressSubtitle = address.formattedAddress != address.addressLine1
        ? '${address.city}, ${address.state} - ${address.postalCode}'
        : null;
    _deliveryAddressFull = address.formattedAddress;
    _deliveryLatitude = address.latitude;
    _deliveryLongitude = address.longitude;
    _deliveryAddressId = address.id;
    notifyListeners();
  }

  void clearDeliveryAddress() {
    _deliveryAddressTitle = null;
    _deliveryAddressSubtitle = null;
    _deliveryAddressFull = null;
    _deliveryLatitude = null;
    _deliveryLongitude = null;
    _deliveryAddressId = null;
    notifyListeners();
  }

  bool _isPlacingOrder = false;
  bool get isPlacingOrder => _isPlacingOrder;

  Future<bool> placeOrder({int? addressId, String? paymentMethod}) async {
    _isPlacingOrder = true;
    notifyListeners();
    try {
      final userId = await SessionManager().getUserId(fallback: 1);
      final effectiveAddressId = addressId ?? _deliveryAddressId ?? 1;
      final method = paymentMethod ?? _selectedPaymentMethod;
      final success = await _repo.createOrder(
        userId: userId,
        addressId: effectiveAddressId,
        paymentMethod: method,
      );
      if (success) {
        _cartItems.clear();
        _cartResponse = null;
        await loadCart();
      }
      return success;
    } catch (e) {
      debugPrint('[EcommerceViewModel] placeOrder error: $e');
      return false;
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }

  void setPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  void setCheckoutStep(int step) {
    _checkoutStep = step;
    notifyListeners();
  }

  // --- Orders State Management ---
  List<OrderModel> _orders = [];
  List<OrderModel> get orders => _orders;

  bool _isLoadingOrders = false;
  bool get isLoadingOrders => _isLoadingOrders;

  String _orderFilter = 'All'; // 'All', 'Pending', 'Paid', 'Delivered'
  String get orderFilter => _orderFilter;

  List<OrderModel> get filteredOrders {
    if (_orderFilter == 'Pending') {
      return _orders
          .where((o) => o.status.toLowerCase() == 'pending')
          .toList();
    } else if (_orderFilter == 'Paid') {
      return _orders
          .where((o) => o.paymentStatus.toLowerCase() == 'paid')
          .toList();
    } else if (_orderFilter == 'Delivered') {
      return _orders
          .where((o) =>
              o.status.toLowerCase() == 'delivered' ||
              o.status.toLowerCase() == 'completed')
          .toList();
    }
    return _orders;
  }

  void setOrderFilter(String filter) {
    _orderFilter = filter;
    notifyListeners();
  }

  Future<List<OrderModel>> fetchUserOrders({int? userId}) async {
    _isLoadingOrders = true;
    notifyListeners();

    try {
      final targetUserId = userId ?? await SessionManager().getLoggedInUserId() ?? 1;
      final fetched = await _repo.fetchOrders(userId: targetUserId);
      _orders = fetched;
      return fetched;
    } catch (e) {
      debugPrint('[EcommerceViewModel] fetchUserOrders error: $e');
      return [];
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }
}
