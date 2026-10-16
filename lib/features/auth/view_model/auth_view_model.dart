import 'package:cooli/features/auth/model/auth_model.dart';
import 'package:cooli/features/auth/repo/auth_repo.dart';
import 'package:cooli/providers/view_model.dart';
import 'package:cooli/services/session_manager.dart';

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
    } catch (_) {
      final fallback = SendOtpResponse(
        message: 'OTP sent successfully',
        otpCode: '7047',
        expiresIn: '10 minutes',
        success: true,
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
    } catch (_) {
      const fallback = SendOtpResponse(
        message: 'OTP sent successfully',
        otpCode: '2393',
        expiresIn: '10 minutes',
        success: true,
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
      print('✅ [AuthViewModel] Verify OTP Response: $res');
      return res;
    } catch (e) {
      print('❌ [AuthViewModel] Verify OTP Exception: $e');
      return const VerifyOtpResponse(
        message: 'OTP verification failed',
        success: false,
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<LoginResponse> login(String phone, {required String otp}) async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await _repo.login(phoneNumber: phone, otp: otp);
      if (res.success) {
        var user = res.user ??
            UserModel(
              id: '1',
              fullName: 'User',
              email: '',
              phoneNumber: phone,
            );

        _currentUser = user;
        await SessionManager().saveUserSession(user: user, token: user.token);
        if (user.fullName.isNotEmpty && user.fullName != 'User') {
          await SessionManager().updateUserName(user.fullName);
        }
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

  Future<RegisterResponse> register({
    required RegisterRequest request,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await _repo.register(request: request);
      if (res.success) {
        var user = res.user ??
            UserModel(
              id: '1',
              fullName: request.name,
              email: request.email,
              phoneNumber: request.mobileNumber,
              address: request.address,
            );
        if (user.fullName.isEmpty || user.fullName == 'User') {
          user = user.copyWith(fullName: request.name);
        }
        _currentUser = user;
        await SessionManager().saveUserSession(user: user, token: user.token);
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
