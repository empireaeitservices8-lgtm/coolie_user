import 'package:cooli/features/porter/model/porter_model.dart';
import 'package:cooli/features/porter/repo/porter_repo.dart';
import 'package:cooli/providers/view_model.dart';
import 'package:cooli/services/session_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class PorterViewModel extends ViewModel {
  final PorterRepo _repo;

  PorterViewModel({PorterRepo? repo}) : _repo = repo ?? PorterRepo() {
    loadVehicles();
  }

  List<PorterVehicleType> _vehicles = [];
  List<PorterVehicleType> get vehicles => _vehicles;

  PorterVehicleType? _selectedVehicle;
  PorterVehicleType? get selectedVehicle => _selectedVehicle;

  String _pickup = 'Select pickup address';
  String get pickup => _pickup;

  String _drop = '';
  String get drop => _drop;

  String _itemDetails = 'Furniture, appliances etc.';
  String get itemDetails => _itemDetails;

  String _dateTime = 'Today, 11:00 AM';
  String get dateTime => _dateTime;

  PorterBookingModel? _currentBooking;
  PorterBookingModel? get currentBooking => _currentBooking;

  double? _pickupLat = 9.9816;
  double? _pickupLng = 76.2763;
  double? _dropLat;
  double? _dropLng;
  double? _estimatedFare;
  double _distanceKm = 0.0;
  bool _isCalculatingFare = false;

  double? get pickupLat => _pickupLat;
  double? get pickupLng => _pickupLng;
  double? get dropLat => _dropLat;
  double? get dropLng => _dropLng;
  double? get estimatedFare => _estimatedFare;
  double get distanceKm => _distanceKm;
  bool get isCalculatingFare => _isCalculatingFare;

  // Booking creation state
  bool _isCreatingBooking = false;
  bool get isCreatingBooking => _isCreatingBooking;
  Map<String, dynamic>? _bookingResult;
  Map<String, dynamic>? get bookingResult => _bookingResult;
  String? _bookingError;
  String? get bookingError => _bookingError;

  // Bookings list state
  List<Map<String, dynamic>> _myBookings = [];
  List<Map<String, dynamic>> get myBookings => _myBookings;
  bool _isLoadingBookings = false;
  bool get isLoadingBookings => _isLoadingBookings;
  String? _bookingsError;
  String? get bookingsError => _bookingsError;

  // Active single booking detail state
  Map<String, dynamic>? _activeBooking;
  Map<String, dynamic>? get activeBooking => _activeBooking;
  bool _isLoadingBookingDetails = false;
  bool get isLoadingBookingDetails => _isLoadingBookingDetails;
  String? _bookingDetailsError;
  String? get bookingDetailsError => _bookingDetailsError;

  void loadVehicles() async {
    _vehicles = _repo.getVehicleTypes();
    if (_vehicles.isNotEmpty) {
      _selectedVehicle = _vehicles.first;
    }
    _currentBooking = _repo.getSampleBooking();
    notifyListeners();

    final live = await _repo.fetchVehicleTypes();
    if (live.isNotEmpty) {
      _vehicles = live;
      if (_selectedVehicle == null || !_vehicles.contains(_selectedVehicle)) {
        _selectedVehicle = _vehicles.first;
      }
      notifyListeners();
    }
    _recalculateFare();
  }

  void selectVehicle(PorterVehicleType vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
    _recalculateFare();
  }

  void setPickup(String val, {double? lat, double? lng}) {
    _pickup = val;
    if (lat != null && lng != null) {
      _pickupLat = lat;
      _pickupLng = lng;
      _recalculateFare();
    }
    notifyListeners();
  }

  void setDrop(String val, {double? lat, double? lng}) {
    _drop = val;
    if (lat != null && lng != null) {
      _dropLat = lat;
      _dropLng = lng;
      _recalculateFare();
    }
    notifyListeners();
  }

  void setDistance(double d) {
    if (d > 0 && (_distanceKm - d).abs() > 0.05) {
      _distanceKm = d;
      _recalculateFare();
      notifyListeners();
    }
  }

  void _recalculateFare() async {
    if (_selectedVehicle == null) return;

    final effectiveDist = _distanceKm > 0 ? _distanceKm : 5.0;

    // If no drop location yet, provide baseline estimated fare based on selected vehicle
    if (_dropLat == null || _dropLng == null) {
      _estimatedFare = _selectedVehicle!.basePrice +
          (effectiveDist * _selectedVehicle!.perKmRate);
      notifyListeners();
      return;
    }

    _isCalculatingFare = true;
    notifyListeners();
    try {
      final vId = int.tryParse(_selectedVehicle!.id) ?? 1;
      final effectiveDist = _distanceKm > 0 ? _distanceKm : 5.0;
      final payload = <String, dynamic>{
        'vehicle_type_id': vId,
        'distance_km': effectiveDist,
        'base_price': _selectedVehicle!.basePrice,
        'per_km_rate': _selectedVehicle!.perKmRate,
      };
      if (_pickupLat != null && _pickupLng != null) {
        payload['pickup_latitude'] = _pickupLat;
        payload['pickup_longitude'] = _pickupLng;
      }
      if (_dropLat != null && _dropLng != null) {
        payload['drop_latitude'] = _dropLat;
        payload['drop_longitude'] = _dropLng;
      }

      final res = await _repo.calculateFare(payload);
      double? parsedAmount;
      if (res['estimated_fare'] != null) {
        parsedAmount = double.tryParse(res['estimated_fare'].toString());
      } else if (res['base_fare'] != null) {
        parsedAmount = double.tryParse(res['base_fare'].toString());
      } else if (res['fare'] != null) {
        parsedAmount = double.tryParse(res['fare'].toString());
      } else if (res['amount'] != null) {
        parsedAmount = double.tryParse(res['amount'].toString());
      }

      if (parsedAmount != null && parsedAmount > 0) {
        _estimatedFare = parsedAmount;
      } else {
        // Ultimate fallback: calculate locally
        _estimatedFare = _selectedVehicle!.basePrice +
            (effectiveDist * _selectedVehicle!.perKmRate);
      }

      if (res['distance_km'] != null) {
        final d = double.tryParse(res['distance_km'].toString());
        if (d != null && d > 0) {
          _distanceKm = d;
        }
      }
    } catch (_) {
      // Fallback: local calculation
      if (_selectedVehicle != null) {
        final effectiveDist = _distanceKm > 0 ? _distanceKm : 5.0;
        _estimatedFare = _selectedVehicle!.basePrice +
            (effectiveDist * _selectedVehicle!.perKmRate);
      } else {
        _estimatedFare = null;
      }
    } finally {
      _isCalculatingFare = false;
      notifyListeners();
    }
  }

  void setItemDetails(String val) {
    _itemDetails = val;
    notifyListeners();
  }

  void setDateTime(String val) {
    _dateTime = val;
    notifyListeners();
  }

  /// Creates a goods booking via POST /goods/bookings/
  /// Returns the booking map from the server on success, or null on failure.
  Future<Map<String, dynamic>?> createBooking({
    required String pickupContactPerson,
    required String pickupMobile,
    String pickupInstructions = '',
    required String receiverName,
    required String receiverMobile,
    String deliveryInstructions = '',
    String goodsCategory = '',
    String approximateWeight = '',
    int numberOfItems = 1,
    bool loadingRequired = false,
    bool unloadingRequired = false,
    String specialInstructions = '',
    String? scheduledPickupTime,
  }) async {
    _isCreatingBooking = true;
    _bookingError = null;
    notifyListeners();

    try {
      final userId = await SessionManager().getUserId();
      final vId = int.tryParse(_selectedVehicle?.id ?? '1') ?? 1;
      final effectiveDist = _distanceKm > 0 ? _distanceKm : 5.0;
      final fare = _estimatedFare ??
          (_selectedVehicle != null
              ? _selectedVehicle!.basePrice +
                  (effectiveDist * _selectedVehicle!.perKmRate)
              : 350.0);
      _estimatedFare = fare;

      // Sanitize phone numbers → E.164 format for Django PhoneNumberField.
      // Strip spaces, dashes, dots, parens. If no leading '+', prepend '+91'.
      // Examples:
      //   "9876543210"        → "+919876543210"
      //   "+91 98765 43210"   → "+919876543210"
      //   "91-9876543210"     → "+919876543210"
      //   "+1-800-555-0199"   → "+18005550199"
      String sanitizePhone(String raw) {
        // Remove all whitespace, dashes, dots, parentheses
        String s = raw.replaceAll(RegExp(r'[\s\-().]+'), '');
        // If no country code prefix, add +91 (India)
        if (!s.startsWith('+')) {
          // If starts with 91 and is 12 digits, just add +
          if (s.startsWith('91') && s.length == 12) {
            s = '+$s';
          }
        }
        return s;
      }

      final sanitizedPickupMobile = sanitizePhone(pickupMobile);
      final sanitizedReceiverMobile = sanitizePhone(receiverMobile);

      // debugPrint('📱 [Booking] Pickup mobile   raw="$pickupMobile"   → sent="$sanitizedPickupMobile"');
      // debugPrint('📱 [Booking] Receiver mobile raw="$receiverMobile" → sent="$sanitizedReceiverMobile"');

      // Round distance to 2 decimal places (server allows max 10 total digits)
      final distRounded = double.parse(effectiveDist.toStringAsFixed(2));

      final payload = <String, dynamic>{
        'user': userId,
        'vehicle_type': vId,
        'pickup_address': _pickup,
        'pickup_contact_person': pickupContactPerson,
        'pickup_mobile_number': sanitizedPickupMobile,
        'pickup_instructions': pickupInstructions,
        'delivery_address': _drop,
        'receiver_name': receiverName,
        'receiver_mobile_number': sanitizedReceiverMobile,
        'delivery_instructions': deliveryInstructions,
        'goods_category':
            goodsCategory.isNotEmpty ? goodsCategory : _itemDetails,
        'approximate_weight': double.tryParse(approximateWeight) ?? 0.0,
        'number_of_items': numberOfItems,
        'loading_requirement': loadingRequired,
        'unloading_requirement': unloadingRequired,
        'special_instructions': specialInstructions,
        'distance_km': distRounded,
        'estimated_fare': double.parse(fare.toStringAsFixed(2)),
      };
      if (scheduledPickupTime != null && scheduledPickupTime.isNotEmpty) {
        payload['scheduled_pickup_time'] = scheduledPickupTime;
      }

      final result = await _repo.createGoodsBooking(payload);
      final enrichedResult = Map<String, dynamic>.from(result);
      if (enrichedResult['estimated_fare'] == null) {
        enrichedResult['estimated_fare'] = fare;
      }
      if (enrichedResult['distance_km'] == null) {
        enrichedResult['distance_km'] = distRounded;
      }
      if (enrichedResult['booking'] is Map) {
        final inner =
            Map<String, dynamic>.from(enrichedResult['booking'] as Map);
        if (inner['estimated_fare'] == null) inner['estimated_fare'] = fare;
        if (inner['distance_km'] == null) inner['distance_km'] = distRounded;
        enrichedResult['booking'] = inner;
      }
      _bookingResult = enrichedResult;
      return enrichedResult;
    } catch (e) {
      String errorMsg = 'Booking failed. Please try again.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          // Collect all field-level validation errors from the server response
          final messages = <String>[];
          data.forEach((key, value) {
            if (value is List) {
              messages.add('$key: ${value.join(', ')}');
            } else if (value is String) {
              messages.add(value);
            }
          });
          if (messages.isNotEmpty) {
            errorMsg = messages.join('\n');
          }
        } else if (data is String && data.isNotEmpty) {
          errorMsg = data;
        } else if (e.message != null && e.message!.isNotEmpty) {
          errorMsg = e.message!;
        }
      } else {
        errorMsg = e.toString();
      }
      _bookingError = errorMsg;
      return null;
    } finally {
      _isCreatingBooking = false;
      notifyListeners();
    }
  }

  /// Helper to get vehicle name by vehicle_type ID
  String getVehicleName(dynamic vehicleTypeId) {
    if (vehicleTypeId == null) return 'Mini Truck';
    final idStr = vehicleTypeId.toString();
    for (final v in _vehicles) {
      if (v.id == idStr) return v.name;
    }
    return 'Vehicle #$idStr';
  }

  /// Fetch list of bookings for the currently authenticated user
  Future<void> fetchMyBookings() async {
    _isLoadingBookings = true;
    _bookingsError = null;
    notifyListeners();

    try {
      final userId = await SessionManager().getUserId();
      final list = await _repo.fetchBookingsList(userId);
      // Ensure every booking has estimated_fare and vehicle_name populated
      for (int i = 0; i < list.length; i++) {
        final b = list[i];
        final vId = b['vehicle_type'];
        final vName = getVehicleName(vId);
        b['vehicle_name'] ??= vName;

        if (b['estimated_fare'] == null && b['final_fare'] == null) {
          final distRaw = b['distance_km'];
          final dist = distRaw is num
              ? distRaw.toDouble()
              : (double.tryParse(distRaw?.toString() ?? '') ?? 5.0);
          PorterVehicleType? match;
          for (final v in _vehicles) {
            if (v.id == vId?.toString()) {
              match = v;
              break;
            }
          }
          final basePrice = match?.basePrice ?? 300.0;
          final perKm = match?.perKmRate ?? 15.0;
          final computedFare = basePrice + (dist * perKm);
          b['estimated_fare'] = double.parse(computedFare.toStringAsFixed(2));
        }
      }
      _myBookings = list;
    } catch (e) {
      debugPrint('[PorterViewModel] fetchMyBookings error: $e');
      _bookingsError = 'Failed to load bookings. Please try again.';
    } finally {
      _isLoadingBookings = false;
      notifyListeners();
    }
  }

  /// Set active booking in provider
  void setActiveBooking(Map<String, dynamic> booking) {
    final copy = Map<String, dynamic>.from(booking);
    final vId = copy['vehicle_type'];
    copy['vehicle_name'] ??= getVehicleName(vId);
    _activeBooking = copy;
    notifyListeners();
  }

  /// Fetch live booking details by ID: GET /goods/bookings/{booking_id}/
  Future<Map<String, dynamic>?> fetchBookingDetails(dynamic bookingId,
      {Map<String, dynamic>? initialData}) async {
    if (initialData != null) {
      final copy = Map<String, dynamic>.from(initialData);
      final vId = copy['vehicle_type'];
      copy['vehicle_name'] ??= getVehicleName(vId);
      _activeBooking = copy;
      notifyListeners();
    }

    _isLoadingBookingDetails = true;
    _bookingDetailsError = null;
    notifyListeners();

    try {
      final live = await _repo.fetchBookingDetails(bookingId);
      if (live != null) {
        final vId = live['vehicle_type'];
        live['vehicle_name'] ??= getVehicleName(vId);
        if (live['estimated_fare'] == null && live['final_fare'] == null) {
          final distRaw = live['distance_km'];
          final dist = distRaw is num
              ? distRaw.toDouble()
              : (double.tryParse(distRaw?.toString() ?? '') ?? 5.0);
          PorterVehicleType? match;
          for (final v in _vehicles) {
            if (v.id == vId?.toString()) {
              match = v;
              break;
            }
          }
          final basePrice = match?.basePrice ?? 300.0;
          final perKm = match?.perKmRate ?? 15.0;
          live['estimated_fare'] =
              double.parse((basePrice + (dist * perKm)).toStringAsFixed(2));
        }
        _activeBooking = {
          if (_activeBooking != null) ..._activeBooking!,
          ...live,
        };
      }
    } catch (e) {
      debugPrint('[PorterViewModel] fetchBookingDetails error: $e');
      _bookingDetailsError = 'Failed to load booking details.';
    } finally {
      _isLoadingBookingDetails = false;
      notifyListeners();
    }
    return _activeBooking;
  }
}
