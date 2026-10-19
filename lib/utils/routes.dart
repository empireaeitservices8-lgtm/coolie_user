import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cooli/features/activity/view_model/activity_view_model.dart';
import 'package:cooli/features/ecommerce/view_model/ecommerce_view_model.dart';
import 'package:cooli/features/onboarding/view_model/onboarding_view_model.dart';
import 'package:cooli/features/porter/view_model/porter_view_model.dart';
import 'package:cooli/features/profile/view_model/profile_view_model.dart';
import 'package:cooli/features/ride/view_model/ride_view_model.dart';
import 'package:cooli/features/services/view_model/services_view_model.dart';
import 'package:cooli/features/splash/view_model/splash_view_model.dart';
import 'package:cooli/features/splash/view/splash_view.dart';
import 'package:cooli/features/onboarding/view/onboarding_view.dart';
import 'package:cooli/features/auth/view/login_view.dart';
import 'package:cooli/features/auth/view/register_view.dart';
import 'package:cooli/features/auth/view/register_details_view.dart';
import 'package:cooli/features/auth/view/otp_verification_view.dart';
import 'package:cooli/features/dashboard/view/main_navigation_view.dart';
import 'package:cooli/features/ecommerce/view/ecommerce_home_view.dart';
import 'package:cooli/features/ecommerce/view/product_detail_view.dart';
import 'package:cooli/features/ecommerce/view/cart_view.dart';
import 'package:cooli/features/ecommerce/view/checkout_view.dart';
import 'package:cooli/features/ecommerce/view/order_confirmed_view.dart';
import 'package:cooli/features/ecommerce/view/track_order_view.dart';
import 'package:cooli/features/ecommerce/view/my_orders_view.dart';
import 'package:cooli/features/ride/view/ride_booking_view.dart';
import 'package:cooli/features/ride/view/ride_selection_view.dart';
import 'package:cooli/features/ride/view/ride_searching_driver_view.dart';
import 'package:cooli/features/ride/view/ride_tracking_view.dart';
import 'package:cooli/features/ride/view/ride_completed_view.dart';
import 'package:cooli/features/ride/view/my_rides_view.dart';
import 'package:cooli/features/porter/view/porter_home_view.dart';
import 'package:cooli/features/porter/view/book_porter_view.dart';
import 'package:cooli/features/porter/view/track_porter_view.dart';
import 'package:cooli/features/porter/view/my_porter_bookings_view.dart';
import 'package:cooli/features/services/view/services_home_view.dart';
import 'package:cooli/features/services/view/blackbuck_find_loads_view.dart';
import 'package:cooli/features/services/view/blackbuck_loads_view.dart';
import 'package:cooli/features/services/view/blackbuck_load_details_view.dart';
import 'package:cooli/features/services/view/blackbuck_bidding_view.dart';
import 'package:cooli/features/services/model/blackbuck_load_model.dart';
import 'package:cooli/features/services/view/blackbuck_vehicle_selection_view.dart';
import 'package:cooli/features/services/view/post_truck_requirement_view.dart';
import 'package:cooli/features/services/view/bids_received_view.dart';
import 'package:cooli/features/services/view/blackbuck_track_truck_view.dart';
import 'package:cooli/features/services/view/blackbuck_delivery_completed_view.dart';
import 'package:cooli/features/services/view/my_shipments_view.dart';
import 'package:cooli/features/services/view/my_bookings_view.dart';
import 'package:cooli/features/address/view/saved_addresses_view.dart';
import 'package:cooli/features/address/view/add_address_view.dart';
import 'package:cooli/features/services/view/service_detail_view.dart';
import 'package:cooli/features/services/view/book_service_view.dart';
import 'package:cooli/features/services/view/service_confirmed_view.dart';
import 'package:cooli/features/profile/view/profile_view.dart';
import 'package:cooli/features/profile/view/edit_profile_view.dart';
import 'package:cooli/features/activity/view/activity_view.dart';
import 'package:cooli/features/wallet/view/wallet_view.dart';
import 'package:cooli/features/ecommerce/model/product_model.dart';
import 'package:cooli/features/services/model/service_model.dart';

