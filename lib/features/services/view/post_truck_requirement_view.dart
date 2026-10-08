import 'package:flutter/material.dart';
import 'package:cooli/features/services/view/service_confirmed_view.dart';

class PostTruckRequirementView extends StatefulWidget {
  static const String routeName = '/post-truck-requirement';
  final String? initialTruckType;
  final String? initialWeight;
  final String? initialFare;

  const PostTruckRequirementView({
    super.key,
    this.initialTruckType,
    this.initialWeight,
    this.initialFare,
  });

  @override
  State<PostTruckRequirementView> createState() => _PostTruckRequirementViewState();
}

class _PostTruckRequirementViewState extends State<PostTruckRequirementView> {
  late String _pickupLocation;
  late String _dropLocation;
  late String _materialType;
  late String _loadWeight;
  late String _truckType;
  late String _pickupDateTime;
  late String _expectedFare;
  late String _specialRequirements;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _pickupLocation = 'Kochi, Kerala';
    _dropLocation = 'Calicut, Kerala';
    _materialType = 'Construction Material';
    _loadWeight = widget.initialWeight ?? '15 Tons';
    _truckType = widget.initialTruckType ?? 'Open Body (10-20T)';
    _pickupDateTime = '22 Apr 2025, 10:00 AM';
    _expectedFare = widget.initialFare != null ? '₹ ${widget.initialFare}' : '₹ 18,000 – 22,000';
    _specialRequirements = '• Cover required\n• No night travel';
  }

  void _editField({
    required String title,
    required String currentValue,
    required Function(String) onSave,
    List<String>? options,
  }) {
    if (options != null) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select $title',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              ...options.map(
                (opt) => ListTile(
                  title: Text(
                    opt,
                    style: TextStyle(
                      fontWeight: opt == currentValue ? FontWeight.w800 : FontWeight.w500,
                      color: opt == currentValue ? const Color(0xFF4F46E5) : const Color(0xFF0F172A),
                    ),
                  ),
                  trailing: opt == currentValue
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4F46E5))
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    onSave(opt);
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    } else {
      final textController = TextEditingController(text: currentValue);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Update $title',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          content: TextField(
            controller: textController,
            maxLines: title.contains('Requirements') ? 3 : 1,
            decoration: InputDecoration(
              hintText: 'Enter $title',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  onSave(textController.text.trim());
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildRequirementCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Icon Box
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF4F46E5),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Middle Labels
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right Chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 24),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? const Color(0xFFEF4444) : const Color(0xFF475569),
              size: 24,
            ),
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFavorite ? 'Saved to requirement templates' : 'Removed from templates'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          // Background soft gradient wave at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 180,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEEF2FF).withValues(alpha: 0.0),
                    const Color(0xFFE0E7FF).withValues(alpha: 0.6),
                    const Color(0xFFC7D2FE).withValues(alpha: 0.4),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Screen Title & Subtitle
                        const Text(
                          'Post Truck Requirement',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tell us what you need. Transporters will bid on your requirement.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 1. Pickup Location
                        _buildRequirementCard(
                          icon: Icons.location_on_outlined,
                          label: 'Pickup Location',
                          value: _pickupLocation,
                          onTap: () => _editField(
                            title: 'Pickup Location',
                            currentValue: _pickupLocation,
                            onSave: (v) => setState(() => _pickupLocation = v),
                            options: [
                              'Kochi, Kerala',
                              'Ernakulam South Hub, Kerala',
                              'Kochi Port & SEZ, Kerala',
                              'Aluva Industrial Zone, Kerala',
                            ],
                          ),
                        ),

                        // 2. Drop Location
                        _buildRequirementCard(
                          icon: Icons.pin_drop_outlined,
                          label: 'Drop Location',
                          value: _dropLocation,
                          onTap: () => _editField(
                            title: 'Drop Location',
                            currentValue: _dropLocation,
                            onSave: (v) => setState(() => _dropLocation = v),
                            options: [
                              'Calicut, Kerala',
                              'Bengaluru Logistics Park, KA',
                              'Chennai Port Terminal, TN',
                              'Coimbatore SIDCO Hub, TN',
                              'Thrissur Town, Kerala',
                            ],
                          ),
                        ),

                        // 3. Material Type
                        _buildRequirementCard(
                          icon: Icons.inventory_2_outlined,
                          label: 'Material Type',
                          value: _materialType,
                          onTap: () => _editField(
                            title: 'Material Type',
                            currentValue: _materialType,
                            onSave: (v) => setState(() => _materialType = v),
                            options: [
                              'Construction Material',
                              'Cement & Aggregates',
                              'Steel & Iron Coils',
                              'FMCG & Consumer Goods',
                              'Industrial Machinery',
                              'Timber & Plywood',
                            ],
                          ),
                        ),

                        // 4. Load Weight / Quantity
                        _buildRequirementCard(
                          icon: Icons.scale_outlined,
                          label: 'Load Weight / Quantity',
                          value: _loadWeight,
                          onTap: () => _editField(
                            title: 'Load Weight / Quantity',
                            currentValue: _loadWeight,
                            onSave: (v) => setState(() => _loadWeight = v),
                            options: [
                              '5 Tons',
                              '10 Tons',
                              '15 Tons',
                              '20 Tons',
                              '25 Tons',
                              '32 Tons',
                            ],
                          ),
                        ),

                        // 5. Truck Type
                        _buildRequirementCard(
                          icon: Icons.local_shipping_outlined,
                          label: 'Truck Type',
                          value: _truckType,
                          onTap: () => _editField(
                            title: 'Truck Type',
                            currentValue: _truckType,
                            onSave: (v) => setState(() => _truckType = v),
                            options: [
                              'Open Body (10-20T)',
                              'Container Box (15-20T)',
                              'Multi-Axle Trailer (25-32T)',
                              'Tipper (10-16T)',
                              'Flatbed Heavy (32T+)',
                            ],
                          ),
                        ),

                        // 6. Pickup Date & Time
                        _buildRequirementCard(
                          icon: Icons.calendar_today_outlined,
                          label: 'Pickup Date & Time',
                          value: _pickupDateTime,
                          onTap: () async {
                            final now = DateTime.now();
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: now,
                              firstDate: now,
                              lastDate: now.add(const Duration(days: 90)),
                            );
                            if (pickedDate == null) return;
                            if (!context.mounted) return;
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 10, minute: 0),
                            );
                            if (pickedTime == null) return;
                            if (!mounted) return;
                            setState(() {
                              final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                              final period = pickedTime.period == DayPeriod.am ? 'AM' : 'PM';
                              final hour = pickedTime.hourOfPeriod == 0 ? 12 : pickedTime.hourOfPeriod;
                              final minute = pickedTime.minute.toString().padLeft(2, '0');
                              _pickupDateTime = '${pickedDate.day} ${months[pickedDate.month - 1]} ${pickedDate.year}, $hour:$minute $period';
                            });
                          },
                        ),

                        // 7. Expected Fare / Budget
                        _buildRequirementCard(
                          icon: Icons.currency_rupee_rounded,
                          label: 'Expected Fare / Budget',
                          value: _expectedFare,
                          onTap: () => _editField(
                            title: 'Expected Fare / Budget',
                            currentValue: _expectedFare,
                            onSave: (v) => setState(() => _expectedFare = v),
                            options: [
                              '₹ 12,000 – 15,000',
                              '₹ 15,000 – 18,000',
                              '₹ 18,000 – 22,000',
                              '₹ 22,000 – 26,000',
                              '₹ 26,000 – 32,000',
                            ],
                          ),
                        ),

                        // 8. Special Requirements
                        _buildRequirementCard(
                          icon: Icons.format_list_bulleted_rounded,
                          label: 'Special Requirements',
                          value: _specialRequirements,
                          onTap: () => _editField(
                            title: 'Special Requirements',
                            currentValue: _specialRequirements,
                            onSave: (v) => setState(() => _specialRequirements = v),
                          ),
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),

                // Bottom Action CTA Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  color: Colors.transparent,
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ServiceConfirmedView(
                              bookingId: 'CL-2025-0422-0018',
                              truckNumber: 'TN 11 AB 4321',
                              driverName: 'Ramesh Kumar',
                              driverPhone: '+91 98765 43210',
                              pickupTime: _pickupDateTime,
                              truckType: _truckType,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Confirm Requirement',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
