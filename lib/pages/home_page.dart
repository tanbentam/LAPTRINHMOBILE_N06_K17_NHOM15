import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coin.dart';
import '../models/user_model.dart';
import '../services/coingecko_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'coin_detail_page.dart';
import 'assets_page.dart';
import 'notification_center_page.dart';
import 'deposit_page.dart';
import 'withdraw_page.dart';
import '../settings/settings_page.dart';
import 'wallet_page.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String selectedFilter = 'Trending';
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
    // Lọc theo search query
    List<Coin> searchFiltered = searchQuery.isEmpty
        ? allCoins
        : allCoins.where((coin) {
            return coin.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                coin.symbol.toLowerCase().contains(searchQuery.toLowerCase());
          }).toList();

    // Lọc theo filter (Trending, Top Gainers, Top Losers)
    switch (selectedFilter) {
      case 'Top Gainers':
        // Chỉ lấy coins tăng giá, sắp xếp từ cao đến thấp
        searchFiltered = searchFiltered
            .where((coin) => coin.priceChangePercentage24h > 0)
            .toList()
          ..sort((a, b) => b.priceChangePercentage24h.compareTo(a.priceChangePercentage24h));
        break;
      
      case 'Top Losers':
        // Chỉ lấy coins giảm giá, sắp xếp từ thấp đến cao
        searchFiltered = searchFiltered
            .where((coin) => coin.priceChangePercentage24h < 0)
            .toList()
          ..sort((a, b) => a.priceChangePercentage24h.compareTo(b.priceChangePercentage24h));
        break;
      
      case 'Trending':
      default:
        // Giữ nguyên thứ tự market cap (top coins)
        break;
    }

    return searchFiltered;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF1A1A1A),
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
          color: Colors.amber,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Bar
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white),
                            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                          ),
                          const Spacer(),
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const NotificationCenterPage(),
                                    ),
                                  );
                                },
                              ),
                              // Notification badge
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(authService.currentUserId)
                                    .collection('notifications')
                                    .where('isRead', isEqualTo: false)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  final unreadCount = snapshot.data!.docs.length;
                                  return Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      child: Text(
                                        unreadCount > 99 ? '99+' : '$unreadCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      // Welcome Text
                      const Text(
                        'Thị trường Crypto',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Theo dõi và quản lý danh mục đầu tư của bạn',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // 💰 Quick Actions - Nạp, Rút, Mua, Bán
                      _buildQuickActionsSection(context, authService),
                      
                      const SizedBox(height: 20),
                      
                      // Quick Access Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickAccessCard(
                              icon: Icons.account_balance_wallet,
                              title: 'Tài sản',
                              subtitle: 'Xem ví tiền',
                              color: Colors.amber,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AssetsPage()),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickAccessCard(
                              icon: Icons.settings,
                              title: 'Cài đặt',
                              subtitle: 'Tùy chỉnh',
                              color: Colors.grey[700]!,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Market Section
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        
                        // Trending Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedFilter == 'Trending'
                                  ? 'Đang thịnh hành'
                                  : selectedFilter == 'Top Gainers'
                                      ? 'Top tăng giá 🚀'
                                      : 'Top giảm giá 📉',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: DropdownButton<String>(
                                value: selectedFilter,
                                underline: const SizedBox(),
                                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                                style: const TextStyle(color: Colors.black, fontSize: 13),
                                items: const [
                                  DropdownMenuItem(value: 'Trending', child: Text('Trending')),
                                  DropdownMenuItem(value: 'Top Gainers', child: Text('Top Gainers')),
                                  DropdownMenuItem(value: 'Top Losers', child: Text('Top Losers')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedFilter = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        
                        // Search bar
                        Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.black),
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Tìm kiếm coin...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                              suffixIcon: searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.grey),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        // Status indicator
                        if (!isLoading)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 15),
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
                                      ? Icons.check_circle 
                                      : Icons.info_outline,
                                  size: 16,
                                  color: allCoins.isNotEmpty 
                                      ? Colors.green 
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    allCoins.isNotEmpty 
                                        ? 'Dữ liệu thời gian thực từ CoinGecko (${allCoins.length} coins)'
                                        : 'Đang tải dữ liệu...',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: allCoins.isNotEmpty 
                                          ? Colors.green[700] 
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Coins list
                        if (isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40.0),
                              child: CircularProgressIndicator(
                                color: Colors.amber,
                              ),
                            ),
                          )
                        else if (filteredCoins.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Column(
                                children: [
                                  Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Không tìm thấy kết quả',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredCoins.length,
                            itemBuilder: (context, index) {
                              final coin = filteredCoins[index];
                              return _buildCoinRow(coin);
                            },
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 💰 Quick Actions Section - Nạp, Rút, Mua, Bán
  Widget _buildQuickActionsSection(BuildContext context, AuthService authService) {
    final firestoreService = Provider.of<FirestoreService>(context);
    
    return StreamBuilder<UserModel?>(
      stream: firestoreService.streamUserData(authService.currentUserId!),
      builder: (context, snapshot) {
        final balance = snapshot.data?.balance ?? 0.0;
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xF9EBAD0A), // Amber dark
                Color(0xFFFFA000), // Amber deeper
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.1),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const WalletPage()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.account_balance_wallet, 
                                    color: Colors.white, 
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ví của tôi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Số dư khả dụng',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currencyFormat.format(balance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WalletPage()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 32,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            
            // Action Buttons - Chỉ Nạp và Rút
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      context: context,
                      icon: Icons.add_circle_outline,
                      label: 'Nạp tiền',
                      color: Colors.white,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DepositPage()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionButton(
                      context: context,
                      icon: Icons.remove_circle_outline,
                      label: 'Rút tiền',
                      color: Colors.white,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const WithdrawPage()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
              ),
            ),
          ],
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Coin logo
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(6),
              child: CachedNetworkImage(
                imageUrl: coin.image,
                placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                errorWidget: (context, url, error) => const Icon(Icons.currency_bitcoin, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            // Coin name & symbol
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.symbol.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    coin.name,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Mini chart placeholder (could add real chart later)
            Container(
              width: 60,
              height: 30,
              child: Icon(
                isUp ? Icons.trending_up : Icons.trending_down,
                color: isUp ? Colors.green : Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            // Price & change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(coin.currentPrice),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    color: isUp ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(6),
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