Map<String, Widget Function(BuildContext context)> appRoutes() => {
      '/': (context) => ChangeNotifierProvider(
            create: (_) => SplashViewModel(),
            child: const SplashView(),
          ),
      SplashView.routeName: (context) => ChangeNotifierProvider(
            create: (_) => SplashViewModel(),
            child: const SplashView(),
          ),
      OnboardingView.routeName: (context) => ChangeNotifierProvider(
            create: (_) => OnboardingViewModel(),
            child: const OnboardingView(),
          ),
      LoginView.routeName: (context) => const LoginView(),
      RegisterView.routeName: (context) => const RegisterView(),
      RegisterDetailsView.routeName: (context) => const RegisterDetailsView(),
      OtpVerificationView.routeName: (context) => const OtpVerificationView(),
      MainNavigationView.routeName: (context) => const MainNavigationView(),
      EcommerceHomeView.routeName: (context) => ChangeNotifierProvider(
            create: (_) => EcommerceViewModel(),
            child: const EcommerceHomeView(),
          ),
      CartView.routeName: (context) => ChangeNotifierProvider(
            create: (_) => EcommerceViewModel(),
            child: const CartView(),
          ),
      CheckoutView.routeName: (context) => ChangeNotifierProvider(
            create: (_) => EcommerceViewModel(),
            child: const CheckoutView(),
          ),
      OrderConfirmedView.routeName: (context) => const OrderConfirmedView(),
      TrackOrderView.routeName: (context) => ChangeNotifierProvider(
            create: (_) => EcommerceViewModel(),
            child: const TrackOrderView(),
          ),
      MyOrdersView.routeName: (context) => const MyOrdersView(),
      RideBookingView.routeName: (context) => const RideBookingView(),
      RideSelectionView.routeName: (context) => ChangeNotifierProvider(
            create: (_) => RideViewModel(),
            child: const RideSelectionView(),
          ),
      RideSearchingDriverView.routeName: (context) =>
          const RideSearchingDriverView(),
      RideTrackingView.routeName: (context) => ChangeNotifierProvider(
            create: (_) => RideViewModel(),
            child: const RideTrackingView(),
          ),
      RideCompletedView.routeName: (context) => const RideCompletedView(),
      MyRidesView.routeName: (context) => const MyRidesView(),
      PorterHomeView.routeName: (context) => const PorterHomeView(),
      BookPorterView.routeName: (context) => ChangeNotifierProvider(
            create: (_) => PorterViewModel(),
            child: const BookPorterView(),
          ),
      MyPorterBookingsView.routeName: (context) => const MyPorterBookingsView(),
      ServicesHomeView.routeName: (context) => const ServicesHomeView(),
      BlackbuckFindLoadsView.routeName: (context) =>
          const BlackbuckFindLoadsView(),
      BlackbuckLoadsView.routeName: (context) => const BlackbuckLoadsView(),
      BlackbuckLoadDetailsView.routeName: (context) =>
          const BlackbuckLoadDetailsView(),
      BlackbuckBiddingView.routeName: (context) =>
          const BlackbuckBiddingView(),
      BlackbuckVehicleSelectionView.routeName: (context) =>
          const BlackbuckVehicleSelectionView(),
      PostTruckRequirementView.routeName: (context) =>
          const PostTruckRequirementView(),
      BidsReceivedView.routeName: (context) => const BidsReceivedView(),
      BlackbuckTrackTruckView.routeName: (context) =>
          const BlackbuckTrackTruckView(),
      BlackbuckDeliveryCompletedView.routeName: (context) =>
          const BlackbuckDeliveryCompletedView(),
      BookServiceView.routeName: (context) => ChangeNotifierProvider(
            create: (_) => ServicesViewModel(),
            child: const BookServiceView(),
          ),
      ServiceConfirmedView.routeName: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map<String, dynamic>) {
          return ServiceConfirmedView(
            bookingId: args['bookingId']?.toString() ?? 'CL-2025-0422-0018',
            truckNumber: args['truckNumber']?.toString() ?? 'TN 11 AB 4321',
            driverName: args['driverName']?.toString() ?? 'Ramesh Kumar',
            driverPhone: args['driverPhone']?.toString() ?? '+91 98765 43210',
            pickupTime: args['pickupTime']?.toString() ?? '22 Apr 2025, 10:00 AM',
            truckType: args['truckType']?.toString(),
            paymentMethod: args['paymentMethod']?.toString() ?? 'Cash on Delivery',
          );
        }
        return const ServiceConfirmedView();
      },
      ProfileView.routeName: (context) => ChangeNotifierProvider(
            create: (_) => ProfileViewModel(),
            child: const ProfileView(),
          ),
      ActivityView.routeName: (context) => ChangeNotifierProvider(
            create: (_) => ActivityViewModel(),
            child: const ActivityView(),
          ),
      WalletView.routeName: (context) => const WalletView(),
      MyShipmentsView.routeName: (context) => const MyShipmentsView(),
      MyBookingsView.routeName: (context) => const MyBookingsView(),
      SavedAddressesView.routeName: (context) => const SavedAddressesView(),
      AddAddressView.routeName: (context) => const AddAddressView(),
      EditProfileView.routeName: (context) => const EditProfileView(),
    };

