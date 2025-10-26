import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/coin.dart';
import '../services/coingecko_service.dart';
import '../services/auth_service.dart';
import 'coin_detail_page.dart';
import 'assets_page.dart';
import '../settings/settings_page.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  List<Coin> allCoins = [];
  bool isLoading = true;

  final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
  final percentFormat = NumberFormat.decimalPattern();

  @override
  void initState() {
    super.initState();
    _loadCoins();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCoins() async {
    setState(() {
      isLoading = true;
    });

    try {
      final coinGeckoService = Provider.of<CoinGeckoService>(context, listen: false);
      final coins = await coinGeckoService.getCoinMarkets(perPage: 50);
      
      if (mounted) {
        setState(() {
          allCoins = coins;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        String errorMessage = 'Lỗi tải dữ liệu';
        if (e.toString().contains('429')) {
          errorMessage = 'Đã gọi quá nhiều lần. Vui lòng thử lại sau 1 phút.';
        } else if (e.toString().contains('Failed host lookup')) {
          errorMessage = 'Không có kết nối internet. Vui lòng kiểm tra kết nối.';
        } else if (e.toString().contains('TimeoutException')) {
          errorMessage = 'Kết nối bị timeout. Vui lòng thử lại.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: _loadCoins,
            ),
          ),
        );
      }
    }
  }

  List<Coin> get filteredCoins {
    if (searchQuery.isEmpty) return allCoins;
    
    return allCoins.where((coin) {
      return coin.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          coin.symbol.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.amber,
                    child: Icon(Icons.person, size: 32, color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    authService.currentUser?.email ?? 'Xin chào!',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.black),
              title: const Text('Ví tiền'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AssetsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.black),
              title: const Text('Cài đặt'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await authService.signOut();
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCoins,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.black),
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
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
                              hintText: 'Tìm kiếm coin...',
                              hintStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(Icons.search, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.black),
                        onPressed: _loadCoins,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Thị trường Crypto',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Status indicator - hiển thị trạng thái kết nối API thực tế
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: allCoins.isNotEmpty 
                          ? Colors.green[50] 
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: allCoins.isNotEmpty 
                            ? Colors.green.shade200 
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          allCoins.isNotEmpty 
                              ? Icons.cloud_done 
                              : Icons.cloud_queue,
                          size: 16,
                          color: allCoins.isNotEmpty 
                              ? Colors.green 
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            allCoins.isNotEmpty 
                                ? 'Dữ liệu CoinGecko API (${allCoins.length} coins)'
                                : 'Đang tải dữ liệu từ API...',
                            style: TextStyle(
                              fontSize: 12,
                              color: allCoins.isNotEmpty 
                                  ? Colors.green[700] 
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                        if (!isLoading)
                          Text(
                            'Kéo để làm mới',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Coins list
                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (filteredCoins.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'Không tìm thấy kết quả.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredCoins.length,
                        itemBuilder: (context, index) {
                          final coin = filteredCoins[index];
                          return _buildCoinRow(coin);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoinRow(Coin coin) {
    final isUp = coin.priceChangePercentage24h >= 0;
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CoinDetailPage(coin: coin),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Coin logo
            CachedNetworkImage(
              imageUrl: coin.image,
              width: 32,
              height: 32,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.currency_bitcoin),
            ),
            const SizedBox(width: 10),
            // Coin name & symbol
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.symbol,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    coin.name,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Price & change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(coin.currentPrice),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isUp ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    '${isUp ? '+' : ''}${percentFormat.format(coin.priceChangePercentage24h)}%',
                    style: TextStyle(
                      color: isUp ? Colors.green[700] : Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
