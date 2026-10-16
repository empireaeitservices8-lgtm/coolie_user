import 'package:cooli/features/auth/model/auth_model.dart';
import 'package:cooli/features/profile/repo/profile_repo.dart';
import 'package:cooli/providers/view_model.dart';
import 'package:cooli/services/session_manager.dart';

class ProfileViewModel extends ViewModel {
  ProfileViewModel({ProfileRepo? repo}) {
    loadUser();
  }

  UserModel? _user;
  UserModel? get user => _user;

  Future<void> loadUser() async {
    // Load active saved user session directly from SessionManager
    final saved = await SessionManager().getSavedUser();
    if (saved != null) {
      _user = saved;
      notifyListeners();
    }
  }
}
