import 'package:flutter/material.dart';
import 'package:cooli/features/services/view/blackbuck_vehicle_selection_view.dart';

class ServicesHomeView extends StatelessWidget {
  static const String routeName = '/services-home';

  const ServicesHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const BlackbuckVehicleSelectionView();
  }
}
