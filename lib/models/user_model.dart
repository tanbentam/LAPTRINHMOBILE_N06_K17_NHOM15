class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final double balance;
  final Map<String, double> holdings;
  final List<String> favoriteCoins;
  final String? password; // Thêm trường password
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.balance = 1000.0,
    this.holdings = const {},
    this.favoriteCoins = const [],
    this.password, // Thêm parameter password
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      balance: (map['balance'] ?? 1000.0).toDouble(),
      holdings: Map<String, double>.from(map['holdings'] ?? {}),
      favoriteCoins: List<String>.from(map['favoriteCoins'] ?? []),
      password: map['password'], // Đọc password từ map
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'balance': balance,
      'holdings': holdings,
      'favoriteCoins': favoriteCoins,
      'password': password, // Thêm password vào map để lưu Firebase
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    double? balance,
    Map<String, double>? holdings,
    List<String>? favoriteCoins,
    String? password,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      balance: balance ?? this.balance,
      holdings: holdings ?? this.holdings,
      favoriteCoins: favoriteCoins ?? this.favoriteCoins,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}