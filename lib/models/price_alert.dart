import 'package:cloud_firestore/cloud_firestore.dart';

class PriceAlert {
  final String id;
  final String userId;
  final String coinId;
  final String coinSymbol;
  final double targetPrice;
  final bool isAbove; // true = alert khi giá lên trên, false = xuống dưới
  final bool isActive;
  final DateTime createdAt;
  final DateTime? triggeredAt;

  PriceAlert({
    required this.id,
    required this.userId,
    required this.coinId,
    required this.coinSymbol,
    required this.targetPrice,
    required this.isAbove,
    this.isActive = true,
    required this.createdAt,
    this.triggeredAt,
  });

  factory PriceAlert.fromMap(Map<String, dynamic> map, String id) {
    return PriceAlert(
      id: id,
      userId: map['userId'] ?? '',
      coinId: map['coinId'] ?? '',
      coinSymbol: map['coinSymbol'] ?? '',
      targetPrice: (map['targetPrice'] ?? 0).toDouble(),
      isAbove: map['isAbove'] ?? true,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      triggeredAt: map['triggeredAt'] != null 
          ? (map['triggeredAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'coinId': coinId,
      'coinSymbol': coinSymbol,
      'targetPrice': targetPrice,
      'isAbove': isAbove,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'triggeredAt': triggeredAt != null ? Timestamp.fromDate(triggeredAt!) : null,
    };
  }

  PriceAlert copyWith({
    String? id,
    String? userId,
    String? coinId,
    String? coinSymbol,
    double? targetPrice,
    bool? isAbove,
    bool? isActive,
    DateTime? createdAt,
    DateTime? triggeredAt,
  }) {
    return PriceAlert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      coinId: coinId ?? this.coinId,
      coinSymbol: coinSymbol ?? this.coinSymbol,
      targetPrice: targetPrice ?? this.targetPrice,
      isAbove: isAbove ?? this.isAbove,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      triggeredAt: triggeredAt ?? this.triggeredAt,
    );
  }
}
