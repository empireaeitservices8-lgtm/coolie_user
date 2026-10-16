import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cooli/features/ride/model/ride_model.dart';
import 'package:cooli/features/ride/view/ride_tracking_view.dart';

class RideSearchingDriverView extends StatefulWidget {
  static const String routeName = '/ride-searching-driver';

  final RideOption? selectedOption;
  final String? pickupLocation;
  final String? dropLocation;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;
  final double? fare;
  final RideBookingData? bookingData;
  final int? bookingId;
  final String? paymentMethod;

  const RideSearchingDriverView({
    super.key,
    this.selectedOption,
    this.pickupLocation,
    this.dropLocation,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.fare,
    this.bookingData,
    this.bookingId,
    this.paymentMethod,
  });

  @override
  State<RideSearchingDriverView> createState() => _RideSearchingDriverViewState();
}

class _RideSearchingDriverViewState extends State<RideSearchingDriverView>
    with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _pulseController;
  late AnimationController _carFloatController;

  late Animation<double> _carFloat;
  Timer? _stepTimer1;
  Timer? _stepTimer2;
  Timer? _completeTimer;

  int _searchStep = 1;
  String _statusText = 'Connecting to nearby drivers...';
  String _statusSubtext = 'Scanning radius within 3 km for available cabs';

  @override
  void initState() {
    super.initState();

    // Radar rotation and wave ripples
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // Pulse controller for central glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Car idle floating bounce
    _carFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _carFloat = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _carFloatController, curve: Curves.easeInOutSine),
    );

    // Step-by-step search progression simulation
    _stepTimer1 = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _searchStep = 2;
          final vehicleName = widget.selectedOption?.name ?? 'Cab';
          _statusText = 'Request sent to 4 nearby $vehicleName drivers...';
          _statusSubtext = 'Waiting for driver confirmation';
        });
      }
    });

    _stepTimer2 = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        setState(() {
          _searchStep = 3;
          _statusText = 'Driver matched! Confirming your trip...';
          _statusSubtext = 'Rahul Kumar accepted your booking';
        });
      }
    });

    _completeTimer = Timer(const Duration(milliseconds: 3800), () {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          RideTrackingView.routeName,
          arguments: {
            'pickup': widget.pickupLocation,
            'drop': widget.dropLocation,
            'pickupLat': widget.pickupLat,
            'pickupLng': widget.pickupLng,
            'dropLat': widget.dropLat,
            'dropLng': widget.dropLng,
            'fare': widget.fare,
            'selectedOption': widget.selectedOption,
            'bookingId': widget.bookingId ?? widget.bookingData?.id,
            'bookingData': widget.bookingData,
            'paymentMethod': widget.paymentMethod ?? 'Cash',
          },
        );
      }
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pulseController.dispose();
    _carFloatController.dispose();
    _stepTimer1?.cancel();
    _stepTimer2?.cancel();
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleName = widget.selectedOption?.name ?? 'Uber Go';
    final fareText = widget.fare != null
        ? '₹${widget.fare!.toStringAsFixed(0)}'
        : (widget.selectedOption != null ? '₹${widget.selectedOption!.fare.toStringAsFixed(0)}' : '₹220');
    final pickup = widget.pickupLocation ?? 'Current Location (MG Road)';
    final drop = widget.dropLocation ?? 'Cochin International Airport';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D), // Premium dark theme map background
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar with Cancel and Close
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1.2),
                      ),
                      child: const Center(
                        child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF38BDF8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          (widget.bookingId != null || widget.bookingData?.id != null)
                              ? 'Booking #${widget.bookingId ?? widget.bookingData?.id} • Searching'
                              : 'Searching Drivers',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Center Radar Animation with Floating 3D Car
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Animated Radar Circles & Wave Ripples
                    AnimatedBuilder(
                      animation: _radarController,
                      builder: (context, _) {
                        return CustomPaint(
                          size: const Size(320, 320),
                          painter: _RadarWavePainter(
                            animationValue: _radarController.value,
                            pulseValue: _pulseController.value,
                          ),
                        );
                      },
                    ),

                    // Central Glowing Hub with 3D Car
                    AnimatedBuilder(
                      animation: _carFloat,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _carFloat.value),
                        child: child,
                      ),
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
                          ),
                          border: Border.all(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.8),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Image.asset(
                              'assets/images/dash_ride_car_clean.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.directions_car_filled_rounded,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Live Status Texts & Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    _statusText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _statusSubtext,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Linear Step Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 5,
                      child: LinearProgressIndicator(
                        value: _searchStep == 1 ? 0.35 : (_searchStep == 2 ? 0.75 : 1.0),
                        backgroundColor: const Color(0xFF1E293B),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bottom Trip Details Card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF131D33),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF1E2C4A)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Vehicle Name & Fare Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.directions_car_filled_rounded,
                              color: Color(0xFF38BDF8),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicleName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                'AC Cab • Best Fare Guaranteed',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            fareText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (widget.paymentMethod == 'Coolie Wallet')
                                  ? Colors.purple.withValues(alpha: 0.25)
                                  : (widget.paymentMethod == 'UPI'
                                      ? const Color(0xFF2563EB).withValues(alpha: 0.25)
                                      : const Color(0xFF16A34A).withValues(alpha: 0.25)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.paymentMethod ?? 'Cash',
                              style: TextStyle(
                                color: (widget.paymentMethod == 'Coolie Wallet')
                                    ? const Color(0xFFD8B4FE)
                                    : (widget.paymentMethod == 'UPI'
                                        ? const Color(0xFF93C5FD)
                                        : const Color(0xFF86EFAC)),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Color(0xFF1E2C4A), height: 1),
                  ),

                  // From / To Locations
                  Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF38BDF8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 24,
                            color: const Color(0xFF1E2C4A),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pickup,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              drop,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Cancel Search Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.maybePop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF87171),
                        side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Cancel Search',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
}

class _RadarWavePainter extends CustomPainter {
  final double animationValue;
  final double pulseValue;

  _RadarWavePainter({
    required this.animationValue,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw 3 expanding concentric radar wave rings
    for (int i = 0; i < 3; i++) {
      final waveProgress = (animationValue + (i / 3.0)) % 1.0;
      final waveRadius = 60.0 + (maxRadius - 60.0) * waveProgress;
      final waveOpacity = (1.0 - waveProgress).clamp(0.0, 1.0);

      final wavePaint = Paint()
        ..color = const Color(0xFF6366F1).withValues(alpha: waveOpacity * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, waveRadius, wavePaint);
    }

    // Static radar grid rings
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2C4A).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, 90, gridPaint);
    canvas.drawCircle(center, 130, gridPaint);

    // Nearby driver dots on radar
    final dotPositions = [
      Offset(center.dx - 80, center.dy - 60),
      Offset(center.dx + 90, center.dy - 40),
      Offset(center.dx - 70, center.dy + 75),
      Offset(center.dx + 75, center.dy + 65),
    ];

    final dotPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.fill;

    final dotGlow = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.3 + 0.3 * pulseValue)
      ..style = PaintingStyle.fill;

    for (final pos in dotPositions) {
      canvas.drawCircle(pos, 8 + 3 * pulseValue, dotGlow);
      canvas.drawCircle(pos, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarWavePainter oldDelegate) => true;
}
