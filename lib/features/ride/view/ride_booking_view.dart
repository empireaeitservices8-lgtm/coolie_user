import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/ride/view_model/ride_view_model.dart';
import 'package:cooli/features/ride/view/ride_selection_view.dart';

class RideBookingView extends StatefulWidget {
  static const String routeName = '/ride-booking';

  const RideBookingView({super.key});

  @override
  State<RideBookingView> createState() => _RideBookingViewState();
}

class _RideBookingViewState extends State<RideBookingView> {
  late RideViewModel _viewModel;
  late TextEditingController _pickupController;
  late TextEditingController _dropController;

  final List<Map<String, String>> _popularPlaces = [
    {
      'title': 'Cochin International Airport (COK)',
      'subtitle': 'Nedumbassery, Kochi',
      'distance': '28 km',
      'time': '35 min',
      'icon': 'flight',
    },
    {
      'title': 'Lulu International Mall',
      'subtitle': 'NH 544, Edappally, Kochi',
      'distance': '8.5 km',
      'time': '18 min',
      'icon': 'shopping_bag',
    },
    {
      'title': 'Ernakulam South Railway Station',
      'subtitle': 'South Railway Station Rd, Ernakulam',
      'distance': '3.2 km',
      'time': '10 min',
      'icon': 'train',
    },
    {
      'title': 'Infopark Phase 1',
      'subtitle': 'Kakkanad, Kochi, Kerala',
      'distance': '14 km',
      'time': '25 min',
      'icon': 'apartment',
    },
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = RideViewModel();
    _pickupController = TextEditingController(text: 'MG Road, Marine Drive, Kochi');
    _dropController = TextEditingController(text: 'Cochin International Airport (COK)');
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  void _swapLocations() {
    setState(() {
      final temp = _pickupController.text;
      _pickupController.text = _dropController.text;
      _dropController.text = temp;
      _viewModel.setPickup(_pickupController.text);
      _viewModel.setDrop(_dropController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
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
            'Search Ride Location',
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
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. From & To Interactive Search Card (Uber Style)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            // Pickup "From" Input Container
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Pickup Location (From)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        TextField(
                                          controller: _pickupController,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: 'Enter pickup address',
                                            hintStyle: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF94A3B8),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            isDense: true,
                                            filled: false,
                                            fillColor: Colors.transparent,
                                            contentPadding: EdgeInsets.symmetric(vertical: 2),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            disabledBorder: InputBorder.none,
                                          ),
                                          onChanged: _viewModel.setPickup,
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _pickupController.text = 'Current Location (MG Road)';
                                        _viewModel.setPickup(_pickupController.text);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF2FF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.my_location_rounded,
                                        color: Color(0xFF4F46E5),
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Divider Row with Centered Swap Button
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                                  GestureDetector(
                                    onTap: _swapLocations,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.swap_vert_rounded, size: 16, color: Color(0xFF4F46E5)),
                                          SizedBox(width: 4),
                                          Text(
                                            'Swap',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF4F46E5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Destination "To" Input Container
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Where to? (Destination)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        TextField(
                                          controller: _dropController,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: 'Search destination',
                                            hintStyle: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF94A3B8),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            isDense: true,
                                            filled: false,
                                            fillColor: Colors.transparent,
                                            contentPadding: EdgeInsets.symmetric(vertical: 2),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            disabledBorder: InputBorder.none,
                                          ),
                                          onChanged: _viewModel.setDrop,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_dropController.text.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _dropController.clear();
                                          _viewModel.setDrop('');
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF1F5F9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Color(0xFF64748B),
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2. Quick Saved Destination Chips
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            _buildQuickChip(
                              icon: Icons.home_rounded,
                              label: 'Home',
                              onTap: () {
                                setState(() {
                                  _dropController.text = 'Home (Panampilly Nagar, Kochi)';
                                  _viewModel.setDrop(_dropController.text);
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildQuickChip(
                              icon: Icons.work_rounded,
                              label: 'Work',
                              onTap: () {
                                setState(() {
                                  _dropController.text = 'Infopark Phase 1, Kakkanad';
                                  _viewModel.setDrop(_dropController.text);
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildQuickChip(
                              icon: Icons.flight_takeoff_rounded,
                              label: 'Airport',
                              onTap: () {
                                setState(() {
                                  _dropController.text = 'Cochin International Airport (COK)';
                                  _viewModel.setDrop(_dropController.text);
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 3. Live Map Route Visual Representation
                      Container(
                        height: 190,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: Stack(
                          children: [
                            // Custom Painter for Map & Glowing Route
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _PreviewMapPainter(),
                              ),
                            ),

                            // Pickup Pin
                            Positioned(
                              top: 40,
                              left: 40,
                              child: _buildPin(
                                label: 'Pickup (MG Road)',
                                color: const Color(0xFF4F46E5),
                                icon: Icons.person_pin_circle_rounded,
                              ),
                            ),

                            // Destination Pin
                            Positioned(
                              bottom: 45,
                              right: 45,
                              child: _buildPin(
                                label: 'Airport (COK)',
                                color: const Color(0xFFEF4444),
                                icon: Icons.location_on_rounded,
                              ),
                            ),

                            // Route Distance & Time Badge
                            Positioned(
                              top: 14,
                              right: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.directions_car_filled_rounded,
                                        size: 14, color: Color(0xFF38BDF8)),
                                    SizedBox(width: 6),
                                    Text(
                                      '28 km • 35 min',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 4. Popular & Recent Destinations List
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: const Text(
                          'Suggested Destinations',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _popularPlaces.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _popularPlaces[index];
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _dropController.text = item['title']!;
                                _viewModel.setDrop(_dropController.text);
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.location_on_outlined,
                                      color: Color(0xFF4F46E5),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title']!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item['subtitle']!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        item['distance']!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        item['time']!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
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

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Bottom Confirm & See Vehicles Button
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, -3),
                    ),
                  ],
                  border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        RideSelectionView.routeName,
                      );
                    },
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
                      children: const [
                        Text(
                          'See Available Rides',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: const Color(0xFF4F46E5)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPin({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        Icon(icon, color: color, size: 28),
      ],
    );
  }
}

class _PreviewMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final roadPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(50, 70);
    path.quadraticBezierTo(size.width * 0.4, size.height * 0.2, size.width * 0.5, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.6, size.height * 0.8, size.width - 55, size.height - 65);

    // Glowing Road
    final glowPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.3)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final routePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, roadPaint);
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

