import 'package:flutter/material.dart';
import 'package:cooli/features/ride/model/ride_model.dart';

class RideRepo {
  RidePlace getDefaultPickup() {
    return const RidePlace(
      id: 'place_current',
      title: 'Current Location',
      address: 'Kaloor Junction, Ernakulam, Kochi',
      tag: 'Current',
      distanceKm: 0.0,
      etaMinutes: 0,
      icon: Icons.my_location_rounded,
      mapNormalizedPos: Offset(0.24, 0.68),
    );
  }

  RidePlace getDefaultDrop() {
    return const RidePlace(
      id: 'place_airport',
      title: 'Cochin International Airport',
      address: 'Airport Rd, Nedumbassery, Kochi',
      tag: 'Airport',
      distanceKm: 22.4,
      etaMinutes: 38,
      icon: Icons.flight_takeoff_rounded,
      mapNormalizedPos: Offset(0.78, 0.24),
    );
  }

  List<RidePlace> getSavedAndRecentPlaces() {
    return const [
      RidePlace(
        id: 'place_home',
        title: 'Home',
        address: 'Panampilly Nagar, Lane 4, Kochi',
        tag: 'Home',
        distanceKm: 5.8,
        etaMinutes: 14,
        icon: Icons.home_rounded,
        mapNormalizedPos: Offset(0.66, 0.42),
      ),
      RidePlace(
        id: 'place_work',
        title: 'Work',
        address: 'Infopark Phase 1, Kakkanad',
        tag: 'Work',
        distanceKm: 11.2,
        etaMinutes: 24,
        icon: Icons.work_rounded,
        mapNormalizedPos: Offset(0.76, 0.34),
      ),
      RidePlace(
        id: 'place_airport',
        title: 'Cochin International Airport',
        address: 'Airport Rd, Nedumbassery, Kochi',
        tag: 'Airport',
        distanceKm: 22.4,
        etaMinutes: 38,
        icon: Icons.flight_takeoff_rounded,
        mapNormalizedPos: Offset(0.78, 0.24),
      ),
      RidePlace(
        id: 'place_lulu',
        title: 'Lulu International Mall',
        address: 'Edappally Junction, NH 66, Kochi',
        tag: 'Recent',
        distanceKm: 6.4,
        etaMinutes: 16,
        icon: Icons.shopping_bag_rounded,
        mapNormalizedPos: Offset(0.58, 0.28),
      ),
      RidePlace(
        id: 'place_railway',
        title: 'Ernakulam South Railway Station',
        address: 'Station Rd, Jos Junction, Kochi',
        tag: 'Recent',
        distanceKm: 4.5,
        etaMinutes: 12,
        icon: Icons.train_rounded,
        mapNormalizedPos: Offset(0.42, 0.26),
      ),
      RidePlace(
        id: 'place_marine',
        title: 'Marine Drive Walkway',
        address: 'Shanmugham Rd, Ernakulam',
        tag: 'Recent',
        distanceKm: 5.2,
        etaMinutes: 15,
        icon: Icons.water_rounded,
        mapNormalizedPos: Offset(0.30, 0.30),
      ),
    ];
  }

  List<RideOption> getRideOptions() {
    return const [
      RideOption(
        id: 'opt_auto',
        name: 'Cooli Auto',
        description: 'Quick, affordable auto-rickshaw',
        baseFare: 30.0,
        perKmRate: 11.0,
        etaMinutes: 2,
        capacity: 3,
        imagePath: 'assets/images/rickshaw_3d.png',
        icon: Icons.electric_rickshaw_rounded,
        badge: 'Fastest',
      ),
      RideOption(
        id: 'opt_economy',
        name: 'Cooli Go',
        description: 'Affordable, compact everyday rides',
        baseFare: 45.0,
        perKmRate: 14.0,
        etaMinutes: 4,
        capacity: 4,
        imagePath: 'assets/images/ride_economy_car.png',
        icon: Icons.local_taxi_rounded,
      ),
      RideOption(
        id: 'opt_comfort',
        name: 'Premier',
        description: 'Comfortable sedans, top-rated drivers',
        baseFare: 70.0,
        perKmRate: 18.0,
        etaMinutes: 6,
        capacity: 4,
        imagePath: 'assets/images/ride_comfort_car.png',
        icon: Icons.directions_car_filled_rounded,
        badge: 'Popular',
      ),
      RideOption(
        id: 'opt_xl',
        name: 'Cooli XL',
        description: 'Spacious SUVs for groups & luggage',
        baseFare: 110.0,
        perKmRate: 24.0,
        etaMinutes: 8,
        capacity: 6,
        imagePath: 'assets/images/suv_3d.png',
        icon: Icons.airport_shuttle_rounded,
      ),
    ];
  }

