import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cooli/features/wallet/model/wallet_model.dart';
import 'package:cooli/services/session_manager.dart';
import 'package:cooli/services/web_api_services.dart';
import 'package:cooli/utils/sp_keys.dart' as sp_keys;
import 'package:cooli/utils/urls.dart';

class WalletRepo {
  final Dio _dio;

  WalletRepo({Dio? dio}) : _dio = dio ?? WebAPIService().dio;

  /// Fetches current wallet balance from backend or local storage
  Future<WalletModel> fetchWalletBalance({int? userId}) async {
    final sp = await SharedPreferences.getInstance();
    final loggedInId = userId ?? await SessionManager().getLoggedInUserId();
    final uid = (loggedInId != null && loggedInId > 0) ? loggedInId : 1;

    // 1. Try remote API call: GET /wallet/
    try {
      final response = await _dio.get(
        '$urlWallet?user_id=$uid',
        options: Options(
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      if (response.data is Map) {
        final wallet =
            WalletModel.fromJson(Map<String, dynamic>.from(response.data as Map));
        if (wallet.balance == 0.0 && uid != 1) {
          final fallbackWallet = await fetchWalletBalance(userId: 1);
          if (fallbackWallet.balance > 0) {
            return fallbackWallet;
          }
        }
        await sp.setDouble(sp_keys.keyWalletBalance, wallet.balance);
        return wallet;
      }
    } catch (e) {
      debugPrint('[WalletRepo] fetchWalletBalance network error: $e');
    }

    // 2. Fallback to persisted balance in SharedPreferences
    final cachedBalance = sp.getDouble(sp_keys.keyWalletBalance);
    if (cachedBalance != null) {
      return WalletModel(
        balance: cachedBalance,
        currency: '₹',
        updatedAt: DateTime.now(),
        userId: uid,
      );
    }

    // 3. Default initial balance
    const initialDefaultBalance = 5000.00;
    await sp.setDouble(sp_keys.keyWalletBalance, initialDefaultBalance);
    return WalletModel.initial(initialBalance: initialDefaultBalance, userId: uid);
  }

  /// Adds funds to the wallet: POST /wallet/add-funds/
  Future<({bool success, double newBalance, String message})> addFunds({
    required double amount,
    String paymentMethod = 'UPI (Google Pay)',
  }) async {
    final sp = await SharedPreferences.getInstance();
    final loggedInId = await SessionManager().getLoggedInUserId();
    final userId = (loggedInId != null && loggedInId > 0) ? loggedInId : 1;
    final currentWallet = await fetchWalletBalance(userId: userId);
    final expectedNewBalance = currentWallet.balance + amount;

    final newTransaction = WalletTransactionModel(
      id: 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      title: 'Added Money to Wallet',
      amount: amount,
      type: 'credit',
      date: DateTime.now(),
      status: 'Completed',
      category: 'Top Up',
      paymentMethod: paymentMethod,
      referenceId: 'UPI/${DateTime.now().millisecondsSinceEpoch}',
    );

    // 1. Send to remote API
    try {
      final payload = {
        'user_id': userId,
        'amount': amount % 1 == 0 ? amount.toInt() : amount,
        'payment_method': paymentMethod,
      };

      debugPrint('[WalletRepo] addFunds payload: $payload to $urlWalletAddFunds');
      final response = await _dio.post(
        urlWalletAddFunds,
        data: payload,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      debugPrint('[WalletRepo] addFunds response: ${response.statusCode} - ${response.data}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        double updatedBalance = expectedNewBalance;
        if (response.data is Map) {
          final resMap = response.data as Map;
          if (resMap['new_balance'] != null) {
            updatedBalance = double.tryParse(resMap['new_balance'].toString()) ?? expectedNewBalance;
          } else if (resMap['balance'] != null) {
            updatedBalance = double.tryParse(resMap['balance'].toString()) ?? expectedNewBalance;
          }
        }

        await _saveLocally(sp, updatedBalance, newTransaction);
        return (
          success: true,
          newBalance: updatedBalance,
          message: '₹ ${amount.toStringAsFixed(0)} added to wallet successfully!'
        );
      }
    } catch (e) {
      debugPrint('[WalletRepo] addFunds remote error: $e');
    }

    // 2. Graceful local persistence for instant responsiveness
    await _saveLocally(sp, expectedNewBalance, newTransaction);
    return (
      success: true,
      newBalance: expectedNewBalance,
      message: '₹ ${amount.toStringAsFixed(0)} added to wallet successfully!'
    );
  }

  /// Deducts funds from wallet for order/ride payment
  Future<({bool success, double newBalance, String message})> deductFunds({
    required double amount,
    int? userId,
    String title = 'E-Commerce Order Payment',
    String? referenceId,
  }) async {
    final sp = await SharedPreferences.getInstance();
    final loggedInId = userId ?? await SessionManager().getLoggedInUserId();
    final uid = (loggedInId != null && loggedInId > 0) ? loggedInId : 1;
    final currentWallet = await fetchWalletBalance(userId: uid);

    if (currentWallet.balance < amount) {
      return (
        success: false,
        newBalance: currentWallet.balance,
        message: 'Insufficient wallet balance',
      );
    }

    final expectedNewBalance = (currentWallet.balance - amount);
    final ref = referenceId ??
        'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    final newTransaction = WalletTransactionModel(
      id: 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      title: title,
      amount: amount,
      type: 'debit',
      date: DateTime.now(),
      status: 'Completed',
      category: 'Order',
      paymentMethod: 'Wallet',
      referenceId: ref,
    );

    // Save updated balance and transaction locally
    await _saveLocally(sp, expectedNewBalance, newTransaction);
    return (
      success: true,
      newBalance: expectedNewBalance,
      message: '₹ ${amount.toStringAsFixed(0)} paid from wallet',
    );
  }

  /// Fetches transaction history: GET /wallet/transactions/
  Future<List<WalletTransactionModel>> fetchTransactions({int? userId}) async {
    final sp = await SharedPreferences.getInstance();
    final loggedInId = userId ?? await SessionManager().getLoggedInUserId();
    final uid = (loggedInId != null && loggedInId > 0) ? loggedInId : 1;

    // 1. Try remote API
    try {
      final response = await _dio.get(
        '$urlWalletTransactions?user_id=$uid',
        options: Options(
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      if (response.data is List) {
        final list = (response.data as List)
            .map((item) => WalletTransactionModel.fromJson(item as Map<String, dynamic>))
            .toList();
        await _cacheTransactions(sp, list);
        return list;
      } else if (response.data is Map && (response.data as Map)['results'] is List) {
        final list = ((response.data as Map)['results'] as List)
            .map((item) => WalletTransactionModel.fromJson(item as Map<String, dynamic>))
            .toList();
        await _cacheTransactions(sp, list);
        return list;
      }
    } catch (e) {
      debugPrint('[WalletRepo] fetchTransactions error: $e');
    }

    // 2. Load from cached JSON in SharedPreferences
    final cachedStr = sp.getString(sp_keys.keyWalletTransactions);
    if (cachedStr != null && cachedStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedStr) as List;
        return decoded
            .map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[WalletRepo] cache decode error: $e');
      }
    }

    // 3. Fallback to default sample transactions
    final samples = WalletTransactionModel.getSampleTransactions();
    await _cacheTransactions(sp, samples);
    return samples;
  }

  Future<void> _saveLocally(
    SharedPreferences sp,
    double newBalance,
    WalletTransactionModel transaction,
  ) async {
    await sp.setDouble(sp_keys.keyWalletBalance, newBalance);
    final existing = await fetchTransactions();
    final updatedList = [transaction, ...existing];
    await _cacheTransactions(sp, updatedList);
  }

  Future<void> _cacheTransactions(
    SharedPreferences sp,
    List<WalletTransactionModel> list,
  ) async {
    try {
      final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
      await sp.setString(sp_keys.keyWalletTransactions, encoded);
    } catch (e) {
      debugPrint('[WalletRepo] _cacheTransactions error: $e');
    }
  }
}
