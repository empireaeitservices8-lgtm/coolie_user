import 'package:flutter/material.dart';
import 'package:cooli/features/services/view/post_truck_requirement_view.dart';

class BlackbuckVehicleSelectionView extends StatefulWidget {
  static const String routeName = '/blackbuck-vehicle-selection';

  const BlackbuckVehicleSelectionView({super.key});

  @override
  State<BlackbuckVehicleSelectionView> createState() =>
      _BlackbuckVehicleSelectionViewState();
}

class _BlackbuckVehicleSelectionViewState
    extends State<BlackbuckVehicleSelectionView> {
  int _selectedVehicleIndex = 0;

  final List<Map<String, dynamic>> _vehicles = [
    {
      'title': '32 Ft Multi-Axle (XL)',
      'shortName': 'Multi-Axle (20-32T)',
      'capacity': '20 Tons Payload',
      'dimension': '32ft x 8ft x 8ft',
      'fare': '₹18,500 – 22,000',
      'tag': 'Best for Long Haul',
      'badgeColor': Color(0xFF4F46E5),
      'imagePath': 'assets/images/dash_blackbuck_clean.png',
      'fallbackIcon': Icons.local_shipping_rounded,
    },
    {
      'title': '20 Ft Open Body Lorry',
      'shortName': 'Open Body (10-20T)',
      'capacity': '15 Tons Payload',
      'dimension': '20ft x 7ft Open Body',
      'fare': '₹14,000 – 18,000',
      'tag': 'Heavy Material & Steel',
      'badgeColor': Color(0xFF0284C7),
      'imagePath': 'assets/images/cooli_truck_exact.png',
      'fallbackIcon': Icons.view_in_ar_rounded,
    },
    {
      'title': '24 Ft Container Lorry',
      'shortName': 'Container Box (14-20T)',
      'capacity': '14 Tons Payload',
      'dimension': '24ft x 7.5ft x 8ft Box',
      'fare': '₹16,000 – 19,500',
      'tag': 'Weather-proof Box',
      'badgeColor': Color(0xFF059669),
      'imagePath': 'assets/images/splash_truck_clean.png',
      'fallbackIcon': Icons.inventory_2_rounded,
    },
    {
      'title': '14 Ft Heavy Tipper',
      'shortName': 'Tipper (10-16T)',
      'capacity': '12 Tons Payload',
      'dimension': '14ft Hydraulic Tipper',
      'fare': '₹11,000 – 14,500',
      'tag': 'Aggregates, Sand & Stone',
      'badgeColor': Color(0xFFD97706),
      'imagePath': 'assets/images/lorry_3d.png',
      'fallbackIcon': Icons.fire_truck_rounded,
    },
    {
      'title': '40 Ft Heavy Flatbed Trailer',
      'shortName': 'Flatbed Heavy (32T+)',
      'capacity': '32 Tons Payload',
      'dimension': '40ft x 8.5ft Flatbed',
      'fare': '₹24,000 – 30,000',
      'tag': 'Industrial Machinery & Coils',
      'badgeColor': Color(0xFF7C3AED),
      'imagePath': 'assets/images/truck_3d.png',
      'fallbackIcon': Icons.rv_hookup_rounded,
    },
  ];

  void _proceedToRequirements() {
    final vehicle = _vehicles[_selectedVehicleIndex];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostTruckRequirementView(
          initialTruckType: vehicle['shortName'] as String,
          initialWeight: vehicle['capacity'] as String,
          initialFare: vehicle['fare'] as String,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedVehicle = _vehicles[_selectedVehicleIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Color(0xFF0F172A), size: 24),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Select Heavy Vehicle',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Vehicle List
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FTL Hero Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3730A3), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF4F46E5).withValues(alpha: 0.28),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'STEP 1 OF 2',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Choose Your Fleet',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Select vehicle capacity matching your cargo shipment',
                                  style: TextStyle(
                                    color: Color(0xFFE0E7FF),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Image.asset(
                              'assets/images/dash_blackbuck_clean.png',
                              fit: BoxFit.contain,
                              height: 80,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Available Commercial Fleet',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap a vehicle to configure requirements and request bids',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Fleet Cards
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _vehicles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final v = _vehicles[index];
                        final isSelected = index == _selectedVehicleIndex;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedVehicleIndex = index);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 2.0 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? const Color(0xFF4F46E5)
                                          .withValues(alpha: 0.12)
                                      : Colors.black.withValues(alpha: 0.02),
                                  blurRadius: isSelected ? 12 : 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Vehicle Thumbnail
                                Container(
                                  width: 64,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFEEF2FF)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: Image.asset(
                                    v['imagePath'] as String,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      v['fallbackIcon'] as IconData,
                                      color: const Color(0xFF4F46E5),
                                      size: 30,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Specs Column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              v['title'] as String,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0F172A),
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            isSelected
                                                ? Icons.check_circle_rounded
                                                : Icons
                                                    .radio_button_unchecked_rounded,
                                            color: isSelected
                                                ? const Color(0xFF4F46E5)
                                                : const Color(0xFFCBD5E1),
                                            size: 22,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${v['capacity']}  •  ${v['dimension']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: (v['badgeColor'] as Color)
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              v['tag'] as String,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: v['badgeColor'] as Color,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            v['fare'] as String,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF4F46E5),
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
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Continue CTA Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(color: Color(0xFFF1F5F9)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selected Fleet',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            selectedVehicle['title'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        selectedVehicle['capacity'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _proceedToRequirements,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Select Requirements',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
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
    );
  }
}
