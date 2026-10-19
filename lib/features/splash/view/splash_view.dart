import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/auth/view_model/auth_view_model.dart';
import 'package:cooli/features/splash/view_model/splash_view_model.dart';
import 'package:cooli/features/onboarding/view/onboarding_view.dart';
import 'package:cooli/features/dashboard/view/main_navigation_view.dart';

class SplashView extends StatefulWidget {
  static const String routeName = '/splash';

  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late SplashViewModel _viewModel;
  late AnimationController _entranceController;
  late AnimationController _idleController;

  // Staggered Animations
  late Animation<Offset> _bar1Anim;
  late Animation<Offset> _bar2Anim;
  late Animation<Offset> _bar3Anim;
  late Animation<double> _titleScale;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;
  late Animation<Offset> _subtitleSlide;

  // Truck Animations
  late Animation<Offset> _truckSlide;
  late Animation<double> _truckScale;
  late Animation<double> _truckFade;
  late Animation<double> _truckBrakeTilt;

  // Idle and Particle Animations
  late Animation<double> _idleFloat;
  late Animation<double> _shadowScale;
  late Animation<double> _ambientGlow;
  late Animation<double> _waveProgress;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;

  Timer? _navTimer;
  bool _hasNavigated = false;
  bool _didInitSplash = false;

  @override
  void initState() {
    super.initState();

    // 1. Entrance Controller (1.6s)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // 2. Idle Suspension & Breathing Controller (2.4s loop)
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Speed bars staggered slide from left
    _bar1Anim =
        Tween<Offset>(begin: const Offset(-2.5, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );
    _bar2Anim =
        Tween<Offset>(begin: const Offset(-3.0, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.08, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _bar3Anim =
        Tween<Offset>(begin: const Offset(-3.5, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.16, 0.65, curve: Curves.easeOutBack),
      ),
    );

    // Brand Title Pop & Fade
    _titleScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.5, curve: Curves.easeIn),
      ),
    );

