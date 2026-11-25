import 'package:flutter/material.dart';
import 'package:cooli/features/ride/model/ride_model.dart';
import 'package:cooli/features/ride/view/ride_tracking_view.dart';
import 'package:cooli/features/ride/view_model/ride_view_model.dart';
import 'package:cooli/features/ride/widgets/plan_ride_sheet.dart';
import 'package:cooli/features/ride/widgets/ride_map_canvas.dart';
import 'package:cooli/features/ride/widgets/ride_view_model_scope.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';

class RideSelectionView extends StatefulWidget {
  static const String routeName = '/ride-selection';

  const RideSelectionView({super.key});

  @override
  State<RideSelectionView> createState() => _RideSelectionViewState();
}

class _RideSelectionViewState extends State<RideSelectionView>
    with SingleTickerProviderStateMixin {
  late AnimationController _mapAnimController;

  @override
  void initState() {
    super.initState();
    _mapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _mapAnimController.dispose();
    super.dispose();
  }

  void _openEditRouteSheet(BuildContext context, RideViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlanRideSheet(
        viewModel: vm,
        initialFocus: PlanRideField.drop,
        onSetOnMap: () => Navigator.maybePop(context),
        onRouteReady: () {},
      ),
    );
  }

  void _showFareBreakdown(
    BuildContext context,
    RideViewModel vm,
    RideOption option,
  ) {
    final breakdown = option.getFareBreakdown(
      vm.routeDistanceKm,
      discount: vm.promoDiscount,
    );

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
                Row(
                  children: [
                    Image.asset(
                      option.imagePath,
                      width: 56,
                      height: 40,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(option.icon, color: CooliColors.primary, size: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: CooliColors.textDark,
                            ),
                          ),
                          Text(
                            '${option.capacity} seats • ${option.description}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: CooliColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${breakdown.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: CooliColors.textDark,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _FareRow('Base fare', '₹${breakdown.baseFare.toStringAsFixed(0)}'),
                _FareRow(
                  'Distance (${vm.routeDistanceKm.toStringAsFixed(1)} km)',
                  '₹${breakdown.distanceFare.toStringAsFixed(0)}',
                ),
                _FareRow('Platform & booking fee', '₹${breakdown.platformFee.toStringAsFixed(0)}'),
                if (breakdown.discount > 0)
                  _FareRow(
                    'Promo (${vm.promoCode ?? 'DISCOUNT'})',
                    '-₹${breakdown.discount.toStringAsFixed(0)}',
                    valueColor: CooliColors.success,
                  ),
                const Divider(height: 20),
                _FareRow(
                  'Estimated Total',
                  '₹${breakdown.total.toStringAsFixed(0)}',
                  isBold: true,
                ),
                const SizedBox(height: 16),
                CooliButton(
                  text: 'Got it',
                  onTap: () => Navigator.pop(sheetCtx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPaymentAndPromoSheet(BuildContext context, RideViewModel vm) {
    final promoCtrl = TextEditingController(text: vm.promoCode ?? '');
    String? promoFeedback;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
                ),
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
                      'Payment options',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: CooliColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...vm.paymentMethods.map((method) {
                      final isSelected = vm.selectedPaymentMethod.id == method.id;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        tileColor: isSelected ? CooliColors.primarySoft : null,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CooliColors.border),
                          ),
                          child: Icon(
                            method.icon,
                            color: isSelected ? CooliColors.primary : CooliColors.textDark,
                          ),
                        ),
                        title: Text(
                          method.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: CooliColors.textDark,
                          ),
                        ),
                        subtitle: Text(
                          method.subtitle,
                          style: const TextStyle(fontSize: 12, color: CooliColors.textMuted),
                        ),
                        trailing: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? CooliColors.primary : CooliColors.textLight,
                        ),
                        onTap: () {
                          vm.selectPaymentMethod(method);
                          Navigator.pop(sheetCtx);
                        },
                      );
                    }),
                    const Divider(height: 24),
                    const Text(
                      'Add promo code (try COOLI20 or SAVE30)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CooliColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: promoCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'Enter promo code',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            final ok = vm.applyPromoCode(promoCtrl.text);
                            setModalState(() {
                              promoFeedback = ok
                                  ? 'Applied ${vm.promoCode}! Saved ₹${vm.promoDiscount.toStringAsFixed(0)}'
                                  : 'Invalid code. Try COOLI20 or SAVE30';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CooliColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          ),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                    if (promoFeedback != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        promoFeedback!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: vm.promoDiscount > 0 ? CooliColors.success : CooliColors.danger,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(promoCtrl.dispose);
  }

  void _showConfirmPickupSheet(BuildContext context, RideViewModel vm) {
    final noteCtrl = TextEditingController(text: vm.pickupNote);
    final selected = vm.selectedOption;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
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
                  'Confirm your pickup spot',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: CooliColors.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${selected?.name ?? 'Ride'} • ₹${vm.selectedFare.toStringAsFixed(0)} via ${vm.selectedPaymentMethod.title}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CooliColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: CooliColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: CooliColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: CooliColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vm.pickupLocation,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: CooliColors.textDark,
                              ),
                            ),
                            Text(
                              vm.pickupAddress,
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
                      TextButton(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _openEditRouteSheet(context, vm);
                        },
                        child: const Text('Edit'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  onChanged: vm.setPickupNote,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.note_add_outlined, size: 20),
                    hintText: 'Add pickup note (e.g. Near main gate)',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: CooliColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                CooliButton(
                  text: 'Confirm Pickup',
                  showForwardArrow: true,
                  onTap: () {
                    vm.setPickupNote(noteCtrl.text);
                    vm.startSearchingDriver();
                    Navigator.pop(sheetCtx);
                    Navigator.pushNamed(context, RideTrackingView.routeName);
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(noteCtrl.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return RideViewModelScope(
      builder: (context, vm) {
        final selectedOption = vm.selectedOption ?? vm.rideOptions.first;

        return Scaffold(
          backgroundColor: CooliColors.background,
          body: Column(
            children: [
              // 1. TOP ROUTE MAP
              Expanded(
                flex: 7,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedBuilder(
                      animation: _mapAnimController,
                      builder: (context, _) {
                        return RideMapCanvas(
                          style: RideMapStyle.light,
                          pickupNormalized: vm.pickupPlace.mapNormalizedPos,
                          dropNormalized:
                              vm.dropPlace?.mapNormalizedPos ?? const Offset(0.76, 0.24),
                          pickupLabel: vm.pickupLocation,
                          dropLabel: vm.dropLocation,
                          showRoute: true,
                          showDropPin: true,
                          showNearbyCars: true,
                          animationProgress: _mapAnimController.value,
                          routePillText:
                              '${vm.routeDurationMinutes} min • ${vm.routeDistanceKm.toStringAsFixed(1)} km',
                        );
                      },
                    ),

                    // Floating Header: Back + Route Summary Pill
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              Material(
                                color: Colors.white,
                                shape: const CircleBorder(),
                                elevation: 3,
                                shadowColor: Colors.black26,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => Navigator.maybePop(context),
                                  child: const SizedBox(
                                    width: 42,
                                    height: 42,
                                    child: Icon(
                                      Icons.arrow_back_rounded,
                                      color: CooliColors.textDark,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _openEditRouteSheet(context, vm),
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
                                        Expanded(
                                          child: Text(
                                            '${vm.pickupLocation}  →  ${vm.dropLocation}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: CooliColors.textDark,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.edit_rounded,
                                          size: 15,
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
                  ],
                ),
              ),

              // 2. BOTTOM RIDE SELECTION SHEET
              Expanded(
                flex: 11,
                child: Container(
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
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Choose a ride',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: CooliColors.textDark,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (vm.promoCode != null)
                                GestureDetector(
                                  onTap: () => vm.clearPromoCode(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: CooliColors.successSoft,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${vm.promoCode} -₹${vm.promoDiscount.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: CooliColors.success,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.close_rounded,
                                          size: 13,
                                          color: CooliColors.success,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  vm.scheduleType == RideScheduleType.now
                                      ? 'Pickup now'
                                      : vm.scheduledTimeLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: CooliColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),

                        // Ride Options List
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            itemCount: vm.rideOptions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final option = vm.rideOptions[index];
                              final isSelected = option.id == selectedOption.id;
                              final fare = vm.fareFor(option);
                              final originalFare = option.calculateFare(vm.routeDistanceKm);

                              return GestureDetector(
                                onTap: () {
                                  if (isSelected) {
                                    _showFareBreakdown(context, vm, option);
                                  } else {
                                    vm.selectOption(option);
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFF8FAFF)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected
                                          ? CooliColors.primary
                                          : const Color(0xFFE2E8F0),
                                      width: isSelected ? 2.0 : 1.0,
                                    ),
                                    boxShadow: isSelected ? CooliShadows.card : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 48,
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? CooliColors.primarySoft
                                              : const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Image.asset(
                                          option.imagePath,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.high,
                                          errorBuilder: (_, __, ___) => Icon(
                                            option.icon,
                                            color: CooliColors.primary,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    option.name,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w800,
                                                      color: CooliColors.textDark,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                const Icon(
                                                  Icons.person_rounded,
                                                  size: 13,
                                                  color: CooliColors.textMuted,
                                                ),
                                                Text(
                                                  '${option.capacity}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: CooliColors.textMuted,
                                                  ),
                                                ),
                                                if (option.badge != null) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: CooliColors.primarySoft,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      option.badge!,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
                                                        color: CooliColors.primary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${option.eta} • ${option.description}',
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
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${fare.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: CooliColors.textDark,
                                            ),
                                          ),
                                          if (vm.promoDiscount > 0)
                                            Text(
                                              '₹${originalFare.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: CooliColors.textLight,
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.info_outline_rounded,
                                              size: 14,
                                              color: CooliColors.primary,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Bottom Payment Row + Confirm CTA
                        Container(
                          padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => _showPaymentAndPromoSheet(context, vm),
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        vm.selectedPaymentMethod.icon,
                                        size: 20,
                                        color: CooliColors.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          vm.selectedPaymentMethod.title,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: CooliColors.textDark,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: CooliColors.surfaceAlt,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          vm.promoCode ?? 'Promo',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: CooliColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: CooliColors.textMuted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              CooliButton(
                                text:
                                    'Choose ${selectedOption.name} • ₹${vm.fareFor(selectedOption).toStringAsFixed(0)}',
                                onTap: () => _showConfirmPickupSheet(context, vm),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FareRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _FareRow(
    this.label,
    this.value, {
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: isBold ? CooliColors.textDark : CooliColors.textMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 13.5,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: valueColor ?? CooliColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
