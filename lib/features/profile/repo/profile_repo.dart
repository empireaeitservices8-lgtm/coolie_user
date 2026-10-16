import 'package:dio/dio.dart';
import 'package:cooli/features/auth/model/auth_model.dart';
import 'package:cooli/services/session_manager.dart';
class ProfileRepo {
  ProfileRepo({Dio? dio});

  Future<UserModel?> fetchUserProfile({int userId = 1}) async {
    return await SessionManager().getSavedUser();
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