    // Subtitle
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeIn),
      ),
    );
    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    // 3D Truck Entrance (Drives smoothly from right to left into center)
    _truckSlide =
        Tween<Offset>(begin: const Offset(1.1, 0.0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.20, 0.82, curve: Curves.easeOutCubic),
      ),
    );
    _truckScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.20, 0.82, curve: Curves.easeOutBack),
      ),
    );
    _truckFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.20, 0.55, curve: Curves.easeIn),
      ),
    );

    // Physics Braking Tilt (settles naturally when decelerating from right to left)
    _truckBrakeTilt = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 0.032), weight: 40),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.032, end: -0.010), weight: 35),
      TweenSequenceItem(
          tween: Tween<double>(begin: -0.010, end: 0.0), weight: 25),
    ]).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.40, 0.90, curve: Curves.easeInOut),
      ),
    );

    // Wave Rise
    _waveProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.85, curve: Curves.easeOutQuart),
      ),
    );

    // Tagline Entrance
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 0.95, curve: Curves.easeIn),
      ),
    );
    _taglineSlide =
        Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 0.95, curve: Curves.easeOutBack),
      ),
    );

    // Idle floating suspension oscillation (Simulates running engine suspension)
    _idleFloat = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(
        parent: _idleController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Coordinated shadow scaling
    _shadowScale = Tween<double>(begin: 1.06, end: 0.92).animate(
      CurvedAnimation(
        parent: _idleController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Ambient halo glow pulsing
    _ambientGlow = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _idleController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Start Entrance and subsequent Idle loop
    _entranceController.forward().then((_) {
      if (mounted) {
        _idleController.repeat(reverse: true);
      }
    });

    // Auto navigate with smooth transition after 3.2s
    _navTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        _handleNavigation();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel = context.read<SplashViewModel>();
    if (!_didInitSplash) {
      _didInitSplash = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _viewModel.initSplash();
      });
    }
  }

  void _handleNavigation() async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final authVm = context.read<AuthViewModel>();
    final canAutoLogin = await authVm.tryAutoLogin();
    if (!mounted) return;

    if (canAutoLogin) {
      // User is already logged in with saved token: proceed to main app
      Navigator.of(context).pushNamedAndRemoveUntil(
        MainNavigationView.routeName,
        (route) => false,
      );
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        OnboardingView.routeName,
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _entranceController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Bottom Organic Wave Decoration
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _waveProgress,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(screenSize.width, 220 * _waveProgress.value),
                  painter: _SplashBottomWavePainter(),
                );
              },
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 36),

                // 2. Top Logo & Title with Staggered Animations
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 3-tier Staggered Speed Bars
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SlideTransition(
                                position: _bar1Anim,
                                child: Container(
                                  width: 34,
                                  height: 5.5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2563EB)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4.5),
                              SlideTransition(
                                position: _bar2Anim,
                                child: Container(
                                  width: 26,
                                  height: 5.5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF38BDF8),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4.5),
                              SlideTransition(
                                position: _bar3Anim,
                                child: Container(
                                  width: 18,
                                  height: 5.5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF60A5FA),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Brand Name
                          ScaleTransition(
                            scale: _titleScale,
                            child: FadeTransition(
                              opacity: _titleFade,
                              child: const Text(
                                'Cooli',
                                style: TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2563EB),
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      SlideTransition(
                        position: _subtitleSlide,
                        child: FadeTransition(
                          opacity: _subtitleFade,
                          child: const Text(
                            'Your Everyday Logistics Partner',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // 3. Center Enhanced 3D Delivery Truck with Smooth Physics & Suspension
                SlideTransition(
                  position: _truckSlide,
                  child: ScaleTransition(
                    scale: _truckScale,
                    child: FadeTransition(
                      opacity: _truckFade,
                      child: AnimatedBuilder(
                        animation: _entranceController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _truckBrakeTilt.value,
                            child: child,
                          );
                        },
                        child: AnimatedBuilder(
                          animation: _idleFloat,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Soft Ambient Radial Aura Behind Truck
                                Positioned(
                                  child: Container(
                                    width: screenSize.width * 0.76,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          const Color(0xFF38BDF8).withValues(
                                            alpha: 0.18 * _ambientGlow.value,
                                          ),
                                          const Color(0xFF6366F1).withValues(
                                            alpha: 0.08 * _ambientGlow.value,
                                          ),
                                          Colors.transparent,
                                        ],
                                        radius: 0.85,
                                      ),
                                    ),
                                  ),
                                ),

                                // Dynamic Ground Shadow beneath wheels
                                Positioned(
                                  bottom: 12,
                                  child: Transform.scale(
                                    scaleX: _shadowScale.value,
                                    scaleY: 1.0,
                                    child: Container(
                                      width: screenSize.width * 0.72,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.12 * _shadowScale.value,
                                        ),
                                        borderRadius: BorderRadius.all(
                                          Radius.elliptical(
                                              screenSize.width * 0.72, 22),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.12 * _shadowScale.value,
                                            ),
                                            blurRadius: 18,
                                            spreadRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // The 3D High-Definition Truck Graphic with Idle Float
                                Transform.translate(
                                  offset: Offset(0, _idleFloat.value),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Image.asset(
                                      'assets/images/cooli_truck_splash_hd.png',
                                      width: screenSize.width * 0.88,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                      errorBuilder: (_, __, ___) => Image.asset(
                                        'assets/images/splash_truck_clean.png',
                                        width: screenSize.width * 0.88,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // 4. Bottom Tagline with Fade & Slide inside Wave
                SlideTransition(
                  position: _taglineSlide,
                  child: FadeTransition(
                    opacity: _taglineFade,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 36.0),
                      child: Text(
                        'Faster   •   Safer   •   Smarter',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.9),
                          letterSpacing: 0.9,
                        ),
                      ),
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
}

class _SplashBottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 0) return;

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFDCE2FC),
          Color(0xFFE9ECFD),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height * 0.40);
    path.cubicTo(
      size.width * 0.30,
      size.height * 0.42,
      size.width * 0.65,
      size.height * 0.78,
      size.width,
      size.height * 0.66,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
