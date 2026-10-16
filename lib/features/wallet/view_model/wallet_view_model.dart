import 'package:flutter/foundation.dart';
import 'package:cooli/features/wallet/model/wallet_model.dart';
import 'package:cooli/features/wallet/repo/wallet_repo.dart';
import 'package:cooli/providers/view_model.dart';
import 'package:cooli/services/session_manager.dart';

class WalletViewModel extends ViewModel {
  final WalletRepo _repo;

  WalletViewModel({WalletRepo? repo}) : _repo = repo ?? WalletRepo() {
    loadWalletData();
  }

  WalletModel _wallet = WalletModel.initial();
  WalletModel get wallet => _wallet;
  double get balance => _wallet.balance;

  List<WalletTransactionModel> _transactions = [];
  List<WalletTransactionModel> get transactions => _transactions;

  bool _isLoading = false;
  @override
  bool get isLoading => _isLoading;

  bool _isAddingFunds = false;
  bool get isAddingFunds => _isAddingFunds;

  bool _isBalanceVisible = true;
  bool get isBalanceVisible => _isBalanceVisible;

  String _activeFilter = 'All'; // 'All', 'Credits', 'Debits'
  String get activeFilter => _activeFilter;

  String _userName = 'User';
  String get userName => _userName;

  List<WalletTransactionModel> get filteredTransactions {
    if (_activeFilter == 'Credits') {
      return _transactions
          .where((t) => t.type.toLowerCase() == 'credit')
          .toList();
    } else if (_activeFilter == 'Debits') {
      return _transactions
          .where((t) => t.type.toLowerCase() == 'debit')
          .toList();
    }
    return _transactions;
  }

  void toggleBalanceVisibility() {
    _isBalanceVisible = !_isBalanceVisible;
    notifyListeners();
  }

  void setFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  Future<void> loadWalletData({int? userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await SessionManager().getSavedUser();
      if (user != null && user.fullName.isNotEmpty) {
        _userName = user.fullName;
      }

      final targetUserId =
          userId ?? await SessionManager().getLoggedInUserId() ?? 1;
      final wallet = await _repo.fetchWalletBalance(userId: targetUserId);
      final txns = await _repo.fetchTransactions(userId: targetUserId);

      _wallet = wallet;
      _transactions = txns;
    } catch (e) {
      debugPrint('[WalletViewModel] loadWalletData error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<({bool success, double newBalance, String message})> addFunds({
    required double amount,
    String paymentMethod = 'UPI (Google Pay)',
  }) async {
    _isAddingFunds = true;
    notifyListeners();

    try {
      final result = await _repo.addFunds(
        amount: amount,
        paymentMethod: paymentMethod,
      );

      if (result.success) {
        // Refresh balance and transaction list
        await loadWalletData();
      }
      return result;
    } catch (e) {
      debugPrint('[WalletViewModel] addFunds error: $e');
      return (
        success: false,
        newBalance: _wallet.balance,
        message: 'Failed to add funds: $e',
      );
    } finally {
      _isAddingFunds = false;
      notifyListeners();
    }
  }

  Future<({bool success, double newBalance, String message})> deductFunds({
    required double amount,
    String title = 'E-Commerce Order Payment',
    String? referenceId,
  }) async {
    try {
      final result = await _repo.deductFunds(
        amount: amount,
        title: title,
        referenceId: referenceId,
      );
      if (result.success) {
        await loadWalletData();
      }
      return result;
    } catch (e) {
      debugPrint('[WalletViewModel] deductFunds error: $e');
      return (
        success: false,
        newBalance: _wallet.balance,
        message: 'Failed to deduct from wallet: $e',
      );
    }
  }
}
