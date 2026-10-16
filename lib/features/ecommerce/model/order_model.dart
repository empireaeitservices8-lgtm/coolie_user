enum OrderStatus {
  placed,
  confirmed,
  packed,
  outForDelivery,
  delivered,
  pending,
  cancelled,
}

class OrderTimelineStep {
  final String title;
  final String time;
  final bool isCompleted;
  final bool isCurrent;

  const OrderTimelineStep({
    required this.title,
    required this.time,
    required this.isCompleted,
    this.isCurrent = false,
  });
}

class OrderAddressDetails {
  final int id;
  final int user;
  final String addressType;
  final String addressLine1;
  final String addressLine2;
  final String landmark;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  const OrderAddressDetails({
    required this.id,
    required this.user,
    this.addressType = 'home',
    required this.addressLine1,
    this.addressLine2 = '',
    this.landmark = '',
    required this.city,
    required this.state,
    required this.postalCode,
    this.country = 'India',
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  String get fullAddress {
    final parts = [
      addressLine1,
      if (addressLine2.isNotEmpty) addressLine2,
      if (landmark.isNotEmpty) landmark,
      city,
      if (state.isNotEmpty) state,
      if (postalCode.isNotEmpty) postalCode,
    ];
    return parts.where((p) => p.trim().isNotEmpty).join(', ');
  }

  factory OrderAddressDetails.fromJson(Map<String, dynamic> json) {
    return OrderAddressDetails(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      user: int.tryParse(json['user']?.toString() ?? '') ?? 0,
      addressType: json['address_type']?.toString() ?? 'home',
      addressLine1: json['address_line1']?.toString() ?? '',
      addressLine2: json['address_line2']?.toString() ?? '',
      landmark: json['landmark']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      postalCode: json['postal_code']?.toString() ?? '',
      country: json['country']?.toString() ?? 'India',
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      isDefault: json['is_default'] == true,
    );
  }
}

class OrderItemModel {
  final int id;
  final int order;
  final int? productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double totalPrice;
  final DateTime? createdAt;

  const OrderItemModel({
    required this.id,
    required this.order,
    this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    this.createdAt,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      order: int.tryParse(json['order']?.toString() ?? '') ?? 0,
      productId: int.tryParse(json['product']?.toString() ?? ''),
      productName: json['product_name']?.toString() ?? 'Item',
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '') ?? 0.0,
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '') ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class OrderModel {
  final int? numericId;
  final int? userId;
  final String orderId;
  final String status;
  final String paymentStatus;
  final int? deliveryAddressId;
  final OrderAddressDetails? deliveryAddressDetails;
  final double subtotal;
  final double deliveryCharge;
  final double discountAmount;
  final double totalAmount;
  final String notes;
  final List<OrderItemModel> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Legacy compatibility fields
  final String? _legacyId;
  final double? _legacyDeliveryFee;
  final String? _legacyAddress;
  final String? _legacyPaymentMethod;
  final String? _legacyEstimatedDelivery;
  final List<OrderTimelineStep>? _legacySteps;

  String get id => _legacyId ?? orderId;
  double get deliveryFee => _legacyDeliveryFee ?? deliveryCharge;
  String get address =>
      _legacyAddress ??
      (deliveryAddressDetails?.fullAddress.isNotEmpty == true
          ? deliveryAddressDetails!.fullAddress
          : 'Address provided upon dispatch');
  String get paymentMethod => _legacyPaymentMethod ?? paymentStatus.toUpperCase();
  String get estimatedDelivery => _legacyEstimatedDelivery ?? '1-2 Days';

  List<OrderTimelineStep> get steps =>
      _legacySteps ??
      [
        OrderTimelineStep(
          title: 'Order Placed',
          time: createdAt != null
              ? '${createdAt!.day}/${createdAt!.month} ${createdAt!.hour}:${createdAt!.minute.toString().padLeft(2, '0')}'
              : 'Placed',
          isCompleted: true,
        ),
        OrderTimelineStep(
          title: 'Payment Confirmed',
          time: paymentStatus.toLowerCase() == 'paid' ? 'Paid' : 'Pending',
          isCompleted: paymentStatus.toLowerCase() == 'paid',
        ),
        OrderTimelineStep(
          title: 'Processing Order',
          time: status.toLowerCase() == 'pending' ? 'Pending Confirmation' : 'In Progress',
          isCompleted: status.toLowerCase() != 'pending',
          isCurrent: status.toLowerCase() == 'pending',
        ),
        OrderTimelineStep(
          title: 'Out for Delivery',
          time: status.toLowerCase() == 'delivered' ? 'Completed' : 'Pending',
          isCompleted: status.toLowerCase() == 'delivered',
        ),
      ];

  const OrderModel({
    this.numericId,
    this.userId,
    String? orderId,
    String? id,
    this.status = 'pending',
    this.paymentStatus = 'paid',
    this.deliveryAddressId,
    this.deliveryAddressDetails,
    required this.subtotal,
    double? deliveryFee,
    this.deliveryCharge = 50.0,
    this.discountAmount = 0.0,
    required this.totalAmount,
    this.notes = '',
    this.items = const [],
    this.createdAt,
    this.updatedAt,
    String? address,
    String? paymentMethod,
    String? estimatedDelivery,
    List<OrderTimelineStep>? steps,
  })  : orderId = orderId ?? id ?? 'ORD-001',
        _legacyId = id,
        _legacyDeliveryFee = deliveryFee,
        _legacyAddress = address,
        _legacyPaymentMethod = paymentMethod,
        _legacyEstimatedDelivery = estimatedDelivery,
        _legacySteps = steps;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawId = int.tryParse(json['id']?.toString() ?? '');
    final rawUser = int.tryParse(json['user']?.toString() ?? '');
    final orderId =
        json['order_id']?.toString() ?? 'ORD-${json['id'] ?? '2026-001'}';
    final status = json['status']?.toString().toLowerCase() ?? 'pending';
    final paymentStatus =
        json['payment_status']?.toString().toLowerCase() ?? 'paid';
    final deliveryAddressId =
        int.tryParse(json['delivery_address']?.toString() ?? '');

    OrderAddressDetails? addressDetails;
    if (json['delivery_address_details'] is Map<String, dynamic>) {
      addressDetails = OrderAddressDetails.fromJson(
          json['delivery_address_details'] as Map<String, dynamic>);
    } else if (json['delivery_address_details'] is Map) {
      addressDetails = OrderAddressDetails.fromJson(
          Map<String, dynamic>.from(json['delivery_address_details'] as Map));
    }

    final subtotal = double.tryParse(json['subtotal']?.toString() ?? '') ?? 0.0;
    final deliveryCharge =
        double.tryParse(json['delivery_charge']?.toString() ?? '') ?? 50.0;
    final discountAmount =
        double.tryParse(json['discount_amount']?.toString() ?? '') ?? 0.0;
    final totalAmount =
        double.tryParse(json['total_amount']?.toString() ?? '') ??
            (subtotal + deliveryCharge - discountAmount);
    final notes = json['notes']?.toString() ?? '';

    final items = <OrderItemModel>[];
    if (json['items'] is List) {
      for (final it in (json['items'] as List)) {
        if (it is Map<String, dynamic>) {
          items.add(OrderItemModel.fromJson(it));
        } else if (it is Map) {
          items.add(OrderItemModel.fromJson(Map<String, dynamic>.from(it)));
        }
      }
    }

    DateTime? createdAt;
    if (json['created_at'] != null) {
      createdAt = DateTime.tryParse(json['created_at'].toString());
    }

    DateTime? updatedAt;
    if (json['updated_at'] != null) {
      updatedAt = DateTime.tryParse(json['updated_at'].toString());
    }

    return OrderModel(
      numericId: rawId,
      userId: rawUser,
      orderId: orderId,
      status: status,
      paymentStatus: paymentStatus,
      deliveryAddressId: deliveryAddressId,
      deliveryAddressDetails: addressDetails,
      subtotal: subtotal,
      deliveryCharge: deliveryCharge,
      discountAmount: discountAmount,
      totalAmount: totalAmount,
      notes: notes,
      items: items,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
