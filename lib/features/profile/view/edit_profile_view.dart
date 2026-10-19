import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/profile/view_model/profile_view_model.dart';
import 'package:cooli/features/dashboard/view_model/dashboard_view_model.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';

class EditProfileView extends StatefulWidget {
  static const String routeName = '/edit-profile';

  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();

  String? _selectedImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<ProfileViewModel>().user;
    final initialName = (user?.fullName != null &&
            user!.fullName.trim().isNotEmpty &&
            user.fullName.trim() != 'User')
        ? user.fullName.trim()
        : '';

    _nameController = TextEditingController(text: initialName);
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _selectedImagePath = user?.profilePhoto;

    _nameFocusNode.addListener(() => setState(() {}));
    _phoneFocusNode.addListener(() => setState(() {}));
    _emailFocusNode.addListener(() => setState(() {}));
    _addressFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _selectedImagePath = picked.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: CooliColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CooliColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: CooliColors.primary),
                  ),
                  title: const Text('Take Photo',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded,
                        color: Colors.green),
                  ),
                  title: const Text('Choose from Gallery',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: Colors.red),
                    ),
                    title: const Text('Remove Photo',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.red)),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedImagePath = '';
                      });
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty) {
      showCooliToast(
        context,
        message: 'Please enter your full name',
        icon: Icons.error_outline_rounded,
        iconColor: Colors.redAccent,
      );
      _nameFocusNode.requestFocus();
      return;
    }

    if (email.isNotEmpty && (!email.contains('@') || !email.contains('.'))) {
      showCooliToast(
        context,
        message: 'Please enter a valid email address',
        icon: Icons.error_outline_rounded,
        iconColor: Colors.redAccent,
      );
      _emailFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final success =
          await context.read<ProfileViewModel>().updateUserProfile(
                fullName: name,
                email: email,
                phoneNumber: phone,
                address: address,
                profilePhoto: _selectedImagePath,
              );

      if (mounted) {
        try {
          context.read<DashboardViewModel>().refreshUserData();
        } catch (_) {}

        if (success) {
          showCooliToast(
            context,
            message: 'Profile updated successfully',
            icon: Icons.check_circle_rounded,
            iconColor: CooliColors.success,
          );
          Navigator.pop(context, true);
        } else {
          showCooliToast(
            context,
            message: 'Could not update profile. Please try again.',
            icon: Icons.error_outline_rounded,
            iconColor: Colors.redAccent,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileViewModel>().user;
    final displayName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : (user?.fullName.isNotEmpty == true ? user!.fullName : 'User');

    final initials = displayName.isNotEmpty && displayName != 'User'
        ? displayName[0].toUpperCase()
        : 'C';

    return Scaffold(
      backgroundColor: CooliColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: CooliColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: CooliColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // 1. Avatar Picker Section
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: CooliColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: CooliColors.primary.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 3.5),
                        ),
                        child: ClipOval(
                          child: _buildAvatarImage(initials),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showImagePickerSheet,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: CooliColors.primary,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 17,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                TextButton(
                  onPressed: _showImagePickerSheet,
                  child: const Text(
                    'Change Profile Photo',
                    style: TextStyle(
                      color: CooliColors.primary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // 2. Personal Information Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: CooliShadows.card,
                    border: Border.all(
                      color: CooliColors.border.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: CooliColors.textDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Full Name
                      _buildFormField(
                        label: 'Full Name',
                        hintText: 'Enter your full name',
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        prefixIcon: Icons.person_outline_rounded,
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                      ),

                      const SizedBox(height: 16),

                      // Phone Number (with verified badge)
                      _buildFormField(
                        label: 'Mobile Number',
                        hintText: 'Enter your phone number',
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
                        prefixIcon: Icons.phone_iphone_rounded,
                        keyboardType: TextInputType.phone,
                        suffixWidget: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 13, color: Color(0xFF10B981)),
                              SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Email Address
                      _buildFormField(
                        label: 'Email Address',
                        hintText: 'Enter your email address',
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 16),

                      // Address
                      _buildFormField(
                        label: 'Home / Delivery Address',
                        hintText: 'Enter your primary address',
                        controller: _addressController,
                        focusNode: _addressFocusNode,
                        prefixIcon: Icons.location_on_outlined,
                        keyboardType: TextInputType.streetAddress,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 3. Save Changes Button
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: CooliColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: CooliColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isSaving ? null : _handleSave,
                      child: Center(
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_rounded,
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String initials) {
    if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty) {
      if (File(_selectedImagePath!).existsSync()) {
        return Image.file(
          File(_selectedImagePath!),
          fit: BoxFit.cover,
        );
      }
      if (_selectedImagePath!.startsWith('http')) {
        return Image.network(
          _selectedImagePath!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialsAvatar(initials),
        );
      }
    }
    return _buildInitialsAvatar(initials);
  }

  Widget _buildInitialsAvatar(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 38,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    Widget? suffixWidget,
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
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFocused ? CooliColors.primary : const Color(0xFFE2E8F0),
              width: isFocused ? 1.8 : 1.2,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: CooliColors.primary.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          padding: EdgeInsets.symmetric(
              horizontal: 14, vertical: maxLines > 1 ? 10 : 4),
          child: Row(
            crossAxisAlignment: maxLines > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: maxLines > 1 ? 6 : 0),
                child: Icon(
                  prefixIcon,
                  size: 20,
                  color: isFocused
                      ? CooliColors.primary
                      : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  textCapitalization: textCapitalization,
                  maxLines: maxLines,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: CooliColors.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              if (suffixWidget != null) ...[
                const SizedBox(width: 8),
                suffixWidget,
              ],
            ],
          ),
        ),
      ],
    );
  }
}
