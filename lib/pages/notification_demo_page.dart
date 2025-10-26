import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/notification_service.dart';

/// 🔔 Trang Demo cho Push Notification
/// Dùng để test và demo các loại thông báo khác nhau
class NotificationDemoPage extends StatefulWidget {
  const NotificationDemoPage({super.key});

  @override
  State<NotificationDemoPage> createState() => _NotificationDemoPageState();
}

class _NotificationDemoPageState extends State<NotificationDemoPage> {
  final _notificationService = NotificationService();
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _loadFCMToken();
  }

  void _loadFCMToken() {
    setState(() {
      _fcmToken = _notificationService.fcmToken;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔔 Demo Push Notification'),
        backgroundColor: Colors.amber,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // FCM Token Section
          _buildFCMTokenCard(),
          const SizedBox(height: 16),
          
          // Instructions
          _buildInstructionsCard(),
          const SizedBox(height: 16),
          
          // Demo Buttons
          const Text(
            '📱 Local Notifications Demo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          _buildDemoButton(
            title: '💰 Thông báo Mua coin',
            subtitle: 'Mua 0.01 BTC với giá \$50,000',
            icon: Icons.shopping_cart,
            color: Colors.green,
            onPressed: () => _showBuyNotification(),
          ),
          
          _buildDemoButton(
            title: '💵 Thông báo Bán coin',
            subtitle: 'Bán 0.5 ETH với giá \$3,000',
            icon: Icons.sell,
            color: Colors.orange,
            onPressed: () => _showSellNotification(),
          ),
          
          _buildDemoButton(
            title: '🎯 Cảnh báo giá tăng',
            subtitle: 'BTC vượt mốc \$52,000',
            icon: Icons.trending_up,
            color: Colors.blue,
            onPressed: () => _showPriceAlertUp(),
          ),
          
          _buildDemoButton(
            title: '📉 Cảnh báo giá giảm',
            subtitle: 'BTC giảm xuống \$48,000',
            icon: Icons.trending_down,
            color: Colors.red,
            onPressed: () => _showPriceAlertDown(),
          ),
          
          _buildDemoButton(
            title: '🚀 Biến động mạnh (Tăng)',
            subtitle: 'BTC tăng 5% trong 1 giờ',
            icon: Icons.rocket_launch,
            color: Colors.purple,
            onPressed: () => _showVolatilityUp(),
          ),
          
          _buildDemoButton(
            title: '⚠️ Biến động mạnh (Giảm)',
            subtitle: 'ETH giảm 8% trong 1 giờ',
            icon: Icons.warning,
            color: Colors.deepOrange,
            onPressed: () => _showVolatilityDown(),
          ),
          
          _buildDemoButton(
            title: '💸 Nhận coin',
            subtitle: 'Nhận 50 USDT từ Hoàng',
            icon: Icons.call_received,
            color: Colors.teal,
            onPressed: () => _showReceivedCoin(),
          ),
          
          _buildDemoButton(
            title: '📰 Tin tức thị trường',
            subtitle: 'Bitcoin ETF được phê duyệt',
            icon: Icons.newspaper,
            color: Colors.indigo,
            onPressed: () => _showMarketNews(),
          ),
          
          _buildDemoButton(
            title: '🛑 Stop Loss kích hoạt',
            subtitle: 'BTC đã bán tại stop loss',
            icon: Icons.stop_circle,
            color: Colors.red[900]!,
            onPressed: () => _showStopLoss(),
          ),
          
          _buildDemoButton(
            title: '🎉 Take Profit kích hoạt',
            subtitle: 'ETH đã bán tại take profit',
            icon: Icons.celebration,
            color: Colors.green[700]!,
            onPressed: () => _showTakeProfit(),
          ),
          
          const SizedBox(height: 20),
          
          // Clear all notifications
          ElevatedButton.icon(
            onPressed: () {
              _notificationService.cancelAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Đã xóa tất cả thông báo')),
              );
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Xóa tất cả thông báo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFCMTokenCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.vpn_key, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'FCM Token',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_fcmToken != null)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _fcmToken!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Đã copy FCM Token')),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _fcmToken ?? 'Đang tải...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontFamily: 'monospace',
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '💡 Dùng token này để gửi thông báo từ Firebase Console',
              style: TextStyle(fontSize: 11, color: Colors.blue[900]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Hướng dẫn sử dụng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInstruction('1️⃣', 'Nhấn các nút bên dưới để test local notifications'),
            _buildInstruction('2️⃣', 'Copy FCM Token để test từ Firebase Console'),
            _buildInstruction('3️⃣', 'Vào Firebase Console > Cloud Messaging'),
            _buildInstruction('4️⃣', 'Chọn "Send test message" và paste token'),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(number, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.send),
        onTap: () {
          onPressed();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã gửi: $title'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  // ========== Demo Notification Methods ==========

  void _showBuyNotification() {
    _notificationService.showTradeNotification(
      type: 'buy',
      coinSymbol: 'BTC',
      amount: 0.01,
      price: 50000,
    );
  }

  void _showSellNotification() {
    _notificationService.showTradeNotification(
      type: 'sell',
      coinSymbol: 'ETH',
      amount: 0.5,
      price: 3000,
    );
  }

  void _showPriceAlertUp() {
    _notificationService.showPriceAlert(
      coinSymbol: 'BTC',
      targetPrice: 52000,
      currentPrice: 52150,
      isAbove: true,
    );
  }

  void _showPriceAlertDown() {
    _notificationService.showPriceAlert(
      coinSymbol: 'BTC',
      targetPrice: 48000,
      currentPrice: 47850,
      isAbove: false,
    );
  }

  void _showVolatilityUp() {
    _notificationService.showVolatilityAlert(
      coinSymbol: 'BTC',
      changePercent: 5.2,
      timeframe: '1 giờ qua',
    );
  }

  void _showVolatilityDown() {
    _notificationService.showVolatilityAlert(
      coinSymbol: 'ETH',
      changePercent: -8.1,
      timeframe: '1 giờ qua',
    );
  }

  void _showReceivedCoin() {
    _notificationService.showReceivedCoinNotification(
      fromUser: 'Hoàng',
      amount: 50,
      coinSymbol: 'USDT',
    );
  }

  void _showMarketNews() {
    _notificationService.showMarketNewsNotification(
      coinSymbol: 'BTC',
      newsTitle: 'Bitcoin ETF được phê duyệt',
      newsBody: 'SEC đã chính thức phê duyệt Bitcoin ETF, thị trường phản ứng tích cực.',
    );
  }

  void _showStopLoss() {
    _notificationService.showStopLossTriggered(
      coinSymbol: 'BTC',
      stopLossPrice: 49000,
      currentPrice: 48950,
    );
  }

  void _showTakeProfit() {
    _notificationService.showTakeProfitTriggered(
      coinSymbol: 'ETH',
      takeProfitPrice: 3200,
      currentPrice: 3205,
    );
  }
}
