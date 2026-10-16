import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:cooli/features/porter/view_model/porter_view_model.dart';
import 'package:cooli/features/porter/view/track_porter_view.dart';
import 'package:cooli/features/porter/view/my_porter_bookings_view.dart';
import 'package:cooli/features/ride/view/ride_map_picker_view.dart';
import 'package:cooli/features/ride/service/ride_location_service.dart';

class BookPorterView extends StatefulWidget {
  static const String routeName = '/book-porter';

  const BookPorterView({super.key});

  @override
  State<BookPorterView> createState() => _BookPorterViewState();
}

class _BookPorterViewState extends State<BookPorterView> {
  late PorterViewModel _viewModel;
  final TextEditingController _pickupCtrl = TextEditingController(text: '');
  final TextEditingController _dropCtrl = TextEditingController();
  final TextEditingController _itemsCtrl = TextEditingController(text: '');
  final TextEditingController _dateTimeCtrl = TextEditingController(text: '');

  // Booking detail form controllers
  final TextEditingController _pickupContactCtrl = TextEditingController();
  final TextEditingController _pickupMobileCtrl = TextEditingController();
  final TextEditingController _pickupInstructionsCtrl = TextEditingController();
  final TextEditingController _receiverNameCtrl = TextEditingController();
  final TextEditingController _receiverMobileCtrl = TextEditingController();
  final TextEditingController _deliveryInstructionsCtrl =
      TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _itemCountCtrl = TextEditingController(text: '1');
  final TextEditingController _specialInstructionsCtrl =
      TextEditingController();
  bool _loadingRequired = false;
  bool _unloadingRequired = false;

  // Country dial codes for phone fields (default: India +91)
  String _pickupDialCode = '+91';
  String _receiverDialCode = '+91';

  double? _pickupLat = 0.00;
  double? _pickupLng = 0.00;
  double? _dropLat;
  double? _dropLng;

  GoogleMapController? _mapController;
  final RideLocationService _locationService = RideLocationService();
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  bool _isLoadingLocation = false;

  bool _didInit = false;

