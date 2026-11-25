import 'package:flutter/material.dart';
import 'package:cooli/features/ride/model/ride_model.dart';
import 'package:cooli/features/ride/view_model/ride_view_model.dart';
import 'package:cooli/utils/cooli_theme.dart';

enum PlanRideField { pickup, drop }

/// Uber-style "Plan your ride" modal sheet with connected pickup/dropoff inputs,
/// swap button, optional stop, and live filtered destination suggestions.
class PlanRideSheet extends StatefulWidget {
  final RideViewModel viewModel;
  final PlanRideField initialFocus;
  final VoidCallback onSetOnMap;
  final VoidCallback onRouteReady;

  const PlanRideSheet({
    super.key,
    required this.viewModel,
    this.initialFocus = PlanRideField.drop,
    required this.onSetOnMap,
    required this.onRouteReady,
  });

  @override
  State<PlanRideSheet> createState() => _PlanRideSheetState();
}

class _PlanRideSheetState extends State<PlanRideSheet> {
  late TextEditingController _pickupCtrl;
  late TextEditingController _dropCtrl;
  late TextEditingController _stopCtrl;
  late FocusNode _pickupFocus;
  late FocusNode _dropFocus;
  late PlanRideField _activeField;
  bool _showStopField = false;

  @override
  void initState() {
    super.initState();
    _pickupCtrl = TextEditingController(text: widget.viewModel.pickupLocation);
    _dropCtrl = TextEditingController(
      text: widget.viewModel.hasDestination ? widget.viewModel.dropLocation : '',
    );
    _stopCtrl = TextEditingController(text: widget.viewModel.stopLocation ?? '');
    _showStopField = widget.viewModel.stopLocation != null;

    _pickupFocus = FocusNode();
    _dropFocus = FocusNode();
    _activeField = widget.initialFocus;

    _pickupFocus.addListener(() {
      if (_pickupFocus.hasFocus && mounted) {
        setState(() => _activeField = PlanRideField.pickup);
      }
    });
    _dropFocus.addListener(() {
      if (_dropFocus.hasFocus && mounted) {
        setState(() => _activeField = PlanRideField.drop);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.initialFocus == PlanRideField.pickup) {
        _pickupFocus.requestFocus();
      } else {
        _dropFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropCtrl.dispose();
    _stopCtrl.dispose();
    _pickupFocus.dispose();
    _dropFocus.dispose();
    super.dispose();
  }

  String get _activeQuery =>
      _activeField == PlanRideField.pickup ? _pickupCtrl.text : _dropCtrl.text;

  void _selectSuggestion(RidePlace place) {
    if (_activeField == PlanRideField.pickup) {
      widget.viewModel.setPickupPlace(place);
      _pickupCtrl.text = place.title;
      if (_dropCtrl.text.trim().isEmpty) {
        _dropFocus.requestFocus();
        setState(() => _activeField = PlanRideField.drop);
      } else {
        Navigator.pop(context);
        widget.onRouteReady();
      }
    } else {
      widget.viewModel.setDropPlace(place);
      if (_showStopField && _stopCtrl.text.trim().isNotEmpty) {
        widget.viewModel.setStop(_stopCtrl.text.trim());
      }
      Navigator.pop(context);
      widget.onRouteReady();
    }
  }

  void _applyCustomText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (_activeField == PlanRideField.pickup) {
      widget.viewModel.setPickup(trimmed);
      _dropFocus.requestFocus();
      setState(() => _activeField = PlanRideField.drop);
    } else {
      widget.viewModel.setDrop(trimmed);
      if (_showStopField && _stopCtrl.text.trim().isNotEmpty) {
        widget.viewModel.setStop(_stopCtrl.text.trim());
      }
      Navigator.pop(context);
      widget.onRouteReady();
    }
  }

  void _handleSwap() {
    if (_dropCtrl.text.trim().isEmpty) return;
    widget.viewModel.setPickup(_pickupCtrl.text);
    widget.viewModel.setDrop(_dropCtrl.text);
    widget.viewModel.swapPickupAndDrop();
    setState(() {
      _pickupCtrl.text = widget.viewModel.pickupLocation;
      _dropCtrl.text = widget.viewModel.dropLocation;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final suggestions = vm.searchPlaces(_activeQuery);
    final customQuery = _activeQuery.trim();
    final hasExactMatch = suggestions.any(
      (p) => p.title.toLowerCase() == customQuery.toLowerCase(),
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: CooliColors.textDark),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Plan your ride',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: CooliColors.textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: CooliColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_filled_rounded,
                          size: 14, color: CooliColors.textDark),
                      const SizedBox(width: 4),
                      Text(
                        vm.scheduleType == RideScheduleType.now ? 'Now' : 'Later',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: CooliColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Connected Pickup / Stop / Drop Input Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: CooliColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Vertical Stepper Dots
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      Container(
                        width: 2,
                        height: _showStopField ? 30 : 28,
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        color: const Color(0xFFCBD5E1),
                      ),
                      if (_showStopField) ...[
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: CooliColors.primary, width: 2),
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 28,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          color: const Color(0xFFCBD5E1),
                        ),
                      ],
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Input Fields
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildInputRow(
                          controller: _pickupCtrl,
                          focusNode: _pickupFocus,
                          hint: 'Pickup location',
                          isActive: _activeField == PlanRideField.pickup,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: _applyCustomText,
                          onClear: () {
                            _pickupCtrl.clear();
                            setState(() {});
                          },
                        ),
                        const Divider(height: 12, color: Color(0xFFE2E8F0)),
                        if (_showStopField) ...[
                          _buildInputRow(
                            controller: _stopCtrl,
                            hint: 'Add a stop (optional)',
                            isActive: false,
                            onChanged: (v) => vm.setStop(v),
                            onSubmitted: (v) => vm.setStop(v),
                            onClear: () {
                              _stopCtrl.clear();
                              vm.setStop(null);
                              setState(() => _showStopField = false);
                            },
                          ),
                          const Divider(height: 12, color: Color(0xFFE2E8F0)),
                        ],
                        _buildInputRow(
                          controller: _dropCtrl,
                          focusNode: _dropFocus,
                          hint: 'Where to?',
                          isActive: _activeField == PlanRideField.drop,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: _applyCustomText,
                          onClear: () {
                            _dropCtrl.clear();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Swap & Add Stop Controls
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Swap locations',
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.swap_vert_rounded,
                            color: CooliColors.textDark, size: 22),
                        onPressed: _handleSwap,
                      ),
                      const SizedBox(height: 4),
                      IconButton(
                        tooltip: _showStopField ? 'Remove stop' : 'Add stop',
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          _showStopField ? Icons.remove_circle_outline : Icons.add_circle_outline,
                          color: CooliColors.primary,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _showStopField = !_showStopField;
                            if (!_showStopField) {
                              _stopCtrl.clear();
                              vm.setStop(null);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Quick Utility Pills: Current Location & Set on Map
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _buildActionPill(
                  icon: Icons.my_location_rounded,
                  label: 'Current location',
                  onTap: () {
                    vm.setPickup('Current Location');
                    _pickupCtrl.text = vm.pickupLocation;
                    _dropFocus.requestFocus();
                    setState(() => _activeField = PlanRideField.drop);
                  },
                ),
                const SizedBox(width: 10),
                _buildActionPill(
                  icon: Icons.map_outlined,
                  label: 'Set on map',
                  onTap: () {
                    Navigator.pop(context);
                    widget.onSetOnMap();
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Suggestions List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (customQuery.isNotEmpty && !hasExactMatch)
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: CooliColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.search_rounded, color: CooliColors.primary),
                    ),
                    title: Text(
                      'Use "$customQuery"',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: CooliColors.textDark,
                      ),
                    ),
                    subtitle: Text(
                      _activeField == PlanRideField.pickup
                          ? 'Set as pickup point'
                          : 'Confirm destination',
                      style: const TextStyle(fontSize: 12, color: CooliColors.textMuted),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => _applyCustomText(customQuery),
                  ),
                ...suggestions.map((place) {
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(place.icon, color: CooliColors.textDark, size: 20),
                    ),
                    title: Text(
                      place.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: CooliColors.textDark,
                      ),
                    ),
                    subtitle: Text(
                      place.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: CooliColors.textMuted),
                    ),
                    trailing: Text(
                      '${place.distanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CooliColors.textMuted,
                      ),
                    ),
                    onTap: () => _selectSuggestion(place),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String hint,
    required bool isActive,
    required ValueChanged<String> onChanged,
    required ValueChanged<String> onSubmitted,
    required VoidCallback onClear,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: CooliColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: CooliColors.textLight,
                fontWeight: FontWeight.w500,
              ),
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ),
        if (controller.text.isNotEmpty)
          GestureDetector(
            onTap: onClear,
            child: const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.close_rounded, size: 17, color: CooliColors.textLight),
            ),
          ),
      ],
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: CooliColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CooliColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: CooliColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CooliColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
