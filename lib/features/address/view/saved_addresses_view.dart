import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/address/model/address_model.dart';
import 'package:cooli/features/address/view_model/address_view_model.dart';
import 'package:cooli/features/address/view/add_address_view.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';

class SavedAddressesView extends StatefulWidget {
  static const String routeName = '/saved-addresses';

  const SavedAddressesView({super.key});

  @override
  State<SavedAddressesView> createState() => _SavedAddressesViewState();
}

class _SavedAddressesViewState extends State<SavedAddressesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressViewModel>().fetchAddresses();
    });
  }

  Future<void> _navigateToAdd({bool openMap = false}) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddAddressView(openMapDirectly: openMap),
      ),
    );
  }

  Future<void> _deleteAddress(AddressModel address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Address?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          'Are you sure you want to delete "${address.addressLine1}" from your saved addresses?',
          style: const TextStyle(fontSize: 13, color: CooliColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(fontWeight: FontWeight.w600)),
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
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result =
          await context.read<AddressViewModel>().deleteAddress(address.id);
      if (mounted) {
        showCooliToast(
          context,
          message: result.message,
          icon: result.success
              ? Icons.check_circle_outline_rounded
              : Icons.info_outline_rounded,
          iconColor: result.success ? CooliColors.success : CooliColors.primary,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressVM = context.watch<AddressViewModel>();
    final addresses = addressVM.addresses;
    final filtered = addressVM.filteredAddresses;
    final isLoading = addressVM.isLoading;
    final activeFilter = addressVM.activeFilter;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: CooliColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text(
              'Saved Addresses',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: CooliColors.textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${addresses.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.purple,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Addresses',
            icon:
                const Icon(Icons.refresh_rounded, color: CooliColors.textDark),
            onPressed: () => context.read<AddressViewModel>().fetchAddresses(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.purple,
        onRefresh: () => context.read<AddressViewModel>().fetchAddresses(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Two Options to Add New Address: Google Map or Typing
              _buildAddAddressOptionsHeader(),

              const SizedBox(height: 20),

              // Filter Chips
              if (addresses.isNotEmpty) ...[
                _buildFilterChips(addressVM),
                const SizedBox(height: 16),
              ],

              // Addresses List or Empty State
              if (isLoading)
                _buildLoadingState()
              else if (filtered.isEmpty)
                _buildEmptyState(activeFilter)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildAddressCard(item);
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () {
          _showAddOptionsBottomSheet(context);
        },
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text(
          'Add Address',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }

  // Header quick add buttons
  Widget _buildAddAddressOptionsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CooliColors.borderLight),
        boxShadow: CooliShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_location_alt_rounded,
                    color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Address',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: CooliColors.textDark,
                      ),
                    ),
                    Text(
                      'Choose how you want to add your address',
                      style: TextStyle(
                        fontSize: 12,
                        color: CooliColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // Option 1: Google Map
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _navigateToAdd(openMap: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF2563EB).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.map_rounded,
                              color: Colors.white, size: 22),
                          SizedBox(height: 6),
                          Text(
                            'Pick on Google Map',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pin exact location',
                            style: TextStyle(
                              color: Color(0xFFDBEAFE),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Option 2: Type Manually
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _navigateToAdd(openMap: false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: CooliColors.border),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.edit_note_rounded,
                              color: CooliColors.textDark, size: 22),
                          SizedBox(height: 6),
                          Text(
                            'Type Manually',
                            style: TextStyle(
                              color: CooliColors.textDark,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Enter street, city, pin',
                            style: TextStyle(
                              color: CooliColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Filter Chips Bar
  Widget _buildFilterChips(AddressViewModel addressVM) {
    final filters = ['All', 'Home', 'Work', 'Other'];
    return Row(
      children: filters.map((f) {
        final isSelected = addressVM.activeFilter == f;
        int count = 0;
        if (f == 'All') {
          count = addressVM.addresses.length;
        } else {
          count = addressVM.addresses
              .where((a) => a.addressType == f.toLowerCase())
              .length;
        }

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => addressVM.setFilter(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? Colors.purple : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.purple : CooliColors.border,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.purple.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    f,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : CooliColors.textDark,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '($count)',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            isSelected ? Colors.white70 : CooliColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Address Card Widget
  Widget _buildAddressCard(AddressModel item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.isDefault
              ? Colors.purple.withValues(alpha: 0.4)
              : CooliColors.borderLight,
          width: item.isDefault ? 1.5 : 1.0,
        ),
        boxShadow: CooliShadows.card,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Type Pill, Default Badge, Delete/Copy Actions
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: item.typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.typeIcon, size: 14, color: item.typeColor),
                    const SizedBox(width: 5),
                    Text(
                      item.typeDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: item.typeColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.isDefault) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 12, color: Colors.green),
                      SizedBox(width: 3),
                      Text(
                        'DEFAULT',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.green,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              // Copy full address
              IconButton(
                tooltip: 'Copy Address',
                icon: const Icon(Icons.copy_rounded,
                    size: 18, color: CooliColors.textMuted),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: item.formattedAddress));
                  showCooliToast(
                    context,
                    message: 'Address copied to clipboard',
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: CooliColors.success,
                  );
                },
              ),
              const SizedBox(width: 4),
              // Delete Address
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 19, color: CooliColors.danger),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                onPressed: () => _deleteAddress(item),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Main Address Line 1
          Text(
            item.addressLine1,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CooliColors.textDark,
              height: 1.3,
            ),
          ),

          // Address Line 2 (if present)
          if (item.addressLine2.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.addressLine2,
              style: const TextStyle(
                fontSize: 13,
                color: CooliColors.textMuted,
              ),
            ),
          ],

          // Landmark (if present)
          if (item.landmark.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.near_me_outlined,
                    size: 13, color: CooliColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Landmark: ${item.landmark}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: CooliColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),

          // City, State, Postal Code
          Row(
            children: [
              const Icon(Icons.location_city_rounded,
                  size: 14, color: CooliColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '${item.city}, ${item.state} - ${item.postalCode}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CooliColors.textDark,
                ),
              ),
            ],
          ),

          // Coordinates chip if available
          if (item.latitude != null && item.longitude != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CooliColors.borderLight),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pin_drop_rounded,
                      size: 12, color: Colors.purple),
                  const SizedBox(width: 4),
                  Text(
                    'GPS: ${item.latitude!.toStringAsFixed(4)}, ${item.longitude!.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CooliColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Loading Skeletons
  Widget _buildLoadingState() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 2,
      itemBuilder: (_, __) => Container(
        height: 140,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: CooliColors.borderLight),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 80,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Container(
                  width: 40,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 160,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState(String activeFilter) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_outlined,
              size: 40,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            activeFilter == 'All'
                ? 'No Saved Addresses'
                : 'No $activeFilter Addresses Found',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: CooliColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Save your home, office, and frequent delivery spots for instant 1-tap bookings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: CooliColors.textMuted),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.add_location_alt_rounded, size: 18),
            label: const Text('Add Your First Address',
                style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: () => _navigateToAdd(openMap: false),
          ),
        ],
      ),
    );
  }

  void _showAddOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CooliColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add Address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: CooliColors.textDark,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.map_rounded,
                      color: Color(0xFF2563EB), size: 22),
                ),
                title: const Text('Pick on Google Map',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Pin location visually on interactive map',
                    style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToAdd(openMap: true);
                },
              ),
              const Divider(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_note_rounded,
                      color: Colors.purple, size: 22),
                ),
                title: const Text('Type Manually',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text(
                    'Fill address line, landmark, city, and pincode',
                    style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToAdd(openMap: false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
