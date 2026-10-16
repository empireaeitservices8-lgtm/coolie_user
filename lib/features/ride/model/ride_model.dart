import 'dart:math' as math;
import 'package:flutter/material.dart';

class RideOption {
  final String id;
  final int? service;
  final String name;
  final String description;
  final String iconName;
  final bool isActive;
  final double fare;
  final double? originalFare;
  final String eta;
  final String capacity;
  final String? tag;
  final Color? tagColor;
  final String imageAsset;
  final IconData icon;
  final RideFareEstimate? fareEstimate;

  const RideOption({
    required this.id,
    this.service,
    required this.name,
    required this.description,
    this.iconName = '',
    this.isActive = true,
    required this.fare,
    this.originalFare,
    required this.eta,
    this.capacity = '4',
    this.tag,
    this.tagColor,
    this.imageAsset = 'assets/images/dash_ride_car_clean.png',
    required this.icon,
    this.fareEstimate,
  });

  factory RideOption.fromJson(Map<String, dynamic> json) {
    final idStr = json['id']?.toString() ?? '10';
    final name = json['name']?.toString() ?? 'Car';
    final description = json['description']?.toString() ?? 'Standard ride';
    final iconName = json['icon']?.toString() ?? '';
    final isActive = json['is_active'] != false;
    final nameLower = name.toLowerCase();

    IconData icon = Icons.directions_car_filled_rounded;
    String imageAsset = 'assets/images/dash_ride_car_clean.png';
    String capacity = '4';
    String eta = '4 min away';
    String? tag;
    Color? tagColor;
    double fare = 220.0;
    double? originalFare = 260.0;

    if (nameLower.contains('bike')) {
      icon = Icons.two_wheeler_rounded;
      imageAsset = 'assets/images/automobile_3d.png';
      capacity = '1';
      eta = '2 min away';
      tag = 'Quickest';
      tagColor = const Color(0xFF10B981);
      fare = 65.0;
      originalFare = 80.0;
    } else if (nameLower.contains('auto')) {
      icon = Icons.electric_rickshaw_rounded;
      imageAsset = 'assets/images/rickshaw_3d.png';
      capacity = '3';
      eta = '3 min away';
      tag = 'Affordable';
      tagColor = const Color(0xFF059669);
      fare = 120.0;
      originalFare = 145.0;
    } else if (nameLower.contains('bmw')) {
      icon = Icons.stars_rounded;
      imageAsset = 'assets/images/ride_comfort_car.png';
      capacity = '4';
      eta = '6 min away';
      tag = 'VIP Luxury';
      tagColor = const Color(0xFFD97706);
      fare = 590.0;
      originalFare = 680.0;
    } else if (nameLower.contains('premium')) {
      icon = Icons.airport_shuttle_rounded;
      imageAsset = 'assets/images/ride_premium_car.png';
      capacity = '4';
      eta = '5 min away';
      tag = 'Top Rated';
      tagColor = const Color(0xFF7C3AED);
      fare = 340.0;
      originalFare = 390.0;
    } else {
      // Car / Standard
      icon = Icons.directions_car_filled_rounded;
      imageAsset = 'assets/images/dash_ride_car_clean.png';
      capacity = '4';
      eta = '4 min away';
      tag = 'Most Popular';
      tagColor = const Color(0xFF2563EB);
      fare = 220.0;
      originalFare = 260.0;
    }

    if (json['base_fare'] is num) {
      fare = (json['base_fare'] as num).toDouble();
    } else if (json['estimated_fare'] is num) {
      fare = (json['estimated_fare'] as num).toDouble();
    }

    return RideOption(
      id: idStr,
      service: json['service'] is int ? json['service'] as int : null,
      name: name,
      description: description,
      iconName: iconName,
      isActive: isActive,
      fare: fare,
      originalFare: originalFare,
      eta: eta,
      capacity: capacity,
      tag: tag,
      tagColor: tagColor,
      imageAsset: imageAsset,
      icon: icon,
    );
  }

  RideOption copyWith({
    String? id,
    int? service,
    String? name,
    String? description,
    String? iconName,
    bool? isActive,
    double? fare,
    double? originalFare,
    String? eta,
    String? capacity,
    String? tag,
    Color? tagColor,
    String? imageAsset,
    IconData? icon,
    RideFareEstimate? fareEstimate,
  }) {
    return RideOption(
      id: id ?? this.id,
      service: service ?? this.service,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      isActive: isActive ?? this.isActive,
      fare: fare ?? this.fare,
      originalFare: originalFare ?? this.originalFare,
      eta: eta ?? this.eta,
      capacity: capacity ?? this.capacity,
      tag: tag ?? this.tag,
      tagColor: tagColor ?? this.tagColor,
      imageAsset: imageAsset ?? this.imageAsset,
      icon: icon ?? this.icon,
      fareEstimate: fareEstimate ?? this.fareEstimate,
    );
  }
}

