import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:cooli/features/auth/model/auth_model.dart';
import 'package:cooli/services/session_manager.dart';
import 'package:cooli/services/web_api_services.dart';
import 'package:cooli/utils/urls.dart';

class ProfileRepo {
  final Dio _dio;

  ProfileRepo({Dio? dio}) : _dio = dio ?? WebAPIService().dio;

  Future<UserModel?> fetchUserProfile({int userId = 1}) async {
    try {
      final response = await _dio.get(
        urlProfile,
        options: Options(headers: {'Accept': 'application/json'}),
      );
      if (response.data is Map<String, dynamic>) {
        final user = UserModel.fromJson(response.data as Map<String, dynamic>);
        await SessionManager().saveUserSession(user: user, token: user.token);
        return user;
      } else if (response.data is Map) {
        final user = UserModel.fromJson(Map<String, dynamic>.from(response.data as Map));
        await SessionManager().saveUserSession(user: user, token: user.token);
        return user;
      }
    } catch (e) {
      debugPrint('[ProfileRepo] fetchUserProfile API error: $e');
    }
    return await SessionManager().getSavedUser();
  }

  Future<bool> updateProfile({
    required String fullName,
    required String email,
    required String phoneNumber,
    String? address,
    String? profilePhoto,
  }) async {
    try {
      final cleanName = fullName.trim();
      final cleanEmail = email.trim();
      final cleanPhone = phoneNumber.trim();

      // 1. Send update to backend profile endpoint if reachable
      try {
        final payload = {
          'name': cleanName,
          'full_name': cleanName,
          'email': cleanEmail,
          'mobile_number': cleanPhone,
          'phone_number': cleanPhone,
          if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
          if (profilePhoto != null && profilePhoto.trim().isNotEmpty) 'profile_photo': profilePhoto.trim(),
        };

        final response = await _dio.put(
          urlProfile,
          data: payload,
          options: Options(headers: {'Accept': 'application/json'}),
        );
        debugPrint('✅ [ProfileRepo] updateProfile API response: ${response.statusCode}');
      } catch (apiError) {
        debugPrint('⚠️ [ProfileRepo] API update failed (falling back to local session sync): $apiError');
      }

      // 2. Persist updated profile in SessionManager
      final existing = await SessionManager().getSavedUser();
      final updatedUser = (existing ??
              const UserModel(
                id: '1',
                fullName: '',
                email: '',
                phoneNumber: '',
              ))
          .copyWith(
        fullName: cleanName,
        email: cleanEmail,
        phoneNumber: cleanPhone,
        address: address?.trim(),
        profilePhoto: profilePhoto?.trim(),
      );

      await SessionManager().saveUserSession(
        user: updatedUser,
        token: updatedUser.token,
      );

      if (cleanName.isNotEmpty && cleanName.toLowerCase() != 'user') {
        await SessionManager().updateUserName(cleanName);
      }

      debugPrint('✅ [ProfileRepo] Profile saved successfully: $cleanName');
      return true;
    } catch (e) {
      debugPrint('❌ [ProfileRepo] updateProfile error: $e');
      return false;
    }
  }

  UserModel getUserProfile() {
    return const UserModel(
      id: '1',
      fullName: 'John Smith',
      email: 'johnsmith@example.com',
      phoneNumber: '',
      address: '',
    );
  }
}
