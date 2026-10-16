import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/wallet/model/wallet_model.dart';
import 'package:cooli/features/wallet/view_model/wallet_view_model.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';

class WalletView extends StatefulWidget {
  static const String routeName = '/wallet';

  const WalletView({super.key});

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  static const Color primaryBlue = Color(0xFF2563EB);

  WalletViewModel get _vm => context.watch<WalletViewModel>();
  WalletModel get _wallet => _vm.wallet;
  bool get _isLoading => _vm.isLoading;
  bool get _isBalanceVisible => _vm.isBalanceVisible;
  String get _activeFilter => _vm.activeFilter;
  String get _userName => _vm.userName;
  List<WalletTransactionModel> get _filteredTransactions =>
      _vm.filteredTransactions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletViewModel>().loadWalletData();
    });
  }

  Future<void> _loadWalletData() async {
    await context.read<WalletViewModel>().loadWalletData();
  }

  void _openAddMoneySheet([double? initialAmount]) {
    final amountController = TextEditingController(
      text: initialAmount != null ? initialAmount.toStringAsFixed(0) : '500',
    );
    String selectedMethod = 'Google Pay (UPI)';
    bool isAdding = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: bottomInset + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: CooliColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Money to Wallet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: CooliColors.textDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: CooliColors.textMuted),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Instant top-up for faster booking checkouts',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: CooliColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Amount Input
                    const Text(
                      'Enter Amount',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CooliColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: primaryBlue,
                        letterSpacing: -0.5,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 16, right: 8),
                          child: Center(
                            widthFactor: 0.0,
                            child: Text(
                              '₹',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: primaryBlue,
                              ),
                            ),
                          ),
                        ),
                        hintText: '500',
                        hintStyle: const TextStyle(
                          fontSize: 22,
                          color: CooliColors.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: CooliColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: CooliColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: CooliColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: primaryBlue,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (val) => setSheetState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // Preset Amount Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['100', '500', '1000', '2000', '5000'].map((amt) {
                          final isSelected =
                              amountController.text.trim() == amt;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                setSheetState(() {
                                  amountController.text = amt;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFEFF6FF)
                                      : CooliColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryBlue
                                        : Colors.transparent,
                                    width: 1.4,
                                  ),
                                ),
                                child: Text(
                                  '+ ₹$amt',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? primaryBlue
                                        : CooliColors.textDark,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Payment Method Selection
                    const Text(
                      'Select Payment Mode',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CooliColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildPaymentMethodTile(
                      title: 'Google Pay (UPI)',
                      subtitle: 'Fast UPI 1-click payment',
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: const Color(0xFF0F9D58),
                      isSelected: selectedMethod == 'Google Pay (UPI)',
                      onTap: () =>
                          setSheetState(() => selectedMethod = 'Google Pay (UPI)'),
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentMethodTile(
                      title: 'PhonePe / Paytm UPI',
                      subtitle: 'Pay via any UPI app',
                      icon: Icons.qr_code_scanner_rounded,
                      iconColor: const Color(0xFF6739B7),
                      isSelected: selectedMethod == 'PhonePe / Paytm UPI',
                      onTap: () => setSheetState(
                          () => selectedMethod = 'PhonePe / Paytm UPI'),
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentMethodTile(
                      title: 'Debit / Credit Card',
                      subtitle: 'Visa, MasterCard, RuPay',
                      icon: Icons.credit_card_rounded,
                      iconColor: primaryBlue,
                      isSelected: selectedMethod == 'Debit / Credit Card',
                      onTap: () => setSheetState(
                          () => selectedMethod = 'Debit / Credit Card'),
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentMethodTile(
                      title: 'Net Banking',
                      subtitle: 'All major Indian banks supported',
                      icon: Icons.account_balance_rounded,
                      iconColor: const Color(0xFFD97706),
                      isSelected: selectedMethod == 'Net Banking',
                      onTap: () => setSheetState(
                          () => selectedMethod = 'Net Banking'),
                    ),
                    const SizedBox(height: 24),

                    // Proceed Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isAdding
                            ? null
                            : () async {
                                final entered = amountController.text.trim();
                                final parsed = double.tryParse(entered);
                                if (parsed == null || parsed <= 0) {
                                  showCooliToast(
                                    context,
                                    message: 'Please enter a valid amount',
                                    icon: Icons.error_outline_rounded,
                                    iconColor: CooliColors.danger,
                                  );
                                  return;
                                }

                                setSheetState(() => isAdding = true);
                                final result =
                                    await context.read<WalletViewModel>().addFunds(
                                          amount: parsed,
                                          paymentMethod: selectedMethod,
                                        );

                                if (!mounted) return;
                                setSheetState(() => isAdding = false);
                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                }

                                if (result.success) {
                                  if (mounted) {
                                    _showAddedSuccessDialog(
                                        parsed, result.newBalance);
                                  }
                                } else {
                                  if (mounted) {
                                    showCooliToast(
                                      this.context,
                                      message: result.message,
                                      icon: Icons.warning_amber_rounded,
                                      iconColor: CooliColors.warning,
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          disabledBackgroundColor:
                              primaryBlue.withValues(alpha: 0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isAdding
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_circle_outline_rounded,
                                      color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    amountController.text.trim().isNotEmpty
                                        ? 'Proceed to Add ₹${amountController.text.trim()}'
                                        : 'Proceed to Add',
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
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentMethodTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : CooliColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primaryBlue : CooliColors.border,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: CooliColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: CooliColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? primaryBlue : CooliColors.textLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddedSuccessDialog(double addedAmount, double newBalance) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF059669),
                size: 42,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Money Added Successfully!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: CooliColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${addedAmount.toStringAsFixed(0)} has been credited to your Cooli Wallet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: CooliColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CooliColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CooliColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Updated Balance',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: CooliColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '₹ ${newBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: primaryBlue,
                    ),
                  ),
                ],
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

  void _showTransactionDetails(WalletTransactionModel txn) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CooliColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: txn.isCredit
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                txn.isCredit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: txn.isCredit
                    ? const Color(0xFF059669)
                    : const Color(0xFFEF4444),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${txn.isCredit ? '+' : '-'} ₹ ${txn.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: txn.isCredit
                    ? const Color(0xFF059669)
                    : CooliColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              txn.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CooliColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CooliColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CooliColors.border),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Transaction ID', txn.id),
                  const Divider(height: 16, color: CooliColors.border),
                  _buildDetailRow('Status', txn.status,
                      valueColor: const Color(0xFF059669)),
                  const Divider(height: 16, color: CooliColors.border),
                  _buildDetailRow('Payment Mode', txn.paymentMethod),
                  const Divider(height: 16, color: CooliColors.border),
                  _buildDetailRow('Category', txn.category),
                  if (txn.referenceId != null) ...[
                    const Divider(height: 16, color: CooliColors.border),
                    _buildDetailRow('Reference Ref', txn.referenceId!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: txn.id));
                  Navigator.pop(ctx);
                  showCooliToast(
                    context,
                    message: 'Transaction ID copied to clipboard',
                    icon: Icons.copy_rounded,
                    iconColor: primaryBlue,
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16, color: primaryBlue),
                label: const Text(
                  'Copy Transaction ID',
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {Color valueColor = CooliColors.textDark}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: CooliColors.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
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
          'Cooli Wallet',
          style: TextStyle(
            color: CooliColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: CooliColors.textDark, size: 22),
            onPressed: _loadWalletData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: CooliColors.border, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryBlue),
            )
          : RefreshIndicator(
              color: primaryBlue,
              onRefresh: _loadWalletData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Premium Wallet Balance Card
                    _buildBalanceCard(),
                    const SizedBox(height: 16),

                    // 2. Quick Action Buttons
                    _buildActionButtons(),
                    const SizedBox(height: 20),

                    // 3. Quick Top-Up Strip
                    _buildQuickTopUpStrip(),
                    const SizedBox(height: 20),

                    // 4. Perks Banner
                    _buildPerksBanner(),
                    const SizedBox(height: 24),

                    // 5. Transaction History Header & Filter
                    _buildTransactionHeader(),
                    const SizedBox(height: 12),

                    // 6. Transaction List
                    _buildTransactionList(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    final balanceText = _isBalanceVisible
        ? '₹ ${_wallet.balance.toStringAsFixed(2)}'
        : '₹ • • • • • •';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E1B4B), // Deep Indigo
            Color(0xFF312E81),
            Color(0xFF4F46E5), // Cooli Indigo
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
            offset: const Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'TOTAL WALLET BALANCE',
                    style: TextStyle(
                      color: Color(0xFFC7D2FE),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _isBalanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () {
                  context.read<WalletViewModel>().toggleBalanceVisibility();
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Balance Display
          Text(
            balanceText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),

          // Bottom card metadata
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _userName.isNotEmpty ? _userName : 'Cooli Transporter',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.5),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Color(0xFF34D399), size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Verified Wallet',
                      style: TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Add Money (Primary)
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _openAddMoneySheet(),
              icon: const Icon(Icons.add_circle_outline_rounded,
                  color: Colors.white, size: 18),
              label: const Text(
                'Add Money',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Transfer / Withdraw
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                showCooliToast(
                  context,
                  message: 'Transfer feature available soon for verified accounts',
                  icon: Icons.info_outline_rounded,
                  iconColor: primaryBlue,
                );
              },
              icon: const Icon(Icons.north_east_rounded,
                  color: CooliColors.textDark, size: 16),
              label: const Text(
                'Transfer',
                style: TextStyle(
                  color: CooliColors.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: CooliColors.border),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTopUpStrip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CooliColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Top Up',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: CooliColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [500.0, 1000.0, 2000.0, 5000.0].map((amt) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openAddMoneySheet(amt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '+ ₹${amt.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPerksBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Color(0xFF059669),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zero Transaction Fees',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF065F46),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Enjoy 100% free advance and freight settlements via Cooli Wallet',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF047857),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaction History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: CooliColors.textDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: ['All', 'Credits', 'Debits'].map((filter) {
            final isSelected = _activeFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  context.read<WalletViewModel>().setFilter(filter);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? CooliColors.textDark
                        : CooliColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : CooliColors.textMuted,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    final list = _filteredTransactions;
    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: CooliColors.border),
        ),
        child: const Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 36, color: CooliColors.textLight),
            SizedBox(height: 10),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: CooliColors.textDark,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CooliColors.border),
        boxShadow: CooliShadows.card,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: CooliColors.border),
        itemBuilder: (context, index) {
          final txn = list[index];
          final dateStr =
              '${txn.date.day.toString().padLeft(2, '0')}/${txn.date.month.toString().padLeft(2, '0')} ${txn.date.hour.toString().padLeft(2, '0')}:${txn.date.minute.toString().padLeft(2, '0')}';

          return InkWell(
            borderRadius: index == 0
                ? const BorderRadius.vertical(top: Radius.circular(20))
                : (index == list.length - 1
                    ? const BorderRadius.vertical(bottom: Radius.circular(20))
                    : BorderRadius.zero),
            onTap: () => _showTransactionDetails(txn),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: txn.isCredit
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      txn.isCredit
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: txn.isCredit
                          ? const Color(0xFF059669)
                          : CooliColors.textDark,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          txn.title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: CooliColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$dateStr • ${txn.paymentMethod}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: CooliColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${txn.isCredit ? '+' : '-'} ₹${txn.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: txn.isCredit
                              ? const Color(0xFF059669)
                              : CooliColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: CooliColors.border),
                        ),
                        child: Text(
                          txn.category,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: CooliColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