class RideFareEstimate {
  final int vehicleTypeId;
  final int? service;
  final String vehicleName;
  final String description;
  final String icon;
  final bool isActive;
  final double distanceKm;
  final double baseFare;
  final double distanceCharge;
  final double surgeMultiplier;
  final double additionalServiceCharge;
  final double minimumFare;
  final double estimatedFare;
  final int estimatedTravelTime;

  const RideFareEstimate({
    required this.vehicleTypeId,
    this.service,
    required this.vehicleName,
    required this.description,
    this.icon = '',
    this.isActive = true,
    required this.distanceKm,
    required this.baseFare,
    required this.distanceCharge,
    required this.surgeMultiplier,
    required this.additionalServiceCharge,
    required this.minimumFare,
    required this.estimatedFare,
    required this.estimatedTravelTime,
  });

  factory RideFareEstimate.fromJson(Map<String, dynamic> json) {
    final vt = (json['vehicle_type'] is Map<String, dynamic>)
        ? json['vehicle_type'] as Map<String, dynamic>
        : (json['vehicle_type'] is Map ? Map<String, dynamic>.from(json['vehicle_type'] as Map) : <String, dynamic>{});

    return RideFareEstimate(
      vehicleTypeId: vt['id'] is int ? vt['id'] as int : int.tryParse(vt['id']?.toString() ?? '') ?? 0,
      service: vt['service'] is int ? vt['service'] as int : null,
      vehicleName: vt['name']?.toString() ?? '',
      description: vt['description']?.toString() ?? '',
      icon: vt['icon']?.toString() ?? '',
      isActive: vt['is_active'] != false,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      baseFare: (json['base_fare'] as num?)?.toDouble() ?? 0.0,
      distanceCharge: (json['distance_charge'] as num?)?.toDouble() ?? 0.0,
      surgeMultiplier: (json['surge_multiplier'] as num?)?.toDouble() ?? 1.0,
      additionalServiceCharge: (json['additional_service_charge'] as num?)?.toDouble() ?? 0.0,
      minimumFare: (json['minimum_fare'] as num?)?.toDouble() ?? 0.0,
      estimatedFare: (json['estimated_fare'] as num?)?.toDouble() ?? 0.0,
      estimatedTravelTime: (json['estimated_travel_time'] as num?)?.toInt() ?? 0,
    );
  }
}

class RideCalculateFareResponse {
  final String pickupAddress;
  final String dropAddress;
  final double distanceKm;
  final List<RideFareEstimate> estimates;
  final String? error;

  const RideCalculateFareResponse({
    required this.pickupAddress,
    required this.dropAddress,
    required this.distanceKm,
    required this.estimates,
    this.error,
  });

  factory RideCalculateFareResponse.fromJson(Map<String, dynamic> json) {
    final rawEstimates = json['estimates'] as List?;
    final list = rawEstimates != null
        ? rawEstimates.map((e) => RideFareEstimate.fromJson(Map<String, dynamic>.from(e as Map))).toList()
        : <RideFareEstimate>[];

    return RideCalculateFareResponse(
      pickupAddress: json['pickup_address']?.toString() ?? '',
      dropAddress: json['drop_address']?.toString() ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      estimates: list,
      error: json['error']?.toString(),
    );
  }
}

class DriverModel {
  final String name;
  final double rating;
  final String vehicleName;
  final String vehicleNumber;
  final String arrivingTime;
  final String photoUrl;

  const DriverModel({
    required this.name,
    required this.rating,
    required this.vehicleName,
    required this.vehicleNumber,
    required this.arrivingTime,
    required this.photoUrl,
  });
}

class RideBookingData {
  final int id;
  final int user;
  final int vehicleType;
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String dropAddress;
  final double dropLatitude;
  final double dropLongitude;
  final int numberOfPassengers;
  final double? distanceKm;
  final double? estimatedFare;
  final int? estimatedTravelTime;
  final double? finalFare;
  final double? actualDistanceKm;
  final int? actualTravelTime;
  final String status;
  final String? scheduledPickupTime;
  final String? driverAssignedTime;
  final String? rideStartedTime;
  final String? rideCompletedTime;
  final String? createdAt;
  final String? updatedAt;
  final String? userMobile;
  final String? vehicleTypeName;
  final String? vehicleTypeService;
  final String? pickupInstructions;
  final String? dropInstructions;
  final String? driverName;
  final String? driverMobile;
  final String? vehicleNumber;

