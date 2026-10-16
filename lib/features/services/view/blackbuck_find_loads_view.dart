import 'package:flutter/material.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';
import 'package:cooli/features/services/view/blackbuck_loads_view.dart';
import 'package:cooli/features/ride/service/ride_location_service.dart';
import 'package:cooli/features/ride/view/ride_map_picker_view.dart';
import 'package:cooli/features/services/repo/services_repo.dart';

class BlackbuckFindLoadsView extends StatefulWidget {
  static const String routeName = '/blackbuck-find-loads';

  const BlackbuckFindLoadsView({super.key});

  @override
  State<BlackbuckFindLoadsView> createState() => _BlackbuckFindLoadsViewState();
}

class _BlackbuckFindLoadsViewState extends State<BlackbuckFindLoadsView> {
  static const Color primaryBlue = Color(0xFF2563EB);

  final RideLocationService _locationService = RideLocationService();
  final TextEditingController _fromController =
      TextEditingController(text: 'Locating current spot...');
  final TextEditingController _toController =
      TextEditingController(text: 'Bengaluru, Karnataka');

  double? _pickupLat;
  double? _pickupLng;
  double? _dropLat;
  double? _dropLng;
  bool _isLoadingCurrentLocation = false;
  bool _isCurrentLocationActive = false;
  double _selectedRadius = 50.0;
  int? _nearbyLoadsCount;
  bool _isCheckingNearbyLoads = false;

  final List<Map<String, dynamic>> _popularCorridors = [
    {
      'from': 'Ernakulam',
      'to': 'Bengaluru',
      'distance': '461 km',
      'loadsCount': 28,
      'avgRate': '₹ 22,000',
    },
    {
      'from': 'Kochi',
      'to': 'Hyderabad',
      'distance': '890 km',
      'loadsCount': 19,
      'avgRate': '₹ 38,500',
    },
    {
      'from': 'Palakkad',
      'to': 'Chennai',
      'distance': '520 km',
      'loadsCount': 24,
      'avgRate': '₹ 26,000',
    },
    {
      'from': 'Kochi',
      'to': 'Coimbatore',
      'distance': '190 km',
      'loadsCount': 35,
      'avgRate': '₹ 14,000',
    },
    {
      'from': 'Thrissur',
      'to': 'Mumbai',
      'distance': '1,280 km',
      'loadsCount': 14,
      'avgRate': '₹ 54,000',
    },
    {
      'from': 'Kozhikode',
      'to': 'Bengaluru',
      'distance': '360 km',
      'loadsCount': 22,
      'avgRate': '₹ 19,500',
    },
  ];

