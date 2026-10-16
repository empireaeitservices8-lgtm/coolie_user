import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/ride/model/ride_model.dart';
import 'package:cooli/features/ride/view_model/ride_view_model.dart';
import 'package:cooli/features/ride/view/ride_searching_driver_view.dart';
import 'package:cooli/features/ride/service/ride_location_service.dart';
import 'package:cooli/features/wallet/view_model/wallet_view_model.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';

class RideSelectionView extends StatefulWidget {
  static const String routeName = '/ride-selection';

  const RideSelectionView({super.key});

  @override
  State<RideSelectionView> createState() => _RideSelectionViewState();
}

class _RideSelectionViewState extends State<RideSelectionView> {
  late RideViewModel _viewModel;
  String _selectedPayment = 'Cash'; // 'Cash', 'UPI', 'Coolie Wallet'

  void _showPaymentSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer<WalletViewModel>(
          builder: (context, walletVM, _) {
            final balance = walletVM.balance;
            return SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Payment Method',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        InkWell(
                          onTap: () => walletVM.loadWalletData(),
                          child: const Row(
                            children: [
                              Icon(Icons.refresh_rounded,
                                  size: 14, color: Color(0xFF2563EB)),
                              SizedBox(width: 4),
                              Text(
                                'Refresh',
                                style: TextStyle(
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
                    const SizedBox(height: 14),

                    // 1. Cash Option
                    _buildPaymentOption(
                      title: 'Cash',
                      subtitle: 'Pay cash directly to driver',
                      icon: Icons.payments_rounded,
                      color: const Color(0xFF16A34A),
                    ),

                    // 2. UPI Option
                    _buildPaymentOption(
                      title: 'UPI',
                      subtitle: 'Google Pay, PhonePe, Paytm, BHIM',
                      icon: Icons.account_balance_rounded,
                      color: const Color(0xFF2563EB),
                    ),

                    // 3. Coolie Wallet Option
                    _buildPaymentOption(
                      title: 'Coolie Wallet',
                      subtitle:
                          'Available Balance: ₹${balance.toStringAsFixed(2)}',
                      icon: Icons.account_balance_wallet_rounded,
                      color: Colors.purple,
                      badge: '₹${balance.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? badge,
  }) {
    final isSelected = _selectedPayment == title;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? color : const Color(0xFFE2E8F0),
          width: isSelected ? 1.8 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          onTap: () {
            setState(() => _selectedPayment = title);
            Navigator.pop(context);
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          trailing: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? color : Colors.transparent,
              border: Border.all(
                color: isSelected ? color : const Color(0xFFCBD5E1),
                width: isSelected ? 2 : 1.5,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }

  bool _initializedArgs = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WalletViewModel>().loadWalletData();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel = context.read<RideViewModel>();
    if (!_initializedArgs) {
      _initializedArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        final pickup = args['pickup']?.toString();
        final drop = args['drop']?.toString();
        final pLat = args['pickupLat'] as double?;
        final pLng = args['pickupLng'] as double?;
        final dLat = args['dropLat'] as double?;
        final dLng = args['dropLng'] as double?;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (pickup != null && pickup.isNotEmpty) {
            _viewModel.setPickup(pickup, lat: pLat, lng: pLng);
          }
          if (drop != null && drop.isNotEmpty) {
            _viewModel.setDrop(drop, lat: dLat, lng: dLng);
          }
          _viewModel.calculateFaresForAvailableOptions();
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _viewModel.calculateFaresForAvailableOptions();
        });
      }
    }
  }

  Future<void> _proceedToSearching(RideOption selectedOption) async {
    final walletVM = context.read<WalletViewModel>();
    final isWallet = _selectedPayment == 'Coolie Wallet';

    if (isWallet && walletVM.balance < selectedOption.fare) {
      showCooliToast(
        context,
        message:
            'Insufficient wallet balance (Available: ₹${walletVM.balance.toStringAsFixed(0)}). Please top up or choose Cash / UPI.',
        icon: Icons.warning_amber_rounded,
        iconColor: CooliColors.danger,
      );
      return;
    }

    final paymentMethod =
        isWallet ? 'wallet' : (_selectedPayment == 'Cash' ? 'cash' : 'upi');

    // Fire booking to live API: POST http://coolie.pythonanywhere.com/api/ride/bookings/
    final response = await _viewModel.createBooking(
      selectedOption,
      paymentMethod: paymentMethod,
    );

    if (!mounted) return;

    if (response != null && response.booking != null) {
      if (isWallet) {
        await walletVM.deductFunds(
          amount: selectedOption.fare,
          title: 'Ride Booking (${selectedOption.name})',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Booking #${response.booking!.id} confirmed ($paymentMethod)! Finding nearby drivers...',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (_viewModel.bookingError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _viewModel.bookingError!,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideSearchingDriverView(
          selectedOption: selectedOption,
          bookingData: response?.booking,
          bookingId: response?.booking?.id,
          pickupLocation: _viewModel.pickupLocation.isNotEmpty
              ? _viewModel.pickupLocation
              : '',
          dropLocation:
              _viewModel.dropLocation.isNotEmpty ? _viewModel.dropLocation : '',
          pickupLat: _viewModel.pickupLat ?? 12.9716,
          pickupLng: _viewModel.pickupLng ?? 77.5946,
          dropLat: _viewModel.dropLat ?? 12.9784,
          dropLng: _viewModel.dropLng ?? 77.6408,
          fare: selectedOption.fare,
          paymentMethod: _selectedPayment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Select Vehicle',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: SafeArea(
        child: Consumer<RideViewModel>(
          builder: (context, vm, child) {
            final options = vm.rideOptions;
            final selectedOption = vm.selectedOption ??
                (options.isNotEmpty ? options.first : null);

            return Column(
              children: [
                // Top Route Header Card
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.route_rounded,
                          color: primaryBlue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${vm.pickupLocation.isNotEmpty ? vm.pickupLocation : 'Current Location'} ➔ ${vm.dropLocation.isNotEmpty ? vm.dropLocation : 'Destination'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              (vm.calculatedDistanceKm != null &&
                                      selectedOption?.fareEstimate != null)
                                  ? '${vm.calculatedDistanceKm!.toStringAsFixed(1)} km  •  ${selectedOption!.fareEstimate!.estimatedTravelTime} mins trip'
                                  : (vm.pickupLat != null && vm.dropLat != null)
                                      ? RideLocationService
                                          .calculateRideEstimate(
                                          lat1: vm.pickupLat!,
                                          lon1: vm.pickupLng ?? 77.5946,
                                          lat2: vm.dropLat!,
                                          lon2: vm.dropLng ?? 77.6408,
                                        )
                                      : 'Quick & safe ride',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: primaryBlue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Available Vehicles List from Live API
                Expanded(
                  child: options.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: primaryBlue,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: options.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = options[index];
                            final isSelected = selectedOption?.id == item.id;

                            return GestureDetector(
                              onTap: () => vm.selectOption(item),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFEFF6FF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryBlue
                                        : const Color(0xFFE2E8F0),
                                    width: isSelected ? 2.0 : 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? primaryBlue.withValues(alpha: 0.16)
                                          : Colors.black
                                              .withValues(alpha: 0.02),
                                      blurRadius: isSelected ? 12 : 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Vehicle Artwork
                                    Container(
                                      width: 64,
                                      height: 50,
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFDBEAFE)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Image.asset(
                                        item.imageAsset,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                        errorBuilder: (_, __, ___) => Icon(
                                          item.icon,
                                          color: primaryBlue,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Details Column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF0F172A),
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              // Capacity badge
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFF1F5F9),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                        Icons.person_rounded,
                                                        size: 11,
                                                        color:
                                                            Color(0xFF64748B)),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      item.capacity,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            Color(0xFF64748B),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (item.tag != null) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: (item.tagColor ??
                                                            primaryBlue)
                                                        .withValues(
                                                            alpha: 0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    item.tag!,
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: item.tagColor ??
                                                          primaryBlue,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${item.eta}  •  ${item.description}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Fare Column & Live Calculation State
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        if (vm.isCalculatingFare &&
                                            isSelected) ...[
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: primaryBlue,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Calculating...',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: primaryBlue,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ] else ...[
                                          Text(
                                            '₹${item.fare.toInt()}',
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF0F172A),
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          if (item.originalFare != null &&
                                              item.originalFare! > item.fare)
                                            Text(
                                              '₹${item.originalFare!.toInt()}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF94A3B8),
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Bottom Booking & Payment Card
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(26),
                      topRight: Radius.circular(26),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, -4),
                      ),
                    ],
                    border:
                        const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Payment Selector Pill & Promo Code
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Payment Mode Pill
                          GestureDetector(
                            onTap: _showPaymentSelector,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 16,
                                    color: primaryBlue,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedPayment,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_drop_down_rounded,
                                    size: 18,
                                    color: Color(0xFF64748B),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Promo discount tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: const Color(0xFFDCFCE7)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.local_offer_rounded,
                                    size: 14, color: Color(0xFF16A34A)),
                                SizedBox(width: 4),
                                Text(
                                  'FLAT50 (₹50 OFF)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Live Fare Breakdown Details (if returned by API)
                      if (selectedOption?.fareEstimate != null) ...[
                        Builder(
                          builder: (context) {
                            final estimate = selectedOption!.fareEstimate!;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.receipt_long_rounded,
                                          size: 14, color: Color(0xFF64748B)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Base: ₹${estimate.baseFare.toInt()}  +  Dist: ₹${estimate.distanceCharge.toInt()}  +  Service: ₹${estimate.additionalServiceCharge.toInt()}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '₹${selectedOption.fare.toInt()}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],

                      // Book Vehicle Button -> Directly starts searching for driver!
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: (selectedOption == null ||
                                  vm.isCalculatingFare ||
                                  vm.isCreatingBooking)
                              ? null
                              : () => _proceedToSearching(selectedOption),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF94A3B8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                            shadowColor: primaryBlue.withValues(alpha: 0.4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (vm.isCreatingBooking) ...[
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Booking ${selectedOption?.name ?? 'Vehicle'}...',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ] else if (vm.isCalculatingFare) ...[
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Calculating Live Fare...',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  selectedOption != null
                                      ? 'Book ${selectedOption.name}  •  ₹${selectedOption.fare.toInt()}'
                                      : 'Select Vehicle',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded,
                                    size: 18),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
