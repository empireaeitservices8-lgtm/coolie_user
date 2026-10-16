import 'package:flutter/material.dart';

class AddressModel {
  final int id;
  final int user;
  final String addressType; // 'home', 'work', 'other'
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
  final String? createdAt;
  final String? updatedAt;

  const AddressModel({
    required this.id,
    required this.user,
    required this.addressType,
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
    this.createdAt,
    this.updatedAt,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      user: json['user'] is int
          ? json['user'] as int
          : int.tryParse(json['user']?.toString() ?? '') ?? 1,
      addressType: (json['address_type']?.toString().isNotEmpty == true)
          ? json['address_type'].toString().toLowerCase()
          : 'home',
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
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user,
      'address_type': addressType,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'landmark': landmark,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'latitude': latitude?.toStringAsFixed(6) ?? '12.971600',
      'longitude': longitude?.toStringAsFixed(6) ?? '77.594600',
      'is_default': isDefault,
    };
  }

  String get typeDisplay {
    switch (addressType.toLowerCase()) {
      case 'home':
        return 'Home';
      case 'work':
        return 'Work';
      case 'other':
      default:
        return 'Other';
    }
  }

  IconData get typeIcon {
    switch (addressType.toLowerCase()) {
      case 'home':
        return Icons.home_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'other':
      default:
        return Icons.location_on_rounded;
    }
  }

  Color get typeColor {
    switch (addressType.toLowerCase()) {
      case 'home':
        return const Color(0xFF2563EB); // Royal Blue
      case 'work':
        return const Color(0xFFD97706); // Amber
      case 'other':
      default:
        return const Color(0xFF0D9488); // Teal
    }
  }

  String get formattedAddress {
    final parts = <String>[];
    if (addressLine1.isNotEmpty) parts.add(addressLine1);
    if (addressLine2.isNotEmpty) parts.add(addressLine2);
    if (landmark.isNotEmpty) parts.add('Near $landmark');
    if (city.isNotEmpty && state.isNotEmpty) {
      parts.add('$city, $state');
    } else if (city.isNotEmpty) {
      parts.add(city);
    } else if (state.isNotEmpty) {
      parts.add(state);
    }
    if (postalCode.isNotEmpty) parts.add(postalCode);
    return parts.join(', ');
  }

  AddressModel copyWith({
    int? id,
    int? user,
    String? addressType,
    String? addressLine1,
    String? addressLine2,
    String? landmark,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    double? latitude,
    double? longitude,
    bool? isDefault,
    String? createdAt,
    String? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      user: user ?? this.user,
      addressType: addressType ?? this.addressType,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
