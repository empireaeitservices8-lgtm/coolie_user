import 'package:flutter/material.dart';

class TransportVehicleTypeModel {
  final int id;
  final int serviceId;
  final String name;
  final String description;
  final String icon;
  final String typeKey;
  final bool isActive;
  final IconData iconData;
  final String capacity;

  const TransportVehicleTypeModel({
    required this.id,
    required this.serviceId,
    required this.name,
    required this.description,
    required this.icon,
    required this.typeKey,
    this.isActive = true,
    required this.iconData,
    required this.capacity,
  });

  /// Map any display name, icon name, or alias to one of the backend supported truck types:
  /// open_body_10_20t, open_body_20_30t, container_20ft, container_40ft, tipper, flatbed
  static String resolveTruckTypeSlug(String input) {
    final lower = input.toLowerCase().trim().replaceAll(' ', '_');
    if (lower == 'tipper' || lower.contains('tipper')) {
      return 'tipper';
    }
    if (lower.contains('flatbed') || lower.contains('trailer')) {
      return 'flatbed';
    }
    if (lower.contains('container_40') ||
        lower.contains('40ft') ||
        lower.contains('40_ft')) {
      return 'container_40ft';
    }
    if (lower.contains('container')) {
      return 'container_20ft';
    }
    if (lower.contains('20_30') ||
        lower.contains('multi_axle') ||
        lower.contains('large')) {
      return 'open_body_20_30t';
    }
    if (lower.contains('10_20') ||
        lower.contains('open') ||
        lower.contains('medium') ||
        lower.contains('small') ||
        lower.contains('truck')) {
      return 'open_body_10_20t';
    }
    return lower;
  }

  factory TransportVehicleTypeModel.fromJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString() ?? 'Truck';
    final rawIcon = json['icon']?.toString().toLowerCase() ?? '';
    final rawDesc = json['description']?.toString() ?? '';
    final rawKey = json['type_key']?.toString() ??
        json['truck_type']?.toString() ??
        resolveTruckTypeSlug(rawName.isNotEmpty ? rawName : rawIcon);

    // Map icon string to Material IconData
    IconData resolvedIcon = Icons.local_shipping_rounded;
    final lowerName = rawName.toLowerCase();
    if (lowerName.contains('tipper') || rawKey == 'tipper') {
      resolvedIcon = Icons.fire_truck_rounded;
    } else if (rawIcon.contains('small') ||
        lowerName.contains('small') ||
        lowerName.contains('mini') ||
        lowerName.contains('pickup')) {
      resolvedIcon = Icons.airport_shuttle_rounded;
    } else if (rawIcon.contains('medium') || lowerName.contains('medium')) {
      resolvedIcon = Icons.fire_truck_rounded;
    } else if (rawIcon.contains('large') ||
        lowerName.contains('large') ||
        lowerName.contains('open')) {
      resolvedIcon = Icons.local_shipping_rounded;
    } else if (rawIcon.contains('container') ||
        lowerName.contains('container')) {
      resolvedIcon = Icons.inventory_2_rounded;
    } else if (rawIcon.contains('trailer') ||
        lowerName.contains('trailer') ||
        lowerName.contains('flatbed')) {
      resolvedIcon = Icons.rv_hookup_rounded;
    }

