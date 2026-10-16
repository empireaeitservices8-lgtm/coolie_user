import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/services/model/blackbuck_load_model.dart';
import 'package:cooli/features/services/view_model/services_view_model.dart';
import 'package:cooli/features/services/view/blackbuck_load_details_view.dart';
import 'package:cooli/features/services/view/blackbuck_loads_view.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';

class MyBookingsView extends StatefulWidget {
  static const String routeName = '/my-bookings';

  const MyBookingsView({super.key});

  @override
  State<MyBookingsView> createState() => _MyBookingsViewState();
}

class _MyBookingsViewState extends State<MyBookingsView> {
  static const Color tealAccent = Color(0xFF0D9488);
  static const Color tealLight = Color(0xFFCCFBF1);

  ServicesViewModel get _vm => context.watch<ServicesViewModel>();
  List<BlackbuckLoadModel> get _bookings => _vm.transportBookings;
  List<BlackbuckLoadModel> get _filteredBookings =>
      _vm.filteredTransportBookings;
  bool get _isLoading => _vm.isLoadingBookings;
  String get _activeFilter => _vm.transportFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServicesViewModel>().fetchTransportBookings();
    });
  }

  Future<void> _fetchBookings() async {
    await context.read<ServicesViewModel>().fetchTransportBookings();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBookings;

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
              'My Bookings',
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
                color: tealAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_bookings.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tealAccent,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Bookings',
            icon: const Icon(Icons.refresh_rounded, color: CooliColors.textDark),
            onPressed: _fetchBookings,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _buildFilterBar(),
        ),
      ),
      body: RefreshIndicator(
        color: tealAccent,
        onRefresh: _fetchBookings,
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
                      return _buildBookingCard(item);
                    },
                  ),
      ),
    );
  }

  // Filter Tabs Bar
  Widget _buildFilterBar() {
    final filters = ['All', 'Confirmed', 'In Transit', 'Completed'];
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
            count = _bookings.length;
          } else if (f == 'Confirmed') {
            count = _bookings.where((b) {
              final st = (b.bookingStatus ?? b.status).toLowerCase();
              return st == 'confirmed' || st == 'bid_accepted' || st == 'accepted';
            }).length;
          } else if (f == 'In Transit') {
            count = _bookings.where((b) {
              final st = (b.bookingStatus ?? b.status).toLowerCase();
              return st == 'in_transit' || st == 'dispatched';
            }).length;
          } else if (f == 'Completed') {
            count = _bookings.where((b) {
              final st = (b.bookingStatus ?? b.status).toLowerCase();
              return st == 'completed' || st == 'delivered';
            }).length;
          }

          return GestureDetector(
            onTap: () => context.read<ServicesViewModel>().setTransportFilter(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? tealAccent : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: tealAccent.withValues(alpha: 0.28),
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

  // Loading Skeleton
  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        height: 230,
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
                  width: 140,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 80,
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
              width: 200,
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
                color: tealAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.build_circle_outlined,
                size: 46,
                color: tealAccent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _activeFilter == 'All' ? 'No Bookings Yet' : 'No $_activeFilter Bookings',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: CooliColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _activeFilter == 'All'
                  ? 'You don\'t have any active transport or freight bookings. Post your requirement or book a truck now.'
                  : 'There are currently no bookings with status "$_activeFilter".',
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
                backgroundColor: tealAccent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_road_rounded, size: 18),
              label: const Text(
                'Explore Transport Services',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BlackbuckLoadsView(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Booking Card Widget
  Widget _buildBookingCard(BlackbuckLoadModel item) {
    final bookingId = item.bookingId ?? item.id;
    final status = (item.bookingStatus ?? item.status).toLowerCase();
    final bool isConfirmed = status == 'confirmed' || status == 'bid_accepted';
    final bool isInTransit = status == 'in_transit' || status == 'dispatched';
    final bool isCompleted = status == 'completed' || status == 'delivered';

    Color statusColor = tealAccent;
    Color statusBg = tealLight;
    String statusText = item.statusBadgeLabel;

    if (isCompleted) {
      statusColor = const Color(0xFF16A34A);
      statusBg = const Color(0xFFDCFCE7);
      statusText = 'COMPLETED';
    } else if (isInTransit) {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFEF3C7);
      statusText = 'IN TRANSIT';
    } else if (isConfirmed) {
      statusColor = tealAccent;
      statusBg = tealLight;
      statusText = 'CONFIRMED';
    }

    final String fareText = item.finalFare != null && item.finalFare!.isNotEmpty
        ? '₹ ${_formatAmount(item.finalFare!)}'
        : (item.bidAmount != null && item.bidAmount!.isNotEmpty
            ? '₹ ${_formatAmount(item.bidAmount!)}'
            : item.totalEarnings);

    final String pickupCity =
        item.pickupCity ?? item.loadingPoint.split(',').first.trim();
    final String dropCity =
        item.dropCity ?? item.unloadingPoint.split(',').first.trim();

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
          // Header: Booking ID, Status Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                    Clipboard.setData(ClipboardData(text: bookingId));
                    showCooliToast(
                      context,
                      message: 'Booking ID copied',
                      icon: Icons.copy_rounded,
                      iconColor: tealAccent,
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: tealAccent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bookmark_added_rounded,
                          size: 14,
                          color: tealAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        bookingId,
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
                          fontSize: 10.5,
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
                _buildRouteTimeline(item, pickupCity, dropCity),

                const SizedBox(height: 14),
                const Divider(height: 1, color: CooliColors.borderLight),
                const SizedBox(height: 14),

                // Specifications
                Row(
                  children: [
                    Expanded(
                      child: _buildSpecItem(
                        icon: Icons.category_outlined,
                        label: 'Material',
                        value: item.materialTypeDisplay ?? item.product,
                      ),
                    ),
                    Expanded(
                      child: _buildSpecItem(
                        icon: Icons.scale_outlined,
                        label: 'Weight',
                        value: item.capacity.isNotEmpty
                            ? item.capacity
                            : '${item.totalLoad} Ton',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildSpecItem(
                        icon: Icons.local_shipping_outlined,
                        label: 'Truck Type',
                        value: item.truckTypeDisplay ?? item.truckType,
                      ),
                    ),
                    Expanded(
                      child: _buildSpecItem(
                        icon: Icons.business_outlined,
                        label: 'Transporter',
                        value: item.transporterName,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Driver / Vehicle Status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: item.hasDriverAssigned
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFFEF9C3).withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item.hasDriverAssigned
                          ? const Color(0xFFBBF7D0)
                          : const Color(0xFFFDE047),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.hasDriverAssigned
                            ? Icons.verified_user_rounded
                            : Icons.schedule_rounded,
                        size: 18,
                        color: item.hasDriverAssigned
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFCA8A04),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.hasDriverAssigned
                                  ? 'Driver Assigned: ${item.driverName ?? "Assigned"}'
                                  : 'Driver Assignment in Progress',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: item.hasDriverAssigned
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFF854D0E),
                              ),
                            ),
                            if (item.hasDriverAssigned &&
                                item.truckNumber != null &&
                                item.truckNumber!.isNotEmpty)
                              Text(
                                'Vehicle: ${item.truckNumber}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              )
                            else
                              const Text(
                                'Dispatch team will update driver details shortly',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFA16207),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (item.podOtp != null && item.podOtp!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            'OTP: ${item.podOtp}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: CooliColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Fare & Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Agreed Amount',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: CooliColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fareText,
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
                          onPressed: () {
                            _showBookingDetailsModal(context, item);
                          },
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
                            backgroundColor: tealAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                          icon: const Icon(Icons.navigation_outlined,
                              size: 15),
                          label: const Text(
                            'Track',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BlackbuckLoadDetailsView(
                                  load: item,
                                  bookingId: item.bookingId,
                                ),
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
  Widget _buildRouteTimeline(
      BlackbuckLoadModel item, String pickupCity, String dropCity) {
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
                      item.loadingPoint,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CooliColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.formattedPickupSchedule.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        'Pickup: ${item.formattedPickupSchedule}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: CooliColors.textMuted,
                        ),
                      ),
                    ],
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
                      const Icon(Icons.straighten_rounded,
                          size: 11, color: tealAccent),
                      const SizedBox(width: 4),
                      Text(
                        item.distance.isNotEmpty ? item.distance : 'Direct',
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
                      item.unloadingPoint,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CooliColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'Unloading Destination',
                      style: TextStyle(
                        fontSize: 11,
                        color: CooliColors.textMuted,
                      ),
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

  // Spec Item
  Widget _buildSpecItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: tealAccent),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: CooliColors.textMuted,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CooliColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Booking Details Modal Sheet
  void _showBookingDetailsModal(BuildContext context, BlackbuckLoadModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
                        'Booking Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: CooliColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Booking ID: ${item.bookingId ?? item.id}',
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
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: tealLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: tealAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: tealAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Load ID: ${item.id}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF134E4A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Booking Status: ${item.statusBadgeLabel}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: tealAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Pickup & Destination',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CooliColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildRouteTimeline(
                      item,
                      item.pickupCity ?? 'Origin',
                      item.dropCity ?? 'Destination',
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Freight Specifications',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CooliColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow('Material Type',
                        item.materialTypeDisplay ?? item.product),
                    _buildInfoRow('Total Weight', item.capacity),
                    _buildInfoRow('Truck Type',
                        item.truckTypeDisplay ?? item.truckType),
                    _buildInfoRow('Distance', item.distance),
                    if (item.formattedPickupSchedule.isNotEmpty)
                      _buildInfoRow(
                          'Scheduled Pickup', item.formattedPickupSchedule),
                    const SizedBox(height: 20),
                    const Text(
                      'Transporter & Booking Info',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CooliColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow('Transporter', item.transporterName),
                    _buildInfoRow('Driver Name',
                        item.driverName?.isNotEmpty == true
                            ? item.driverName!
                            : 'Pending Assignment'),
                    _buildInfoRow('Truck Number',
                        item.truckNumber?.isNotEmpty == true
                            ? item.truckNumber!
                            : 'Pending Assignment'),
                    if (item.driverMobileNumber?.isNotEmpty == true)
                      _buildInfoRow('Driver Contact', item.driverMobileNumber!),
                    if (item.etaHours != null)
                      _buildInfoRow('Estimated Transit', '${item.etaHours} Hours'),
                    if (item.podOtp != null && item.podOtp!.isNotEmpty)
                      _buildInfoRow('POD OTP', item.podOtp!),
                    const SizedBox(height: 20),
                    const Text(
                      'Agreed Fare & Terms',
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
                              const Text('Total Agreed Fare',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: CooliColors.textMuted)),
                              Text(
                                item.finalFare != null &&
                                        item.finalFare!.isNotEmpty
                                    ? '₹ ${_formatAmount(item.finalFare!)}'
                                    : item.totalEarnings,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: CooliColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Payment Mode',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: CooliColors.textMuted)),
                              Text(
                                item.paymentTerms,
                                style: const TextStyle(
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
                    const SizedBox(height: 20),
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: CooliColors.border),
                      ),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Share Booking',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text:
                              'Booking ${item.bookingId ?? item.id}: ${item.loadingPoint} to ${item.unloadingPoint}. Transporter: ${item.transporterName}.',
                        ));
                        showCooliToast(
                          context,
                          message: 'Booking details copied',
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: CooliColors.success,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tealAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.navigation_outlined, size: 18),
                      label: const Text('Track Booking',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlackbuckLoadDetailsView(
                              load: item,
                              bookingId: item.bookingId,
                            ),
                          ),
                        );
                      },
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

  static String _formatAmount(String amountStr) {
    final d = double.tryParse(amountStr);
    if (d == null) return amountStr;
    final intVal = d.round();
    return intVal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
