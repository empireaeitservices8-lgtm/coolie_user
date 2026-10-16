import 'package:cooli/features/address/service/ai_address_service.dart';
import 'package:cooli/features/address/view/add_address_view.dart';
import 'package:cooli/features/address/view_model/address_view_model.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AiAddAddressSheet extends StatefulWidget {
  final String? initialText;

  const AiAddAddressSheet({super.key, this.initialText});

  static Future<bool?> show(BuildContext context, {String? initialText}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiAddAddressSheet(initialText: initialText),
    );
  }

  @override
  State<AiAddAddressSheet> createState() => _AiAddAddressSheetState();
}

class _AiAddAddressSheetState extends State<AiAddAddressSheet> {
  late TextEditingController _textController;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  AiParsedAddress? _parsedAddress;
  bool _isDefault = true;
  String _selectedType = 'home';

  static const String _sampleAddress =
      '123 Main St, Apt 4B, Near Metro Station, Bangalore, Karnataka 560001';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText ?? '');
    if (widget.initialText?.isNotEmpty == true) {
      _processAiAddress(widget.initialText!);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _textController.text = data.text!.trim();
      });
      _processAiAddress(_textController.text);
    } else {
      if (!mounted) return;
      showCooliToast(
        context,
        message: 'Clipboard is empty',
        icon: Icons.info_outline_rounded,
        iconColor: CooliColors.primary,
      );
    }
  }

  Future<void> _processAiAddress(String raw) async {
    final text = raw.trim();
    if (text.isEmpty) {
      showCooliToast(
        context,
        message: 'Please enter or paste an address',
        icon: Icons.warning_amber_rounded,
        iconColor: CooliColors.danger,
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final parsed = await AiAddressService.parseAddress(text);
      if (!mounted) return;
      setState(() {
        _parsedAddress = parsed;
        _selectedType = parsed.addressType;
        _isDefault = parsed.isDefault;
        _isAnalyzing = false;
      });
    } catch (e) {
      debugPrint('[AiAddAddressSheet] parsing error: $e');
      if (mounted) {
        setState(() => _isAnalyzing = false);
        showCooliToast(
          context,
          message: 'Could not parse address: $e',
          icon: Icons.error_outline_rounded,
          iconColor: CooliColors.danger,
        );
      }
    }
  }

  Future<void> _saveAddressDirectly() async {
    if (_parsedAddress == null) return;

    setState(() => _isSaving = true);
    try {
      final addressVM = context.read<AddressViewModel>();
      final result = await addressVM.createAddress(
        addressType: _selectedType,
        addressLine1: _parsedAddress!.addressLine1,
        addressLine2: _parsedAddress!.addressLine2,
        landmark: _parsedAddress!.landmark,
        city: _parsedAddress!.city,
        state: _parsedAddress!.state,
        postalCode: _parsedAddress!.postalCode,
        country: _parsedAddress!.country,
        latitude: _parsedAddress!.latitude,
        longitude: _parsedAddress!.longitude,
        isDefault: _isDefault,
      );

      if (!mounted) return;

      if (result.success) {
        showCooliToast(
          context,
          message: 'Address added with AI successfully!',
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
      debugPrint('[AiAddAddressSheet] _saveAddressDirectly error: $e');
      if (mounted) {
        showCooliToast(
          context,
          message: 'Failed to save address: $e',
          icon: Icons.error_outline_rounded,
          iconColor: CooliColors.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openInFullForm() {
    if (_parsedAddress == null) return;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAddressView(
          initialAddress: _parsedAddress!
              .copyWith(
                addressType: _selectedType,
                isDefault: _isDefault,
              )
              .toAddressModel(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'AI Address Assistant',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: CooliColors.textDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(width: 6),
                            CooliBadge(
                              text: 'SMART',
                              backgroundColor: Color(0xFF8B5CF6),
                              textColor: Colors.white,
                            ),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Paste text from WhatsApp, SMS or type naturally',
                          style: TextStyle(
                            fontSize: 12,
                            color: CooliColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: CooliColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Input box
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            TextField(
                              controller: _textController,
                              maxLines: 3,
                              minLines: 2,
                              style: const TextStyle(
                                fontSize: 14,
                                color: CooliColors.textDark,
                                height: 1.4,
                              ),
                              decoration: const InputDecoration(
                                hintText:
                                    'e.g. 123 Main St, Apt 4B, Near Metro Station, Bangalore, Karnataka 560001',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF94A3B8),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Action bar below text area
                            Row(
                              children: [
                                ActionChip(
                                  avatar: const Icon(Icons.content_paste_rounded,
                                      size: 14, color: Color(0xFF6366F1)),
                                  label: const Text('Paste'),
                                  labelStyle: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6366F1),
                                  ),
                                  backgroundColor: const Color(0xFFEEF2FF),
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  onPressed: _pasteFromClipboard,
                                ),
                                const SizedBox(width: 8),
                                ActionChip(
                                  avatar: const Icon(Icons.lightbulb_outline_rounded,
                                      size: 14, color: Colors.purple),
                                  label: const Text('Sample'),
                                  labelStyle: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.purple,
                                  ),
                                  backgroundColor:
                                      Colors.purple.withValues(alpha: 0.08),
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  onPressed: () {
                                    setState(() {
                                      _textController.text = _sampleAddress;
                                    });
                                    _processAiAddress(_sampleAddress);
                                  },
                                ),
                                const Spacer(),
                                if (_textController.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _textController.clear();
                                        _parsedAddress = null;
                                      });
                                    },
                                    child: const Text(
                                      'Clear',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: CooliColors.danger,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Extract Button
                      CooliButton(
                        text: _isAnalyzing
                            ? 'AI is Analyzing Address...'
                            : 'Extract with AI',
                        isLoading: _isAnalyzing,
                        icon: Icons.auto_awesome_rounded,
                        backgroundColor: const Color(0xFF8B5CF6),
                        onTap: () =>
                            _processAiAddress(_textController.text),
                      ),

                      if (_parsedAddress != null) ...[
                        const SizedBox(height: 20),
                        _buildParsedResultCard(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParsedResultCard() {
    final parsed = _parsedAddress!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 13, color: Color(0xFF16A34A)),
                    SizedBox(width: 4),
                    Text(
                      'AI Breakdown',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Address Type Chips
              Row(
                children: ['home', 'work', 'other'].map((type) {
                  final isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(
                        type[0].toUpperCase() + type.substring(1),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : CooliColors.textDark,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF8B5CF6),
                      backgroundColor: const Color(0xFFF1F5F9),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onSelected: (val) {
                        if (val) setState(() => _selectedType = type);
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Line 1
          _buildFieldRow(
            icon: Icons.location_on_rounded,
            title: 'Line 1',
            value: parsed.addressLine1,
          ),
          if (parsed.addressLine2.isNotEmpty)
            _buildFieldRow(
              icon: Icons.apartment_rounded,
              title: 'Line 2',
              value: parsed.addressLine2,
            ),
          if (parsed.landmark.isNotEmpty)
            _buildFieldRow(
              icon: Icons.near_me_outlined,
              title: 'Landmark',
              value: parsed.landmark,
              isHighlight: true,
            ),
          _buildFieldRow(
            icon: Icons.location_city_rounded,
            title: 'City & State',
            value: '${parsed.city}, ${parsed.state} - ${parsed.postalCode}',
          ),
          _buildFieldRow(
            icon: Icons.gps_fixed_rounded,
            title: 'Coordinates',
            value:
                '${parsed.latitude.toStringAsFixed(4)}, ${parsed.longitude.toStringAsFixed(4)}',
            isMuted: true,
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Default address switch
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Set as Default Delivery Address',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CooliColors.textDark,
                  ),
                ),
              ),
              Switch.adaptive(
                value: _isDefault,
                activeTrackColor: Colors.purple,
                onChanged: (val) => setState(() => _isDefault = val),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: CooliButton(
                  text: _isSaving ? 'Saving...' : 'Save Address Directly',
                  isLoading: _isSaving,
                  icon: Icons.save_rounded,
                  backgroundColor: CooliColors.success,
                  onTap: _saveAddressDirectly,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: CooliOutlineButton(
                  text: 'Edit in Form',
                  icon: Icons.edit_note_rounded,
                  borderColor: CooliColors.primary,
                  textColor: CooliColors.primary,
                  onTap: _openInFullForm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow({
    required IconData icon,
    required String title,
    required String value,
    bool isHighlight = false,
    bool isMuted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 16,
              color: isHighlight ? CooliColors.primary : CooliColors.textMuted),
          const SizedBox(width: 8),
          SizedBox(
            width: 78,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11.5,
                color: CooliColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
                color: isHighlight
                    ? CooliColors.primary
                    : (isMuted ? CooliColors.textMuted : CooliColors.textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