    // Determine standard tonnage capacity / subtitle guide
    String resolvedCapacity = '';
    if (lowerName.contains('tipper') || rawKey == 'tipper') {
      resolvedCapacity = '10 - 16 Ton';
    } else if (rawKey == 'open_body_10_20t') {
      resolvedCapacity = '10 - 20 Ton';
    } else if (rawKey == 'open_body_20_30t') {
      resolvedCapacity = '20 - 30 Ton';
    } else if (rawKey == 'container_20ft') {
      resolvedCapacity = '14 - 20 Ton';
    } else if (rawKey == 'container_40ft') {
      resolvedCapacity = '20 - 32 Ton';
    } else if (rawKey == 'flatbed') {
      resolvedCapacity = '25 - 40 Ton';
    } else if (lowerName.contains('small')) {
      resolvedCapacity = 'Up to 3.5 Ton';
    } else if (lowerName.contains('medium')) {
      resolvedCapacity = '3.5 - 10 Ton';
    } else if (lowerName.contains('large')) {
      resolvedCapacity = '10 - 25 Ton';
    } else if (lowerName.contains('container')) {
      resolvedCapacity = '7.5 - 32 Ton';
    } else if (lowerName.contains('trailer')) {
      resolvedCapacity = '16 - 43 Ton';
    } else if (rawDesc.isNotEmpty) {
      resolvedCapacity = rawDesc;
    } else {
      resolvedCapacity = 'Commercial';
    }

    return TransportVehicleTypeModel(
      id: (json['id'] is num) ? (json['id'] as num).toInt() : 0,
      serviceId:
          (json['service_id'] is num) ? (json['service_id'] as num).toInt() : 10,
      name: rawName,
      description: rawDesc,
      icon: rawIcon,
      typeKey: rawKey,
      isActive: json['is_active'] != false,
      iconData: resolvedIcon,
      capacity: resolvedCapacity,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'service_id': serviceId,
        'name': name,
        'description': description,
        'icon': icon,
        'type_key': typeKey,
        'is_active': isActive,
      };

  /// Default vehicle types matching the backend transport load choices:
  /// tipper, open_body_10_20t, open_body_20_30t, container_20ft, container_40ft, flatbed
  static List<TransportVehicleTypeModel> getDefaultVehicleTypes() {
    return const [
      TransportVehicleTypeModel(
        id: 1,
        serviceId: 10,
        name: 'Tipper',
        description: 'Hydraulic tipper for sand, stone & aggregates',
        icon: 'tipper',
        typeKey: 'tipper',
        isActive: true,
        iconData: Icons.fire_truck_rounded,
        capacity: '10 - 16 Ton',
      ),
      TransportVehicleTypeModel(
        id: 2,
        serviceId: 10,
        name: 'Open Body 10-20T',
        description: 'Heavy material, steel & construction load',
        icon: 'open_body_10_20t',
        typeKey: 'open_body_10_20t',
        isActive: true,
        iconData: Icons.local_shipping_rounded,
        capacity: '10 - 20 Ton',
      ),
      TransportVehicleTypeModel(
        id: 3,
        serviceId: 10,
        name: 'Open Body 20-30T',
        description: 'Multi-axle open body for heavy loads',
        icon: 'open_body_20_30t',
        typeKey: 'open_body_20_30t',
        isActive: true,
        iconData: Icons.local_shipping_outlined,
        capacity: '20 - 30 Ton',
      ),
      TransportVehicleTypeModel(
        id: 4,
        serviceId: 10,
        name: 'Container 20ft',
        description: 'Weather-proof 20ft container box',
        icon: 'container_20ft',
        typeKey: 'container_20ft',
        isActive: true,
        iconData: Icons.inventory_2_rounded,
        capacity: '14 - 20 Ton',
      ),
      TransportVehicleTypeModel(
        id: 5,
        serviceId: 10,
        name: 'Container 40ft',
        description: 'Large 40ft multi-axle container',
        icon: 'container_40ft',
        typeKey: 'container_40ft',
        isActive: true,
        iconData: Icons.inventory_rounded,
        capacity: '20 - 32 Ton',
      ),
      TransportVehicleTypeModel(
        id: 6,
        serviceId: 10,
        name: 'Flatbed',
        description: 'Flatbed trailer for machinery & pipes',
        icon: 'flatbed',
        typeKey: 'flatbed',
        isActive: true,
        iconData: Icons.rv_hookup_rounded,
        capacity: '25 - 40 Ton',
      ),
    ];
  }
}
