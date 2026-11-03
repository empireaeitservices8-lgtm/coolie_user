import 'package:cooli/features/activity/model/activity_model.dart';
import 'package:cooli/features/activity/repo/activity_repo.dart';
import 'package:cooli/providers/view_model.dart';
import 'package:cooli/services/session_manager.dart';

class ActivityViewModel extends ViewModel {
  final ActivityRepo _repo;

  ActivityViewModel({ActivityRepo? repo}) : _repo = repo ?? ActivityRepo() {
    loadActivities();
  }

  List<ActivityModel> _allLoadedActivities = [];
  List<ActivityModel> _activities = [];
  List<ActivityModel> get activities => _activities;

  ActivityType? _selectedFilter;
  ActivityType? get selectedFilter => _selectedFilter;

  Future<void> loadActivities() async {
    if (_allLoadedActivities.isEmpty) {
      _allLoadedActivities = _repo.getAllActivities();
      _applyFilter();
      notifyListeners();
    }

    final userId = await SessionManager().getUserId(fallback: 20);
    final live = await _repo.fetchLiveActivities(userId: userId);
    if (live.isNotEmpty) {
      _allLoadedActivities = live;
      _applyFilter();
      notifyListeners();
    }
  }

  void _applyFilter() {
    if (_selectedFilter == null) {
      _activities = List<ActivityModel>.from(_allLoadedActivities);
    } else {
      _activities =
          _allLoadedActivities.where((a) => a.type == _selectedFilter).toList();
    }
  }

  void setFilter(ActivityType? filter) {
    _selectedFilter = filter;
    _applyFilter();
    notifyListeners();
  }
}
