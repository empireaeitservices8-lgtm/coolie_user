import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cooli/features/ride/service/ride_location_service.dart';

class RideMapPickerView extends StatefulWidget {
  static const String routeName = '/ride-map-picker';

  final bool isPickup;
  final bool singleLocationOnly;
  final String? initialPickupAddress;
  final String? initialDropAddress;
  final double? initialPickupLat;
  final double? initialPickupLng;
  final double? initialDropLat;
  final double? initialDropLng;

  // Backward compatibility with single-location callers
  final String? initialAddress;
  final double? initialLat;
  final double? initialLng;

  const RideMapPickerView({
    super.key,
    this.isPickup = true,
    this.singleLocationOnly = false,
    this.initialPickupAddress,
    this.initialDropAddress,
    this.initialPickupLat,
    this.initialPickupLng,
    this.initialDropLat,
    this.initialDropLng,
    this.initialAddress,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<RideMapPickerView> createState() => _RideMapPickerViewState();
}

class _RideMapPickerViewState extends State<RideMapPickerView> {
  final RideLocationService _locationService = RideLocationService();
  final TextEditingController _searchController = TextEditingController();

  GoogleMapController? _mapController;

  // Active selection mode: true = Pick-up (Current Location), false = Drop-off
  late bool _isSelectingPickup;

  // Pick-up location state (starts from user's current location)
  late double _pickupLat;
  late double _pickupLng;
  late String _pickupTitle;
  late String _pickupSubtitle;

  // Drop-off location state
  late double _dropLat;
  late double _dropLng;
  late String _dropTitle;
  late String _dropSubtitle;

  bool _hasPickupLocation = false;
  bool _hasDropLocation = false;

  LatLng? _currentCameraTarget;
  bool _isLoadingAddress = false;
  bool _isSearching = false;
  List<LocationResult> _searchResults = [];
  List<LatLng> _routePoints = [];
  String _routeEstimate = '';

  // Default coordinate: Kochi fallback (Current Location)
  static const LatLng _defaultCurrentLocation = LatLng(9.9816, 76.2763);

  void _updateRoadRoute() async {
    if (widget.singleLocationOnly) return;
    if (!_hasPickupLocation || !_hasDropLocation || _pickupTitle.isEmpty || _dropTitle.isEmpty) {
      if (_routePoints.isNotEmpty && mounted) {
        setState(() {
          _routePoints = [];
          _routeEstimate = '';
        });
      }
      return;
    }
    final details = await _locationService.getRouteDetails(
      LatLng(_pickupLat, _pickupLng),
      LatLng(_dropLat, _dropLng),
    );
    if (mounted) {
      setState(() {
        _routePoints = details?.coordinates ?? [];
        if (details != null) {
          _routeEstimate = '${details.distanceKm.toStringAsFixed(1)} km • ${details.durationMinutes} mins';
        }
      });
    }
  }

  void _onMapTappedDirectly(LatLng pos) async {
    setState(() {
      _isLoadingAddress = true;
      _currentCameraTarget = pos;
      if (_isSelectingPickup) {
        _hasPickupLocation = true;
        _pickupLat = pos.latitude;
        _pickupLng = pos.longitude;
        _pickupTitle = 'Locating pickup spot...';
      } else {
        _hasDropLocation = true;
        _dropLat = pos.latitude;
        _dropLng = pos.longitude;
        _dropTitle = 'Locating drop-off spot...';
      }
    });

    final res = await _locationService.reverseGeocode(pos.latitude, pos.longitude);
    if (mounted && res != null) {
      setState(() {
        _isLoadingAddress = false;
        if (_isSelectingPickup) {
          _pickupTitle = res.title;
          _pickupSubtitle = res.subtitle;
        } else {
          _dropTitle = res.title;
          _dropSubtitle = res.subtitle;
        }
      });
      _updateRoadRoute();
    }
  }

  bool _isCoordinateText(String? text) {
    if (text == null || text.trim().isEmpty) return true;
    final clean = text.trim();
    if (clean.toLowerCase().contains('pinned location') ||
        clean.toLowerCase().contains('device location') ||
        clean.toLowerCase().contains('locating pickup') ||
        clean.toLowerCase().contains('current spot')) {
      return true;
    }
    return RegExp(r'^-?\d{1,3}\.\d+[\s,]+-?\d{1,3}\.\d+$').hasMatch(clean);
  }

  @override
  void initState() {
    super.initState();
    _isSelectingPickup = widget.isPickup;

    // 1. Initialize Pickup
    final pickupRaw = widget.initialPickupAddress ??
        (widget.isPickup ? widget.initialAddress : null);
    _pickupLat = widget.initialPickupLat ??
        (widget.isPickup ? widget.initialLat ?? _defaultCurrentLocation.latitude : _defaultCurrentLocation.latitude);
    _pickupLng = widget.initialPickupLng ??
        (widget.isPickup ? widget.initialLng ?? _defaultCurrentLocation.longitude : _defaultCurrentLocation.longitude);

    if (pickupRaw != null &&
        pickupRaw.trim().isNotEmpty &&
        !_isCoordinateText(pickupRaw)) {
      _hasPickupLocation = true;
      if (pickupRaw.contains(',')) {
        final parts = pickupRaw.split(',');
        _pickupTitle = parts.first.trim();
        _pickupSubtitle = parts.sublist(1).map((e) => e.trim()).where((e) => e.isNotEmpty).join(', ');
      } else {
        _pickupTitle = pickupRaw.trim();
        _pickupSubtitle = '';
      }
    } else {
      _hasPickupLocation = true;
      _pickupTitle = 'Locating pickup spot...';
      _pickupSubtitle = '';
      _resolveAddressFor(isPickup: true, lat: _pickupLat, lng: _pickupLng);
    }

    // 2. Initialize Drop-off
    final dropRaw = widget.initialDropAddress ??
        (!widget.isPickup ? widget.initialAddress : null);
    _dropLat = widget.initialDropLat ??
        (!widget.isPickup ? widget.initialLat ?? _pickupLat : _pickupLat);
    _dropLng = widget.initialDropLng ??
        (!widget.isPickup ? widget.initialLng ?? _pickupLng : _pickupLng);

    if (dropRaw != null &&
        dropRaw.trim().isNotEmpty &&
        !_isCoordinateText(dropRaw)) {
      _hasDropLocation = true;
      if (dropRaw.contains(',')) {
        final parts = dropRaw.split(',');
        _dropTitle = parts.first.trim();
        _dropSubtitle = parts.sublist(1).map((e) => e.trim()).where((e) => e.isNotEmpty).join(', ');
      } else {
        _dropTitle = dropRaw.trim();
        _dropSubtitle = '';
      }
    } else if (widget.initialDropAddress != null && widget.initialDropAddress!.isNotEmpty) {
      _hasDropLocation = true;
      _dropTitle = 'Selecting destination...';
      _dropSubtitle = '';
      _resolveAddressFor(isPickup: false, lat: _dropLat, lng: _dropLng);
    } else {
      _hasDropLocation = false;
      _dropTitle = '';
      _dropSubtitle = '';
    }

    _initLiveLocation();
  }

  void _initLiveLocation() async {
    try {
      await Permission.location.request();
    } catch (_) {}

    if (widget.isPickup && (widget.initialPickupAddress == null || widget.initialPickupAddress!.isEmpty)) {
      setState(() {
        _isLoadingAddress = true;
        _pickupTitle = 'Locating current spot...';
      });
    }

    final clientLoc = await _locationService.getCurrentClientLocation();
    if (mounted && clientLoc != null) {
      final pos = LatLng(clientLoc.latitude, clientLoc.longitude);
      if (widget.isPickup && (widget.initialPickupAddress == null || widget.initialPickupAddress!.isEmpty)) {
        setState(() {
          _pickupLat = pos.latitude;
          _pickupLng = pos.longitude;
          _pickupTitle = clientLoc.title;
          _pickupSubtitle = clientLoc.subtitle;
          _hasPickupLocation = true;
          _isLoadingAddress = false;
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 15.5));
      } else if (!widget.isPickup && (widget.initialDropAddress == null || widget.initialDropAddress!.isEmpty)) {
        setState(() {
          _isLoadingAddress = false;
        });
        // Drop starts empty (same as Rapido). Camera centers on user's current location so they can pick destination.
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 15.5));
      }
    } else if (mounted) {
      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _resolveAddressFor({
    required bool isPickup,
    required double lat,
    required double lng,
  }) async {
    final res = await _locationService.reverseGeocode(lat, lng);
    if (mounted && res != null) {
      setState(() {
        if (isPickup) {
          _pickupTitle = res.title;
          _pickupSubtitle = res.subtitle;
        } else {
          _dropTitle = res.title;
          _dropSubtitle = res.subtitle;
        }
      });
      _updateRoadRoute();
    }
  }

  void _toggleMode(bool toPickup) {
    if (_isSelectingPickup == toPickup) return;
    setState(() {
      _isSelectingPickup = toPickup;
      _isSearching = false;
      _searchController.clear();
      _searchResults = [];
    });

    final target = toPickup ? LatLng(_pickupLat, _pickupLng) : LatLng(_dropLat, _dropLng);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 15.0),
      ),
    );
  }

  void _swapPickupAndDrop() {
    setState(() {
      final tLat = _pickupLat;
      final tLng = _pickupLng;
      final tTitle = _pickupTitle;
      final tSub = _pickupSubtitle;

      _pickupLat = _dropLat;
      _pickupLng = _dropLng;
      _pickupTitle = _dropTitle;
      _pickupSubtitle = _dropSubtitle;

      _dropLat = tLat;
      _dropLng = tLng;
      _dropTitle = tTitle;
      _dropSubtitle = tSub;
    });

    _updateRoadRoute();

    final target = _isSelectingPickup ? LatLng(_pickupLat, _pickupLng) : LatLng(_dropLat, _dropLng);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 15.0),
      ),
    );
  }

  void _onSearchChanged(String val) async {
    if (val.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await _locationService.searchPlaces(val);
    if (mounted) {
      setState(() {
        _searchResults = results;
      });
    }
  }

  void _selectSearchResult(LocationResult result) async {
    double lat = result.latitude;
    double lng = result.longitude;

    if (lat == 0.0 || lng == 0.0) {
      final coords = await _locationService.getPlaceCoordinates(
        placeId: result.placeId,
        query: result.title,
      );
      if (coords != null) {
        lat = coords.latitude;
        lng = coords.longitude;
      }
    }

    if (!mounted) return;

    setState(() {
      if (_isSelectingPickup) {
        _hasPickupLocation = true;
        _pickupLat = lat;
        _pickupLng = lng;
        _pickupTitle = result.title;
        _pickupSubtitle = result.subtitle;
      } else {
        _hasDropLocation = true;
        _dropLat = lat;
        _dropLng = lng;
        _dropTitle = result.title;
        _dropSubtitle = result.subtitle;
      }
      _isSearching = false;
      _searchController.clear();
    });

    _updateRoadRoute();

    if (lat != 0.0 && lng != 0.0) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15.5),
      );
    }
  }

  void _onCameraMove(CameraPosition position) {
    _currentCameraTarget = position.target;
  }

  void _onCameraIdle() async {
    if (_currentCameraTarget == null) return;
    final lat = _currentCameraTarget!.latitude;
    final lng = _currentCameraTarget!.longitude;

    setState(() {
      _isLoadingAddress = true;
      if (_isSelectingPickup) {
        _hasPickupLocation = true;
        _pickupLat = lat;
        _pickupLng = lng;
      } else {
        _hasDropLocation = true;
        _dropLat = lat;
        _dropLng = lng;
      }
    });

    final res = await _locationService.reverseGeocode(lat, lng);
    if (mounted) {
      setState(() {
        _isLoadingAddress = false;
        if (res != null) {
          if (_isSelectingPickup) {
            _pickupTitle = res.title;
            _pickupSubtitle = res.subtitle;
          } else {
            _dropTitle = res.title;
            _dropSubtitle = res.subtitle;
          }
        }
      });
      _updateRoadRoute();
    }
  }

  void _resetToCurrentLocation() async {
    setState(() {
      _isLoadingAddress = true;
      _pickupTitle = 'Locating current spot...';
    });

    final clientLoc = await _locationService.getCurrentClientLocation();
    LatLng target = _defaultCurrentLocation;
    String title = 'Current Spot';
    String sub = '';

    if (clientLoc != null) {
      target = LatLng(clientLoc.latitude, clientLoc.longitude);
      title = clientLoc.title.isNotEmpty ? clientLoc.title : 'Current Spot';
      sub = clientLoc.subtitle;
    }

    if (!mounted) return;

    setState(() {
      _isLoadingAddress = false;
      _isSelectingPickup = true;
      _hasPickupLocation = true;
      _pickupLat = target.latitude;
      _pickupLng = target.longitude;
      _pickupTitle = title;
      _pickupSubtitle = sub;
      _isSearching = false;
      _searchController.clear();
    });

    _updateRoadRoute();

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(target, 15.5),
    );
  }

  void _confirmSelection() {
    if (widget.singleLocationOnly) {
      final pickupResult = LocationResult(
        title: _pickupTitle.isNotEmpty ? _pickupTitle : 'Current Location',
        subtitle: _pickupSubtitle,
        latitude: _pickupLat,
        longitude: _pickupLng,
      );
      Navigator.pop(context, pickupResult);
      return;
    }

    if (_isSelectingPickup && (!_hasDropLocation || _dropTitle.trim().isEmpty)) {
      // Auto-advance user to select drop-off on map smoothly
      _toggleMode(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.place_rounded, color: Color(0xFFEF4444), size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Pickup saved! Now tap map or search destination.')),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!_isSelectingPickup && (!_hasDropLocation || _dropTitle.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or search your drop-off destination'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final pickupResult = LocationResult(
      title: _pickupTitle.isNotEmpty ? _pickupTitle : 'Current Location',
      subtitle: _pickupSubtitle,
      latitude: _pickupLat,
      longitude: _pickupLng,
    );
    final dropResult = LocationResult(
      title: _hasDropLocation ? _dropTitle : '',
      subtitle: _dropSubtitle,
      latitude: _dropLat,
      longitude: _dropLng,
    );

    final selection = RideMapSelectionResult(
      pickup: pickupResult,
      drop: dropResult,
      isPickupActive: _isSelectingPickup,
    );

    Navigator.pop(context, selection);
  }

  Set<Marker> _buildMarkers() {
    if (widget.singleLocationOnly) {
      return {};
    }
    final markers = <Marker>{};

    if (_isSelectingPickup) {
      // Pickup is active at screen center; render Drop marker on the Google Map if set
      if (_hasDropLocation && _dropTitle.isNotEmpty) {
        markers.add(
          Marker(
            markerId: const MarkerId('drop_destination_marker'),
            position: LatLng(_dropLat, _dropLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: 'Drop-off Destination',
              snippet: _dropTitle,
            ),
            onTap: () => _toggleMode(false),
          ),
        );
      }
    } else {
      // Drop is active at screen center; render Pickup marker on the Google Map if set
      if (_hasPickupLocation && _pickupTitle.isNotEmpty) {
        markers.add(
          Marker(
            markerId: const MarkerId('pickup_origin_marker'),
            position: LatLng(_pickupLat, _pickupLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: 'Pickup (Current Location)',
              snippet: _pickupTitle,
            ),
            onTap: () => _toggleMode(true),
          ),
        );
      }
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (widget.singleLocationOnly) {
      return {};
    }
    // Only draw polyline when both locations are selected and road travel path is available
    if (!_hasPickupLocation || !_hasDropLocation || _pickupTitle.isEmpty || _dropTitle.isEmpty || _routePoints.isEmpty) {
      return {};
    }
    return {
      Polyline(
        polylineId: const PolylineId('route_road_travel_path'),
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

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);
    final pickupColor = const Color(0xFF10B981);
    final dropColor = const Color(0xFFEF4444);
    final activeColor = _isSelectingPickup ? pickupColor : dropColor;

    final routeEstimate = RideLocationService.calculateRideEstimate(
      lat1: _pickupLat,
      lon1: _pickupLng,
      lat2: _dropLat,
      lon2: _dropLng,
    );

    final initialTarget = LatLng(
      _isSelectingPickup ? _pickupLat : _dropLat,
      _isSelectingPickup ? _pickupLng : _dropLng,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. Google Maps Widget with Live Markers, Polylines & Gestures
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialTarget,
                zoom: 15.0,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onTap: (pos) {
                _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
                _onMapTappedDirectly(pos);
              },
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
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

          // 2. Center Active Moving Pin with Dynamic Floating Tooltip Badge
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 38.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Floating Tooltip Badge showing live address of the active pin
                  Container(
                    constraints: const BoxConstraints(maxWidth: 260),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: activeColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: activeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isSelectingPickup
                                    ? 'PICKUP (CURRENT SPOT)'
                                    : 'DROP-OFF DESTINATION',
                                style: TextStyle(
                                  color: activeColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                _isLoadingAddress
                                    ? 'Locating address...'
                                    : (_isSelectingPickup
                                        ? (_pickupTitle.isNotEmpty ? _pickupTitle : 'Move map to set pickup')
                                        : (_dropTitle.isNotEmpty ? _dropTitle : 'Move map to set destination')),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (!_isLoadingAddress &&
                                  (_isSelectingPickup ? _pickupSubtitle : _dropSubtitle).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    _isSelectingPickup ? _pickupSubtitle : _dropSubtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Animated Map Pin Icon
                  Icon(
                    Icons.location_on_rounded,
                    size: 48,
                    color: activeColor,
                  ),
                  // Drop shadow beneath active pin
                  Container(
                    width: 14,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Top Safe Area Header, Search Bar & Dual-Location Mode Switcher
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Bar & Back Button
                  Row(
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Search Bar Field
                      Expanded(
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                color: activeColor,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: _onSearchChanged,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: _isSelectingPickup
                                        ? 'Search pickup spot...'
                                        : 'Search destination...',
                                    hintStyle: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Search Results Dropdown Overlay
                  if (_isSearching && _searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 240),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              dense: true,
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: activeColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.place_rounded, color: activeColor, size: 16),
                              ),
                              title: Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              subtitle: Text(
                                item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                              onTap: () => _selectSearchResult(item),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Dual-Location Segmented Selector Pill (Pick-up <-> Drop-off)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // 1. Pickup Tab
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _toggleMode(true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: _isSelectingPickup
                                    ? const Color(0xFFECFDF5)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _isSelectingPickup
                                      ? const Color(0xFF10B981)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          widget.singleLocationOnly
                                              ? 'PINNED LOCATION'
                                              : 'PICKUP (CURRENT)',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF059669),
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        Text(
                                          _pickupTitle.isNotEmpty ? _pickupTitle : 'Tap to set location',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _isSelectingPickup
                                                ? const Color(0xFF065F46)
                                                : const Color(0xFF334155),
                                          ),
                                        ),
                                        if (_pickupSubtitle.isNotEmpty)
                                          Text(
                                            _pickupSubtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: _isSelectingPickup
                                                  ? const Color(0xFF047857)
                                                  : const Color(0xFF64748B),
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

                        if (!widget.singleLocationOnly) ...[
                          // Swap Button
                          IconButton(
                            icon: const Icon(
                              Icons.swap_horiz_rounded,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            tooltip: 'Swap Pickup & Drop',
                            onPressed: _swapPickupAndDrop,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),

                          // 2. Drop-off Tab
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _toggleMode(false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: !_isSelectingPickup
                                      ? const Color(0xFFFEF2F2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: !_isSelectingPickup
                                        ? const Color(0xFFEF4444)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'DROP-OFF',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFFDC2626),
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          Text(
                                            _dropTitle.isNotEmpty ? _dropTitle : 'Tap to set drop',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: !_isSelectingPickup
                                                  ? const Color(0xFF991B1B)
                                                  : const Color(0xFF334155),
                                            ),
                                          ),
                                          if (_dropSubtitle.isNotEmpty)
                                            Text(
                                              _dropSubtitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: !_isSelectingPickup
                                                    ? const Color(0xFFB91C1C)
                                                    : const Color(0xFF64748B),
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
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Floating Map Action Buttons (Locate Me, Zoom In/Out)
          Positioned(
            right: 16,
            bottom: 245,
            child: Column(
              children: [
                // Locate Me Button (Sets Pickup to Current Location)
                GestureDetector(
                  onTap: _resetToCurrentLocation,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: primaryBlue,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Zoom In
                GestureDetector(
                  onTap: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                  child: Container(
                    width: 44,
                    height: 44,
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
                    child: const Icon(Icons.add_rounded, color: Color(0xFF0F172A), size: 22),
                  ),
                ),
                const SizedBox(height: 10),
                // Zoom Out
                GestureDetector(
                  onTap: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                  child: Container(
                    width: 44,
                    height: 44,
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
                    child: const Icon(Icons.remove_rounded, color: Color(0xFF0F172A), size: 22),
                  ),
                ),
              ],
            ),
          ),

          // 5. Bottom Ride Confirmation Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 22,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (!widget.singleLocationOnly) ...[
                      // Route Distance & Duration Header Pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.alt_route_rounded,
                                color: primaryBlue,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Selected Ride Route',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Text(
                              _routeEstimate.isNotEmpty ? _routeEstimate : routeEstimate,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Pickup Details Row
                    GestureDetector(
                      onTap: () => _toggleMode(true),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isSelectingPickup ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isSelectingPickup ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: pickupColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.my_location_rounded, color: pickupColor, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.singleLocationOnly
                                        ? 'SELECTED PICKUP LOCATION'
                                        : 'PICKUP SPOT (CURRENT LOCATION)',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF059669),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  Text(
                                    _pickupTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (_pickupSubtitle.isNotEmpty)
                                    Text(
                                      _pickupSubtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                ],
                              ),
                            ),
                            if (_isSelectingPickup)
                              const Icon(Icons.edit_location_rounded, color: Color(0xFF10B981), size: 18),
                          ],
                        ),
                      ),
                    ),

                    if (!widget.singleLocationOnly) ...[
                      const SizedBox(height: 8),

                      // Drop-off Details Row
                      GestureDetector(
                        onTap: () => _toggleMode(false),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: !_isSelectingPickup ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: !_isSelectingPickup ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: dropColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.location_on_rounded, color: dropColor, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'DROP-OFF DESTINATION',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFDC2626),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    Text(
                                      _dropTitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    if (_dropSubtitle.isNotEmpty)
                                      Text(
                                        _dropSubtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                  ],
                                ),
                              ),
                              if (!_isSelectingPickup)
                                const Icon(Icons.edit_location_rounded, color: Color(0xFFEF4444), size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Confirm CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _confirmSelection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                          shadowColor: primaryBlue.withValues(alpha: 0.4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              widget.singleLocationOnly
                                  ? 'Confirm Location'
                                  : (_hasPickupLocation && _hasDropLocation && _dropTitle.isNotEmpty
                                      ? 'Confirm Route & View Rides'
                                      : (_isSelectingPickup
                                          ? (_hasDropLocation && _dropTitle.isNotEmpty
                                              ? 'Confirm Pickup'
                                              : 'Confirm Pickup & Choose Drop')
                                          : 'Confirm Drop Location')),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
