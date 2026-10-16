import 'package:flutter/material.dart';
import 'package:cooli/features/services/model/blackbuck_load_model.dart';
import 'package:cooli/features/services/repo/services_repo.dart';
import 'package:cooli/services/session_manager.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';

class BlackbuckBiddingView extends StatefulWidget {
  static const String routeName = '/blackbuck-bidding';

  final BlackbuckLoadModel? load;

  const BlackbuckBiddingView({super.key, this.load});

  @override
  State<BlackbuckBiddingView> createState() => _BlackbuckBiddingViewState();
}

class _BlackbuckBiddingViewState extends State<BlackbuckBiddingView> {
  static const Color primaryBlue = Color(0xFF2563EB);

  late BlackbuckLoadModel _load;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  int _bidderId = 2; // Default per API spec
  String _bidderName = 'Transporter';
  String _bidderPhone = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _load = widget.load ?? BlackbuckLoadModel.getSampleLoads().first;

    // Default amount from expected fare or 19500 per example
    final defaultAmt = _load.expectedFareMin != null
        ? _load.expectedFareMin!.split('.').first
        : '19500';
    _amountController.text = defaultAmt;

    // Default message per API spec
    _messageController.text = 'I can deliver safely';

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
            _bidderId = 2; // Default bidder fallback from requirements
          }
          if (user != null) {
            _bidderName = user.fullName;
            _bidderPhone = user.phoneNumber;
          }
        });
      }
    } catch (e) {
      debugPrint('[BlackbuckBiddingView] _initUserData error: $e');
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

  Future<void> _handleBidSubmit() async {
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
    final loadIdentifier = _load.id.isNotEmpty ? _load.id : 'LOAD-2026-001';

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
      _showSuccessDialog(
        loadId: loadIdentifier,
        amount: bidAmount,
        date: deliveryDateFormatted,
        message: message,
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

  void _showSuccessDialog({
    required String loadId,
    required double amount,
    required String date,
    required String message,
    required String serverMessage,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: CooliColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF059669),
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                serverMessage.isNotEmpty
                    ? serverMessage
                    : 'Bid submitted successfully',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: CooliColors.textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your freight bid has been received by the shipper for $loadId',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: CooliColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CooliColors.border),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Load ID', loadId),
                    const Divider(height: 16, color: CooliColors.border),
                    _buildSummaryRow(
                      'Bid Amount',
                      '₹ ${amount.toStringAsFixed(0)}',
                      valueColor: primaryBlue,
                      isBold: true,
                    ),
                    const Divider(height: 16, color: CooliColors.border),
                    _buildSummaryRow('Est. Delivery', date),
                    const Divider(height: 16, color: CooliColors.border),
                    _buildSummaryRow('Bidder ID', '#$_bidderId'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close sheet
                    Navigator.pop(context, true); // Return to loads list
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color valueColor = CooliColors.textDark,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: CooliColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            color: valueColor,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
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
              size: 20, color: CooliColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Place Freight Bid',
          style: TextStyle(
            color: CooliColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFD97706)),
                SizedBox(width: 4),
                Text(
                  'BIDDING OPEN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: CooliColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Load Route & Summary Card
                      _buildLoadSummaryCard(),
                      const SizedBox(height: 16),

                      // 2. Offer Amount Section
                      _buildOfferAmountCard(),
                      const SizedBox(height: 16),

                      // 3. Estimated Delivery Date Section
                      _buildDeliveryDateCard(),
                      const SizedBox(height: 16),

                      // 4. Message / Remarks Section
                      _buildMessageCard(),
                      const SizedBox(height: 16),

                      // 5. Bidder Information Card
                      _buildBidderInfoCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Sticky Bottom Submit Bar
              _buildBottomAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CooliColors.border),
        boxShadow: CooliShadows.card,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  _load.id.isNotEmpty ? _load.id : 'LOAD-2026-001',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: primaryBlue,
                  ),
                ),
              ),
              if (_load.distance.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.straighten_rounded,
                          size: 13, color: CooliColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        _load.distance,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: CooliColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Route Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 36,
                    color: const Color(0xFFE2E8F0),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _load.loadingPoint,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: CooliColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _load.loadingAddressNote,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: CooliColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _load.unloadingPoint,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: CooliColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _load.unloadingAddressNote,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: CooliColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildMiniChip(Icons.local_shipping_outlined, _load.truckType),
              _buildMiniChip(Icons.scale_rounded, _load.capacity),
              _buildMiniChip(Icons.inventory_2_outlined, _load.product),
            ],
          ),
          const SizedBox(height: 12),

          // Expected Fare Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CooliColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Expected Freight Rate',
                  style: TextStyle(
                    fontSize: 12,
                    color: CooliColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _load.totalEarnings.isNotEmpty
                      ? _load.totalEarnings
                      : '₹ 18,000 - ₹ 22,000',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: CooliColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: CooliColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CooliColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferAmountCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CooliColors.border),
        boxShadow: CooliShadows.card,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.currency_rupee_rounded, size: 18, color: primaryBlue),
              SizedBox(width: 6),
              Text(
                'Your Bid Amount',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: CooliColors.textDark,
                ),
              ),
              Spacer(),
              Text(
                'Negotiable',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: CooliColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Amount TextField
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: primaryBlue,
              letterSpacing: -0.5,
            ),
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 8),
                child: Center(
                  widthFactor: 0.0,
                  child: Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: primaryBlue,
                    ),
                  ),
                ),
              ),
              hintText: '19500',
              hintStyle: const TextStyle(
                fontSize: 20,
                color: CooliColors.textLight,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: CooliColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: CooliColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: primaryBlue, width: 2),
              ),
            ),
            onChanged: (val) {
              setState(() {});
            },
          ),
          const SizedBox(height: 12),

          // Suggested quick buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChip('18000'),
                _buildQuickChip('19000'),
                _buildQuickChip('19500'),
                _buildQuickChip('20000'),
                _buildQuickChip('21000'),
                _buildQuickChip('22000'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String amt) {
    final isSelected = _amountController.text.trim() == amt;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            _amountController.text = amt;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? primaryBlue : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            '₹ $amt',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? primaryBlue : CooliColors.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryDateCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CooliColors.border),
        boxShadow: CooliShadows.card,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.event_available_rounded,
                  size: 18, color: primaryBlue),
              SizedBox(width: 6),
              Text(
                'Estimated Delivery Date',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: CooliColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _selectDeliveryDate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CooliColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatFriendlyDate(_selectedDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: CooliColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ISO: ${_formatDate(_selectedDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CooliColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.edit_calendar_rounded,
                    color: primaryBlue,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CooliColors.border),
        boxShadow: CooliShadows.card,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 18, color: primaryBlue),
              SizedBox(width: 6),
              Text(
                'Bid Message / Note',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: CooliColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: CooliColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. I can deliver safely',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: CooliColors.textLight,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: CooliColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: CooliColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: primaryBlue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMsgChip('I can deliver safely'),
                _buildMsgChip('Available immediately'),
                _buildMsgChip('GPS tracked vehicle'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMsgChip(String text) {
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
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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

  Widget _buildBidderInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_pin_rounded,
                color: primaryBlue, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _bidderName.isNotEmpty ? _bidderName : 'Transporter',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: CooliColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 6),
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
                const SizedBox(height: 2),
                Text(
                  _bidderPhone.isNotEmpty
                      ? _bidderPhone
                      : 'Verified Logistics Partner',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: CooliColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    final amountText = _amountController.text.trim();
    final displayAmount = amountText.isNotEmpty ? '₹ $amountText' : '₹ 19,500';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: CooliColors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'YOUR BID',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: CooliColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayAmount,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: primaryBlue,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleBidSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  disabledBackgroundColor: primaryBlue.withValues(alpha: 0.6),
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
                          strokeWidth: 2.4,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.gavel_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Submit Bid',
                            style: TextStyle(
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
          ),
        ],
      ),
    );
  }
}
