import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cooli/features/porter/model/porter_model.dart';
import 'package:cooli/services/web_api_services.dart';
import 'package:cooli/utils/urls.dart';

class PorterRepo {
  final Dio _dio;

  PorterRepo({Dio? dio}) : _dio = dio ?? WebAPIService().dio;

  /// Fetch Vehicle Types: GET /goods/vehicle-types/
  Future<List<PorterVehicleType>> fetchVehicleTypes() async {
    try {
      final response = await _dio.get(
        urlGoodsVehicleTypes,
        options: Options(headers: {'Accept': 'application/json'}),
      );
      if (response.data is List) {
        final list = (response.data as List)
            .map((item) => PorterVehicleType.fromJson(item as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      debugPrint('[PorterRepo] fetchVehicleTypes error: $e');
    }
    return getVehicleTypes();
  }

  /// Calculate Fare: POST /goods/calculate-fare/
  Future<Map<String, dynamic>> calculateFare(Map<String, dynamic> payload) async {
    try {
      final vId = payload['vehicle_type_id'] ?? payload['vehicle_type'] ?? payload['vehicle'];
      final dist = payload['distance_km'] ?? payload['distance'] ?? 5.0;
      final distDouble = dist is num ? dist.toDouble() : (double.tryParse(dist.toString()) ?? 5.0);
      final apiPayload = <String, dynamic>{
        'vehicle_type_id': vId is int ? vId : (int.tryParse(vId.toString()) ?? 1),
        'distance_km': distDouble,
      };
      if (payload.containsKey('pickup_latitude')) apiPayload['pickup_latitude'] = payload['pickup_latitude'];
      if (payload.containsKey('pickup_longitude')) apiPayload['pickup_longitude'] = payload['pickup_longitude'];
      if (payload.containsKey('drop_latitude')) apiPayload['drop_latitude'] = payload['drop_latitude'];
      if (payload.containsKey('drop_longitude')) apiPayload['drop_longitude'] = payload['drop_longitude'];

      final response = await _dio.post(
        urlGoodsCalculateFare,
        data: apiPayload,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[PorterRepo] calculateFare error: $e');
    }
    // Local fallback: calculate fare from basePrice when API is unavailable
    final dist = payload['distance_km'] ?? 5.0;
    final distDouble = dist is num ? dist.toDouble() : (double.tryParse(dist.toString()) ?? 5.0);
    final basePriceRaw = payload['base_price'];
    if (basePriceRaw != null) {
      final basePrice = basePriceRaw is num ? basePriceRaw.toDouble() : (double.tryParse(basePriceRaw.toString()) ?? 0.0);
      final perKm = payload['per_km_rate'];
      final perKmRate = perKm is num ? perKm.toDouble() : (double.tryParse(perKm?.toString() ?? '') ?? 15.0);
      final fare = basePrice + (distDouble * perKmRate);
      return {'estimated_fare': fare, 'distance_km': distDouble};
    }
    return {};
  }

  /// Create Goods Booking: POST /goods/bookings/
  Future<Map<String, dynamic>> createGoodsBooking(Map<String, dynamic> payload) async {
    final response = await _dio.post(
      urlGoodsBookings,
      data: payload,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

  /// Fetch user bookings: GET /goods/bookings/list/?user_id={userId}
  Future<List<Map<String, dynamic>>> fetchBookingsList(dynamic userId) async {
    try {
      final response = await _dio.get(
        urlGoodsBookingsList,
        queryParameters: {'user_id': userId},
        options: Options(headers: {'Accept': 'application/json'}),
      );
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else if (response.data is Map && (response.data as Map).containsKey('results')) {
        final results = response.data['results'];
        if (results is List) {
          return results
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[PorterRepo] fetchBookingsList error: $e');
    }
    return [];
  }

  /// Fetch booking details: GET /goods/bookings/{booking_id}/
  Future<Map<String, dynamic>?> fetchBookingDetails(dynamic bookingId) async {
    try {
      final response = await _dio.get(
        '$urlGoodsBookings$bookingId/',
        options: Options(headers: {'Accept': 'application/json'}),
      );
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('[PorterRepo] fetchBookingDetails error: $e');
    }
    return null;
  }

  List<PorterVehicleType> getVehicleTypes() {
    return const [
      PorterVehicleType(
        id: '1',
        name: '3-Wheeler',
        capacity: '500 kg',
        basePrice: 280.0,
        perKmRate: 12.0,
        icon: Icons.electric_rickshaw_rounded,
      ),
      PorterVehicleType(
        id: '2',
        name: 'Tata Ace',
        capacity: '750 kg',
        basePrice: 450.0,
        perKmRate: 18.0,
        icon: Icons.local_shipping_rounded,
      ),
      PorterVehicleType(
        id: '3',
        name: '8ft Pickup',
        capacity: '1200 kg',
        basePrice: 700.0,
        perKmRate: 25.0,
        icon: Icons.airport_shuttle_rounded,
      ),
    ];
  }

  PorterBookingModel getSampleBooking() {
    return const PorterBookingModel(
      id: 'PT1234',
      vehicleType: 'Tata Ace',
      pickupAddress: 'Vyttila, Kochi',
      dropAddress: 'Kakkanad, Kochi',
      itemsDescription: 'Furniture, appliances etc.',
      dateTime: 'Today, 11:00 AM',
      estimatedPrice: 450.0,
      status: 'Pickup in Progress',
      estimatedArrival: 'Today, 12:30 PM',
    );
  }
}