  @override
  void initState() {
    super.initState();

    // Automatically detect and set the user's live physical GPS location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAndSetCurrentLocation();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel = context.read<PorterViewModel>();
    if (!_didInit) {
      _didInit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _viewModel.setPickup(_pickupCtrl.text,
            lat: _pickupLat, lng: _pickupLng);
      });
    }
  }

  Future<void> _fetchAndSetCurrentLocation({bool showFeedback = false}) async {
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);

    try {
      final clientLoc = await _locationService.getCurrentClientLocation();
      if (mounted && clientLoc != null) {
        final address = clientLoc.fullAddress.isNotEmpty
            ? clientLoc.fullAddress
            : (clientLoc.title.isNotEmpty
                ? clientLoc.title
                : 'Current Location');

        setState(() {
          _pickupLat = clientLoc.latitude;
          _pickupLng = clientLoc.longitude;
          _pickupCtrl.text = address;
        });

        _viewModel.setPickup(address,
            lat: clientLoc.latitude, lng: clientLoc.longitude);

        await _updateRouteAndCamera();

        if (showFeedback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.my_location_rounded,
                      color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pickup set to ${clientLoc.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0F172A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[BookPorterView] fetch current location error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _centerMapOnPickup() {
    if (_mapController != null && _pickupLat != null && _pickupLng != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_pickupLat!, _pickupLng!),
          15.5,
        ),
      );
    }
  }

  void _fitRouteCamera() {
    if (_mapController == null) return;
    if (_routePoints.isNotEmpty) {
      double south = _routePoints.first.latitude;
      double north = _routePoints.first.latitude;
      double west = _routePoints.first.longitude;
      double east = _routePoints.first.longitude;

      for (final p in _routePoints) {
        if (p.latitude < south) south = p.latitude;
        if (p.latitude > north) north = p.latitude;
        if (p.longitude < west) west = p.longitude;
        if (p.longitude > east) east = p.longitude;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(south, west),
        northeast: LatLng(north, east),
      );
      try {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 42),
        );
      } catch (_) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng((south + north) / 2, (west + east) / 2),
            12.5,
          ),
        );
      }
    } else if (_pickupLat != null && _pickupLng != null) {
      _centerMapOnPickup();
    }
  }

  Future<void> _updateRouteAndCamera() async {
    if (_pickupLat == null || _dropLat == null) {
      _centerMapOnPickup();
      return;
    }
    final start = LatLng(_pickupLat!, _pickupLng!);
    final end = LatLng(_dropLat!, _dropLng!);

    setState(() => _isLoadingRoute = true);

    try {
      final details = await _locationService.getRouteDetails(start, end);
      if (mounted) {
        final points = details?.coordinates ?? [start, end];
        setState(() {
          _routePoints = points;
          _isLoadingRoute = false;
        });

        if (details != null && details.distanceKm > 0) {
          _viewModel.setDistance(details.distanceKm);
        }

        if (points.isNotEmpty && _mapController != null) {
          _fitRouteCamera();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _routePoints = [start, end];
          _isLoadingRoute = false;
        });
        _fitRouteCamera();
      }
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    if (_pickupLat != null && _pickupLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('porter_pickup'),
          position: LatLng(_pickupLat!, _pickupLng!),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: _pickupCtrl.text,
          ),
        ),
      );
    }
    if (_dropLat != null && _dropLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('porter_drop'),
          position: LatLng(_dropLat!, _dropLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Drop-off Destination',
            snippet: _dropCtrl.text,
          ),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_routePoints.isEmpty) return {};
    return {
      Polyline(
        polylineId: const PolylineId('porter_route_path'),
        points: _routePoints,
        color: const Color(0xFF4F46E5),
        width: 5,
        geodesic: false,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  Future<void> _openMapPicker({required bool isPickup}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideMapPickerView(
          isPickup: isPickup,
          singleLocationOnly: false,
          initialPickupAddress:
              _pickupCtrl.text.isNotEmpty ? _pickupCtrl.text : null,
          initialDropAddress: _dropCtrl.text.isNotEmpty ? _dropCtrl.text : null,
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

        if (pAddress.isNotEmpty) {
          setState(() {
            _pickupCtrl.text = pAddress;
            _pickupLat = result.pickup.latitude;
            _pickupLng = result.pickup.longitude;
          });
          _viewModel.setPickup(pAddress,
              lat: result.pickup.latitude, lng: result.pickup.longitude);
        }

        if (dAddress.isNotEmpty) {
          setState(() {
            _dropCtrl.text = dAddress;
            _dropLat = result.drop.latitude;
            _dropLng = result.drop.longitude;
          });
          _viewModel.setDrop(dAddress,
              lat: result.drop.latitude, lng: result.drop.longitude);
        }
      } else if (result is LocationResult) {
        final address =
            result.fullAddress.isNotEmpty ? result.fullAddress : result.title;
        if (isPickup) {
          setState(() {
            _pickupCtrl.text = address;
            _pickupLat = result.latitude;
            _pickupLng = result.longitude;
          });
          _viewModel.setPickup(address,
              lat: result.latitude, lng: result.longitude);
        } else {
          setState(() {
            _dropCtrl.text = address;
            _dropLat = result.latitude;
            _dropLng = result.longitude;
          });
          _viewModel.setDrop(address,
              lat: result.latitude, lng: result.longitude);
        }
      }
      _updateRouteAndCamera();
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime == null || !mounted) return;

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final period = pickedTime.period == DayPeriod.am ? 'AM' : 'PM';
    final hour = pickedTime.hourOfPeriod == 0 ? 12 : pickedTime.hourOfPeriod;
    final minute = pickedTime.minute.toString().padLeft(2, '0');

    final isToday = pickedDate.year == now.year &&
        pickedDate.month == now.month &&
        pickedDate.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = pickedDate.year == tomorrow.year &&
        pickedDate.month == tomorrow.month &&
        pickedDate.day == tomorrow.day;

    final dateStr = isToday
        ? 'Today'
        : isTomorrow
            ? 'Tomorrow'
            : '${pickedDate.day} ${months[pickedDate.month - 1]} ${pickedDate.year}';

    final formatted = '$dateStr, $hour:$minute $period';
    setState(() {
      _dateTimeCtrl.text = formatted;
    });
    _viewModel.setDateTime(formatted);
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropCtrl.dispose();
    _itemsCtrl.dispose();
    _dateTimeCtrl.dispose();
    _pickupContactCtrl.dispose();
    _pickupMobileCtrl.dispose();
    _pickupInstructionsCtrl.dispose();
    _receiverNameCtrl.dispose();
    _receiverMobileCtrl.dispose();
    _deliveryInstructionsCtrl.dispose();
    _weightCtrl.dispose();
    _itemCountCtrl.dispose();
    _specialInstructionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          'Book Porter',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF4F46E5),
              size: 22,
            ),
            tooltip: 'My Bookings',
            onPressed: () {
              Navigator.pushNamed(context, MyPorterBookingsView.routeName);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: Consumer<PorterViewModel>(
        builder: (context, vm, child) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vehicle Selection Horizontal List
                      const Text(
                        'Select Vehicle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 126,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: vm.vehicles.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final v = vm.vehicles[index];
                            final isSelected = vm.selectedVehicle?.id == v.id;
                            return GestureDetector(
                              onTap: () => vm.selectVehicle(v),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 118,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF4F46E5)
                                        : const Color(0xFFE2E8F0),
                                    width: isSelected ? 2.0 : 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? const Color(0xFF4F46E5)
                                              .withValues(alpha: 0.15)
                                          : Colors.black
                                              .withValues(alpha: 0.03),
                                      blurRadius: isSelected ? 12 : 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      v.icon,
                                      size: 28,
                                      color: isSelected
                                          ? const Color(0xFF4F46E5)
                                          : const Color(0xFF1E293B),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      v.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? const Color(0xFF4F46E5)
                                            : const Color(0xFF0F172A),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      v.capacity,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Pickup Location Input Field
                      _buildCustomInputField(
                        label: 'Pickup Location',
                        icon: Icons.my_location_rounded,
                        iconColor: const Color(0xFF4F46E5),
                        iconBgColor: const Color(0xFFEEF2FF),
                        controller: _pickupCtrl,
                        onTap: () => _openMapPicker(isPickup: true),
                        onMapTap: () => _openMapPicker(isPickup: true),
                        onGpsTap: () =>
                            _fetchAndSetCurrentLocation(showFeedback: true),
                        isGpsLoading: _isLoadingLocation,
                        hintText: 'Detecting current location...',
                      ),

                      if (vm.distanceKm > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6.0, horizontal: 16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 2,
                                height: 18,
                                color: const Color(0xFFCBD5E1),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.route_rounded,
                                        size: 12, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${vm.distanceKm.toStringAsFixed(1)} km route distance',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox(height: 14),

                      // Drop Location Input Field
                      _buildCustomInputField(
                        label: 'Drop Location',
                        icon: Icons.location_on_rounded,
                        iconColor: const Color(0xFFEF4444),
                        iconBgColor: const Color(0xFFFEE2E2),
                        controller: _dropCtrl,
                        onTap: () => _openMapPicker(isPickup: false),
                        onMapTap: () => _openMapPicker(isPickup: false),
                        hintText: 'Select destination point on Map',
                      ),

                      const SizedBox(height: 18),

                      // Interactive Map Route Preview
                      _buildMapRoutePreview(vm),

                      const SizedBox(height: 18),

                      // Item Details Input Field
                      _buildCustomInputField(
                        label: 'Item Details',
                        icon: Icons.inventory_2_outlined,
                        iconColor: const Color(0xFFD97706),
                        iconBgColor: const Color(0xFFFEF3C7),
                        controller: _itemsCtrl,
                      ),

                      const SizedBox(height: 16),

                      // Date & Time Input with Native Picker
                      _buildCustomInputField(
                        label: 'Date & Time',
                        icon: Icons.calendar_month_rounded,
                        iconColor: const Color(0xFF0284C7),
                        iconBgColor: const Color(0xFFE0F2FE),
                        controller: _dateTimeCtrl,
                        isReadOnly: true,
                        onTap: _pickDateTime,
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.access_time_rounded,
                            color: Color(0xFF0284C7),
                            size: 22,
                          ),
                          onPressed: _pickDateTime,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Select date & time',
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom Sticky Price & Continue Card
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(26),
                    topRight: Radius.circular(26),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, -4),
                    ),
                  ],
                  border:
                      const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Estimated Price',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          vm.isCalculatingFare
                              ? 'Calculating...'
                              : (vm.estimatedFare != null &&
                                      vm.estimatedFare! > 0
                                  ? '₹${vm.estimatedFare!.toStringAsFixed(0)}'
                                  : (vm.selectedVehicle != null
                                      ? '₹${(vm.selectedVehicle!.basePrice + ((vm.distanceKm > 0 ? vm.distanceKm : 5.0) * vm.selectedVehicle!.perKmRate)).toStringAsFixed(0)}'
                                      : '₹--')),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF4F46E5),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => _showBookingSheet(context, vm),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                            shadowColor:
                                const Color(0xFF4F46E5).withValues(alpha: 0.35),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Continue',
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
            ],
          );
        },
      ),
    );
  }

  // ─── Booking Sheet & Submission ─────────────────────────────────────────────

  void _showBookingSheet(BuildContext ctx, PorterViewModel vm) {
    if (_pickupCtrl.text.isEmpty || _dropCtrl.text.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: const Text('Please select both pickup and drop locations.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.92,
            minChildSize: 0.55,
            maxChildSize: 0.97,
            expand: false,
            builder: (_, scrollCtrl) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    // ── Sticky Header ──────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Column(
                        children: [
                          // Handle bar
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Booking Details',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Fill in contact & delivery info below',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Fare + vehicle chip
                              Builder(
                                builder: (context) {
                                  final double sheetFare =
                                      (vm.estimatedFare != null &&
                                              vm.estimatedFare! > 0)
                                          ? vm.estimatedFare!
                                          : (vm.selectedVehicle != null
                                              ? (vm.selectedVehicle!.basePrice +
                                                  ((vm.distanceKm > 0
                                                          ? vm.distanceKm
                                                          : 5.0) *
                                                      vm.selectedVehicle!
                                                          .perKmRate))
                                              : 350.0);
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${sheetFare.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF4F46E5),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const Text(
                                        'Est. Fare',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF94A3B8),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Route pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0), width: 1),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.circle,
                                    size: 9, color: Color(0xFF10B981)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _pickupCtrl.text.isNotEmpty
                                        ? _pickupCtrl.text
                                        : 'Pickup',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Container(
                                    height: 1,
                                    width: 18,
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                ),
                                const Icon(Icons.location_on,
                                    size: 12, color: Color(0xFFEF4444)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _dropCtrl.text.isNotEmpty
                                        ? _dropCtrl.text
                                        : 'Drop',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Scrollable Form Body ───────────────────────────────
                    Expanded(
                      child: ListView(
                        controller: scrollCtrl,
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom:
                              MediaQuery.of(sheetCtx).viewInsets.bottom + 32,
                        ),
                        children: [
                          // ── Section 1: Pickup Contact ──────────────────
                          _buildSheetSection(
                            icon: Icons.person_pin_circle_rounded,
                            iconColor: const Color(0xFF4F46E5),
                            iconBg: const Color(0xFFEEF2FF),
                            title: 'Pickup Contact',
                            subtitle:
                                'Who should the driver contact at pickup?',
                            children: [
                              _modernSheetField(
                                controller: _pickupContactCtrl,
                                label: 'Contact Person Name *',
                                icon: Icons.badge_rounded,
                                hint: 'Full name',
                                keyboardType: TextInputType.name,
                              ),
                              const SizedBox(height: 10),
                              _phoneInputField(
                                controller: _pickupMobileCtrl,
                                label: 'Pickup Mobile Number *',
                                dialCode: _pickupDialCode,
                                onDialCodeChanged: (code) =>
                                    setState(() => _pickupDialCode = code),
                                setSheetState: setSheetState,
                              ),
                              const SizedBox(height: 10),
                              _modernSheetField(
                                controller: _pickupInstructionsCtrl,
                                label: 'Pickup Instructions',
                                icon: Icons.info_outline_rounded,
                                hint: 'Gate No., floor, landmark...',
                                keyboardType: TextInputType.text,
                                isOptional: true,
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // ── Section 2: Receiver Details ────────────────
                          _buildSheetSection(
                            icon: Icons.person_outline_rounded,
                            iconColor: const Color(0xFF0284C7),
                            iconBg: const Color(0xFFE0F2FE),
                            title: 'Receiver Details',
                            subtitle: 'Who will receive the goods at drop-off?',
                            children: [
                              _modernSheetField(
                                controller: _receiverNameCtrl,
                                label: 'Receiver Name *',
                                icon: Icons.badge_outlined,
                                hint: 'Full name',
                                keyboardType: TextInputType.name,
                              ),
                              const SizedBox(height: 10),
                              _phoneInputField(
                                controller: _receiverMobileCtrl,
                                label: 'Receiver Mobile Number *',
                                dialCode: _receiverDialCode,
                                onDialCodeChanged: (code) =>
                                    setState(() => _receiverDialCode = code),
                                setSheetState: setSheetState,
                              ),
                              const SizedBox(height: 10),
                              _modernSheetField(
                                controller: _deliveryInstructionsCtrl,
                                label: 'Delivery Instructions',
                                icon: Icons.info_outline_rounded,
                                hint: 'Ring bell, leave at door...',
                                keyboardType: TextInputType.text,
                                isOptional: true,
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // ── Section 3: Goods Info ──────────────────────
                          _buildSheetSection(
                            icon: Icons.inventory_2_rounded,
                            iconColor: const Color(0xFFD97706),
                            iconBg: const Color(0xFFFEF3C7),
                            title: 'Goods Information',
                            subtitle: 'Describe what is being transported.',
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _modernSheetField(
                                      controller: _weightCtrl,
                                      label: 'Weight (kg)',
                                      icon: Icons.fitness_center_rounded,
                                      hint: 'e.g. 500',
                                      keyboardType: TextInputType.number,
                                      isOptional: true,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _modernSheetField(
                                      controller: _itemCountCtrl,
                                      label: 'No. of Items',
                                      icon: Icons.numbers_rounded,
                                      hint: '1',
                                      keyboardType: TextInputType.number,
                                      isOptional: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _modernSheetField(
                                controller: _specialInstructionsCtrl,
                                label: 'Special Instructions',
                                icon: Icons.star_outline_rounded,
                                hint: 'Handle with care, fragile...',
                                keyboardType: TextInputType.text,
                                isOptional: true,
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // ── Section 4: Helper Requirements ────────────
                          _buildSheetSection(
                            icon: Icons.engineering_rounded,
                            iconColor: const Color(0xFF059669),
                            iconBg: const Color(0xFFD1FAE5),
                            title: 'Helper Requirements',
                            subtitle:
                                'Do you need help with loading or unloading?',
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setSheetState(() =>
                                          _loadingRequired = !_loadingRequired),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14, horizontal: 14),
                                        decoration: BoxDecoration(
                                          color: _loadingRequired
                                              ? const Color(0xFFEEF2FF)
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: _loadingRequired
                                                ? const Color(0xFF4F46E5)
                                                : const Color(0xFFE2E8F0),
                                            width: _loadingRequired ? 2.0 : 1.2,
                                          ),
                                          boxShadow: _loadingRequired
                                              ? [
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFF4F46E5)
                                                            .withValues(
                                                                alpha: 0.12),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.upload_rounded,
                                              size: 24,
                                              color: _loadingRequired
                                                  ? const Color(0xFF4F46E5)
                                                  : const Color(0xFFCBD5E1),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Loading',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: _loadingRequired
                                                    ? const Color(0xFF4F46E5)
                                                    : const Color(0xFF94A3B8),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _loadingRequired
                                                  ? 'Required ✓'
                                                  : 'Tap to select',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: _loadingRequired
                                                    ? const Color(0xFF6366F1)
                                                    : const Color(0xFFCBD5E1),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setSheetState(() =>
                                          _unloadingRequired =
                                              !_unloadingRequired),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14, horizontal: 14),
                                        decoration: BoxDecoration(
                                          color: _unloadingRequired
                                              ? const Color(0xFFEEF2FF)
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: _unloadingRequired
                                                ? const Color(0xFF4F46E5)
                                                : const Color(0xFFE2E8F0),
                                            width:
                                                _unloadingRequired ? 2.0 : 1.2,
                                          ),
                                          boxShadow: _unloadingRequired
                                              ? [
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFF4F46E5)
                                                            .withValues(
                                                                alpha: 0.12),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.download_rounded,
                                              size: 24,
                                              color: _unloadingRequired
                                                  ? const Color(0xFF4F46E5)
                                                  : const Color(0xFFCBD5E1),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Unloading',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: _unloadingRequired
                                                    ? const Color(0xFF4F46E5)
                                                    : const Color(0xFF94A3B8),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _unloadingRequired
                                                  ? 'Required ✓'
                                                  : 'Tap to select',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: _unloadingRequired
                                                    ? const Color(0xFF6366F1)
                                                    : const Color(0xFFCBD5E1),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ── Required fields note ────────────────────────
                          const Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 13, color: Color(0xFF94A3B8)),
                              SizedBox(width: 5),
                              Text(
                                '* Required fields must be filled to confirm.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ── Confirm Booking Button ─────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: vm.isCreatingBooking
                                  ? null
                                  : () => _submitBooking(ctx, vm),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(0xFF4F46E5)
                                    .withValues(alpha: 0.45),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: vm.isCreatingBooking
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Confirming...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle_rounded,
                                            size: 22),
                                        SizedBox(width: 10),
                                        Text(
                                          'Confirm Booking',
                                          style: TextStyle(
                                            fontSize: 17,
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
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Strips spaces, dashes, dots and parentheses then checks digit count (7–15).
  bool _isValidPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[\s\-().+]+'), '');
    return digits.length >= 7 &&
        digits.length <= 15 &&
        RegExp(r'^\d+$').hasMatch(digits);
  }

  Future<void> _submitBooking(BuildContext ctx, PorterViewModel vm) async {
    final contactName = _pickupContactCtrl.text.trim();
    final pickupMobile = _pickupMobileCtrl.text.trim();
    final receiverName = _receiverNameCtrl.text.trim();
    final receiverMobile = _receiverMobileCtrl.text.trim();

    // ── Required field check ─────────────────────────────────────────────────
    if (contactName.isEmpty ||
        pickupMobile.isEmpty ||
        receiverName.isEmpty ||
        receiverMobile.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: const Text('Please fill in contact person & mobile fields.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // ── Phone format validation ──────────────────────────────────────────────
    if (!_isValidPhone(pickupMobile)) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: const Text(
              'Pickup mobile number is not valid. Enter 7–15 digits.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    if (!_isValidPhone(receiverMobile)) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: const Text(
              'Receiver mobile number is not valid. Enter 7–15 digits.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Combine dial code + digits → full number for the API
    final fullPickupMobile = _pickupDialCode + pickupMobile.trim();
    final fullReceiverMobile = _receiverDialCode + receiverMobile.trim();

    final result = await vm.createBooking(
      pickupContactPerson: contactName,
      pickupMobile: fullPickupMobile,
      pickupInstructions: _pickupInstructionsCtrl.text.trim(),
      receiverName: receiverName,
      receiverMobile: fullReceiverMobile,
      deliveryInstructions: _deliveryInstructionsCtrl.text.trim(),
      goodsCategory: _itemsCtrl.text.trim(),
      approximateWeight: _weightCtrl.text.trim(),
      numberOfItems: int.tryParse(_itemCountCtrl.text.trim()) ?? 1,
      loadingRequired: _loadingRequired,
      unloadingRequired: _unloadingRequired,
      specialInstructions: _specialInstructionsCtrl.text.trim(),
    );

    if (!mounted) return;

    // Close the bottom sheet
    Navigator.pop(context);

    if (result != null && result.isNotEmpty) {
      // Server may nest booking under 'booking' key
      Map<String, dynamic> bookingData =
          result['booking'] is Map<String, dynamic>
              ? result['booking'] as Map<String, dynamic>
              : result;

      // Ensure estimated_fare and distance_km are always present for the
      // tracking page — fall back to the locally-computed values if the
      // server response omits them.
      final localFare = vm.estimatedFare ??
          (vm.selectedVehicle != null
              ? vm.selectedVehicle!.basePrice +
                  ((vm.distanceKm > 0 ? vm.distanceKm : 5.0) *
                      vm.selectedVehicle!.perKmRate)
              : 350.0);
      if (bookingData['estimated_fare'] == null ||
          bookingData['estimated_fare'] == 0) {
        bookingData = Map<String, dynamic>.from(bookingData)
          ..['estimated_fare'] = localFare;
      }
      if (bookingData['distance_km'] == null ||
          bookingData['distance_km'] == 0) {
        bookingData = Map<String, dynamic>.from(bookingData)
          ..['distance_km'] = vm.distanceKm > 0 ? vm.distanceKm : 5.0;
      }

      // Navigate to TrackPorterView passing booking via route arguments
      Navigator.pushNamed(
        context,
        TrackPorterView.routeName,
        arguments: bookingData,
      );
    } else {
      final errorMsg = vm.bookingError?.isNotEmpty == true
          ? vm.bookingError!
          : 'Booking failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// Wraps a group of fields in a white card with an icon header and subtitle.
  Widget _buildSheetSection({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _sheetSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Color(0xFF334155),
        letterSpacing: -0.1,
      ),
    );
  }

  // ── Phone field with country code picker ───────────────────────────────────

  /// Opens a bottom-sheet country picker and calls [onDialCodeChanged] with
  /// the selected dial code string (e.g. "+91").
  Future<void> _pickCountryCode({
    required BuildContext ctx,
    required String current,
    required ValueChanged<String> onDialCodeChanged,
    required StateSetter setSheetState,
  }) async {
    final searchCtrl = TextEditingController();
    List<Country> filtered = List.from(countries);

    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bsCtx) {
        return StatefulBuilder(
          builder: (bsCtx, setBS) {
            return Container(
              height: MediaQuery.of(bsCtx).size.height * 0.72,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const Text(
                    'Select Country',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded,
                              size: 18, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: searchCtrl,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF0F172A),
                                  height: 1.2),
                              decoration: const InputDecoration(
                                hintText: 'Search country...',
                                hintStyle: TextStyle(
                                    color: Color(0xFFB0BAC8), fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                isCollapsed: true,
                              ),
                              onChanged: (q) {
                                setBS(() {
                                  filtered = countries
                                      .where((c) =>
                                          c.name
                                              .toLowerCase()
                                              .contains(q.toLowerCase()) ||
                                          c.dialCode.contains(q))
                                      .toList();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // List
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        final dialCode = '+${c.dialCode}';
                        final isSelected = dialCode == current;
                        return InkWell(
                          onTap: () {
                            onDialCodeChanged(dialCode);
                            setSheetState(() {});
                            Navigator.pop(bsCtx);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            color: isSelected
                                ? const Color(0xFFEEF2FF)
                                : Colors.transparent,
                            child: Row(
                              children: [
                                Text(
                                  c.flag,
                                  style: const TextStyle(fontSize: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    c.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Text(
                                  dialCode,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? const Color(0xFF4F46E5)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Phone input with a tappable country-code pill + digit TextField.
  Widget _phoneInputField({
    required TextEditingController controller,
    required String label,
    required String dialCode,
    required ValueChanged<String> onDialCodeChanged,
    required StateSetter setSheetState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Country code pill
              GestureDetector(
                onTap: () => _pickCountryCode(
                  ctx: context,
                  current: dialCode,
                  onDialCodeChanged: onDialCodeChanged,
                  setSheetState: setSheetState,
                ),
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dialCode,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4F46E5),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Divider
              Container(width: 1, height: 22, color: const Color(0xFFDDE3ED)),
              const SizedBox(width: 10),
              // Phone number text field
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    height: 1.3,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Phone number',
                    hintStyle: TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFFB0BAC8),
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    isCollapsed: false,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.phone_rounded,
                  size: 17, color: Color(0xFFCBD5E1)),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ],
    );
  }

  /// Modern field used inside sheet sections.
  Widget _modernSheetField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required TextInputType keyboardType,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            if (isOptional) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'optional',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: const Color(0xFF94A3B8)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    height: 1.3,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFFB0BAC8),
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    isCollapsed: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sheetField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required TextInputType keyboardType,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                height: 1.3,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFFB0BAC8),
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                isCollapsed: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomInputField({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required TextEditingController controller,
    bool isReadOnly = false,
    VoidCallback? onTap,
    VoidCallback? onMapTap,
    VoidCallback? onGpsTap,
    bool isGpsLoading = false,
    String? hintText,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
                letterSpacing: -0.1,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onGpsTap != null) ...[
                  GestureDetector(
                    onTap: isGpsLoading ? null : onGpsTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFBBF7D0), width: 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isGpsLoading)
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF16A34A)),
                              ),
                            )
                          else
                            const Icon(Icons.my_location_rounded,
                                size: 12, color: Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          const Text(
                            'Current GPS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (onMapTap != null)
                  GestureDetector(
                    onTap: onMapTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFC7D2FE), width: 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.map_rounded,
                              size: 12, color: Color(0xFF4F46E5)),
                          SizedBox(width: 4),
                          Text(
                            'Map Pin',
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
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Tinted Icon Capsule
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                // Single Borderless Text Field
                Expanded(
                  child: TextField(
                    controller: controller,
                    readOnly: isReadOnly,
                    onTap: onTap,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      filled: false,
                      fillColor: Colors.transparent,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (trailing != null)
                  trailing
                else if (onMapTap != null)
                  IconButton(
                    icon: const Icon(
                      Icons.place_rounded,
                      color: Color(0xFF4F46E5),
                      size: 22,
                    ),
                    onPressed: onMapTap,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Select on Google Map',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapRoutePreview(PorterViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.alt_route_rounded,
                    size: 17, color: Color(0xFF4F46E5)),
                SizedBox(width: 6),
                Text(
                  'Route Map Preview',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
            if (vm.distanceKm > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: const Color(0xFFC7D2FE), width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.route_rounded,
                        size: 13, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 4),
                    Text(
                      '${vm.distanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(
              children: [
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target:
                          LatLng(_pickupLat ?? 9.9816, _pickupLng ?? 76.2763),
                      zoom: 13.0,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _updateRouteAndCamera();
                    },
                    markers: _buildMarkers(),
                    polylines: _buildPolylines(),
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: true,
                    mapToolbarEnabled: false,
                    scrollGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                  ),
                ),

                // Floating Route Legend Badge (Pickup -> Drop)
                Positioned(
                  top: 10,
                  left: 10,
                  right: 60,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
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
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            _pickupCtrl.text.isNotEmpty
                                ? _pickupCtrl.text.split(',').first
                                : 'Pickup',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.0),
                          child: Icon(Icons.arrow_forward_rounded,
                              size: 12, color: Color(0xFF94A3B8)),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            _dropCtrl.text.isNotEmpty
                                ? _dropCtrl.text.split(',').first
                                : 'Drop',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Floating Action Controls on Map (Top-Right Stack)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Column(
                    children: [
                      // Full Map Expansion Button
                      GestureDetector(
                        onTap: () => _openMapPicker(isPickup: false),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4F46E5)
                                    .withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.open_in_full_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // GPS Re-Locate Current Position Button
                      GestureDetector(
                        onTap: () =>
                            _fetchAndSetCurrentLocation(showFeedback: true),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isLoadingLocation
                              ? const Padding(
                                  padding: EdgeInsets.all(9.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF16A34A)),
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location_rounded,
                                  size: 18,
                                  color: Color(0xFF16A34A),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Re-center / Fit Entire Route Button
                      GestureDetector(
                        onTap: _fitRouteCamera,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.fit_screen_rounded,
                            size: 18,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom loading indicator while path is calculating
                if (_isLoadingRoute)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Drawing route path...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
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
      ],
    );
  }
}
