import 'package:flutter/material.dart';

class OtpSetupPage extends StatefulWidget {
  const OtpSetupPage({super.key});

  @override
  State<OtpSetupPage> createState() => _OtpSetupPageState();
}

class _OtpSetupPageState extends State<OtpSetupPage> {
  bool _enabled = false;
  // Trong thực tế bạn sẽ tích hợp với backend (tạo secret, QR code...), ở đây làm demo
  @override
  void initState() {
    super.initState();
    // nếu muốn: load trạng thái từ SharedPreferences hoặc backend
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết lập Digital OTP'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Digital OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Bật OTP để tăng cường bảo mật. Bạn sẽ cần mã OTP từ ứng dụng xác thực khi đăng nhập.'),
            const SizedBox(height: 20),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_clock),
              title: const Text('Sử dụng ứng dụng xác thực (Google Authenticator, Authy,...)'),
            ),

            const SizedBox(height: 12),

            Center(
              child: ElevatedButton(
                onPressed: () async {
                  // Ở đây demo: chỉ bật/tắt
                  setState(() => _enabled = !_enabled);
                  // Trả về trạng thái về trang trước
                  Navigator.pop(context, _enabled);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _enabled ? Colors.red : Colors.black,
                ),
                child: Text(_enabled ? 'Tắt OTP' : 'Bật OTP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
