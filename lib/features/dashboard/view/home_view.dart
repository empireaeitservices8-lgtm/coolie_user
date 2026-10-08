import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/dashboard/view_model/dashboard_view_model.dart';
import 'package:cooli/features/ecommerce/view/ecommerce_home_view.dart';
import 'package:cooli/features/ride/view/ride_booking_view.dart';
import 'package:cooli/features/porter/view/porter_home_view.dart';
import 'package:cooli/features/services/view/services_home_view.dart';
import 'package:cooli/features/activity/view/activity_view.dart';
import 'package:cooli/features/profile/view/profile_view.dart';

class HomeView extends StatefulWidget {
  static const String routeName = '/home';

  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _idleFloatController;
  late AnimationController _handWaveController;

  // Staggered Entrance Animations
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _searchFade;
  late Animation<Offset> _searchSlide;
  late Animation<double> _heroScale;
  late Animation<double> _heroFade;

  // Staggered Right-to-Left Entrance Animations for 4 Service Cards
  late Animation<double> _ecomFade;
  late Animation<Offset> _ecomSlide;
  late Animation<double> _rideFade;
  late Animation<Offset> _rideSlide;
  late Animation<double> _courierFade;
  late Animation<Offset> _courierSlide;
  late Animation<double> _blackbuckFade;
  late Animation<Offset> _blackbuckSlide;

  late Animation<double> _recentFade;

  // Idle Floating Animation for Hero Truck
  late Animation<double> _heroTruckFloat;
  late Animation<double> _handWaveAngle;

