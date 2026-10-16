import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/porter/view_model/porter_view_model.dart';
import 'package:cooli/utils/cooli_theme.dart';

class TrackPorterView extends StatefulWidget {
  static const String routeName = '/track-porter';

  final Map<String, dynamic>? booking;
  final String? bookingId;

  const TrackPorterView({super.key, this.booking, this.bookingId});

  @override
  State<TrackPorterView> createState() => _TrackPorterViewState();
}

class _TrackPorterViewState extends State<TrackPorterView> {
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      final routeArgs = ModalRoute.of(context)?.settings.arguments;
      Map<String, dynamic>? initialMap;
      if (widget.booking != null) {
        initialMap = widget.booking;
      } else if (routeArgs is Map<String, dynamic>) {
        initialMap = routeArgs;
      }

      final bId = widget.bookingId ??
          initialMap?['id']?.toString() ??
          (routeArgs is String || routeArgs is int ? routeArgs.toString() : null);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final vm = context.read<PorterViewModel>();
        if (bId != null && bId.isNotEmpty && bId != '--') {
          vm.fetchBookingDetails(bId, initialData: initialMap);
        } else if (initialMap != null) {
          vm.setActiveBooking(initialMap);
        }
      });
    }
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '--';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $period';
    } catch (_) {
      return raw;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Booking Confirmed 🎉';
      case 'assigned':
        return 'Porter Assigned';
      case 'pickup':
        return 'Pickup in Progress';
      case 'in_transit':
        return 'On the Way';
      case 'delivered':
        return 'Delivered ✅';
      case 'cancelled':
        return 'Booking Cancelled';
      default:
        return 'Booking Confirmed 🎉';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PorterViewModel>(
      builder: (context, vm, child) {
        final bookingData = vm.activeBooking ?? widget.booking ?? {};
        final isLoading = vm.isLoadingBookingDetails;
        final bookingId = bookingData['id']?.toString() ?? widget.bookingId ?? '--';
        final status = (bookingData['status'] ?? 'pending').toString();
        final pickupAddress = bookingData['pickup_address']?.toString() ?? '--';
        final deliveryAddress = bookingData['delivery_address']?.toString() ?? '--';
        final pickupContact = bookingData['pickup_contact_person']?.toString() ?? '--';
        final pickupPhone = bookingData['pickup_mobile_number']?.toString() ?? '--';
        final pickupInstructions = bookingData['pickup_instructions']?.toString();
        final receiverName = bookingData['receiver_name']?.toString() ?? '--';
        final receiverPhone = bookingData['receiver_mobile_number']?.toString() ?? '--';
        final deliveryInstructions = bookingData['delivery_instructions']?.toString();

        final vehicleType = bookingData['vehicle_name']?.toString() ??
            bookingData['vehicle_type_name']?.toString() ??
            (bookingData['vehicle_type'] != null
                ? vm.getVehicleName(bookingData['vehicle_type'])
                : '--');
        final goodsCategory = bookingData['goods_category']?.toString() ?? '--';
        final approxWeight = bookingData['approximate_weight']?.toString();
        final numberOfItems = bookingData['number_of_items']?.toString();
        final specialInstructions = bookingData['special_instructions']?.toString();
        final distanceKm = bookingData['distance_km']?.toString();

        final rawFare = bookingData['final_fare'] ?? bookingData['estimated_fare'];
        double? fareNum;
        if (rawFare != null) {
          fareNum = double.tryParse(rawFare.toString());
        }
        if (fareNum == null || fareNum <= 0) {
          final distRaw = bookingData['distance_km'];
          final dist = distRaw is num
              ? distRaw.toDouble()
              : (double.tryParse(distRaw?.toString() ?? '') ?? 5.0);
          final vMatch = vm.vehicles.where((v) => v.id == bookingData['vehicle_type']?.toString()).firstOrNull;
          final base = vMatch?.basePrice ?? 300.0;
          final perKm = vMatch?.perKmRate ?? 15.0;
          fareNum = base + (dist * perKm);
        }
        final fareStr = '₹${fareNum.toStringAsFixed(0)}';

        final scheduledTime = _formatDateTime(bookingData['scheduled_pickup_time']?.toString());
        final actualPickupTime = _formatDateTime(bookingData['actual_pickup_time']?.toString());
        final deliveryTime = _formatDateTime(bookingData['delivery_time']?.toString());
        final createdAt = _formatDateTime(bookingData['created_at']?.toString());
        final updatedAt = _formatDateTime(bookingData['updated_at']?.toString());

        final loadingReq = bookingData['loading_requirement'] == true;
        final unloadingReq = bookingData['unloading_requirement'] == true;

        final steps = [
          {
            'title': 'Booking Confirmed',
            'subtitle': createdAt != '--' ? createdAt : 'Order placed',
            'done': true,
            'icon': Icons.check_circle_rounded,
          },
          {
            'title': 'Porter Assigned',
            'subtitle': status == 'assigned' ||
                    status == 'pickup' ||
                    status == 'in_transit' ||
                    status == 'delivered'
                ? 'Driver assigned to order'
                : 'Looking for nearby driver',
            'done': status == 'assigned' ||
                status == 'pickup' ||
                status == 'in_transit' ||
                status == 'delivered',
            'icon': Icons.person_rounded,
          },
          {
            'title': 'Pickup in Progress',
            'subtitle': actualPickupTime != '--'
                ? 'Picked up at $actualPickupTime'
                : (scheduledTime != '--'
                    ? 'Scheduled for $scheduledTime'
                    : 'En route to pickup point'),
            'done': status == 'pickup' ||
                status == 'in_transit' ||
                status == 'delivered',
            'icon': Icons.local_shipping_rounded,
          },
          {
            'title': 'Delivered',
            'subtitle': deliveryTime != '--'
                ? 'Delivered at $deliveryTime'
                : (status == 'delivered' ? 'Completed' : 'Expected destination arrival'),
            'done': status == 'delivered',
            'icon': Icons.where_to_vote_rounded,
          },
        ];

        return Scaffold(
          backgroundColor: CooliColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: CooliColors.textDark, size: 20),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: Column(
              children: [
                const Text(
                  'Track Booking',
                  style: TextStyle(
                    color: CooliColors.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Booking #$bookingId',
                  style: const TextStyle(
                    color: CooliColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(CooliColors.primary),
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, color: CooliColors.primary),
                tooltip: 'Refresh Status',
                onPressed: () {
                  if (bookingId != '--') {
                    context.read<PorterViewModel>().fetchBookingDetails(bookingId);
                  }
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: const Color(0xFFF1F5F9), height: 1),
            ),
          ),
          body: RefreshIndicator(
            color: CooliColors.primary,
            onRefresh: () async {
              if (bookingId != '--') {
                await context.read<PorterViewModel>().fetchBookingDetails(bookingId);
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Status Hero Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _statusLabel(status),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Booking #$bookingId · $fareStr',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Route & Contact Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: CooliShadows.card,
                      border: Border.all(color: CooliColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildAddressSection(
                          icon: Icons.my_location_rounded,
                          color: const Color(0xFF10B981),
                          bgColor: const Color(0xFFECFDF5),
                          label: 'PICKUP LOCATION',
                          address: pickupAddress,
                          contactPerson: pickupContact,
                          phone: pickupPhone,
                          instructions: pickupInstructions,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                          child: Row(
                            children: [
                              Container(width: 2, height: 26, color: const Color(0xFFCBD5E1)),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  distanceKm != null && distanceKm != 'null'
                                      ? '$distanceKm km'
                                      : 'Calculated along route',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF475569),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildAddressSection(
                          icon: Icons.location_on_rounded,
                          color: const Color(0xFFEF4444),
                          bgColor: const Color(0xFFFEE2E2),
                          label: 'DELIVERY DESTINATION',
                          address: deliveryAddress,
                          contactPerson: receiverName,
                          phone: receiverPhone,
                          instructions: deliveryInstructions,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Progress Timeline Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: CooliShadows.card,
                      border: Border.all(color: CooliColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking Progress',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: CooliColors.textDark,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: steps.length,
                          itemBuilder: (context, index) {
                            final step = steps[index];
                            final isDone = step['done'] as bool;
                            final isLast = index == steps.length - 1;
                            final isActive = !isDone &&
                                (index == 0 || (steps[index - 1]['done'] as bool));

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDone
                                        ? const Color(0xFF4F46E5)
                                        : isActive
                                            ? const Color(0xFFEEF2FF)
                                            : CooliColors.surfaceAlt,
                                    border: Border.all(
                                      color: isDone
                                          ? const Color(0xFF4F46E5)
                                          : isActive
                                              ? const Color(0xFF4F46E5)
                                              : CooliColors.border,
                                      width: isActive ? 2 : 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: isDone
                                        ? const Icon(Icons.check_rounded,
                                            size: 16, color: Colors.white)
                                        : isActive
                                            ? Container(
                                                width: 10,
                                                height: 10,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF4F46E5),
                                                ),
                                              )
                                            : null,
                                  ),
                                ),
                                if (!isLast)
                                  Container(
                                    width: 2,
                                    height: 52,
                                    color: isDone
                                        ? const Color(0xFF4F46E5)
                                        : CooliColors.border,
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      step['title'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDone || isActive
                                            ? CooliColors.textDark
                                            : CooliColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      step['subtitle'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDone
                                            ? const Color(0xFF4F46E5)
                                            : CooliColors.textMuted,
                                        fontWeight: isDone
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                    if (!isLast) const SizedBox(height: 28),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Goods Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: CooliShadows.card,
                  border: Border.all(color: CooliColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.inventory_2_rounded,
                            size: 18, color: CooliColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Goods Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: CooliColors.textDark,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Category', goodsCategory),
                    if (numberOfItems != null && numberOfItems.isNotEmpty)
                      _buildDetailRow('Quantity', '$numberOfItems items'),
                    if (approxWeight != null &&
                        approxWeight.isNotEmpty &&
                        approxWeight != '0' &&
                        approxWeight != '0.00')
                      _buildDetailRow('Approximate Weight',
                          '${double.tryParse(approxWeight)?.toStringAsFixed(1) ?? approxWeight} kg'),
                    _buildDetailRow(
                      'Helpers Requested',
                      [
                        if (loadingReq) 'Loading',
                        if (unloadingReq) 'Unloading',
                        if (!loadingReq && !unloadingReq) 'None',
                      ].join(', '),
                    ),
                    if (specialInstructions != null &&
                        specialInstructions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 16, color: Color(0xFFD97706)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Note: $specialInstructions',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Booking & Fare Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: CooliShadows.card,
                  border: Border.all(color: CooliColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 18, color: CooliColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Fare & Details Summary',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: CooliColors.textDark,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Vehicle Type', vehicleType),
                    _buildDetailRow(
                      'Distance',
                      distanceKm != null && distanceKm != 'null'
                          ? '$distanceKm km'
                          : '--',
                    ),
                    _buildDetailRow('Estimated Fare', fareStr),
                    if (bookingData['final_fare'] != null)
                      _buildDetailRow('Final Fare', '₹${bookingData['final_fare']}'),
                    _buildDetailRow('Booked At', createdAt),
                    if (updatedAt != '--' && updatedAt != createdAt)
                      _buildDetailRow('Last Updated', updatedAt),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  },
);
  }

  Widget _buildAddressSection({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String label,
    required String address,
    required String contactPerson,
    required String phone,
    String? instructions,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: CooliColors.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: CooliColors.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (contactPerson != '--' || phone != '--')
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '$contactPerson${phone != '--' ? ' · $phone' : ''}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: CooliColors.textMuted,
                    ),
                  ),
                ),
              if (instructions != null && instructions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Instructions: $instructions',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF475569),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: CooliColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CooliColors.textDark,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
