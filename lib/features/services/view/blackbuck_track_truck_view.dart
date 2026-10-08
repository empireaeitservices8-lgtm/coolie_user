import 'package:flutter/material.dart';
import 'package:cooli/features/services/view/blackbuck_delivery_completed_view.dart';

class BlackbuckTrackTruckView extends StatefulWidget {
  static const String routeName = '/blackbuck-track-truck';

  final String bookingId;
  final String truckNumber;
  final String driverName;
  final String driverPhone;
  final String truckType;
  final String eta;

  const BlackbuckTrackTruckView({
    super.key,
    this.bookingId = 'CL-2025-0422-0018',
    this.truckNumber = 'TN 11 AB 4321',
    this.driverName = 'Ramesh Kumar',
    this.driverPhone = '+91 98765 43210',
    this.truckType = 'Open Body • 15T',
    this.eta = '3h 10m',
  });

  @override
  State<BlackbuckTrackTruckView> createState() => _BlackbuckTrackTruckViewState();
}

class _BlackbuckTrackTruckViewState extends State<BlackbuckTrackTruckView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _callDriver() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${widget.driverName} (${widget.driverPhone})...'),
        backgroundColor: const Color(0xFF4F46E5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _proceedToDeliveryCompleted() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlackbuckDeliveryCompletedView(
          bookingId: widget.bookingId,
          truckNumber: widget.truckNumber,
          driverName: widget.driverName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 24),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Track Truck',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Driver & Truck Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Truck Thumbnail
                          Container(
                            width: 60,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Image.asset(
                              'assets/images/splash_truck_clean.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/dash_blackbuck_clean.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Truck specs & Driver
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.truckNumber,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.truckType,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.person_pin, size: 14, color: Color(0xFF4F46E5)),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.driverName,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.driverPhone,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Call Button
                          GestureDetector(
                            onTap: _callDriver,
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE0E7FF)),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.call_rounded,
                                  color: Color(0xFF4F46E5),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Map Section
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          children: [
                            // Vector Map Background
                            CustomPaint(
                              size: const Size(double.infinity, 220),
                              painter: _TrackMapPainter(),
                            ),

                            // Pickup Marker (Kochi)
                            Positioned(
                              left: 36,
                              bottom: 30,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Column(
                                      children: [
                                        Text('Pickup', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                                        Text('Kochi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF16A34A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.location_on, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Drop Marker (Calicut)
                            Positioned(
                              right: 40,
                              top: 24,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Column(
                                      children: [
                                        Text('Drop', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                                        Text('Calicut', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFDC2626),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.pin_drop, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Moving Live Truck Marker
                            Positioned(
                              left: 140,
                              top: 80,
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) => Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3852E8),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF3852E8).withValues(
                                          alpha: 0.3 + (_pulseController.value * 0.25),
                                        ),
                                        blurRadius: 12 + (_pulseController.value * 6),
                                        spreadRadius: 2 + (_pulseController.value * 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.local_shipping_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ETA & Status Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ETA & Current Status Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ETA',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.eta,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: const [
                                  Text(
                                    'Current Status',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'In Transit',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFF1F5F9), height: 1),
                          const SizedBox(height: 16),

                          // Timeline Steps
                          _buildTimelineStep(
                            isCompleted: true,
                            isCurrent: false,
                            isLast: false,
                            title: 'Driver Assigned',
                            time: '10:15 AM',
                          ),
                          _buildTimelineStep(
                            isCompleted: true,
                            isCurrent: false,
                            isLast: false,
                            title: 'Truck Arriving',
                            time: '11:30 AM',
                          ),
                          _buildTimelineStep(
                            isCompleted: true,
                            isCurrent: false,
                            isLast: false,
                            title: 'Picked Up',
                            time: '12:15 PM',
                          ),
                          _buildTimelineStep(
                            isCompleted: false,
                            isCurrent: true,
                            isLast: false,
                            title: 'In Transit',
                            time: 'ETA 3:10 PM',
                          ),
                          _buildTimelineStep(
                            isCompleted: false,
                            isCurrent: false,
                            isLast: true,
                            title: 'Delivered',
                            time: '',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Action to Proceed to Delivery Completed
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _proceedToDeliveryCompleted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'View Delivery Completed Screen',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 19),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
    required String title,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicator column with vertical line
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF10B981)
                    : isCurrent
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFFCBD5E1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                    : isCurrent
                        ? const Icon(Icons.circle, color: Colors.white, size: 10)
                        : const Icon(Icons.circle_outlined, color: Colors.white, size: 10),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
              ),
          ],
        ),
        const SizedBox(width: 14),
        // Step details
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: isCurrent
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                : EdgeInsets.zero,
            decoration: isCurrent
                ? BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCurrent || isCompleted ? FontWeight.w800 : FontWeight.w500,
                    color: isCurrent
                        ? const Color(0xFF4F46E5)
                        : isCompleted
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF94A3B8),
                  ),
                ),
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: isCurrent ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
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

/// Vector painter for the live road map visualization
class _TrackMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background terrain
    final bgPaint = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Green parks
    final parkPaint = Paint()..color = const Color(0xFFDCFCE7).withValues(alpha: 0.6);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(20, 20, 80, 50), const Radius.circular(16)), parkPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w - 120, h - 80, 90, 60), const Radius.circular(16)), parkPaint);

    // Minor roads
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, h * 0.4), Offset(w, h * 0.35), roadPaint);
    canvas.drawLine(Offset(w * 0.3, 0), Offset(w * 0.35, h), roadPaint);
    canvas.drawLine(Offset(w * 0.7, 0), Offset(w * 0.65, h), roadPaint);
    canvas.drawLine(Offset(0, h * 0.75), Offset(w, h * 0.8), roadPaint);

    // Main Delivery Route Polyline
    final routePaint = Paint()
      ..color = const Color(0xFF3852E8)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final routePath = Path()
      ..moveTo(48, h - 40)
      ..lineTo(70, h - 70)
      ..lineTo(140, h * 0.55)
      ..lineTo(165, h * 0.45)
      ..lineTo(210, h * 0.35)
      ..lineTo(w - 52, 45);

    canvas.drawPath(routePath, routePaint);

    // Route waypoint dots
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(70, h - 70), 3.5, dotPaint);
    canvas.drawCircle(Offset(210, h * 0.35), 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