  @override
  void initState() {
    super.initState();

    // 1. Entrance Controller (1200ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 2. Idle Floating Controller (2.4s repeat)
    _idleFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // 3. Hand Wave Controller (1.2s, 3 wave cycles)
    _handWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Header Slide & Fade
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.40, curve: Curves.easeIn),
      ),
    );
    _headerSlide = Tween<Offset>(begin: const Offset(0.0, -0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOutCubic),
      ),
    );

    // Search Bar
    _searchFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.12, 0.48, curve: Curves.easeIn),
      ),
    );
    _searchSlide = Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.12, 0.48, curve: Curves.easeOutCubic),
      ),
    );

    // Hero Banner Scale & Fade
    _heroScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.20, 0.58, curve: Curves.easeOutBack),
      ),
    );
    _heroFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.20, 0.54, curve: Curves.easeIn),
      ),
    );

    // 1. E-Commerce (1st: Right-to-Left Slide & Fade)
    _ecomFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.30, 0.60, curve: Curves.easeIn),
      ),
    );
    _ecomSlide = Tween<Offset>(begin: const Offset(0.40, 0.0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.30, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Rides / Uber (2nd: Right-to-Left Slide & Fade)
    _rideFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.42, 0.72, curve: Curves.easeIn),
      ),
    );
    _rideSlide = Tween<Offset>(begin: const Offset(0.40, 0.0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.42, 0.72, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Truck & Courier (3rd: Right-to-Left Slide & Fade)
    _courierFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.54, 0.84, curve: Curves.easeIn),
      ),
    );
    _courierSlide = Tween<Offset>(begin: const Offset(0.40, 0.0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.54, 0.84, curve: Curves.easeOutCubic),
      ),
    );

    // 4. BlackBuck (4th: Right-to-Left Slide & Fade)
    _blackbuckFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.66, 0.96, curve: Curves.easeIn),
      ),
    );
    _blackbuckSlide = Tween<Offset>(begin: const Offset(0.40, 0.0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.66, 0.96, curve: Curves.easeOutCubic),
      ),
    );

    // Recent Activity Fade
    _recentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.72, 1.0, curve: Curves.easeIn),
      ),
    );

    // Hero Truck Floating Oscillation
    _heroTruckFloat = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(
        parent: _idleFloatController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Hand wave rotation sequence
    _handWaveAngle = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.25), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.25, end: -0.20), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: -0.20, end: 0.15), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: 0.15, end: 0.0), weight: 25),
    ]).animate(
      CurvedAnimation(
        parent: _handWaveController,
        curve: Curves.easeInOut,
      ),
    );

    _entranceController.forward();
    _handWaveController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _idleFloatController.dispose();
    _handWaveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ChangeNotifierProvider(
          create: (_) => DashboardViewModel(),
          child: Consumer<DashboardViewModel>(
            builder: (context, vm, child) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Header: "Good Morning, John 👋" & Notification + Avatar
                    FadeTransition(
                      opacity: _headerFade,
                      child: SlideTransition(
                        position: _headerSlide,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Good Morning,',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Text(
                                      'John',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    AnimatedBuilder(
                                      animation: _handWaveController,
                                      builder: (context, child) => Transform.rotate(
                                        angle: _handWaveAngle.value,
                                        alignment: Alignment.bottomRight,
                                        child: child,
                                      ),
                                      child: const Text('👋', style: TextStyle(fontSize: 20)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                // Notification Button
                                GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('No new notifications'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        const Icon(
                                          Icons.notifications_none_rounded,
                                          color: Color(0xFF1E293B),
                                          size: 22,
                                        ),
                                        Positioned(
                                          top: 10,
                                          right: 11,
                                          child: Container(
                                            width: 7,
                                            height: 7,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFEF4444),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // User Avatar -> Navigates to Profile
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, ProfileView.routeName);
                                  },
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/images/home_user_avatar.png',
                                        fit: BoxFit.cover,
                                        filterQuality: FilterQuality.high,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.person_rounded,
                                          color: Color(0xFF4F46E5),
                                          size: 26,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2. Search Bar
                    FadeTransition(
                      opacity: _searchFade,
                      child: SlideTransition(
                        position: _searchSlide,
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.search_rounded,
                                color: Color(0xFF94A3B8),
                                size: 22,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search services...',
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 3. Hero Banner: "Faster Delivery for Your Business" with Floating Animated Truck
                    FadeTransition(
                      opacity: _heroFade,
                      child: ScaleTransition(
                        scale: _heroScale,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, PorterHomeView.routeName);
                          },
                          child: Container(
                            width: double.infinity,
                            height: 140,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Faster Delivery\nfor Your Business',
                                          style: TextStyle(
                                            color: Color(0xFF1E1B4B),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            height: 1.25,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4F46E5),
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Text(
                                                'Ship Now',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 3D HD Clean Truck Image with Floating Suspension Animation
                                  Expanded(
                                    flex: 5,
                                    child: Center(
                                      child: AnimatedBuilder(
                                        animation: _heroTruckFloat,
                                        builder: (context, child) => Transform.translate(
                                          offset: Offset(0, _heroTruckFloat.value),
                                          child: child,
                                        ),
                                        child: Image.asset(
                                          'assets/images/cooli_truck_splash_hd.png',
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.high,
                                          errorBuilder: (_, __, ___) => Image.asset(
                                            'assets/images/splash_truck_clean.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 4. 2x2 Service Cards Grid with Staggered Right-to-Left Cascade Entrance
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.96,
                      children: [
                        // 1. E-Commerce (1st: Right-to-Left Slide & Levitation)
                        FadeTransition(
                          opacity: _ecomFade,
                          child: SlideTransition(
                            position: _ecomSlide,
                            child: _InteractiveServiceCard(
                              title: 'E-Commerce',
                              subtitle: 'Sand & Bricks',
                              imagePath: 'assets/images/dash_ecom_bricks_clean.png',
                              fallbackIcon: Icons.view_in_ar_rounded,
                              bgColor: const Color(0xFFFFF7ED),
                              borderColor: const Color(0xFFFFEDD5),
                              textColor: const Color(0xFFC2410C),
                              animationType: CardAnimationType.ecom,
                              onTap: () => Navigator.pushNamed(context, EcommerceHomeView.routeName),
                            ),
                          ),
                        ),

                        // 2. Rides / Uber (2nd: Right-to-Left Slide & Cruising Glide)
                        FadeTransition(
                          opacity: _rideFade,
                          child: SlideTransition(
                            position: _rideSlide,
                            child: _InteractiveServiceCard(
                              title: 'Rides',
                              subtitle: 'Cabs & Auto',
                              imagePath: 'assets/images/dash_ride_car_clean.png',
                              fallbackIcon: Icons.directions_car_filled_rounded,
                              bgColor: const Color(0xFFF0FDF4),
                              borderColor: const Color(0xFFDCFCE7),
                              textColor: const Color(0xFF15803D),
                              animationType: CardAnimationType.ride,
                              onTap: () => Navigator.pushNamed(context, RideBookingView.routeName),
                            ),
                          ),
                        ),

                        // 3. Truck & Courier (3rd: Right-to-Left Slide & Suspension Hop)
                        FadeTransition(
                          opacity: _courierFade,
                          child: SlideTransition(
                            position: _courierSlide,
                            child: _InteractiveServiceCard(
                              title: 'Truck & Courier',
                              subtitle: 'Mini-Trucks & Cargo',
                              imagePath: 'assets/images/dash_courier_van_clean.png',
                              fallbackIcon: Icons.local_shipping_rounded,
                              bgColor: const Color(0xFFEFF6FF),
                              borderColor: const Color(0xFFDBEAFE),
                              textColor: const Color(0xFF1D4ED8),
                              animationType: CardAnimationType.courier,
                              onTap: () => Navigator.pushNamed(context, PorterHomeView.routeName),
                            ),
                          ),
                        ),

                        // 4. BlackBuck (4th: Right-to-Left Slide & Heavy Diesel Rumble)
                        FadeTransition(
                          opacity: _blackbuckFade,
                          child: SlideTransition(
                            position: _blackbuckSlide,
                            child: _InteractiveServiceCard(
                              title: 'BlackBuck',
                              subtitle: 'Full Truckload (FTL)',
                              imagePath: 'assets/images/dash_blackbuck_clean.png',
                              fallbackIcon: Icons.local_shipping_rounded,
                              bgColor: const Color(0xFFF0FDFA),
                              borderColor: const Color(0xFFCCFBF1),
                              textColor: const Color(0xFF0F766E),
                              animationType: CardAnimationType.truck,
                              onTap: () => Navigator.pushNamed(context, ServicesHomeView.routeName),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 5. Recent Activity Header & List with Smooth Fade
                    FadeTransition(
                      opacity: _recentFade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Activity',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, ActivityView.routeName);
                                },
                                child: const Text(
                                  'See all',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Activity List Card
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Column(
                                children: [
                                  _buildActivityTile(
                                    context: context,
                                    icon: Icons.inventory_2_outlined,
                                    title: 'Sand Order #S1234',
                                    status: 'Delivered',
                                    time: '2h ago',
                                    onTap: () {
                                      Navigator.pushNamed(context, ActivityView.routeName);
                                    },
                                  ),
                                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                                  _buildActivityTile(
                                    context: context,
                                    icon: Icons.local_taxi_outlined,
                                    title: 'Ride to Airport',
                                    status: 'Completed',
                                    time: 'Yesterday',
                                    onTap: () {
                                      Navigator.pushNamed(context, ActivityView.routeName);
                                    },
                                  ),
                                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                                  _buildActivityTile(
                                    context: context,
                                    icon: Icons.local_shipping_outlined,
                                    title: 'Truck & Courier #TC882',
                                    status: 'In Transit',
                                    time: '22 Apr',
                                    onTap: () {
                                      Navigator.pushNamed(context, ActivityView.routeName);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String status,
    required String time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF475569)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$status • $time',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}

enum CardAnimationType { ecom, ride, courier, truck }

/// Interactive Card Widget with Smooth Spring Scale Physics and Dedicated Vehicle Animations
class _InteractiveServiceCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final IconData fallbackIcon;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final CardAnimationType animationType;
  final VoidCallback onTap;

  const _InteractiveServiceCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.fallbackIcon,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.animationType,
    required this.onTap,
  });

  @override
  State<_InteractiveServiceCard> createState() => _InteractiveServiceCardState();
}

class _InteractiveServiceCardState extends State<_InteractiveServiceCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animController;
  late Animation<double> _primaryAnim;
  late Animation<double> _secondaryAnim;

  @override
  void initState() {
    super.initState();

    switch (widget.animationType) {
      case CardAnimationType.ecom:
        // E-Commerce: Smooth isometric floating + gentle pulse
        _animController = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2200),
        )..repeat(reverse: true);

        _primaryAnim = Tween<double>(begin: -4.0, end: 4.0).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
        );
        _secondaryAnim = Tween<double>(begin: 0.98, end: 1.03).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
        );
        break;

      case CardAnimationType.ride:
        // Rides: Smooth driving cruise glide (horizontal drift) + slight cornering tilt
        _animController = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2400),
        )..repeat(reverse: true);

        _primaryAnim = Tween<double>(begin: -4.0, end: 4.0).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
        );
        _secondaryAnim = Tween<double>(begin: -0.028, end: 0.028).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
        );
        break;

      case CardAnimationType.courier:
        // Courier: Express delivery van suspension bounce & parcel hop
        _animController = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1700),
        )..repeat(reverse: true);

        _primaryAnim = Tween<double>(begin: -5.0, end: 2.0).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeInOutQuad),
        );
        _secondaryAnim = Tween<double>(begin: -0.015, end: 0.02).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
        );
        break;

      case CardAnimationType.truck:
        // BlackBuck Truck: Heavy diesel engine rumble & heavy payload suspension sway
        _animController = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2800),
        )..repeat(reverse: true);

        _primaryAnim = Tween<double>(begin: -2.5, end: 2.5).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
        );
        _secondaryAnim = Tween<double>(begin: -0.018, end: 0.018).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
        );
        break;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedImage() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        Widget animatedWidget = child!;

        switch (widget.animationType) {
          case CardAnimationType.ecom:
            // Floating vertical translate + subtle scale breath
            animatedWidget = Transform.translate(
              offset: Offset(0, _primaryAnim.value),
              child: Transform.scale(
                scale: _secondaryAnim.value,
                child: child,
              ),
            );
            break;

          case CardAnimationType.ride:
            // Horizontal cruising glide + subtle steering tilt
            animatedWidget = Transform.translate(
              offset: Offset(_primaryAnim.value, 0),
              child: Transform.rotate(
                angle: _secondaryAnim.value,
                child: child,
              ),
            );
            break;

          case CardAnimationType.courier:
            // Dynamic suspension bounce + slight forward lean
            animatedWidget = Transform.translate(
              offset: Offset(0, _primaryAnim.value),
              child: Transform.rotate(
                angle: _secondaryAnim.value,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            );
            break;

          case CardAnimationType.truck:
            // Slow heavy vertical sway + solid chassis pitch
            animatedWidget = Transform.translate(
              offset: Offset(0, _primaryAnim.value),
              child: Transform.rotate(
                angle: _secondaryAnim.value,
                alignment: Alignment.center,
                child: child,
              ),
            );
            break;
        }

        return animatedWidget;
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          widget.imagePath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => Icon(
            widget.fallbackIcon,
            size: 44,
            color: widget.textColor.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isPressed
                  ? widget.borderColor.withValues(alpha: 0.9)
                  : widget.borderColor,
              width: _isPressed ? 1.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.borderColor.withValues(alpha: _isPressed ? 0.6 : 0.35),
                blurRadius: _isPressed ? 14 : 8,
                offset: Offset(0, _isPressed ? 2 : 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3D Visual Artwork with Custom Micro-Animation
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                    child: _buildAnimatedImage(),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.textColor.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
