import 'package:flutter/material.dart';
import 'package:cooli/features/ride/model/ride_model.dart';
import 'package:cooli/features/ride/repo/ride_repo.dart';
import 'package:cooli/providers/view_model.dart';

class RideViewModel extends ViewModel {
  final RideRepo _repo;

  RideViewModel({RideRepo? repo}) : _repo = repo ?? RideRepo() {
    _initDefaults();
  }

  late RidePlace _pickupPlace;
  RidePlace get pickupPlace => _pickupPlace;

  RidePlace? _dropPlace;
  RidePlace? get dropPlace => _dropPlace;

  String get pickupLocation => _pickupPlace.title;
  String get pickupAddress => _pickupPlace.address;
  String get dropLocation => _dropPlace?.title ?? _repo.getDefaultDrop().title;
  String get dropAddress => _dropPlace?.address ?? _repo.getDefaultDrop().address;

  String? _stopLocation;
  String? get stopLocation => _stopLocation;

  String _pickupNote = '';
  String get pickupNote => _pickupNote;

  RideScheduleType _scheduleType = RideScheduleType.now;
  RideScheduleType get scheduleType => _scheduleType;

  String _scheduledTimeLabel = 'Today, 5:30 PM';
  String get scheduledTimeLabel => _scheduledTimeLabel;

  List<RidePlace> _places = [];
  List<RidePlace> get places => _places;

  List<RideOption> _rideOptions = [];
  List<RideOption> get rideOptions => _rideOptions;

  RideOption? _selectedOption;
  RideOption? get selectedOption => _selectedOption;

  List<RidePaymentMethod> _paymentMethods = [];
  List<RidePaymentMethod> get paymentMethods => _paymentMethods;

  late RidePaymentMethod _selectedPaymentMethod;
  RidePaymentMethod get selectedPaymentMethod => _selectedPaymentMethod;

  String? _promoCode;
  String? get promoCode => _promoCode;

  double _promoDiscount = 0;
  double get promoDiscount => _promoDiscount;

  DriverModel? _driver;
  DriverModel? get driver => _driver;

  RideTripStage _tripStage = RideTripStage.idle;
  RideTripStage get tripStage => _tripStage;

  final List<RideChatMessage> _chatMessages = [];
  List<RideChatMessage> get chatMessages => List.unmodifiable(_chatMessages);

  int _userRating = 5;
  int get userRating => _userRating;

  final Set<String> _selectedCompliments = {'Smooth Driving'};
  Set<String> get selectedCompliments => Set.unmodifiable(_selectedCompliments);

  double _tipAmount = 0;
  double get tipAmount => _tipAmount;

  bool get hasDestination => _dropPlace != null;

  double get routeDistanceKm {
    final target = _dropPlace ?? _repo.getDefaultDrop();
    final base = target.distanceKm > 0 ? target.distanceKm : 8.5;
    return _stopLocation != null ? base + 2.4 : base;
  }

  int get routeDurationMinutes {
    final target = _dropPlace ?? _repo.getDefaultDrop();
    final base = target.etaMinutes > 0 ? target.etaMinutes : 18;
    return _stopLocation != null ? base + 6 : base;
  }

  double fareFor(RideOption option) {
    return option.calculateFare(routeDistanceKm, discount: _promoDiscount);
  }

  double get selectedFare {
    final option = _selectedOption ?? (_rideOptions.isNotEmpty ? _rideOptions.first : null);
    if (option == null) return 250.0;
    return fareFor(option);
  }

  double get finalTotalFare => selectedFare + _tipAmount;

  FareBreakdown? get selectedFareBreakdown {
    final option = _selectedOption;
    if (option == null) return null;
    return option.getFareBreakdown(routeDistanceKm, discount: _promoDiscount);
  }

  List<String> get cancellationReasons => _repo.getCancellationReasons();
  List<String> get complimentTags => _repo.getComplimentTags();
  List<String> get quickChatReplies => _repo.getQuickChatReplies();

  void _initDefaults() {
    _pickupPlace = _repo.getDefaultPickup();
    _dropPlace = null;
    _places = _repo.getSavedAndRecentPlaces();
    _rideOptions = _repo.getRideOptions();
    if (_rideOptions.length > 2) {
      _selectedOption = _rideOptions[2]; // Premier / Comfort default
    } else if (_rideOptions.isNotEmpty) {
      _selectedOption = _rideOptions.first;
    }
    _paymentMethods = _repo.getPaymentMethods();
    _selectedPaymentMethod = _paymentMethods.first;
    _driver = _repo.getAssignedDriver(rideOptionId: _selectedOption?.id);
    notifyListeners();
  }

  void loadRideOptions() {
    _rideOptions = _repo.getRideOptions();
    _selectedOption ??= _rideOptions.isNotEmpty ? _rideOptions.first : null;
    _driver = _repo.getAssignedDriver(rideOptionId: _selectedOption?.id);
    notifyListeners();
  }

  void setPickupPlace(RidePlace place) {
    _pickupPlace = place;
    notifyListeners();
  }

  void setPickup(String location) {
    final trimmed = location.trim();
    if (trimmed.isEmpty) return;
    _pickupPlace = RidePlace(
      id: 'custom_pickup',
      title: trimmed,
      address: '$trimmed, Kochi',
      tag: 'Pickup',
      distanceKm: 0,
      etaMinutes: 0,
      icon: Icons.my_location_rounded,
      mapNormalizedPos: _pickupPlace.mapNormalizedPos,
    );
    notifyListeners();
  }

  void setDropPlace(RidePlace place) {
    _dropPlace = place;
    notifyListeners();
  }

