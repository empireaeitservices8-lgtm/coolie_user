import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cooli/features/ride/view_model/ride_view_model.dart';
import 'package:cooli/features/ride/view/ride_selection_view.dart';
import 'package:cooli/features/ride/service/ride_location_service.dart';
import 'package:cooli/features/ride/view/ride_map_picker_view.dart';
import 'package:cooli/features/ride/model/ride_model.dart';
import 'package:cooli/features/ride/repo/ride_repo.dart';
import 'package:cooli/services/session_manager.dart';
import 'package:intl/intl.dart';

class RideBookingView extends StatefulWidget {
  static const String routeName = '/ride-booking';
  const RideBookingView({super.key});

  @override
  State<RideBookingView> createState() => _RideBookingViewState();
}

class _RideBookingViewState extends State<RideBookingView> {
  late RideViewModel _viewModel;
  late TextEditingController _pickupController;
  late TextEditingController _dropController;
  final RideLocationService _locationService = RideLocationService();

  // Coordinates state: null by default (empty search)
  double? _pickupLat;
  double? _pickupLng;
  double? _dropLat;
  double? _dropLng;

  GoogleMapController? _mapController;
  List<LatLng> _routePoints = [];
  String _routeEstimateText = '';
  bool _isFetchingRoute = false;

  // Active map tap mode: true = Setting Pickup, false = Setting Drop-off
  bool _isSettingPickupOnMap = false;

  // Live device location state
  LatLng? _currentDeviceLocation;
  bool _isLoadingCurrentLocation = false;

  // Default coordinate: Kochi fallback
  static const LatLng _defaultCurrentLocation = LatLng(9.9816, 76.2763);

  List<LocationResult> _pickupSuggestions = [];
  List<LocationResult> _dropSuggestions = [];

  int? _loggedInUserId;
  bool _isLoadingRecentRides = false;
  List<RideBookingData> _recentRides = [];

  Future<void> _loadRecentDestinations() async {
    await _loadRecentRides();
  }

  Future<void> _loadRecentRides() async {
    final userId = await SessionManager().getLoggedInUserId();
    if (!mounted) return;

    if (userId == null || userId <= 0) {
      setState(() {
        _loggedInUserId = null;
        _recentRides = [];
        _isLoadingRecentRides = false;
      });
      return;
    }

    setState(() {
      _loggedInUserId = userId;
      _isLoadingRecentRides = true;
    });

    // 1. Load user-specific cached rides for instant presentation
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('recent_rides_user_$userId');
      if (cached != null && cached.isNotEmpty && mounted) {
        final list = (jsonDecode(cached) as List)
            .map((item) => RideBookingData.fromJson(Map<String, dynamic>.from(item as Map)))
            .where((b) => b.user == userId)
            .toList();
        if (list.isNotEmpty && mounted) {
          setState(() {
            _recentRides = list;
          });
        }
      }
    } catch (_) {}

