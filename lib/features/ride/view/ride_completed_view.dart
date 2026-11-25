import 'package:flutter/material.dart';
import 'package:cooli/features/dashboard/view/main_navigation_view.dart';
import 'package:cooli/features/ride/view_model/ride_view_model.dart';
import 'package:cooli/features/ride/widgets/ride_view_model_scope.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';

class RideCompletedView extends StatelessWidget {
  static const String routeName = '/ride-completed';

  const RideCompletedView({super.key});

  void _finishAndGoHome(BuildContext context, RideViewModel vm, {bool submitted = false}) {
    if (submitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Rated ${vm.driver?.name ?? 'driver'} ${vm.userRating}★ — Thank you!',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    vm.resetTrip();
    Navigator.pushNamedAndRemoveUntil(
      context,
      MainNavigationView.routeName,
      (route) => false,
    );
  }

  void _showReceiptDialog(BuildContext context, RideViewModel vm) {
    final breakdown = vm.selectedFareBreakdown;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
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
                  'Trip Receipt',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: CooliColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${vm.pickupLocation} → ${vm.dropLocation}',
                  style: const TextStyle(fontSize: 13, color: CooliColors.textMuted),
                ),
                const Divider(height: 22),
                if (breakdown != null) ...[
                  _ReceiptLine('Base fare', '₹${breakdown.baseFare.toStringAsFixed(0)}'),
                  _ReceiptLine(
                    'Distance (${vm.routeDistanceKm.toStringAsFixed(1)} km)',
                    '₹${breakdown.distanceFare.toStringAsFixed(0)}',
                  ),
                  _ReceiptLine('Platform fee', '₹${breakdown.platformFee.toStringAsFixed(0)}'),
                  if (breakdown.discount > 0)
                    _ReceiptLine(
                      'Promo discount',
                      '-₹${breakdown.discount.toStringAsFixed(0)}',
                    ),
                ],
                if (vm.tipAmount > 0)
                  _ReceiptLine('Driver tip', '₹${vm.tipAmount.toStringAsFixed(0)}'),
                const Divider(height: 20),
                _ReceiptLine(
                  'Total Paid (${vm.selectedPaymentMethod.title})',
                  '₹${vm.finalTotalFare.toStringAsFixed(0)}',
                  isBold: true,
                ),
                const SizedBox(height: 16),
                CooliButton(
                  text: 'Close Receipt',
                  onTap: () => Navigator.pop(sheetCtx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tipOptions = [0.0, 20.0, 50.0, 100.0];

    return RideViewModelScope(
      builder: (context, vm) {
        final driver = vm.driver;
        final vehicleImage = vm.selectedOption?.imagePath ?? 'assets/images/ride_completed_car.png';

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: CooliColors.textDark,
                size: 20,
              ),
              onPressed: () => _finishAndGoHome(context, vm),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => _showReceiptDialog(context, vm),
                icon: const Icon(Icons.receipt_long_rounded, size: 17),
                label: const Text('Receipt'),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Checkmark + Vehicle Illustration
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 210,
                        height: 130,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFEEF2FF),
                              const Color(0xFFE0E7FF).withValues(alpha: 0.5),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            radius: 0.8,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 112,
                        child: Image.asset(
                          vehicleImage,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.directions_car_filled_rounded,
                            size: 76,
                            color: CooliColors.primary,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -8,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: CooliColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: CooliColors.success.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Ride Completed!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: CooliColors.textDark,
                      letterSpacing: -0.4,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    '${vm.pickupLocation} → ${vm.dropLocation}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CooliColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    '₹${vm.finalTotalFare.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: CooliColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: CooliColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Paid via ${vm.selectedPaymentMethod.title}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CooliColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Driver Rating
                  Text(
                    'How was your ride with ${driver?.name ?? 'your driver'}?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = index + 1;
                      final isSelected = starVal <= vm.userRating;
                      return GestureDetector(
                        onTap: () => vm.setRating(starVal),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 36,
                            color: isSelected
                                ? CooliColors.warning
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                      );
                    }),
                  ),

                  if (vm.userRating >= 4) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: vm.complimentTags.map((tag) {
                        final selected = vm.selectedCompliments.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: selected,
                          selectedColor: CooliColors.primarySoft,
                          checkmarkColor: CooliColors.primary,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected ? CooliColors.primary : CooliColors.textDark,
                          ),
                          onSelected: (_) => vm.toggleCompliment(tag),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Add Tip (Uber Style)
                  const Text(
                    'Add a tip for your driver',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: CooliColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: tipOptions.map((amount) {
                      final selected = vm.tipAmount == amount;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(
                            amount == 0 ? 'No tip' : '₹${amount.toStringAsFixed(0)}',
                          ),
                          selected: selected,
                          selectedColor: CooliColors.primary,
                          backgroundColor: CooliColors.surfaceAlt,
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : CooliColors.textDark,
                          ),
                          onSelected: (_) => vm.setTip(amount),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  CooliButton(
                    text: 'Submit Rating',
                    onTap: () => _finishAndGoHome(context, vm, submitted: true),
                  ),

                  const SizedBox(height: 10),

                  CooliOutlineButton(
                    text: 'Done',
                    borderColor: CooliColors.border,
                    textColor: CooliColors.textMuted,
                    onTap: () => _finishAndGoHome(context, vm),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  final String label;
  final String amount;
  final bool isBold;

  const _ReceiptLine(
    this.label,
    this.amount, {
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 15 : 13.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: isBold ? CooliColors.textDark : CooliColors.textMuted,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isBold ? 16 : 13.5,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: CooliColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
