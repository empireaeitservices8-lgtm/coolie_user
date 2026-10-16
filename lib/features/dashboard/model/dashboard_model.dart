import 'package:flutter/material.dart';

class ServiceCategory {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String route;

  const ServiceCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.route,
  });
}

class RecentActivityItem {
  final String id;
  final String title;
  final String status;
  final String time;
  final IconData icon;
  final Color iconColor;
  final double amount;

  const RecentActivityItem({
    required this.id,
    required this.title,
    required this.status,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.amount,
  });
}

class HomeVehicleTypeItem {
  final int id;
  final int serviceId;
  final String name;
  final String description;
  final String icon;
  final bool isActive;
  final String serviceName;
  final String serviceDisplayName;

  const HomeVehicleTypeItem({
    required this.id,
    required this.serviceId,
    required this.name,
    required this.description,
    required this.icon,
    required this.isActive,
    this.serviceName = '',
    this.serviceDisplayName = '',
  });

  factory HomeVehicleTypeItem.fromJson(Map<String, dynamic> json) {
    return HomeVehicleTypeItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      serviceId: json['service'] is int
          ? json['service']
          : int.tryParse(json['service']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      isActive: json['is_active'] == true,
      serviceName: json['service_name']?.toString() ?? '',
      serviceDisplayName: json['service_display_name']?.toString() ?? '',
    );
  }
}

class HomeServiceItem {
  final int id;
  final String name;
  final String displayName;
  final String description;
  final String icon;
  final bool isActive;
  final List<HomeVehicleTypeItem> vehicleTypes;

  const HomeServiceItem({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.icon,
    required this.isActive,
    required this.vehicleTypes,
  });

  factory HomeServiceItem.fromJson(Map<String, dynamic> json) {
    return HomeServiceItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      isActive: json['is_active'] == true,
      vehicleTypes: (json['vehicle_types'] as List?)
              ?.map((v) => HomeVehicleTypeItem.fromJson(Map<String, dynamic>.from(v as Map)))
              .toList() ??
          [],
    );
  }
}

class HomeApiResponse {
  final List<HomeServiceItem> services;
  final List<HomeVehicleTypeItem> vehicleTypes;

  const HomeApiResponse({
    required this.services,
    required this.vehicleTypes,
  });

  factory HomeApiResponse.fromJson(Map<String, dynamic> json) {
    return HomeApiResponse(
      services: (json['services'] as List?)
              ?.map((s) => HomeServiceItem.fromJson(Map<String, dynamic>.from(s as Map)))
              .toList() ??
          [],
      vehicleTypes: (json['vehicle_types'] as List?)
              ?.map((v) => HomeVehicleTypeItem.fromJson(Map<String, dynamic>.from(v as Map)))
              .toList() ??
          [],
    );
  }
}

const List<HomeServiceItem> initialHomeServices = [
  HomeServiceItem(
    id: 8,
    name: 'ride',
    displayName: 'Ride',
    description: 'Book a passenger vehicle',
    icon: 'car',
    isActive: true,
    vehicleTypes: [
      HomeVehicleTypeItem(
        id: 10,
        serviceId: 8,
        name: 'Bike',
        description: 'Two-wheeler ride',
        icon: 'bike',
        isActive: true,
        serviceName: 'ride',
        serviceDisplayName: 'Ride',
      ),
      HomeVehicleTypeItem(
        id: 11,
        serviceId: 8,
        name: 'Auto',
        description: 'Three-wheeler auto rickshaw',
        icon: 'auto',
        isActive: true,
        serviceName: 'ride',
        serviceDisplayName: 'Ride',
      ),
      HomeVehicleTypeItem(
        id: 12,
        serviceId: 8,
        name: 'Car',
        description: 'Standard car ride',
        icon: 'car',
        isActive: true,
        serviceName: 'ride',
        serviceDisplayName: 'Ride',
      ),
      HomeVehicleTypeItem(
        id: 13,
        serviceId: 8,
        name: 'Premium car',
        description: 'Premium car ride',
        icon: 'premium_car',
        isActive: true,
        serviceName: 'ride',
        serviceDisplayName: 'Ride',
      ),
      HomeVehicleTypeItem(
        id: 24,
        serviceId: 8,
        name: 'BMW',
        description: 'VIP RIDE',
        icon: '',
        isActive: true,
        serviceName: 'ride',
        serviceDisplayName: 'Ride',
      ),
    ],
  ),
  HomeServiceItem(
    id: 9,
    name: 'goods',
    displayName: 'Goods',
    description: 'Move goods locally',
    icon: 'box',
    isActive: true,
    vehicleTypes: [
      HomeVehicleTypeItem(
        id: 14,
        serviceId: 9,
        name: 'Bike delivery',
        description: 'Two-wheeler for small goods delivery',
        icon: 'delivery_bike',
        isActive: true,
        serviceName: 'goods',
        serviceDisplayName: 'Goods',
      ),
      HomeVehicleTypeItem(
        id: 15,
        serviceId: 9,
        name: 'Mini truck',
        description: 'Small truck for local goods',
        icon: 'mini_truck',
        isActive: true,
        serviceName: 'goods',
        serviceDisplayName: 'Goods',
      ),
      HomeVehicleTypeItem(
        id: 16,
        serviceId: 9,
        name: 'Pickup truck',
        description: 'Pickup truck for local goods',
        icon: 'pickup_truck',
        isActive: true,
        serviceName: 'goods',
        serviceDisplayName: 'Goods',
      ),
      HomeVehicleTypeItem(
        id: 17,
        serviceId: 9,
        name: 'Tata Ace',
        description: 'Tata Ace mini truck',
        icon: 'tata_ace',
        isActive: true,
        serviceName: 'goods',
        serviceDisplayName: 'Goods',
      ),
    ],
  ),
  HomeServiceItem(
    id: 10,
    name: 'transport',
    displayName: 'Transport',
    description: 'Move goods between cities/districts/states',
    icon: 'truck',
    isActive: true,
    vehicleTypes: [
      HomeVehicleTypeItem(
        id: 18,
        serviceId: 10,
        name: 'Small truck',
        description: 'Small commercial truck',
        icon: 'small_truck',
        isActive: true,
        serviceName: 'transport',
        serviceDisplayName: 'Transport',
      ),
      HomeVehicleTypeItem(
        id: 19,
        serviceId: 10,
        name: 'Medium truck',
        description: 'Medium commercial truck',
        icon: 'medium_truck',
        isActive: true,
        serviceName: 'transport',
        serviceDisplayName: 'Transport',
      ),
      HomeVehicleTypeItem(
        id: 20,
        serviceId: 10,
        name: 'Large truck',
        description: 'Large commercial truck',
        icon: 'large_truck',
        isActive: true,
        serviceName: 'transport',
        serviceDisplayName: 'Transport',
      ),
      HomeVehicleTypeItem(
        id: 21,
        serviceId: 10,
        name: 'Container',
        description: 'Container truck',
        icon: 'container',
        isActive: true,
        serviceName: 'transport',
        serviceDisplayName: 'Transport',
      ),
      HomeVehicleTypeItem(
        id: 22,
        serviceId: 10,
        name: 'Trailer',
        description: 'Trailer truck',
        icon: 'trailer',
        isActive: true,
        serviceName: 'transport',
        serviceDisplayName: 'Transport',
      ),
    ],
  ),
];
