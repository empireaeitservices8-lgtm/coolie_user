import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cooli/features/dashboard/model/dashboard_model.dart';
import 'package:cooli/features/ecommerce/view/ecommerce_home_view.dart';
import 'package:cooli/features/ride/view/ride_booking_view.dart';
import 'package:cooli/features/porter/view/porter_home_view.dart';
import 'package:cooli/features/services/view/services_home_view.dart';
import 'package:cooli/services/session_manager.dart';
import 'package:cooli/services/web_api_services.dart';
import 'package:cooli/utils/urls.dart';

class DashboardRepo {
  final Dio _dio;

  DashboardRepo({Dio? dio}) : _dio = dio ?? WebAPIService().dio;

  /// Fetch Home Screen Data: GET /home/
  Future<Map<String, dynamic>> fetchHomeScreenData() async {
    try {
      final response = await _dio.get(
        urlHomeScreen,
        options: Options(headers: {'Accept': 'application/json'}),
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('[DashboardRepo] fetchHomeScreenData error: $e');
    }
    return {};
  }

  /// Fetch Structured Home Services & Vehicle Types: GET /home/
  Future<HomeApiResponse?> fetchHomeScreenServices() async {
    try {
      final response = await _dio.get(
        urlHomeScreen,
        options: Options(headers: {'Accept': 'application/json'}),
      );
      if (response.data is Map) {
        return HomeApiResponse.fromJson(
            Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      debugPrint('[DashboardRepo] fetchHomeScreenServices error: $e');
    }
    return null;
  }

  /// Fetch User Profile Name from Local Session
  Future<String> fetchUserProfileName({int userId = 1}) async {
    final savedUser = await SessionManager().getSavedUser();
    if (savedUser != null &&
        savedUser.fullName.trim().isNotEmpty &&
        savedUser.fullName.trim().toLowerCase() != 'user') {
      return savedUser.fullName.trim();
    }
    final name = await SessionManager().getUserName();
    if (name != null &&
        name.trim().isNotEmpty &&
        name.trim().toLowerCase() != 'user') {
      return name.trim();
    }
    return '';
  }

  /// Fetch Live Recent Activities from All Service APIs
  Future<List<RecentActivityItem>> fetchRecentActivities({int userId = 1}) async {
    final List<RecentActivityItem> activities = [];

    // 1. E-Commerce Orders: GET /orders/list/?user_id=1
    try {
      final res = await _dio.get(
        '$urlOrdersList?user_id=$userId',
        options: Options(headers: {'Accept': 'application/json'}),
      );
      if (res.data is List) {
        for (final item in (res.data as List).take(2)) {
          activities.add(RecentActivityItem(
            id: item['order_id']?.toString() ?? 'ORD-001',
            title: 'Order #${item['order_id'] ?? 'ORD-001'}',
            status: (item['status'] ?? 'Delivered').toString().toUpperCase(),
            time: item['created_at'] != null
                ? item['created_at'].toString().split('T').first
                : 'Today',
            icon: Icons.inventory_2_rounded,
            iconColor: const Color(0xFFFF6B00),
            amount: double.tryParse(item['total_amount']?.toString() ?? '') ?? 2050.0,
          ));
        }
      }
    } catch (e) {
      debugPrint('[DashboardRepo] fetch live orders error: $e');
    }

    // 2. Transport Bookings: GET /transport/bookings/list/?user_id=1
    try {
      final res = await _dio.get(
        '$urlTransportBookingsList?user_id=$userId',
        options: Options(headers: {'Accept': 'application/json'}),
      );
      if (res.data is List) {
        for (final item in (res.data as List).take(1)) {
          final loadId = item['load_details']?['load_id']?.toString() ?? 'LOAD-001';
          activities.add(RecentActivityItem(
            id: item['id']?.toString() ?? 'CL-001',
            title: 'Freight Load #$loadId',
            status: (item['status'] ?? 'In Transit').toString().toUpperCase(),
            time: '2h ago',
            icon: Icons.local_shipping_rounded,
            iconColor: const Color(0xFF2563EB),
            amount: 18000.0,
          ));
        }
      }
    } catch (e) {
      debugPrint('[DashboardRepo] fetch live transport error: $e');
    }

    // 3. Ride Bookings: GET /ride/bookings/list/?user_id=1
    try {
      final res = await _dio.get(
        '$urlRideBookingsList?user_id=$userId',
        options: Options(headers: {'Accept': 'application/json'}),
      );
      if (res.data is List) {
        for (final item in (res.data as List).take(1)) {
          final drop = item['drop_address']?.toString() ?? 'Airport';
          activities.add(RecentActivityItem(
            id: item['id']?.toString() ?? 'RD-001',
            title: 'Ride to $drop',
            status: (item['status'] ?? 'Completed').toString().toUpperCase(),
            time: 'Yesterday',
            icon: Icons.directions_car_filled_rounded,
            iconColor: const Color(0xFF16A34A),
            amount: double.tryParse(item['estimated_fare']?.toString() ?? '') ?? 250.0,
          ));
        }
      }
    } catch (e) {
      debugPrint('[DashboardRepo] fetch live rides error: $e');
    }

    if (activities.isNotEmpty) {
      return activities;
    }
    return getRecentActivities();
  }
  List<ServiceCategory> getServiceCategories() {
    return const [
      ServiceCategory(
        id: 'ecommerce',
        title: 'E-Commerce',
        subtitle: 'Sand & Bricks',
        icon: Icons.view_in_ar_rounded,
        color: Color(0xFFFF6B00),
        bgColor: Color(0xFFFFF3EB),
        route: EcommerceHomeView.routeName,
      ),
      ServiceCategory(
        id: 'ride',
        title: 'Rides',
        subtitle: 'Cabs & Auto',
        icon: Icons.directions_car_filled_rounded,
        color: Color(0xFF16A34A),
        bgColor: Color(0xFFF0FDF4),
        route: RideBookingView.routeName,
      ),
      ServiceCategory(
        id: 'porter',
        title: 'Truck & Courier',
        subtitle: 'Mini-Trucks & Cargo',
        icon: Icons.local_shipping_rounded,
        color: Color(0xFF2563EB),
        bgColor: Color(0xFFEFF6FF),
        route: PorterHomeView.routeName,
      ),
      ServiceCategory(
        id: 'services',
        title: 'Home Services',
        subtitle: 'Cleaning & Repairs',
        icon: Icons.handyman_rounded,
        color: Color(0xFF0D9488),
        bgColor: Color(0xFFF0FDFA),
        route: ServicesHomeView.routeName,
      ),
    ];
  }

  List<RecentActivityItem> getRecentActivities() {
    return const [
      RecentActivityItem(
        id: 'S1234',
        title: 'Sand Order #S1234',
        status: 'Completed',
        time: '2h ago',
        icon: Icons.inventory_2_rounded,
        iconColor: Color(0xFFFF6B00),
        amount: 1200.0,
      ),
      RecentActivityItem(
        id: 'RD890',
        title: 'Ride to Airport',
        status: 'Completed',
        time: '4h ago',
        icon: Icons.directions_car_filled_rounded,
        iconColor: Color(0xFF2563EB),
        amount: 250.0,
      ),
    ];
  }
}
