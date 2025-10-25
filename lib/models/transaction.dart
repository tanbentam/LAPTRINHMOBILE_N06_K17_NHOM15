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
    };
  }
}
