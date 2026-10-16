import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/ride/model/ride_model.dart';
import 'package:cooli/features/ride/view_model/ride_view_model.dart';
import 'package:cooli/features/ride/view/ride_booking_view.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';

class MyRidesView extends StatefulWidget {
  static const String routeName = '/my-rides';

  const MyRidesView({super.key});

  @override
  State<MyRidesView> createState() => _MyRidesViewState();
}

class _MyRidesViewState extends State<MyRidesView> {
  RideViewModel get _vm => context.watch<RideViewModel>();
  List<RideBookingData> get _rides => _vm.rideBookings;
  List<RideBookingData> get _filteredRides => _vm.filteredRideBookings;
  bool get _isLoading => _vm.isLoadingBookings;
  String get _activeFilter => _vm.rideFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RideViewModel>().fetchUserRideBookings();
    });
  }

  Future<void> _fetchRides() async {
    await context.read<RideViewModel>().fetchUserRideBookings();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRides;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: CooliColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text(
              'My Rides',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: CooliColors.textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: CooliColors.rideBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_rides.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CooliColors.rideBlue,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Rides',
            icon: const Icon(Icons.refresh_rounded, color: CooliColors.textDark),
            onPressed: _fetchRides,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _buildFilterBar(),
        ),
      ),
      body: RefreshIndicator(
        color: CooliColors.rideBlue,
        onRefresh: _fetchRides,
        child: _isLoading
            ? _buildLoadingState()
            : filtered.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildRideCard(item);
                    },
                  ),
      ),
    );
  }

  // Filter Tabs Bar
  Widget _buildFilterBar() {
    final filters = ['All', 'Active', 'Assigned', 'Completed'];
    return Container(
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _activeFilter == f;

          int count = 0;
          if (f == 'All') {
            count = _rides.length;
          } else if (f == 'Active') {
            count = _rides.where((r) {
              final st = r.status.toLowerCase();
              return st == 'pending' || st == 'in_progress' || st == 'started';
            }).length;
          } else if (f == 'Assigned') {
            count = _rides.where((r) {
              final st = r.status.toLowerCase();
              return st == 'driver_assigned' || (r.driverName != null && r.driverName!.isNotEmpty);
            }).length;
          } else if (f == 'Completed') {
            count = _rides.where((r) {
              final st = r.status.toLowerCase();
              return st == 'completed';
            }).length;
          }

          return GestureDetector(
            onTap: () => context.read<RideViewModel>().setRideFilter(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? CooliColors.rideBlue : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: CooliColors.rideBlue.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    f,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : CooliColors.textMuted,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : CooliColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Loading Skeletons
  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        height: 220,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CooliColors.borderLight),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 130,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Container(
                  width: 90,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 180,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: CooliColors.rideBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_filled_rounded,
                size: 46,
                color: CooliColors.rideBlue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _activeFilter == 'All' ? 'No Rides Found' : 'No $_activeFilter Rides',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: CooliColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _activeFilter == 'All'
                  ? 'You haven\'t booked any taxi or bike rides yet. Book your first ride to get moving!'
                  : 'There are currently no rides matching the "$_activeFilter" filter.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: CooliColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: CooliColors.rideBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.local_taxi_rounded, size: 18),
              label: const Text(
                'Book a Ride Now',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RideBookingView(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Ride Card Widget
  Widget _buildRideCard(RideBookingData item) {
    final status = item.status.toLowerCase();
    final bool isCompleted = status == 'completed';
    final bool isAssigned = status == 'driver_assigned' || (item.driverName != null && item.driverName!.isNotEmpty);
    final bool isCancelled = status == 'cancelled';

    Color statusColor = CooliColors.rideBlue;
    Color statusBg = CooliColors.rideBlue.withValues(alpha: 0.1);
    String statusText = item.statusBadgeLabel;

    if (isCompleted) {
      statusColor = const Color(0xFF16A34A);
      statusBg = const Color(0xFFDCFCE7);
      statusText = 'COMPLETED';
    } else if (isAssigned) {
      statusColor = const Color(0xFF0D9488);
      statusBg = const Color(0xFFCCFBF1);
      statusText = 'DRIVER ASSIGNED';
    } else if (isCancelled) {
      statusColor = CooliColors.danger;
      statusBg = CooliColors.danger.withValues(alpha: 0.1);
      statusText = 'CANCELLED';
    }

    final String vType = item.vehicleTypeName ?? 'Car';
    final double dist = item.calculatedDistanceKm;
    final String distText = dist > 0 ? '${dist.toStringAsFixed(1)} km' : 'Direct';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CooliColors.borderLight),
        boxShadow: CooliShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Ride ID, Vehicle Pill, Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                bottom: BorderSide(color: CooliColors.borderLight),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: '#${item.id}'));
                    showCooliToast(
                      context,
                      message: 'Ride ID copied',
                      icon: Icons.copy_rounded,
                      iconColor: CooliColors.rideBlue,
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: CooliColors.rideBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.vehicleIcon,
                          size: 15,
                          color: CooliColors.rideBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RIDE #${item.id}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: CooliColors.textDark,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy_rounded,
                          size: 12, color: CooliColors.textLight),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        vType,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: CooliColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.person, size: 12, color: Colors.grey.shade600),
                      Text(
                        '${item.numberOfPassengers}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route Visual Timeline
                _buildRouteTimeline(item, distText),

                const SizedBox(height: 14),

                // Driver Info or Searching Banner
                if (isAssigned && item.driverName != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: CooliColors.primary.withValues(alpha: 0.15),
                          child: const Icon(Icons.person,
                              size: 18, color: CooliColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.driverName ?? 'Driver Assigned',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                              if (item.vehicleNumber != null &&
                                  item.vehicleNumber!.isNotEmpty)
                                Text(
                                  item.vehicleNumber!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (item.driverMobile != null &&
                            item.driverMobile!.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.phone_rounded,
                                color: Color(0xFF16A34A), size: 20),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: item.driverMobile!));
                              showCooliToast(
                                context,
                                message: 'Driver phone copied',
                                icon: Icons.phone_rounded,
                                iconColor: CooliColors.success,
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ] else if (status == 'pending') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search_rounded,
                            size: 18, color: Color(0xFF2563EB)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Finding nearest driver for pickup...',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Fare & Bottom Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.formattedDate,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: CooliColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.displayFare,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: CooliColors.textDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: CooliColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                          onPressed: () =>
                              _showRideDetailsModal(context, item),
                          child: const Text(
                            'Details',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: CooliColors.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CooliColors.rideBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                          icon: const Icon(Icons.repeat_rounded, size: 15),
                          label: const Text(
                            'Rebook',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RideBookingView(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Visual Route Timeline
  Widget _buildRouteTimeline(RideBookingData item, String distText) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CooliColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.pickupAddress.isNotEmpty
                          ? item.pickupAddress
                          : 'Pickup Location',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CooliColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.pickupInstructions != null &&
                        item.pickupInstructions!.isNotEmpty)
                      Text(
                        'Note: ${item.pickupInstructions}',
                        style: const TextStyle(
                            fontSize: 11, color: CooliColors.textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4.5, top: 4, bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 1.5,
                  height: 22,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(width: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.navigation_outlined,
                          size: 11, color: CooliColors.rideBlue),
                      const SizedBox(width: 4),
                      Text(
                        distText,
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
            ),
          ),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.dropAddress.isNotEmpty
                          ? item.dropAddress
                          : 'Destination Drop Location',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CooliColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.dropInstructions != null &&
                        item.dropInstructions!.isNotEmpty)
                      Text(
                        'Note: ${item.dropInstructions}',
                        style: const TextStyle(
                            fontSize: 11, color: CooliColors.textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Ride Details Modal
  void _showRideDetailsModal(BuildContext context, RideBookingData item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ride Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: CooliColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Booking # ${item.id}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CooliColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: CooliColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: CooliColors.borderLight),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRouteTimeline(item, '${item.calculatedDistanceKm.toStringAsFixed(1)} km'),
                    const SizedBox(height: 20),
                    const Text(
                      'Ride Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CooliColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow('Vehicle Type', item.vehicleTypeName ?? 'Car'),
                    _buildInfoRow('Service', item.vehicleTypeService ?? 'Ride'),
                    _buildInfoRow('Passengers', '${item.numberOfPassengers} Passenger(s)'),
                    _buildInfoRow('Status', item.statusBadgeLabel),
                    _buildInfoRow('Date & Time', item.formattedDate),

                    const SizedBox(height: 20),
                    const Text(
                      'Driver & Vehicle Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CooliColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow('Driver Name', item.driverName ?? 'Awaiting Assignment'),
                    _buildInfoRow('Vehicle Number', item.vehicleNumber ?? 'Pending Assignment'),
                    if (item.driverMobile != null && item.driverMobile!.isNotEmpty)
                      _buildInfoRow('Driver Contact', item.driverMobile!),

                    const SizedBox(height: 20),
                    const Text(
                      'Fare Information',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CooliColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CooliColors.borderLight),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Ride Fare',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: CooliColors.textMuted)),
                              Text(
                                item.displayFare,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: CooliColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Payment Mode',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: CooliColors.textMuted)),
                              Text(
                                'Cash / Wallet / UPI',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: CooliColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: CooliColors.borderLight),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CooliColors.rideBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.repeat_rounded, size: 18),
                  label: const Text('Rebook This Route',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RideBookingView(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: CooliColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CooliColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
