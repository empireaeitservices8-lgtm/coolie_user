import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cooli/features/address/model/address_model.dart';
import 'package:cooli/services/web_api_services.dart';
import 'package:cooli/utils/urls.dart';

class AddressRepo {
  final Dio _dio;

  AddressRepo({Dio? dio}) : _dio = dio ?? WebAPIService().dio;

  /// Fetch user addresses: GET /addresses/?user_id={userId}
  Future<List<AddressModel>> fetchAddresses({int? userId}) async {
    final uid = (userId != null && userId > 0) ? userId : 1;
    try {
      final response = await _dio.get(
        '$urlAddresses?user_id=$uid',
        options: Options(
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 12),
        ),
      );

      List rawList = [];
      if (response.data is List) {
        rawList = response.data as List;
      } else if (response.data is Map) {
        final map = response.data as Map;
        if (map['results'] is List) {
          rawList = map['results'] as List;
        } else if (map['addresses'] is List) {
          rawList = map['addresses'] as List;
        } else if (map['data'] is List) {
          rawList = map['data'] as List;
        } else if (map['value'] is List) {
          rawList = map['value'] as List;
        }
      }

      final addresses = rawList
          .whereType<Map>()
          .map((item) =>
              AddressModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      if (addresses.isEmpty && uid != 1) {
        // Fallback to user_id=1 if current user has no addresses yet
        return await fetchAddresses(userId: 1);
      }
      return addresses;
    } catch (e) {
      debugPrint('[AddressRepo] fetchAddresses error: $e');
    }
    return [];
  }

  /// Create new address: POST /addresses/
  Future<({bool success, AddressModel? address, String message})> createAddress({
    required int userId,
    required String addressType,
    required String addressLine1,
    String addressLine2 = '',
    String landmark = '',
    required String city,
    required String state,
    required String postalCode,
    String country = 'India',
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    final payload = {
      'user': userId > 0 ? userId : 1,
      'address_type': addressType.toLowerCase(),
      'address_line1': addressLine1.trim(),
      'address_line2': addressLine2.trim(),
      'landmark': landmark.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'postal_code': postalCode.trim(),
      'country': country.trim(),
      'latitude': latitude != null
          ? double.parse(latitude.toStringAsFixed(6))
          : 12.9716,
      'longitude': longitude != null
          ? double.parse(longitude.toStringAsFixed(6))
          : 77.5946,
      'is_default': isDefault,
    };

    try {
      final response = await _dio.post(
        urlAddresses,
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          sendTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 12),
        ),
      );

      if (response.data is Map) {
        final created =
            AddressModel.fromJson(Map<String, dynamic>.from(response.data as Map));
        return (
          success: true,
          address: created,
          message: 'Address added successfully',
        );
      }
      return (
        success: true,
        address: null,
        message: 'Address saved successfully',
      );
    } catch (e) {
      debugPrint('[AddressRepo] createAddress error: $e');
      String errorMsg = 'Failed to save address';
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map;
        final detail = data['detail'] ?? data['message'] ?? data['error'];
        if (detail != null) errorMsg = detail.toString();
      }
      return (success: false, address: null, message: errorMsg);
    }
  }

  /// Delete address: DELETE /addresses/{id}/
  Future<({bool success, String message, bool notFound})> deleteAddress(
      int addressId) async {
    try {
      final response = await _dio.delete(
        '$urlAddresses$addressId/',
        options: Options(
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 202) {
        String msg = 'Address deleted successfully';
        if (response.data is Map && response.data['message'] != null) {
          msg = response.data['message'].toString();
        }
        return (success: true, message: msg, notFound: false);
      }
      return (
        success: false,
        message: 'Failed to delete address',
        notFound: false
      );
    } catch (e) {
      debugPrint('[AddressRepo] deleteAddress error: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          return (
            success: true,
            message: 'Address not found or already deleted',
            notFound: true,
          );
        }
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          final err = data['error'] ?? data['detail'] ?? data['message'];
          if (err != null) {
            return (
              success: false,
              message: err.toString(),
              notFound: false,
            );
          }
        }
      }
      return (
        success: false,
        message: 'Failed to delete address',
        notFound: false
      );
    }
  }
}
