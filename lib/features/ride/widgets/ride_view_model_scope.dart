import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/ride/view_model/ride_view_model.dart';

/// Resolves the shared [RideViewModel] from the widget tree when present,
/// or creates a scoped fallback instance when a ride screen is mounted alone.
class RideViewModelScope extends StatefulWidget {
  final Widget Function(BuildContext context, RideViewModel vm) builder;

  const RideViewModelScope({
    super.key,
    required this.builder,
  });

  @override
  State<RideViewModelScope> createState() => _RideViewModelScopeState();
}

class _RideViewModelScopeState extends State<RideViewModelScope> {
  RideViewModel? _fallbackViewModel;
  RideViewModel? _resolvedViewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolvedViewModel != null) return;
    try {
      _resolvedViewModel = Provider.of<RideViewModel>(context, listen: false);
    } on ProviderNotFoundException {
      _fallbackViewModel = RideViewModel();
      _resolvedViewModel = _fallbackViewModel;
    }
  }

  @override
  void dispose() {
    _fallbackViewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_fallbackViewModel != null) {
      return ChangeNotifierProvider<RideViewModel>.value(
        value: _fallbackViewModel!,
        child: Consumer<RideViewModel>(
          builder: (context, vm, _) => widget.builder(context, vm),
        ),
      );
    }
    return Consumer<RideViewModel>(
      builder: (context, vm, _) => widget.builder(context, vm),
    );
  }
}
