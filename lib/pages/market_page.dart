import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/coin.dart';
import '../models/user_model.dart';
import '../services/coingecko_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'coin_detail_page.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  int activeTab = 0; // 0: tất cả, 1: yêu thích, 2: top gainers, 3: top losers
  
  List<Coin> allCoins = [];
  Set<String> favoriteCoins = {};
  bool isLoading = true;
  UserModel? currentUser;
  
  final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
  final percentFormat = NumberFormat.decimalPattern();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      final coinGeckoService = Provider.of<CoinGeckoService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      // Load coins
      final coins = await coinGeckoService.getCoinMarkets(perPage: 100);
      
      // Load user favorites
      if (authService.currentUserId != null) {
        currentUser = await firestoreService.getUserData(authService.currentUserId!);
        // Get favorites from user model
        favoriteCoins = currentUser?.favoriteCoins.toSet() ?? {};
      }
      
      if (mounted) {
        setState(() {
          allCoins = coins;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  List<Coin> get filteredCoins {
    List<Coin> coins = [];
    
    // Filter by search query first
    List<Coin> searchFiltered = allCoins.where((coin) {
      return coin.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          coin.symbol.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
    
    // Then filter by tab
    switch (activeTab) {
      case 0: // Tất cả
        coins = searchFiltered;
        break;
      case 1: // Yêu thích
        coins = searchFiltered.where((coin) => favoriteCoins.contains(coin.id)).toList();
        break;
      case 2: // Top Gainers
        coins = searchFiltered.where((coin) => coin.priceChangePercentage24h > 0).toList();
        coins.sort((a, b) => b.priceChangePercentage24h.compareTo(a.priceChangePercentage24h));
        break;
      case 3: // Top Losers
        coins = searchFiltered.where((coin) => coin.priceChangePercentage24h < 0).toList();
        coins.sort((a, b) => a.priceChangePercentage24h.compareTo(b.priceChangePercentage24h));
        break;
    }
    
    return coins;
  }

  Future<void> _toggleFavorite(String coinId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      if (authService.currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để sử dụng tính năng này')),
        );
        return;
      }
      
      setState(() {
        if (favoriteCoins.contains(coinId)) {
          favoriteCoins.remove(coinId);
        } else {
          favoriteCoins.add(coinId);
        }
      });
      
      // Save to Firestore
      await firestoreService.updateFavorites(
        authService.currentUserId!,
        favoriteCoins.toList(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(favoriteCoins.contains(coinId) 
                ? 'Đã thêm vào yêu thích' 
                : 'Đã xóa khỏi yêu thích'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Text(
                      'Thị trường Crypto',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadData,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Search bar
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
                      hintText: 'Tìm kiếm coin...',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _MarketTab(
                        title: "Tất cả",
                        isActive: activeTab == 0,
                        onTap: () => setState(() => activeTab = 0),
                      ),
                      _MarketTab(
                        title: "Yêu thích",
                        isActive: activeTab == 1,
                        onTap: () => setState(() => activeTab = 1),
                      ),
                      _MarketTab(
                        title: "Top Gainers",
                        isActive: activeTab == 2,
                        onTap: () => setState(() => activeTab = 2),
                      ),
                      _MarketTab(
                        title: "Top Losers",
                        isActive: activeTab == 3,
                        onTap: () => setState(() => activeTab = 3),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Market summary
                if (!isLoading && allCoins.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MarketStat(
                          label: 'Tổng coins',
                          value: '${allCoins.length}',
                          icon: Icons.currency_bitcoin,
                        ),
                        _MarketStat(
                          label: 'Tăng giá',
                          value: '${allCoins.where((c) => c.priceChangePercentage24h > 0).length}',
                          icon: Icons.trending_up,
                          color: Colors.green,
                        ),
                        _MarketStat(
                          label: 'Giảm giá',
                          value: '${allCoins.where((c) => c.priceChangePercentage24h < 0).length}',
                          icon: Icons.trending_down,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Coins list
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredCoins.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    activeTab == 1 
                                        ? 'Chưa có coin yêu thích nào'
                                        : 'Không tìm thấy kết quả',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredCoins.length,
                              itemBuilder: (context, index) {
                                final coin = filteredCoins[index];
                                return _buildCoinItem(coin);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoinItem(Coin coin) {
    final isUp = coin.priceChangePercentage24h >= 0;
    final isFavorite = favoriteCoins.contains(coin.id);
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CoinDetailPage(coin: coin),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Coin image
            CachedNetworkImage(
              imageUrl: coin.image,
              width: 40,
              height: 40,
              placeholder: (context, url) => Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.currency_bitcoin, color: Colors.orange),
              ),
              errorWidget: (context, url, error) => Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.currency_bitcoin, color: Colors.orange),
              ),
            ),
            const SizedBox(width: 12),
            
            // Coin info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        coin.symbol,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#${coin.marketCapRank}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ],
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
            
            // Price and change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(coin.currentPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUp ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
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
            
            const SizedBox(width: 8),
            
            // Actions
Column(
              children: [
                IconButton(
                  onPressed: () => _toggleFavorite(coin.id),
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey,
                    size: 20,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Navigate to coin detail instead of trade page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CoinDetailPage(coin: coin),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.shopping_cart,
                    color: Colors.blue,
                    size: 20,
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
        padding: const EdgeInsets.only(right: 20),
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

// ----------- Widget thống kê thị trường -----------

class _MarketStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _MarketStat({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.blue, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
