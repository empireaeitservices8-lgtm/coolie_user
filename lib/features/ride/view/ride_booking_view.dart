import 'package:flutter/material.dart';
import 'package:cooli/features/ride/model/ride_model.dart';
import 'package:cooli/features/ride/view/ride_selection_view.dart';
import 'package:cooli/features/ride/view_model/ride_view_model.dart';
import 'package:cooli/features/ride/widgets/plan_ride_sheet.dart';
import 'package:cooli/features/ride/widgets/ride_map_canvas.dart';
import 'package:cooli/features/ride/widgets/ride_view_model_scope.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';

class RideBookingView extends StatefulWidget {
  static const String routeName = '/ride-booking';

  const RideBookingView({super.key});

  @override
  State<RideBookingView> createState() => _RideBookingViewState();
}

class _RideBookingViewState extends State<RideBookingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ambientCarsController;
  bool _isPinSelectionMode = false;
  Offset _customPinNormalized = const Offset(0.72, 0.34);

  @override
  void initState() {
    super.initState();
    _ambientCarsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientCarsController.dispose();
    super.dispose();
  }

  void _openPlanRideSheet(
    BuildContext context,
    RideViewModel vm, {
    PlanRideField initialFocus = PlanRideField.drop,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlanRideSheet(
        viewModel: vm,
        initialFocus: initialFocus,
        onSetOnMap: () {
          setState(() => _isPinSelectionMode = true);
        },
        onRouteReady: () {
          if (!mounted) return;
          Navigator.pushNamed(context, RideSelectionView.routeName);
        },
      ),
    );
  }

  void _openScheduleSheet(BuildContext context, RideViewModel vm) {
    final slots = [
      'Today, 5:30 PM',
      'Today, 7:00 PM',
      'Tomorrow, 8:30 AM',
      'Tomorrow, 10:00 AM',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'When do you want to be picked up?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: CooliColors.textDark,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: CooliColors.primarySoft,
                    child: Icon(Icons.flash_on_rounded, color: CooliColors.primary),
                  ),
                  title: const Text(
                    'Pickup Now',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Get picked up in a few minutes'),
                  trailing: vm.scheduleType == RideScheduleType.now
                      ? const Icon(Icons.check_circle_rounded, color: CooliColors.primary)
                      : null,
                  onTap: () {
                    vm.setSchedule(RideScheduleType.now);
                    Navigator.pop(sheetCtx);
                  },
                ),
                const Divider(height: 16),
                const Text(
                  'Or reserve for later',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CooliColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: slots.map((slot) {
                    final selected = vm.scheduleType == RideScheduleType.later &&
                        vm.scheduledTimeLabel == slot;
                    return ChoiceChip(
                      label: Text(slot),
                      selected: selected,
                      selectedColor: CooliColors.primarySoft,
                      labelStyle: TextStyle(
                        color: selected ? CooliColors.primary : CooliColors.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      onSelected: (_) {
                        vm.setSchedule(RideScheduleType.later, timeLabel: slot);
                        Navigator.pop(sheetCtx);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectQuickPlace(BuildContext context, RideViewModel vm, RidePlace place) {
    vm.setDropPlace(place);
    Navigator.pushNamed(context, RideSelectionView.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return RideViewModelScope(
      builder: (context, vm) {
        final quickPlaces = vm.places.take(3).toList();
        final recentPlaces = vm.places.skip(2).take(3).toList();

        return Scaffold(
          backgroundColor: CooliColors.background,
          body: Column(
            children: [
              // 1. TOP MAP AREA (Uber Style Full-Bleed Map)
              Expanded(
                flex: 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LayoutBuilder(
                      builder: (mapContext, constraints) {
                        return GestureDetector(
                          onTapDown: _isPinSelectionMode
                              ? (details) {
                                  if (constraints.maxWidth > 0 &&
                                      constraints.maxHeight > 0) {
                                    final dx = (details.localPosition.dx /
                                            constraints.maxWidth)
                                        .clamp(0.15, 0.85);
                                    final dy = (details.localPosition.dy /
                                            constraints.maxHeight)
                                        .clamp(0.15, 0.78);
                                    setState(() {
                                      _customPinNormalized = Offset(dx, dy);
                                    });
                                  }
                                }
                              : null,
                          child: AnimatedBuilder(
                            animation: _ambientCarsController,
                            builder: (context, _) {
                              return RideMapCanvas(
                                style: RideMapStyle.light,
                                pickupNormalized: vm.pickupPlace.mapNormalizedPos,
                                dropNormalized: _isPinSelectionMode
                                    ? _customPinNormalized
                                    : (vm.dropPlace?.mapNormalizedPos ??
                                        const Offset(0.76, 0.26)),
                                pickupLabel: vm.pickupLocation,
                                dropLabel: _isPinSelectionMode
                                    ? 'Dropped Pin'
                                    : (vm.hasDestination ? vm.dropLocation : null),
                                showRoute: vm.hasDestination || _isPinSelectionMode,
                                showDropPin:
                                    vm.hasDestination || _isPinSelectionMode,
                                showNearbyCars: true,
                                animationProgress: _ambientCarsController.value,
                                routePillText:
                                    vm.hasDestination && !_isPinSelectionMode
                                        ? '${vm.routeDurationMinutes} min • ${vm.routeDistanceKm.toStringAsFixed(1)} km'
                                        : null,
                                onPickupPinTap: () => _openPlanRideSheet(
                                  context,
                                  vm,
                                  initialFocus: PlanRideField.pickup,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),

                    // Top Floating Header Bar
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              _CircleMapButton(
                                icon: Icons.arrow_back_rounded,
                                onTap: () => Navigator.maybePop(context),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _openPlanRideSheet(
                                    context,
                                    vm,
                                    initialFocus: PlanRideField.pickup,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: CooliShadows.soft,
                                      border: Border.all(color: CooliColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'From ${vm.pickupLocation}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: CooliColors.textDark,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.edit_location_alt_outlined,
                                          size: 16,
                                          color: CooliColors.primary,
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
                    ),

                    // Recenter GPS Button
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: _CircleMapButton(
                        icon: Icons.my_location_rounded,
                        iconColor: CooliColors.primary,
                        onTap: () {
                          vm.setPickup('Current Location');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Centered on Current Location'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 2. BOTTOM SHEET: Either "Set on map" confirmation OR Uber "Where to?" sheet
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: _isPinSelectionMode
                      ? _buildPinConfirmSheet(context, vm)
                      : _buildWhereToSheet(context, vm, quickPlaces, recentPlaces),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPinConfirmSheet(BuildContext context, RideViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Set destination on map',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: CooliColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap anywhere on the map to move the destination pin',
            style: TextStyle(fontSize: 13, color: CooliColors.textMuted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CooliOutlineButton(
                  text: 'Cancel',
                  onTap: () => setState(() => _isPinSelectionMode = false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: CooliButton(
                  text: 'Confirm Pin',
                  onTap: () {
                    vm.setDropPlace(
                      RidePlace(
                        id: 'pinned_loc',
                        title: 'Pinned Destination',
                        address: 'Selected Map Point, Kochi',
                        tag: 'Pinned',
                        distanceKm: 10.6,
                        etaMinutes: 22,
                        icon: Icons.location_on_rounded,
                        mapNormalizedPos: _customPinNormalized,
                      ),
                    );
                    setState(() => _isPinSelectionMode = false);
                    Navigator.pushNamed(context, RideSelectionView.routeName);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhereToSheet(
    BuildContext context,
    RideViewModel vm,
    List<RidePlace> quickPlaces,
    List<RidePlace> recentPlaces,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Uber "Where to?" Search Pill + "Now ▾" Scheduler
          GestureDetector(
            key: const Key('ride_where_to_bar'),
            onTap: () => _openPlanRideSheet(context, vm, initialFocus: PlanRideField.drop),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: CooliColors.textDark, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      vm.hasDestination ? vm.dropLocation : 'Where to?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: vm.hasDestination
                            ? CooliColors.textDark
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openScheduleSheet(context, vm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: CooliShadows.soft,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_filled_rounded,
                            size: 14,
                            color: CooliColors.textDark,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            vm.scheduleType == RideScheduleType.now ? 'Now' : 'Later',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: CooliColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: CooliColors.textDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Saved Shortcut Chips (Home, Work, Airport)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: quickPlaces.map((place) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(place.icon, size: 16, color: CooliColors.primary),
                    label: Text(
                      place.tag == 'Airport' ? 'Airport' : place.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CooliColors.textDark,
                      ),
                    ),
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: const BorderSide(color: CooliColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onPressed: () => _selectQuickPlace(context, vm, place),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // Recent & Suggested Destinations
          ...recentPlaces.take(2).map((place) {
            return InkWell(
              onTap: () => _selectQuickPlace(context, vm, place),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(place.icon, size: 18, color: CooliColors.textDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: CooliColors.textDark,
                            ),
                          ),
                          Text(
                            place.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: CooliColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: CooliColors.textLight,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          // Continue CTA
          CooliButton(
            text: vm.hasDestination
                ? 'Choose Ride to ${vm.dropLocation.split(' ').first}'
                : 'Search Ride',
            showForwardArrow: true,
            onTap: () {
              if (!vm.hasDestination) {
                _openPlanRideSheet(context, vm, initialFocus: PlanRideField.drop);
                return;
              }
              Navigator.pushNamed(context, RideSelectionView.routeName);
            },
          ),
        ],
      ),
    );
  }
}

class _CircleMapButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _CircleMapButton({
    required this.icon,
    this.iconColor = CooliColors.textDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}