  final List<Map<String, dynamic>> _statesData = [
    {'name': 'Kerala', 'loads': 142, 'icon': Icons.location_on_rounded},
    {'name': 'Karnataka', 'loads': 188, 'icon': Icons.location_city_rounded},
    {'name': 'Tamil Nadu', 'loads': 210, 'icon': Icons.terrain_rounded},
    {'name': 'Andhra Pradesh', 'loads': 96, 'icon': Icons.alt_route_rounded},
    {'name': 'Maharashtra', 'loads': 165, 'icon': Icons.domain_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _detectCurrentLocation();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  /// Automatically fetch user's live physical GPS location on screen launch
  Future<void> _detectCurrentLocation({bool showToast = false}) async {
    setState(() {
      _isLoadingCurrentLocation = true;
    });

    try {
      final loc = await _locationService.getCurrentClientLocation();
      if (loc != null && mounted) {
        setState(() {
          _pickupLat = loc.latitude;
          _pickupLng = loc.longitude;
          final addr = loc.fullAddress.isNotEmpty ? loc.fullAddress : loc.title;
          _fromController.text = addr;
          _isCurrentLocationActive = true;
        });

        if (showToast) {
          showCooliToast(
            context,
            message: 'Loading point set to current GPS location',
            icon: Icons.my_location_rounded,
            iconColor: CooliColors.success,
          );
        }

        _checkNearbyLoadsCount(loc.latitude, loc.longitude);
      } else if (mounted) {
        // Fallback default coordinates (Kochi)
        setState(() {
          _pickupLat ??= 9.9312;
          _pickupLng ??= 76.2673;
          if (_fromController.text == 'Locating current spot...') {
            _fromController.text = 'Kochi, Kerala';
          }
        });
        _checkNearbyLoadsCount(_pickupLat!, _pickupLng!);
      }
    } catch (e) {
      debugPrint('[BlackbuckFindLoadsView] _detectCurrentLocation error: $e');
      if (mounted) {
        setState(() {
          _pickupLat ??= 9.9312;
          _pickupLng ??= 76.2673;
          if (_fromController.text == 'Locating current spot...') {
            _fromController.text = 'Kochi, Kerala';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCurrentLocation = false;
        });
      }
    }
  }

  /// Query backend API: /transport/loads/list-by-location/?latitude=...&longitude=...
  Future<void> _checkNearbyLoadsCount(double lat, double lng) async {
    setState(() {
      _isCheckingNearbyLoads = true;
    });

    try {
      final res = await ServicesRepo().fetchTransportLoadsByLocation(
        latitude: lat,
        longitude: lng,
        radiusKm: _selectedRadius,
        locationType: 'pickup',
      );

      if (mounted) {
        setState(() {
          _nearbyLoadsCount = res?.count ?? 0;
          _isCheckingNearbyLoads = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCheckingNearbyLoads = false;
        });
      }
    }
  }

  /// Open interactive Google Map to pick/change Loading Point or Unloading Point
  Future<void> _openMapPicker({required bool isPickup}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideMapPickerView(
          isPickup: isPickup,
          singleLocationOnly: false,
          initialPickupAddress: _fromController.text.isNotEmpty &&
                  _fromController.text != 'Locating current spot...'
              ? _fromController.text
              : null,
          initialDropAddress: _toController.text.isNotEmpty
              ? _toController.text
              : null,
          initialPickupLat: _pickupLat,
          initialPickupLng: _pickupLng,
          initialDropLat: _dropLat,
          initialDropLng: _dropLng,
        ),
      ),
    );

    if (result != null && mounted) {
      if (result is RideMapSelectionResult) {
        final pAddress = result.pickup.fullAddress.isNotEmpty
            ? result.pickup.fullAddress
            : result.pickup.title;
        final dAddress = result.drop.fullAddress.isNotEmpty
            ? result.drop.fullAddress
            : result.drop.title;

        setState(() {
          if (pAddress.isNotEmpty) {
            _fromController.text = pAddress;
            _pickupLat = result.pickup.latitude;
            _pickupLng = result.pickup.longitude;
            _isCurrentLocationActive = false;
          }
          if (dAddress.isNotEmpty) {
            _toController.text = dAddress;
            _dropLat = result.drop.latitude;
            _dropLng = result.drop.longitude;
          }
        });

        if (_pickupLat != null && _pickupLng != null) {
          _checkNearbyLoadsCount(_pickupLat!, _pickupLng!);
        }
      } else if (result is LocationResult) {
        final address = result.fullAddress.isNotEmpty
            ? result.fullAddress
            : result.title;
        setState(() {
          if (isPickup) {
            _fromController.text = address;
            _pickupLat = result.latitude;
            _pickupLng = result.longitude;
            _isCurrentLocationActive = false;
          } else {
            _toController.text = address;
            _dropLat = result.latitude;
            _dropLng = result.longitude;
          }
        });

        if (isPickup && _pickupLat != null && _pickupLng != null) {
          _checkNearbyLoadsCount(_pickupLat!, _pickupLng!);
        }
      }
    }
  }

  void _swapLocations() {
    setState(() {
      final tempText = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = tempText;

      final tempLat = _pickupLat;
      final tempLng = _pickupLng;
      _pickupLat = _dropLat;
      _pickupLng = _dropLng;
      _dropLat = tempLat;
      _dropLng = tempLng;

      _isCurrentLocationActive = false;
    });

    if (_pickupLat != null && _pickupLng != null) {
      _checkNearbyLoadsCount(_pickupLat!, _pickupLng!);
    }
  }

  void _onFindLoadsPressed({String? customRoute}) {
    String targetRoute = 'Loading Point - Destination';
    if (customRoute != null) {
      targetRoute = customRoute;
    } else {
      final from = _fromController.text.trim();
      final to = _toController.text.trim();
      if (from.isNotEmpty && to.isNotEmpty) {
        targetRoute = '$from - $to';
      } else if (from.isNotEmpty) {
        targetRoute = from;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlackbuckLoadsView(
          initialRoute: targetRoute,
          searchLat: _pickupLat,
          searchLng: _pickupLng,
          dropLat: _dropLat,
          dropLng: _dropLng,
          searchAddress: _fromController.text.isNotEmpty
              ? _fromController.text
              : 'Current Location',
          dropAddress: _toController.text.isNotEmpty
              ? _toController.text
              : null,
          radiusKm: _selectedRadius,
          locationType: 'pickup',
        ),
      ),
    );
  }


  void _showPremiumModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CooliColors.warningSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFD97706),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'BlackBuck Premium',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: CooliColors.textDark,
                        ),
                      ),
                      Text(
                        'Priority Access for Fleet Owners',
                        style: TextStyle(
                          fontSize: 12,
                          color: CooliColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildPerkItem('15-minute advance load access before general marketplace'),
              _buildPerkItem('0% Commission on all direct consignor bookings'),
              _buildPerkItem('Guaranteed 24-hr payment settlement on POD delivery'),
              _buildPerkItem('Dedicated 24x7 route dispatcher hotline support'),
              const SizedBox(height: 22),
              CooliButton(
                text: 'Activate VIP Freight Access (₹499/mo)',
                backgroundColor: primaryBlue,
                onTap: () {
                  Navigator.pop(context);
                  showCooliToast(
                    context,
                    message: 'Welcome to BlackBuck Premium!',
                    icon: Icons.verified_rounded,
                    iconColor: CooliColors.success,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerkItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: primaryBlue, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: CooliColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CooliColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: CooliColors.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Find Truck Loads',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: CooliColors.textDark,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Full Truckload (FTL) Freight',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: CooliColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          // Premium Button with Cooli aesthetic
          GestureDetector(
            onTap: _showPremiumModal,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFB45309),
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Buy Premium',
                    style: TextStyle(
                      color: Color(0xFF92400E),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Freight Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), primaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: CooliShadows.card,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'LIVE MARKETPLACE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Direct Consignor Loads',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Bid directly, call verified transporters & get trip advances.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Location Search Card with Map Picker and Live GPS
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: CooliColors.border),
                boxShadow: CooliShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.route_rounded,
                          color: primaryBlue, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Route Search',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: CooliColors.textDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: primaryBlue.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.touch_app_rounded,
                                size: 12, color: primaryBlue),
                            SizedBox(width: 4),
                            Text(
                              'Tap Map to Pick',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Loading Point (From) with Live GPS & Map button
                  _buildInputBox(
                    label: 'Loading Point (From)',
                    controller: _fromController,
                    hint: 'City, town or industrial hub',
                    dotColor: CooliColors.success,
                    isPickup: true,
                    onTapMap: () => _openMapPicker(isPickup: true),
                    onTapGps: () => _detectCurrentLocation(showToast: true),
                    isGpsLoading: _isLoadingCurrentLocation,
                    isCurrentLocationActive: _isCurrentLocationActive,
                    latitude: _pickupLat,
                    longitude: _pickupLng,
                  ),

                  // Route connector with Swap Button
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: CooliColors.border,
                            ),
                          ),
                          GestureDetector(
                            onTap: _swapLocations,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: primaryBlue, width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.swap_vert_rounded,
                                color: primaryBlue,
                                size: 18,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: CooliColors.border,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Unloading Point (To) with Map button
                  _buildInputBox(
                    label: 'Unloading Point (Destination)',
                    controller: _toController,
                    hint: 'Destination hub or state',
                    dotColor: CooliColors.danger,
                    isPickup: false,
                    onTapMap: () => _openMapPicker(isPickup: false),
                    latitude: _dropLat,
                    longitude: _dropLng,
                  ),

                  const SizedBox(height: 16),

                  // Radius Selector Chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.radar_rounded,
                              size: 15, color: CooliColors.textMuted),
                          SizedBox(width: 5),
                          Text(
                            'Search Radius',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: CooliColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_selectedRadius.toInt()} km radius',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [25.0, 50.0, 100.0, 250.0, 500.0].map((r) {
                        final isSel = _selectedRadius == r;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              r == 50.0 ? '50 km (Default)' : '${r.toInt()} km',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    isSel ? FontWeight.w800 : FontWeight.w600,
                                color: isSel ? Colors.white : CooliColors.textDark,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: primaryBlue,
                            backgroundColor: CooliColors.surfaceAlt,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isSel ? primaryBlue : CooliColors.border,
                              ),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedRadius = r;
                                });
                                if (_pickupLat != null && _pickupLng != null) {
                                  _checkNearbyLoadsCount(
                                      _pickupLat!, _pickupLng!);
                                }
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Live Nearby Loads Result preview badge
                  if (_isCheckingNearbyLoads)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: primaryBlue.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: const [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primaryBlue),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Checking live loads within radius...',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_nearbyLoadsCount != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _nearbyLoadsCount! > 0
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _nearbyLoadsCount! > 0
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _nearbyLoadsCount! > 0
                                ? Icons.verified_rounded
                                : Icons.radar_rounded,
                            size: 18,
                            color: _nearbyLoadsCount! > 0
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _nearbyLoadsCount! > 0
                                  ? '$_nearbyLoadsCount load${_nearbyLoadsCount! > 1 ? 's' : ''} available within ${_selectedRadius.toInt()} km of loading point'
                                  : '0 loads within ${_selectedRadius.toInt()} km. Expand radius or search all corridors.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _nearbyLoadsCount! > 0
                                    ? const Color(0xFF166534)
                                    : const Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Find Loads Button
                  CooliButton(
                    text: 'FIND AVAILABLE LOADS',
                    icon: Icons.search_rounded,
                    showForwardArrow: true,
                    backgroundColor: primaryBlue,
                    onTap: () => _onFindLoadsPressed(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Popular Corridors For You Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popular Corridors For You',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: CooliColors.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  '${_popularCorridors.length} Routes',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ..._popularCorridors.map((c) => _buildCorridorCard(c)),

            const SizedBox(height: 20),

            // Explore by State Section
            const Text(
              'Explore Loads by Origin State',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: CooliColors.textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _statesData.map((st) => _buildStateChipCard(st)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBox({
    required String label,
    required TextEditingController controller,
    required String hint,
    required Color dotColor,
    required bool isPickup,
    VoidCallback? onTapMap,
    VoidCallback? onTapGps,
    bool isGpsLoading = false,
    bool isCurrentLocationActive = false,
    double? latitude,
    double? longitude,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CooliColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentLocationActive
              ? CooliColors.success.withValues(alpha: 0.4)
              : CooliColors.border,
          width: isCurrentLocationActive ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                        boxShadow: [
                          BoxShadow(
                            color: dotColor.withValues(alpha: 0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: CooliColors.textMuted,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    if (isCurrentLocationActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.my_location_rounded,
                                size: 9, color: Color(0xFF16A34A)),
                            SizedBox(width: 2),
                            Text(
                              'CURRENT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF16A34A),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (isPickup && onTapGps != null)
                GestureDetector(
                  onTap: isGpsLoading ? null : onTapGps,
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: primaryBlue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isGpsLoading)
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primaryBlue),
                            ),
                          )
                        else
                          const Icon(Icons.my_location_rounded,
                              size: 11, color: primaryBlue),
                        const SizedBox(width: 3),
                        Text(
                          isGpsLoading ? '...' : 'GPS',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Pick on Map Button
              if (onTapMap != null)
                GestureDetector(
                  onTap: onTapMap,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.map_rounded, size: 11, color: Colors.white),
                        SizedBox(width: 3),
                        Text(
                          'MAP',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CooliColors.textDark,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: isGpsLoading ? 'Detecting current spot...' : hint,
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: CooliColors.textLight,
                    ),
                  ),
                ),
              ),
              if (controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    controller.clear();
                    setState(() {});
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.clear, size: 16, color: CooliColors.textLight),
                  ),
                ),
            ],
          ),
          if (latitude != null && longitude != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.pin_drop_outlined,
                    size: 11, color: CooliColors.textLight),
                const SizedBox(width: 4),
                Text(
                  '${latitude.toStringAsFixed(4)}° N, ${longitude.toStringAsFixed(4)}° E',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: CooliColors.textLight,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCorridorCard(Map<String, dynamic> c) {
    final routeTitle = '${c['from']} - ${c['to']}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CooliColors.border),
        boxShadow: CooliShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onFindLoadsPressed(customRoute: routeTitle),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Direction icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Corridor details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            c['from'] as String,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: CooliColors.textDark,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: primaryBlue,
                            ),
                          ),
                          Text(
                            c['to'] as String,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: CooliColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            c['distance'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: CooliColors.textMuted,
                            ),
                          ),
                          const Text(
                            ' • ',
                            style: TextStyle(color: CooliColors.textLight),
                          ),
                          Text(
                            'Avg ${c['avgRate']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Available loads badge + arrow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${c['loadsCount']} Loads',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: CooliColors.textLight,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateChipCard(Map<String, dynamic> st) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CooliColors.border),
        boxShadow: CooliShadows.soft,
      ),
      child: InkWell(
        onTap: () => _onFindLoadsPressed(customRoute: '${st['name']} - All Corridors'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                st['icon'] as IconData,
                color: primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              st['name'] as String,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: CooliColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${st['loads']} loads live',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: CooliColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
