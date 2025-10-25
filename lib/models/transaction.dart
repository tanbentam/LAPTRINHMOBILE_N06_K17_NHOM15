class Transaction {
  final String id;
  final String userId;
  final String coinId;
  final String coinSymbol;
  final String type; // 'buy' or 'sell'
  final double amount;
  final double price;
  final double total;
  final DateTime timestamp;
  final double? stopLoss;    // Giá cắt lỗ (optional)
  final double? takeProfit;  // Giá chốt lời (optional)
  final bool autoSellEnabled;
  final String? notes;       // Ghi chú

  Transaction({
    required this.id,
    required this.userId,
    required this.coinId,
    required this.coinSymbol,
    required this.type,
    required this.amount,
    required this.price,
    required this.total,
    required this.timestamp,
    this.stopLoss,
    this.takeProfit,
    this.autoSellEnabled = false,
    this.notes,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      coinId: json['coinId'] ?? '',
      coinSymbol: json['coinSymbol'] ?? '',
      type: json['type'] ?? 'buy',
      amount: (json['amount'] ?? 0).toDouble(),
      price: (json['price'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      stopLoss: json['stopLoss'] != null ? (json['stopLoss'] as num).toDouble() : null,
      takeProfit: json['takeProfit'] != null ? (json['takeProfit'] as num).toDouble() : null,
      autoSellEnabled: json['autoSellEnabled'] ?? false,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'coinId': coinId,
      'coinSymbol': coinSymbol,
      'type': type,
      'amount': amount,
      'price': price,
      'total': total,
      'timestamp': timestamp.toIso8601String(),
      'stopLoss': stopLoss,
      'takeProfit': takeProfit,
      'autoSellEnabled': autoSellEnabled,
      'notes': notes,
    };
  }
}
