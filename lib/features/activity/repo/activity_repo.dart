import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cooli/features/activity/model/activity_model.dart';
import 'package:cooli/services/web_api_services.dart';
import 'package:cooli/utils/cooli_theme.dart';
import 'package:cooli/utils/urls.dart';

class ActivityRepo {
  final Dio _dio;

  ActivityRepo({Dio? dio}) : _dio = dio ?? WebAPIService().dio;

  /// Fetch all activities directly from live service API endpoints
  Future<List<ActivityModel>> fetchLiveActivities({int userId = 1}) async {
    final List<ActivityModel> activities = [];

    // 1. E-Commerce Orders: GET /orders/list/?user_id=1
    try {
      final res = await _dio.get(
        '$urlOrdersList?user_id=$userId',
        options: Options(headers: {'Accept': 'application/json'}),
      );
      if (res.data is List) {
        for (final item in (res.data as List)) {
          final itemsList = item['items'] as List? ?? [];
          final firstItemName = itemsList.isNotEmpty
              ? itemsList.first['product_name']?.toString()
              : 'Building Materials';
          activities.add(ActivityModel(
            id: item['order_id']?.toString() ?? 'ORD-001',
            title: firstItemName ?? 'Materials Order',
            subtitle: 'Delivered to Registered Address',
            date: item['created_at'] != null
                ? item['created_at'].toString().split('T').first
                : 'Today',
            status: (item['status'] ?? 'Delivered').toString().toUpperCase(),
            amount: double.tryParse(item['total_amount']?.toString() ?? '') ?? 2050.0,
            type: ActivityType.ecommerce,
            icon: Icons.inventory_2_rounded,
            statusColor: CooliColors.warning,
          ));
        }
      }
    } catch (e) {
      debugPrint('[ActivityRepo] orders error: $e');
    }

    // 2. Transport Bookings: GET /transport/bookings/list/?user_id=1
    try {
      final res = await _dio.get(
        '$urlTransportBookingsList?user_id=$userId',
        options: Options(headers: {'Accept': 'application/json'}),
      );
      if (res.data is List) {
        for (final item in (res.data as List)) {
          final loadId = item['load_details']?['load_id']?.toString() ?? 'LOAD-001';
          final pickup = item['load_details']?['pickup_location']?.toString() ?? 'Kochi';
          final drop = item['load_details']?['drop_location']?.toString() ?? 'Calicut';
          activities.add(ActivityModel(
            id: item['id']?.toString() ?? 'CL-001',
            title: 'BlackBuck Freight #$loadId',
            subtitle: '$pickup -> $drop',
            date: 'Today',
            status: (item['status'] ?? 'In Transit').toString().toUpperCase(),
            amount: 18000.0,
            type: ActivityType.service,
            icon: Icons.local_shipping_rounded,
            statusColor: CooliColors.info,
          ));
        }
      }
    } catch (e) {
      debugPrint('[ActivityRepo] transport error: $e');
    }

    // 3. Ride Bookings: GET /ride/bookings/list/?user_id=1
    try {
      final res = await _dio.get(
        '$urlRideBookingsList?user_id=$userId',
        options: Options(headers: {'Accept': 'application/json'}),
      );
      if (res.data is List) {
        for (final item in (res.data as List)) {
          final drop = item['drop_address']?.toString() ?? 'Airport';
          activities.add(ActivityModel(
            id: item['id']?.toString() ?? 'RD-001',
            title: 'City Ride',
            subtitle: 'To $drop',
            date: 'Yesterday',
            status: (item['status'] ?? 'Completed').toString().toUpperCase(),
            amount: double.tryParse(item['estimated_fare']?.toString() ?? '') ?? 250.0,
            type: ActivityType.ride,
            icon: Icons.directions_car_filled_rounded,
            statusColor: CooliColors.success,
          ));
        }
      }
    } catch (e) {
      debugPrint('[ActivityRepo] ride error: $e');
    }

    // 4. Goods Bookings: GET /goods/bookings/list/?user_id=1
    try {
      final res = await _dio.get(
        '$urlGoodsBookingsList?user_id=$userId',
        options: Options(headers: {'Accept': 'application/json'}),
      );
      if (res.data is List) {
        for (final item in (res.data as List)) {
          activities.add(ActivityModel(
            id: item['id']?.toString() ?? 'PT-001',
            title: 'Porter Goods: ${item['goods_category'] ?? 'Delivery'}',
            subtitle: '${item['pickup_address']} -> ${item['delivery_address']}',
            date: '12 Apr',
            status: (item['status'] ?? 'In Transit').toString().toUpperCase(),
            amount: double.tryParse(item['estimated_fare']?.toString() ?? '') ?? 670.0,
            type: ActivityType.porter,
            icon: Icons.local_shipping_rounded,
            statusColor: CooliColors.info,
          ));
        }
      }
    } catch (e) {
      debugPrint('[ActivityRepo] goods error: $e');
    }

    if (activities.isNotEmpty) {
      return activities;
    }
    return getAllActivities();
  }

  List<ActivityModel> getAllActivities() {
    return const [
      ActivityModel(
        id: 'CO12345',
        title: 'River Sand & Red Bricks',
        subtitle: 'Delivered to Kochi, Kerala',
        date: 'Today, 10:24 AM',
        status: 'In Transit',
        amount: 11150.0,
        type: ActivityType.ecommerce,
        icon: Icons.inventory_2_rounded,
        statusColor: CooliColors.warning,
      ),
      ActivityModel(
        id: 'RD9876',
        title: 'Airport Ride (Comfort Sedan)',
        subtitle: 'Kaloor -> Cochin International Airport',
        date: 'Yesterday, 04:30 PM',
        status: 'Completed',
        amount: 250.0,
        type: ActivityType.ride,
        icon: Icons.directions_car_filled_rounded,
        statusColor: CooliColors.success,
      ),
      ActivityModel(
        id: 'PT1234',
        title: 'Tata Ace Porter Booking',
        subtitle: 'House shifting 4 items',
        date: '12 Apr, 11:00 AM',
        status: 'Pickup in Progress',
        amount: 450.0,
        type: ActivityType.porter,
        icon: Icons.local_shipping_rounded,
        statusColor: CooliColors.info,
      ),
      ActivityModel(
        id: 'BK1234',
        title: 'Home Deep Cleaning',
        subtitle: '3 BHK Full Cleaning Service',
        date: '10 Apr, 10:00 AM',
        status: 'Completed',
        amount: 499.0,
        type: ActivityType.service,
        icon: Icons.cleaning_services_rounded,
        statusColor: CooliColors.success,
      ),
    ];
  }
}
