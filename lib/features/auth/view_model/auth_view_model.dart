import 'package:flutter/foundation.dart';
import 'package:cooli/features/auth/model/auth_model.dart';
import 'package:cooli/features/auth/repo/auth_repo.dart';
import 'package:cooli/providers/view_model.dart';
import 'package:cooli/services/session_manager.dart';
import 'package:cooli/services/web_api_services.dart';

class AuthViewModel extends ViewModel {
  final AuthRepo _repo;

  AuthViewModel({AuthRepo? repo}) : _repo = repo ?? AuthRepo();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  bool _obscureConfirmPassword = true;
  bool get obscureConfirmPassword => _obscureConfirmPassword;

  bool _agreeToTerms = true;
  bool get agreeToTerms => _agreeToTerms;

  String _otpCode = '';
  String get otpCode => _otpCode;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  void setAgreeToTerms(bool value) {
    _agreeToTerms = value;
    notifyListeners();
  }

  void setOtpCode(String code) {
    _otpCode = code;
    notifyListeners();
  }

  SendOtpResponse? _lastOtpResponse;
  SendOtpResponse? get lastOtpResponse => _lastOtpResponse;

  Future<SendOtpResponse> sendOtp(String phone) async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await _repo.sendOtp(phoneNumber: phone);
      _lastOtpResponse = res;
      return res;
    } catch (e) {
      final fallback = SendOtpResponse(
        message: 'Failed to send OTP',
        success: false,
      );
      _lastOtpResponse = fallback;
      return fallback;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<SendOtpResponse> sendLoginOtp(String phone) async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await _repo.sendLoginOtp(phoneNumber: phone);
      _lastOtpResponse = res;
      return res;
    } catch (e) {
      final fallback = SendOtpResponse(
        message: 'Failed to send OTP',
        success: false,
      );
      _lastOtpResponse = fallback;
      return fallback;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<VerifyOtpResponse> verifyOtp(String phone, String otp) async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await _repo.verifyOtp(phoneNumber: phone, otp: otp);
      debugPrint('✅ [AuthViewModel] Verify OTP Response: $res');
      return res;
    } catch (e) {
      debugPrint('❌ [AuthViewModel] Verify OTP Exception: $e');
      return const VerifyOtpResponse(
        message: 'OTP verification failed',
        success: false,
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Logs in with mobile and OTP, saving the token and user session
  Future<LoginResponse> login(String phone, {required String otp}) async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await _repo.login(phoneNumber: phone, otp: otp);
      if (res.success) {
        final tokenToSave = res.token ?? res.user?.token;
        var user = res.user ??
            UserModel(
              id: '1',
              fullName: 'User',
              email: '',
              phoneNumber: phone,
              token: tokenToSave,
            );

        if (tokenToSave != null &&
            (user.token == null || user.token!.isEmpty)) {
          user = user.copyWith(token: tokenToSave);
        }

        _currentUser = user;

        // Persist token and complete user session
        await SessionManager().saveUserSession(
          user: user,
          token: tokenToSave,
        );

        if (user.fullName.isNotEmpty && user.fullName != 'User') {
          await SessionManager().updateUserName(user.fullName);
        }

        debugPrint('======================================================');
        debugPrint('🔐 [AuthViewModel] LOGIN SESSION ESTABLISHED');
        debugPrint('🔑 Token: $tokenToSave');
        debugPrint('👤 User: ${user.fullName} (${user.phoneNumber})');
        debugPrint('======================================================');

        notifyListeners();
      }
      return res;
    } catch (_) {
      return const LoginResponse(
        message: 'Login failed. Please try again.',
        success: false,
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Automatically restores the session and logs in using the saved token
  Future<bool> tryAutoLogin() async {
    try {
      final isLoggedIn = await SessionManager().isLoggedIn();
      final token = await SessionManager().getToken();
      if (isLoggedIn && token != null && token.isNotEmpty) {
        // 1. Ensure Dio headers have Bearer <token>
        await WebAPIService().initTokenToHeader();

        // 2. Restore user profile from storage
        final savedUser = await SessionManager().getSavedUser();
        if (savedUser != null) {
          _currentUser = savedUser.copyWith(token: token);
        } else {
          final userName = await SessionManager().getUserName();
          _currentUser = UserModel(
            id: '1',
            fullName: userName ?? 'User',
            email: '',
            phoneNumber: '',
            token: token,
          );
        }

        debugPrint('======================================================');
        debugPrint('🚀 [AuthViewModel] AUTO-LOGIN SUCCESSFUL WITH SAVED TOKEN');
        debugPrint('🔑 Token: $token');
        debugPrint('👤 User: ${_currentUser?.fullName}');
        debugPrint('======================================================');

        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ [AuthViewModel] tryAutoLogin error: $e');
    }
    return false;
  }

  /// Direct login using an explicit token string
  Future<bool> loginWithToken(String token, {UserModel? user}) async {
    final clean = token.trim();
    if (clean.isEmpty) return false;

    isLoading = true;
    notifyListeners();
    try {
      await SessionManager().saveToken(clean);

      final restoredUser = user ??
          await SessionManager().getSavedUser() ??
          UserModel(
            id: '1',
            fullName: await SessionManager().getUserName() ?? 'User',
            email: '',
            phoneNumber: '',
            token: clean,
          );

      _currentUser = restoredUser.copyWith(token: clean);
      await SessionManager().saveUserSession(user: _currentUser!, token: clean);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('⚠️ [AuthViewModel] loginWithToken error: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<RegisterResponse> register({
    required RegisterRequest request,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await _repo.register(request: request);
      if (res.success) {
        final tokenToSave = res.token ?? res.user?.token;
        var user = res.user ??
            UserModel(
              id: '1',
              fullName: request.name,
              email: request.email,
              phoneNumber: request.mobileNumber,
              address: request.address,
              token: tokenToSave,
            );
        if (user.fullName.isEmpty || user.fullName == 'User') {
          user = user.copyWith(fullName: request.name);
        }
        if (tokenToSave != null &&
            (user.token == null || user.token!.isEmpty)) {
          user = user.copyWith(token: tokenToSave);
        }
        _currentUser = user;
        await SessionManager().saveUserSession(
          user: user,
          token: tokenToSave,
        );
        if (user.fullName.isNotEmpty && user.fullName != 'User') {
          await SessionManager().updateUserName(user.fullName);
        }
        notifyListeners();
      }
      return res;
    } catch (_) {
      return const RegisterResponse(
        message: 'Registration failed. Please try again.',
        success: false,
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await SessionManager().clearSession();
    notifyListeners();
  }
}
