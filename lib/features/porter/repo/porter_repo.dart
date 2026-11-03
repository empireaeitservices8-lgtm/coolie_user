import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cooli/features/porter/model/porter_model.dart';
import 'package:cooli/services/web_api_services.dart';
import 'package:cooli/utils/urls.dart';

class PorterRepo {
  final Dio _dio;

  PorterRepo({Dio? dio}) : _dio = dio ?? WebAPIService().dio;

  bool _isCreatingBookingInProgress = false;

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
    return [];
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
      double formatCoord(dynamic val) {
        if (val is num) return double.parse(val.toDouble().toStringAsFixed(6));
        final parsed = double.tryParse(val?.toString() ?? '');
        return parsed != null ? double.parse(parsed.toStringAsFixed(6)) : 0.0;
      }

      if (payload.containsKey('pickup_latitude')) apiPayload['pickup_latitude'] = formatCoord(payload['pickup_latitude']);
      if (payload.containsKey('pickup_longitude')) apiPayload['pickup_longitude'] = formatCoord(payload['pickup_longitude']);
      if (payload.containsKey('drop_latitude')) apiPayload['drop_latitude'] = formatCoord(payload['drop_latitude']);
      if (payload.containsKey('drop_longitude')) apiPayload['drop_longitude'] = formatCoord(payload['drop_longitude']);

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
  /// Strictly whitelists only the arguments expected by the API:
  /// user, vehicle_type, pickup_address, pickup_contact_person, pickup_mobile_number,
  /// pickup_instructions, delivery_address, receiver_name, receiver_mobile_number,
  /// delivery_instructions, goods_category, approximate_weight, number_of_items,
  /// loading_requirement, unloading_requirement, special_instructions,
  /// distance_km, estimated_fare.
  Future<Map<String, dynamic>> createGoodsBooking(Map<String, dynamic> payload) async {
    if (_isCreatingBookingInProgress) {
      debugPrint('[PorterRepo] Duplicate goods booking request blocked.');
      return {};
    }
    _isCreatingBookingInProgress = true;

    try {
      final sanitizedWeight = (payload['approximate_weight'] != null &&
              payload['approximate_weight'].toString().trim().isNotEmpty &&
              payload['approximate_weight'].toString().trim() != '0' &&
              payload['approximate_weight'].toString().trim() != '0.0' &&
              payload['approximate_weight'].toString().trim() != '0.00')
          ? payload['approximate_weight'].toString().trim()
          : '10';

      final apiPayload = <String, dynamic>{
        'user': payload['user'] is int
            ? payload['user']
            : (int.tryParse(payload['user']?.toString() ?? '') ?? 1),
        'vehicle_type': payload['vehicle_type'] is int
            ? payload['vehicle_type']
            : (int.tryParse(payload['vehicle_type']?.toString() ?? '') ?? 15),
        'pickup_address': (payload['pickup_address'] ?? '').toString().trim(),
        'pickup_contact_person': (payload['pickup_contact_person'] ?? '').toString().trim(),
        'pickup_mobile_number': (payload['pickup_mobile_number'] ?? '').toString().trim(),
        'pickup_instructions': (payload['pickup_instructions'] ?? '').toString().trim(),
        'delivery_address': (payload['delivery_address'] ?? '').toString().trim(),
        'receiver_name': (payload['receiver_name'] ?? '').toString().trim(),
        'receiver_mobile_number': (payload['receiver_mobile_number'] ?? '').toString().trim(),
        'delivery_instructions': (payload['delivery_instructions'] ?? '').toString().trim(),
        'goods_category': (payload['goods_category'] ?? '').toString().trim().isNotEmpty
            ? (payload['goods_category'] ?? '').toString().trim()
            : 'General Goods',
        'approximate_weight': sanitizedWeight,
        'number_of_items': payload['number_of_items'] is int
            ? payload['number_of_items']
            : (int.tryParse(payload['number_of_items']?.toString() ?? '') ?? 1),
        'loading_requirement': payload['loading_requirement'] == true,
        'unloading_requirement': payload['unloading_requirement'] == true,
        'special_instructions': (payload['special_instructions'] ?? '').toString().trim(),
        'distance_km': payload['distance_km'] is num
            ? double.parse((payload['distance_km'] as num).toDouble().toStringAsFixed(2))
            : (double.tryParse(payload['distance_km']?.toString() ?? '') ?? 5.0),
        'estimated_fare': payload['estimated_fare'] is num
            ? double.parse((payload['estimated_fare'] as num).toDouble().toStringAsFixed(2))
            : (double.tryParse(payload['estimated_fare']?.toString() ?? '') ?? 350.0),
      };

      final response = await _dio.post(
        urlGoodsBookings,
        data: apiPayload,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } finally {
      _isCreatingBookingInProgress = false;
    }
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
}
