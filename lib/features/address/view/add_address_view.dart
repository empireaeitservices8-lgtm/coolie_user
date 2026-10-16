import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/address/model/address_model.dart';
import 'package:cooli/features/address/view_model/address_view_model.dart';
import 'package:cooli/features/ride/service/ride_location_service.dart';
import 'package:cooli/features/ride/view/ride_map_picker_view.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';

class AddAddressView extends StatefulWidget {
  static const String routeName = '/add-address';

  final bool openMapDirectly;
  final AddressModel? initialAddress;

  const AddAddressView({
    super.key,
    this.openMapDirectly = false,
    this.initialAddress,
  });

  @override
  State<AddAddressView> createState() => _AddAddressViewState();
}

class _AddAddressViewState extends State<AddAddressView> {
  final _formKey = GlobalKey<FormState>();
  final RideLocationService _locationService = RideLocationService();

  late TextEditingController _line1Controller;
  late TextEditingController _line2Controller;
  late TextEditingController _landmarkController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;

  String _selectedType = 'home';
  bool _isDefault = false;
  double? _latitude;
  double? _longitude;
  bool _isSaving = false;
  bool _autoValidate = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initialAddress;
    _line1Controller = TextEditingController(text: init?.addressLine1 ?? '');
    _line2Controller = TextEditingController(text: init?.addressLine2 ?? '');
    _landmarkController = TextEditingController(text: init?.landmark ?? '');
    _cityController = TextEditingController(text: init?.city ?? '');
    _stateController = TextEditingController(text: init?.state ?? '');
    _postalCodeController = TextEditingController(text: init?.postalCode ?? '');

    _selectedType = init?.addressType.toLowerCase() ?? 'home';
    _isDefault = init?.isDefault ?? false;
    _latitude = init?.latitude ?? 12.971600;
    _longitude = init?.longitude ?? 77.594600;

