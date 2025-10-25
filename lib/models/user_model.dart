class UserModel {
  final String uid;
  final String email;
  final double balance;
  final Map<String, double> holdings; // {coinId: amount}
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.balance,
    required this.holdings,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      balance: (json['balance'] ?? 10000.0).toDouble(),
      holdings: Map<String, double>.from(json['holdings'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'balance': balance,
      'holdings': holdings,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    double? balance,
    Map<String, double>? holdings,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      balance: balance ?? this.balance,
      holdings: holdings ?? this.holdings,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
