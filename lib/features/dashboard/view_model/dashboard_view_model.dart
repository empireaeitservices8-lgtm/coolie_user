import 'package:flutter/foundation.dart';
import 'package:cooli/features/dashboard/model/dashboard_model.dart';
import 'package:cooli/features/dashboard/repo/dashboard_repo.dart';
import 'package:cooli/providers/view_model.dart';
import 'package:cooli/services/session_manager.dart';

class DashboardViewModel extends ViewModel {
  final DashboardRepo _repo;

  DashboardViewModel({DashboardRepo? repo}) : _repo = repo ?? DashboardRepo() {
    loadDashboardData();
  }

  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  List<ServiceCategory> _categories = [];
  List<ServiceCategory> get categories => _categories;

  List<RecentActivityItem> _recentActivities = [];
  List<RecentActivityItem> get recentActivities => _recentActivities;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _userName = '';
  String get userName => _userName.isNotEmpty
      ? _userName
      : (SessionManager.inMemoryUserName.isNotEmpty
          ? SessionManager.inMemoryUserName
          : '');

  void setSelectedTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  HomeApiResponse _homeData = const HomeApiResponse(
    services: initialHomeServices,
    vehicleTypes: [],
  );
  HomeApiResponse get homeData => _homeData;

  bool _isHomeDataLoading = false;
  bool get isHomeDataLoading => _isHomeDataLoading;

  int _selectedFleetFilter = 0; // 0 = All, 8 = Ride, 9 = Goods, 10 = Transport
  int get selectedFleetFilter => _selectedFleetFilter;

  void setSelectedFleetFilter(int serviceId) {
    _selectedFleetFilter = serviceId;
    notifyListeners();
  }

  Future<void> fetchHomeScreen() async {
    _isHomeDataLoading = true;
    notifyListeners();
    try {
      final res = await _repo.fetchHomeScreenServices();
      if (res != null && res.services.isNotEmpty) {
        _homeData = res;
      }
    } catch (e) {
      debugPrint('[DashboardViewModel] fetchHomeScreen error: $e');
    } finally {
      _isHomeDataLoading = false;
      notifyListeners();
    }
  }

  String _formatDisplayName(String rawName) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'user') return '';
    return trimmed.split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }

  Future<void> refreshUserData() async {
    // 1. Always prioritize user name directly from SharedPreferences
    final cachedName = await SessionManager().getUserName();
    if (cachedName != null &&
        cachedName.trim().isNotEmpty &&
        cachedName.trim().toLowerCase() != 'user') {
      final formatted = _formatDisplayName(cachedName);
      if (formatted.isNotEmpty) {
        _userName = formatted;
        notifyListeners();
        return; // Retain SharedPreferences name, never overwrite with API response
      }
    }

    final savedUser = await SessionManager().getSavedUser();
    if (savedUser != null &&
        savedUser.fullName.trim().isNotEmpty &&
        savedUser.fullName.trim().toLowerCase() != 'user') {
      final formatted = _formatDisplayName(savedUser.fullName);
      if (formatted.isNotEmpty) {
        _userName = formatted;
        notifyListeners();
        return; // Retain SharedPreferences name, never overwrite with API response
      }
    }

    // 2. Only if SharedPreferences has no name, try to fetch from API
    final loggedInUserId = await SessionManager().getLoggedInUserId() ?? 1;
    final name = await _repo.fetchUserProfileName(userId: loggedInUserId);
    if (name.isNotEmpty && name.toLowerCase() != 'user') {
      final formatted = _formatDisplayName(name);
      if (formatted.isNotEmpty) {
        _userName = formatted;
        notifyListeners();
      }

      if (savedUser != null) {
        await SessionManager().saveUserSession(
          user: savedUser.copyWith(fullName: name),
          token: savedUser.token,
        );
      } else {
        await SessionManager().updateUserName(name);
      }
    }
  }

  void loadDashboardData() async {
    _categories = _repo.getServiceCategories();
    _recentActivities = _repo.getRecentActivities();
    notifyListeners();

    await refreshUserData();

    // 3. Fetch live recent activities from API responses
    final loggedInUserId = await SessionManager().getLoggedInUserId() ?? 1;
    final liveActivities =
        await _repo.fetchRecentActivities(userId: loggedInUserId);
    if (liveActivities.isNotEmpty) {
      _recentActivities = liveActivities;
      notifyListeners();
    }

    // 4. Fetch structured home screen services from API GET /home/
    await fetchHomeScreen();
  }
}
