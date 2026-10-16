import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/ride/model/ride_model.dart';
import 'package:cooli/features/ride/view_model/ride_view_model.dart';
import 'package:cooli/features/ride/view/ride_completed_view.dart';
import 'package:cooli/features/ride/service/ride_location_service.dart';

class RideTrackingView extends StatefulWidget {
  static const String routeName = '/ride-tracking';

  const RideTrackingView({super.key});

  @override
  State<RideTrackingView> createState() => _RideTrackingViewState();
}

class _RideTrackingViewState extends State<RideTrackingView>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  final RideLocationService _locationService = RideLocationService();

  late RideViewModel _viewModel;
  late AnimationController _carAnimController;
  late Animation<double> _carProgress;

  String _pickupTitle = 'Pickup Location';
  String _dropTitle = 'Destination';
  double? _pickupLat;
  double? _pickupLng;
  double? _dropLat;
  double? _dropLng;
  double? _fare;
  String _paymentMethod = 'Cash';
  RideOption? _selectedOption;

  List<LatLng> _routePoints = [];
  LatLng? _currentCarPosition;
  double _carBearing = 0.0;
  bool _initializedArgs = false;

  static const String _darkMapStyleJson = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#1d2c4d"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8ec3b9"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a3646"}]},
  {"featureType": "administrative.country", "elementType": "geometry.stroke", "stylers": [{"color": "#4b6878"}]},
  {"featureType": "landscape.man_made", "elementType": "geometry.stroke", "stylers": [{"color": "#334e87"}]},
  {"featureType": "landscape.natural", "elementType": "geometry", "stylers": [{"color": "#023e58"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#283d6a"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#6f9ba5"}]},
  {"featureType": "poi.park", "elementType": "geometry.fill", "stylers": [{"color": "#023e58"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#304a7d"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#2c6675"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#255463"}]},
  {"featureType": "transit", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0e1626"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#4e6d70"}]}
]
''';

  @override
  void initState() {
    super.initState();

    _carAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _carProgress = Tween<double>(begin: 0.02, end: 0.98).animate(
      CurvedAnimation(parent: _carAnimController, curve: Curves.easeInOut),
    )..addListener(_updateCarPosition);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel = context.read<RideViewModel>();
    if (!_initializedArgs) {
      _initializedArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        _pickupTitle = args['pickup']?.toString() ?? 'Pickup Location';
        _dropTitle = args['drop']?.toString() ?? 'Destination';
        _pickupLat = args['pickupLat'] as double?;
        _pickupLng = args['pickupLng'] as double?;
        _dropLat = args['dropLat'] as double?;
        _dropLng = args['dropLng'] as double?;
        _fare = args['fare'] as double?;
        _paymentMethod = args['paymentMethod']?.toString() ?? 'Cash';
        _selectedOption = args['selectedOption'] as RideOption?;
      }

      _pickupLat ??= _viewModel.pickupLat ?? 9.9816;
      _pickupLng ??= _viewModel.pickupLng ?? 76.2763;
      _dropLat ??= _viewModel.dropLat ?? 10.0159;
      _dropLng ??= _viewModel.dropLng ?? 76.3419;

      _loadRouteAndInitTracking();
    }
  }

  Future<void> _loadRouteAndInitTracking() async {
    final start = LatLng(_pickupLat!, _pickupLng!);
    final end = LatLng(_dropLat!, _dropLng!);

    final points = await _locationService.getRouteCoordinates(start, end);
    if (!mounted) return;

    setState(() {
      _routePoints = points.isNotEmpty ? points : [start, end];
      _currentCarPosition = _routePoints.first;
    });

    _fitMapToBounds(start, end, _routePoints);
  }

  void _updateCarPosition() {
    if (_routePoints.length < 2) return;
    final progress = _carProgress.value;
    final totalSegments = _routePoints.length - 1;
    final floatIndex = progress.clamp(0.0, 1.0) * totalSegments;
    final index = floatIndex.floor().clamp(0, totalSegments - 1);
    final remainder = floatIndex - index;

    final p1 = _routePoints[index];
    final p2 = _routePoints[index + 1];

    final lat = p1.latitude + (p2.latitude - p1.latitude) * remainder;
    final lng = p1.longitude + (p2.longitude - p1.longitude) * remainder;
    final pos = LatLng(lat, lng);
    final bearing = _calculateBearing(p1, p2);

    setState(() {
      _currentCarPosition = pos;
      _carBearing = bearing;
    });
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * (pi / 180.0);
    final lon1 = start.longitude * (pi / 180.0);
    final lat2 = end.latitude * (pi / 180.0);
    final lon2 = end.longitude * (pi / 180.0);

    final dLon = lon2 - lon1;
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final radians = atan2(y, x);
    return (radians * (180.0 / pi) + 360.0) % 360.0;
  }

  void _fitMapToBounds(LatLng start, LatLng end, List<LatLng> points) {
    if (_mapController == null) return;
    double south = min(start.latitude, end.latitude);
    double north = max(start.latitude, end.latitude);
    double west = min(start.longitude, end.longitude);
    double east = max(start.longitude, end.longitude);

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

  void _recenterOnDriver() {
    if (_currentCarPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentCarPosition!, 16.0),
      );
    } else if (_pickupLat != null && _dropLat != null) {
      _fitMapToBounds(
        LatLng(_pickupLat!, _pickupLng!),
        LatLng(_dropLat!, _dropLng!),
        _routePoints,
      );
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    final start = LatLng(_pickupLat ?? 9.9816, _pickupLng ?? 76.2763);
    final end = LatLng(_dropLat ?? 10.0159, _dropLng ?? 76.3419);

    // Pickup Marker
    markers.add(
      Marker(
        markerId: const MarkerId('pickup_pin'),
        position: start,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Pickup', snippet: _pickupTitle),
      ),
    );

    // Drop Marker
    markers.add(
      Marker(
        markerId: const MarkerId('drop_pin'),
        position: end,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Destination', snippet: _dropTitle),
      ),
    );

    // Moving Driver Car Marker along real road route
    if (_currentCarPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver_car'),
          position: _currentCarPosition!,
          rotation: _carBearing,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Rahul Kumar (Toyota Etios)'),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_routePoints.isEmpty) return {};
    return {
      Polyline(
        polylineId: const PolylineId('tracking_road_route'),
        points: _routePoints,
        color: const Color(0xFF38BDF8),
        width: 6,
        geodesic: false,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  @override
  void dispose() {
    _carProgress.removeListener(_updateCarPosition);
    _carAnimController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090F1D),
      body: Column(
        children: [
          // 1. TOP HALF: GoogleMap from google_maps_flutter with road route, moving car & floating controls
          Expanded(
            flex: 11,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Real GoogleMap Widget
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_pickupLat ?? 9.9816, _pickupLng ?? 76.2763),
                    zoom: 14.5,
                  ),
                  style: _darkMapStyleJson,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_routePoints.isNotEmpty &&
                        _pickupLat != null &&
                        _dropLat != null) {
                      _fitMapToBounds(
                        LatLng(_pickupLat!, _pickupLng!),
                        LatLng(_dropLat!, _dropLng!),
                        _routePoints,
                      );
                    }
                  },
                  markers: _buildMarkers(),
                  polylines: _buildPolylines(),
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: true,
                  mapToolbarEnabled: false,
                  rotateGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                ),

                // Top Floating Header: Back Button + "On the way" + Recenter Action
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Back Button Pill
                        GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B)
                                  .withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white24, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // "On the way" Green Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF064E3B).withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                                color: const Color(0xFF10B981), width: 1.3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF34D399),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'On the way',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Map Center on Driver Action Button
                        GestureDetector(
                          onTap: _recenterOnDriver,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B)
                                  .withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white24, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.my_location_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. BOTTOM HALF: Floating White Driver Details Card
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 24,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle Bar Indicator
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Driver Profile Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Driver Avatar
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFE2E8F0), width: 1.5),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/ride_driver_avatar.png',
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              size: 30,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Driver Name, Star Rating & Vehicle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Text(
                                  'Rahul Kumar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.star_rounded,
                                    color: Color(0xFFF59E0B), size: 18),
                                SizedBox(width: 2),
                                Text(
                                  '4.9',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${_selectedOption?.name ?? "Toyota Etios"}  •  KL 07 AB 1234',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ETA Banner: "Arriving in 4 min"
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1E1B4B),
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            const TextSpan(text: 'Arriving in '),
                            const TextSpan(
                              text: '4 min',
                              style: TextStyle(
                                color: Color(0xFF4F46E5),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (_fare != null) ...[
                              const TextSpan(text: '  •  '),
                              TextSpan(
                                text: '₹${_fare!.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Color(0xFF059669),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                            const TextSpan(text: '  •  '),
                            TextSpan(
                              text: _paymentMethod,
                              style: TextStyle(
                                color: _paymentMethod == 'Coolie Wallet'
                                    ? Colors.purple
                                    : (_paymentMethod == 'UPI'
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF16A34A)),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 3 Action Buttons: Call, OTP, Chat
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.phone_rounded,
                          label: 'Call',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Calling Rahul Kumar (+91 98765 43210)...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.pin_rounded,
                          label: 'OTP: 4219',
                          isHighlighted: true,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Chat',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Opening chat with driver...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Complete Ride Button (Takes user to Ride Completed)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          RideCompletedView.routeName,
                          arguments: {
                            'fare': _fare,
                            'paymentMethod': _paymentMethod,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Simulate Arrival / End Ride',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Cancel Ride Button
                  TextButton(
                    onPressed: () => Navigator.maybePop(context),
                    child: const Text(
                      'Cancel Ride',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isHighlighted ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted
                ? const Color(0xFFCBD5E1)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isHighlighted
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFF475569),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
                color: isHighlighted
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