Widget? _getScreen(RouteSettings settings) {
  switch (settings.name) {
    case ProductDetailView.routeName:
      final product = settings.arguments as ProductModel?;
      return ChangeNotifierProvider(
        create: (_) => EcommerceViewModel(),
        child: ProductDetailView(product: product),
      );
    case ServiceDetailView.routeName:
      final service = settings.arguments as HomeServiceModel?;
      return ChangeNotifierProvider(
        create: (_) => ServicesViewModel(),
        child: ServiceDetailView(service: service),
      );
    case BlackbuckLoadsView.routeName:
      final initialRoute = settings.arguments as String?;
      return BlackbuckLoadsView(initialRoute: initialRoute);
    case BlackbuckLoadDetailsView.routeName:
      if (settings.arguments is BlackbuckLoadModel) {
        return BlackbuckLoadDetailsView(
            load: settings.arguments as BlackbuckLoadModel);
      } else if (settings.arguments is String) {
        return BlackbuckLoadDetailsView(
            bookingId: settings.arguments as String);
      } else if (settings.arguments is Map<String, dynamic>) {
        final args = settings.arguments as Map<String, dynamic>;
        return BlackbuckLoadDetailsView(
          load: args['load'] as BlackbuckLoadModel?,
          bookingId: args['bookingId'] as String?,
        );
      }
      return const BlackbuckLoadDetailsView();
    case BlackbuckBiddingView.routeName:
      if (settings.arguments is BlackbuckLoadModel) {
        return BlackbuckBiddingView(
            load: settings.arguments as BlackbuckLoadModel);
      }
      return const BlackbuckBiddingView();
    case TrackPorterView.routeName:
      final args = settings.arguments;
      if (args is Map<String, dynamic>) {
        return TrackPorterView(booking: args);
      } else if (args != null) {
        return TrackPorterView(bookingId: args.toString());
      }
      return const TrackPorterView();
    case WalletView.routeName:
      return const WalletView();
    case MyOrdersView.routeName:
      return const MyOrdersView();
    case MyShipmentsView.routeName:
      return const MyShipmentsView();
    case MyRidesView.routeName:
      return const MyRidesView();
    case MyBookingsView.routeName:
      return const MyBookingsView();
    case SavedAddressesView.routeName:
      return const SavedAddressesView();
    case AddAddressView.routeName:
      return const AddAddressView();
    case EditProfileView.routeName:
      return const EditProfileView();
    default:
      return null;
  }
}

RouteFactory onAppGenerateRoute() => (settings) {
      Widget? screen = _getScreen(settings);
      if (screen != null) {
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) => screen,
          transitionsBuilder: (_, a, __, c) {
            return FadeTransition(opacity: a, child: c);
          },
        );
      }
      return null;
    };
