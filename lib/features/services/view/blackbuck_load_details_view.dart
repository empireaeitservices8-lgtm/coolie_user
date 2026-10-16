import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';
import 'package:cooli/features/services/model/blackbuck_load_model.dart';
import 'package:cooli/features/services/repo/services_repo.dart';
import 'package:cooli/features/services/view/create_bid_bottom_sheet.dart';

class BlackbuckLoadDetailsView extends StatefulWidget {
  static const String routeName = '/blackbuck-load-details';

  final BlackbuckLoadModel? load;
  final String? bookingId;

  const BlackbuckLoadDetailsView({super.key, this.load, this.bookingId});

  @override
  State<BlackbuckLoadDetailsView> createState() =>
      _BlackbuckLoadDetailsViewState();
}

class _BlackbuckLoadDetailsViewState extends State<BlackbuckLoadDetailsView> {
  static const Color primaryBlue = Color(0xFF2563EB);

  late BlackbuckLoadModel _load;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load = widget.load ?? BlackbuckLoadModel.getSampleLoads().first;
    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    final bookingIdToFetch = widget.bookingId ??
        _load.bookingId ??
        'CL-20261005-4950';

    setState(() => _isLoading = true);
    final booking = await ServicesRepo().fetchBookingDetail(bookingIdToFetch);
    if (!mounted) return;

