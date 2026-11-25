import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cooli/utils/cooli_theme.dart';

enum RideMapStyle { light, dark }

/// Shared Uber-inspired interactive vector map canvas supporting light/dark themes,
/// animated vehicle movement, pickup/drop route lines, and radar search pulses.
class RideMapCanvas extends StatelessWidget {
  final RideMapStyle style;
  final Offset pickupNormalized;
  final Offset dropNormalized;
  final String? pickupLabel;
  final String? dropLabel;
  final bool showRoute;
  final bool showDropPin;
  final bool isSearchingRadar;
  final bool showMovingVehicle;
  final double animationProgress;
  final String? routePillText;
  final bool showNearbyCars;
  final VoidCallback? onPickupPinTap;

  const RideMapCanvas({
    super.key,
    this.style = RideMapStyle.light,
    this.pickupNormalized = const Offset(0.24, 0.68),
    this.dropNormalized = const Offset(0.76, 0.24),
    this.pickupLabel,
    this.dropLabel,
    this.showRoute = true,
    this.showDropPin = true,
    this.isSearchingRadar = false,
    this.showMovingVehicle = false,
    this.animationProgress = 0.45,
    this.routePillText,
    this.showNearbyCars = true,
    this.onPickupPinTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final pickupPos = Offset(width * pickupNormalized.dx, height * pickupNormalized.dy);
        final dropPos = Offset(width * dropNormalized.dx, height * dropNormalized.dy);
        final midPoint = Offset(
          (pickupPos.dx + dropPos.dx) * 0.5,
          (pickupPos.dy + dropPos.dy) * 0.5 - 24,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _UberVectorMapPainter(
                style: style,
                pickupNormalized: pickupNormalized,
                dropNormalized: dropNormalized,
                showRoute: showRoute,
                isSearchingRadar: isSearchingRadar,
                showMovingVehicle: showMovingVehicle,
                progress: animationProgress,
                showNearbyCars: showNearbyCars,
              ),
            ),

            // Pickup Label Pin
            if (pickupLabel != null && width > 80 && height > 80)
              Positioned(
                left: (pickupPos.dx - 70).clamp(12.0, math.max(12.0, width - 156)),
                top: (pickupPos.dy - 52).clamp(12.0, math.max(12.0, height - 60)),
                child: GestureDetector(
                  onTap: onPickupPinTap,
                  child: _MapLabelChip(
                    label: pickupLabel!,
                    dotColor: const Color(0xFF2563EB),
                    isSquare: false,
                    isDark: style == RideMapStyle.dark,
                  ),
                ),
              ),

            // Drop Label Pin
            if (showDropPin && dropLabel != null && width > 80 && height > 80)
              Positioned(
                left: (dropPos.dx - 70).clamp(12.0, math.max(12.0, width - 160)),
                top: (dropPos.dy - 52).clamp(12.0, math.max(12.0, height - 60)),
                child: _MapLabelChip(
                  label: dropLabel!,
                  dotColor: const Color(0xFF0F172A),
                  isSquare: true,
                  isDark: style == RideMapStyle.dark,
                ),
              ),

            // Route ETA / Distance Floating Tag
            if (showRoute && routePillText != null && width > 120 && height > 120)
              Positioned(
                left: (midPoint.dx - 55).clamp(16.0, math.max(16.0, width - 140)),
                top: (midPoint.dy - 14).clamp(16.0, math.max(16.0, height - 48)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: style == RideMapStyle.dark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: style == RideMapStyle.dark
                          ? Colors.white24
                          : Colors.white,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    routePillText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MapLabelChip extends StatelessWidget {
  final String label;
  final Color dotColor;
  final bool isSquare;
  final bool isDark;

  const _MapLabelChip({
    required this.label,
    required this.dotColor,
    required this.isSquare,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white24 : CooliColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 10,
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
              color: isDark && isSquare ? const Color(0xFF38BDF8) : dotColor,
              shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: isSquare ? BorderRadius.circular(2) : null,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : CooliColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UberVectorMapPainter extends CustomPainter {
  final RideMapStyle style;
  final Offset pickupNormalized;
  final Offset dropNormalized;
  final bool showRoute;
  final bool isSearchingRadar;
  final bool showMovingVehicle;
  final double progress;
  final bool showNearbyCars;

  _UberVectorMapPainter({
    required this.style,
    required this.pickupNormalized,
    required this.dropNormalized,
    required this.showRoute,
    required this.isSearchingRadar,
    required this.showMovingVehicle,
    required this.progress,
    required this.showNearbyCars,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final isDark = style == RideMapStyle.dark;

    // 1. Base Canvas
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = isDark ? const Color(0xFF0D1424) : const Color(0xFFEEF2F7),
    );

    // 2. Subtle Park & Water Zones
    final parkPaint = Paint()
      ..color = isDark ? const Color(0xFF10242A) : const Color(0xFFDCF2E7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.04, size.height * 0.14, size.width * 0.25, size.height * 0.18),
        const Radius.circular(18),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.66, size.height * 0.56, size.width * 0.28, size.height * 0.22),
        const Radius.circular(20),
      ),
      parkPaint,
    );

    // 3. City Blocks
    final blockPaint = Paint()
      ..color = isDark ? const Color(0xFF131D33) : const Color(0xFFE3E9F2);
    final blockBorder = Paint()
      ..color = isDark ? const Color(0xFF1E2C4A) : const Color(0xFFD5DEE9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final blocks = [
      Rect.fromLTWH(size.width * 0.34, size.height * 0.08, size.width * 0.24, size.height * 0.20),
      Rect.fromLTWH(size.width * 0.08, size.height * 0.42, size.width * 0.28, size.height * 0.22),
      Rect.fromLTWH(size.width * 0.44, size.height * 0.40, size.width * 0.20, size.height * 0.24),
      Rect.fromLTWH(size.width * 0.68, size.height * 0.12, size.width * 0.25, size.height * 0.26),
    ];

    for (final b in blocks) {
      final rrect = RRect.fromRectAndRadius(b, const Radius.circular(10));
      canvas.drawRRect(rrect, blockPaint);
      canvas.drawRRect(rrect, blockBorder);
    }

    // 4. Road Network
    final majorRoad = Paint()
      ..color = isDark ? const Color(0xFF1A2742) : Colors.white
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final minorRoad = Paint()
      ..color = isDark ? const Color(0xFF152038) : Colors.white.withValues(alpha: 0.78)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadsMajor = [
      Path()
        ..moveTo(0, size.height * 0.35)
        ..quadraticBezierTo(size.width * 0.45, size.height * 0.30, size.width, size.height * 0.38),
      Path()
        ..moveTo(size.width * 0.38, 0)
        ..lineTo(size.width * 0.42, size.height),
      Path()
        ..moveTo(0, size.height * 0.72)
        ..lineTo(size.width, size.height * 0.66),
    ];

    final roadsMinor = [
      Path()
        ..moveTo(size.width * 0.65, 0)
        ..lineTo(size.width * 0.62, size.height),
      Path()
        ..moveTo(0, size.height * 0.14)
        ..lineTo(size.width, size.height * 0.16),
      Path()
        ..moveTo(size.width * 0.16, 0)
        ..lineTo(size.width * 0.14, size.height),
    ];

    for (final r in roadsMinor) {
      canvas.drawPath(r, minorRoad);
    }
    for (final r in roadsMajor) {
      canvas.drawPath(r, majorRoad);
    }

    final pickupPos = Offset(size.width * pickupNormalized.dx, size.height * pickupNormalized.dy);
    final dropPos = Offset(size.width * dropNormalized.dx, size.height * dropNormalized.dy);

    // 5. Route Polyline
    final routePath = Path();
    routePath.moveTo(pickupPos.dx, pickupPos.dy);
    routePath.cubicTo(
      pickupPos.dx + (dropPos.dx - pickupPos.dx) * 0.35,
      pickupPos.dy - 25,
      pickupPos.dx + (dropPos.dx - pickupPos.dx) * 0.55,
      dropPos.dy + 35,
      dropPos.dx,
      dropPos.dy,
    );

    if (showRoute) {
      final glowColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF4F46E5);
      canvas.drawPath(
        routePath,
        Paint()
          ..color = glowColor.withValues(alpha: isDark ? 0.32 : 0.22)
          ..strokeWidth = 14
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        routePath,
        Paint()
          ..color = glowColor
          ..strokeWidth = 5.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      // Dropoff Square Pin (Uber style)
      canvas.drawCircle(
        dropPos,
        14,
        Paint()..color = (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A)).withValues(alpha: 0.16),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: dropPos, width: 16, height: 16),
          const Radius.circular(4),
        ),
        Paint()..color = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: dropPos, width: 6, height: 6),
          const Radius.circular(1.5),
        ),
        Paint()..color = Colors.white,
      );
    }

    // 6. Nearby Idle Cars (Uber roaming cabs)
    if (showNearbyCars) {
      final nearbyOffsets = [
        Offset(size.width * 0.18, size.height * 0.52),
        Offset(size.width * 0.52, size.height * 0.58),
        Offset(size.width * 0.72, size.height * 0.45),
      ];
      for (int i = 0; i < nearbyOffsets.length; i++) {
        final jitter = math.sin((progress * math.pi * 2) + i) * 6;
        final pos = nearbyOffsets[i] + Offset(jitter, -jitter * 0.5);
        _drawVehicleMarker(canvas, pos, isDark: isDark, small: true, angle: i * 0.7);
      }
    }

    // 7. Radar Pulse when searching for driver
    if (isSearchingRadar) {
      final pulseRadius1 = 22 + (progress * 68);
      final pulseRadius2 = 22 + (((progress + 0.5) % 1.0) * 68);
      final alpha1 = (1.0 - progress).clamp(0.0, 1.0) * 0.45;
      final alpha2 = (1.0 - ((progress + 0.5) % 1.0)).clamp(0.0, 1.0) * 0.45;

      canvas.drawCircle(
        pickupPos,
        pulseRadius1,
        Paint()
          ..color = const Color(0xFF4F46E5).withValues(alpha: alpha1)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        pickupPos,
        pulseRadius2,
        Paint()
          ..color = const Color(0xFF38BDF8).withValues(alpha: alpha2)
          ..style = PaintingStyle.fill,
      );
    }

    // 8. Pickup Marker (Uber Blue Ring + White Core)
    canvas.drawCircle(
      pickupPos,
      18,
      Paint()..color = const Color(0xFF2563EB).withValues(alpha: 0.22),
    );
    canvas.drawCircle(
      pickupPos,
      10,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      pickupPos,
      6.5,
      Paint()..color = const Color(0xFF2563EB),
    );

    // 9. Moving Assigned Vehicle on Route
    if (showMovingVehicle && showRoute) {
      final metrics = routePath.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final metric = metrics.first;
        final dist = metric.length * progress.clamp(0.04, 0.96);
        final tangent = metric.getTangentForOffset(dist);
        if (tangent != null) {
          _drawVehicleMarker(
            canvas,
            tangent.position,
            isDark: isDark,
            small: false,
            angle: -tangent.angle + math.pi / 2,
          );
        }
      }
    }
  }

  void _drawVehicleMarker(
    Canvas canvas,
    Offset pos, {
    required bool isDark,
    required bool small,
    double angle = 0,
  }) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    final w = small ? 15.0 : 22.0;
    final h = small ? 24.0 : 34.0;

    canvas.drawCircle(
      const Offset(0, 3),
      small ? 11 : 16,
      Paint()
        ..color = Colors.black.withValues(alpha: isDark ? 0.55 : 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        Radius.circular(small ? 5 : 8),
      ),
      Paint()..color = Colors.white,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w * 0.65, height: h * 0.5),
        Radius.circular(small ? 2 : 4),
      ),
      Paint()..color = const Color(0xFF1E293B),
    );

    if (!small) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 8, height: 6),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF4F46E5),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _UberVectorMapPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.pickupNormalized != pickupNormalized ||
        oldDelegate.dropNormalized != dropNormalized ||
        oldDelegate.showRoute != showRoute ||
        oldDelegate.isSearchingRadar != isSearchingRadar ||
        oldDelegate.showMovingVehicle != showMovingVehicle ||
        oldDelegate.progress != progress;
  }
}
