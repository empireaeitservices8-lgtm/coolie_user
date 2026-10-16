import 'package:flutter/foundation.dart';
import 'package:cooli/features/ride/model/ride_model.dart';
import 'package:cooli/features/ride/repo/ride_repo.dart';
import 'package:cooli/providers/view_model.dart';
import 'package:cooli/services/session_manager.dart';

class RideViewModel extends ViewModel {
  final RideRepo _repo;

  RideViewModel({RideRepo? repo}) : _repo = repo ?? RideRepo() {
    _loadLoggedInUser();
    loadRideOptions();
  }

  int? _userId;
  int? get userId => _userId;

  void _loadLoggedInUser() async {
    _userId = await SessionManager().getLoggedInUserId();
    notifyListeners();
  }

  String _pickupLocation = '';
  String get pickupLocation => _pickupLocation;

  String _dropLocation = '';
  String get dropLocation => _dropLocation;

  double? _pickupLat;
  double? get pickupLat => _pickupLat;
  double? _pickupLng;
  double? get pickupLng => _pickupLng;

  double? _dropLat;
  double? get dropLat => _dropLat;
  double? _dropLng;
  double? get dropLng => _dropLng;

  List<RideOption> _rideOptions = [];
  List<RideOption> get rideOptions => _rideOptions;

  RideOption? _selectedOption;
  RideOption? get selectedOption => _selectedOption;

  DriverModel? _driver;
  DriverModel? get driver => _driver;

  int _userRating = 5;
  int get userRating => _userRating;

