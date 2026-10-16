import 'package:flutter/material.dart';
import 'package:cooli/features/services/model/blackbuck_load_model.dart';
import 'package:cooli/features/services/repo/services_repo.dart';
import 'package:cooli/services/session_manager.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';

/// Opens the Create Bid Bottom Sheet for a transport load
Future<bool?> showCreateBidBottomSheet(
  BuildContext context, {
  required BlackbuckLoadModel load,
  VoidCallback? onBidSubmitted,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => CreateBidBottomSheet(
      load: load,
      onBidSubmitted: onBidSubmitted,
    ),
  );
}

class CreateBidBottomSheet extends StatefulWidget {
  final BlackbuckLoadModel load;
  final VoidCallback? onBidSubmitted;

  const CreateBidBottomSheet({
    super.key,
    required this.load,
    this.onBidSubmitted,
  });

  @override
  State<CreateBidBottomSheet> createState() => _CreateBidBottomSheetState();
}

class _CreateBidBottomSheetState extends State<CreateBidBottomSheet> {
  static const Color primaryBlue = Color(0xFF2563EB);

  late TextEditingController _amountController;
  late TextEditingController _messageController;
  late DateTime _selectedDate;

  int _bidderId = 2; // Default per API spec
  String _bidderName = 'Transporter';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Default amount from expected fare or 19500 per example
    final defaultAmt = widget.load.expectedFareMin != null
        ? widget.load.expectedFareMin!.split('.').first
        : '19500';
    _amountController = TextEditingController(text: defaultAmt);

    // Default message per API spec
    _messageController = TextEditingController(text: 'I can deliver safely');

    // Default delivery date: 2 days from now
    _selectedDate = DateTime.now().add(const Duration(days: 2));

    _initUserData();
  }

  Future<void> _initUserData() async {
    try {
      final user = await SessionManager().getSavedUser();
      final id = await SessionManager().getLoggedInUserId();
      if (mounted) {
        setState(() {
          if (id != null && id > 0) {
            _bidderId = id;
          } else {
            _bidderId = 2; // Default fallback
          }
          if (user != null && user.fullName.isNotEmpty) {
            _bidderName = user.fullName;
          }
        });
      }
    } catch (e) {
      debugPrint('[CreateBidBottomSheet] _initUserData error: $e');
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatFriendlyDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday, ${date.day} $month ${date.year}';
  }

  Future<void> _selectDeliveryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: CooliColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      showCooliToast(
        context,
        message: 'Please enter your bid amount',
        icon: Icons.error_outline_rounded,
        iconColor: CooliColors.danger,
      );
      return;
    }

    final cleanedNumStr = amountText.replaceAll(RegExp(r'[^0-9.]'), '');
    final bidAmount = double.tryParse(cleanedNumStr);
    if (bidAmount == null || bidAmount <= 0) {
      showCooliToast(
        context,
        message: 'Please enter a valid bid amount (e.g. ₹ 19,500)',
        icon: Icons.error_outline_rounded,
        iconColor: CooliColors.danger,
      );
      return;
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) {
      showCooliToast(
        context,
        message: 'Please provide a message or delivery note',
        icon: Icons.error_outline_rounded,
        iconColor: CooliColors.danger,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final deliveryDateFormatted = _formatDate(_selectedDate);
    final loadIdentifier = widget.load.id.isNotEmpty
        ? widget.load.id
        : 'LOAD-2026-001';

    final result = await ServicesRepo().submitBid(
      loadId: loadIdentifier,
      bidderId: _bidderId,
      bidAmount: bidAmount,
      estimatedDeliveryDate: deliveryDateFormatted,
      message: message,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      Navigator.pop(context, true);
      widget.onBidSubmitted?.call();

      _showSuccessDialog(
        context,
        loadId: loadIdentifier,
        amount: bidAmount,
        date: deliveryDateFormatted,
        serverMessage: result.message,
      );
    } else {
      showCooliToast(
        context,
        message: result.message,
        icon: Icons.warning_amber_rounded,
        iconColor: CooliColors.warning,
      );
    }
  }

  void _showSuccessDialog(
    BuildContext ctx, {
    required String loadId,
    required double amount,
    required String date,
    required String serverMessage,
  }) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF059669),
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              serverMessage.isNotEmpty
                  ? serverMessage
                  : 'Bid submitted successfully',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: CooliColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your offer of ₹${amount.toStringAsFixed(0)} for $loadId has been communicated to the shipper.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: CooliColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Create Freight Bid',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: CooliColors.textDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Text(
                                widget.load.id.isNotEmpty
                                    ? widget.load.id
                                    : 'LOAD-2026-001',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${widget.load.loadingPoint} → ${widget.load.unloadingPoint}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: primaryBlue,
                            fontWeight: FontWeight.w600,
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
            ),
            const Divider(height: 16, color: CooliColors.border),

            // Scrollable Form Content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Offer Rate
                    const Text(
                      'Your Offer Rate (₹)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CooliColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: primaryBlue,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 14, right: 8),
                          child: Center(
                            widthFactor: 0.0,
                            child: Text(
                              '₹',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: primaryBlue,
                              ),
                            ),
                          ),
                        ),
                        hintText: '19500',
                        hintStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: CooliColors.textLight,
                        ),
                        filled: true,
                        fillColor: CooliColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: CooliColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: CooliColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: primaryBlue,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 10),

                    // Quick rate chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildQuickAmountChip('18000'),
                          _buildQuickAmountChip('19000'),
                          _buildQuickAmountChip('19500'),
                          _buildQuickAmountChip('20000'),
                          _buildQuickAmountChip('21000'),
                          _buildQuickAmountChip('22000'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. Estimated Delivery Date
                    const Text(
                      'Estimated Delivery Date',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CooliColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDeliveryDate,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: CooliColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: CooliColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: primaryBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${_formatFriendlyDate(_selectedDate)}  (${_formatDate(_selectedDate)})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: CooliColors.textDark,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.edit_calendar_rounded,
                              color: primaryBlue,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 3. Message / Remarks
                    const Text(
                      'Message / Delivery Note',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CooliColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CooliColors.textDark,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. I can deliver safely',
                        hintStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: CooliColors.textLight,
                        ),
                        filled: true,
                        fillColor: CooliColors.background,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: CooliColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: CooliColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: primaryBlue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Quick message chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildQuickMsgChip('I can deliver safely'),
                          _buildQuickMsgChip('Available immediately'),
                          _buildQuickMsgChip('GPS tracked vehicle'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Bidder Info Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_circle_outlined,
                              size: 18, color: primaryBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bidding as $_bidderName',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: CooliColors.textDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryBlue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Bidder #$_bidderId',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          disabledBackgroundColor:
                              primaryBlue.withValues(alpha: 0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.gavel_rounded,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _amountController.text.trim().isNotEmpty
                                        ? 'Submit Bid (₹ ${_amountController.text.trim()})'
                                        : 'Submit Bid',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountChip(String amt) {
    final isSelected = _amountController.text.trim() == amt;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _amountController.text = amt;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : CooliColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? primaryBlue : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Text(
            '₹ $amt',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isSelected ? primaryBlue : CooliColors.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMsgChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _messageController.text = text;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: CooliColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CooliColors.border),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CooliColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}
