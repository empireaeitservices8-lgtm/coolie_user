import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/ecommerce/model/order_model.dart';
import 'package:cooli/features/ecommerce/view_model/ecommerce_view_model.dart';
import 'package:cooli/features/ecommerce/view/ecommerce_home_view.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/widgets/cooli_widgets.dart';

class MyOrdersView extends StatefulWidget {
  static const String routeName = '/my-orders';

  const MyOrdersView({super.key});

  @override
  State<MyOrdersView> createState() => _MyOrdersViewState();
}

class _MyOrdersViewState extends State<MyOrdersView> {
  EcommerceViewModel get _vm => context.watch<EcommerceViewModel>();
  List<OrderModel> get _filteredOrders => _vm.filteredOrders;
  bool get _isLoading => _vm.isLoadingOrders;
  String get _activeFilter => _vm.orderFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EcommerceViewModel>().fetchUserOrders();
    });
  }

  Future<void> _fetchOrders() async {
    await context.read<EcommerceViewModel>().fetchUserOrders();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Recent';
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
    final month = months[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $month ${dt.year}, $hour:$minute';
  }

  void _showOrderDetails(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderId,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: CooliColors.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(order.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: CooliColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: CooliColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 20, color: CooliColors.border),

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status & Payment Summary
                      Row(
                        children: [
                          _buildStatusTag(order.status),
                          const SizedBox(width: 8),
                          _buildPaymentTag(order.paymentStatus),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Ordered Items List
                      const Text(
                        'Items Ordered',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: CooliColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: CooliColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: CooliColors.border),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: order.items.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: CooliColors.border),
                          itemBuilder: (context, idx) {
                            final item = order.items[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: Text(
                                      '${item.quantity}x',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: CooliColors.rideBlue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: CooliColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '₹${item.unitPrice.toStringAsFixed(2)} per unit',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: CooliColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${item.totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: CooliColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Delivery Address Details
                      if (order.deliveryAddressDetails != null) ...[
                        const Text(
                          'Delivery Address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: CooliColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: CooliColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: CooliColors.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.home_outlined,
                                  color: CooliColors.primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  order.deliveryAddressDetails!.fullAddress,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: CooliColors.textDark,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Bill Summary
                      const Text(
                        'Payment Summary',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: CooliColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: CooliColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: CooliColors.border),
                        ),
                        child: Column(
                          children: [
                            _buildPriceRow('Items Subtotal',
                                '₹ ${order.subtotal.toStringAsFixed(2)}'),
                            const SizedBox(height: 8),
                            _buildPriceRow('Delivery Charge',
                                '₹ ${order.deliveryCharge.toStringAsFixed(2)}'),
                            if (order.discountAmount > 0) ...[
                              const SizedBox(height: 8),
                              _buildPriceRow('Discount',
                                  '- ₹ ${order.discountAmount.toStringAsFixed(2)}',
                                  color: const Color(0xFF059669)),
                            ],
                            const Divider(
                                height: 16, color: CooliColors.border),
                            _buildPriceRow(
                              'Total Paid',
                              '₹ ${order.totalAmount.toStringAsFixed(2)}',
                              isBold: true,
                              fontSize: 15,
                              color: CooliColors.textDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Copy Order ID Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: order.orderId));
                            Navigator.pop(ctx);
                            showCooliToast(
                              context,
                              message: 'Order ID copied to clipboard',
                              icon: Icons.copy_rounded,
                              iconColor: CooliColors.rideBlue,
                            );
                          },
                          icon: const Icon(Icons.copy_rounded,
                              size: 16, color: CooliColors.rideBlue),
                          label: const Text(
                            'Copy Order ID',
                            style: TextStyle(
                              color: CooliColors.rideBlue,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: CooliColors.rideBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 13,
    Color color = CooliColors.textDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: isBold ? CooliColors.textDark : CooliColors.textMuted,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTag(String status) {
    Color bg = const Color(0xFFFFFBEB);
    Color border = const Color(0xFFFDE68A);
    Color text = const Color(0xFFD97706);
    IconData icon = Icons.schedule_rounded;

    if (status.toLowerCase() == 'delivered') {
      bg = const Color(0xFFECFDF5);
      border = const Color(0xFFA7F3D0);
      text = const Color(0xFF059669);
      icon = Icons.check_circle_rounded;
    } else if (status.toLowerCase() == 'cancelled') {
      bg = const Color(0xFFFEE2E2);
      border = const Color(0xFFFECACA);
      text = const Color(0xFFDC2626);
      icon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTag(String paymentStatus) {
    final isPaid = paymentStatus.toLowerCase() == 'paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPaid ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaid ? Icons.check_rounded : Icons.pending_rounded,
            size: 12,
            color: isPaid ? const Color(0xFF059669) : CooliColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            isPaid ? 'PAID' : 'PAYMENT PENDING',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: isPaid ? const Color(0xFF059669) : CooliColors.textMuted,
            ),
          ),
        ],
      ),
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
          'My Orders',
          style: TextStyle(
            color: CooliColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: CooliColors.textDark, size: 22),
            onPressed: _fetchOrders,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: CooliColors.border, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: CooliColors.ecommerceOrange),
            )
          : RefreshIndicator(
              color: CooliColors.ecommerceOrange,
              onRefresh: _fetchOrders,
              child: Column(
                children: [
                  // Filter Chips Bar
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Pending', 'Paid', 'Delivered']
                            .map((filter) {
                          final isSelected = _activeFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                context
                                    .read<EcommerceViewModel>()
                                    .setOrderFilter(filter);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? CooliColors.ecommerceOrange
                                      : CooliColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  filter,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : CooliColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: CooliColors.border),

                  // Orders List
                  Expanded(
                    child: _filteredOrders.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = _filteredOrders[index];
                              return _buildOrderCard(order);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFEDD5), width: 2),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: CooliColors.ecommerceOrange,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Orders Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: CooliColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You haven\'t placed any orders in this category yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: CooliColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, EcommerceHomeView.routeName);
              },
              icon: const Icon(Icons.shopping_bag_outlined,
                  size: 16, color: Colors.white),
              label: const Text(
                'Browse Materials Store',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: CooliColors.ecommerceOrange,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CooliColors.border),
        boxShadow: CooliShadows.card,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showOrderDetails(order),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header: Order ID & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: CooliColors.ecommerceOrange,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        order.orderId,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: CooliColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  _buildStatusTag(order.status),
                ],
              ),
              const SizedBox(height: 8),

              // Date & Payment tag row
              Row(
                children: [
                  const Icon(Icons.event_outlined,
                      size: 13, color: CooliColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(order.createdAt),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: CooliColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  _buildPaymentTag(order.paymentStatus),
                ],
              ),
              const Divider(height: 18, color: CooliColors.border),

              // Items Summary
              Column(
                children: order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: CooliColors.ecommerceOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${item.productName} (${item.quantity} units)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: CooliColors.textDark,
                            ),
                          ),
                        ),
                        Text(
                          '₹ ${item.totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: CooliColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              // Address Preview
              if (order.deliveryAddressDetails != null) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: CooliColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.deliveryAddressDetails!.fullAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: CooliColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 18, color: CooliColors.border),

              // Card Bottom: Total Amount & Action Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 11,
                          color: CooliColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '₹ ${order.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: CooliColors.ecommerceOrange,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _showOrderDetails(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFF6FF),
                      foregroundColor: CooliColors.rideBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 11),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
