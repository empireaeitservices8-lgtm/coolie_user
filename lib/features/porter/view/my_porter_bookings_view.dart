import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/porter/view/book_porter_view.dart';
import 'package:cooli/features/porter/view/track_porter_view.dart';
import 'package:cooli/features/porter/view_model/porter_view_model.dart';
import 'package:cooli/utils/cooli_theme.dart';

class MyPorterBookingsView extends StatefulWidget {
  static const String routeName = '/my-porter-bookings';

  const MyPorterBookingsView({super.key});

  @override
  State<MyPorterBookingsView> createState() => _MyPorterBookingsViewState();
}

class _MyPorterBookingsViewState extends State<MyPorterBookingsView> {
  String _selectedFilter = 'all'; // 'all', 'active', 'delivered'
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PorterViewModel>().fetchMyBookings();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'assigned':
        return const Color(0xFF0284C7);
      case 'pickup':
      case 'in_transit':
        return const Color(0xFF4F46E5);
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'assigned':
        return const Color(0xFFE0F2FE);
      case 'pickup':
      case 'in_transit':
        return const Color(0xFFEEF2FF);
      case 'delivered':
        return const Color(0xFFECFDF5);
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'assigned':
        return Icons.person_pin_rounded;
      case 'pickup':
      case 'in_transit':
        return Icons.local_shipping_rounded;
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  List<Map<String, dynamic>> _filterBookings(List<Map<String, dynamic>> list) {
    return list.where((b) {
      final status = (b['status'] ?? 'pending').toString().toLowerCase();

      // Tab filter
      if (_selectedFilter == 'active') {
        if (status == 'delivered' || status == 'cancelled') return false;
      } else if (_selectedFilter == 'delivered') {
        if (status != 'delivered') return false;
      }

      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final id = (b['id'] ?? '').toString().toLowerCase();
        final pickup = (b['pickup_address'] ?? '').toString().toLowerCase();
        final drop = (b['delivery_address'] ?? '').toString().toLowerCase();
        final goods = (b['goods_category'] ?? '').toString().toLowerCase();
        final contact = (b['pickup_contact_person'] ?? '').toString().toLowerCase();
        final receiver = (b['receiver_name'] ?? '').toString().toLowerCase();

        return id.contains(query) ||
            pickup.contains(query) ||
            drop.contains(query) ||
            goods.contains(query) ||
            contact.contains(query) ||
            receiver.contains(query);
      }
      return true;
    }).toList();
  }

  void _openTracking(Map<String, dynamic> booking, PorterViewModel vm) {
    final enriched = Map<String, dynamic>.from(booking);
    if (enriched['vehicle_name'] == null) {
      enriched['vehicle_name'] = vm.getVehicleName(booking['vehicle_type']);
    }
    if (enriched['estimated_fare'] == null && enriched['final_fare'] == null) {
      final distRaw = booking['distance_km'];
      final dist = distRaw is num
          ? distRaw.toDouble()
          : (double.tryParse(distRaw?.toString() ?? '') ?? 5.0);
      final vId = booking['vehicle_type']?.toString();
      final vMatch = vm.vehicles.where((v) => v.id == vId).firstOrNull;
      final base = vMatch?.basePrice ?? 300.0;
      final perKm = vMatch?.perKmRate ?? 15.0;
      enriched['estimated_fare'] = base + (dist * perKm);
    }
    vm.setActiveBooking(enriched);
    Navigator.pushNamed(
      context,
      TrackPorterView.routeName,
      arguments: enriched,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: CooliColors.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'My Porter Bookings',
          style: TextStyle(
            color: CooliColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: CooliColors.primary),
            tooltip: 'Refresh',
            onPressed: () => context.read<PorterViewModel>().fetchMyBookings(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
        body: Consumer<PorterViewModel>(
          builder: (context, vm, child) {
            final allBookings = vm.myBookings;
            final filtered = _filterBookings(allBookings);

            final activeCount = allBookings.where((b) {
              final s = (b['status'] ?? '').toString().toLowerCase();
              return s != 'delivered' && s != 'cancelled';
            }).length;
            final deliveredCount = allBookings.where((b) {
              final s = (b['status'] ?? '').toString().toLowerCase();
              return s == 'delivered';
            }).length;

            return Column(
              children: [
                // Top Search & Filter Bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    children: [
                      // Search field
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim();
                            });
                          },
                          style: const TextStyle(
                            fontSize: 14,
                            color: CooliColors.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search by ID, location, or goods...',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: CooliColors.textMuted,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: CooliColors.textMuted,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Filter chips
                      Row(
                        children: [
                          _buildFilterTab(
                            title: 'All (${allBookings.length})',
                            key: 'all',
                          ),
                          const SizedBox(width: 8),
                          _buildFilterTab(
                            title: 'Active ($activeCount)',
                            key: 'active',
                          ),
                          const SizedBox(width: 8),
                          _buildFilterTab(
                            title: 'Delivered ($deliveredCount)',
                            key: 'delivered',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: vm.isLoadingBookings
                      ? _buildLoadingState()
                      : vm.bookingsError != null
                          ? _buildErrorState(vm)
                          : filtered.isEmpty
                              ? _buildEmptyState()
                              : RefreshIndicator(
                                  color: CooliColors.primary,
                                  onRefresh: () => vm.fetchMyBookings(),
                                  child: ListView.separated(
                                    physics: const AlwaysScrollableScrollPhysics(
                                      parent: BouncingScrollPhysics(),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 14),
                                    itemBuilder: (context, index) {
                                      return _buildBookingCard(
                                          filtered[index], vm);
                                    },
                                  ),
                                ),
                ),
              ],
            );
          },
        ),
      );
    }

  Widget _buildFilterTab({required String title, required String key}) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = key;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? CooliColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : CooliColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, PorterViewModel vm) {
    final bookingId = booking['id']?.toString() ?? '--';
    final status = (booking['status'] ?? 'pending').toString();
    final statusColor = _getStatusColor(status);
    final statusBg = _getStatusBg(status);
    final statusIcon = _getStatusIcon(status);

    final pickupAddress = booking['pickup_address']?.toString() ?? '--';
    final deliveryAddress = booking['delivery_address']?.toString() ?? '--';
    final pickupContact = booking['pickup_contact_person']?.toString();
    final pickupPhone = booking['pickup_mobile_number']?.toString();
    final receiverName = booking['receiver_name']?.toString();
    final receiverPhone = booking['receiver_mobile_number']?.toString();

    final vehicleTypeId = booking['vehicle_type'];
    final vehicleName = vm.getVehicleName(vehicleTypeId);
    final goodsCategory = booking['goods_category']?.toString() ?? '--';
    final approximateWeight = booking['approximate_weight']?.toString();
    final numberOfItems = booking['number_of_items']?.toString();
    final distanceKm = booking['distance_km']?.toString();
    final rawFare = booking['final_fare'] ?? booking['estimated_fare'];
    double? fareNum;
    if (rawFare != null) {
      fareNum = double.tryParse(rawFare.toString());
    }
    if (fareNum == null || fareNum <= 0) {
      final distRaw = booking['distance_km'];
      final dist = distRaw is num
          ? distRaw.toDouble()
          : (double.tryParse(distRaw?.toString() ?? '') ?? 5.0);
      final vMatch = vm.vehicles.where((v) => v.id == vehicleTypeId?.toString()).firstOrNull;
      final base = vMatch?.basePrice ?? 300.0;
      final perKm = vMatch?.perKmRate ?? 15.0;
      fareNum = base + (dist * perKm);
    }
    final fareStr = '₹${fareNum.toStringAsFixed(0)}';

    final hasLoading = booking['loading_requirement'] == true;
    final hasUnloading = booking['unloading_requirement'] == true;
    final createdAt = _formatDateTime(booking['created_at']?.toString());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openTracking(booking, vm),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: ID, date, status chip
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: CooliColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Booking #$bookingId',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: CooliColors.textDark,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  vehicleName,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: CooliColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            createdAt,
                            style: const TextStyle(
                              fontSize: 11,
                              color: CooliColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 14),

                // Pickup & Drop visual route
                _buildRouteRow(
                  pickupAddress: pickupAddress,
                  deliveryAddress: deliveryAddress,
                  pickupContact: pickupContact,
                  pickupPhone: pickupPhone,
                  receiverName: receiverName,
                  receiverPhone: receiverPhone,
                  distanceKm: distanceKm,
                ),

                const SizedBox(height: 14),

                // Goods & helpers pill tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildPillTag(
                      icon: Icons.inventory_2_outlined,
                      label: goodsCategory,
                      color: const Color(0xFF4F46E5),
                      bg: const Color(0xFFEEF2FF),
                    ),
                    if (numberOfItems != null && numberOfItems != '0')
                      _buildPillTag(
                        icon: Icons.format_list_numbered_rounded,
                        label: '$numberOfItems items',
                        color: const Color(0xFF0F172A),
                        bg: const Color(0xFFF1F5F9),
                      ),
                    if (approximateWeight != null &&
                        approximateWeight != '0' &&
                        approximateWeight != '0.00')
                      _buildPillTag(
                        icon: Icons.scale_outlined,
                        label: '${double.tryParse(approximateWeight)?.toStringAsFixed(0) ?? approximateWeight} kg',
                        color: const Color(0xFF0F172A),
                        bg: const Color(0xFFF1F5F9),
                      ),
                    if (hasLoading)
                      _buildPillTag(
                        icon: Icons.north_rounded,
                        label: 'Loading helper',
                        color: const Color(0xFF10B981),
                        bg: const Color(0xFFECFDF5),
                      ),
                    if (hasUnloading)
                      _buildPillTag(
                        icon: Icons.south_rounded,
                        label: 'Unloading helper',
                        color: const Color(0xFF10B981),
                        bg: const Color(0xFFECFDF5),
                      ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 12),

                // Bottom Footer: Fare + Track Button
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estimated Fare',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: CooliColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          fareStr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Track Booking',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteRow({
    required String pickupAddress,
    required String deliveryAddress,
    String? pickupContact,
    String? pickupPhone,
    String? receiverName,
    String? receiverPhone,
    String? distanceKm,
  }) {
    return Column(
      children: [
        // Pickup row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    border: Border.all(color: const Color(0xFF10B981), width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.5,
                  height: 28,
                  color: const Color(0xFFCBD5E1),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pickupAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (pickupContact != null && pickupContact.isNotEmpty)
                    Text(
                      '$pickupContact${pickupPhone != null ? ' · $pickupPhone' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: CooliColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            if (distanceKm != null && distanceKm.isNotEmpty && distanceKm != 'null')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$distanceKm km',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: CooliColors.textDark,
                  ),
                ),
              ),
          ],
        ),

        // Drop-off row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                border: Border.all(color: const Color(0xFFEF4444), width: 2),
              ),
              child: Center(
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deliveryAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (receiverName != null && receiverName.isNotEmpty)
                    Text(
                      '$receiverName${receiverPhone != null ? ' · $receiverPhone' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: CooliColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPillTag({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, __) => Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(CooliColors.primary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(PorterViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 38,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Bookings',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: CooliColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              vm.bookingsError ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: CooliColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => vm.fetchMyBookings(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CooliColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                size: 48,
                color: CooliColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Bookings Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: CooliColors.textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You haven\'t made any porter bookings yet. Move your goods easily with trusted drivers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: CooliColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, BookPorterView.routeName);
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Book Porter Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CooliColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
