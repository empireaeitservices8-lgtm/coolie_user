import 'package:cooli/features/auth/model/auth_model.dart';
import 'package:cooli/features/profile/repo/profile_repo.dart';
import 'package:cooli/providers/view_model.dart';
import 'package:cooli/services/session_manager.dart';

class ProfileViewModel extends ViewModel {
  final ProfileRepo _repo;

  ProfileViewModel({ProfileRepo? repo}) : _repo = repo ?? ProfileRepo() {
    loadUser();
  }

  UserModel? _user;
  UserModel? get user => _user;

  Future<void> loadUser() async {
    // 1. Instantly load saved local user session
    final saved = await SessionManager().getSavedUser();
    if (saved != null) {
      _user = saved;
      notifyListeners();
    }

    // 2. Refresh from backend
    try {
      final remote = await _repo.fetchUserProfile();
      if (remote != null) {
        _user = remote;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> updateUserProfile({
    required String fullName,
    required String email,
    required String phoneNumber,
    String? address,
    String? profilePhoto,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      final success = await _repo.updateProfile(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        address: address,
        profilePhoto: profilePhoto,
      );
      if (success) {
        _user = await SessionManager().getSavedUser();
        notifyListeners();
      }
      return success;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
