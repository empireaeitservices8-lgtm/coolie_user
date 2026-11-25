import 'package:flutter/material.dart';

enum RideTripStage {
  idle,
  confirmingPickup,
  searchingDriver,
  driverEnRoute,
  driverArrived,
  inProgress,
  completed,
  cancelled,
}

enum RideScheduleType { now, later }

class RidePlace {
  final String id;
  final String title;
  final String address;
  final String tag;
  final double distanceKm;
  final int etaMinutes;
  final IconData icon;
  final Offset mapNormalizedPos;

  const RidePlace({
    required this.id,
    required this.title,
    required this.address,
    required this.tag,
    required this.distanceKm,
    required this.etaMinutes,
    required this.icon,
    required this.mapNormalizedPos,
  });
}

class FareBreakdown {
  final double baseFare;
  final double distanceFare;
  final double platformFee;
  final double discount;

  const FareBreakdown({
    required this.baseFare,
    required this.distanceFare,
    required this.platformFee,
    this.discount = 0,
  });

  double get total {
    final sum = baseFare + distanceFare + platformFee - discount;
    return sum < 30 ? 30 : sum;
  }
}

class RideOption {
  final String id;
  final String name;
  final String description;
  final double baseFare;
  final double perKmRate;
  final int etaMinutes;
  final int capacity;
  final String imagePath;
  final IconData icon;
  final String? badge;

  const RideOption({
    required this.id,
    required this.name,
    required this.description,
    required this.baseFare,
    required this.perKmRate,
    required this.etaMinutes,
    required this.capacity,
    required this.imagePath,
    required this.icon,
    this.badge,
  });

  /// Legacy compatibility getter for default 12 km trip
  double get fare => calculateFare(12.0);

  String get eta => '$etaMinutes min away';

  double calculateFare(double distanceKm, {double discount = 0}) {
    final raw = baseFare + (distanceKm * perKmRate) + 10.0 - discount;
    final rounded = (raw / 5).round() * 5.0;
    return rounded < 30 ? 30 : rounded;
  }

  FareBreakdown getFareBreakdown(double distanceKm, {double discount = 0}) {
    final total = calculateFare(distanceKm, discount: discount);
    const platformFee = 10.0;
    final distanceFare = (total + discount - baseFare - platformFee).clamp(0.0, double.infinity);
    return FareBreakdown(
      baseFare: baseFare,
      distanceFare: distanceFare,
      platformFee: platformFee,
      discount: discount,
    );
  }
}

class RidePaymentMethod {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const RidePaymentMethod({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class DriverModel {
  final String name;
  final double rating;
  final int totalTrips;
  final String vehicleName;
  final String vehicleColor;
  final String vehicleNumber;
  final String arrivingTime;
  final String phone;
  final String photoUrl;
  final String otpPin;

  const DriverModel({
    required this.name,
    required this.rating,
    required this.totalTrips,
    required this.vehicleName,
    required this.vehicleColor,
    required this.vehicleNumber,
    required this.arrivingTime,
    required this.phone,
    required this.photoUrl,
    required this.otpPin,
  });
}

class RideChatMessage {
  final String text;
  final bool isRider;
  final String timeLabel;

  const RideChatMessage({
    required this.text,
    required this.isRider,
    required this.timeLabel,
  });
}
