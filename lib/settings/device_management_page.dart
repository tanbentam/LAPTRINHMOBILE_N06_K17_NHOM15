import 'package:flutter/material.dart';

class DeviceManagementPage extends StatefulWidget {
  const DeviceManagementPage({super.key});

  @override
  State<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage> {
  // Mẫu dữ liệu device (trong thực tế bạn nên lấy từ server)
  List<Map<String, String>> devices = [
    {'id': '1', 'name': 'Windows - Chrome', 'lastSeen': '2025-10-19 14:22'},
    {'id': '2', 'name': 'Android - Pixel 7', 'lastSeen': '2025-10-20 08:10'},
    {'id': '3', 'name': 'iPhone - Safari', 'lastSeen': '2025-10-21 21:05'},
  ];

  void _signOutDevice(String id) {
    setState(() {
      devices.removeWhere((d) => d['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đăng xuất thiết bị'), duration: Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thiết bị'),
        backgroundColor: Colors.black,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: devices.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, idx) {
          final d = devices[idx];
          return ListTile(
            leading: const Icon(Icons.devices),
            title: Text(d['name'] ?? ''),
            subtitle: Text('Lần cuối hoạt động: ${d['lastSeen']}'),
            trailing: TextButton(
              onPressed: () => _confirmSignOut(d['id']!, d['name']!),
              child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            ),
          );
        },
      ),
    );
  }

  void _confirmSignOut(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc muốn đăng xuất thiết bị: $name ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(onPressed: () {
            Navigator.pop(ctx);
            _signOutDevice(id);
          }, child: const Text('Đăng xuất', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