  void setDrop(String location) {
    final trimmed = location.trim();
    if (trimmed.isEmpty) {
      _dropPlace = null;
      notifyListeners();
      return;
    }
    final existing = _places.where(
      (p) => p.title.toLowerCase() == trimmed.toLowerCase(),
    );
    if (existing.isNotEmpty) {
      _dropPlace = existing.first;
    } else {
      final pseudoDistance = (6.0 + (trimmed.length % 14)).toDouble();
      _dropPlace = RidePlace(
        id: 'custom_drop_${trimmed.hashCode}',
        title: trimmed,
        address: '$trimmed, Kochi',
        tag: 'Custom',
        distanceKm: pseudoDistance,
        etaMinutes: (pseudoDistance * 1.8).round(),
        icon: Icons.location_on_rounded,
        mapNormalizedPos: const Offset(0.76, 0.25),
      );
    }
    notifyListeners();
  }

  void swapPickupAndDrop() {
    if (_dropPlace == null) return;
    final oldPickup = _pickupPlace;
    final oldDrop = _dropPlace!;
    _pickupPlace = RidePlace(
      id: oldDrop.id,
      title: oldDrop.title,
      address: oldDrop.address,
      tag: oldDrop.tag,
      distanceKm: oldDrop.distanceKm,
      etaMinutes: oldDrop.etaMinutes,
      icon: oldDrop.icon,
      mapNormalizedPos: const Offset(0.24, 0.68),
    );
    _dropPlace = RidePlace(
      id: oldPickup.id,
      title: oldPickup.title,
      address: oldPickup.address,
      tag: oldPickup.tag,
      distanceKm: oldDrop.distanceKm > 0 ? oldDrop.distanceKm : 11.5,
      etaMinutes: oldDrop.etaMinutes > 0 ? oldDrop.etaMinutes : 24,
      icon: oldPickup.icon,
      mapNormalizedPos: const Offset(0.78, 0.24),
    );
    notifyListeners();
  }

  void setStop(String? stop) {
    final trimmed = stop?.trim();
    _stopLocation = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    notifyListeners();
  }

  void setPickupNote(String note) {
    _pickupNote = note.trim();
    notifyListeners();
  }

  void setSchedule(RideScheduleType type, {String? timeLabel}) {
    _scheduleType = type;
    if (timeLabel != null) {
      _scheduledTimeLabel = timeLabel;
    }
    notifyListeners();
  }

  List<RidePlace> searchPlaces(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _places;
    return _places
        .where(
          (p) =>
              p.title.toLowerCase().contains(q) ||
              p.address.toLowerCase().contains(q) ||
              p.tag.toLowerCase().contains(q),
        )
        .toList();
  }

  void selectOption(RideOption option) {
    _selectedOption = option;
    _driver = _repo.getAssignedDriver(rideOptionId: option.id);
    notifyListeners();
  }

  void selectPaymentMethod(RidePaymentMethod method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  bool applyPromoCode(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized == 'COOLI20' || normalized == 'UBER20' || normalized == 'SAVE30') {
      _promoCode = normalized;
      _promoDiscount = normalized == 'SAVE30' ? 30.0 : 20.0;
      notifyListeners();
      return true;
    }
    return false;
  }

  void clearPromoCode() {
    _promoCode = null;
    _promoDiscount = 0;
    notifyListeners();
  }

  void enterPickupConfirmation() {
    _tripStage = RideTripStage.confirmingPickup;
    notifyListeners();
  }

  void startSearchingDriver() {
    _driver = _repo.getAssignedDriver(rideOptionId: _selectedOption?.id);
    _tripStage = RideTripStage.searchingDriver;
    _chatMessages
      ..clear()
      ..add(
        RideChatMessage(
          text: "Hi, I'm ${_driver?.name ?? 'your driver'}. Heading towards you shortly!",
          isRider: false,
          timeLabel: 'Now',
        ),
      );
    notifyListeners();
  }

  void assignDriver() {
    _driver = _repo.getAssignedDriver(rideOptionId: _selectedOption?.id);
    _tripStage = RideTripStage.driverEnRoute;
    notifyListeners();
  }

  void markDriverArrived() {
    _tripStage = RideTripStage.driverArrived;
    notifyListeners();
  }

  void startTrip() {
    _tripStage = RideTripStage.inProgress;
    notifyListeners();
  }

  void completeTrip() {
    _tripStage = RideTripStage.completed;
    notifyListeners();
  }

  void cancelRide([String? reason]) {
    _tripStage = RideTripStage.cancelled;
    _chatMessages.clear();
    notifyListeners();
  }

  void sendChatMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _chatMessages.add(
      RideChatMessage(
        text: trimmed,
        isRider: true,
        timeLabel: 'Just now',
      ),
    );
    _chatMessages.add(
      const RideChatMessage(
        text: 'Got it, thanks! See you shortly.',
        isRider: false,
        timeLabel: 'Just now',
      ),
    );
    notifyListeners();
  }

  void setRating(int rating) {
    _userRating = rating;
    notifyListeners();
  }

  void toggleCompliment(String tag) {
    if (_selectedCompliments.contains(tag)) {
      _selectedCompliments.remove(tag);
    } else {
      _selectedCompliments.add(tag);
    }
    notifyListeners();
  }

  void setTip(double amount) {
    _tipAmount = amount;
    notifyListeners();
  }

  void resetTrip() {
    _tripStage = RideTripStage.idle;
    _dropPlace = null;
    _pickupNote = '';
    _stopLocation = null;
    _tipAmount = 0;
    _userRating = 5;
    _selectedCompliments
      ..clear()
      ..add('Smooth Driving');
    _chatMessages.clear();
    notifyListeners();
  }
}
