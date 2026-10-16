import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/services/view_model/services_view_model.dart';
import 'package:cooli/features/services/view/service_confirmed_view.dart';
import 'package:cooli/features/wallet/view_model/wallet_view_model.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';

class BookServiceView extends StatefulWidget {
  static const String routeName = '/book-service';

  const BookServiceView({super.key});

  @override
  State<BookServiceView> createState() => _BookServiceViewState();
}

class _BookServiceViewState extends State<BookServiceView> {
  String _paymentMethod = 'Cash on Delivery';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WalletViewModel>().loadWalletData(userId: 1);
      }
    });
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
          'Book Service',
          style: TextStyle(
            color: CooliColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<ServicesViewModel>(
        builder: (context, vm, child) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Select Date
                      _buildSectionHeader('Select Date'),
                      const SizedBox(height: 8),
                      _buildPickerCard(
                        icon: Icons.calendar_today_rounded,
                        title: vm.selectedDate,
                        onTap: () {},
                      ),

                      const SizedBox(height: 20),

                      // Select Time
                      _buildSectionHeader('Select Time'),
                      const SizedBox(height: 8),
                      _buildPickerCard(
                        icon: Icons.access_time_rounded,
                        title: vm.selectedTime,
                        onTap: () {},
                      ),

                      const SizedBox(height: 20),

                      // Address
                      _buildSectionHeader('Address'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: CooliShadows.card,
                          border: Border.all(color: CooliColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: CooliColors.primarySoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: CooliColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Home',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: CooliColors.textDark,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Kochi, Kerala',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: CooliColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Change',
                                style: TextStyle(
                                  color: CooliColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Payment Method
                      _buildSectionHeader('Payment Method'),
                      const SizedBox(height: 8),
                      Consumer<WalletViewModel>(
                        builder: (context, walletVM, _) {
                          final balance = walletVM.balance;
                          return Column(
                            children: [
                              _buildPaymentTile(
                                id: 'Cash on Delivery',
                                title: 'Cash on Delivery',
                                subtitle: 'Pay cash to technician after service',
                                icon: Icons.payments_rounded,
                                iconColor: const Color(0xFF16A34A),
                              ),
                              const SizedBox(height: 8),
                              _buildPaymentTile(
                                id: 'UPI',
                                title: 'UPI Payment',
                                subtitle: 'Instant pay via Google Pay, PhonePe, Paytm',
                                icon: Icons.account_balance_rounded,
                                iconColor: const Color(0xFF2563EB),
                              ),
                              const SizedBox(height: 8),
                              _buildPaymentTile(
                                id: 'Coolie Wallet',
                                title: 'Coolie Wallet',
                                subtitle: 'Available Balance: ₹${balance.toStringAsFixed(2)}',
                                icon: Icons.account_balance_wallet_rounded,
                                iconColor: Colors.purple,
                                badge: '₹${balance.toStringAsFixed(0)}',
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom Action & Total Price
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
                      children: const [
                        Text(
                          'Total Price',
                          style: TextStyle(
                              fontSize: 12, color: CooliColors.textMuted),
                        ),
                        Text(
                          '₹499',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: CooliColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: CooliButton(
                        text: 'Confirm Booking',
                        onTap: () async {
                          if (_paymentMethod == 'Coolie Wallet') {
                            final walletVM = context.read<WalletViewModel>();
                            final balance = walletVM.balance;
                            if (balance < 499) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Insufficient wallet balance (₹${balance.toStringAsFixed(2)}). Please top up or pay with Cash/UPI.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            await walletVM.deductFunds(
                              amount: 499,
                              title: 'Home Service Booking',
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '₹499 deducted from Coolie Wallet. Remaining balance: ₹${walletVM.balance.toStringAsFixed(2)}',
                                  ),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            }
                          }

                          if (!context.mounted) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ServiceConfirmedView(
                                bookingId: 'SRV-2025-0422',
                                truckNumber: 'Technician Assigned',
                                driverName: 'Suresh Menon',
                                driverPhone: '+91 94470 12345',
                                pickupTime: '${vm.selectedDate}, ${vm.selectedTime}',
                                truckType: 'Plumbing & Repair Service',
                                paymentMethod: _paymentMethod,
                              ),
                            ),
                          );
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: CooliColors.textDark,
      ),
    );
  }

  Widget _buildPickerCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: CooliShadows.card,
        border: Border.all(color: CooliColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: CooliColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CooliColors.textDark,
              ),
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: CooliColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    String? badge,
  }) {
    final isSelected = _paymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: CooliShadows.card,
          border: Border.all(
            color: isSelected ? iconColor : CooliColors.border,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: CooliColors.textDark,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Text(
                            badge,
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CooliColors.textMuted,
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
                border: Border.all(
                  color: isSelected ? iconColor : const Color(0xFFCBD5E1),
                  width: 2,
                ),
                color: isSelected ? iconColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
