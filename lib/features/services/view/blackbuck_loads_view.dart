import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';
import 'package:cooli/features/services/model/blackbuck_load_model.dart';
import 'package:cooli/features/services/model/transport_vehicle_type_model.dart';
import 'package:cooli/features/services/repo/services_repo.dart';
import 'package:cooli/features/services/view/blackbuck_load_details_view.dart';
import 'package:cooli/features/services/view/create_bid_bottom_sheet.dart';
import 'package:cooli/services/session_manager.dart';
import 'package:cooli/features/ride/service/ride_location_service.dart';
import 'package:cooli/features/ride/view/ride_map_picker_view.dart';

class BlackbuckLoadsView extends StatefulWidget {
  static const String routeName = '/blackbuck-loads';

  final String? initialRoute;
  final double? searchLat;
  final double? searchLng;
  final double? dropLat;
  final double? dropLng;
  final String? searchAddress;
  final String? dropAddress;
  final double? radiusKm;
  final String? locationType;
  final String? initialTruckType;

  const BlackbuckLoadsView({
    super.key,
    this.initialRoute,
    this.searchLat,
    this.searchLng,
    this.dropLat,
    this.dropLng,
    this.searchAddress,
    this.dropAddress,
    this.radiusKm,
    this.locationType,
    this.initialTruckType,
  });

  @override
  State<BlackbuckLoadsView> createState() => _BlackbuckLoadsViewState();
}

class _BlackbuckLoadsViewState extends State<BlackbuckLoadsView> {
  static const Color primaryBlue = Color(0xFF2563EB);

  late String _selectedRoute;
  String _selectedLoadsFrom = 'All';
  String? _selectedTruckType;
  String? _selectedTruckTypeSlug;
  TransportTruckTypeFilter? _activeTruckTypeFilter;
  TransportAvailableCities? _availableCities;
  int? _truckTypeResultCount;
  bool _isTruckTypesExpanded = true;
  bool _isLoading = false;

  double? _activeLat;
  double? _activeLng;
  double? _activeDropLat;
  double? _activeDropLng;
  String? _activeSearchAddress;
  String? _activeDropAddress;
  late double _activeRadiusKm;
  late String _activeLocationType;
  bool _isLocationSearch = false;
  int _locationResultCount = 0;

  late List<BlackbuckLoadModel> _allLoads;

  final List<String> _subLocations = [
    'All',
    'Kochi',
    'Calicut',
    'Ernakulam',
    'Aluva',
    'Kottayam',
    'Angamaly',
  ];

  List<TransportVehicleTypeModel> _vehicleTypes =
      TransportVehicleTypeModel.getDefaultVehicleTypes();
  bool _isLoadingVehicleTypes = false;

  @override
  void initState() {
    super.initState();
    _selectedRoute = widget.initialRoute ?? 'Kochi - Calicut';
    _activeLat = widget.searchLat;
    _activeLng = widget.searchLng;
    _activeDropLat = widget.dropLat;
    _activeDropLng = widget.dropLng;
    _activeSearchAddress = widget.searchAddress;
    _activeDropAddress = widget.dropAddress;
    _activeRadiusKm = widget.radiusKm ?? 50.0;
    _activeLocationType = widget.locationType ?? 'pickup';
    _isLocationSearch = _activeLat != null && _activeLng != null;

    _allLoads = BlackbuckLoadModel.getSampleLoads();

    if (widget.initialTruckType != null &&
        widget.initialTruckType!.trim().isNotEmpty) {
      final slug = TransportVehicleTypeModel.resolveTruckTypeSlug(
          widget.initialTruckType!);
      _selectedTruckType = widget.initialTruckType;
      _selectedTruckTypeSlug = slug;
      _filterLoadsByTruckType(slug, showToast: false);
    } else {
      _loadLiveLoads();
    }
    _loadVehicleTypes();
  }