    if (booking != null) {
      setState(() {
        _load = booking;
        _isLoading = false;
      });
    } else {
      // Fallback: if booking wasn't found, try fetching load detail
      if (_load.id.isNotEmpty) {
        final loadDetail = await ServicesRepo().fetchLoadDetail(_load.id);
        if (mounted && loadDetail != null) {
          setState(() {
            _load = loadDetail;
            _isLoading = false;
          });
          return;
        }
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showCallModal(phoneNumber);
      }
    } catch (_) {
      _showCallModal(phoneNumber);
    }
  }

  void _showCallModal(String phoneNumber) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: CooliColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFEFF6FF),
                child: const Icon(
                  Icons.phone_in_talk_rounded,
                  color: primaryBlue,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _load.transporterName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: CooliColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _load.contactPerson,
                style: const TextStyle(
                  fontSize: 13,
                  color: CooliColors.textMuted,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: CooliColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  phoneNumber,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: primaryBlue,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              CooliButton(
                text: 'Call Now',
                icon: Icons.call,
                backgroundColor: primaryBlue,
                onTap: () {
                  Navigator.pop(context);
                  showCooliToast(
                    context,
                    message: 'Connecting to ${_load.contactPerson}...',
                    icon: Icons.phone_forwarded_rounded,
                    iconColor: CooliColors.success,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBidModal() {
    showCreateBidBottomSheet(
      context,
      load: _load,
      onBidSubmitted: () {
        _fetchBookingDetails();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConfirmed = _load.isConfirmedBooking || _load.bookingId != null;

    return Scaffold(
      backgroundColor: CooliColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: CooliColors.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Load Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: CooliColors.textDark,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              _load.bookingId != null
                  ? 'Booking #${_load.bookingId}'
                  : 'Load #${_load.id}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: primaryBlue,
              ),
            ),
          ],
        ),
        actions: [
          // WhatsApp Share Load
          GestureDetector(
            onTap: () {
              showCooliToast(
                context,
                message: 'Sharing load link on WhatsApp...',
                icon: Icons.share_rounded,
                iconColor: CooliColors.success,
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 11),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF16A34A), width: 1.2),
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFFECFDF5),
              ),
              child: Row(
                children: const [
                  Icon(Icons.chat_bubble_outline,
                      color: Color(0xFF16A34A), size: 14),
                  SizedBox(width: 4),
                  Text(
                    'SHARE',
                    style: TextStyle(
                      color: Color(0xFF16A34A),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Help
          GestureDetector(
            onTap: () {
              showCooliToast(
                context,
                message: 'Freight Hotline: 1800-200-COOL',
                icon: Icons.support_agent_rounded,
                iconColor: primaryBlue,
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 11),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: CooliColors.border),
                borderRadius: BorderRadius.circular(20),
                color: CooliColors.surfaceAlt,
              ),
              child: const Center(
                child: Text(
                  'Help',
                  style: TextStyle(
                    color: CooliColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            const LinearProgressIndicator(
              minHeight: 2.5,
              backgroundColor: Color(0xFFEFF6FF),
              valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
            ),
          Expanded(
            child: RefreshIndicator(
              color: primaryBlue,
              onRefresh: _fetchBookingDetails,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Confirmed Booking Card (When booking is confirmed / bid accepted)
                    if (isConfirmed) ...[
                      _buildConfirmedBookingCard(),
                      const SizedBox(height: 16),
                    ],

                    // Route Visualizer Card with Distance in km
                    _buildRouteCard(),

                    const SizedBox(height: 16),

                    // Specifications 2x2 Grid (Truck Type, Product, Weight, Payment Mode)
                    _buildSpecificationsGrid(),

                    const SizedBox(height: 16),

                    // Assigned Truck & Driver Card
                    if (isConfirmed) ...[
                      _buildAssignedVehicleCard(),
                      const SizedBox(height: 16),
                    ],

                    // Pricing & Terms Card
                    _buildPricingCard(),

                    const SizedBox(height: 16),

                    // Transporter Profile Card (John Doe)
                    _buildTransporterCard(),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Dock
          _buildBottomDock(isConfirmed),
        ],
      ),
    );
  }

  /// Top Confirmed Booking Card showing Booking ID, Agreed Final Fare & Transporter
  Widget _buildConfirmedBookingCard() {
    final bookingIdStr = _load.bookingId ?? 'CL-20261005-4950';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1410B981),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner Top Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF059669),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'BOOKING CONFIRMED',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF065F46),
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: bookingIdStr));
                    showCooliToast(
                      context,
                      message: 'Booking ID copied to clipboard!',
                      icon: Icons.copy_rounded,
                      iconColor: CooliColors.success,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          bookingIdStr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF047857),
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.copy_rounded,
                          size: 11,
                          color: Color(0xFF047857),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Agreed Final Fare',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CooliColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _load.formattedFinalFare,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: primaryBlue,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Confirmed Transporter Bid',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF059669),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Transporter Partner',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CooliColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  _load.transporterName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: CooliColors.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                size: 15,
                                color: primaryBlue,
                              ),
                            ],
                          ),
                          if (_load.etaHours != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'ETA: ${_load.etaHours} Hours (${(_load.etaHours! / 24).round()} Days)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: CooliColors.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ],
                        ],
                      ),
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

  /// Route Visualizer Card with calculated distance in km
  Widget _buildRouteCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CooliColors.border),
        boxShadow: CooliShadows.card,
      ),
      child: Column(
        children: [
          // Corridor title header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFBFDBFE),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.route_rounded,
                          size: 13,
                          color: primaryBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _load.distance,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: CooliColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CooliColors.border),
                    ),
                    child: Text(
                      '#${_load.id}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: CooliColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _load.isBidAccepted || _load.isConfirmedBooking
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _load.isBidAccepted || _load.isConfirmedBooking
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Text(
                  _load.statusBadgeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _load.isBidAccepted || _load.isConfirmedBooking
                        ? const Color(0xFF059669)
                        : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Route points timeline
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: CooliColors.success,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 38,
                    color: CooliColors.border,
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: CooliColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Loading Point
                    const Text(
                      'Loading Point',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CooliColors.textMuted,
                      ),
                    ),
                    Text(
                      _load.loadingPoint,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: CooliColors.textDark,
                      ),
                    ),
                    Text(
                      _load.loadingAddressNote,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CooliColors.textLight,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Unloading Point
                    const Text(
                      'Unloading Point',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CooliColors.textMuted,
                      ),
                    ),
                    Text(
                      _load.unloadingPoint,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: CooliColors.textDark,
                      ),
                    ),
                    Text(
                      _load.unloadingAddressNote,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CooliColors.textLight,
                      ),
                    ),
                    if (_load.formattedPickupSchedule.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              size: 15,
                              color: primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Scheduled Pickup: ${_load.formattedPickupSchedule}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: CooliColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Specifications 2x2 Grid
  Widget _buildSpecificationsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSpecTile(
                icon: Icons.local_shipping_rounded,
                label: 'Truck Required',
                value: _load.truckType,
                subtitle: '${_load.capacity} • ${_load.wheelers}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSpecTile(
                icon: Icons.inventory_2_rounded,
                label: 'Consignment Product',
                value: _load.product,
                subtitle: 'Standard Cargo Packaging',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSpecTile(
                icon: Icons.scale_rounded,
                label: 'Total Load Weight',
                value: _load.totalLoad,
                subtitle: 'Full Payload (FTL)',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSpecTile(
                icon: Icons.payments_rounded,
                label: 'Payment Mode',
                value: _load.paymentTerms,
                subtitle: 'Agreed on Confirmation',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Assigned Truck & Driver Card
  Widget _buildAssignedVehicleCard() {
    final hasDriver =
        _load.driverName != null && _load.driverName!.trim().isNotEmpty;
    final hasTruck =
        _load.truckNumber != null && _load.truckNumber!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CooliColors.border),
        boxShadow: CooliShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.directions_car_filled_rounded,
                      color: primaryBlue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Assigned Truck & Driver',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: CooliColors.textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasDriver && hasTruck
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasDriver && hasTruck ? 'ASSIGNED' : 'ASSIGNMENT IN PROGRESS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: hasDriver && hasTruck
                        ? const Color(0xFF059669)
                        : primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (hasDriver || hasTruck) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Truck Number',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CooliColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _load.truckNumber ?? 'KL 07 CD 4488',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: CooliColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned Driver',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CooliColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _load.driverName ?? 'Driver Assigned',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: CooliColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Transporter ${_load.transporterName} is finalizing the vehicle (${_load.truckType}) and driver dispatch details for the scheduled pickup on ${_load.formattedPickupSchedule}.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CooliColors.textDark,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_load.podOtp != null && _load.podOtp!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.key_rounded,
                      color: Color(0xFFD97706), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Delivery POD OTP: ${_load.podOtp}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Pricing & Terms Card
  Widget _buildPricingCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CooliColors.border),
        boxShadow: CooliShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Freight Pricing & Terms',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: CooliColors.textDark,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _load.isConfirmedBooking ? 'Agreed' : 'Negotiable',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _load.isConfirmedBooking
                    ? 'Agreed Transporter Bid'
                    : 'Total Driver Earnings',
                style: const TextStyle(
                  fontSize: 13,
                  color: CooliColors.textMuted,
                ),
              ),
              Text(
                _load.formattedFinalFare,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
          if (_load.expectedFareMin != null &&
              _load.expectedFareMax != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Expected Budget Range',
                  style: TextStyle(
                    fontSize: 12,
                    color: CooliColors.textLight,
                  ),
                ),
                Text(
                  '₹ ${_load.expectedFareMin?.split('.').first} - ₹ ${_load.expectedFareMax?.split('.').first}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CooliColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          // Payment Guarantee Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFFD97706),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _load.paymentNote,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Transporter Profile Card
  Widget _buildTransporterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CooliColors.border),
        boxShadow: CooliShadows.card,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFEFF6FF),
            child: const Icon(
              Icons.business_rounded,
              color: primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _load.transporterName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: CooliColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      color: primaryBlue,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _load.contactPerson,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CooliColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: CooliColors.warningSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFD97706),
                  size: 14,
                ),
                const SizedBox(width: 3),
                Text(
                  '${_load.rating}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Action Dock
  Widget _buildBottomDock(bool isConfirmed) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: CooliColors.border)),
        boxShadow: CooliShadows.elevated,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (isConfirmed) ...[
              // Call Transporter Button
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _makePhoneCall(_load.phoneNumber),
                    icon: const Icon(Icons.call_rounded,
                        color: Colors.white, size: 18),
                    label: Text(
                      'CALL ${_load.transporterName.split(' ').first.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Share or Track Button
              SizedBox(
                height: 50,
                width: 54,
                child: OutlinedButton(
                  onPressed: () {
                    showCooliToast(
                      context,
                      message: 'Load ${_load.id} is confirmed with ${_load.transporterName}',
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: CooliColors.success,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryBlue, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.share_rounded, color: primaryBlue, size: 20),
                ),
              ),
            ] else ...[
              // Bid Button
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _openBidModal,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: primaryBlue,
                        width: 1.8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'PLACE BID',
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Call Button
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _makePhoneCall(_load.phoneNumber),
                    icon: const Icon(Icons.call,
                        color: Colors.white, size: 18),
                    label: const Text(
                      'CALL NOW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpecTile({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CooliColors.border),
        boxShadow: CooliShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryBlue, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CooliColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: CooliColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: CooliColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
