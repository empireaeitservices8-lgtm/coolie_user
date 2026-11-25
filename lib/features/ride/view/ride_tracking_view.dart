import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cooli/features/ride/model/ride_model.dart';
import 'package:cooli/features/ride/view/ride_completed_view.dart';
import 'package:cooli/features/ride/view_model/ride_view_model.dart';
import 'package:cooli/features/ride/widgets/driver_chat_sheet.dart';
import 'package:cooli/features/ride/widgets/ride_map_canvas.dart';
import 'package:cooli/features/ride/widgets/ride_view_model_scope.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';

class RideTrackingView extends StatefulWidget {
  static const String routeName = '/ride-tracking';

  const RideTrackingView({super.key});

  @override
  State<RideTrackingView> createState() => _RideTrackingViewState();
}

class _RideTrackingViewState extends State<RideTrackingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _carAnimController;
  late Animation<double> _carProgress;
  Timer? _autoMatchTimer;
  RideViewModel? _attachedVm;

  @override
  void initState() {
    super.initState();
    _carAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _carProgress = Tween<double>(begin: 0.06, end: 0.94).animate(
      CurvedAnimation(parent: _carAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _autoMatchTimer?.cancel();
    _carAnimController.dispose();
    super.dispose();
  }

  void _ensureLifecycleSetup(RideViewModel vm) {
    if (_attachedVm == vm) return;
    _attachedVm = vm;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (vm.tripStage == RideTripStage.idle ||
          vm.tripStage == RideTripStage.confirmingPickup) {
        vm.assignDriver();
      } else if (vm.tripStage == RideTripStage.searchingDriver) {
        _autoMatchTimer?.cancel();
        _autoMatchTimer = Timer(const Duration(seconds: 2), () {
          if (mounted && vm.tripStage == RideTripStage.searchingDriver) {
            vm.assignDriver();
          }
        });
      }
    });
  }

  void _openSafetyToolkit(BuildContext context, RideViewModel vm) {
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
                  'Safety Toolkit',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: CooliColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: CooliColors.primarySoft,
                    child: Icon(Icons.share_location_rounded, color: CooliColors.primary),
                  ),
                  title: const Text(
                    'Share my trip',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('Share live location to ${vm.dropLocation}'),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Live trip status link copied to share!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: CooliColors.dangerSoft,
                    child: Icon(Icons.emergency_share_rounded, color: CooliColors.danger),
                  ),
                  title: const Text(
                    'Emergency Assistance (112)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: CooliColors.danger,
                    ),
                  ),
                  subtitle: const Text('Connect with safety response team'),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Safety team alerted with your live GPS location.'),
                        backgroundColor: CooliColors.danger,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCancelSheet(BuildContext context, RideViewModel vm) {
    String selectedReason = vm.cancellationReasons.first;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setModalState) {
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
                      'Cancel your ride?',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: CooliColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tell us why you want to cancel',
                      style: TextStyle(fontSize: 13, color: CooliColors.textMuted),
                    ),
                    const SizedBox(height: 10),
                    ...vm.cancellationReasons.map((reason) {
                      final isSelected = reason == selectedReason;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? CooliColors.primary : CooliColors.textLight,
                        ),
                        title: Text(
                          reason,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: CooliColors.textDark,
                          ),
                        ),
                        onTap: () => setModalState(() => selectedReason = reason),
                      );
                    }),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CooliOutlineButton(
                            text: 'Keep Ride',
                            onTap: () => Navigator.pop(sheetCtx),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CooliButton(
                            text: 'Cancel Ride',
                            backgroundColor: CooliColors.danger,
                            onTap: () {
                              _autoMatchTimer?.cancel();
                              vm.cancelRide(selectedReason);
                              Navigator.pop(sheetCtx);
                              Navigator.maybePop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openCallModal(BuildContext context, DriverModel driver) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: const Color(0xFF1E293B),
                  backgroundImage: AssetImage(driver.photoUrl),
                ),
                const SizedBox(height: 14),
                Text(
                  driver.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connecting masked call • ${driver.phone}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 22),
                FloatingActionButton(
                  backgroundColor: CooliColors.danger,
                  onPressed: () => Navigator.pop(sheetCtx),
                  child: const Icon(Icons.call_end_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _stageBadgeText(RideTripStage stage) {
    switch (stage) {
      case RideTripStage.searchingDriver:
        return 'Finding your ride';
      case RideTripStage.driverEnRoute:
        return 'On the way';
      case RideTripStage.driverArrived:
        return 'Driver arrived';
      case RideTripStage.inProgress:
        return 'Trip in progress';
      case RideTripStage.completed:
        return 'Arrived';
      case RideTripStage.cancelled:
        return 'Cancelled';
      default:
        return 'On the way';
    }
  }

  Color _stageBadgeColor(RideTripStage stage) {
    switch (stage) {
      case RideTripStage.searchingDriver:
        return const Color(0xFF4F46E5);
      case RideTripStage.driverEnRoute:
        return const Color(0xFF10B981);
      case RideTripStage.driverArrived:
        return const Color(0xFF0EA5E9);
      case RideTripStage.inProgress:
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RideViewModelScope(
      builder: (context, vm) {
        _ensureLifecycleSetup(vm);
        final stage = vm.tripStage;
        final driver = vm.driver ??
            const DriverModel(
              name: 'Rahul Kumar',
              rating: 4.9,
              totalTrips: 1420,
              vehicleName: 'Toyota Etios',
              vehicleColor: 'White',
              vehicleNumber: 'KL 07 AB 1234',
              arrivingTime: '4 min',
              phone: '+91 98765 43210',
              photoUrl: 'assets/images/ride_driver_avatar.png',
              otpPin: '4219',
            );
        final isSearching = stage == RideTripStage.searchingDriver;
        final badgeColor = _stageBadgeColor(stage);

        return Scaffold(
          backgroundColor: const Color(0xFF090F1D),
          body: Column(
            children: [
              // 1. TOP HALF: Dark Navigation Map
              Expanded(
                flex: 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedBuilder(
                      animation: _carProgress,
                      builder: (context, _) {
                        double carPosProgress = _carProgress.value;
                        if (stage == RideTripStage.driverArrived) {
                          carPosProgress = 0.05;
                        } else if (stage == RideTripStage.driverEnRoute) {
                          carPosProgress = 1.0 - (_carProgress.value * 0.75);
                        }
                        return RideMapCanvas(
                          style: RideMapStyle.dark,
                          pickupNormalized: vm.pickupPlace.mapNormalizedPos,
                          dropNormalized:
                              vm.dropPlace?.mapNormalizedPos ?? const Offset(0.78, 0.22),
                          pickupLabel: vm.pickupLocation,
                          dropLabel: vm.dropLocation,
                          showRoute: true,
                          showDropPin: true,
                          isSearchingRadar: isSearching,
                          showMovingVehicle: !isSearching,
                          showNearbyCars: isSearching,
                          animationProgress: carPosProgress,
                          routePillText: stage == RideTripStage.inProgress
                              ? '${vm.routeDurationMinutes} min to dropoff'
                              : null,
                        );
                      },
                    ),

                    // Top Floating Controls
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _DarkCircleButton(
                                icon: Icons.arrow_back_rounded,
                                onTap: () => Navigator.maybePop(context),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: badgeColor, width: 1.4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: badgeColor.withValues(alpha: 0.35),
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
                                      decoration: BoxDecoration(
                                        color: badgeColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _stageBadgeText(stage),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _DarkCircleButton(
                                icon: Icons.shield_outlined,
                                onTap: () => _openSafetyToolkit(context, vm),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. BOTTOM HALF: Stage-Driven Driver & Trip Sheet
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 24,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                    child: isSearching
                        ? _buildSearchingCard(context, vm)
                        : _buildActiveTripCard(context, vm, driver, stage),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchingCard(BuildContext context, RideViewModel vm) {
    final option = vm.selectedOption;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Finding your ${option?.name ?? 'ride'}...',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: CooliColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Connecting with nearby drivers around ${vm.pickupLocation}',
          style: const TextStyle(fontSize: 13, color: CooliColors.textMuted),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: const LinearProgressIndicator(
            minHeight: 6,
            backgroundColor: CooliColors.primarySoft,
            color: CooliColors.primary,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CooliColors.border),
          ),
          child: Row(
            children: [
              if (option != null)
                Image.asset(
                  option.imagePath,
                  width: 50,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      Icon(option.icon, color: CooliColors.primary),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vm.pickupLocation} → ${vm.dropLocation}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: CooliColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${vm.selectedFare.toStringAsFixed(0)} • ${vm.selectedPaymentMethod.title}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CooliColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CooliButton(
          text: 'Match Driver Now',
          onTap: () {
            _autoMatchTimer?.cancel();
            vm.assignDriver();
          },
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: () {
              _autoMatchTimer?.cancel();
              vm.cancelRide('Cancelled while searching');
              Navigator.maybePop(context);
            },
            child: const Text(
              'Cancel Request',
              style: TextStyle(
                color: CooliColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTripCard(
    BuildContext context,
    RideViewModel vm,
    DriverModel driver,
    RideTripStage stage,
  ) {
    final isInProgress = stage == RideTripStage.inProgress;
    final isArrived = stage == RideTripStage.driverArrived;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),

        // Uber-style Headline Banner + PIN Display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isInProgress
                        ? 'Heading to ${vm.dropLocation}'
                        : isArrived
                            ? '${driver.name.split(' ').first} is at pickup'
                            : 'Meet at ${vm.pickupLocation}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: CooliColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isInProgress
                        ? '${vm.routeDurationMinutes} min • ${vm.routeDistanceKm.toStringAsFixed(1)} km remaining'
                        : isArrived
                            ? 'Share your PIN to start the ride'
                            : 'Arriving in ${driver.arrivingTime}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isArrived ? CooliColors.info : CooliColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (!isInProgress)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: CooliColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CooliColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'PIN',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: CooliColors.primary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      driver.otpPin,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: CooliColors.textDark,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 14),

        // Driver + Vehicle Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CooliColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: CooliColors.border, width: 1.5),
                ),
                child: ClipOval(
                  child: Image.asset(
                    driver.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      size: 28,
                      color: CooliColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          driver.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: CooliColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.star_rounded,
                            color: CooliColors.warning, size: 16),
                        Text(
                          '${driver.rating}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: CooliColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${driver.vehicleColor} ${driver.vehicleName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CooliColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: CooliColors.border),
                      ),
                      child: Text(
                        driver.vehicleNumber,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: CooliColors.textDark,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${vm.selectedFare.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: CooliColors.textDark,
                    ),
                  ),
                  Text(
                    vm.selectedPaymentMethod.title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CooliColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 3 Uber Action Buttons: Call, Message, Share
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.phone_rounded,
                label: 'Call',
                onTap: () => _openCallModal(context, driver),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Message',
                isHighlighted: true,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => DriverChatSheet(viewModel: vm),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                icon: Icons.share_location_rounded,
                label: 'Share Trip',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Live trip status shared!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Primary Stage Transition Button
        CooliButton(
          text: isInProgress
              ? 'Complete Ride'
              : isArrived
                  ? 'Start Trip (Verify PIN ${driver.otpPin})'
                  : 'Simulate Driver Arrived',
          showForwardArrow: isInProgress,
          onTap: () {
            if (stage == RideTripStage.driverEnRoute) {
              vm.markDriverArrived();
            } else if (stage == RideTripStage.driverArrived) {
              vm.startTrip();
            } else {
              vm.completeTrip();
              Navigator.pushReplacementNamed(
                context,
                RideCompletedView.routeName,
              );
            }
          },
        ),

        if (!isInProgress) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => _openCancelSheet(context, vm),
            child: const Text(
              'Cancel Ride',
              style: TextStyle(
                color: CooliColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DarkCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _DarkCircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isHighlighted;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isHighlighted ? CooliColors.primarySoft : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isHighlighted
                ? CooliColors.primary.withValues(alpha: 0.25)
                : CooliColors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19,
              color: isHighlighted ? CooliColors.primary : const Color(0xFF475569),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
                color: isHighlighted ? CooliColors.primaryDark : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