  List<RidePaymentMethod> getPaymentMethods() {
    return const [
      RidePaymentMethod(
        id: 'upi',
        title: 'UPI',
        subtitle: 'Google Pay, PhonePe, Paytm',
        icon: Icons.account_balance_wallet_rounded,
      ),
      RidePaymentMethod(
        id: 'cash',
        title: 'Cash',
        subtitle: 'Pay driver directly at dropoff',
        icon: Icons.payments_rounded,
      ),
      RidePaymentMethod(
        id: 'card',
        title: 'Visa •••• 4821',
        subtitle: 'Personal Credit Card',
        icon: Icons.credit_card_rounded,
      ),
      RidePaymentMethod(
        id: 'wallet',
        title: 'Cooli Wallet',
        subtitle: 'Balance: ₹1,450',
        icon: Icons.account_balance_rounded,
      ),
    ];
  }

  DriverModel getAssignedDriver({String? rideOptionId}) {
    switch (rideOptionId) {
      case 'opt_auto':
        return const DriverModel(
          name: 'Suresh Babu',
          rating: 4.8,
          totalTrips: 1890,
          vehicleName: 'Bajaj RE Compact',
          vehicleColor: 'Yellow & Black',
          vehicleNumber: 'KL 07 CD 4812',
          arrivingTime: '2 min',
          phone: '+91 98470 11223',
          photoUrl: 'assets/images/ride_driver_avatar.png',
          otpPin: '4219',
        );
      case 'opt_economy':
        return const DriverModel(
          name: 'Arjun Nair',
          rating: 4.85,
          totalTrips: 1120,
          vehicleName: 'Maruti Suzuki Swift',
          vehicleColor: 'Silver',
          vehicleNumber: 'KL 07 EF 7390',
          arrivingTime: '4 min',
          phone: '+91 98470 55442',
          photoUrl: 'assets/images/ride_driver_avatar.png',
          otpPin: '4219',
        );
      case 'opt_xl':
        return const DriverModel(
          name: 'Vikram Menon',
          rating: 4.95,
          totalTrips: 2340,
          vehicleName: 'Toyota Innova Crysta',
          vehicleColor: 'Pearl White',
          vehicleNumber: 'KL 07 GH 9001',
          arrivingTime: '8 min',
          phone: '+91 98470 88991',
          photoUrl: 'assets/images/ride_driver_avatar.png',
          otpPin: '4219',
        );
      case 'opt_comfort':
      default:
        return const DriverModel(
          name: 'Rahul Kumar',
          rating: 4.9,
          totalTrips: 1420,
          vehicleName: 'Toyota Etios',
          vehicleColor: 'White',
          vehicleNumber: 'KL 07 AB 1234',
          arrivingTime: '6 min',
          phone: '+91 98765 43210',
          photoUrl: 'assets/images/ride_driver_avatar.png',
          otpPin: '4219',
        );
    }
  }

  List<String> getCancellationReasons() {
    return const [
      'Driver taking too long to arrive',
      'Changed my mind / Plans changed',
      'Entered wrong pickup location',
      'Driver asked me to cancel',
      'Found another ride',
    ];
  }

  List<String> getComplimentTags() {
    return const [
      'Spotless Car',
      'Smooth Driving',
      'Polite Driver',
      'Great Route',
    ];
  }

  List<String> getQuickChatReplies() {
    return const [
      "I'm at the pickup point",
      'On my way, 2 mins',
      'Please wait near main gate',
      'Call me when you arrive',
    ];
  }
}
