import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cooli/features/services/model/blackbuck_load_model.dart';
import 'package:cooli/features/services/repo/services_repo.dart';
import 'package:cooli/features/services/view/blackbuck_load_details_view.dart';
import 'package:cooli/features/services/view/blackbuck_loads_view.dart';
import 'package:cooli/services/session_manager.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';

class MyShipmentsView extends StatefulWidget {
  static const String routeName = '/my-shipments';

  const MyShipmentsView({super.key});

  @override
  State<MyShipmentsView> createState() => _MyShipmentsViewState();
}

class _MyShipmentsViewState extends State<MyShipmentsView> {
  final ServicesRepo _repo = ServicesRepo();
  List<BlackbuckLoadModel> _shipments = [];
  bool _isLoading = true;
  String _activeFilter = 'All'; // 'All', 'Confirmed', 'In Transit', 'Delivered'

  @override
  void initState() {
    super.initState();
    _fetchShipments();
  }

  Future<void> _fetchShipments() async {
    setState(() => _isLoading = true);
    try {
      final userId = await SessionManager().getLoggedInUserId() ?? 1;
      final shipments = await _repo.fetchTransportBookings(userId: userId);
      if (mounted) {
        setState(() {
          _shipments = shipments;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[MyShipmentsView] _fetchShipments error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<BlackbuckLoadModel> get _filteredShipments {
    if (_activeFilter == 'Confirmed') {
      return _shipments.where((s) {
        final st = (s.bookingStatus ?? s.status).toLowerCase();
        return st == 'confirmed' || st == 'bid_accepted' || st == 'accepted';
      }).toList();
    } else if (_activeFilter == 'In Transit') {
      return _shipments.where((s) {
        final st = (s.bookingStatus ?? s.status).toLowerCase();
        return st == 'in_transit' || st == 'dispatched' || st == 'on_the_way';
      }).toList();
    } else if (_activeFilter == 'Delivered') {
      return _shipments.where((s) {
        final st = (s.bookingStatus ?? s.status).toLowerCase();
        return st == 'delivered' || st == 'completed';
      }).toList();
    }
    return _shipments;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredShipments;

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
              'My Shipments',
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
                color: CooliColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_shipments.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CooliColors.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Shipments',
            icon:
                const Icon(Icons.refresh_rounded, color: CooliColors.textDark),
            onPressed: _fetchShipments,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _buildFilterBar(),
        ),
      ),
      body: RefreshIndicator(
        color: CooliColors.primary,
        onRefresh: _fetchShipments,
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
                      return _buildShipmentCard(item);
                    },
                  ),
      ),
    );
  }

  // Filter Tabs Bar
  Widget _buildFilterBar() {
    final filters = ['All', 'Confirmed', 'In Transit', 'Delivered'];
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
            count = _shipments.length;
          } else if (f == 'Confirmed') {
            count = _shipments.where((s) {
              final st = (s.bookingStatus ?? s.status).toLowerCase();
              return st == 'confirmed' ||
                  st == 'bid_accepted' ||
                  st == 'accepted';
            }).length;
          } else if (f == 'In Transit') {
            count = _shipments.where((s) {
              final st = (s.bookingStatus ?? s.status).toLowerCase();
              return st == 'in_transit' || st == 'dispatched';
            }).length;
          } else if (f == 'Delivered') {
            count = _shipments.where((s) {
              final st = (s.bookingStatus ?? s.status).toLowerCase();
              return st == 'delivered' || st == 'completed';
            }).length;
          }

