import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'device_management_page.dart';
import 'notification_settings_page.dart';
import '../pages/debug_page.dart';
import '../pages/simulate_balance_page.dart';
import '../pages/notification_demo_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Tài khoản'),
            subtitle: Text(authService.currentUser?.email ?? ''),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Giả lập số dư'),
            subtitle: const Text('Điều chỉnh số tiền và tài sản cho demo'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SimulateBalancePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active, color: Colors.blue),
            title: const Text('Cài đặt thông báo'),
            subtitle: const Text('Tùy chỉnh các loại thông báo nhận được'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationSettingsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active, color: Colors.amber),
            title: const Text('🔔 Demo Push Notification'),
            subtitle: const Text('Test các loại thông báo'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationDemoPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Quản lý thiết bị'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DeviceManagementPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Debug & Cache'),
            subtitle: const Text('Thông tin cache và kiểm tra API'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DebugPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Về ứng dụng'),
            subtitle: const Text('Phiên bản 1.0.0'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xác nhận'),
                  content: const Text('Bạn có chắc muốn đăng xuất?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await authService.signOut();
              }
            },
          ),
        ],
      ),
    );
  }
}
