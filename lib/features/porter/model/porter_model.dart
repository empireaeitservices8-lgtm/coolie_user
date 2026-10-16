import 'package:flutter/material.dart';

class PorterVehicleType {
  final String id;
  final String name;
  final String capacity;
  final double basePrice;
  final double perKmRate;
  final IconData icon;

  const PorterVehicleType({
    required this.id,
    required this.name,
    required this.capacity,
    required this.basePrice,
    this.perKmRate = 15.0,
    required this.icon,
  });

  factory PorterVehicleType.fromJson(Map<String, dynamic> json) {
    IconData iconData = Icons.local_shipping_rounded;
    final nameLower = (json['name'] ?? '').toString().toLowerCase();
    if (nameLower.contains('bike')) {
      iconData = Icons.delivery_dining_rounded;
    } else if (nameLower.contains('mini')) {
      iconData = Icons.electric_rickshaw_rounded;
    } else if (nameLower.contains('pickup')) {
      iconData = Icons.airport_shuttle_rounded;
    } else if (nameLower.contains('ace')) {
      iconData = Icons.local_shipping_rounded;
    }

    return PorterVehicleType(
      id: json['id']?.toString() ?? '1',
      name: json['name']?.toString() ?? 'Mini Truck',
      capacity: json['description']?.toString() ?? '750 kg',
      basePrice: (json['base_price'] is num)
          ? (json['base_price'] as num).toDouble()
          : 350.0,
      perKmRate: (json['per_km_rate'] is num)
          ? (json['per_km_rate'] as num).toDouble()
          : 15.0,
      icon: iconData,
    );
  }
}

class PorterBookingModel {
  final String id;
  final String vehicleType;
  final String pickupAddress;
  final String dropAddress;
  final String itemsDescription;
  final String dateTime;
  final double estimatedPrice;
  final String status;
  final String estimatedArrival;

  const PorterBookingModel({
    required this.id,
    required this.vehicleType,
    required this.pickupAddress,
    required this.dropAddress,
    required this.itemsDescription,
    required this.dateTime,
    required this.estimatedPrice,
    required this.status,
    required this.estimatedArrival,
  });
}
