import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_settings.dart';
import '../services/auth_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final _db = FirebaseFirestore.instance;
  UserNotificationSettings? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUserId;

    if (userId == null) return;

    try {
      final doc = await _db.collection('users').doc(userId).get();
      final settingsData = doc.data()?['notificationSettings'];
      
      setState(() {
        _settings = UserNotificationSettings.fromMap(settingsData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _settings = UserNotificationSettings();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSettings(UserNotificationSettings newSettings) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUserId;

    if (userId == null) return;

    try {
      await _db.collection('users').doc(userId).update({
        'notificationSettings': newSettings.toMap(),
      });

      setState(() {
        _settings = newSettings;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã lưu cài đặt')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt thông báo'),
        backgroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _settings == null
              ? const Center(child: Text('Không thể tải cài đặt'))
              : ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue[50],
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Bật/tắt các loại thông báo bạn muốn nhận',
                              style: TextStyle(color: Colors.blue[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    _buildSettingTile(
                      icon: Icons.swap_horiz,
                      color: Colors.green,
                      title: 'Thông báo giao dịch',
                      subtitle: 'Nhận thông báo khi mua/bán coin thành công',
                      value: _settings!.tradeNotifications,
                      onChanged: (value) {
                        _updateSettings(_settings!.copyWith(tradeNotifications: value));
                      },
                    ),
                    
                    _buildSettingTile(
                      icon: Icons.notifications_active,
                      color: Colors.orange,
                      title: 'Cảnh báo giá',
                      subtitle: 'Thông báo khi giá coin đạt mức đặt trước',
                      value: _settings!.priceAlerts,
                      onChanged: (value) {
                        _updateSettings(_settings!.copyWith(priceAlerts: value));
                      },
                    ),
                    
                    _buildSettingTile(
                      icon: Icons.trending_up,
                      color: Colors.red,
                      title: 'Cảnh báo biến động',
                      subtitle: 'Thông báo khi giá biến động mạnh',
                      value: _settings!.volatilityAlerts,
                      onChanged: (value) {
                        _updateSettings(_settings!.copyWith(volatilityAlerts: value));
                      },
                    ),
                    
                    _buildSettingTile(
                      icon: Icons.article,
                      color: Colors.blue,
                      title: 'Tin tức thị trường',
                      subtitle: 'Nhận tin tức và cập nhật mới nhất',
                      value: _settings!.newsNotifications,
                      onChanged: (value) {
                        _updateSettings(_settings!.copyWith(newsNotifications: value));
                      },
                    ),
                    
                    _buildSettingTile(
                      icon: Icons.notifications,
                      color: Colors.grey,
                      title: 'Thông báo chung',
                      subtitle: 'Các thông báo khác từ hệ thống',
                      value: _settings!.generalNotifications,
                      onChanged: (value) {
                        _updateSettings(_settings!.copyWith(generalNotifications: value));
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _updateSettings(UserNotificationSettings());
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Đặt lại mặc định'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
        value: value,
        activeColor: color,
        onChanged: onChanged,
      ),
    );
  }
}
