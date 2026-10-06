import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/auth/view_model/auth_view_model.dart';
import 'package:cooli/features/dashboard/view/main_navigation_view.dart';

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
  static const int _otpLength = 6;

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

    _floatAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(
        parent: _illustrationController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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

  void _handleVerify() async {
    final otp = _getOtp();
    if (otp.length < _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter all 6 digits of the OTP code'),
          backgroundColor: const Color(0xFF4355E8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final phone = widget.phoneNumber ??
        (ModalRoute.of(context)?.settings.arguments as String?) ??
        '+91 98765 43210';

    final success = await _viewModel.verifyOtp(phone, otp);
    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        MainNavigationView.routeName,
        (route) => false,
      );
    }
  }

  void _onDigitChanged(String value, int index) {
    // Check if pasted full OTP
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.isNotEmpty) {
        for (int i = 0; i < _otpLength; i++) {
          if (i < digits.length) {
            _controllers[i].text = digits[i];
          }
        }
        final targetIndex = (digits.length < _otpLength) ? digits.length : _otpLength - 1;
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
    final phoneDisplay = widget.phoneNumber ??
        (ModalRoute.of(context)?.settings.arguments as String?) ??
        '+91 98765 43210';

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Top-right soft lavender cloud/blob
            Positioned(
              top: -50,
              right: -40,
              child: IgnorePointer(
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFEDE9FE).withValues(alpha: 0.8),
                        const Color(0xFFEDE9FE).withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.65, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom flowing lavender organic waves
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 230,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _OtpBottomWavesPainter(),
                ),
              ),
            ),

            // Foreground Content
            SafeArea(
              child: Consumer<AuthViewModel>(
                builder: (context, vm, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 12),

                          // Top bar (Back button if route can pop, unobtrusively positioned)
                          SizedBox(
                            height: 40,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Navigator.canPop(context)
                                  ? GestureDetector(
                                      onTap: () => Navigator.maybePop(context),
                                      child: Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.05),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.arrow_back_ios_new_rounded,
                                            size: 15,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),

                          const SizedBox(height: 10),

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

                          const SizedBox(height: 24),

                          // Title: "Verify Your Number"
                          const Text(
                            'Verify Your Number',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E2432),
                              letterSpacing: -0.4,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Subtitle: "We've sent a 6 digit code to"
                          const Text(
                            "We've sent a 6 digit code to",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8A94A6),
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
                              color: Color(0xFF1E2432),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // 6 OTP Input Boxes
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_otpLength, (index) {
                              final isFilled =
                                  _controllers[index].text.isNotEmpty;
                              final isFocused = _focusNodes[index].hasFocus;

                              return Container(
                                width: 46,
                                height: 56,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isFocused
                                        ? const Color(0xFF4355E8)
                                        : isFilled
                                            ? const Color(0xFFCBD5E1)
                                            : const Color(0xFFE2E8F0),
                                    width: isFocused ? 1.8 : 1.2,
                                  ),
                                  boxShadow: isFocused
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF4355E8)
                                                .withValues(alpha: 0.18),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.04),
                                            blurRadius: 8,
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
                                      fontSize: 21,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E2432),
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
                                    onSubmitted: (_) {
                                      if (index < _otpLength - 1) {
                                        _focusNodes[index + 1].requestFocus();
                                      } else {
                                        _focusNodes[index].unfocus();
                                      }
                                    },
                                  ),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 28),

                          // Resend Code in 00:30 (exact style as screenshot)
                          GestureDetector(
                            onTap: _resendSeconds == 0
                                ? () {
                                    _startResendTimer();
                                    final phone = widget.phoneNumber ??
                                        (ModalRoute.of(context)
                                                ?.settings
                                                .arguments as String?) ??
                                        '+91 98765 43210';
                                    _viewModel.sendOtp(phone);
                                  }
                                : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_resendSeconds > 0) ...[
                                  const Text(
                                    'Resend code in ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4355E8),
                                    ),
                                  ),
                                  Text(
                                    '00:${_resendSeconds.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF4355E8),
                                    ),
                                  ),
                                ] else ...[
                                  const Text(
                                    "Didn't receive code? ",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF8A94A6),
                                    ),
                                  ),
                                  const Text(
                                    'Resend OTP',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4355E8),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 38),

                          // "Verify ->" Button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF4355E8),
                                  Color(0xFF3B66F5),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4355E8)
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
                                                letterSpacing: 0.2,
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

                          const SizedBox(height: 32),
                        ],
                      ),
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

    // Layer 1: Background Soft Lavender Wave (rises higher on the right)
    final backPaint = Paint()
      ..color = const Color(0xFFEDE9FE).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final backPath = Path()
      ..moveTo(0, h * 0.72)
      ..cubicTo(
        w * 0.25,
        h * 0.88,
        w * 0.50,
        h * 0.60,
        w * 0.78,
        h * 0.42,
      )
      ..cubicTo(
        w * 0.90,
        h * 0.32,
        w * 0.96,
        h * 0.28,
        w,
        h * 0.25,
      )
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(backPath, backPaint);

    // Layer 2: Middle Soft Violet Wave
    final midPaint = Paint()
      ..color = const Color(0xFFDDD6FE).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final midPath = Path()
      ..moveTo(0, h * 0.86)
      ..cubicTo(
        w * 0.20,
        h * 0.65,
        w * 0.45,
        h * 0.82,
        w * 0.70,
        h * 0.55,
      )
      ..cubicTo(
        w * 0.82,
        h * 0.42,
        w * 0.92,
        h * 0.48,
        w,
        h * 0.50,
      )
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(midPath, midPaint);

    // Layer 3: Foreground Delicate Violet Swell
    final frontPaint = Paint()
      ..color = const Color(0xFFC4B5FD).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final frontPath = Path()
      ..moveTo(0, h * 0.92)
      ..cubicTo(
        w * 0.30,
        h * 0.96,
        w * 0.55,
        h * 0.76,
        w * 0.82,
        h * 0.78,
      )
      ..cubicTo(
        w * 0.92,
        h * 0.80,
        w * 0.98,
        h * 0.75,
        w,
        h * 0.72,
      )
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(frontPath, frontPaint);
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
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background soft blob
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEDE9FE).withValues(alpha: 0.7),
            ),
          ),
          // Phone outline
          Positioned(
            top: 20,
            left: 45,
            child: Container(
              width: 95,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
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
                  width: 80,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFFEDE9FE),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.security_rounded,
                      size: 42,
                      color: Color(0xFF4355E8),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Shield in foreground
          Positioned(
            bottom: 22,
            right: 25,
            child: Container(
              width: 56,
              height: 62,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
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
