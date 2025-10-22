import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // 🟢 Thêm key
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  final List<Map<String, dynamic>> coins = [
    {'name': 'BNB', 'price': '1,010.60', 'change': '+0.48%', 'isUp': true},
    {'name': 'BTC', 'price': '112,895.37', 'change': '+0.75%', 'isUp': true},
    {'name': 'ETH', 'price': '4,158.87', 'change': '+1.34%', 'isUp': true},
    {'name': 'SOL', 'price': '206.37', 'change': '-0.33%', 'isUp': false},
    {'name': 'FF', 'price': '0.20416', 'change': '+308.32%', 'isUp': true},
  ];

  @override
  Widget build(BuildContext context) {
    // Lọc danh sách theo từ khóa
    final filteredCoins = coins
        .where((coin) =>
        coin['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      key: _scaffoldKey, // 🟢 gắn key cho Scaffold
      backgroundColor: Colors.white,

      // Drawer menu
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: AssetImage('assets/profile.png'),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Xin chào, Nhà đầu tư!',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.black),
              title: const Text('Tài khoản'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mở trang tài khoản')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.black),
              title: const Text('Ví tiền'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mở ví tiền')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.black),
              title: const Text('Thị trường'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Xem thị trường')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.black),
              title: const Text('Cài đặt'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mở cài đặt')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đăng xuất thành công')),
                );
              },
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thanh tìm kiếm + icon
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black),
                      onPressed: () {
                        _scaffoldKey.currentState?.openDrawer(); // 🟢 Mở Drawer qua key
                      },
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.black),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Sàn giao dịch / Ví...',
                            hintStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.headphones, color: Colors.black),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Trò chuyện với hỗ trợ')),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: Colors.black),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Xem thông báo')),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  'Khám phá lĩnh vực tài sản số!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 20),

                // Danh mục coin
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          Text(
                            'Phổ biến',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          Text(
                            'Tiền mã hóa',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (filteredCoins.isEmpty)
                        const Text(
                          'Không tìm thấy kết quả.',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        for (var coin in filteredCoins)
                          _buildCoinRow(
                            coin['name'],
                            coin['price'],
                            coin['change'],
                            coin['isUp'],
                          ),

                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          'Xem thêm',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Khám phá',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundImage: AssetImage('assets/profile.png'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Crypto Raju X • 19 phút trước',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Mở khóa Lợi suất Tổ chức với BounceBit CeDeFi: '
                                  'Hệ sinh thái, Cơ sở hạ tầng & Chiến lược',
                              style: TextStyle(color: Colors.black, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget coin row
  Widget _buildCoinRow(String name, String price, String change, bool isUp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(name,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(price,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: isUp ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              change,
              style: TextStyle(
                color: isUp ? Colors.green[700] : Colors.red[700],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
