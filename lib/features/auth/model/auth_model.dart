class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? address;
  final String? profilePhoto;
  final bool isVerified;
  final String? token;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.address,
    this.profilePhoto,
    this.isVerified = true,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : (json['user'] is Map ? Map<String, dynamic>.from(json['user'] as Map) : json);

    final profileMap = userMap['profile'] is Map<String, dynamic>
        ? userMap['profile'] as Map<String, dynamic>
        : (userMap['profile'] is Map ? Map<String, dynamic>.from(userMap['profile'] as Map) : null);

    return UserModel(
      id: userMap['id']?.toString() ?? profileMap?['id']?.toString() ?? 'usr_1001',
      fullName: profileMap?['name']?.toString() ?? userMap['name']?.toString() ?? userMap['full_name']?.toString() ?? 'User',
      email: profileMap?['email']?.toString() ?? userMap['email']?.toString() ?? '',
      phoneNumber: userMap['mobile_number']?.toString() ?? userMap['phone']?.toString() ?? '',
      address: profileMap?['address_line1']?.toString() ?? userMap['address']?.toString(),
      profilePhoto: profileMap?['profile_photo']?.toString() ?? userMap['profile_photo']?.toString(),
      isVerified: userMap['is_verified'] == true,
      token: json['token']?.toString() ?? json['access_token']?.toString(),
    );
  }
}

class SendOtpResponse {
  final String message;
  final String? otpCode;
  final String? expiresIn;
  final bool success;

  const SendOtpResponse({
    required this.message,
    this.otpCode,
    this.expiresIn,
    this.success = true,
  });

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) {
    return SendOtpResponse(
      message: json['message']?.toString() ?? 'OTP sent successfully',
      otpCode: json['otp_code']?.toString(),
      expiresIn: json['expires_in']?.toString(),
      success: true,
    );
  }
}

class VerifyOtpResponse {
  final String message;
  final String? mobileNumber;
  final bool success;

  const VerifyOtpResponse({
    required this.message,
    this.mobileNumber,
    this.success = true,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      message: json['message']?.toString() ?? 'OTP verified successfully',
      mobileNumber: json['mobile_number']?.toString(),
      success: true,
    );
  }
}

class RegisterRequest {
  final String name;
  final String mobileNumber;
  final String email;
  final String address;

  const RegisterRequest({
    required this.name,
    required this.mobileNumber,
    required this.email,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
    'mobile_number': mobileNumber,
    'name': name,
    'email': email,
    'address': address,
  };
}

class RegisterResponse {
  final String message;
  final UserModel? user;
  final bool success;

  const RegisterResponse({
    required this.message,
    this.user,
    this.success = true,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      message: json['message']?.toString() ?? 'Registration successful',
      user: json['user'] != null ? UserModel.fromJson(json) : null,
      success: true,
    );
  }
}

class LoginResponse {
  final String message;
  final UserModel? user;
  final bool profileComplete;
  final bool success;

  const LoginResponse({
    required this.message,
    this.user,
    this.profileComplete = true,
    this.success = true,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message']?.toString() ?? 'Login successful',
      user: json['user'] != null ? UserModel.fromJson(json) : null,
      profileComplete: json['profile_complete'] == true || json['profile_complete'] == null,
      success: true,
    );
  }
}

class OtpVerificationArgs {
  final String phoneNumber;
  final bool isRegisterFlow;
  final RegisterRequest? registerData;
  final String? serverOtp;

  const OtpVerificationArgs({
    required this.phoneNumber,
    required this.isRegisterFlow,
    this.registerData,
    this.serverOtp,
  });
}

class RegisterDetailsArgs {
  final String phoneNumber;
  final String? verifiedOtp;

  const RegisterDetailsArgs({
    required this.phoneNumber,
    this.verifiedOtp,
  });
}