          return GestureDetector(
            onTap: () => setState(() => _activeFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isSelected ? CooliColors.primary : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: CooliColors.primary.withValues(alpha: 0.25),
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
                          color:
                              isSelected ? Colors.white : CooliColors.textDark,
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
          borderRadius: BorderRadius.circular(18),
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
                color: CooliColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                size: 46,
                color: CooliColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _activeFilter == 'All'
                  ? 'No Shipments Yet'
                  : 'No $_activeFilter Shipments',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: CooliColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _activeFilter == 'All'
                  ? 'You haven\'t booked any freight loads yet. Book a truck or post your load requirement to get started.'
                  : 'There are currently no shipments under the "$_activeFilter" filter.',
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
                backgroundColor: CooliColors.primary,
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
                'Explore Transport Loads',
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

  // Shipment Card
  Widget _buildShipmentCard(BlackbuckLoadModel item) {
    final bookingId = item.bookingId ?? item.id;
    final status = (item.bookingStatus ?? item.status).toLowerCase();
    final bool isConfirmed = status == 'confirmed' || status == 'bid_accepted';
    final bool isInTransit = status == 'in_transit' || status == 'dispatched';
    final bool isCompleted = status == 'completed' || status == 'delivered';

    Color statusColor = CooliColors.primary;
    Color statusBg = CooliColors.primary.withValues(alpha: 0.1);
    String statusText = item.statusBadgeLabel;

    if (isCompleted) {
      statusColor = const Color(0xFF16A34A);
      statusBg = const Color(0xFFDCFCE7);
      statusText = 'DELIVERED';
    } else if (isInTransit) {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFEF3C7);
      statusText = 'IN TRANSIT';
    } else if (isConfirmed) {
      statusColor = const Color(0xFF2563EB);
      statusBg = const Color(0xFFEFF6FF);
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
          // Header: Booking ID, Status Badge
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
                      message: 'Booking ID copied to clipboard',
                      icon: Icons.copy_rounded,
                      iconColor: CooliColors.primary,
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: CooliColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          size: 14,
                          color: CooliColors.primary,
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
                          size: 13, color: CooliColors.textLight),
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
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          letterSpacing: 0.3,
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

                const SizedBox(height: 16),
                const Divider(height: 1, color: CooliColors.borderLight),
                const SizedBox(height: 14),

                // Specs Grid (Material, Weight, Truck Type, Transporter)
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
                        icon: Icons.directions_bus_outlined,
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

                // Driver / Truck Assignment Status
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
                            : Icons.access_time_rounded,
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
                                  ? 'Driver & Vehicle Assigned'
                                  : 'Driver Assignment In Progress',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: item.hasDriverAssigned
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFF854D0E),
                              ),
                            ),
                            if (item.hasDriverAssigned) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${item.driverName ?? "Driver"} • ${item.truckNumber ?? ""}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 2),
                              const Text(
                                'Transporter will assign driver details shortly',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFA16207),
                                ),
                              ),
                            ],
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

                // Fare Breakdown & CTA Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Fare',
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
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: CooliColors.textDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Details Button
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: CooliColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                          onPressed: () {
                            _showShipmentDetailsModal(context, item);
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

                        // Track / Full View Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CooliColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                          icon: const Icon(Icons.navigation_outlined, size: 15),
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
              // Pickup Node
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
                          size: 11, color: CooliColors.primary),
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
              // Drop Node
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
                      'Destination Unloading Point',
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

  // Spec Item Widget
  Widget _buildSpecItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: CooliColors.primary),
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

  // Bottom Sheet Detailed Breakdown Modal
  void _showShipmentDetailsModal(
      BuildContext context, BlackbuckLoadModel item) {
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
            // Handle Bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Modal Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shipment Overview',
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
                    // Status & Load ID Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: Color(0xFF2563EB), size: 20),
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
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Status: ${item.statusBadgeLabel}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2563EB),
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
                      'Freight Details',
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
                    _buildInfoRow(
                        'Truck Type', item.truckTypeDisplay ?? item.truckType),
                    _buildInfoRow('Distance', item.distance),
                    if (item.formattedPickupSchedule.isNotEmpty)
                      _buildInfoRow(
                          'Scheduled Pickup', item.formattedPickupSchedule),

                    const SizedBox(height: 20),
                    const Text(
                      'Transporter & Booking Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CooliColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow('Transporter', item.transporterName),
                    _buildInfoRow(
                        'Driver Name',
                        item.driverName?.isNotEmpty == true
                            ? item.driverName!
                            : 'Pending Assignment'),
                    _buildInfoRow(
                        'Truck Number',
                        item.truckNumber?.isNotEmpty == true
                            ? item.truckNumber!
                            : 'Pending Assignment'),
                    if (item.driverMobileNumber?.isNotEmpty == true)
                      _buildInfoRow('Driver Contact', item.driverMobileNumber!),
                    if (item.etaHours != null)
                      _buildInfoRow('ETA Transit', '${item.etaHours} Hours'),
                    if (item.podOtp != null && item.podOtp!.isNotEmpty)
                      _buildInfoRow('POD OTP', item.podOtp!),

                    const SizedBox(height: 20),
                    const Text(
                      'Fare & Payment',
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
                              const Text('Agreed Fare',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: CooliColors.textMuted)),
                              Text(
                                item.finalFare != null &&
                                        item.finalFare!.isNotEmpty
                                    ? '₹ ${_formatAmount(item.finalFare!)}'
                                    : item.totalEarnings,
                                style: const TextStyle(
                                  fontSize: 15,
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
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // Bottom Actions Bar
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
                      label: const Text('Share Load Details',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text:
                              'Shipment Booking ${item.bookingId ?? item.id}: ${item.loadingPoint} to ${item.unloadingPoint}. Transporter: ${item.transporterName}.',
                        ));
                        showCooliToast(
                          context,
                          message: 'Shipment info copied to clipboard',
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
                        backgroundColor: CooliColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.navigation_outlined, size: 18),
                      label: const Text('Open Tracker',
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