  const RideBookingData({
    required this.id,
    required this.user,
    required this.vehicleType,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropAddress,
    required this.dropLatitude,
    required this.dropLongitude,
    required this.numberOfPassengers,
    this.distanceKm,
    this.estimatedFare,
    this.estimatedTravelTime,
    this.finalFare,
    this.actualDistanceKm,
    this.actualTravelTime,
    required this.status,
    this.scheduledPickupTime,
    this.driverAssignedTime,
    this.rideStartedTime,
    this.rideCompletedTime,
    this.createdAt,
    this.updatedAt,
    this.userMobile,
    this.vehicleTypeName,
    this.vehicleTypeService,
    this.pickupInstructions,
    this.dropInstructions,
    this.driverName,
    this.driverMobile,
    this.vehicleNumber,
  });

  factory RideBookingData.fromJson(Map<String, dynamic> json) {
    return RideBookingData(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      user: json['user'] is int ? json['user'] as int : int.tryParse(json['user']?.toString() ?? '') ?? 1,
      vehicleType: json['vehicle_type'] is int
          ? json['vehicle_type'] as int
          : int.tryParse(json['vehicle_type']?.toString() ?? '') ?? 10,
      pickupAddress: json['pickup_address']?.toString() ?? '',
      pickupLatitude: (json['pickup_latitude'] is num)
          ? (json['pickup_latitude'] as num).toDouble()
          : double.tryParse(json['pickup_latitude']?.toString() ?? '') ?? 0.0,
      pickupLongitude: (json['pickup_longitude'] is num)
          ? (json['pickup_longitude'] as num).toDouble()
          : double.tryParse(json['pickup_longitude']?.toString() ?? '') ?? 0.0,
      dropAddress: json['drop_address']?.toString() ?? '',
      dropLatitude: (json['drop_latitude'] is num)
          ? (json['drop_latitude'] as num).toDouble()
          : double.tryParse(json['drop_latitude']?.toString() ?? '') ?? 0.0,
      dropLongitude: (json['drop_longitude'] is num)
          ? (json['drop_longitude'] as num).toDouble()
          : double.tryParse(json['drop_longitude']?.toString() ?? '') ?? 0.0,
      numberOfPassengers: json['number_of_passengers'] is int
          ? json['number_of_passengers'] as int
          : int.tryParse(json['number_of_passengers']?.toString() ?? '') ?? 1,
      distanceKm: (json['distance_km'] is num)
          ? (json['distance_km'] as num).toDouble()
          : double.tryParse(json['distance_km']?.toString() ?? ''),
      estimatedFare: (json['estimated_fare'] is num)
          ? (json['estimated_fare'] as num).toDouble()
          : double.tryParse(json['estimated_fare']?.toString() ?? ''),
      estimatedTravelTime: (json['estimated_travel_time'] is num)
          ? (json['estimated_travel_time'] as num).toInt()
          : int.tryParse(json['estimated_travel_time']?.toString() ?? ''),
      finalFare: (json['final_fare'] is num)
          ? (json['final_fare'] as num).toDouble()
          : double.tryParse(json['final_fare']?.toString() ?? ''),
      actualDistanceKm: (json['actual_distance_km'] is num)
          ? (json['actual_distance_km'] as num).toDouble()
          : double.tryParse(json['actual_distance_km']?.toString() ?? ''),
      actualTravelTime: (json['actual_travel_time'] is num)
          ? (json['actual_travel_time'] as num).toInt()
          : int.tryParse(json['actual_travel_time']?.toString() ?? ''),
      status: json['status']?.toString() ?? 'pending',
      scheduledPickupTime: json['scheduled_pickup_time']?.toString(),
      driverAssignedTime: json['driver_assigned_time']?.toString(),
      rideStartedTime: json['ride_started_time']?.toString(),
      rideCompletedTime: json['ride_completed_time']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      userMobile: json['user_mobile']?.toString(),
      vehicleTypeName: json['vehicle_type_name']?.toString(),
      vehicleTypeService: json['vehicle_type_service']?.toString(),
      pickupInstructions: json['pickup_instructions']?.toString(),
      dropInstructions: json['drop_instructions']?.toString(),
      driverName: json['driver_name']?.toString(),
      driverMobile: json['driver_mobile']?.toString(),
      vehicleNumber: json['vehicle_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user': user,
    'vehicle_type': vehicleType,
    'pickup_address': pickupAddress,
    'pickup_latitude': pickupLatitude,
    'pickup_longitude': pickupLongitude,
    'drop_address': dropAddress,
    'drop_latitude': dropLatitude,
    'drop_longitude': dropLongitude,
    'number_of_passengers': numberOfPassengers,
    'distance_km': distanceKm,
    'estimated_fare': estimatedFare,
    'estimated_travel_time': estimatedTravelTime,
    'final_fare': finalFare,
    'actual_distance_km': actualDistanceKm,
    'actual_travel_time': actualTravelTime,
    'status': status,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'user_mobile': userMobile,
    'vehicle_type_name': vehicleTypeName,
    'vehicle_type_service': vehicleTypeService,
    'pickup_instructions': pickupInstructions,
    'drop_instructions': dropInstructions,
    'driver_name': driverName,
    'driver_mobile': driverMobile,
    'vehicle_number': vehicleNumber,
  };

  String get statusBadgeLabel {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'FINDING DRIVER';
      case 'driver_assigned':
        return 'DRIVER ASSIGNED';
      case 'in_progress':
      case 'started':
        return 'ON TRIP';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  double get calculatedDistanceKm {
    if (distanceKm != null && distanceKm! > 0) return distanceKm!;
    if (actualDistanceKm != null && actualDistanceKm! > 0) {
      return actualDistanceKm!;
    }
    if (pickupLatitude != 0.0 && dropLatitude != 0.0) {
      const double p = 0.017453292519943295;
      final double a = 0.5 -
          math.cos((dropLatitude - pickupLatitude) * p) / 2 +
          math.cos(pickupLatitude * p) *
              math.cos(dropLatitude * p) *
              (1 - math.cos((dropLongitude - pickupLongitude) * p)) /
              2;
      return 12742 * math.asin(math.sqrt(a));
    }
    return 0.0;
  }

  String get displayFare {
    if (finalFare != null && finalFare! > 0) {
      return '₹ ${finalFare!.toStringAsFixed(0)}';
    }
    if (estimatedFare != null && estimatedFare! > 0) {
      return '₹ ${estimatedFare!.toStringAsFixed(0)}';
    }
    final dist = calculatedDistanceKm;
    if (dist > 0) {
      double rate = 25.0;
      double base = 50.0;
      if (vehicleTypeName?.toLowerCase().contains('bike') == true) {
        rate = 12.0;
        base = 30.0;
      } else if (vehicleTypeName?.toLowerCase().contains('auto') == true) {
        rate = 18.0;
        base = 40.0;
      }
      final computed = (base + (dist * rate)).round();
      return '₹ $computed';
    }
    return 'Standard Fare';
  }

  String get formattedDate {
    if (createdAt == null || createdAt!.isEmpty) return 'Recent Ride';
    try {
      final dt = DateTime.parse(createdAt!).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final m = months[dt.month - 1];
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} $m ${dt.year} • $h:$min $ampm';
    } catch (_) {
      return createdAt!.split('T').first;
    }
  }

  IconData get vehicleIcon {
    final name = (vehicleTypeName ?? '').toLowerCase();
    if (name.contains('bike')) return Icons.two_wheeler_rounded;
    if (name.contains('auto')) return Icons.electric_rickshaw_rounded;
    return Icons.directions_car_filled_rounded;
  }
}

class RideBookingResponse {
  final String message;
  final RideBookingData? booking;
  final bool success;
  final String? error;

  const RideBookingResponse({
    required this.message,
    this.booking,
    this.success = true,
    this.error,
  });

  factory RideBookingResponse.fromJson(Map<String, dynamic> json) {
    RideBookingData? bookingData;
    if (json['booking'] is Map) {
      bookingData = RideBookingData.fromJson(Map<String, dynamic>.from(json['booking'] as Map));
    } else if (json['id'] != null) {
      bookingData = RideBookingData.fromJson(json);
    }

    final hasError = json.containsKey('error') || json.containsKey('detail');
    final msg = json['message']?.toString() ??
        json['error']?.toString() ??
        json['detail']?.toString() ??
        'Ride booking processed';

    return RideBookingResponse(
      message: msg,
      booking: bookingData,
      success: !hasError && bookingData != null,
      error: json['error']?.toString() ?? json['detail']?.toString(),
    );
  }
}

