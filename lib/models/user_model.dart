class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final double balance;
  final Map<String, double> holdings;
  final List<String> favoriteCoins;
  final List<String> watchlist; // Danh sách theo dõi
  final String? password; // Thêm trường password
  final String role; // Thêm trường role (user, admin)
  final bool isActive; // Trạng thái hoạt động của tài khoản
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
    this.watchlist = const [],
    this.password, // Thêm parameter password
    this.role = 'user', // Mặc định là user
    this.isActive = true, // Mặc định là active
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
      watchlist: List<String>.from(map['watchlist'] ?? []),
      password: map['password'], // Đọc password từ map
      role: map['role'] ?? 'user', // Đọc role từ map
      isActive: map['isActive'] ?? true, // Đọc isActive từ map
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
      'watchlist': watchlist,
      'password': password, // Thêm password vào map để lưu Firebase
      'role': role, // Thêm role vào map
      'isActive': isActive, // Thêm isActive vào map
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
    List<String>? watchlist,
    String? password,
    String? role,
    bool? isActive,
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
      watchlist: watchlist ?? this.watchlist,
      password: password ?? this.password,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Phương thức kiểm tra quyền admin
  bool get isAdmin => role == 'admin';
}