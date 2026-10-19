import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/dashboard/view_model/dashboard_view_model.dart';
import 'package:cooli/features/ecommerce/view/ecommerce_home_view.dart';
import 'package:cooli/features/ride/view/ride_booking_view.dart';
import 'package:cooli/features/porter/view/porter_home_view.dart';
import 'package:cooli/features/services/view/blackbuck_find_loads_view.dart';
import 'package:cooli/features/services/view/blackbuck_vehicle_selection_view.dart';
import 'package:cooli/features/profile/view/profile_view.dart';
import 'package:cooli/features/profile/view_model/profile_view_model.dart';
import 'package:cooli/features/auth/model/auth_model.dart';
import 'package:cooli/features/auth/view_model/auth_view_model.dart';
import 'package:cooli/features/dashboard/model/dashboard_model.dart';
import 'package:cooli/services/session_manager.dart';

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

  String _cachedUserName = SessionManager.inMemoryUserName;

  // Hero Carousel State & Auto-Scroll
  late final PageController _bannerController;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  static const List<_HomeBannerItem> _bannerItems = [
    _HomeBannerItem(
      tag: 'EXPRESS LOGISTICS',
      title: 'Faster Delivery\nfor Your Business',
      buttonText: 'Ship Now',
      imagePath: 'assets/images/cooli_truck_splash_hd.png',
      fallbackImagePath: 'assets/images/splash_truck_clean.png',
      gradientColors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
      accentColor: Color(0xFF4F46E5),
      textColor: Color(0xFF1E1B4B),
      tagBgColor: Color(0xFFE0E7FF),
      tagTextColor: Color(0xFF4338CA),
      routeName: PorterHomeView.routeName,
    ),
    _HomeBannerItem(
      tag: 'CABS & AUTOS',
      title: 'Instant Rides &\nCity Travel',
      buttonText: 'Book Ride',
      imagePath: 'assets/images/dash_ride_car_clean.png',
      fallbackImagePath: 'assets/images/ride_white_car.png',
      gradientColors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
      accentColor: Color(0xFF16A34A),
      textColor: Color(0xFF14532D),
      tagBgColor: Color(0xFFDCFCE7),
      tagTextColor: Color(0xFF15803D),
      routeName: RideBookingView.routeName,
    ),
    _HomeBannerItem(
      tag: 'INTERCITY FREIGHT',
      title: 'Full Truckload\nHire & Transport',
      buttonText: 'Hire Truck',
      imagePath: 'assets/images/dash_blackbuck_clean.png',
      fallbackImagePath: 'assets/images/cooli_truck_exact.png',
      gradientColors: [Color(0xFFF0FDFA), Color(0xFFCCFBF1)],
      accentColor: Color(0xFF0D9488),
      textColor: Color(0xFF134E4A),
      tagBgColor: Color(0xFFCCFBF1),
      tagTextColor: Color(0xFF0F766E),
      routeName: BlackbuckFindLoadsView.routeName,
    ),
    _HomeBannerItem(
      tag: 'CONSTRUCTION SUPPLIES',
      title: 'Order Construction\nMaterials Directly',
      buttonText: 'Shop Now',
      imagePath: 'assets/images/dash_ecom_bricks_clean.png',
      fallbackImagePath: 'assets/images/brick_clean_hd.png',
      gradientColors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
      accentColor: Color(0xFFEA580C),
      textColor: Color(0xFF7C2D12),
      tagBgColor: Color(0xFFFFEDD5),
      tagTextColor: Color(0xFFC2410C),
      routeName: EcommerceHomeView.routeName,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    _startBannerTimer();
    _loadInitialUserName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashboardViewModel>().refreshUserData();
        context.read<ProfileViewModel>().loadUser();
      }
    });

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
    _headerSlide =
        Tween<Offset>(begin: const Offset(0.0, -0.3), end: Offset.zero).animate(
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
    _searchSlide =
        Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(
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
    _ecomSlide =
        Tween<Offset>(begin: const Offset(0.40, 0.0), end: Offset.zero).animate(
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
    _rideSlide =
        Tween<Offset>(begin: const Offset(0.40, 0.0), end: Offset.zero).animate(
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
    _courierSlide =
        Tween<Offset>(begin: const Offset(0.40, 0.0), end: Offset.zero).animate(
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
    _blackbuckSlide =
        Tween<Offset>(begin: const Offset(0.40, 0.0), end: Offset.zero).animate(
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
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 0.25), weight: 20),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.25, end: -0.20), weight: 30),
      TweenSequenceItem(
          tween: Tween<double>(begin: -0.20, end: 0.15), weight: 25),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.15, end: 0.0), weight: 25),
    ]).animate(
      CurvedAnimation(
        parent: _handWaveController,
        curve: Curves.easeInOut,
      ),
    );

    _entranceController.forward();
    _handWaveController.forward();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(milliseconds: 3800), (timer) {
      if (!mounted || !_bannerController.hasClients) return;
      final nextIndex = (_currentBannerIndex + 1) % _bannerItems.length;
      _bannerController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _entranceController.dispose();
    _idleFloatController.dispose();
    _handWaveController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialUserName() async {
    try {
      final name = await SessionManager().getUserName();
      if (name != null &&
          name.trim().isNotEmpty &&
          name.trim().toLowerCase() != 'user' &&
          mounted) {
        setState(() {
          _cachedUserName = name.trim();
        });
        return;
      }

      final saved = await SessionManager().getSavedUser();
      if (saved != null &&
          saved.fullName.trim().isNotEmpty &&
          saved.fullName.trim().toLowerCase() != 'user' &&
          mounted) {
        setState(() {
          _cachedUserName = saved.fullName.trim();
        });
        return;
      }
    } catch (e) {
      debugPrint('[HomeView] _loadInitialUserName error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Consumer<DashboardViewModel>(
          builder: (context, vm, child) {
            // 1. SharedPreferences / SessionManager in-memory name
            final spName = _cachedUserName.isNotEmpty
                ? _cachedUserName
                : SessionManager.inMemoryUserName;

            // 2. AuthViewModel logged-in user from Login / Register API
            UserModel? authUser;
            try {
              authUser = context.watch<AuthViewModel>().currentUser;
            } catch (_) {}

            // 3. ProfileViewModel user
            UserModel? profileUser;
            try {
              profileUser = context.watch<ProfileViewModel>().user;
            } catch (_) {}

            String rawName = '';
            if (spName.isNotEmpty && spName.toLowerCase() != 'user') {
              rawName = spName;
            } else if (authUser?.fullName != null &&
                authUser!.fullName.trim().isNotEmpty &&
                authUser.fullName.trim().toLowerCase() != 'user') {
              rawName = authUser.fullName.trim();
            } else if (vm.userName.isNotEmpty &&
                vm.userName.toLowerCase() != 'user') {
              rawName = vm.userName;
            } else if (profileUser?.fullName != null &&
                profileUser!.fullName.trim().isNotEmpty &&
                profileUser.fullName.trim().toLowerCase() != 'user') {
              rawName = profileUser.fullName.trim();
            }

            if (rawName.isEmpty || rawName.toLowerCase() == 'user') {
              rawName = 'User';
            }

            final displayName = rawName.split(RegExp(r'\s+')).map((word) {
              if (word.isEmpty) return '';
              return '${word[0].toUpperCase()}${word.substring(1)}';
            }).join(' ');

              return RefreshIndicator(
                  color: const Color(0xFF2563EB),
                  onRefresh: () async {
                    try {
                      await context.read<ProfileViewModel>().loadUser();
                    } catch (_) {}
                    await Future.wait([
                      vm.refreshUserData(),
                      vm.fetchHomeScreen(),
                    ]);
                    await _loadInitialUserName();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Top Header: "Good Morning" & User Name 👋 & Notification + Avatar
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
                                    Text(
                                      _getTimeBasedGreeting(),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.55,
                                          ),
                                          child: Text(
                                            displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF0F172A),
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        AnimatedBuilder(
                                          animation: _handWaveController,
                                          builder: (context, child) =>
                                              Transform.rotate(
                                            angle: _handWaveAngle.value,
                                            alignment: Alignment.bottomRight,
                                            child: child,
                                          ),
                                          child: const Text('👋',
                                              style: TextStyle(fontSize: 20)),
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
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('No new notifications'),
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
                                          border: Border.all(
                                              color: const Color(0xFFE2E8F0)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.04),
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
                                      onTap: () async {
                                        await Navigator.pushNamed(
                                            context, ProfileView.routeName);
                                        if (mounted) {
                                          _loadInitialUserName();
                                          vm.refreshUserData();
                                        }
                                      },
                                      child: Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: const Color(0xFFE2E8F0),
                                              width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.04),
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
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
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

                        // 3. Hero Carousel: 4 Animated Service Banners with Floating Suspension & Indicator Dots
                        FadeTransition(
                          opacity: _heroFade,
                          child: ScaleTransition(
                            scale: _heroScale,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 142,
                                  child: PageView.builder(
                                    controller: _bannerController,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentBannerIndex = index;
                                      });
                                    },
                                    itemCount: _bannerItems.length,
                                    itemBuilder: (context, index) {
                                      final item = _bannerItems[index];
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(
                                              context, item.routeName);
                                        },
                                        child: Container(
                                          width: double.infinity,
                                          height: 142,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: item.gradientColors,
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(22),
                                            boxShadow: [
                                              BoxShadow(
                                                color: item.accentColor
                                                    .withValues(alpha: 0.10),
                                                blurRadius: 14,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0,
                                                vertical: 14.0),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 6,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        item.title,
                                                        style: TextStyle(
                                                          color: item.textColor,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          height: 1.25,
                                                          letterSpacing: -0.3,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 12),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 14,
                                                                vertical: 6),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              item.accentColor,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: item
                                                                  .accentColor
                                                                  .withValues(
                                                                      alpha:
                                                                          0.3),
                                                              blurRadius: 6,
                                                              offset:
                                                                  const Offset(
                                                                      0, 2),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              item.buttonText,
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
                                                            const Icon(
                                                              Icons
                                                                  .arrow_forward_rounded,
                                                              size: 12,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // 3D HD Clean Asset with Floating Suspension Animation
                                                Expanded(
                                                  flex: 5,
                                                  child: Center(
                                                    child: AnimatedBuilder(
                                                      animation:
                                                          _heroTruckFloat,
                                                      builder:
                                                          (context, child) =>
                                                              Transform
                                                                  .translate(
                                                        offset: Offset(
                                                            0,
                                                            _heroTruckFloat
                                                                .value),
                                                        child: child,
                                                      ),
                                                      child: Image.asset(
                                                        item.imagePath,
                                                        fit: BoxFit.contain,
                                                        filterQuality:
                                                            FilterQuality.high,
                                                        errorBuilder:
                                                            (_, __, ___) =>
                                                                item.fallbackImagePath !=
                                                                        null
                                                                    ? Image
                                                                        .asset(
                                                                        item.fallbackImagePath!,
                                                                        fit: BoxFit
                                                                            .contain,
                                                                      )
                                                                    : const SizedBox
                                                                        .shrink(),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Modern Animated Carousel Dots Indicator
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    _bannerItems.length,
                                    (dotIndex) {
                                      final isSelected =
                                          dotIndex == _currentBannerIndex;
                                      return AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3),
                                        width: isSelected ? 22 : 6,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? _bannerItems[
                                                      _currentBannerIndex]
                                                  .accentColor
                                              : const Color(0xFFCBD5E1),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
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
                            // 2. Rides / Uber (2nd: Right-to-Left Slide & Cruising Glide)
                            FadeTransition(
                              opacity: _rideFade,
                              child: SlideTransition(
                                position: _rideSlide,
                                child: _InteractiveServiceCard(
                                  title: 'Rides',
                                  subtitle: 'Cabs & Auto',
                                  imagePath:
                                      'assets/images/dash_ride_car_clean.png',
                                  fallbackIcon:
                                      Icons.directions_car_filled_rounded,
                                  bgColor: const Color(0xFFF0FDF4),
                                  borderColor: const Color(0xFFDCFCE7),
                                  textColor: const Color(0xFF15803D),
                                  animationType: CardAnimationType.ride,
                                  onTap: () => Navigator.pushNamed(
                                      context, RideBookingView.routeName),
                                ),
                              ),
                            ),

                            // 3. Truck & Courier (3rd: Right-to-Left Slide & Suspension Hop)
                            FadeTransition(
                              opacity: _courierFade,
                              child: SlideTransition(
                                position: _courierSlide,
                                child: _InteractiveServiceCard(
                                  title: "Your Consignment",
                                  // title: 'Truck & Courier',
                                  subtitle: 'Mini-Trucks & Cargo',
                                  imagePath:
                                      'assets/images/dash_courier_van_clean.png',
                                  fallbackIcon: Icons.local_shipping_rounded,
                                  bgColor: const Color(0xFFEFF6FF),
                                  borderColor: const Color(0xFFDBEAFE),
                                  textColor: const Color(0xFF1D4ED8),
                                  animationType: CardAnimationType.courier,
                                  onTap: () => Navigator.pushNamed(
                                      context, PorterHomeView.routeName),
                                ),
                              ),
                            ),

                            // 4. BlackBuck (4th: Right-to-Left Slide & Heavy Diesel Rumble)
                            FadeTransition(
                              opacity: _blackbuckFade,
                              child: SlideTransition(
                                position: _blackbuckSlide,
                                child: _InteractiveServiceCard(
                                  title: 'Hire Truck',
                                  subtitle: 'Full Truckload (FTL)',
                                  imagePath:
                                      'assets/images/dash_blackbuck_clean.png',
                                  fallbackIcon: Icons.local_shipping_rounded,
                                  bgColor: const Color(0xFFF0FDFA),
                                  borderColor: const Color(0xFFCCFBF1),
                                  textColor: const Color(0xFF0F766E),
                                  animationType: CardAnimationType.truck,
                                  onTap: () => Navigator.pushNamed(context,
                                      BlackbuckFindLoadsView.routeName),
                                ),
                              ),
                            ),
                            // 1. E-Commerce (1st: Right-to-Left Slide & Levitation)
                            FadeTransition(
                              opacity: _ecomFade,
                              child: SlideTransition(
                                position: _ecomSlide,
                                child: _InteractiveServiceCard(
                                  title: 'E-Commerce',
                                  subtitle: 'Sand & Bricks',
                                  imagePath:
                                      'assets/images/dash_ecom_bricks_clean.png',
                                  fallbackIcon: Icons.view_in_ar_rounded,
                                  bgColor: const Color(0xFFFFF7ED),
                                  borderColor: const Color(0xFFFFEDD5),
                                  textColor: const Color(0xFFC2410C),
                                  animationType: CardAnimationType.ecom,
                                  onTap: () => Navigator.pushNamed(
                                      context, EcommerceHomeView.routeName),
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
                              // Row(
                              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              //   children: [
                              //     const Text(
                              //       'Activity & Orders',
                              //       style: TextStyle(
                              //         fontSize: 17,
                              //         fontWeight: FontWeight.w800,
                              //         color: Color(0xFF0F172A),
                              //         letterSpacing: -0.3,
                              //       ),
                              //     ),
                              //     GestureDetector(
                              //       onTap: () {
                              //         Navigator.pushNamed(
                              //             context, ActivityView.routeName);
                              //       },
                              //       child: const Text(
                              //         'See all',
                              //         style: TextStyle(
                              //           fontSize: 13,
                              //           fontWeight: FontWeight.w700,
                              //           color: Color(0xFF4F46E5),
                              //         ),
                              //       ),
                              //     ),
                              //   ],
                              // ),

                              const SizedBox(height: 12),

                              // Activity List Card
                              // Container(
                              //   decoration: BoxDecoration(
                              //     color: Colors.white,
                              //     borderRadius: BorderRadius.circular(20),
                              //     border:
                              //         Border.all(color: const Color(0xFFE2E8F0)),
                              //     boxShadow: [
                              //       BoxShadow(
                              //         color: Colors.black.withValues(alpha: 0.03),
                              //         blurRadius: 10,
                              //         offset: const Offset(0, 2),
                              //       ),
                              //     ],
                              //   ),
                              //   clipBehavior: Clip.antiAlias,
                              //   child: vm.recentActivities.isEmpty
                              //       ? Padding(
                              //           padding: const EdgeInsets.symmetric(
                              //               vertical: 24.0),
                              //           child: Center(
                              //             child: Text(
                              //               'No recent activity yet',
                              //               style: TextStyle(
                              //                 fontSize: 13,
                              //                 color: Colors.grey.shade500,
                              //                 fontWeight: FontWeight.w500,
                              //               ),
                              //             ),
                              //           ),
                              //         )
                              //       : ListView.separated(
                              //           shrinkWrap: true,
                              //           physics:
                              //               const NeverScrollableScrollPhysics(),
                              //           padding: const EdgeInsets.symmetric(
                              //               vertical: 4.0),
                              //           itemCount: vm.recentActivities.length,
                              //           separatorBuilder: (context, index) =>
                              //               const Divider(
                              //             color: Color(0xFFF1F5F9),
                              //             height: 1,
                              //             indent: 16,
                              //             endIndent: 16,
                              //           ),
                              //           itemBuilder: (context, index) {
                              //             final item = vm.recentActivities[index];
                              //             return _buildActivityTile(
                              //               context: context,
                              //               item: item,
                              //               onTap: () {
                              //                 Navigator.pushNamed(
                              //                     context, ActivityView.routeName);
                              //               },
                              //             );
                              //           },
                              //         ),
                              // ),

                              const SizedBox(height: 28),

                              // 6. Available Fleets & Services from API GET /api/home/ (Below Recent Activity)
                              _buildHomeServicesSection(context, vm),

                              const SizedBox(height: 28),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ));
            },
          ),
      ),
    );
  }

  Widget _buildActivityTile({
    required BuildContext context,
    RecentActivityItem? item,
    IconData? icon,
    String? title,
    String? status,
    String? time,
    Color? iconColor,
    double? amount,
    required VoidCallback onTap,
  }) {
    final displayIcon = item?.icon ?? icon ?? Icons.history;
    final displayColor =
        item?.iconColor ?? iconColor ?? const Color(0xFF475569);
    final displayTitle = item?.title ?? title ?? '';
    final displayStatus = item?.status ?? status ?? '';
    final displayTime = item?.time ?? time ?? '';
    final displayAmount = item?.amount ?? amount ?? 0.0;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: displayColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(displayIcon, size: 20, color: displayColor),
        ),
        title: Text(
          displayTitle,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(
            '$displayStatus • $displayTime',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (displayAmount > 0)
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Text(
                  '₹${displayAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
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

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildHomeServicesSection(
      BuildContext context, DashboardViewModel vm) {
    final homeData = vm.homeData;
    final services = homeData.services;

    // Filter services according to user filter (0 = All, 8 = Ride, 9 = Goods, 10 = Transport)
    final filteredServices = vm.selectedFleetFilter == 0
        ? services
        : services.where((s) => s.id == vm.selectedFleetFilter).toList();

    // Total vehicles count
    int totalVehicles = 0;
    for (final s in services) {
      totalVehicles += s.vehicleTypes.length;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Live indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Recent activity',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // const Text(
                //   'Book passenger rides, local goods delivery, or freight transport',
                //   style: TextStyle(
                //     fontSize: 12,
                //     color: Color(0xFF64748B),
                //     fontWeight: FontWeight.w500,
                //   ),
                // ),
              ],
            ),
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                size: 20,
                color: vm.isHomeDataLoading
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFF94A3B8),
              ),
              onPressed: () => vm.fetchHomeScreen(),
              tooltip: 'Refresh API Fleets',
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Filter Pills Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFleetFilterChip(
                label: 'All Fleets ($totalVehicles)',
                icon: Icons.dashboard_customize_rounded,
                isSelected: vm.selectedFleetFilter == 0,
                onTap: () => vm.setSelectedFleetFilter(0),
              ),
              const SizedBox(width: 8),
              ...services.map((s) {
                final isSelected = vm.selectedFleetFilter == s.id;
                final icon = s.name.toLowerCase() == 'ride'
                    ? Icons.directions_car_rounded
                    : (s.name.toLowerCase() == 'goods'
                        ? Icons.local_shipping_outlined
                        : Icons.rv_hookup_rounded);
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _buildFleetFilterChip(
                    label: '${s.displayName} (${s.vehicleTypes.length})',
                    icon: icon,
                    isSelected: isSelected,
                    onTap: () => vm.setSelectedFleetFilter(s.id),
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Services & Vehicle Types converted to ListTile List
        if (filteredServices.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No activity available right now',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          )
        else
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
            clipBehavior: Clip.antiAlias,
            child: Builder(
              builder: (context) {
                final allItems = <_HomeVehicleListItem>[];
                for (final service in filteredServices) {
                  final accentColor = service.name.toLowerCase() == 'ride'
                      ? const Color(0xFF2563EB)
                      : (service.name.toLowerCase() == 'goods'
                          ? const Color(0xFF10B981)
                          : const Color(0xFF8B5CF6));
                  for (final vehicle in service.vehicleTypes) {
                    allItems.add(_HomeVehicleListItem(
                      service: service,
                      vehicle: vehicle,
                      accentColor: accentColor,
                    ));
                  }
                }

                if (allItems.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        'No items available',
                        style:
                            TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  itemCount: allItems.length,
                  separatorBuilder: (context, index) => const Divider(
                    color: Color(0xFFF1F5F9),
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final item = allItems[index];
                    return _buildVehicleListTile(
                      context: context,
                      service: item.service,
                      vehicle: item.vehicle,
                      accentColor: item.accentColor,
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFleetFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleListTile({
    required BuildContext context,
    required HomeServiceItem service,
    required HomeVehicleTypeItem vehicle,
    required Color accentColor,
  }) {
    final imagePath = _getVehicleImagePath(vehicle.name);
    final fallbackIcon = _getVehicleFallbackIcon(vehicle.name);

    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: () =>
            _navigateToService(context, service.name, vehicleName: vehicle.name),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        leading: Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: imagePath != null
              ? Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    fallbackIcon,
                    color: accentColor,
                    size: 24,
                  ),
                )
              : Center(
                  child: Icon(
                    fallbackIcon,
                    color: accentColor,
                    size: 24,
                  ),
                ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                vehicle.name,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                service.displayName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3.0),
          child: Text(
            vehicle.description.isNotEmpty
                ? vehicle.description
                : 'Available for immediate booking',
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Book',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.arrow_forward_rounded,
                size: 13,
                color: accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _getVehicleImagePath(String vehicleName) {
    final name = vehicleName.toLowerCase();
    if (name.contains('auto')) return 'assets/images/rickshaw_3d.png';
    if (name == 'car') return 'assets/images/car_3d.png';
    if (name.contains('premium'))
      return 'assets/images/dash_ride_car_clean.png';
    if (name.contains('bmw')) return 'assets/images/suv_3d.png';
    if (name.contains('mini truck')) return 'assets/images/pickup_3d.png';
    if (name.contains('pickup')) return 'assets/images/pickup_3d.png';
    if (name.contains('tata ace')) return 'assets/images/lorry_3d.png';
    if (name.contains('small truck')) return 'assets/images/truck_3d.png';
    if (name.contains('medium truck')) return 'assets/images/truck_3d.png';
    if (name.contains('large truck'))
      return 'assets/images/splash_truck_clean.png';
    if (name.contains('container'))
      return 'assets/images/dash_blackbuck_clean.png';
    if (name.contains('trailer'))
      return 'assets/images/dash_blackbuck_clean.png';
    return null;
  }

  IconData _getVehicleFallbackIcon(String vehicleName) {
    final name = vehicleName.toLowerCase();
    if (name.contains('bike')) return Icons.two_wheeler_rounded;
    if (name.contains('auto')) return Icons.electric_rickshaw_rounded;
    if (name == 'car') return Icons.directions_car_rounded;
    if (name.contains('premium') || name.contains('bmw'))
      return Icons.car_rental_rounded;
    if (name.contains('pickup') ||
        name.contains('mini') ||
        name.contains('tata')) {
      return Icons.local_shipping_rounded;
    }
    if (name.contains('truck')) return Icons.local_shipping_rounded;
    if (name.contains('container') || name.contains('trailer')) {
      return Icons.rv_hookup_rounded;
    }
    return Icons.directions_car_filled_rounded;
  }

  void _navigateToService(BuildContext context, String serviceName,
      {String? vehicleName}) {
    final sName = serviceName.toLowerCase();
    if (sName == 'ride') {
      Navigator.pushNamed(context, RideBookingView.routeName);
    } else if (sName == 'goods') {
      Navigator.pushNamed(context, PorterHomeView.routeName);
    } else if (sName == 'transport') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BlackbuckVehicleSelectionView(),
        ),
      );
    }
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
  State<_InteractiveServiceCard> createState() =>
      _InteractiveServiceCardState();
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
                color: widget.borderColor
                    .withValues(alpha: _isPressed ? 0.6 : 0.35),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4.0, vertical: 2.0),
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

class _HomeVehicleListItem {
  final HomeServiceItem service;
  final HomeVehicleTypeItem vehicle;
  final Color accentColor;

  const _HomeVehicleListItem({
    required this.service,
    required this.vehicle,
    required this.accentColor,
  });
}

class _HomeBannerItem {
  final String tag;
  final String title;
  final String buttonText;
  final String imagePath;
  final String? fallbackImagePath;
  final List<Color> gradientColors;
  final Color accentColor;
  final Color textColor;
  final Color tagBgColor;
  final Color tagTextColor;
  final String routeName;

  const _HomeBannerItem({
    required this.tag,
    required this.title,
    required this.buttonText,
    required this.imagePath,
    this.fallbackImagePath,
    required this.gradientColors,
    required this.accentColor,
    required this.textColor,
    required this.tagBgColor,
    required this.tagTextColor,
    required this.routeName,
  });
}