    if (widget.openMapDirectly && init == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickFromMap();
      });
    }
  }

  @override
  void dispose() {
    _line1Controller.dispose();
    _line2Controller.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickFromMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideMapPickerView(
          singleLocationOnly: true,
          initialLat: _latitude,
          initialLng: _longitude,
          initialAddress: _line1Controller.text.isNotEmpty
              ? _line1Controller.text
              : 'Current Location',
        ),
      ),
    );

    if (result != null && mounted) {
      final LocationResult loc;
      if (result is LocationResult) {
        loc = result;
      } else if (result is RideMapSelectionResult) {
        loc = result.selected;
      } else {
        return;
      }

      setState(() {
        _latitude = loc.latitude;
        _longitude = loc.longitude;
        if (loc.title.isNotEmpty) {
          _line1Controller.text = loc.title;
        }
        if (loc.subtitle.isNotEmpty) {
          _landmarkController.text = loc.subtitle;
        }
      });

      // Attempt reverse geocoding to auto-fill city, state, postal code
      try {
        final geocoded = await _locationService.reverseGeocode(
            loc.latitude, loc.longitude);
        if (geocoded != null && mounted) {
          final sub = geocoded.subtitle;
          final parts = sub.split(',').map((s) => s.trim()).toList();
          if (parts.isNotEmpty) {
            for (final part in parts) {
              if (RegExp(r'^\d{6}$').hasMatch(part)) {
                _postalCodeController.text = part;
              } else if (part.toLowerCase().contains('karnataka') ||
                  part.toLowerCase().contains('kerala') ||
                  part.toLowerCase().contains('tamil nadu') ||
                  part.toLowerCase().contains('maharashtra')) {
                _stateController.text = part;
              } else if (part.toLowerCase().contains('bangalore') ||
                  part.toLowerCase().contains('bengaluru') ||
                  part.toLowerCase().contains('kochi') ||
                  part.toLowerCase().contains('ernakulam') ||
                  part.toLowerCase().contains('calicut')) {
                _cityController.text = part;
              }
            }
          }
        }
      } catch (_) {}

      if (!mounted) return;
      showCooliToast(
        context,
        message: 'Location pinned from map',
        icon: Icons.pin_drop_rounded,
        iconColor: CooliColors.primary,
      );
    }
  }

  Future<void> _saveAddress() async {
    setState(() => _autoValidate = true);

    if (!_formKey.currentState!.validate()) {
      showCooliToast(
        context,
        message: 'Please fill in all required fields correctly',
        icon: Icons.error_outline_rounded,
        iconColor: CooliColors.danger,
      );
      return;
    }

    final line1 = _line1Controller.text.trim();
    final line2 = _line2Controller.text.trim();
    final landmark = _landmarkController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final postalCode = _postalCodeController.text.trim();

    setState(() => _isSaving = true);
    try {
      final result = await context.read<AddressViewModel>().createAddress(
        addressType: _selectedType,
        addressLine1: line1,
        addressLine2: line2,
        landmark: landmark,
        city: city,
        state: state,
        postalCode: postalCode,
        latitude: _latitude ?? 12.9716,
        longitude: _longitude ?? 77.5946,
        isDefault: _isDefault,
      );

      if (!mounted) return;

      if (result.success) {
        showCooliToast(
          context,
          message: 'Address saved successfully',
          icon: Icons.check_circle_outline_rounded,
          iconColor: CooliColors.success,
        );
        Navigator.pop(context, true);
      } else {
        showCooliToast(
          context,
          message: result.message,
          icon: Icons.error_outline_rounded,
          iconColor: CooliColors.danger,
        );
      }
    } catch (e) {
      debugPrint('[AddAddressView] _saveAddress error: $e');
      if (mounted) {
        showCooliToast(
          context,
          message: 'Error saving address',
          icon: Icons.error_outline_rounded,
          iconColor: CooliColors.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          widget.initialAddress == null ? 'Add New Address' : 'Edit Address',
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: CooliColors.textDark,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidate
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map Pick Shortcut Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CooliColors.primary,
                      const Color(0xFF1D4ED8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: CooliColors.primary.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.map_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pick from Google Map',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pin exact location to autofill street & landmark',
                            style: TextStyle(
                              color: Color(0xFFE0E7FF),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: CooliColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _pickFromMap,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pin_drop_rounded, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Select',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Address Type Selector
              const Text(
                'Address Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CooliColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildTypeChip('home', 'Home', Icons.home_rounded),
                  const SizedBox(width: 10),
                  _buildTypeChip('work', 'Work', Icons.work_rounded),
                  const SizedBox(width: 10),
                  _buildTypeChip(
                      'other', 'Other', Icons.location_on_rounded),
                ],
              ),

              const SizedBox(height: 22),

              // Main Form Container
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: CooliColors.borderLight),
                  boxShadow: CooliShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Address Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: CooliColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Address Line 1
                    _buildTextField(
                      controller: _line1Controller,
                      label: 'Flat / House No. / Building / Street *',
                      hintText: 'e.g. 123 Main St, Apt 4B',
                      icon: Icons.home_outlined,
                      textInputAction: TextInputAction.next,
                      validator: (val) {
                        final text = val?.trim() ?? '';
                        if (text.isEmpty) {
                          return 'Please enter flat, house no. or street address';
                        }
                        if (text.length < 3) {
                          return 'Address is too short (min 3 characters)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Address Line 2
                    _buildTextField(
                      controller: _line2Controller,
                      label: 'Area / Colony / Road (Optional)',
                      hintText: 'e.g. 4th Block, Koramangala',
                      icon: Icons.signpost_outlined,
                      textInputAction: TextInputAction.next,
                      validator: (val) {
                        if (val != null && val.trim().length > 100) {
                          return 'Area name is too long (max 100 characters)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Landmark
                    _buildTextField(
                      controller: _landmarkController,
                      label: 'Nearby Landmark (Optional)',
                      hintText: 'e.g. Near Metro Station / Opposite Park',
                      icon: Icons.near_me_outlined,
                      textInputAction: TextInputAction.next,
                      validator: (val) {
                        if (val != null && val.trim().length > 100) {
                          return 'Landmark is too long (max 100 characters)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // City & State Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _cityController,
                            label: 'City *',
                            hintText: 'e.g. Bangalore',
                            icon: Icons.location_city_outlined,
                            textInputAction: TextInputAction.next,
                            validator: (val) {
                              final text = val?.trim() ?? '';
                              if (text.isEmpty) {
                                return 'Please enter city';
                              }
                              if (text.length < 2) {
                                return 'Min 2 characters';
                              }
                              if (!RegExp(r'^[a-zA-Z\s\.\-]+$').hasMatch(text)) {
                                return 'Enter a valid city';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _stateController,
                            label: 'State *',
                            hintText: 'e.g. Karnataka',
                            icon: Icons.map_outlined,
                            textInputAction: TextInputAction.next,
                            validator: (val) {
                              final text = val?.trim() ?? '';
                              if (text.isEmpty) {
                                return 'Please enter state';
                              }
                              if (text.length < 2) {
                                return 'Min 2 characters';
                              }
                              if (!RegExp(r'^[a-zA-Z\s\.\-]+$').hasMatch(text)) {
                                return 'Enter a valid state';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Postal Code & GPS Coordinates Info
                    _buildTextField(
                      controller: _postalCodeController,
                      label: 'Postal / PIN Code *',
                      hintText: 'e.g. 560001',
                      icon: Icons.pin_outlined,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      validator: (val) {
                        final text = val?.trim() ?? '';
                        if (text.isEmpty) {
                          return 'Please enter 6-digit postal code';
                        }
                        if (text.length != 6) {
                          return 'PIN code must be exactly 6 digits';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // GPS Coordinates preview chip
              if (_latitude != null && _longitude != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: CooliColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed_rounded,
                          size: 16, color: CooliColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'GPS Coordinates: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CooliColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _pickFromMap,
                        child: const Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: CooliColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Set as default checkbox
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CooliColors.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            color: CooliColors.primary, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Set as default address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: CooliColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isDefault,
                      activeThumbColor: CooliColors.primary,
                      onChanged: (val) => setState(() => _isDefault = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Save Address Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CooliColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveAddress,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Save Address',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? CooliColors.primary.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? CooliColors.primary : CooliColors.border,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? CooliColors.primary : CooliColors.textMuted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color:
                      isSelected ? CooliColors.primary : CooliColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CooliColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CooliColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: Icon(icon, size: 19, color: Colors.grey.shade500),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CooliColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CooliColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: CooliColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: CooliColors.danger, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: CooliColors.danger, width: 1.5),
            ),
            errorStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: CooliColors.danger,
            ),
          ),
        ),
      ],
    );
  }
}
