import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cooli/features/ride/model/ride_model.dart';
import 'package:cooli/services/web_api_services.dart';
import 'package:cooli/utils/urls.dart';

class RideRepo {
  final Dio _dio;

  RideRepo({Dio? dio}) : _dio = dio ?? WebAPIService().dio;

  /// Fetch Vehicle Types: GET /ride/vehicle-types/
  Future<List<RideOption>> fetchVehicleTypes() async {
    try {
      final response = await _dio.get(
        urlRideVehicleTypes,
        options: Options(headers: {'Accept': 'application/json'}),
      );
      if (response.data is List) {
        final list = (response.data as List)
            .map((item) => RideOption.fromJson(item as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      debugPrint('[RideRepo] fetchVehicleTypes error: $e');
    }
    return getRideOptions();
  }

  /// Calculate Fare: POST /ride/calculate-fare/
  Future<RideCalculateFareResponse?> calculateFare({
    required String pickupAddress,
    required int vehicleTypeId,
    required double pickupLatitude,
    required double pickupLongitude,
    required String dropAddress,
    required double dropLatitude,
    required double dropLongitude,
  }) async {
    final payload = {
      'pickup_address': pickupAddress,
      'vehicle_type_id': vehicleTypeId,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'drop_address': dropAddress,
      'drop_latitude': dropLatitude,
      'drop_longitude': dropLongitude,
    };
    try {
      final response = await _dio.post(
        urlRideCalculateFare,
        data: payload,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (response.data is Map) {
        return RideCalculateFareResponse.fromJson(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      debugPrint('[RideRepo] calculateFare error: $e');
    }
    return null;
  }

  /// Create Ride Booking: POST /ride/bookings/
  Future<RideBookingResponse?> createRideBooking(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        urlRideBookings,
        data: payload,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }),
      );
      if (response.data is Map) {
        return RideBookingResponse.fromJson(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      debugPrint('[RideRepo] createRideBooking error: $e');
      if (e is DioException && e.response?.data != null && e.response!.data is Map) {
        return RideBookingResponse.fromJson(Map<String, dynamic>.from(e.response!.data as Map));
      }
    }
    return null;
  }

  /// Fetch User Ride Bookings: GET /ride/bookings/list/?user_id={userId}
  Future<List<RideBookingData>> fetchRideBookings({int? userId}) async {
    final uid = (userId != null && userId > 0) ? userId : 1;
    try {
      final response = await _dio.get(
        '$urlRideBookingsList?user_id=$uid',
        options: Options(
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 12),
        ),
      );

      List rawList = [];
      if (response.data is List) {
        rawList = response.data as List;
      } else if (response.data is Map) {
        final map = response.data as Map;
        if (map['results'] is List) {
          rawList = map['results'] as List;
        } else if (map['bookings'] is List) {
          rawList = map['bookings'] as List;
        } else if (map['data'] is List) {
          rawList = map['data'] as List;
        } else if (map['value'] is List) {
          rawList = map['value'] as List;
        }
      }

      final list = rawList
          .whereType<Map>()
          .map((item) => RideBookingData.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.user == uid)
          .toList();

      // Sort by most recent first (descending by createdAt, or descending by id)
      list.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          try {
            final da = DateTime.parse(a.createdAt!);
            final db = DateTime.parse(b.createdAt!);
            return db.compareTo(da);
          } catch (_) {}
        }
        return b.id.compareTo(a.id);
      });

      return list;
    } catch (e) {
      debugPrint('[RideRepo] fetchRideBookings error: $e');
    }
    return [];
  }

  List<RideOption> getRideOptions() {
    return const [
      RideOption(
        id: '10',
        service: 8,
        name: 'Bike',
        description: 'Two-wheeler ride',
        iconName: 'bike',
        fare: 65.0,
        originalFare: 80.0,
        eta: '2 min away',
        capacity: '1',
        tag: 'Quickest',
        tagColor: Color(0xFF10B981),
        imageAsset: 'assets/images/automobile_3d.png',
        icon: Icons.two_wheeler_rounded,
      ),
      RideOption(
        id: '11',
        service: 8,
        name: 'Auto',
        description: 'Three-wheeler auto rickshaw',
        iconName: 'auto',
        fare: 120.0,
        originalFare: 145.0,
        eta: '3 min away',
        capacity: '3',
        tag: 'Affordable',
        tagColor: Color(0xFF059669),
        imageAsset: 'assets/images/rickshaw_3d.png',
        icon: Icons.electric_rickshaw_rounded,
      ),
      RideOption(
        id: '12',
        service: 8,
        name: 'Car',
        description: 'Standard car ride',
        iconName: 'car',
        fare: 220.0,
        originalFare: 260.0,
        eta: '4 min away',
        capacity: '4',
        tag: 'Most Popular',
        tagColor: Color(0xFF2563EB),
        imageAsset: 'assets/images/dash_ride_car_clean.png',
        icon: Icons.directions_car_filled_rounded,
      ),
      RideOption(
        id: '13',
        service: 8,
        name: 'Premium car',
        description: 'Premium car ride',
        iconName: 'premium_car',
        fare: 340.0,
        originalFare: 390.0,
        eta: '5 min away',
        capacity: '4',
        tag: 'Top Rated',
        tagColor: Color(0xFF7C3AED),
        imageAsset: 'assets/images/ride_premium_car.png',
        icon: Icons.airport_shuttle_rounded,
      ),
      RideOption(
        id: '24',
        service: 8,
        name: 'BMW',
        description: 'VIP RIDE',
        iconName: '',
        fare: 590.0,
        originalFare: 680.0,
        eta: '6 min away',
        capacity: '4',
        tag: 'VIP Luxury',
        tagColor: Color(0xFFD97706),
        imageAsset: 'assets/images/ride_comfort_car.png',
        icon: Icons.stars_rounded,
      ),
    ];
  }

  DriverModel getAssignedDriver() {
    return const DriverModel(
      name: 'Rahul Kumar',
      rating: 4.9,
      vehicleName: 'Toyota Etios',
      vehicleNumber: 'KL 07 AB 1234',
      arrivingTime: '4 min',
      photoUrl: '',
    );
  }
}
