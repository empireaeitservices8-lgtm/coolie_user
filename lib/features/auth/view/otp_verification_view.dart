import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/auth/model/auth_model.dart';
import 'package:cooli/features/auth/view_model/auth_view_model.dart';
import 'package:cooli/features/auth/view/register_details_view.dart';
import 'package:cooli/features/dashboard/view/main_navigation_view.dart';
import 'package:cooli/widgets/cooli_widgets.dart';

class OtpVerificationView extends StatefulWidget {
  static const String routeName = '/otp-verification';
  final String? phoneNumber;

  const OtpVerificationView({super.key, this.phoneNumber});

  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView>
    with TickerProviderStateMixin {
  late AuthViewModel _viewModel;
  static const int _otpLength = 4;

  late AnimationController _illustrationController;
  late AnimationController _fadeController;
  late Animation<double> _floatAnimation;
  late Animation<double> _fadeAnimation;

  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  int _resendSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _viewModel = AuthViewModel();
    _startResendTimer();

    _illustrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(
        parent: _illustrationController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });

    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  void _startResendTimer() {
    _resendSeconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        if (mounted) {
          setState(() {
            _resendSeconds--;
          });
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _illustrationController.dispose();
    _fadeController.dispose();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _getOtp() {
    return _controllers.map((c) => c.text).join();
  }

  OtpVerificationArgs _getArgs() {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    if (rawArgs is OtpVerificationArgs) {
      return rawArgs;
    } else if (rawArgs is String) {
      return OtpVerificationArgs(
        phoneNumber: rawArgs,
        isRegisterFlow: false,
      );
    }
    return OtpVerificationArgs(
      phoneNumber: widget.phoneNumber ?? '+91 98765 43210',
      isRegisterFlow: false,
    );
  }

  void _handleVerify() async {
    final otp = _getOtp();
    if (otp.length < _otpLength) {
      showCooliToast(
        context,
        message: 'Please enter all 4 digits of the OTP code',
        icon: Icons.error_outline_rounded,
        iconColor: Colors.redAccent,
      );
      return;
    }

    final args = _getArgs();

    if (args.isRegisterFlow) {
      // 1. If Register Flow: Verify OTP via POST /auth/verify-otp/, then proceed to enter Name, Address, Email
      final res = await _viewModel.verifyOtp(args.phoneNumber, otp);
      if (!mounted) return;

      if (res.success) {
        showCooliToast(
          context,
          message: res.message,
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF10B981),
        );

        Navigator.pushReplacementNamed(
          context,
          RegisterDetailsView.routeName,
          arguments: RegisterDetailsArgs(
            phoneNumber: res.mobileNumber ?? args.phoneNumber,
            verifiedOtp: otp,
          ),
        );
      } else {
        showCooliToast(
          context,
          message: res.message,
          icon: Icons.error_outline_rounded,
          iconColor: Colors.redAccent,
        );
      }
    } else {
      // 2. If Login Flow: complete login flow via POST /auth/login/
      final res = await _viewModel.login(
        args.phoneNumber,
        otp: otp,
      );
      if (!mounted) return;

      if (res.success) {
        showCooliToast(
          context,
          message: res.message,
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF10B981),
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          MainNavigationView.routeName,
          (route) => false,
        );
      } else {
        showCooliToast(
          context,
          message: res.message,
          icon: Icons.error_outline_rounded,
          iconColor: Colors.redAccent,
        );
      }
    }
  }

  void _handleResendOtp() async {
    if (_resendSeconds > 0) return;
    _startResendTimer();
    final args = _getArgs();
    final res = args.isRegisterFlow
        ? await _viewModel.sendOtp(args.phoneNumber)
        : await _viewModel.sendLoginOtp(args.phoneNumber);
    if (!mounted) return;
    showCooliToast(
      context,
      message: res.message,
      icon: Icons.mark_email_read_outlined,
      iconColor: const Color(0xFF3852E8),
    );
  }

