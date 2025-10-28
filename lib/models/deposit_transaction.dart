class DepositTransaction {
  final String id;
  final String userId;
  final String type; // 'deposit' or 'withdraw'
  final double amount; // Amount in USD
  final DateTime timestamp;
  final String paymentMethod; // 'momo', 'visa', 'bank_transfer'
  final String status; // 'pending', 'completed', 'failed'
  final String? notes;

  DepositTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.timestamp,
    required this.paymentMethod,
    required this.status,
    this.notes,
  });

  factory DepositTransaction.fromJson(Map<String, dynamic> json) {
    return DepositTransaction(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? 'deposit',
      amount: (json['amount'] ?? 0).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      paymentMethod: json['paymentMethod'] ?? 'unknown',
      status: json['status'] ?? 'completed',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'paymentMethod': paymentMethod,
      'status': status,
      'notes': notes,
    };
  }

  // Helper để kiểm tra loại giao dịch
  bool get isDeposit => type == 'deposit';
  bool get isWithdraw => type == 'withdraw';
  
  // Helper để kiểm tra trạng thái
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
}
