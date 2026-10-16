class WalletModel {
  final double balance;
  final String currency;
  final DateTime updatedAt;
  final int? userId;
  final int transactionCount;

  const WalletModel({
    required this.balance,
    this.currency = '₹',
    required this.updatedAt,
    this.userId,
    this.transactionCount = 0,
  });

  factory WalletModel.initial({double initialBalance = 2450.00, int? userId}) {
    return WalletModel(
      balance: initialBalance,
      currency: '₹',
      updatedAt: DateTime.now(),
      userId: userId,
      transactionCount: 4,
    );
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final rawBalance = json['balance'] ?? json['wallet_balance'] ?? json['amount'];
    final parsedBalance = double.tryParse(rawBalance?.toString() ?? '') ?? 0.0;
    final userId = int.tryParse(json['user_id']?.toString() ?? json['user']?.toString() ?? '');

    return WalletModel(
      balance: parsedBalance,
      currency: json['currency']?.toString() ?? '₹',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      userId: userId,
      transactionCount: int.tryParse(json['transaction_count']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'currency': currency,
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
      'transaction_count': transactionCount,
    };
  }

  WalletModel copyWith({
    double? balance,
    String? currency,
    DateTime? updatedAt,
    int? userId,
    int? transactionCount,
  }) {
    return WalletModel(
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      transactionCount: transactionCount ?? this.transactionCount,
    );
  }
}

class WalletTransactionModel {
  final String id;
  final String title;
  final double amount;
  final String type; // 'credit' | 'debit'
  final DateTime date;
  final String status; // 'Completed' | 'Pending' | 'Failed'
  final String category; // 'Top Up' | 'Freight' | 'Ride' | 'Refund' | 'Cashback'
  final String paymentMethod;
  final String? referenceId;

  const WalletTransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    this.status = 'Completed',
    this.category = 'Top Up',
    this.paymentMethod = 'UPI',
    this.referenceId,
  });

  bool get isCredit => type.toLowerCase() == 'credit';

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount']?.toString() ?? '0';
    final parsedAmount = double.tryParse(rawAmount) ?? 0.0;
    final rawDate = json['created_at'] ?? json['date'] ?? json['timestamp'];

    return WalletTransactionModel(
      id: json['id']?.toString() ??
          json['transaction_id']?.toString() ??
          'TXN-${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ??
          json['description']?.toString() ??
          (json['type'] == 'credit' ? 'Money Added' : 'Payment Made'),
      amount: parsedAmount,
      type: json['type']?.toString().toLowerCase() ?? 'credit',
      date: rawDate != null
          ? DateTime.tryParse(rawDate.toString()) ?? DateTime.now()
          : DateTime.now(),
      status: json['status']?.toString() ?? 'Completed',
      category: json['category']?.toString() ?? 'Top Up',
      paymentMethod: json['payment_method']?.toString() ?? 'UPI',
      referenceId: json['reference_id']?.toString() ?? json['utr']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
      'status': status,
      'category': category,
      'payment_method': paymentMethod,
      'reference_id': referenceId,
    };
  }

  static List<WalletTransactionModel> getSampleTransactions() {
    final now = DateTime.now();
    return [
      WalletTransactionModel(
        id: 'TXN-20261015-8941',
        title: 'Money Added via UPI',
        amount: 1000.00,
        type: 'credit',
        date: now.subtract(const Duration(hours: 2)),
        status: 'Completed',
        category: 'Top Up',
        paymentMethod: 'Google Pay (UPI)',
        referenceId: 'UPI/20261015/98231',
      ),
      WalletTransactionModel(
        id: 'TXN-20261014-4120',
        title: 'Payment for Transport Load',
        amount: 450.00,
        type: 'debit',
        date: now.subtract(const Duration(days: 1, hours: 3)),
        status: 'Completed',
        category: 'Freight',
        paymentMethod: 'Cooli Wallet',
        referenceId: 'LOAD-2026-001/ADV',
      ),
      WalletTransactionModel(
        id: 'TXN-20261013-7712',
        title: 'Promotional Cashback Received',
        amount: 150.00,
        type: 'credit',
        date: now.subtract(const Duration(days: 2, hours: 5)),
        status: 'Completed',
        category: 'Cashback',
        paymentMethod: 'Cooli Rewards',
        referenceId: 'CB-WELCOME-150',
      ),
      WalletTransactionModel(
        id: 'TXN-20261011-3098',
        title: 'Ride Booking Fare',
        amount: 250.00,
        type: 'debit',
        date: now.subtract(const Duration(days: 4, hours: 1)),
        status: 'Completed',
        category: 'Ride',
        paymentMethod: 'Cooli Wallet',
        referenceId: 'RD-20261011-948',
      ),
    ];
  }
}
