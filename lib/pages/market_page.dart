import 'package:flutter/material.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  int activeTab = 0; // 0: yêu thích, 1: thị trường, 2: alpha, 3: phát triển, 4: squads

  // Dữ liệu coin theo từng tab
  final Map<int, List<Map<String, dynamic>>> tabCoins = {
    0: [
      {'name': 'BTC', 'pair': 'USDT', 'change': '+0.76%', 'isUp': true},
      {'name': 'ETH', 'pair': 'USDT', 'change': '+1.36%', 'isUp': true},
      {'name': 'BNB', 'pair': 'USDT', 'change': '+0.49%', 'isUp': true},
    ],
    1: [
      {'name': 'SOL', 'pair': 'USDT', 'change': '-0.31%', 'isUp': false},
      {'name': 'DOGE', 'pair': 'USDT', 'change': '-0.37%', 'isUp': false},
      {'name': 'AVAX', 'pair': 'USDT', 'change': '+2.14%', 'isUp': true},
    ],
    2: [
      {'name': 'FF', 'pair': 'USDT', 'change': '+308.16%', 'isUp': true},
      {'name': 'PUMP', 'pair': 'USDT', 'change': '-3.56%', 'isUp': false},
    ],
    3: [
      {'name': 'AVNT', 'pair': 'USDT', 'change': '-11.31%', 'isUp': false},
      {'name': 'SOL', 'pair': 'USDT', 'change': '+4.02%', 'isUp': true},
    ],
    4: [
      {'name': 'SHIB', 'pair': 'USDT', 'change': '+12.56%', 'isUp': true},
      {'name': 'PEPE', 'pair': 'USDT', 'change': '-2.21%', 'isUp': false},
    ],
  };

  @override
  Widget build(BuildContext context) {
    // Lọc danh sách coin theo từ khóa và tab đang chọn
    final currentCoins = tabCoins[activeTab] ?? [];
    final filteredCoins = currentCoins
        .where((coin) =>
    coin['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
        coin['pair'].toString().toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ô tìm kiếm
              Container(
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
                    hintText: 'Tìm kiếm Coin / Cặp giao dịch / Phái sinh',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Tabs (có thể nhấn)
              Row(
                children: [
                  _MarketTab(
                    title: "Danh sách yêu thích",
                    isActive: activeTab == 0,
                    onTap: () => setState(() => activeTab = 0),
                  ),
                  _MarketTab(
                    title: "Thị trường",
                    isActive: activeTab == 1,
                    onTap: () => setState(() => activeTab = 1),
                  ),
                  _MarketTab(
                    title: "Alpha",
                    isActive: activeTab == 2,
                    onTap: () => setState(() => activeTab = 2),
                  ),
                  _MarketTab(
                    title: "Phát triển",
                    isActive: activeTab == 3,
                    onTap: () => setState(() => activeTab = 3),
                  ),
                  _MarketTab(
                    title: "Squads",
                    isActive: activeTab == 4,
                    onTap: () => setState(() => activeTab = 4),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Danh sách coin
              Expanded(
                child: filteredCoins.isEmpty
                    ? const Center(
                  child: Text(
                    'Không tìm thấy kết quả.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.9,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    for (var coin in filteredCoins)
                      _CoinCard(
                        coin['name'],
                        coin['pair'],
                        coin['change'],
                        coin['isUp'],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Nút thêm vào yêu thích
              Container(
                width: double.infinity,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD400),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'Thêm vào yêu thích',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Center(
                child: Text(
                  'Thêm các cặp khác',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------- Widget Tab có thể nhấn -----------

class _MarketTab extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;
  const _MarketTab({
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.black : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2,
                width: 20,
                color: const Color(0xFFFFD400),
              ),
          ],
        ),
      ),
    );
  }
}

// ----------- Widget hiển thị coin -----------

class _CoinCard extends StatelessWidget {
  final String name;
  final String pair;
  final String change;
  final bool isUp;

  const _CoinCard(this.name, this.pair, this.change, this.isUp);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "$name/$pair",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              const Icon(Icons.check_box, color: Colors.grey, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            change,
            style: TextStyle(
              color: isUp ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