  void _onDigitChanged(String value, int index) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.isNotEmpty) {
        for (int i = 0; i < _otpLength; i++) {
          if (i < digits.length) {
            _controllers[i].text = digits[i];
          }
        }
        final targetIndex =
            (digits.length < _otpLength) ? digits.length : _otpLength - 1;
        _focusNodes[targetIndex].requestFocus();
        setState(() {});
        if (digits.length >= _otpLength) {
          _handleVerify();
        }
        return;
      }
    }

    setState(() {});
    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_getOtp().length == _otpLength) {
          _handleVerify();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = _getArgs();
    final phoneDisplay = args.phoneNumber;

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Top-right organic lavender curve
            Positioned(
              top: 0,
              right: 0,
              width: 170,
              height: 140,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _OtpTopRightWavePainter(),
                ),
              ),
            ),

            // Bottom rich organic layered waves (pinned seamlessly to the bottom)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 220,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _OtpBottomWavesPainter(),
                ),
              ),
            ),

            // Main Content with LayoutBuilder for bottom pinning & keyboard friendliness
            SafeArea(
              child: Consumer<AuthViewModel>(
                builder: (context, vm, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Top & Middle Content
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Top Bar with back button
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Row(
                                          children: [
                                            if (Navigator.canPop(context))
                                              GestureDetector(
                                                onTap: () => Navigator.maybePop(context),
                                                child: Container(
                                                  width: 38,
                                                  height: 38,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF1F5F9),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.arrow_back_ios_new_rounded,
                                                      size: 16,
                                                      color: Color(0xFF1E293B),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // 3D Phone Shield Illustration
                                      AnimatedBuilder(
                                        animation: _floatAnimation,
                                        builder: (context, child) => Transform.translate(
                                          offset: Offset(0, _floatAnimation.value),
                                          child: child,
                                        ),
                                        child: Image.asset(
                                          'assets/images/cooli_otp_shield.png',
                                          width: 220,
                                          height: 220,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const _OtpPhoneIllustration(),
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      // Title: "Verify Your Number"
                                      const Text(
                                        'Verify Your Number',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF181E28),
                                          letterSpacing: -0.3,
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // Subtitle: "We've sent a 4 digit code to"
                                      const Text(
                                        "We've sent a 4 digit code to",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF8C96A6),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      // Phone Number: "+91 98765 43210"
                                      Text(
                                        phoneDisplay,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Color(0xFF181E28),
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
                                        ),
                                      ),

                                      const SizedBox(height: 26),

                                      // 4 OTP Input Boxes (Perfect spacious squircle boxes)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(_otpLength, (index) {
                                          final isFilled =
                                              _controllers[index].text.isNotEmpty;
                                          final isFocused = _focusNodes[index].hasFocus;

                                          return Container(
                                            width: 60,
                                            height: 60,
                                            margin: const EdgeInsets.symmetric(horizontal: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isFocused
                                                    ? const Color(0xFF3852E8)
                                                    : isFilled
                                                        ? const Color(0xFFC7D2FE)
                                                        : const Color(0xFFE2E8F0),
                                                width: isFocused ? 1.8 : 1.2,
                                              ),
                                              boxShadow: isFocused
                                                  ? [
                                                      BoxShadow(
                                                        color: const Color(0xFF3852E8)
                                                            .withValues(alpha: 0.18),
                                                        blurRadius: 10,
                                                        offset: const Offset(0, 3),
                                                      ),
                                                    ]
                                                  : [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withValues(alpha: 0.04),
                                                        blurRadius: 6,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                            ),
                                            child: Center(
                                              child: TextField(
                                                controller: _controllers[index],
                                                focusNode: _focusNodes[index],
                                                textAlign: TextAlign.center,
                                                textAlignVertical:
                                                    TextAlignVertical.center,
                                                keyboardType: TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.digitsOnly,
                                                ],
                                                maxLength: 1,
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF181E28),
                                                  height: 1.0,
                                                ),
                                                decoration: const InputDecoration(
                                                  counterText: '',
                                                  border: InputBorder.none,
                                                  enabledBorder: InputBorder.none,
                                                  focusedBorder: InputBorder.none,
                                                  errorBorder: InputBorder.none,
                                                  disabledBorder: InputBorder.none,
                                                  filled: false,
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.zero,
                                                ),
                                                onChanged: (val) =>
                                                    _onDigitChanged(val, index),
                                                onTap: () {
                                                  _controllers[index].selection =
                                                      TextSelection.fromPosition(
                                                    TextPosition(
                                                      offset:
                                                          _controllers[index].text.length,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          );
                                        }),
                                      ),

                                      const SizedBox(height: 22),

                                      // Resend code in 00:21
                                      GestureDetector(
                                        onTap: _resendSeconds == 0 ? _handleResendOtp : null,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              'Resend code in ',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF3852E8),
                                              ),
                                            ),
                                            Text(
                                              '00:${_resendSeconds.toString().padLeft(2, '0')}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF3852E8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Bottom Pinned CTA Button
                                  Padding(
                                    padding: const EdgeInsets.only(top: 32, bottom: 20),
                                    child: Container(
                                      width: double.infinity,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF3852E8),
                                            Color(0xFF4568F8),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF3852E8)
                                                .withValues(alpha: 0.38),
                                            blurRadius: 18,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(30),
                                          onTap: vm.isLoading ? null : _handleVerify,
                                          child: Center(
                                            child: vm.isLoading
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<Color>(
                                                        Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                : const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'Verify',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w700,
                                                          letterSpacing: 0.3,
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Icon(
                                                        Icons.arrow_forward_rounded,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                    ],
                                                  ),
                                          ),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Organic flowing layered lavender waves at the bottom matching reference
class _OtpBottomWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Layer 1: Background Soft Lavender Wave (rises prominently on the right)
    final backPaint = Paint()
      ..color = const Color(0xFFEDE5FF)
      ..style = PaintingStyle.fill;

    final backPath = Path()
      ..moveTo(0, h * 0.45)
      ..cubicTo(
        w * 0.22,
        h * 0.58,
        w * 0.45,
        h * 0.52,
        w * 0.68,
        h * 0.28,
      )
      ..cubicTo(
        w * 0.82,
        h * 0.10,
        w * 0.94,
        h * 0.12,
        w,
        h * 0.16,
      )
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(backPath, backPaint);

    // Layer 2: Middle Lilac Wave
    final midPaint = Paint()
      ..color = const Color(0xFFDCCEFF)
      ..style = PaintingStyle.fill;

    final midPath = Path()
      ..moveTo(0, h * 0.62)
      ..cubicTo(
        w * 0.20,
        h * 0.48,
        w * 0.38,
        h * 0.54,
        w * 0.55,
        h * 0.64,
      )
      ..cubicTo(
        w * 0.74,
        h * 0.38,
        w * 0.88,
        h * 0.28,
        w,
        h * 0.34,
      )
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(midPath, midPaint);

    // Layer 3: Foreground Deeper Pastel Violet Swell
    final frontPaint = Paint()
      ..color = const Color(0xFFC7B1FD)
      ..style = PaintingStyle.fill;

    final frontPath = Path()
      ..moveTo(0, h * 0.82)
      ..cubicTo(
        w * 0.32,
        h * 0.86,
        w * 0.58,
        h * 0.74,
        w * 0.78,
        h * 0.58,
      )
      ..cubicTo(
        w * 0.90,
        h * 0.50,
        w * 0.96,
        h * 0.54,
        w,
        h * 0.56,
      )
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(frontPath, frontPaint);

    // Subtle soft floating bubble at bottom left
    final dotPaint = Paint()
      ..color = const Color(0xFFDCCEFF).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(32, h - 28), 7, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Organic pastel lavender curve at top right corner matching reference
class _OtpTopRightWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = const Color(0xFFF1EAFF)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(w * 0.2, 0)
      ..cubicTo(
        w * 0.35,
        h * 0.45,
        w * 0.70,
        h * 0.85,
        w,
        h * 0.95,
      )
      ..lineTo(w, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Fallback illustration if asset cannot be found
class _OtpPhoneIllustration extends StatelessWidget {
  const _OtpPhoneIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEDE5FF).withValues(alpha: 0.7),
            ),
          ),
          Positioned(
            top: 20,
            left: 50,
            child: Container(
              width: 100,
              height: 155,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4338CA).withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 85,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: const Color(0xFFEDE9FE),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.security_rounded,
                      size: 44,
                      color: Color(0xFF3852E8),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 28,
            child: Container(
              width: 58,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4338CA).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
