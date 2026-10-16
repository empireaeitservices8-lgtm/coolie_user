import 'package:flutter/foundation.dart';
import 'package:cooli/features/address/model/address_model.dart';
import 'package:cooli/features/address/repo/address_repo.dart';
import 'package:cooli/providers/view_model.dart';
import 'package:cooli/services/session_manager.dart';

class AddressViewModel extends ViewModel {
  final AddressRepo _repo;

  AddressViewModel({AddressRepo? repo}) : _repo = repo ?? AddressRepo() {
    fetchAddresses();
  }

  List<AddressModel> _addresses = [];
  List<AddressModel> get addresses => _addresses;

  bool _isLoading = false;
  @override
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String _activeFilter = 'All'; // 'All', 'Home', 'Work', 'Other'
  String get activeFilter => _activeFilter;

  AddressModel? _selectedAddress;
  AddressModel? get selectedAddress => _selectedAddress;

  AddressModel? get defaultAddress {
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  List<AddressModel> get filteredAddresses {
    if (_activeFilter == 'Home') {
      return _addresses.where((a) => a.addressType == 'home').toList();
    } else if (_activeFilter == 'Work') {
      return _addresses.where((a) => a.addressType == 'work').toList();
    } else if (_activeFilter == 'Other') {
      return _addresses.where((a) => a.addressType == 'other').toList();
    }
    return _addresses;
  }

  void setFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  void selectAddress(AddressModel? address) {
    _selectedAddress = address;
    notifyListeners();
  }

  Future<void> fetchAddresses({int? userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final targetUserId =
          userId ?? await SessionManager().getLoggedInUserId() ?? 1;
      final list = await _repo.fetchAddresses(userId: targetUserId);
      _addresses = list;
      if (_selectedAddress == null && list.isNotEmpty) {
        _selectedAddress = defaultAddress;
      }
    } catch (e) {
      debugPrint('[AddressViewModel] fetchAddresses error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<({bool success, String message, AddressModel? address})>
      createAddress({
    required String addressLine1,
    String addressLine2 = '',
    String landmark = '',
    required String city,
    required String state,
    required String postalCode,
    String country = 'India',
    String addressType = 'home',
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      final targetUserId = await SessionManager().getLoggedInUserId() ?? 1;
      final result = await _repo.createAddress(
        userId: targetUserId,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        landmark: landmark,
        city: city,
        state: state,
        postalCode: postalCode,
        country: country,
        addressType: addressType,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );

      if (result.success) {
        // Refresh full address list so all views get updated instantly
        await fetchAddresses(userId: targetUserId);
      }
      return result;
    } catch (e) {
      debugPrint('[AddressViewModel] createAddress error: $e');
      return (
        success: false,
        message: 'Error saving address: $e',
        address: null,
      );
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<({bool success, String message})> deleteAddress(int id) async {
    try {
      final result = await _repo.deleteAddress(id);
      if (result.success || result.notFound) {
        _addresses.removeWhere((a) => a.id == id);
        if (_selectedAddress?.id == id) {
          _selectedAddress = defaultAddress;
        }
        notifyListeners();
        return (
          success: true,
          message: result.notFound
              ? 'Address was already deleted from server'
              : result.message,
        );
      }
      return (success: false, message: result.message);
    } catch (e) {
      debugPrint('[AddressViewModel] deleteAddress error: $e');
      return (success: false, message: 'Failed to delete address: $e');
    }
  }
}
