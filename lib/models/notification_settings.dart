class UserNotificationSettings {
  final bool tradeNotifications;
  final bool priceAlerts;
  final bool volatilityAlerts;
  final bool newsNotifications;
  final bool generalNotifications;

  UserNotificationSettings({
    this.tradeNotifications = true,
    this.priceAlerts = true,
    this.volatilityAlerts = true,
    this.newsNotifications = true,
    this.generalNotifications = true,
  });

  factory UserNotificationSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return UserNotificationSettings();
    return UserNotificationSettings(
      tradeNotifications: map['tradeNotifications'] ?? true,
      priceAlerts: map['priceAlerts'] ?? true,
      volatilityAlerts: map['volatilityAlerts'] ?? true,
      newsNotifications: map['newsNotifications'] ?? true,
      generalNotifications: map['generalNotifications'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tradeNotifications': tradeNotifications,
      'priceAlerts': priceAlerts,
      'volatilityAlerts': volatilityAlerts,
      'newsNotifications': newsNotifications,
      'generalNotifications': generalNotifications,
    };
  }

  UserNotificationSettings copyWith({
    bool? tradeNotifications,
    bool? priceAlerts,
    bool? volatilityAlerts,
    bool? newsNotifications,
    bool? generalNotifications,
  }) {
    return UserNotificationSettings(
      tradeNotifications: tradeNotifications ?? this.tradeNotifications,
      priceAlerts: priceAlerts ?? this.priceAlerts,
      volatilityAlerts: volatilityAlerts ?? this.volatilityAlerts,
      newsNotifications: newsNotifications ?? this.newsNotifications,
      generalNotifications: generalNotifications ?? this.generalNotifications,
    );
  }
}
