import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/auth/model/auth_model.dart';
import 'package:cooli/features/profile/view_model/profile_view_model.dart';
import 'package:cooli/features/profile/view/edit_profile_view.dart';
import 'package:cooli/features/auth/view/login_view.dart';
import 'package:cooli/services/session_manager.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';
import 'package:cooli/features/wallet/view/wallet_view.dart';
import 'package:cooli/features/ecommerce/view/my_orders_view.dart';
import 'package:cooli/features/services/view/my_shipments_view.dart';
import 'package:cooli/features/ride/view/my_rides_view.dart';
import 'package:cooli/features/services/view/my_bookings_view.dart';
import 'package:cooli/features/address/view/saved_addresses_view.dart';
import 'package:cooli/features/address/view_model/address_view_model.dart';

class ProfileView extends StatefulWidget {
  static const String routeName = '/profile';

  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileViewModel>().loadUser();
        context.read<AddressViewModel>().fetchAddresses();
      }
    });
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.pushNamed(
      context,
      EditProfileView.routeName,
    );
    if (updated == true && mounted) {
      context.read<ProfileViewModel>().loadUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CooliColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: CooliColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<ProfileViewModel>(
        builder: (context, vm, child) {
          final user = vm.user;
          final displayName = (user?.fullName != null &&
                  user!.fullName.trim().isNotEmpty &&
                  user.fullName.trim() != 'User')
              ? user.fullName.trim()
              : 'Coolie User';

          final displayPhone =
              (user?.phoneNumber != null && user!.phoneNumber.trim().isNotEmpty)
                  ? user.phoneNumber.trim()
                  : 'Mobile not available';

          final initials =
              displayName.isNotEmpty && displayName != 'Coolie User'
                  ? displayName[0].toUpperCase()
                  : (displayPhone.isNotEmpty &&
                          displayPhone != 'Mobile not available'
                      ? displayPhone
                          .replaceAll(RegExp(r'[^0-9]'), '')
                          .characters
                          .takeLast(1)
                          .first
                      : 'C');

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                context.read<ProfileViewModel>().loadUser(),
                context.read<AddressViewModel>().fetchAddresses(),
              ]);
            },
            color: CooliColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
              child: Column(
                children: [
                  // User Info Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: CooliShadows.card,
                      border: Border.all(
                          color: CooliColors.border.withValues(alpha: 0.8)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _openEditProfile,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: CooliColors.primaryGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: CooliColors.primary
                                          .withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _buildProfileAvatar(user, initials),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            displayName,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              color: CooliColors.textDark,
                                              letterSpacing: -0.2,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.verified_rounded,
                                          size: 16,
                                          color: CooliColors.primary,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.phone_iphone_rounded,
                                          size: 14,
                                          color: CooliColors.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          displayPhone,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: CooliColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: CooliColors.primary
                                      .withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.edit_outlined,
                                      color: CooliColors.primary, size: 19),
                                  tooltip: 'Edit Profile',
                                  onPressed: _openEditProfile,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Saved Addresses Quick Preview Card
                  _buildAddressPreviewCard(context),

                  const SizedBox(height: 16),

                  // Menu Items Container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: CooliShadows.card,
                      border: Border.all(
                          color: CooliColors.border.withValues(alpha: 0.8)),
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          Icons.person_outline_rounded,
                          'Edit Profile',
                          CooliColors.primary,
                          subtitle: 'Name, email, phone & address',
                          onTap: _openEditProfile,
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          Icons.inventory_2_outlined,
                          'My Orders',
                          CooliColors.ecommerceOrange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyOrdersView(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          Icons.local_shipping_outlined,
                          'My Shipments',
                          CooliColors.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyBookingsView(),
                              ),
                            );
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) => const MyShipmentsView(),
                            //   ),
                            // );
                          },
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          Icons.directions_car_outlined,
                          'My Rides',
                          CooliColors.rideBlue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyRidesView(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          Icons.build_outlined,
                          'My Bookings',
                          const Color(0xFF0D9488),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyShipmentsView(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        Consumer<AddressViewModel>(
                          builder: (context, addressVM, child) {
                            final count = addressVM.addresses.length;
                            final defaultAddr = addressVM.defaultAddress;
                            final subtitle = defaultAddr != null
                                ? '${defaultAddr.typeDisplay}: ${defaultAddr.addressLine1}'
                                : (count > 0
                                    ? '$count addresses saved'
                                    : 'Add delivery address');

                            return _buildMenuItem(
                              Icons.location_on_outlined,
                              'Addresses',
                              Colors.purple,
                              subtitle: subtitle,
                              trailingBadge: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SavedAddressesView(),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildMenuItem(Icons.credit_card_outlined,
                            'Payment Methods', Colors.indigo),
                        _buildDivider(),
                        _buildMenuItem(
                          Icons.account_balance_wallet_outlined,
                          'Wallet',
                          Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WalletView(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildMenuItem(Icons.notifications_none_rounded,
                            'Notifications', Colors.amber.shade800),
                        _buildDivider(),
                        _buildMenuItem(Icons.help_outline_rounded,
                            'Help & Support', Colors.blueGrey),
                        _buildDivider(),
                        _buildMenuItem(Icons.settings_outlined, 'Settings',
                            Colors.grey.shade700),
                        _buildDivider(),
                        _buildMenuItem(
                          Icons.logout_rounded,
                          'Logout',
                          CooliColors.danger,
                          isDanger: true,
                          onTap: _handleLogout,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: CooliColors.danger, size: 24),
            SizedBox(width: 10),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: CooliColors.textDark,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your Cooli account?',
          style: TextStyle(
            fontSize: 14,
            color: CooliColors.textMuted,
            height: 1.4,
          ),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: CooliColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CooliColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await SessionManager().clearSession();
      if (!mounted) return;
      showCooliToast(
        context,
        message: 'Logged out successfully',
        icon: Icons.check_circle_outline_rounded,
        iconColor: CooliColors.success,
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginView.routeName,
        (route) => false,
      );
    }
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    Color iconColor, {
    bool isDanger = false,
    Widget? trailingBadge,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {},
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 18.0, vertical: 13.0),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 21),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isDanger ? FontWeight.w700 : FontWeight.w600,
                          color: isDanger
                              ? CooliColors.danger
                              : CooliColors.textDark,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: CooliColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailingBadge != null) ...[
                  trailingBadge,
                  const SizedBox(width: 8),
                ],
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDanger ? CooliColors.danger : CooliColors.textLight,
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildAddressPreviewCard(BuildContext context) {
    return Consumer<AddressViewModel>(
      builder: (context, addressVM, child) {
        final addresses = addressVM.addresses;
        final defaultAddress = addressVM.defaultAddress;
        final count = addresses.length;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: CooliShadows.card,
            border: Border.all(
              color: CooliColors.border.withValues(alpha: 0.8),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedAddressesView(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: Icon, Title, Count Badge & Manage Arrow
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.purple,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delivery Addresses',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: CooliColors.textDark,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Primary location for orders & rides',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: CooliColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.purple.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$count',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.purple,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Saved',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: CooliColors.textLight,
                        ),
                      ],
                    ),

                    if (addressVM.isLoading && addresses.isEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                    ] else if (defaultAddress != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: CooliColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: defaultAddress.typeColor
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        defaultAddress.typeIcon,
                                        size: 12,
                                        color: defaultAddress.typeColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        defaultAddress.typeDisplay,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: defaultAddress.typeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (defaultAddress.isDefault) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.green.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'DEFAULT',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.green,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                const Text(
                                  'Manage',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              defaultAddress.addressLine1,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: CooliColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${defaultAddress.city}, ${defaultAddress.state} - ${defaultAddress.postalCode}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: CooliColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: CooliColors.borderLight),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.add_location_alt_outlined,
                              size: 18,
                              color: CooliColors.textMuted,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No saved address yet',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: CooliColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '+ Add Address',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider() {
    return const Divider(
        height: 1, indent: 52, endIndent: 16, color: CooliColors.borderLight);
  }

  Widget _buildProfileAvatar(UserModel? user, String initials) {
    final photo = user?.profilePhoto;
    if (photo != null && photo.isNotEmpty) {
      if (File(photo).existsSync()) {
        return Image.file(
          File(photo),
          fit: BoxFit.cover,
          width: 58,
          height: 58,
        );
      }
      if (photo.startsWith('http')) {
        return Image.network(
          photo,
          fit: BoxFit.cover,
          width: 58,
          height: 58,
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
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
