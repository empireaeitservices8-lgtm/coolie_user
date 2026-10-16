import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cooli/features/services/model/service_model.dart';
import 'package:cooli/features/services/model/blackbuck_load_model.dart';
import 'package:cooli/features/services/model/transport_vehicle_type_model.dart';
import 'package:cooli/services/web_api_services.dart';
import 'package:cooli/utils/urls.dart';

class ServicesRepo {
  final Dio _dio;

  ServicesRepo({Dio? dio}) : _dio = dio ?? WebAPIService().dio;

  /// Fetch Transport Loads from Postman API: GET /transport/loads/list/?user_id=1
  Future<List<BlackbuckLoadModel>> fetchTransportLoads({int userId = 1}) async {
    try {
      final response = await _dio.get(
        '$urlTransportLoadsList?user_id=$userId',
        options: Options(
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      List<dynamic>? rawList;
      if (response.data is List) {
        rawList = response.data as List;
      } else if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        if (map['data'] is List) {
          rawList = map['data'] as List;
        } else if (map['results'] is List) {
          rawList = map['results'] as List;
        } else if (map['loads'] is List) {
          rawList = map['loads'] as List;
        }
      }

      if (rawList != null && rawList.isNotEmpty) {
        // Also fetch bookings list to match bookings (e.g. CL-20261005-4950) with loads
        Map<int, Map<String, dynamic>> bookingByLoadId = {};
        try {
          final bookingsRes = await _dio.get(
            '$urlTransportBookingsList?user_id=$userId',
            options: Options(
              headers: {'Accept': 'application/json'},
              sendTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          );
          List<dynamic>? bookingList;
          if (bookingsRes.data is List) {
            bookingList = bookingsRes.data as List;
          } else if (bookingsRes.data is Map<String, dynamic>) {
            final bMap = bookingsRes.data as Map<String, dynamic>;
            if (bMap['results'] is List) {
              bookingList = bMap['results'] as List;
            } else if (bMap['data'] is List) {
              bookingList = bMap['data'] as List;
            }
          }
          if (bookingList != null) {
            for (var b in bookingList) {
              if (b is Map<String, dynamic>) {
                final loadIdNum = int.tryParse(b['load']?.toString() ?? '');
                if (loadIdNum != null) {
                  bookingByLoadId[loadIdNum] = b;
                }
              }
            }
          }
        } catch (_) {}

        final list = rawList.map((item) {
          final map = item as Map<String, dynamic>;
          final loadNum = int.tryParse(map['id']?.toString() ?? '');
          if (loadNum != null && bookingByLoadId.containsKey(loadNum)) {
            final b = bookingByLoadId[loadNum]!;
            return BlackbuckLoadModel.fromBookingJson(b);
          }
          return BlackbuckLoadModel.fromJson(map);
        }).toList();

        if (list.isNotEmpty) {
          return list;
        }
      }
    } catch (e) {
      debugPrint('[ServicesRepo] fetchTransportLoads error: $e');
    }
    return BlackbuckLoadModel.getSampleLoads();
  }

  /// Fetch Transport Loads by Location:
  /// GET /transport/loads/list-by-location/?latitude=12.9716&longitude=77.5946&radius_km=50.0&location_type=pickup
  Future<TransportLocationSearchResult?> fetchTransportLoadsByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    String locationType = 'pickup',
  }) async {
    try {
      final response = await _dio.get(
        urlTransportLoadsListByLocation,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius_km': radiusKm,
          'location_type': locationType,
        },
        options: Options(
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.data is Map<String, dynamic>) {
        return TransportLocationSearchResult.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('[ServicesRepo] fetchTransportLoadsByLocation error: $e');
    }
    return null;
  }

  /// Fetch Transport Loads filtered by Truck Type:
  /// GET /transport/loads/list-by-truck-type/?truck_type=tipper&pickup_city=...&drop_city=...
  Future<TransportTruckTypeSearchResult?> fetchTransportLoadsByTruckType({
    required String truckType,
    String? pickupCity,
    String? dropCity,
    String? pickupState,
    String? dropState,
    String? status,
    int? userId,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'truck_type': truckType,
      };
      if (pickupCity != null && pickupCity.isNotEmpty && pickupCity != 'All') {
        queryParams['pickup_city'] = pickupCity;
      }
      if (dropCity != null && dropCity.isNotEmpty && dropCity != 'All') {
        queryParams['drop_city'] = dropCity;
      }
      if (pickupState != null && pickupState.isNotEmpty) {
        queryParams['pickup_state'] = pickupState;
      }
      if (dropState != null && dropState.isNotEmpty) {
        queryParams['drop_state'] = dropState;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (userId != null) {
        queryParams['user_id'] = userId;
      }

      final response = await _dio.get(
        urlTransportLoadsListByTruckType,
        queryParameters: queryParams,
        options: Options(
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.data is Map<String, dynamic>) {
        return TransportTruckTypeSearchResult.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('[ServicesRepo] fetchTransportLoadsByTruckType error: $e');
    }
    return null;
  }

  /// Fetch Transport Bookings (Shipments):
  /// GET http://coolie.pythonanywhere.com/api/transport/bookings/list/?user_id=1
  Future<List<BlackbuckLoadModel>> fetchTransportBookings({int? userId}) async {
    try {
      final uid = userId ?? 1;
      final response = await _dio.get(
        '$urlTransportBookingsList?user_id=$uid',
        options: Options(
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 12),
        ),
      );

      List rawList = [];
      if (response.data is List) {
        rawList = response.data as List;
      } else if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
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

      return rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => BlackbuckLoadModel.fromBookingJson(item))
          .toList();
    } catch (e) {
      debugPrint('[ServicesRepo] fetchTransportBookings error: $e');
    }
    return [];
  }

  /// Fetch Booking Details: GET /transport/bookings/:booking_id/
  /// e.g. http://coolie.pythonanywhere.com/api/transport/bookings/CL-20261005-4950/
  Future<BlackbuckLoadModel?> fetchBookingDetail(String bookingId) async {
    try {
      final cleanBookingId = bookingId.trim();
      final url = '$urlTransportBookings$cleanBookingId/';
      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (response.data is Map<String, dynamic>) {
        return BlackbuckLoadModel.fromBookingJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('[ServicesRepo] fetchBookingDetail error: $e');
    }
    return null;
  }

  /// Fetch Transport Load Detail: GET /transport/loads/:load_id/
  Future<BlackbuckLoadModel?> fetchLoadDetail(String loadId) async {
    try {
      final response = await _dio.get(
        '$urlTransportLoads$loadId/',
        options: Options(
          headers: {'Accept': 'application/json'},
        ),
      );
      if (response.data is Map<String, dynamic>) {
        return BlackbuckLoadModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[ServicesRepo] fetchLoadDetail error: $e');
    }
    return null;
  }

  /// Create Bid: POST /transport/bids/
  /// URL: http://coolie.pythonanywhere.com/api/transport/bids/
  /// Payload:
  /// {
  ///   "load": "LOAD-2026-001",
  ///   "bidder": 2,
  ///   "bid_amount": 19500,
  ///   "estimated_delivery_date": "2026-10-12",
  ///   "message": "I can deliver safely"
  /// }
  /// Response:
  /// {
  ///   "message": "Bid submitted successfully"
  /// }
  Future<({bool success, String message})> submitBid({
    required String loadId,
    required int bidderId,
    required num bidAmount,
    required String message,
    String? estimatedDeliveryDate,
  }) async {
    try {
      final formattedDeliveryDate = estimatedDeliveryDate ??
          DateTime.now()
              .add(const Duration(days: 2))
              .toIso8601String()
              .split('T')
              .first;

      final payload = {
        'load': loadId,
        'bidder': bidderId,
        'bid_amount': bidAmount % 1 == 0 ? bidAmount.toInt() : bidAmount,
        'estimated_delivery_date': formattedDeliveryDate,
        'message': message,
      };

      debugPrint('[ServicesRepo] submitBid POST -> $urlTransportBids');
      debugPrint('[ServicesRepo] submitBid payload: $payload');

      final response = await _dio.post(
        urlTransportBids,
        data: payload,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 12),
        ),
      );

      debugPrint(
          '[ServicesRepo] submitBid response status: ${response.statusCode}');
      debugPrint('[ServicesRepo] submitBid response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        String msg = 'Bid submitted successfully';
        if (response.data is Map &&
            (response.data as Map)['message'] != null) {
          msg = (response.data as Map)['message'].toString();
        }
        return (success: true, message: msg);
      } else {
        String errMsg = 'Failed to submit bid';
        if (response.data is Map) {
          final map = response.data as Map;
          if (map['message'] != null) {
            errMsg = map['message'].toString();
          } else if (map['error'] != null) {
            errMsg = map['error'].toString();
          } else if (map['detail'] != null) {
            errMsg = map['detail'].toString();
          }
        }
        return (success: false, message: errMsg);
      }
    } catch (e) {
      debugPrint('[ServicesRepo] submitBid error: $e');
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map) {
          if (data['message'] != null) {
            return (success: false, message: data['message'].toString());
          }
          if (data['error'] != null) {
            return (success: false, message: data['error'].toString());
          }
          if (data['detail'] != null) {
            return (success: false, message: data['detail'].toString());
          }
        }
      }
      return (success: false, message: 'Bid submission error: $e');
    }
  }

  /// Create Transport Load: POST /transport/loads/
  Future<bool> createTransportLoad(Map<String, dynamic> loadData) async {
    try {
      final response = await _dio.post(
        urlTransportLoads,
        data: loadData,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('[ServicesRepo] createTransportLoad error: $e');
      return false;
    }
  }

  /// Fetch Transport Vehicle Types from:
  /// GET /vehicle-types/by-service/?service=transport
  Future<List<TransportVehicleTypeModel>> fetchTransportVehicleTypes({
    String service = 'transport',
  }) async {
    try {
      final response = await _dio.get(
        '$urlVehicleTypesByService?service=$service',
        options: Options(
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final servicesList = data['services'];
        if (servicesList is List && servicesList.isNotEmpty) {
          final firstService = servicesList.first;
          if (firstService is Map<String, dynamic>) {
            final vTypes = firstService['vehicle_types'];
            if (vTypes is List) {
              final parsed = vTypes
                  .whereType<Map<String, dynamic>>()
                  .where((item) => item['is_active'] != false)
                  .map((item) => TransportVehicleTypeModel.fromJson(item))
                  .toList();
              if (parsed.isNotEmpty) {
                return parsed;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[ServicesRepo] fetchTransportVehicleTypes error: $e');
    }
    return TransportVehicleTypeModel.getDefaultVehicleTypes();
  }

  List<ServiceSubCategory> getSubCategories() {
    return const [
      ServiceSubCategory(id: 'cleaning', title: 'Cleaning', icon: Icons.cleaning_services_rounded),
      ServiceSubCategory(id: 'repair', title: 'Repair', icon: Icons.build_rounded),
      ServiceSubCategory(id: 'moving', title: 'Moving', icon: Icons.inventory_2_rounded),
      ServiceSubCategory(id: 'beauty', title: 'Beauty', icon: Icons.face_rounded),
      ServiceSubCategory(id: 'homeservices', title: 'Home Services', icon: Icons.home_repair_service_rounded),
      ServiceSubCategory(id: 'other', title: 'Other', icon: Icons.more_horiz_rounded),
    ];
  }

  List<HomeServiceModel> getHomeServices() {
    return const [
      HomeServiceModel(
        id: 'srv_cleaning',
        title: 'Home Cleaning',
        category: 'Cleaning',
        rating: 4.8,
        reviewCount: 250,
        startingPrice: 499.0,
        description: 'Professional deep home cleaning services for a cleaner, sanitized, and healthier home living space.',
        includedFeatures: [
          'Living Room Deep Cleaning & Mopping',
          'Bedroom Sanitization & Dusting',
          'Kitchen Countertop & Chimney Degreasing',
          'Bathroom Disinfection & Tile Scrubbing',
        ],
      ),
      HomeServiceModel(
        id: 'srv_ac_repair',
        title: 'AC Service & Repair',
        category: 'Repair',
        rating: 4.9,
        reviewCount: 180,
        startingPrice: 599.0,
        description: 'Complete air conditioner filter cleaning, gas refill check, and jet cooling service.',
        includedFeatures: [
          'Filter and Coil Washing',
          'Gas Pressure Leakage Inspection',
          'Drain Pipe Flushing',
        ],
      ),
    ];
  }
}