  void loadRideOptions() async {
    isLoading = true;
    _rideOptions = _repo.getRideOptions();
    if (_rideOptions.isNotEmpty) {
      _selectedOption = _rideOptions.firstWhere(
        (o) => o.name.toLowerCase() == 'car' || o.id == '12',
        orElse: () => _rideOptions.first,
      );
    }
    _driver = _repo.getAssignedDriver();
    notifyListeners();

    try {
      final live = await _repo.fetchVehicleTypes();
      if (live.isNotEmpty) {
        _rideOptions = live;
        if (_selectedOption == null ||
            !_rideOptions.any((o) => o.id == _selectedOption!.id)) {
          _selectedOption = _rideOptions.firstWhere(
            (o) => o.name.toLowerCase() == 'car' || o.id == '12',
            orElse: () => _rideOptions.first,
          );
        }
      }
    } catch (_) {
      // Keep existing options
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setPickup(String location, {double? lat, double? lng}) {
    _pickupLocation = location;
    if (lat != null && lng != null) {
      _pickupLat = lat;
      _pickupLng = lng;
    }
    notifyListeners();
  }

  void setDrop(String location, {double? lat, double? lng}) {
    _dropLocation = location;
    if (lat != null && lng != null) {
      _dropLat = lat;
      _dropLng = lng;
    }
    notifyListeners();
  }

  bool _isCalculatingFare = false;
  bool get isCalculatingFare => _isCalculatingFare;

  RideCalculateFareResponse? _fareCalculationResponse;
  RideCalculateFareResponse? get fareCalculationResponse =>
      _fareCalculationResponse;

  double? _calculatedDistanceKm;
  double? get calculatedDistanceKm => _calculatedDistanceKm;

  void selectOption(RideOption option) {
    _selectedOption = option;
    notifyListeners();
    calculateFareForOption(option);
  }

  Future<void> calculateFareForOption(RideOption option) async {
    _isCalculatingFare = true;
    notifyListeners();

    final pAddress =
        _pickupLocation.isNotEmpty ? _pickupLocation : 'MG Road, Bangalore';
    final dAddress =
        _dropLocation.isNotEmpty ? _dropLocation : 'Indiranagar, Bangalore';
    final pLat = _pickupLat ?? 12.9716;
    final pLng = _pickupLng ?? 77.5946;
    final dLat = _dropLat ?? 12.9784;
    final dLng = _dropLng ?? 77.6408;
    final vId = int.tryParse(option.id) ?? 10;

    try {
      final res = await _repo.calculateFare(
        pickupAddress: pAddress,
        vehicleTypeId: vId,
        pickupLatitude: pLat,
        pickupLongitude: pLng,
        dropAddress: dAddress,
        dropLatitude: dLat,
        dropLongitude: dLng,
      );

      if (res != null && res.estimates.isNotEmpty) {
        _fareCalculationResponse = res;
        _calculatedDistanceKm = res.distanceKm;

        final estimate = res.estimates.first;
        final updatedOption = option.copyWith(
          fare: estimate.estimatedFare,
          originalFare: (estimate.estimatedFare * 1.15).roundToDouble(),
          eta: '${estimate.estimatedTravelTime} min trip',
          fareEstimate: estimate,
        );

        final index = _rideOptions.indexWhere((o) => o.id == option.id);
        if (index != -1) {
          _rideOptions[index] = updatedOption;
        }
        if (_selectedOption?.id == option.id) {
          _selectedOption = updatedOption;
        }
      }
    } catch (e) {
      debugPrint('[RideViewModel] calculateFare error: $e');
    } finally {
      _isCalculatingFare = false;
      notifyListeners();
    }
  }

  void calculateFaresForAvailableOptions() {
    if (_selectedOption != null) {
      calculateFareForOption(_selectedOption!);
    } else if (_rideOptions.isNotEmpty) {
      calculateFareForOption(_rideOptions.first);
    }
  }

  void setRating(int rating) {
    _userRating = rating;
    notifyListeners();
  }

  bool _isCreatingBooking = false;
  bool get isCreatingBooking => _isCreatingBooking;

  RideBookingData? _latestBooking;
  RideBookingData? get latestBooking => _latestBooking;

  String? _bookingError;
  String? get bookingError => _bookingError;

  Future<RideBookingResponse?> createBooking(RideOption option,
      {int? customUserId, String? paymentMethod}) async {
    _isCreatingBooking = true;
    _bookingError = null;
    notifyListeners();

    try {
      // Get user ID from logged-in session
      final effectiveUserId = customUserId ??
          await SessionManager().getLoggedInUserId() ??
          _userId ??
          1;
      _userId = effectiveUserId;
      debugPrint(
          '[RideViewModel] Creating ride booking for logged-in User ID: $effectiveUserId');

      final payload = {
        'user': effectiveUserId,
        'vehicle_type': int.tryParse(option.id) ?? 10,
        'pickup_address':
            _pickupLocation.isNotEmpty ? _pickupLocation : 'MG Road, Bangalore',
        'pickup_latitude': _pickupLat ?? 12.9716,
        'pickup_longitude': _pickupLng ?? 77.5946,
        'drop_address':
            _dropLocation.isNotEmpty ? _dropLocation : 'Indiranagar, Bangalore',
        'drop_latitude': _dropLat ?? 0.00,
        'drop_longitude': _dropLng ?? 0.00,
        'number_of_passengers': int.tryParse(option.capacity) ?? 1,
        'payment_method': paymentMethod ?? 'cash',
      };

      debugPrint(
          '[RideViewModel] Calling createRideBooking with payload: $payload');
      final response = await _repo.createRideBooking(payload);
      if (response != null && response.booking != null) {
        _latestBooking = response.booking;
        debugPrint(
            '[RideViewModel] Booking created successfully: ID=${response.booking!.id}');
        return response;
      } else {
        _bookingError =
            response?.message ?? response?.error ?? 'Failed to create booking';
        return response;
      }
    } catch (e) {
      debugPrint('[RideViewModel] createBooking error: $e');
      _bookingError = e.toString();
      return null;
    } finally {
      _isCreatingBooking = false;
      notifyListeners();
    }
  }

  List<RideBookingData> _rideBookings = [];
  List<RideBookingData> get rideBookings => _rideBookings;

  bool _isLoadingBookings = false;
  bool get isLoadingBookings => _isLoadingBookings;

  String _rideFilter = 'All'; // 'All', 'Active', 'Assigned', 'Completed'
  String get rideFilter => _rideFilter;

  List<RideBookingData> get filteredRideBookings {
    if (_rideFilter == 'Active') {
      return _rideBookings.where((r) {
        final st = r.status.toLowerCase();
        return st == 'pending' || st == 'in_progress' || st == 'started';
      }).toList();
    } else if (_rideFilter == 'Assigned') {
      return _rideBookings.where((r) {
        final st = r.status.toLowerCase();
        return st == 'driver_assigned' ||
            (r.driverName != null && r.driverName!.isNotEmpty);
      }).toList();
    } else if (_rideFilter == 'Completed') {
      return _rideBookings
          .where((r) => r.status.toLowerCase() == 'completed')
          .toList();
    }
    return _rideBookings;
  }

  void setRideFilter(String filter) {
    _rideFilter = filter;
    notifyListeners();
  }

  Future<List<RideBookingData>> fetchUserRideBookings({int? userId}) async {
    _isLoadingBookings = true;
    notifyListeners();

    try {
      final targetUserId = userId ?? await SessionManager().getLoggedInUserId() ?? 1;
      _userId = targetUserId;
      final list = await _repo.fetchRideBookings(userId: targetUserId);
      _rideBookings = list;
      return list;
    } catch (e) {
      debugPrint('[RideViewModel] fetchUserRideBookings error: $e');
      return [];
    } finally {
      _isLoadingBookings = false;
      notifyListeners();
    }
  }
}
