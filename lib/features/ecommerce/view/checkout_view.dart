import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/ecommerce/view_model/ecommerce_view_model.dart';
import 'package:cooli/features/ecommerce/view/order_confirmed_view.dart';
import 'package:cooli/features/ride/view/ride_map_picker_view.dart';
import 'package:cooli/features/ride/service/ride_location_service.dart';
import 'package:cooli/features/address/model/address_model.dart';
import 'package:cooli/features/address/view_model/address_view_model.dart';
import 'package:cooli/features/address/view/add_address_view.dart';
import 'package:cooli/features/wallet/view_model/wallet_view_model.dart';
import 'package:cooli/features/wallet/view/wallet_view.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';

class CheckoutView extends StatefulWidget {
  static const String routeName = '/checkout';

  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WalletViewModel>().loadWalletData();
        final addressVM = context.read<AddressViewModel>();
        addressVM.fetchAddresses().then((_) {
          if (!mounted) return;
          final ecommerceVM = context.read<EcommerceViewModel>();
          if (!ecommerceVM.hasDeliveryAddress && addressVM.addresses.isNotEmpty) {
            final defaultAddr =
                addressVM.defaultAddress ?? addressVM.addresses.first;
            ecommerceVM.selectSavedAddress(defaultAddr);
          }
        });
      }
    });
  }

  Future<void> _navigateToAddAddress(EcommerceViewModel ecommerceVM) async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddAddressView(),
      ),
    );

    if (!mounted) return;
    if (added == true) {
      final addressVM = context.read<AddressViewModel>();
      await addressVM.fetchAddresses();
      if (!mounted) return;
      if (addressVM.addresses.isNotEmpty) {
        final newest = addressVM.addresses.first;
        ecommerceVM.selectSavedAddress(newest);
        showCooliToast(
          context,
          message: 'Address added and selected for delivery',
          icon: Icons.check_circle_outline_rounded,
          iconColor: CooliColors.success,
        );
      }
    }
  }

  Future<void> _deleteAddress(
      AddressModel address, EcommerceViewModel ecommerceVM) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded,
                color: CooliColors.danger, size: 22),
            SizedBox(width: 8),
            Text(
              'Remove Address?',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${address.addressLine1}" from your saved addresses?',
          style: const TextStyle(fontSize: 13, color: CooliColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: CooliColors.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CooliColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final addressVM = context.read<AddressViewModel>();
      final result = await addressVM.deleteAddress(address.id);
      if (!mounted) return;

      if (result.success) {
        // If the removed address was currently selected in checkout, update selection
        if (ecommerceVM.deliveryAddressId == address.id) {
          if (addressVM.addresses.isNotEmpty) {
            final next = addressVM.defaultAddress ?? addressVM.addresses.first;
            ecommerceVM.selectSavedAddress(next);
          } else {
            ecommerceVM.clearDeliveryAddress();
          }
        }
        showCooliToast(
          context,
          message: result.message,
          icon: Icons.check_circle_outline_rounded,
          iconColor: CooliColors.success,
        );
      } else {
        showCooliToast(
          context,
          message: result.message,
          icon: Icons.error_outline_rounded,
          iconColor: CooliColors.danger,
        );
      }
    }
  }

  Future<void> _pickAddressFromMap(EcommerceViewModel vm) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideMapPickerView(
          isPickup: true,
          singleLocationOnly: true,
          initialAddress: vm.deliveryAddressFull,
          initialLat: vm.deliveryLatitude,
          initialLng: vm.deliveryLongitude,
        ),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      if (result is LocationResult) {
        final title =
            result.title.isNotEmpty ? result.title : 'Delivery Location';
        final subtitle = result.subtitle;
        await vm.setDeliveryAddress(
          title: title,
          subtitle: subtitle,
          latitude: result.latitude,
          longitude: result.longitude,
        );
      } else if (result is RideMapSelectionResult) {
        final selected = result.selected;
        final title =
            selected.title.isNotEmpty ? selected.title : 'Delivery Location';
        final subtitle = selected.subtitle;
        await vm.setDeliveryAddress(
          title: title,
          subtitle: subtitle,
          latitude: selected.latitude,
          longitude: selected.longitude,
        );
      }
    }
  }

  Widget _buildStepIndicator(bool hasAddress) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepItem(1, 'Address', hasAddress, isActive: !hasAddress),
        _buildStepLine(hasAddress),
        _buildStepItem(2, 'Delivery', hasAddress),
        _buildStepLine(hasAddress),
        _buildStepItem(3, 'Payment', false, isActive: hasAddress),
        _buildStepLine(false),
        _buildStepItem(4, 'Review', false),
      ],
    );
  }

  Widget _buildStepItem(int step, String label, bool isDone,
      {bool isActive = false}) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone || isActive
                ? CooliColors.primary
                : CooliColors.surfaceAlt,
            border: Border.all(
              color:
                  isDone || isActive ? CooliColors.primary : CooliColors.border,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '$step',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : CooliColors.textMuted,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive || isDone ? FontWeight.w600 : FontWeight.w500,
            color: isActive || isDone
                ? CooliColors.primary
                : CooliColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isDone) {
    return Container(
      width: 28,
      height: 2,
      margin: const EdgeInsets.only(bottom: 14, left: 4, right: 4),
      color: isDone ? CooliColors.primary : CooliColors.border,
    );
  }

  Widget _buildAddressSection(BuildContext context, EcommerceViewModel vm) {
    return Consumer<AddressViewModel>(
      builder: (context, addressVM, child) {
        final addresses = addressVM.addresses;
        final isLoading = addressVM.isLoading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action bar: Add New Address & Pick on Map buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToAddAddress(vm),
                    icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                    label: const Text(
                      'Add New Address',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple,
                      side: const BorderSide(color: Colors.purple),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _pickAddressFromMap(vm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map_rounded,
                              size: 18, color: Color(0xFF2563EB)),
                          SizedBox(width: 6),
                          Text(
                            'Map',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (isLoading && addresses.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: CooliShadows.card,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.purple),
                  ),
                ),
              )
            else if (addresses.isEmpty && !vm.hasDeliveryAddress)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: CooliShadows.card,
                  border: Border.all(color: CooliColors.border),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_off_rounded,
                        color: Colors.purple,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No Delivery Address Found',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: CooliColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Add an address or pick from the map to proceed with checkout',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12, color: CooliColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToAddAddress(vm),
                      icon:
                          const Icon(Icons.add_location_alt_rounded, size: 16),
                      label: const Text('Add Address Now',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // List all saved addresses
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: addresses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = addresses[index];
                  final isSelected = vm.deliveryAddressId != null
                      ? vm.deliveryAddressId == item.id
                      : (vm.deliveryAddressTitle != null &&
                          vm.deliveryAddressTitle!.trim().toLowerCase() ==
                              item.addressLine1.trim().toLowerCase());

                  return _buildAddressCard(
                    item,
                    isSelected,
                    () => vm.selectSavedAddress(item),
                    () => _deleteAddress(item, vm),
                  );
                },
              ),

              // If an address was selected directly via Google Map that isn't in saved list
              if (vm.hasDeliveryAddress &&
                  !addresses.any((a) => a.id == vm.deliveryAddressId)) ...[
                const SizedBox(height: 10),
                _buildCustomMapSelectedCard(vm),
              ],
            ],
          ],
        );
      },
    );
  }

  Widget _buildAddressCard(
      AddressModel item, bool isSelected, VoidCallback onSelect, VoidCallback onDelete) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF16A34A) : CooliColors.border,
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : CooliShadows.card,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected ? const Color(0xFF16A34A) : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF16A34A)
                        : CooliColors.textLight,
                    width: isSelected ? 2 : 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: item.typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(item.typeIcon,
                                  size: 12, color: item.typeColor),
                              const SizedBox(width: 4),
                              Text(
                                item.typeDisplay,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: item.typeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (item.isDefault) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5),
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
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'DELIVER HERE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF15803D),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: 'Remove address',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: onDelete,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2)
                                      .withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.addressLine1,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: CooliColors.textDark,
                        height: 1.25,
                      ),
                    ),
                    if (item.addressLine2.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.addressLine2,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CooliColors.textMuted,
                        ),
                      ),
                    ],
                    if (item.landmark.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.landmark.toLowerCase().startsWith('near')
                            ? item.landmark
                            : 'Near ${item.landmark}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: CooliColors.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${item.city}, ${item.state} - ${item.postalCode}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: CooliColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomMapSelectedCard(EcommerceViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF16A34A), width: 1.8),
        boxShadow: CooliShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF16A34A),
            ),
            child: const Icon(Icons.check, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pin_drop_rounded,
                              size: 12, color: Color(0xFF2563EB)),
                          SizedBox(width: 4),
                          Text(
                            'Map Selected Spot',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'DELIVER HERE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF15803D),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Remove map selection',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () {
                            final addressVM = context.read<AddressViewModel>();
                            if (addressVM.addresses.isNotEmpty) {
                              vm.selectSavedAddress(
                                  addressVM.defaultAddress ??
                                      addressVM.addresses.first);
                            } else {
                              vm.clearDeliveryAddress();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2)
                                  .withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  vm.deliveryAddressTitle ?? 'Selected Location',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CooliColors.textDark,
                  ),
                ),
                if (vm.deliveryAddressSubtitle != null &&
                    vm.deliveryAddressSubtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    vm.deliveryAddressSubtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CooliColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CooliColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: CooliColors.textDark, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: CooliColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<EcommerceViewModel>(
        builder: (context, vm, child) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Steps Indicator
                      _buildStepIndicator(vm.hasDeliveryAddress),

                      const SizedBox(height: 24),

                      // Delivery Address Header
                      Consumer<AddressViewModel>(
                        builder: (context, addressVM, child) {
                          final count = addressVM.addresses.length;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Delivery Address',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: CooliColors.textDark,
                                    ),
                                  ),
                                  if (count > 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.purple
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$count saved',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.purple,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      // Dynamic Delivery Address (lists all saved addresses + add new option)
                      _buildAddressSection(context, vm),

                      const SizedBox(height: 24),

                      // Payment Method
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Payment Method',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: CooliColors.textDark,
                            ),
                          ),
                          Consumer<WalletViewModel>(
                            builder: (context, walletVM, _) {
                              return InkWell(
                                onTap: () => walletVM.loadWalletData(),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                          Icons.account_balance_wallet_outlined,
                                          size: 13,
                                          color: Colors.purple),
                                      const SizedBox(width: 4),
                                      Text(
                                        '₹${walletVM.balance.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.purple,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 1. Coolie Wallet Payment Option (get amount from wallet)
                      Consumer<WalletViewModel>(
                        builder: (context, walletVM, _) {
                          final walletBalance = walletVM.balance;
                          final isSufficient = walletBalance >= vm.totalAmount;
                          final isSelected =
                              vm.selectedPaymentMethod.toLowerCase() == 'wallet';

                          return _buildWalletPaymentTile(
                            walletBalance: walletBalance,
                            orderAmount: vm.totalAmount,
                            isSufficient: isSufficient,
                            isSelected: isSelected,
                            onSelect: () => vm.setPaymentMethod('Wallet'),
                            onAddFunds: () {
                              Navigator.pushNamed(context, WalletView.routeName)
                                  .then((_) {
                                if (context.mounted) {
                                  context.read<WalletViewModel>().loadWalletData();
                                }
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      // 2. UPI Option
                      _buildPaymentTile(
                        title: 'UPI',
                        subtitle: 'Google Pay, PhonePe, Paytm',
                        icon: Icons.account_balance_rounded,
                        value: 'UPI',
                        selectedValue: vm.selectedPaymentMethod,
                        onChanged: vm.setPaymentMethod,
                      ),
                      const SizedBox(height: 10),

                      // 3. Card Option
                      _buildPaymentTile(
                        title: 'Card',
                        subtitle: 'Credit / Debit Card',
                        icon: Icons.credit_card_rounded,
                        value: 'Card',
                        selectedValue: vm.selectedPaymentMethod,
                        onChanged: vm.setPaymentMethod,
                      ),
                      const SizedBox(height: 10),

                      // 4. Cash on Delivery Option
                      _buildPaymentTile(
                        title: 'Cash on Delivery',
                        subtitle: 'Pay when items arrive',
                        icon: Icons.payments_rounded,
                        value: 'COD',
                        selectedValue: vm.selectedPaymentMethod,
                        onChanged: vm.setPaymentMethod,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom Checkout Action Bar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: CooliShadows.elevated,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                              fontSize: 12, color: CooliColors.textMuted),
                        ),
                        Text(
                          '₹${vm.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: CooliColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: CooliButton(
                        text: vm.selectedPaymentMethod.toLowerCase() == 'wallet'
                            ? 'Pay with Wallet'
                            : 'Place Order',
                        isLoading: vm.isPlacingOrder,
                        onTap: () async {
                          if (!vm.hasDeliveryAddress) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: const [
                                    Icon(Icons.location_off_rounded,
                                        color: Colors.white, size: 20),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Please select a delivery address first',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFFDC2626),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                action: SnackBarAction(
                                  label: 'Add Address',
                                  textColor: Colors.white,
                                  onPressed: () =>
                                      _navigateToAddAddress(vm),
                                ),
                              ),
                            );
                            return;
                          }

                          final isWallet =
                              vm.selectedPaymentMethod.toLowerCase() == 'wallet';
                          final walletVM = context.read<WalletViewModel>();

                          if (isWallet && walletVM.balance < vm.totalAmount) {
                            showCooliToast(
                              context,
                              message:
                                  'Insufficient wallet balance (Available: ₹${walletVM.balance.toStringAsFixed(0)}). Please top up or choose another payment method.',
                              icon: Icons.warning_amber_rounded,
                              iconColor: CooliColors.danger,
                            );
                            return;
                          }

                          final success = await vm.placeOrder(
                            paymentMethod: isWallet ? 'wallet' : vm.selectedPaymentMethod,
                          );
                          if (success && context.mounted) {
                            if (isWallet) {
                              await walletVM.deductFunds(
                                amount: vm.totalAmount,
                                title: 'E-Commerce Order Payment',
                              );
                            }
                            if (context.mounted) {
                              Navigator.pushNamed(
                                  context, OrderConfirmedView.routeName);
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required String selectedValue,
    required ValueChanged<String> onChanged,
  }) {
    final isSelected = value == selectedValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? CooliColors.primary : CooliColors.border,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: isSelected
              ? CooliShadows.button.sublist(0, 1)
              : CooliShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? CooliColors.primarySoft
                    : CooliColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? CooliColors.primary : CooliColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? CooliColors.primaryDark
                          : CooliColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: CooliColors.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? CooliColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? CooliColors.primary : CooliColors.border,
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: SizedBox(
                        width: 7,
                        height: 7,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletPaymentTile({
    required double walletBalance,
    required double orderAmount,
    required bool isSufficient,
    required bool isSelected,
    required VoidCallback onSelect,
    required VoidCallback onAddFunds,
  }) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFAF5FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.purple : CooliColors.border,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : CooliShadows.card,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.purple.withValues(alpha: 0.15)
                        : const Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.purple,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Coolie Wallet',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: CooliColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSufficient
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isSufficient ? 'SUFFICIENT' : 'LOW BALANCE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: isSufficient
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFDC2626),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Available Balance: ₹${walletBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isSufficient
                              ? const Color(0xFF16A34A)
                              : CooliColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.purple : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Colors.purple : CooliColors.border,
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Center(
                          child: SizedBox(
                            width: 7,
                            height: 7,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
            if (!isSufficient) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Need ₹${(orderAmount - walletBalance).toStringAsFixed(0)} more to pay via wallet',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onAddFunds,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '+ Top Up',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isSelected) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 16, color: Color(0xFF16A34A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '₹${orderAmount.toStringAsFixed(0)} will be deducted from wallet. Remaining: ₹${(walletBalance - orderAmount).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
