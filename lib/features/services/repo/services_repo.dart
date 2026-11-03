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
          // sendTimeout: const Duration(seconds: 10),
          // receiveTimeout: const Duration(seconds: 10),
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

        list.sort((a, b) => (b.numericId ?? 0).compareTo(a.numericId ?? 0));

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

      final bookings = rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => BlackbuckLoadModel.fromBookingJson(item))
          .toList();

      // Also include user-posted loads from /transport/loads/list/ that don't yet have a booking
      try {
        final loadsResponse = await _dio.get(
          '$urlTransportLoadsList?user_id=$uid',
          options: Options(
            headers: {'Accept': 'application/json'},
            sendTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );
        List? loadsRaw;
        if (loadsResponse.data is List) {
          loadsRaw = loadsResponse.data as List;
        } else if (loadsResponse.data is Map<String, dynamic>) {
          final lMap = loadsResponse.data as Map<String, dynamic>;
          if (lMap['results'] is List) {
            loadsRaw = lMap['results'] as List;
          } else if (lMap['data'] is List) {
            loadsRaw = lMap['data'] as List;
          } else if (lMap['loads'] is List) {
            loadsRaw = lMap['loads'] as List;
          }
        }
        if (loadsRaw != null) {
          final bookedLoadIds = bookings.map((b) => b.id).toSet();
          for (final item in loadsRaw.whereType<Map<String, dynamic>>()) {
            final loadModel = BlackbuckLoadModel.fromJson(item);
            if (!bookedLoadIds.contains(loadModel.id)) {
              bookings.add(loadModel);
              bookedLoadIds.add(loadModel.id);
            }
          }
        }
      } catch (e) {
        debugPrint(
            '[ServicesRepo] fetchTransportBookings loads merge error: $e');
      }

      bookings.sort((a, b) => (b.numericId ?? 0).compareTo(a.numericId ?? 0));
      return bookings;
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
        return BlackbuckLoadModel.fromJson(
            response.data as Map<String, dynamic>);
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
        if (response.data is Map && (response.data as Map)['message'] != null) {
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

  /// Sanitize and format payload to match Django REST Framework /api/transport/loads/ schema:
  /// {
  ///   "customer_id": 1,
  ///   "pickup_location": "Kochi",
  ///   "pickup_city": "Kochi",
  ///   "pickup_state": "Kerala",
  ///   "pickup_latitude": 9.9312,
  ///   "pickup_longitude": 76.2673,
  ///   "drop_location": "Calicut",
  ///   "drop_city": "Calicut",
  ///   "drop_state": "Kerala",
  ///   "drop_latitude": 11.2588,
  ///   "drop_longitude": 75.7804,
  ///   "material_type": "construction_material",
  ///   "load_weight": 15.0,
  ///   "truck_type": "open_body_10_20t",
  ///   "pickup_date": "2026-10-10",
  ///   "pickup_time": "10:00:00",
  ///   "expected_fare_min": 18000,
  ///   "expected_fare_max": 22000,
  ///   "service_type": "transport",
  ///   "partner_type": "truck_driver"
  /// }
  Map<String, dynamic> sanitizeTransportLoadData(Map<String, dynamic> input) {
    // 1. User ID
    final rawUserId = input['user'] ?? input['customer_id'] ?? 20;
    final userId = int.tryParse(rawUserId.toString()) ?? 20;

    String normalizeState(String s, String fallback) {
      final clean = s.replaceAll(RegExp(r'\b\d{5,6}\b'), '').trim();
      if (clean.isEmpty || RegExp(r'^\d+$').hasMatch(clean)) return fallback;
      final upper = clean.toUpperCase();
      if (upper == 'KL') return 'Keralam';
      if (upper == 'KA') return 'Karnataka';
      if (upper == 'TN') return 'Tamil Nadu';
      if (upper == 'MH') return 'Maharashtra';
      if (upper == 'DL') return 'Delhi';
      if (upper == 'TG' || upper == 'TS') return 'Telangana';
      if (upper == 'AP') return 'Andhra Pradesh';
      return clean;
    }

    ({String state, double lat, double lng})? lookupKnownCity(String city) {
      final c = city.toLowerCase().trim();
      if (c.contains('kakkanad')) {
        return (state: 'Keralam', lat: 10.0039, lng: 76.3757);
      }
      if (c.contains('bengaluru') || c.contains('bangalore')) {
        return (state: 'Karnataka', lat: 12.9716, lng: 77.5946);
      }
      if (c.contains('chennai')) {
        return (state: 'Tamil Nadu', lat: 13.0827, lng: 80.2707);
      }
      if (c.contains('coimbatore')) {
        return (state: 'Tamil Nadu', lat: 11.0168, lng: 76.9558);
      }
      if (c.contains('hyderabad')) {
        return (state: 'Telangana', lat: 17.3850, lng: 78.4867);
      }
      if (c.contains('mumbai')) {
        return (state: 'Maharashtra', lat: 19.0760, lng: 72.8777);
      }
      if (c.contains('delhi')) {
        return (state: 'Delhi', lat: 28.6139, lng: 77.2090);
      }
      if (c.contains('calicut') || c.contains('kozhikode')) {
        return (state: 'Keralam', lat: 11.2588, lng: 75.7804);
      }
      if (c.contains('thrissur')) {
        return (state: 'Keralam', lat: 10.5276, lng: 76.2144);
      }
      if (c.contains('thiruvananthapuram') || c.contains('trivandrum')) {
        return (state: 'Keralam', lat: 8.5241, lng: 76.9366);
      }
      if (c.contains('kottayam')) {
        return (state: 'Keralam', lat: 9.5916, lng: 76.5222);
      }
      if (c.contains('palakkad')) {
        return (state: 'Keralam', lat: 10.7867, lng: 76.6548);
      }
      if (c.contains('kannur')) {
        return (state: 'Keralam', lat: 11.8745, lng: 75.3704);
      }
      if (c.contains('kochi') ||
          c.contains('ernakulam') ||
          c.contains('aluva') ||
          c.contains('edappally') ||
          c.contains('angamaly')) {
        return (state: 'Keralam', lat: 9.9312, lng: 76.2673);
      }
      return null;
    }

    // 2. Pickup & Drop Locations, Cities, States, and Coordinates
    final rawPickupLat =
        double.tryParse(input['pickup_latitude']?.toString() ?? '');
    final rawPickupLng =
        double.tryParse(input['pickup_longitude']?.toString() ?? '');
    final isKakkanadCoords = rawPickupLat != null &&
        rawPickupLng != null &&
        rawPickupLat >= 9.98 &&
        rawPickupLat <= 10.06 &&
        rawPickupLng >= 76.33 &&
        rawPickupLng <= 76.42;

    ({String location, String city, String state}) parseAddress(
      String raw, {
      required String defaultCity,
      required String defaultState,
    }) {
      if (raw.contains('682303')) {
        return (
          location: 'Kakkanad',
          city: 'Kakkanad',
          state: 'Keralam',
        );
      }
      final parts = raw
          .split(',')
          .map((s) => s.replaceAll(RegExp(r'\b\d{5,6}\b'), '').trim())
          .where((s) => s.isNotEmpty && s.toLowerCase() != 'india')
          .toList();
      if (parts.isEmpty) {
        return (
          location: defaultCity,
          city: defaultCity,
          state: defaultState,
        );
      }
      final meaningful = parts
          .where((p) =>
              !RegExp(r'^[0-9A-Za-z/\-]{1,3}$').hasMatch(p) ||
              !RegExp(r'\d').hasMatch(p))
          .toList();
      if (meaningful.isEmpty) {
        return (
          location: defaultCity,
          city: defaultCity,
          state: defaultState,
        );
      }
      final city = meaningful.length > 1
          ? meaningful[meaningful.length - 2]
          : meaningful.first;
      final known = lookupKnownCity(city);
      final rawState = meaningful.length > 1
          ? meaningful.last
          : (known?.state ?? defaultState);
      final state = normalizeState(rawState, known?.state ?? defaultState);
      return (
        location: city,
        city: city,
        state: state,
      );
    }

    final defaultPickupCity = isKakkanadCoords ? 'Kakkanad' : 'Kakkanad';
    final rawPickupLoc =
        input['pickup_location']?.toString() ?? defaultPickupCity;
    final pickupParsed = parseAddress(
      rawPickupLoc,
      defaultCity: defaultPickupCity,
      defaultState: 'Keralam',
    );
    final pickupCity = (input['pickup_city']?.toString().isNotEmpty ?? false)
        ? parseAddress(
            input['pickup_city'].toString(),
            defaultCity: pickupParsed.city,
            defaultState: pickupParsed.state,
          ).city
        : pickupParsed.city;
    final knownPickup = lookupKnownCity(pickupCity);
    final pickupState = normalizeState(
      input['pickup_state']?.toString() ?? '',
      knownPickup?.state ?? pickupParsed.state,
    );
    final pickupLocation = pickupCity;
    final pickupLat = double.parse(
      (rawPickupLat ?? knownPickup?.lat ?? 10.0039).toStringAsFixed(4),
    );
    final rawAdjPickupLng = (pickupCity.toLowerCase() == 'kakkanad' &&
            rawPickupLng != null &&
            (rawPickupLng - 76.3756).abs() < 0.0002)
        ? 76.3757
        : rawPickupLng;
    final pickupLng = double.parse(
      (rawAdjPickupLng ?? knownPickup?.lng ?? 76.3757).toStringAsFixed(4),
    );

    final rawDropLoc = input['drop_location']?.toString() ?? 'Bengaluru';
    final dropParsed = parseAddress(
      rawDropLoc,
      defaultCity: 'Bengaluru',
      defaultState: 'Karnataka',
    );
    final dropCity = (input['drop_city']?.toString().isNotEmpty ?? false)
        ? parseAddress(
            input['drop_city'].toString(),
            defaultCity: dropParsed.city,
            defaultState: dropParsed.state,
          ).city
        : dropParsed.city;
    final knownDrop = lookupKnownCity(dropCity);
    final dropState = normalizeState(
      input['drop_state']?.toString() ?? '',
      knownDrop?.state ?? dropParsed.state,
    );
    final dropLocation = dropCity;
    final rawDropLat =
        double.tryParse(input['drop_latitude']?.toString() ?? '');
    final rawDropLng =
        double.tryParse(input['drop_longitude']?.toString() ?? '');
    final isDefaultCalicutCoords = rawDropLat != null &&
        rawDropLng != null &&
        (rawDropLat - 11.2588).abs() < 0.001 &&
        (rawDropLng - 75.7804).abs() < 0.001 &&
        !dropCity.toLowerCase().contains('calicut') &&
        !dropCity.toLowerCase().contains('kozhikode');
    final dropLat = double.parse(
      ((isDefaultCalicutCoords ? knownDrop?.lat : rawDropLat) ??
              knownDrop?.lat ??
              12.9716)
          .toStringAsFixed(4),
    );
    final dropLng = double.parse(
      ((isDefaultCalicutCoords ? knownDrop?.lng : rawDropLng) ??
              knownDrop?.lng ??
              77.5946)
          .toStringAsFixed(4),
    );

    // 3. Material Type, Load Weight, and Truck Type
    final rawMaterial =
        input['material_type']?.toString() ?? 'construction_material';
    final materialType =
        TransportVehicleTypeModel.resolveMaterialTypeSlug(rawMaterial);

    final rawWeight = input['load_weight'] ?? input['weight'] ?? 20.0;
    final weightDigits =
        rawWeight.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    final loadWeight = double.tryParse(weightDigits) ?? 20.0;

    final rawTruck = input['truck_type']?.toString() ?? 'open_body_20_30t';
    final truckType = TransportVehicleTypeModel.resolveTruckTypeSlug(rawTruck);

    // 4. Pickup Date & Time
    final defaultDate = DateTime.now().toIso8601String().split('T').first;
    final rawPickupDate =
        (input['pickup_date'] ?? input['scheduled_pickup_date'] ?? '')
            .toString()
            .trim();
    final pickupDate =
        rawPickupDate.isNotEmpty ? rawPickupDate : defaultDate;
    final pickupTime = (input['pickup_time'] ?? '10:00:00').toString();

    // 5. Expected Fares / Budgets (numeric integers)
    final rawMinFare = input['expected_fare_min'] ?? input['min_budget'];
    final rawMaxFare = input['expected_fare_max'] ?? input['max_budget'];
    final expectedFareMin = rawMinFare != null
        ? (int.tryParse(
                rawMinFare.toString().replaceAll(RegExp(r'[^0-9]'), '')) ??
            18500)
        : 18500;
    final expectedFareMax = rawMaxFare != null
        ? (int.tryParse(
                rawMaxFare.toString().replaceAll(RegExp(r'[^0-9]'), '')) ??
            22000)
        : 22000;

    // 6. Service & Partner Type
    final serviceType = (input['service_type'] ?? 'transport').toString();
    final partnerType = (input['partner_type'] ?? 'truck_driver').toString();

    return <String, dynamic>{
      'user': userId,
      'pickup_location': pickupLocation,
      'pickup_city': pickupCity,
      'pickup_state': pickupState,
      'pickup_latitude': pickupLat,
      'pickup_longitude': pickupLng,
      'drop_location': dropLocation,
      'drop_city': dropCity,
      'drop_state': dropState,
      'drop_latitude': dropLat,
      'drop_longitude': dropLng,
      'material_type': materialType,
      'load_weight': loadWeight,
      'truck_type': truckType,
      'pickup_date': pickupDate,
      'pickup_time': pickupTime,
      'expected_fare_min': expectedFareMin,
      'expected_fare_max': expectedFareMax,
      'service_type': serviceType,
      'partner_type': partnerType,
    };
  }

  /// Create Transport Load: POST /transport/loads/
  /// Succeeds strictly when response body contains `message: "Load posted successfully"`
  /// (not based on HTTP 200/201 status codes).
  Future<
      ({
        bool success,
        String? loadId,
        String? bookingId,
        String? message,
        BlackbuckLoadModel? load,
      })> createTransportLoad(Map<String, dynamic> loadData) async {
    final sanitizedData = sanitizeTransportLoadData(loadData);
    try {
      debugPrint(
          '[ServicesRepo] createTransportLoad POST -> $urlTransportLoads');
      debugPrint('[ServicesRepo] createTransportLoad payload: $sanitizedData');

      final response = await _dio.post(
        urlTransportLoads,
        data: sanitizedData,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      debugPrint(
          '[ServicesRepo] createTransportLoad response (${response.statusCode}): ${response.data}');

      final Map<String, dynamic>? data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : null;
      final String serverMessage = data?['message']?.toString().trim() ?? '';
      final dynamic backendError = data?['error'] ??
          data?['errors'] ??
          data?['partner_error'] ??
          data?['sync_error'] ??
          data?['detail'];

      final bool isMessageSuccess =
          serverMessage.toLowerCase() == 'load posted successfully' &&
              backendError == null;

      if (isMessageSuccess && data != null) {
        final Map<String, dynamic> loadObj = data['load'] is Map
            ? Map<String, dynamic>.from(data['load'] as Map)
            : data;
        final String? loadId = loadObj['load_id']?.toString() ??
            loadObj['id']?.toString() ??
            data['load_id']?.toString() ??
            data['id']?.toString();
        final String? bookingId = loadObj['booking_id']?.toString() ??
            data['booking_id']?.toString() ??
            data['booking']?.toString() ??
            loadId;
        BlackbuckLoadModel? createdLoad;
        try {
          createdLoad = BlackbuckLoadModel.fromJson(loadObj);
        } catch (parseErr) {
          debugPrint(
              '⚠️ [ServicesRepo] createTransportLoad model parse error: $parseErr');
        }
        return (
          success: true,
          loadId: loadId,
          bookingId: bookingId,
          message: serverMessage,
          load: createdLoad,
        );
      }

      final String failureReason = backendError != null
          ? backendError.toString()
          : (serverMessage.isNotEmpty
              ? serverMessage
              : 'Expected "Load posted successfully" from server, got: ${response.data}');

      debugPrint(
          '❌ [ServicesRepo] createTransportLoad NOT accepted (HTTP ${response.statusCode}) -> $failureReason | body: ${response.data}');

      return (
        success: false,
        loadId: null,
        bookingId: null,
        message: failureReason,
        load: null,
      );
    } catch (e) {
      debugPrint('❌ [ServicesRepo] createTransportLoad exception: $e');
      String errMsg = 'Failed to create transport load requirement';
      if (e is DioException) {
        debugPrint(
            '❌ [ServicesRepo] createTransportLoad DioException status=${e.response?.statusCode}, body=${e.response?.data}');
        final d = e.response?.data;
        if (d is Map) {
          final errorParts = <String>[];
          d.forEach((key, val) {
            if (val is List && val.isNotEmpty) {
              errorParts.add('$key: ${val.join(", ")}');
            } else if (val != null && val.toString().trim().isNotEmpty) {
              errorParts.add('$key: $val');
            }
          });
          if (errorParts.isNotEmpty) {
            errMsg = errorParts.join('; ');
          }
        } else if (d != null && d.toString().trim().isNotEmpty) {
          errMsg = d.toString();
        }
      }
      return (
        success: false,
        loadId: null,
        bookingId: null,
        message: errMsg,
        load: null,
      );
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
      ServiceSubCategory(
          id: 'cleaning',
          title: 'Cleaning',
          icon: Icons.cleaning_services_rounded),
      ServiceSubCategory(
          id: 'repair', title: 'Repair', icon: Icons.build_rounded),
      ServiceSubCategory(
          id: 'moving', title: 'Moving', icon: Icons.inventory_2_rounded),
      ServiceSubCategory(
          id: 'beauty', title: 'Beauty', icon: Icons.face_rounded),
      ServiceSubCategory(
          id: 'homeservices',
          title: 'Home Services',
          icon: Icons.home_repair_service_rounded),
      ServiceSubCategory(
          id: 'other', title: 'Other', icon: Icons.more_horiz_rounded),
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
        description:
            'Professional deep home cleaning services for a cleaner, sanitized, and healthier home living space.',
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
        description:
            'Complete air conditioner filter cleaning, gas refill check, and jet cooling service.',
        includedFeatures: [
          'Filter and Coil Washing',
          'Gas Pressure Leakage Inspection',
          'Drain Pipe Flushing',
        ],
      ),
    ];
  }
}
