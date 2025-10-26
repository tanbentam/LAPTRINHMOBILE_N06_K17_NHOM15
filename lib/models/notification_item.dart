class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type; // trade, price_alert, volatility, news, etc.
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'general',
      timestamp: map['timestamp']?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      data: map['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': timestamp,
      'isRead': isRead,
      'data': data,
    };
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}
