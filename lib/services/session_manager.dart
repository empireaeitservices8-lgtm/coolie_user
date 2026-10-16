import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cooli/features/auth/model/auth_model.dart';
import 'package:cooli/services/web_api_services.dart';
import 'package:cooli/utils/sp_keys.dart' as sp_keys;

/// Centralized Session Manager for managing authentication state and session persistence
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  static String _inMemoryUserName = '';
  static String get inMemoryUserName => _inMemoryUserName;

  /// Warm up SharedPreferences cache and read user name immediately at app startup
  Future<void> init() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.reload();
      final name = sp.getString(sp_keys.keyUserName) ??
          sp.getString('KEY_USER_NAME') ??
          sp.getString('user_name') ??
          sp.getString('userName') ??
          sp.getString('name') ??
          sp.getString('full_name');
      if (name != null &&
          name.trim().isNotEmpty &&
          name.trim().toLowerCase() != 'user') {
        _inMemoryUserName = name.trim();
        debugPrint('👤 [SessionManager] Loaded user name from SharedPreferences: $_inMemoryUserName');
      }
    } catch (e) {
      debugPrint('[SessionManager] init error: $e');
    }
  }

  /// Checks if user has an active authenticated session
  Future<bool> isLoggedIn() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final isLoggedIn = sp.getBool(sp_keys.keyIsLoggedIn) ?? false;
      final token = sp.getString(sp_keys.keyToken);
      return isLoggedIn && token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('[SessionManager] isLoggedIn error: $e');
      return false;
    }
  }

  /// Saves user session details into SharedPreferences and configures Dio headers
  Future<void> saveUserSession({
    required UserModel user,
    String? token,
  }) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final effectiveToken = token ??
          user.token ??
          'cooli_token_${user.id}_${DateTime.now().millisecondsSinceEpoch}';

      await sp.setBool(sp_keys.keyIsLoggedIn, true);
      await sp.setString(sp_keys.keyToken, effectiveToken);
      await sp.setString(sp_keys.keyUserId, user.id);
      if (user.fullName.trim().isNotEmpty &&
          user.fullName.trim().toLowerCase() != 'user') {
        _inMemoryUserName = user.fullName.trim();
        await sp.setString(sp_keys.keyUserName, user.fullName.trim());
        await sp.setString('KEY_USER_NAME', user.fullName.trim());
        await sp.setString('user_name', user.fullName.trim());
      }
      if (user.phoneNumber.trim().isNotEmpty) {
        await sp.setString(sp_keys.keyUseMobile, user.phoneNumber.trim());
      }
      if (user.email.trim().isNotEmpty) {
        await sp.setString(sp_keys.keyEmail, user.email.trim());
      }
      if (user.address != null && user.address!.isNotEmpty) {
        await sp.setString(sp_keys.keyUserAddress, user.address!);
      }

      // Automatically sync Authorization header to Dio
      await WebAPIService().initTokenToHeader();

      debugPrint('======================================================');
      debugPrint('✅ [SessionManager] USER SESSION SAVED');
      debugPrint('👤 Name: ${user.fullName}');
      debugPrint('📱 Phone: ${user.phoneNumber}');
      debugPrint('🔑 Token: $effectiveToken');
      debugPrint('======================================================');
    } catch (e) {
      debugPrint('⚠️ [SessionManager] saveUserSession error: $e');
    }
  }

  /// Retrieves the saved user profile from SharedPreferences
  Future<UserModel?> getSavedUser() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final id = sp.getString(sp_keys.keyUserId);
      final name = sp.getString(sp_keys.keyUserName) ??
          sp.getString('KEY_USER_NAME') ??
          sp.getString('user_name') ??
          sp.getString('userName') ??
          sp.getString('name') ??
          sp.getString('full_name');
      final phone = sp.getString(sp_keys.keyUseMobile);
      final email = sp.getString(sp_keys.keyEmail);
      final address = sp.getString(sp_keys.keyUserAddress);
      final token = sp.getString(sp_keys.keyToken);

      final hasValidName = name != null &&
          name.trim().isNotEmpty &&
          name.trim().toLowerCase() != 'user';

      if (hasValidName) {
        _inMemoryUserName = name.trim();
      }

      if (id != null || phone != null || hasValidName) {
        final safeId = (id != null && id != 'usr_1001' && id != '1001') ? id : '1';
        return UserModel(
          id: safeId,
          fullName: hasValidName ? name.trim() : '',
          email: email ?? '',
          phoneNumber: phone ?? '',
          address: address,
          token: token,
        );
      }
    } catch (e) {
      debugPrint('[SessionManager] getSavedUser error: $e');
    }
    return null;
  }

  /// Retrieves the saved user display name from SharedPreferences
  Future<String?> getUserName() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.reload();
      final name = sp.getString(sp_keys.keyUserName) ??
          sp.getString('KEY_USER_NAME') ??
          sp.getString('user_name') ??
          sp.getString('userName') ??
          sp.getString('name') ??
          sp.getString('full_name');
      if (name != null &&
          name.trim().isNotEmpty &&
          name.trim().toLowerCase() != 'user') {
        _inMemoryUserName = name.trim();
        return name.trim();
      }
    } catch (e) {
      debugPrint('[SessionManager] getUserName error: $e');
    }
    return _inMemoryUserName.isNotEmpty ? _inMemoryUserName : null;
  }

  /// Updates or caches user display name in SharedPreferences
  Future<void> updateUserName(String name) async {
    try {
      if (name.trim().isEmpty || name.trim().toLowerCase() == 'user') return;
      _inMemoryUserName = name.trim();
      final sp = await SharedPreferences.getInstance();
      await sp.setString(sp_keys.keyUserName, name.trim());
      await sp.setString('KEY_USER_NAME', name.trim());
      await sp.setString('user_name', name.trim());
      debugPrint('👤 [SessionManager] Updated user name in SharedPreferences: ${name.trim()}');
    } catch (e) {
      debugPrint('[SessionManager] updateUserName error: $e');
    }
  }

  /// Retrieves the active logged-in user integer ID, or null if not logged in
  Future<int?> getLoggedInUserId() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final idStr = sp.getString(sp_keys.keyUserId);
      if (idStr != null && idStr.isNotEmpty && idStr != 'usr_1001' && idStr != '1001') {
        final parsed = int.tryParse(idStr);
        if (parsed != null && parsed > 0 && parsed != 1001) return parsed;
        final digits = idStr.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.isNotEmpty && digits != '1001') {
          final parsedDigits = int.tryParse(digits);
          if (parsedDigits != null && parsedDigits > 0 && parsedDigits != 1001) return parsedDigits;
        }
      }
      final idInt = sp.getInt(sp_keys.keyUserId);
      if (idInt != null && idInt > 0 && idInt != 1001) return idInt;

      final savedUser = await getSavedUser();
      if (savedUser != null && savedUser.id.isNotEmpty && savedUser.id != 'usr_1001' && savedUser.id != '1001') {
        final parsed = int.tryParse(savedUser.id);
        if (parsed != null && parsed > 0 && parsed != 1001) return parsed;
        final digits = savedUser.id.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.isNotEmpty && digits != '1001') {
          final parsedDigits = int.tryParse(digits);
          if (parsedDigits != null && parsedDigits > 0 && parsedDigits != 1001) return parsedDigits;
        }
      }
    } catch (e) {
      debugPrint('[SessionManager] getLoggedInUserId error: $e');
    }
    return null;
  }

  /// Retrieves the active logged-in user integer ID, or [fallback] (default: 1)
  Future<int> getUserId({int fallback = 1}) async {
    final id = await getLoggedInUserId();
    return id ?? fallback;
  }

  /// Clears user session completely on logout
  Future<void> clearSession() async {
    try {
      _inMemoryUserName = '';
      final sp = await SharedPreferences.getInstance();
      await sp.remove(sp_keys.keyIsLoggedIn);
      await sp.remove(sp_keys.keyToken);
      await sp.remove(sp_keys.keyUserId);
      await sp.remove(sp_keys.keyUserName);
      await sp.remove('KEY_USER_NAME');
      await sp.remove('user_name');
      await sp.remove(sp_keys.keyUseMobile);
      await sp.remove(sp_keys.keyEmail);
      await sp.remove(sp_keys.keyUserAddress);

      // Remove Authorization header from Dio
      if (WebAPIService().dio.options.headers.containsKey('Authorization')) {
        WebAPIService().dio.options.headers.remove('Authorization');
      }

      debugPrint('======================================================');
      debugPrint('🔒 [SessionManager] USER SESSION CLEARED (LOGGED OUT)');
      debugPrint('======================================================');
    } catch (e) {
      debugPrint('⚠️ [SessionManager] clearSession error: $e');
    }
  }
}
