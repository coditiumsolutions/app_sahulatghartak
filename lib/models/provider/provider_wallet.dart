class WalletTransactionEntry {
  final int uid;
  final DateTime createdOn;
  final int? bookingUid;
  final String reason;
  final double signedAmount;
  final double runningBalance;

  const WalletTransactionEntry({
    required this.uid,
    required this.createdOn,
    this.bookingUid,
    required this.reason,
    required this.signedAmount,
    required this.runningBalance,
  });

  factory WalletTransactionEntry.fromJson(Map<String, dynamic> json) {
    return WalletTransactionEntry(
      uid: json['uid'] as int,
      createdOn: DateTime.parse(json['createdOn'] as String),
      bookingUid: json['bookingUid'] as int?,
      reason: json['reason'] as String? ?? '',
      signedAmount: (json['signedAmount'] as num?)?.toDouble() ?? 0,
      runningBalance: (json['runningBalance'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ProviderWallet {
  final int providerUid;
  final String providerName;
  final String categoryName;
  final double balance;
  final double pendingPayoutTotal;
  final List<WalletTransactionEntry> transactions;

  const ProviderWallet({
    required this.providerUid,
    required this.providerName,
    required this.categoryName,
    required this.balance,
    required this.pendingPayoutTotal,
    required this.transactions,
  });

  factory ProviderWallet.fromJson(Map<String, dynamic> json) {
    final List<dynamic> txns = json['transactions'] as List<dynamic>? ?? [];
    return ProviderWallet(
      providerUid: json['providerUid'] as int,
      providerName: json['providerName'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      pendingPayoutTotal: (json['pendingPayoutTotal'] as num?)?.toDouble() ?? 0,
      transactions: txns.map((t) => WalletTransactionEntry.fromJson(t as Map<String, dynamic>)).toList(),
    );
  }
}
