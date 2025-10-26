import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Top-level function để xử lý background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Background message received: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  bool _isInitialized = false;
  String? _fcmToken;
  
  // Counter cho notification ID
  static int _notificationIdCounter = 0;
  
  // Getter để lấy FCM token
  String? get fcmToken => _fcmToken;

  /// Generate safe notification ID (trong khoảng 32-bit integer)
  int _generateNotificationId() {
    _notificationIdCounter = (_notificationIdCounter + 1) % 2147483647; // Max 32-bit int
    return _notificationIdCounter;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Khởi tạo Local Notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // 2. Đăng ký background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // 3. Request permission cho notifications (Android 13+)
    await _requestPermission();
    
    // 4. Lấy FCM token
    await _initializeFCM();
    
    // 5. Lắng nghe foreground messages
    _listenToForegroundMessages();
    
    // 6. Xử lý notification khi app được mở từ terminated state
    _handleInitialMessage();
    
    _isInitialized = true;
    print('✅ Notification service initialized with FCM');
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notification permission granted');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ Provisional notification permission granted');
      } else {
        print('❌ Notification permission denied');
      }
    } catch (e) {
      print('❌ Error requesting permission: $e');
    }
  }

  /// Khởi tạo FCM và lưu token
  Future<void> _initializeFCM() async {
    try {
      // Lấy FCM token
      _fcmToken = await _fcm.getToken();
      print('📱 FCM Token: $_fcmToken');
      
      // Lưu token vào Firestore
      if (_fcmToken != null) {
        await _saveFCMToken(_fcmToken!);
      }
      
      // Lắng nghe token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('🔄 FCM Token refreshed: $newToken');
        _saveFCMToken(newToken);
      });
    } catch (e) {
      print('❌ Error initializing FCM: $e');
    }
  }

  /// Lưu FCM token vào Firestore
  Future<void> _saveFCMToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _db.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('✅ FCM Token saved to Firestore');
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// Lắng nghe foreground messages
  void _listenToForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Foreground message received: ${message.messageId}');
      
      // Hiển thị notification khi app đang mở
      if (message.notification != null) {
        _showFCMNotification(message);
      }
    });
  }

  /// Hiển thị FCM notification
  Future<void> _showFCMNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;
    
    if (notification == null) return;
    
    const androidDetails = AndroidNotificationDetails(
      'fcm_messages',
      'FCM Messages',
      channelDescription: 'Firebase Cloud Messaging notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      _generateNotificationId(),
      notification.title ?? 'Crypto App',
      notification.body ?? '',
      notificationDetails,
      payload: data['route'] ?? data['type'] ?? 'default',
    );
  }

  /// Xử lý khi tap vào notification
  void _onNotificationTapped(NotificationResponse details) {
    print('🔔 Notification tapped: ${details.payload}');
    
    // Navigation sẽ được xử lý bởi UI layer thông qua stream hoặc callback
    // Payload có thể chứa thông tin như: "coin_id:bitcoin", "trade_id:12345", etc.
  }

  /// Xử lý notification khi app được mở từ terminated state
  void _handleInitialMessage() {
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('🚀 App opened from notification: ${message.messageId}');
        // Navigation được xử lý tại main.dart hoặc home_page.dart
      }
    });
    
    // Xử lý khi app được mở từ background state
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('🔓 App opened from background: ${message.messageId}');
      // Navigation được xử lý tại main.dart hoặc home_page.dart
    });
  }

  // ============= LOCAL NOTIFICATION METHODS =============

  /// Hiển thị thông báo giao dịch thành công
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
      enableVibration: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    final isBuy = type.toLowerCase() == 'buy';
    final emoji = isBuy ? '💰' : '💵';
    final title = '$emoji ${isBuy ? 'Mua' : 'Bán'} thành công';
    final totalValue = amount * price;
    final body = '${isBuy ? 'Đã mua' : 'Đã bán'} ${amount.toStringAsFixed(8)} $coinSymbol\n'
                 'Giá: \$${price.toStringAsFixed(2)}\n'
                 'Tổng: \$${totalValue.toStringAsFixed(2)}';

    await _notifications.show(
      _generateNotificationId(),
      title,
      body,
      notificationDetails,
      payload: 'trade:$coinSymbol',
    );
  }

  /// Hiển thị thông báo cảnh báo giá
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
      enableVibration: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    final title = '🎯 Cảnh báo giá: $coinSymbol';
    final body = isAbove
        ? '📈 Giá đã vượt \$${targetPrice.toStringAsFixed(2)}\nHiện tại: \$${currentPrice.toStringAsFixed(2)}'
        : '📉 Giá đã giảm xuống \$${targetPrice.toStringAsFixed(2)}\nHiện tại: \$${currentPrice.toStringAsFixed(2)}';

    await _notifications.show(
      _generateNotificationId(),
      title,
      body,
      notificationDetails,
      payload: 'price_alert:$coinSymbol',
    );
  }

  /// Hiển thị thông báo tin tức thị trường
  Future<void> showMarketNewsNotification({
    required String coinSymbol,
    required String newsTitle,
    required String newsBody,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'market_news',
      'Market News',
      channelDescription: 'Notifications for market news and updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      _generateNotificationId(),
      '📰 $newsTitle',
      newsBody,
      notificationDetails,
      payload: 'news:$coinSymbol',
    );
  }

  /// Hiển thị thông báo biến động mạnh
  Future<void> showVolatilityAlert({
    required String coinSymbol,
    required double changePercent,
    required String timeframe,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'volatility_alerts',
      'Volatility Alerts',
      channelDescription: 'Notifications for high price volatility',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    final isPositive = changePercent > 0;
    final emoji = isPositive ? '🚀' : '⚠️';
    final sign = isPositive ? '+' : '';
    
    await _notifications.show(
      _generateNotificationId(),
      '$emoji Biến động mạnh: $coinSymbol',
      '$coinSymbol ${isPositive ? 'tăng' : 'giảm'} $sign${changePercent.toStringAsFixed(2)}% trong $timeframe',
      notificationDetails,
      payload: 'volatility:$coinSymbol',
    );
  }

  /// Hiển thị thông báo Stop Loss
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
      enableVibration: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      _generateNotificationId(),
      '🛑 Stop Loss đã kích hoạt: $coinSymbol',
      'Đã bán tại \$${currentPrice.toStringAsFixed(2)}\n(Stop Loss: \$${stopLossPrice.toStringAsFixed(2)})',
      notificationDetails,
      payload: 'stop_loss:$coinSymbol',
    );
  }

  /// Hiển thị thông báo Take Profit
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
      enableVibration: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      _generateNotificationId(),
      '🎉 Take Profit đã kích hoạt: $coinSymbol',
      'Đã bán tại \$${currentPrice.toStringAsFixed(2)}\n(Take Profit: \$${takeProfitPrice.toStringAsFixed(2)})',
      notificationDetails,
      payload: 'take_profit:$coinSymbol',
    );
  }

  /// Hiển thị thông báo nhận coin từ người khác
  Future<void> showReceivedCoinNotification({
    required String fromUser,
    required double amount,
    required String coinSymbol,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'received_coins',
      'Received Coins',
      channelDescription: 'Notifications when receiving coins',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      _generateNotificationId(),
      '💸 Nhận coin từ $fromUser',
      'Bạn vừa nhận ${amount.toStringAsFixed(8)} $coinSymbol',
      notificationDetails,
      payload: 'received:$coinSymbol',
    );
  }

  /// Hủy tất cả notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Hủy một notification cụ thể
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}