import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/ride/model/ride_model.dart';
import 'package:cooli/features/ride/view_model/ride_view_model.dart';
import 'package:cooli/features/ride/view/ride_searching_driver_view.dart';

class RideSelectionView extends StatefulWidget {
  static const String routeName = '/ride-selection';

  const RideSelectionView({super.key});

  @override
  State<RideSelectionView> createState() => _RideSelectionViewState();
}

class _RideSelectionViewState extends State<RideSelectionView> {
  late RideViewModel _viewModel;
  String _selectedId = 'uber_go';
  String _selectedPayment = 'Google Pay / UPI';

  void _showPaymentSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              const Text(
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),
              _buildPaymentOption('Google Pay / UPI', Icons.account_balance_wallet_rounded),
              _buildPaymentOption('Cash on Delivery', Icons.money_rounded),
              _buildPaymentOption('Cooli Wallet (₹850)', Icons.wallet_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String label, IconData icon) {
    final isSelected = _selectedPayment == label;
    return ListTile(
      onTap: () {
        setState(() => _selectedPayment = label);
        Navigator.pop(context);
      },
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B), size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF0F172A),
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4F46E5), size: 20)
          : null,
    );
  }

  final List<Map<String, dynamic>> _rideOptions = [
    {
      'id': 'uber_auto',
      'name': 'Uber Auto',
      'subtitle': 'Affordable 3-wheeler auto rickshaw',
      'fare': 120.0,
      'originalFare': 140.0,
      'eta': '3 min away',
      'capacity': '3',
      'tag': 'Cheapest',
      'tagColor': Color(0xFF10B981),
      'image': 'assets/images/dash_ride_car_clean.png',
      'icon': Icons.electric_rickshaw_rounded,
    },
    {
      'id': 'uber_go',
      'name': 'Uber Go',
      'subtitle': 'Affordable, compact hatchback with AC',
      'fare': 220.0,
      'originalFare': 260.0,
      'eta': '4 min away',
      'capacity': '4',
      'tag': 'Most Popular',
      'tagColor': Color(0xFF4F46E5),
      'image': 'assets/images/dash_ride_car_clean.png',
      'icon': Icons.directions_car_filled_rounded,
    },
    {
      'id': 'uber_premier',
      'name': 'Uber Premier',
      'subtitle': 'Top-rated sedans with extra legroom',
      'fare': 340.0,
      'originalFare': 390.0,
      'eta': '5 min away',
      'capacity': '4',
      'tag': 'Comfort',
      'tagColor': Color(0xFF0284C7),
      'image': 'assets/images/dash_ride_car_clean.png',
      'icon': Icons.airport_shuttle_rounded,
    },
    {
      'id': 'uber_xl',
      'name': 'Uber XL',
      'subtitle': 'Spacious 6-seater SUV for luggage & groups',
      'fare': 480.0,
      'originalFare': 540.0,
      'eta': '7 min away',
      'capacity': '6',
      'tag': 'Extra Space',
      'tagColor': Color(0xFFD97706),
      'image': 'assets/images/dash_ride_car_clean.png',
      'icon': Icons.directions_car_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = RideViewModel();
  }

  void _proceedToSearching(Map<String, dynamic> selectedOption) {
    final optionModel = RideOption(
      id: selectedOption['id'] as String,
      name: selectedOption['name'] as String,
      description: selectedOption['subtitle'] as String,
      fare: (selectedOption['fare'] as num).toDouble(),
      eta: selectedOption['eta'] as String,
      icon: selectedOption['icon'] as IconData,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideSearchingDriverView(
          selectedOption: optionModel,
          pickupLocation: _viewModel.pickupLocation.isNotEmpty
              ? _viewModel.pickupLocation
              : 'MG Road, Marine Drive, Kochi',
          dropLocation: _viewModel.dropLocation.isNotEmpty
              ? _viewModel.dropLocation
              : 'Cochin International Airport (COK)',
          fare: (selectedOption['fare'] as num).toDouble(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedOption = _rideOptions.firstWhere(
      (o) => o['id'] == _selectedId,
      orElse: () => _rideOptions[1],
    );

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
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
          child: Column(
            children: [
              // Top Route Header Card
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        color: Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.route_rounded,
                        color: Color(0xFF4F46E5),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'MG Road ➔ Cochin Airport (COK)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            '28 km  •  Estimated 35 min',
                            style: TextStyle(
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Available Vehicles List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _rideOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _rideOptions[index];
                    final isSelected = item['id'] == _selectedId;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedId = item['id'] as String;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? const Color(0xFF4F46E5).withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.02),
                              blurRadius: isSelected ? 12 : 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // 3D Car artwork
                            Container(
                              width: 64,
                              height: 50,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFEEF2FF)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.asset(
                                item['image'] as String,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (_, __, ___) => Icon(
                                  item['icon'] as IconData,
                                  color: const Color(0xFF4F46E5),
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Details Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item['name'] as String,
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
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.person_rounded, size: 11, color: Color(0xFF64748B)),
                                            const SizedBox(width: 2),
                                            Text(
                                              item['capacity'] as String,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (item['tag'] != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: (item['tagColor'] as Color).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            item['tag'] as String,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: item['tagColor'] as Color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${item['eta']}  •  ${item['subtitle']}',
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

                            // Fare Column & Radio
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${(item['fare'] as num).toInt()}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                if (item['originalFare'] != null)
                                  Text(
                                    '₹${(item['originalFare'] as num).toInt()}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                      decoration: TextDecoration.lineThrough,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                  border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.account_balance_wallet_outlined,
                                    size: 16, color: Color(0xFF4F46E5)),
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
                                const Icon(Icons.arrow_drop_down_rounded,
                                    size: 18, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ),

                        // Promo discount tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFDCFCE7)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.local_offer_rounded, size: 14, color: Color(0xFF16A34A)),
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

                    const SizedBox(height: 14),

                    // Book Vehicle Button -> Directly starts searching for driver!
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => _proceedToSearching(selectedOption),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                          shadowColor: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Book ${selectedOption['name']}  •  ₹${(selectedOption['fare'] as num).toInt()}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