  Future<void> _loadVehicleTypes() async {
    setState(() => _isLoadingVehicleTypes = true);
    try {
      final types = await ServicesRepo().fetchTransportVehicleTypes();
      if (mounted && types.isNotEmpty) {
        setState(() {
          // Merge defaults with types returned by server so Tipper and standard choices remain available
          final defaults = TransportVehicleTypeModel.getDefaultVehicleTypes();
          final Map<String, TransportVehicleTypeModel> merged = {};
          for (final d in defaults) {
            merged[d.typeKey] = d;
          }
          for (final t in types) {
            final slug = TransportVehicleTypeModel.resolveTruckTypeSlug(t.name);
            if (!merged.containsKey(slug)) {
              merged[slug] = t;
            }
          }
          _vehicleTypes = merged.values.toList();
        });
      }
    } catch (e) {
      debugPrint('[BlackbuckLoadsView] _loadVehicleTypes error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingVehicleTypes = false);
      }
    }
  }

  /// Filter loads from backend by selected truck type:
  /// GET /api/transport/loads/list-by-truck-type/?truck_type=tipper&pickup_city=...
  Future<void> _filterLoadsByTruckType(
    String truckTypeSlug, {
    String? pickupCity,
    bool showToast = false,
  }) async {
    setState(() {
      _isLoading = true;
      _selectedTruckTypeSlug = truckTypeSlug;
    });

    try {
      final userId = await SessionManager().getUserId(fallback: 1);
      final activeCity = pickupCity ??
          (_selectedLoadsFrom != 'All' ? _selectedLoadsFrom : null);

      final result = await ServicesRepo().fetchTransportLoadsByTruckType(
        truckType: truckTypeSlug,
        pickupCity: activeCity,
        userId: userId,
      );

      if (mounted) {
        if (result != null) {
          setState(() {
            _activeTruckTypeFilter = result.filters;
            _availableCities = result.availableCities;
            _truckTypeResultCount = result.count;
            _allLoads = result.results;

            // Dynamically update origin sub-locations from available cities in response
            _subLocations.clear();
            _subLocations.add('All');
            if (result.availableCities != null) {
              for (final c in result.availableCities!.pickupCities) {
                if (c.isNotEmpty && !_subLocations.contains(c)) {
                  _subLocations.add(c);
                }
              }
            }
            for (final l in _allLoads) {
              if (l.loadsFrom.isNotEmpty && !_subLocations.contains(l.loadsFrom)) {
                _subLocations.add(l.loadsFrom);
              }
            }
          });

          if (showToast) {
            final displayName =
                result.filters?.truckTypeDisplay ?? _selectedTruckType ?? truckTypeSlug;
            showCooliToast(
              context,
              message: result.count > 0
                  ? 'Found ${result.count} load${result.count == 1 ? '' : 's'} for $displayName'
                  : 'No loads found for $displayName',
              icon: Icons.filter_alt_rounded,
              iconColor: primaryBlue,
            );
          }
        } else {
          setState(() {
            _allLoads = [];
            _truckTypeResultCount = 0;
          });
        }
      }
    } catch (e) {
      debugPrint('[BlackbuckLoadsView] _filterLoadsByTruckType error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearTruckTypeFilter() {
    setState(() {
      _selectedTruckType = null;
      _selectedTruckTypeSlug = null;
      _activeTruckTypeFilter = null;
      _availableCities = null;
      _truckTypeResultCount = null;
      _selectedLoadsFrom = 'All';
    });
    _loadLiveLoads();
    showCooliToast(
      context,
      message: 'Cleared truck filter, showing all loads',
      icon: Icons.refresh_rounded,
      iconColor: primaryBlue,
    );
  }

  void _onSelectTruckType(TransportVehicleTypeModel type) {
    if (_selectedTruckTypeSlug == type.typeKey ||
        _selectedTruckType == type.name) {
      _clearTruckTypeFilter();
    } else {
      setState(() {
        _selectedTruckType = type.name;
        _selectedTruckTypeSlug = type.typeKey;
      });
      _filterLoadsByTruckType(type.typeKey, showToast: true);
    }
  }

  Future<void> _loadLiveLoads() async {
    setState(() => _isLoading = true);
    try {
      if (_isLocationSearch && _activeLat != null && _activeLng != null) {
        final locResult = await ServicesRepo().fetchTransportLoadsByLocation(
          latitude: _activeLat!,
          longitude: _activeLng!,
          radiusKm: _activeRadiusKm,
          locationType: _activeLocationType,
        );

        if (mounted) {
          if (locResult != null) {
            setState(() {
              _locationResultCount = locResult.count;
              _allLoads = locResult.results;
              _subLocations.clear();
              _subLocations.add('All');
              for (final l in _allLoads) {
                if (!_subLocations.contains(l.loadsFrom) &&
                    l.loadsFrom.isNotEmpty) {
                  _subLocations.add(l.loadsFrom);
                }
              }
            });
          } else {
            setState(() {
              _locationResultCount = 0;
              _allLoads = [];
            });
          }
        }
      } else {
        final userId = await SessionManager().getUserId(fallback: 1);
        final liveLoads =
            await ServicesRepo().fetchTransportLoads(userId: userId);
        if (mounted && liveLoads.isNotEmpty) {
          setState(() {
            _allLoads = liveLoads;
            for (final l in liveLoads) {
              if (!_subLocations.contains(l.loadsFrom) &&
                  l.loadsFrom.isNotEmpty) {
                _subLocations.add(l.loadsFrom);
              }
            }
            if (widget.initialRoute == null && liveLoads.first.route.isNotEmpty) {
              _selectedRoute = liveLoads.first.route;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[BlackbuckLoadsView] _loadLiveLoads error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Change loading/pickup or destination spot from interactive Google Map
  Future<void> _changeLocationOnMap({bool isPickup = true}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideMapPickerView(
          isPickup: isPickup,
          singleLocationOnly: false,
          initialPickupAddress: _activeSearchAddress,
          initialDropAddress: _activeDropAddress,
          initialPickupLat: _activeLat,
          initialPickupLng: _activeLng,
          initialDropLat: _activeDropLat,
          initialDropLng: _activeDropLng,
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
            _activeSearchAddress = pAddress;
            _activeLat = result.pickup.latitude;
            _activeLng = result.pickup.longitude;
            _isLocationSearch = true;
          }
          if (dAddress.isNotEmpty) {
            _activeDropAddress = dAddress;
            _activeDropLat = result.drop.latitude;
            _activeDropLng = result.drop.longitude;
          }
          if (pAddress.isNotEmpty && dAddress.isNotEmpty) {
            _selectedRoute = '$pAddress - $dAddress';
          }
        });
        _loadLiveLoads();
      } else if (result is LocationResult) {
        final address = result.fullAddress.isNotEmpty
            ? result.fullAddress
            : result.title;
        setState(() {
          if (isPickup) {
            _activeSearchAddress = address;
            _activeLat = result.latitude;
            _activeLng = result.longitude;
            _isLocationSearch = true;
          } else {
            _activeDropAddress = address;
            _activeDropLat = result.latitude;
            _activeDropLng = result.longitude;
          }
        });
        _loadLiveLoads();
      }
    }
  }

  void _setRadius(double radius) {
    setState(() {
      _activeRadiusKm = radius;
    });
    _loadLiveLoads();
  }

  void _showAllIndiaLoads() {
    setState(() {
      _isLocationSearch = false;
      _activeLat = null;
      _activeLng = null;
      _selectedTruckType = null;
      _selectedTruckTypeSlug = null;
      _activeTruckTypeFilter = null;
      _availableCities = null;
      _truckTypeResultCount = null;
      _selectedLoadsFrom = 'All';
    });
    _loadLiveLoads();
  }


  bool _matchesSelectedTruck(BlackbuckLoadModel load, String selected) {
    final sel = selected.toLowerCase().trim();
    final cat = load.vehicleCategory.toLowerCase().trim();
    final truck = load.truckType.toLowerCase().trim();

    if (cat.contains(sel) || truck.contains(sel)) return true;

    if (sel.contains('small')) {
      return cat.contains('small') ||
          cat.contains('mini') ||
          cat.contains('pickup') ||
          cat.contains('lcv') ||
          truck.contains('small') ||
          truck.contains('mini') ||
          truck.contains('pickup') ||
          truck.contains('lcv');
    }

    if (sel.contains('medium')) {
      return cat.contains('medium') ||
          cat.contains('tipper') ||
          truck.contains('medium') ||
          truck.contains('6 wheeler') ||
          truck.contains('tipper');
    }

    if (sel.contains('large')) {
      return cat.contains('large') ||
          cat.contains('open') ||
          cat.contains('bulker') ||
          cat.contains('tanker') ||
          truck.contains('large') ||
          truck.contains('open body') ||
          truck.contains('10-12 wheeler') ||
          truck.contains('14 wheeler') ||
          truck.contains('multi-axle');
    }

    if (sel.contains('container')) {
      return cat.contains('container') || truck.contains('container');
    }

    if (sel.contains('trailer')) {
      return cat.contains('trailer') ||
          cat.contains('flatbed') ||
          truck.contains('trailer') ||
          truck.contains('flatbed');
    }

    return false;
  }

  List<BlackbuckLoadModel> get _filteredLoads {
    return _allLoads.where((load) {
      final matchesLocation = _selectedLoadsFrom == 'All' ||
          load.loadsFrom.toLowerCase() == _selectedLoadsFrom.toLowerCase() ||
          (load.pickupCity != null &&
              load.pickupCity!.toLowerCase() == _selectedLoadsFrom.toLowerCase());

      // If filtered by backend API using truck_type, all loads in _allLoads already match
      if (_selectedTruckTypeSlug != null) {
        return matchesLocation;
      }

      final matchesTruck = _selectedTruckType == null ||
          _matchesSelectedTruck(load, _selectedTruckType!);
      return matchesLocation && matchesTruck;
    }).toList();
  }

  Future<void> _makePhoneCall(String phoneNumber, String name) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) {
          showCooliToast(
            context,
            message: 'Calling $name: $phoneNumber',
            icon: Icons.phone_forwarded_rounded,
            iconColor: primaryBlue,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        showCooliToast(
          context,
          message: 'Calling $name: $phoneNumber',
          icon: Icons.phone_forwarded_rounded,
          iconColor: primaryBlue,
        );
      }
    }
  }

  void _showRoutePicker() {
    final routes = [
      'Kochi - Calicut',
      'Ernakulam - Bengaluru',
      'Kochi - Chennai',
      'Ernakulam - Coimbatore',
      'Kozhikode - Bengaluru',
      'Thiruvananthapuram - Chennai',
      'Thrissur - Hyderabad',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CooliColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Switch Corridor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: CooliColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ...routes.map((route) {
                final isSelected = route == _selectedRoute;
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: isSelected ? primaryBlue : CooliColors.textLight,
                    ),
                    title: Text(
                      route,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? primaryBlue : CooliColors.textMuted,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedRoute = route;
                      });
                      Navigator.pop(context);
                      showCooliToast(
                        context,
                        message: 'Loaded loads for $route',
                        icon: Icons.route_rounded,
                        iconColor: primaryBlue,
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showSetAlertDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Icon(Icons.notifications_active_rounded,
                color: primaryBlue, size: 24),
            SizedBox(width: 10),
            Text(
              'Set Route Alert',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: CooliColors.textDark,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get instant WhatsApp & SMS alerts as soon as new loads are posted for:',
              style: TextStyle(
                  fontSize: 13, color: CooliColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedRoute,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: CooliColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showCooliToast(
                context,
                message: 'Alert set for $_selectedRoute!',
                icon: Icons.check_circle_rounded,
                iconColor: CooliColors.success,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Enable Alert',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentSupportSheet() {
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Trip & Payment Guarantee',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: CooliColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '• 80% Trip advance paid directly to driver before loading\n'
                '• Guaranteed 24h POD settlement directly to your bank account\n'
                '• 100% Transit insurance coverage on registered loads\n'
                '• Dedicated dispatch helpline: 1800-200-COOL',
                style: TextStyle(
                  fontSize: 14,
                  color: CooliColors.textMuted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              CooliButton(
                text: 'Got It',
                backgroundColor: primaryBlue,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loads = _filteredLoads;

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
        titleSpacing: 0,
        title: GestureDetector(
          onTap: _showRoutePicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: CooliColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sync_alt_rounded,
                  color: primaryBlue,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _selectedRoute,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: CooliColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: CooliColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Set Alert Button
          GestureDetector(
            onTap: _showSetAlertDialog,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryBlue, width: 1.2),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.notifications_active_outlined,
                    color: primaryBlue,
                    size: 15,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Alerts',
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLocationSearch) _buildLocationSearchBanner(),

          // Truck Type Selector Carousel
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Select Truck Type',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: CooliColors.textDark,
                          ),
                        ),
                        if (_selectedTruckType != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _clearTruckTypeFilter,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryBlue.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${_activeTruckTypeFilter?.truckTypeDisplay ?? _selectedTruckType!}${_truckTypeResultCount != null ? ' ($_truckTypeResultCount)' : ''}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: primaryBlue,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.close_rounded,
                                      size: 13, color: primaryBlue),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isTruckTypesExpanded = !_isTruckTypesExpanded;
                        });
                      },
                      child: Icon(
                        _isTruckTypesExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: CooliColors.textMuted,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                if (_isTruckTypesExpanded) ...[
                  const SizedBox(height: 10),
                  _buildTruckTypesCarousel(),
                ],
              ],
            ),
          ),

          // Origin Filter Chips Bar
          Container(
            color: CooliColors.surfaceAlt,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        color: CooliColors.textMuted, size: 16),
                    const SizedBox(width: 4),
                    const Text(
                      'Loads From: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: CooliColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: _subLocations.map((loc) {
                            final isSelected = _selectedLoadsFrom == loc;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedLoadsFrom = loc;
                                });
                                if (_selectedTruckTypeSlug != null) {
                                  _filterLoadsByTruckType(
                                    _selectedTruckTypeSlug!,
                                    pickupCity: loc != 'All' ? loc : null,
                                  );
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryBlue : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryBlue
                                        : CooliColors.border,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  loc,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : CooliColors.textDark,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_availableCities != null &&
                    _availableCities!.dropCities.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.alt_route_rounded,
                          size: 13, color: primaryBlue),
                      const SizedBox(width: 4),
                      Text(
                        'Drop Hubs: ${_availableCities!.dropCities.join(', ')}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Loads List Cards
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      if (_selectedTruckTypeSlug != null) {
                        await Future.wait([
                          _filterLoadsByTruckType(_selectedTruckTypeSlug!),
                          _loadVehicleTypes(),
                        ]);
                      } else {
                        await Future.wait([
                          _loadLiveLoads(),
                          _loadVehicleTypes(),
                        ]);
                      }
                    },
                    color: primaryBlue,
                    child: loads.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              _buildEmptyState(),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: loads.length,
                            itemBuilder: (context, index) {
                              return _buildElevatedLoadCard(loads[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),

      // Bottom Support Bar with primaryBlue accent
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SafeArea(
          top: false,
          child: GestureDetector(
            onTap: _showPaymentSupportSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), primaryBlue],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: CooliShadows.button,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.currency_rupee_rounded,
                      color: primaryBlue,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Trip Advance & Payment Protection',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '80% trip advance • 24h POD settlement',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSearchBanner() {
    if (!_isLocationSearch || _activeLat == null || _activeLng == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryBlue.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.my_location_rounded,
                      color: primaryBlue, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _activeSearchAddress ?? 'Search Location',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: CooliColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_activeRadiusKm.toInt()} km',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_activeLat!.toStringAsFixed(4)}° N, ${_activeLng!.toStringAsFixed(4)}° E • $_locationResultCount live load${_locationResultCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: CooliColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Change on Map Button
                GestureDetector(
                  onTap: () => _changeLocationOnMap(isPickup: true),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: CooliShadows.button,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.map_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'MAP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Quick Radius Selector Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  ...[25.0, 50.0, 100.0, 250.0, 500.0].map((r) {
                    final isSel = _activeRadiusKm == r;
                    return GestureDetector(
                      onTap: () => _setRadius(r),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel ? primaryBlue : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel ? primaryBlue : CooliColors.border,
                          ),
                        ),
                        child: Text(
                          '${r.toInt()} km',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSel ? FontWeight.w800 : FontWeight.w600,
                            color: isSel ? Colors.white : CooliColors.textDark,
                          ),
                        ),
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: _showAllIndiaLoads,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CooliColors.border),
                      ),
                      child: const Text(
                        'All India',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CooliColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_isLocationSearch) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  size: 46,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Loads within ${_activeRadiusKm.toInt()} km',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: CooliColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'No active truck consignments found near ${_activeSearchAddress ?? 'your selected location'}. Try expanding your search radius or choose another loading hub on the map.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: CooliColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.zoom_out_map_rounded, size: 16),
                    label: const Text('Expand to 250 km'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _setRadius(250.0),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map_rounded, size: 16),
                    label: const Text('Change on Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryBlue,
                      side: const BorderSide(color: primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _changeLocationOnMap(isPickup: true),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _showAllIndiaLoads,
                child: const Text(
                  'Browse All India Loads',
                  style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    }

    if (_selectedTruckType != null) {
      final displayTruck =
          _activeTruckTypeFilter?.truckTypeDisplay ?? _selectedTruckType!;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryBlue.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  size: 44,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No $displayTruck Loads Available',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: CooliColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'There are currently 0 active loads posted for "$displayTruck". Try selecting a different truck type or clear the filter to browse all consignments.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: CooliColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Show All Loads'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: _clearTruckTypeFilter,
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CooliColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                size: 40,
                color: CooliColors.textLight,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No loads match this filter',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: CooliColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedLoadsFrom = 'All';
                });
                if (_selectedTruckTypeSlug != null) {
                  _filterLoadsByTruckType(_selectedTruckTypeSlug!);
                } else {
                  _clearTruckTypeFilter();
                }
              },
              child: const Text(
                'Show All Loads',
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTruckTypesCarousel() {
    if (_isLoadingVehicleTypes && _vehicleTypes.isEmpty) {
      return const SizedBox(
        height: 96,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _vehicleTypes.map((type) {
          final isSelected = _selectedTruckTypeSlug == type.typeKey ||
              _selectedTruckType == type.name;
          return GestureDetector(
            onTap: () => _onSelectTruckType(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 104,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? primaryBlue : CooliColors.border,
                  width: isSelected ? 1.8 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? primaryBlue.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFDBEAFE)
                              : CooliColors.surfaceAlt,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          type.iconData,
                          size: 22,
                          color: isSelected ? primaryBlue : CooliColors.textMuted,
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    type.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? primaryBlue : CooliColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.capacity,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? primaryBlue : CooliColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildElevatedLoadCard(BlackbuckLoadModel load) {
    // Dynamic status styling based on live load status
    Color statusBg = const Color(0xFFEFF6FF);
    Color statusBorder = const Color(0xFFBFDBFE);
    Color statusColor = primaryBlue;
    IconData statusIcon = Icons.local_shipping_outlined;

    if (load.isBidAccepted) {
      statusBg = const Color(0xFFECFDF5);
      statusBorder = const Color(0xFFA7F3D0);
      statusColor = const Color(0xFF059669);
      statusIcon = Icons.check_circle_rounded;
    } else if (load.isBiddingOpen) {
      statusBg = const Color(0xFFFFFBEB);
      statusBorder = const Color(0xFFFDE68A);
      statusColor = const Color(0xFFD97706);
      statusIcon = Icons.bolt_rounded;
    } else if (load.isNew) {
      statusBg = const Color(0xFFECFDF5);
      statusBorder = const Color(0xFFA7F3D0);
      statusColor = const Color(0xFF059669);
      statusIcon = Icons.fiber_new_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CooliColors.border),
        boxShadow: CooliShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlackbuckLoadDetailsView(
                  load: load,
                  bookingId: load.bookingId ?? 'CL-20261005-4950',
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag Row: Status Badge, Load ID & Fare Range
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: statusBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 12, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  load.statusBadgeLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Container(
                          //   padding: const EdgeInsets.symmetric(
                          //       horizontal: 7, vertical: 3.5),
                          //   decoration: BoxDecoration(
                          //     color: CooliColors.surfaceAlt,
                          //     borderRadius: BorderRadius.circular(6),
                          //     border: Border.all(color: CooliColors.border),
                          //   ),
                          //   child: Text(
                          //     '#${load.id}',
                          //     style: const TextStyle(
                          //       color: CooliColors.textMuted,
                          //       fontSize: 10,
                          //       fontWeight: FontWeight.w700,
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          load.totalEarnings,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: primaryBlue,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          load.paymentTerms,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: CooliColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Route Timeline
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: CooliColors.success,
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 28,
                          color: CooliColors.border,
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: CooliColors.danger,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  load.loadingPoint,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: CooliColors.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFBFDBFE),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.route_rounded,
                                      size: 11,
                                      color: primaryBlue,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      load.distance,
                                      style: const TextStyle(
                                        color: primaryBlue,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            load.unloadingPoint,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: CooliColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_isLocationSearch && load.distanceInKm != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: primaryBlue.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.near_me_rounded,
                                      size: 11, color: primaryBlue),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${load.distanceInKm!.toStringAsFixed(1)} km from loading point',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: CooliColors.textLight,
                    ),
                  ],
                ),

                // Pickup Schedule Pill (if available)
                if (load.formattedPickupSchedule.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 13,
                          color: primaryBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Pickup: ${load.formattedPickupSchedule}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: CooliColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Specs Chips Row
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildSpecTag(
                        Icons.local_shipping_outlined, load.truckType),
                    _buildSpecTag(Icons.scale_outlined, load.capacity),
                    _buildSpecTag(Icons.inventory_2_outlined, load.product),
                    _buildSpecTag(Icons.donut_large_outlined, load.wheelers),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(color: CooliColors.borderLight, height: 1),
                const SizedBox(height: 10),

                // Transporter & Action Row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: const Color(0xFFEFF6FF),
                      child: const Icon(
                        Icons.business_rounded,
                        color: primaryBlue,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            load.transporterName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: CooliColors.textDark,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${load.rating}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFF59E0B),
                                size: 12,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  load.contactPerson,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: CooliColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Quick Actions (Call & Bid/View)
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _makePhoneCall(
                              load.phoneNumber, load.transporterName),
                          icon: const Icon(Icons.call,
                              color: primaryBlue, size: 13),
                          label: const Text(
                            'Call',
                            style: TextStyle(
                              color: primaryBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: primaryBlue),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (load.isBiddingOpen) {
                              showCreateBidBottomSheet(
                                context,
                                load: load,
                                onBidSubmitted: () {
                                  _loadLiveLoads();
                                },
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BlackbuckLoadDetailsView(load: load),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            load.isBiddingOpen ? 'Place Bid' : 'View Load',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildSpecTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CooliColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CooliColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: CooliColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CooliColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
