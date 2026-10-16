import 'package:flutter/foundation.dart';
import 'package:cooli/features/services/model/blackbuck_load_model.dart';
import 'package:cooli/features/services/model/service_model.dart';
import 'package:cooli/features/services/repo/services_repo.dart';
import 'package:cooli/providers/view_model.dart';
import 'package:cooli/services/session_manager.dart';

class ServicesViewModel extends ViewModel {
  final ServicesRepo _repo;

  ServicesViewModel({ServicesRepo? repo}) : _repo = repo ?? ServicesRepo() {
    loadServices();
  }

  List<ServiceSubCategory> _categories = [];
  List<ServiceSubCategory> get categories => _categories;

  List<HomeServiceModel> _services = [];
  List<HomeServiceModel> get services => _services;

  HomeServiceModel? _selectedService;
  HomeServiceModel? get selectedService => _selectedService;

  String _selectedDate = '12 Apr 2025';
  String get selectedDate => _selectedDate;

  String _selectedTime = '10:00 AM - 11:00 AM';
  String get selectedTime => _selectedTime;

  String _address = 'Home - Kochi, Kerala';
  String get address => _address;

  void loadServices() {
    _categories = _repo.getSubCategories();
    _services = _repo.getHomeServices();
    if (_services.isNotEmpty) {
      _selectedService = _services.first;
    }
    notifyListeners();
  }

  void selectService(HomeServiceModel service) {
    _selectedService = service;
    notifyListeners();
  }

  void setDate(String date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setTime(String time) {
    _selectedTime = time;
    notifyListeners();
  }

  void setAddress(String address) {
    _address = address;
    notifyListeners();
  }

  // --- Transport Bookings State Management ---
  List<BlackbuckLoadModel> _transportBookings = [];
  List<BlackbuckLoadModel> get transportBookings => _transportBookings;

  bool _isLoadingBookings = false;
  bool get isLoadingBookings => _isLoadingBookings;

  String _transportFilter = 'All'; // 'All', 'Confirmed', 'In Transit', 'Completed'
  String get transportFilter => _transportFilter;

  List<BlackbuckLoadModel> get filteredTransportBookings {
    if (_transportFilter == 'Confirmed') {
      return _transportBookings.where((b) {
        final st = (b.bookingStatus ?? b.status).toLowerCase();
        return st == 'confirmed' || st == 'bid_accepted' || st == 'accepted';
      }).toList();
    } else if (_transportFilter == 'In Transit') {
      return _transportBookings.where((b) {
        final st = (b.bookingStatus ?? b.status).toLowerCase();
        return st == 'in_transit' || st == 'picked_up' || st == 'started';
      }).toList();
    } else if (_transportFilter == 'Completed') {
      return _transportBookings.where((b) {
        final st = (b.bookingStatus ?? b.status).toLowerCase();
        return st == 'delivered' || st == 'completed';
      }).toList();
    }
    return _transportBookings;
  }

  void setTransportFilter(String filter) {
    _transportFilter = filter;
    notifyListeners();
  }

  Future<List<BlackbuckLoadModel>> fetchTransportBookings({int? userId}) async {
    _isLoadingBookings = true;
    notifyListeners();

    try {
      final targetUserId = userId ?? await SessionManager().getLoggedInUserId() ?? 1;
      final fetched = await _repo.fetchTransportBookings(userId: targetUserId);
      _transportBookings = fetched;
      return fetched;
    } catch (e) {
      debugPrint('[ServicesViewModel] fetchTransportBookings error: $e');
      return [];
    } finally {
      _isLoadingBookings = false;
      notifyListeners();
    }
  }
}