    // 2. Fetch live recent rides strictly for logged-in user: GET /ride/bookings/list/?user_id=$userId
    try {
      final repo = RideRepo();
      final bookings = await repo.fetchRideBookings(userId: userId);

      if (mounted) {
        // Strictly based on logged-in user id
        final userRides = bookings.where((b) => b.user == userId).toList();
        setState(() {
          _recentRides = userRides;
          _isLoadingRecentRides = false;
        });

        // Cache for this user
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'recent_rides_user_$userId',
            jsonEncode(userRides.take(20).map((b) => b.toJson()).toList()),
          );
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[RideBookingView] _loadRecentRides error: $e');
      if (mounted) {
        setState(() => _isLoadingRecentRides = false);
      }
    }
  }

  void _selectRecentRide(RideBookingData ride) {
    String cleanDrop = ride.dropAddress.trim();
    while (cleanDrop.startsWith(',') || cleanDrop.startsWith(' ')) {
      cleanDrop = cleanDrop.substring(1).trim();
    }
    String cleanPickup = ride.pickupAddress.trim();
    while (cleanPickup.startsWith(',') || cleanPickup.startsWith(' ')) {
      cleanPickup = cleanPickup.substring(1).trim();
    }

    _setPickupLocation(
      cleanPickup.isNotEmpty ? cleanPickup : 'Pickup Spot',
      ride.pickupLatitude,
      ride.pickupLongitude,
    );
    _setDropLocation(
      cleanDrop.isNotEmpty ? cleanDrop : 'Destination',
      ride.dropLatitude,
      ride.dropLongitude,
      subtitle: cleanPickup,
    );

    // Auto-select matching vehicle type if available
    final vId = ride.vehicleType.toString();
    final matchingOpt = _viewModel.rideOptions.where((o) => o.id == vId).toList();
    if (matchingOpt.isNotEmpty) {
      _viewModel.selectOption(matchingOpt.first);
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ride selected: $cleanPickup -> $cleanDrop',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _applyBookingRoute(RideBookingData booking) => _selectRecentRide(booking);

  Future<void> _saveRecentDestination({
    required String title,
    required String subtitle,
    required double lat,
    required double lng,
  }) async {
    // Rides are persisted in the backend database
  }


  Future<void> _handleHomeTap() async {
    final prefs = await SharedPreferences.getInstance();
    final homeTitle = prefs.getString('saved_home_title');
    final homeLat = prefs.getDouble('saved_home_lat');
    final homeLng = prefs.getDouble('saved_home_lng');
    if (homeTitle != null && homeLat != null && homeLng != null) {
      _setDropLocation(homeTitle, homeLat, homeLng, subtitle: 'Home');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pick your Home location on the map'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      _openMapPicker(isPickup: false, saveAsType: 'home');
    }
  }

  Future<void> _handleWorkTap() async {
    final prefs = await SharedPreferences.getInstance();
    final workTitle = prefs.getString('saved_work_title');
    final workLat = prefs.getDouble('saved_work_lat');
    final workLng = prefs.getDouble('saved_work_lng');
    if (workTitle != null && workLat != null && workLng != null) {
      _setDropLocation(workTitle, workLat, workLng, subtitle: 'Work');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pick your Work location on the map'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      _openMapPicker(isPickup: false, saveAsType: 'work');
    }
  }

  Future<void> _saveHomeLocation(String title, double lat, double lng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_home_title', title);
      await prefs.setDouble('saved_home_lat', lat);
      await prefs.setDouble('saved_home_lng', lng);
    } catch (_) {}
  }

  Future<void> _saveWorkLocation(String title, double lat, double lng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_work_title', title);
      await prefs.setDouble('saved_work_lat', lat);
      await prefs.setDouble('saved_work_lng', lng);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    // Start clean with live locating indicator while device GPS acquires location
    _pickupController = TextEditingController();
    _dropController = TextEditingController();
    _pickupLat = null;
    _pickupLng = null;
    _dropLat = null;
    _dropLng = null;
    _isLoadingCurrentLocation = true;

    _loadRecentDestinations();
    // Always detect and set pickup location to user's live current location
    _detectCurrentLocation(setAsPickup: true, showFeedback: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel = context.read<RideViewModel>();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _swapLocations() {
    setState(() {
      final tempText = _pickupController.text;
      final tempLat = _pickupLat;
      final tempLng = _pickupLng;

      _pickupController.text = _dropController.text;
      _pickupLat = _dropLat;
      _pickupLng = _dropLng;

      _dropController.text = tempText;
      _dropLat = tempLat;
      _dropLng = tempLng;

      _viewModel.setPickup(_pickupController.text, lat: _pickupLat, lng: _pickupLng);
      _viewModel.setDrop(_dropController.text, lat: _dropLat, lng: _dropLng);
      _pickupSuggestions = [];
      _dropSuggestions = [];
    });
    _updateRouteAndMap();
  }

  String _formatFullAddress(String title, String subtitle, {String defaultName = 'Location'}) {
    final cleanTitle = title.trim();
    final cleanSub = subtitle.trim();

    final isTitleCoord = RegExp(r'^-?\d{1,3}\.\d+[\s,]+-?\d{1,3}\.\d+$').hasMatch(cleanTitle) ||
        cleanTitle.toLowerCase() == 'pinned location' ||
        cleanTitle.toLowerCase() == 'device location' ||
        cleanTitle.toLowerCase() == 'current spot' ||
        cleanTitle.toLowerCase() == 'map location' ||
        cleanTitle.toLowerCase() == 'selected spot';

    final isSubCoord = RegExp(r'^-?\d{1,3}\.\d+[\s,]+-?\d{1,3}\.\d+$').hasMatch(cleanSub) ||
        cleanSub.toLowerCase() == 'device location' ||
        cleanSub.toLowerCase() == 'map location' ||
        cleanSub.toLowerCase() == 'current spot' ||
        cleanSub.toLowerCase() == 'selected spot' ||
        cleanSub.toLowerCase() == 'selected address' ||
        cleanSub.toLowerCase() == 'selected destination' ||
        cleanSub.toLowerCase() == 'home' ||
        cleanSub.toLowerCase() == 'work';

    final validTitle = isTitleCoord ? '' : cleanTitle;
    final validSub = isSubCoord ? '' : cleanSub;

    if (validTitle.isNotEmpty && validSub.isNotEmpty) {
      final parts = <String>[];
      final seen = <String>{};

      for (final part in [...validTitle.split(','), ...validSub.split(',')]) {
        final trimmed = part.trim();
        if (trimmed.isNotEmpty && !seen.contains(trimmed.toLowerCase())) {
          seen.add(trimmed.toLowerCase());
          parts.add(trimmed);
        }
      }

      if (parts.isNotEmpty) {
        return parts.join(', ');
      }
    } else if (validTitle.isNotEmpty) {
      return validTitle;
    } else if (validSub.isNotEmpty) {
      return validSub;
    }
    return defaultName;
  }

  /// Detects the user's real device GPS/client location and centers the map
  Future<void> _detectCurrentLocation({bool setAsPickup = false, bool showFeedback = false}) async {
    try {
      final status = await Permission.location.request();
      if (!status.isGranted && !status.isLimited) {
        if (showFeedback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please grant location permission to detect your current location'),
              backgroundColor: Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoadingCurrentLocation = true);
    }

    final clientLoc = await _locationService.getCurrentClientLocation();
    if (mounted) {
      setState(() => _isLoadingCurrentLocation = false);
      if (clientLoc != null) {
        final pos = LatLng(clientLoc.latitude, clientLoc.longitude);
        _currentDeviceLocation = pos;
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(pos, 15.5),
        );

        if (setAsPickup) {
          final title = _formatFullAddress(clientLoc.title, clientLoc.subtitle, defaultName: 'Current Location');
          _pickupController.text = title;
          _pickupLat = clientLoc.latitude;
          _pickupLng = clientLoc.longitude;
          _viewModel.setPickup(title, lat: _pickupLat, lng: _pickupLng);
          _pickupSuggestions = [];
          _updateRouteAndMap();

          if (showFeedback) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Pickup set to current location: $title',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF0F172A),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        }
      } else if (setAsPickup) {
        final target = _currentDeviceLocation ?? _defaultCurrentLocation;
        final res = await _locationService.reverseGeocode(target.latitude, target.longitude);
        final title = _formatFullAddress(res?.title ?? '', res?.subtitle ?? '', defaultName: 'Current Location');
        _pickupController.text = title;
        _pickupLat = target.latitude;
        _pickupLng = target.longitude;
        _viewModel.setPickup(title, lat: _pickupLat, lng: _pickupLng);
        _pickupSuggestions = [];
        _updateRouteAndMap();
      }
    }
  }

  /// Takes pickup location from current device location on the map
  void _useCurrentLocationAsPickup() {
    _detectCurrentLocation(setAsPickup: true, showFeedback: true);
  }

  /// Takes location directly from tapping on the current location map
  void _onMapTapped(LatLng position) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 10),
            Text('Selecting location from map...'),
          ],
        ),
        backgroundColor: Color(0xFF0F172A),
        duration: Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final res = await _locationService.reverseGeocode(position.latitude, position.longitude);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (_isSettingPickupOnMap || _pickupController.text.trim().isEmpty) {
      // Setting Pickup location
      final title = _formatFullAddress(res?.title ?? '', res?.subtitle ?? '', defaultName: 'Pickup Spot');
      _setPickupLocation(title, position.latitude, position.longitude, subtitle: res?.subtitle ?? '');
      // Automatically switch to setting Drop-off destination so the next tap sets destination
      setState(() {
        _isSettingPickupOnMap = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Pickup set: $title\nNow tap map to set destination',
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      // Setting Drop-off destination
      final title = _formatFullAddress(res?.title ?? '', res?.subtitle ?? '', defaultName: 'Selected Destination');
      _setDropLocation(title, position.latitude, position.longitude, subtitle: res?.subtitle ?? '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFFEF4444), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Destination set: $title',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    _updateRouteAndMap();
  }

  void _clearPickup() {
    setState(() {
      _pickupController.clear();
      _pickupLat = null;
      _pickupLng = null;
      _pickupSuggestions = [];
      _isSettingPickupOnMap = true;
      _viewModel.setPickup('');
    });
    _updateRouteAndMap();
  }

  void _clearDrop() {
    setState(() {
      _dropController.clear();
      _dropLat = null;
      _dropLng = null;
      _dropSuggestions = [];
      _isSettingPickupOnMap = false;
      _viewModel.setDrop('');
    });
    _updateRouteAndMap();
  }

  void _setPickupLocation(String title, double lat, double lng, {String subtitle = ''}) {
    final cleanTitle = _formatFullAddress(title, subtitle, defaultName: 'Current Location');
    setState(() {
      _pickupController.text = cleanTitle;
      _pickupLat = lat;
      _pickupLng = lng;
      _pickupSuggestions = [];
      _viewModel.setPickup(cleanTitle, lat: lat, lng: lng);
    });
    _updateRouteAndMap();
  }

  void _setDropLocation(String title, double lat, double lng, {String subtitle = ''}) {
    final cleanTitle = _formatFullAddress(title, subtitle, defaultName: 'Selected Destination');
    setState(() {
      _dropController.text = cleanTitle;
      _dropLat = lat;
      _dropLng = lng;
      _dropSuggestions = [];
      _viewModel.setDrop(cleanTitle, lat: lat, lng: lng);
    });
    _saveRecentDestination(
      title: cleanTitle,
      subtitle: subtitle.isNotEmpty ? subtitle : 'Selected Destination',
      lat: lat,
      lng: lng,
    );
    _updateRouteAndMap();
  }

  void _onPickupSearch(String query) async {
    _viewModel.setPickup(query);
    if (query.trim().isEmpty) {
      setState(() {
        _pickupSuggestions = [];
        _pickupLat = null;
        _pickupLng = null;
      });
      _updateRouteAndMap();
      return;
    }
    final results = await _locationService.searchPlaces(query);
    if (mounted) {
      setState(() {
        _pickupSuggestions = results;
      });
    }
  }

  void _onDropSearch(String query) async {
    _viewModel.setDrop(query);
    if (query.trim().isEmpty) {
      setState(() {
        _dropSuggestions = [];
        _dropLat = null;
        _dropLng = null;
      });
      _updateRouteAndMap();
      return;
    }
    final results = await _locationService.searchPlaces(query);
    if (mounted) {
      setState(() {
        _dropSuggestions = results;
      });
    }
  }

  void _openMapPicker({required bool isPickup, String? saveAsType}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideMapPickerView(
          isPickup: isPickup,
          initialPickupAddress: _pickupController.text.isNotEmpty ? _pickupController.text : null,
          initialDropAddress: _dropController.text.isNotEmpty ? _dropController.text : null,
          initialPickupLat: _pickupLat ?? _currentDeviceLocation?.latitude,
          initialPickupLng: _pickupLng ?? _currentDeviceLocation?.longitude,
          initialDropLat: _dropLat,
          initialDropLng: _dropLng,
        ),
      ),
    );
    if (result != null) {
      if (result is RideMapSelectionResult) {
        final pTitle = _formatFullAddress(result.pickup.title, result.pickup.subtitle, defaultName: 'Current Location');
        final dTitle = _formatFullAddress(result.drop.title, result.drop.subtitle, defaultName: 'Selected Destination');

        if (pTitle.isNotEmpty) {
          _pickupController.text = pTitle;
          _pickupLat = result.pickup.latitude;
          _pickupLng = result.pickup.longitude;
          _viewModel.setPickup(pTitle, lat: _pickupLat, lng: _pickupLng);
        }
        if (dTitle.isNotEmpty) {
          _setDropLocation(
            dTitle,
            result.drop.latitude,
            result.drop.longitude,
            subtitle: result.drop.subtitle,
          );
          if (saveAsType == 'home') {
            _saveHomeLocation(dTitle, result.drop.latitude, result.drop.longitude);
          } else if (saveAsType == 'work') {
            _saveWorkLocation(dTitle, result.drop.latitude, result.drop.longitude);
          }
        }
      } else if (result is LocationResult) {
        final title = _formatFullAddress(result.title, result.subtitle, defaultName: isPickup ? 'Current Location' : 'Selected Destination');
        if (isPickup) {
          _setPickupLocation(title, result.latitude, result.longitude, subtitle: result.subtitle);
        } else {
          _setDropLocation(
            title,
            result.latitude,
            result.longitude,
            subtitle: result.subtitle,
          );
          if (saveAsType == 'home') {
            _saveHomeLocation(title, result.latitude, result.longitude);
          } else if (saveAsType == 'work') {
            _saveWorkLocation(title, result.latitude, result.longitude);
          }
        }
      }
      _updateRouteAndMap();
    }
  }

  void _updateRouteAndMap() async {
    // 2 locations selected: fetch authentic road navigation route and animate bounds
    if (_pickupLat != null && _dropLat != null) {
      final start = LatLng(_pickupLat!, _pickupLng!);
      final end = LatLng(_dropLat!, _dropLng!);

      setState(() {
        _isFetchingRoute = true;
      });

      final details = await _locationService.getRouteDetails(start, end);
      if (mounted) {
        final points = details?.coordinates ?? await _locationService.getRouteCoordinates(start, end);
        final distText = details != null
            ? '${details.distanceKm.toStringAsFixed(1)} km • ${details.durationMinutes} mins'
            : RideLocationService.calculateRideEstimate(
                lat1: _pickupLat!,
                lon1: _pickupLng!,
                lat2: _dropLat!,
                lon2: _dropLng!,
              );

        setState(() {
          _routePoints = points;
          _routeEstimateText = distText;
          _isFetchingRoute = false;
        });

        // Calculate bounding box and animate camera to frame entire route
        if (points.isNotEmpty) {
          double south = points.first.latitude;
          double north = points.first.latitude;
          double west = points.first.longitude;
          double east = points.first.longitude;

          for (final p in points) {
            if (p.latitude < south) south = p.latitude;
            if (p.latitude > north) north = p.latitude;
            if (p.longitude < west) west = p.longitude;
            if (p.longitude > east) east = p.longitude;
          }

          final bounds = LatLngBounds(
            southwest: LatLng(south, west),
            northeast: LatLng(north, east),
          );
          _mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 50),
          );
        }
      }
    } else {
      // 0 or 1 location selected: DO NOT draw path, only center on current or selected point
      setState(() {
        _routePoints = [];
        _routeEstimateText = '';
        _isFetchingRoute = false;
      });

      final target = _pickupLat != null
          ? LatLng(_pickupLat!, _pickupLng!)
          : (_dropLat != null
              ? LatLng(_dropLat!, _dropLng!)
              : (_currentDeviceLocation ?? _defaultCurrentLocation));

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(target, 15.0),
      );
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (_pickupLat != null && _dropLat != null) {
      // BOTH locations selected: Show Pickup and Drop pins
      markers.add(
        Marker(
          markerId: const MarkerId('pickup_marker'),
          position: LatLng(_pickupLat!, _pickupLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: _pickupController.text.isNotEmpty ? _pickupController.text : 'Pickup Point',
          ),
        ),
      );
      markers.add(
        Marker(
          markerId: const MarkerId('drop_marker'),
          position: LatLng(_dropLat!, _dropLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Drop-off Destination',
            snippet: _dropController.text.isNotEmpty ? _dropController.text : 'Drop Point',
          ),
        ),
      );
    } else if (_pickupLat != null) {
      // Only Pickup selected
      markers.add(
        Marker(
          markerId: const MarkerId('pickup_marker'),
          position: LatLng(_pickupLat!, _pickupLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: _pickupController.text,
          ),
        ),
      );
    } else if (_dropLat != null) {
      // Only Drop selected
      markers.add(
        Marker(
          markerId: const MarkerId('drop_marker'),
          position: LatLng(_dropLat!, _dropLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Drop-off Destination',
            snippet: _dropController.text,
          ),
        ),
      );
    }

    // In start (when neither is selected), return empty set: NO markers at start!
    return markers;
  }

  Set<Polyline> _buildPolylines() {
    // Rapido / Uber behavior: ONLY draw route path when BOTH 2 locations are selected!
    if (_pickupLat == null || _dropLat == null || _routePoints.isEmpty) {
      return {};
    }

    return {
      Polyline(
        polylineId: const PolylineId('rapido_route_path'),
        points: _routePoints,
        color: const Color(0xFF2563EB),
        width: 5,
        geodesic: false,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  void _proceedToAvailableRides() {
    if (_pickupController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter or select a pickup location'),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (_dropController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter or select a destination / drop location'),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      RideSelectionView.routeName,
      arguments: {
        'pickup': _pickupController.text,
        'drop': _dropController.text,
        'pickupLat': _pickupLat,
        'pickupLng': _pickupLng,
        'dropLat': _dropLat,
        'dropLng': _dropLng,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasBothLocations = _pickupLat != null && _dropLat != null;

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A),
              size: 20,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text(
            'Search Ride Location',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: const Color(0xFFF1F5F9), height: 1),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. From & To Interactive Search Card (Rapido / Uber Style)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            // Pickup "From" Input Container
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Pickup Location (From)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        TextField(
                                          controller: _pickupController,
                                          onTap: () {
                                            setState(() => _isSettingPickupOnMap = true);
                                            if (_pickupLat != null && _pickupLng != null) {
                                              _mapController?.animateCamera(
                                                CameraUpdate.newLatLngZoom(LatLng(_pickupLat!, _pickupLng!), 15.5),
                                              );
                                            }
                                          },
                                          maxLines: 2,
                                          minLines: 1,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                          decoration: InputDecoration(
                                            hintText: _isLoadingCurrentLocation
                                                ? 'Locating your current spot...'
                                                : 'Enter pickup address',
                                            hintStyle: TextStyle(
                                              fontSize: 14,
                                              color: _isLoadingCurrentLocation
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFF94A3B8),
                                              fontWeight: _isLoadingCurrentLocation
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                            ),
                                            isDense: true,
                                            filled: false,
                                            fillColor: Colors.transparent,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 2),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            disabledBorder: InputBorder.none,
                                          ),
                                          onChanged: _onPickupSearch,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_isLoadingCurrentLocation) ...[
                                        const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      if (_pickupController.text.isNotEmpty && !_isLoadingCurrentLocation) ...[
                                        GestureDetector(
                                          onTap: _clearPickup,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFF1F5F9),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close_rounded,
                                              color: Color(0xFF64748B),
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      GestureDetector(
                                        onTap: () => _openMapPicker(isPickup: true),
                                        child: Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE0F2FE),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.map_rounded,
                                            color: Color(0xFF0284C7),
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: _useCurrentLocationAsPickup,
                                        child: Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEEF2FF),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.my_location_rounded,
                                            color: Color(0xFF4F46E5),
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Pickup Autocomplete Dropdown
                            if (_pickupSuggestions.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildSuggestionsList(
                                suggestions: _pickupSuggestions,
                                isPickup: true,
                              ),
                            ],

                            // Divider Row with Centered Swap Button
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                                  GestureDetector(
                                    onTap: _swapLocations,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.swap_vert_rounded,
                                            size: 16,
                                            color: Color(0xFF4F46E5),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Swap',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF4F46E5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Destination "To" Input Container
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Where to? (Destination)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        TextField(
                                          controller: _dropController,
                                          onTap: () {
                                            setState(() => _isSettingPickupOnMap = false);
                                            if (_dropLat != null && _dropLng != null) {
                                              _mapController?.animateCamera(
                                                CameraUpdate.newLatLngZoom(LatLng(_dropLat!, _dropLng!), 15.5),
                                              );
                                            }
                                          },
                                          maxLines: 2,
                                          minLines: 1,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: 'Search destination or pick on map',
                                            hintStyle: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF94A3B8),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            isDense: true,
                                            filled: false,
                                            fillColor: Colors.transparent,
                                            contentPadding: EdgeInsets.symmetric(vertical: 2),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            disabledBorder: InputBorder.none,
                                          ),
                                          onChanged: _onDropSearch,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_dropController.text.isNotEmpty) ...[
                                        GestureDetector(
                                          onTap: _clearDrop,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFF1F5F9),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close_rounded,
                                              color: Color(0xFF64748B),
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      GestureDetector(
                                        onTap: () => _openMapPicker(isPickup: false),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEEF2FF),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: const Color(0xFFC7D2FE)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(
                                                Icons.map_rounded,
                                                color: Color(0xFF4F46E5),
                                                size: 15,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Map',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF4F46E5),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Drop Autocomplete Dropdown
                            if (_dropSuggestions.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildSuggestionsList(
                                suggestions: _dropSuggestions,
                                isPickup: false,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // 2. Quick Saved Destination Chips
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildQuickChip(
                                icon: Icons.map_rounded,
                                label: 'Pick on Map',
                                isHighlighted: true,
                                onTap: () => _openMapPicker(isPickup: false),
                              ),
                              const SizedBox(width: 8),
                              _buildQuickChip(
                                icon: Icons.home_rounded,
                                label: 'Home',
                                onTap: _handleHomeTap,
                              ),
                              const SizedBox(width: 8),
                              _buildQuickChip(
                                icon: Icons.work_rounded,
                                label: 'Work',
                                onTap: _handleWorkTap,
                              ),
                              const SizedBox(width: 8),
                              _buildQuickChip(
                                icon: Icons.my_location_rounded,
                                label: 'Current Location',
                                isHighlighted: _pickupController.text.isNotEmpty,
                                onTap: _useCurrentLocationAsPickup,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Map Tap Selection Mode Bar (Rapido / Uber style)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            const Text(
                              'TAP MAP TO SET:',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 1. Pickup Mode Tab
                            GestureDetector(
                              onTap: () {
                                setState(() => _isSettingPickupOnMap = true);
                                if (_pickupLat != null && _pickupLng != null) {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLngZoom(LatLng(_pickupLat!, _pickupLng!), 15.5),
                                  );
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _isSettingPickupOnMap ? const Color(0xFF10B981) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _isSettingPickupOnMap ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                                    width: 1.5,
                                  ),
                                  boxShadow: _isSettingPickupOnMap
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: _isSettingPickupOnMap ? Colors.white : const Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Pickup',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _isSettingPickupOnMap ? Colors.white : const Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 2. Drop-off Mode Tab
                            GestureDetector(
                              onTap: () {
                                setState(() => _isSettingPickupOnMap = false);
                                if (_dropLat != null && _dropLng != null) {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLngZoom(LatLng(_dropLat!, _dropLng!), 15.5),
                                  );
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: !_isSettingPickupOnMap ? const Color(0xFFEF4444) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: !_isSettingPickupOnMap ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                                    width: 1.5,
                                  ),
                                  boxShadow: !_isSettingPickupOnMap
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: !_isSettingPickupOnMap ? Colors.white : const Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Drop-off',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: !_isSettingPickupOnMap ? Colors.white : const Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            // 3. Full Map CTA Button
                            GestureDetector(
                              onTap: () => _openMapPicker(isPickup: _isSettingPickupOnMap),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.fullscreen_rounded, size: 16, color: Color(0xFF2563EB)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Full Map',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 3. Live Google Map Route Card (Rapido / Uber style)
                      Container(
                        height: 280,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              // Google Map widget
                              Positioned.fill(
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: _currentDeviceLocation ?? _defaultCurrentLocation,
                                    zoom: 15.0,
                                  ),
                                  onMapCreated: (controller) {
                                    _mapController = controller;
                                    if (_currentDeviceLocation != null) {
                                      controller.animateCamera(
                                        CameraUpdate.newLatLngZoom(_currentDeviceLocation!, 15.5),
                                      );
                                    }
                                  },
                                  onTap: _onMapTapped,
                                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                                    Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                                  },
                                  markers: _buildMarkers(),
                                  polylines: _buildPolylines(),
                                  myLocationEnabled: true,
                                  myLocationButtonEnabled: false,
                                  zoomControlsEnabled: false,
                                  compassEnabled: true,
                                  mapToolbarEnabled: false,
                                  rotateGesturesEnabled: true,
                                  scrollGesturesEnabled: true,
                                  tiltGesturesEnabled: true,
                                  zoomGesturesEnabled: true,
                                ),
                              ),

                              // Top Route Information Badge
                              Positioned(
                                top: 12,
                                left: 12,
                                right: 12,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (hasBothLocations && _routeEstimateText.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.4)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.directions_car_filled_rounded,
                                              size: 15,
                                              color: Color(0xFF2563EB),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '$_routeEstimateText (Road Route)',
                                              style: const TextStyle(
                                                color: Color(0xFF0F172A),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.95),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: _isSettingPickupOnMap
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFEF4444),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.08),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _isSettingPickupOnMap
                                                  ? Icons.my_location_rounded
                                                  : Icons.location_on_rounded,
                                              size: 14,
                                              color: _isSettingPickupOnMap
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFFEF4444),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _isSettingPickupOnMap
                                                  ? 'Tap map to set Pickup spot'
                                                  : 'Tap map to set Destination spot',
                                              style: TextStyle(
                                                color: _isSettingPickupOnMap
                                                    ? const Color(0xFF065F46)
                                                    : const Color(0xFF991B1B),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    if (_isFetchingRoute)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.08),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Routing...',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Bottom Floating Map Buttons (Zoom in, Zoom out, My Location, Fullscreen)
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        if (_currentDeviceLocation != null) {
                                          _mapController?.animateCamera(
                                            CameraUpdate.newLatLngZoom(_currentDeviceLocation!, 15.5),
                                          );
                                        } else {
                                          await _detectCurrentLocation(setAsPickup: false);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.14),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: _isLoadingCurrentLocation
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Color(0xFF2563EB),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.my_location_rounded,
                                                color: Color(0xFF2563EB),
                                                size: 18,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.14),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.add_rounded,
                                          color: Color(0xFF0F172A),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.14),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.remove_rounded,
                                          color: Color(0xFF0F172A),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () => _openMapPicker(isPickup: _isSettingPickupOnMap),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.14),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.fullscreen_rounded,
                                          color: Color(0xFF2563EB),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Bottom-left hint / mode switcher pill
                              Positioned(
                                bottom: 10,
                                left: 10,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _isSettingPickupOnMap = !_isSettingPickupOnMap);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _isSettingPickupOnMap
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isSettingPickupOnMap
                                              ? Icons.my_location_rounded
                                              : Icons.location_on_rounded,
                                          size: 13,
                                          color: _isSettingPickupOnMap
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          _isSettingPickupOnMap
                                              ? 'Setting Pickup (Switch)'
                                              : 'Setting Drop (Switch)',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 4. Recent Rides Section (Based on logged-in user ID)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Recent Rides',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                if (_recentRides.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${_recentRides.length}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (_isLoadingRecentRides)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF4F46E5),
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: _loadRecentRides,
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (_isLoadingRecentRides && _recentRides.isEmpty)
                        _buildDestinationSkeleton()
                      else if (_loggedInUserId == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline_rounded,
                                    color: Color(0xFF94A3B8),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Log in to view recent rides',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Sign in to see rides booked on your account',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_recentRides.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.directions_car_outlined,
                                    color: Color(0xFF94A3B8),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'No recent rides yet',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Your recent rides for this account will appear here',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: min(8, _recentRides.length),
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final ride = _recentRides[index];
                            return _buildBookingCard(ride);
                          },
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Bottom Confirm & See Vehicles Button
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, -3),
                    ),
                  ],
                  border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _proceedToAvailableRides,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'See Available Rides',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList({
    required List<LocationResult> suggestions,
    required bool isPickup,
  }) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
        itemBuilder: (context, index) {
          final loc = suggestions[index];
          return Material(
            color: Colors.transparent,
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isPickup ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: isPickup ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                  size: 18,
                ),
              ),
              title: Text(
                loc.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
              subtitle: Text(
                loc.subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
              onTap: () async {
                double lat = loc.latitude;
                double lng = loc.longitude;
                if (lat == 0.0 || lng == 0.0) {
                  final coords = await _locationService.getPlaceCoordinates(
                    placeId: loc.placeId,
                    query: loc.title,
                  );
                  if (coords != null) {
                    lat = coords.latitude;
                    lng = coords.longitude;
                  }
                }
                if (isPickup) {
                  _setPickupLocation(loc.title, lat, lng, subtitle: loc.subtitle);
                } else {
                  _setDropLocation(loc.title, lat, lng, subtitle: loc.subtitle);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isHighlighted ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighlighted ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: const Color(0xFF4F46E5)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isHighlighted ? const Color(0xFF4F46E5) : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(
          3,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Color(0xFFCBD5E1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 90,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(RideBookingData b) {
    String cleanDrop = b.dropAddress.trim();
    while (cleanDrop.startsWith(',') || cleanDrop.startsWith(' ')) {
      cleanDrop = cleanDrop.substring(1).trim();
    }
    String cleanPickup = b.pickupAddress.trim();
    while (cleanPickup.startsWith(',') || cleanPickup.startsWith(' ')) {
      cleanPickup = cleanPickup.substring(1).trim();
    }

    final vehicleName = b.vehicleTypeName ??
        (b.vehicleType == 10
            ? 'Bike'
            : b.vehicleType == 11
                ? 'Auto'
                : 'Car');

    IconData vehicleIcon = Icons.directions_car_filled_rounded;
    Color vehicleColor = const Color(0xFF2563EB);
    if (vehicleName.toLowerCase().contains('bike') || b.vehicleType == 10) {
      vehicleIcon = Icons.two_wheeler_rounded;
      vehicleColor = const Color(0xFF10B981);
    } else if (vehicleName.toLowerCase().contains('auto') || b.vehicleType == 11) {
      vehicleIcon = Icons.electric_rickshaw_rounded;
      vehicleColor = const Color(0xFF059669);
    }

    Color statusBg = const Color(0xFFFEF3C7);
    Color statusText = const Color(0xFFD97706);
    final sLower = b.status.toLowerCase();
    if (sLower.contains('driver') || sLower.contains('assigned')) {
      statusBg = const Color(0xFFDBEAFE);
      statusText = const Color(0xFF2563EB);
    } else if (sLower.contains('completed') || sLower.contains('finished')) {
      statusBg = const Color(0xFFD1FAE5);
      statusText = const Color(0xFF059669);
    } else if (sLower.contains('cancelled')) {
      statusBg = const Color(0xFFFEE2E2);
      statusText = const Color(0xFFDC2626);
    }

    String formattedDate = '';
    if (b.createdAt != null && b.createdAt!.isNotEmpty) {
      try {
        final dt = DateTime.parse(b.createdAt!).toLocal();
        formattedDate = DateFormat('dd MMM, hh:mm a').format(dt);
      } catch (_) {
        formattedDate = b.createdAt!;
      }
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _applyBookingRoute(b),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Vehicle Icon, Vehicle Name, Booking ID, Date & Status Pill
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: vehicleColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(vehicleIcon, color: vehicleColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$vehicleName • #${b.id}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (formattedDate.isNotEmpty)
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      b.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusText,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Route timeline: Pickup -> Drop
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 1.5,
                        height: 22,
                        color: const Color(0xFFCBD5E1),
                      ),
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cleanPickup.isNotEmpty ? cleanPickup : 'Pickup Spot',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          cleanDrop.isNotEmpty ? cleanDrop : 'Destination',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),
              // Bottom action row: passengers / fare & Re-book button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        '${b.numberOfPassengers} ${b.numberOfPassengers == 1 ? 'passenger' : 'passengers'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (b.finalFare != null || b.estimatedFare != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '•  ₹${(b.finalFare ?? b.estimatedFare)!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ],
                  ),
                  InkWell(
                    onTap: () => _applyBookingRoute(b),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.replay_rounded, size: 13, color: Color(0xFF4F46E5)),
                          SizedBox(width: 4),
                          Text(
                            'Use Route',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}