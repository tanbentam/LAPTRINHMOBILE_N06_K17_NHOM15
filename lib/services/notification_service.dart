import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        print('Notification tapped: ${details.payload}');
      },
    );
    
    _isInitialized = true;
    print('✅ Notification service initialized');
  }

  Future<void> showPriceAlert({
    required String coinSymbol,
    required double targetPrice,
    required double currentPrice,
    required bool isAbove,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'price_alerts',
      'Price Alerts',
      channelDescription: 'Notifications for price alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    final title = '🎯 Price Alert: $coinSymbol';
    final body = isAbove
        ? '📈 Price rose above \$${targetPrice.toStringAsFixed(2)} (Current: \$${currentPrice.toStringAsFixed(2)})'
        : '📉 Price fell below \$${targetPrice.toStringAsFixed(2)} (Current: \$${currentPrice.toStringAsFixed(2)})';

    await _notifications.show(
      coinSymbol.hashCode,
      title,
      body,
      notificationDetails,
      payload: 'price_alert:$coinSymbol',
    );
  }

  Future<void> showTradeNotification({
    required String type,
    required String coinSymbol,
    required double amount,
    required double price,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'trade_notifications',
      'Trade Notifications',
      channelDescription: 'Notifications for successful trades',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    final isBuy = type.toLowerCase() == 'buy';
    final title = isBuy ? '✅ Purchase Successful' : '✅ Sale Successful';
    final body = '${isBuy ? 'Bought' : 'Sold'} $amount $coinSymbol at \$${price.toStringAsFixed(2)}';

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      notificationDetails,
      payload: 'trade:$coinSymbol',
    );
  }

  Future<void> showStopLossTriggered({
    required String coinSymbol,
    required double stopLossPrice,
    required double currentPrice,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'stop_loss',
      'Stop Loss Alerts',
      channelDescription: 'Notifications when stop loss is triggered',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch,
      '🛑 Stop Loss Triggered: $coinSymbol',
      'Sold at \$${currentPrice.toStringAsFixed(2)} (Stop Loss: \$${stopLossPrice.toStringAsFixed(2)})',
      notificationDetails,
      payload: 'stop_loss:$coinSymbol',
    );
  }

  Future<void> showTakeProfitTriggered({
    required String coinSymbol,
    required double takeProfitPrice,
    required double currentPrice,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'take_profit',
      'Take Profit Alerts',
      channelDescription: 'Notifications when take profit is triggered',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch,
      '🎉 Take Profit Triggered: $coinSymbol',
      'Sold at \$${currentPrice.toStringAsFixed(2)} (Take Profit: \$${takeProfitPrice.toStringAsFixed(2)})',
      notificationDetails,
      payload: 'take_profit:$coinSymbol',
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}
