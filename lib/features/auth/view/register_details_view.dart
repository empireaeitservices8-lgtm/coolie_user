import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/auth/model/auth_model.dart';
import 'package:cooli/features/auth/view_model/auth_view_model.dart';
import 'package:cooli/features/dashboard/view/main_navigation_view.dart';
import 'package:cooli/features/dashboard/view_model/dashboard_view_model.dart';
import 'package:cooli/features/profile/view_model/profile_view_model.dart';
import 'package:cooli/widgets/cooli_widgets.dart';

class RegisterDetailsView extends StatefulWidget {
  static const String routeName = '/register-details';
  final String? phoneNumber;
  final String? verifiedOtp;

  const RegisterDetailsView({
    super.key,
    this.phoneNumber,
    this.verifiedOtp,
  });

  @override
  State<RegisterDetailsView> createState() => _RegisterDetailsViewState();
}

class _RegisterDetailsViewState extends State<RegisterDetailsView> {
  late AuthViewModel _viewModel;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    for (var f in [_nameFocus, _addressFocus, _emailFocus]) {
      f.addListener(() => setState(() {}));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel = context.read<AuthViewModel>();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _nameFocus.dispose();
    _addressFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  RegisterDetailsArgs _getArgs() {
    final raw = ModalRoute.of(context)?.settings.arguments;
    if (raw is RegisterDetailsArgs) {
      return raw;
    } else if (raw is String) {
      return RegisterDetailsArgs(phoneNumber: raw);
    }
    return RegisterDetailsArgs(
      phoneNumber: widget.phoneNumber ?? '+919876543210',
      verifiedOtp: widget.verifiedOtp,
    );
  }

  Widget _buildFormField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final isFocused = focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFocused ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
              width: isFocused ? 1.8 : 1.2,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines > 1 ? 12 : 10),
          child: Row(
            crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: maxLines > 1 ? 2 : 0),
                child: Icon(
                  prefixIcon,
                  size: 20,
                  color: isFocused ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(
                      filled: false,
                      fillColor: Colors.transparent,
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: keyboardType,
                    maxLines: maxLines,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleRegister() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final email = _emailController.text.trim();
    final args = _getArgs();

    if (name.isEmpty) {
      showCooliToast(
        context,
        message: 'Please enter your name',
        icon: Icons.error_outline_rounded,
        iconColor: Colors.redAccent,
      );
      return;
    }

    if (address.isEmpty) {
      showCooliToast(
        context,
        message: 'Please enter your address',
        icon: Icons.error_outline_rounded,
        iconColor: Colors.redAccent,
      );
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      showCooliToast(
        context,
        message: 'Please enter a valid email address',
        icon: Icons.error_outline_rounded,
        iconColor: Colors.redAccent,
      );
      return;
    }

    final request = RegisterRequest(
      name: name,
      mobileNumber: args.phoneNumber,
      email: email,
      address: address,
    );

    final res = await _viewModel.register(request: request);
    if (!mounted) return;

    if (res.success) {
      showCooliToast(
        context,
        message: res.message,
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF10B981),
      );

      try {
        await context.read<ProfileViewModel>().loadUser();
        await context.read<DashboardViewModel>().refreshUserData();
      } catch (e) {
        debugPrint('Error syncing providers on register: $e');
      }

      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final args = _getArgs();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
            // Top Right & Bottom Decorative Organic Lavender Shapes
            Positioned(
              top: -60,
              right: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE4E8FB).withValues(alpha: 0.7),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE4E8FB).withValues(alpha: 0.6),
                ),
              ),
            ),

            SafeArea(
              child: Consumer<AuthViewModel>(
                builder: (context, vm, child) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),

                        // Back Button
                        GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            width: 40,
                            height: 40,
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

                        const SizedBox(height: 18),

                        // Title & Subtitle
                        const Text(
                          'Complete Profile',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Enter your name, address, and email to finish registration.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Verified Phone Number Pill Badge Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF86EFAC),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Mobile Number Verified',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                    Text(
                                      args.phoneNumber,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF14532D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.verified_rounded,
                                color: Color(0xFF22C55E),
                                size: 20,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 1. Full Name Field
                        _buildFormField(
                          label: 'Full Name *',
                          hintText: 'e.g. Aslam',
                          controller: _nameController,
                          focusNode: _nameFocus,
                          prefixIcon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 16),

                        // 2. Address Field
                        _buildFormField(
                          label: 'Address *',
                          hintText: 'e.g. Ernakulam',
                          controller: _addressController,
                          focusNode: _addressFocus,
                          prefixIcon: Icons.location_on_outlined,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        // 3. Email Field
                        _buildFormField(
                          label: 'Email Address *',
                          hintText: 'e.g. aslam@example.com',
                          controller: _emailController,
                          focusNode: _emailFocus,
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 20),

                        // Terms & Privacy Agreement Checkbox
                        Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: vm.agreeToTerms,
                                activeColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                onChanged: (val) => vm.setAgreeToTerms(val ?? false),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF64748B),
                                  ),
                                  children: [
                                    TextSpan(text: 'I agree to the '),
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(text: ' & '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Register CTA Button
                        Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF4338CA)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(27),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(27),
                              onTap: vm.isLoading ? null : _handleRegister,
                              child: Center(
                                child: vm.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Register',
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
                                            size: 19,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
  }
}
