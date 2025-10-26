import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/coin.dart';
import '../models/user_model.dart';
import '../services/coingecko_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import 'coin_detail_page.dart';
import 'market_page.dart';

class TradePage extends StatefulWidget {
  const TradePage({super.key});

  @override
  State<TradePage> createState() => _TradePageState();
}

class _TradePageState extends State<TradePage> with AutomaticKeepAliveClientMixin {
  List<Coin> trendingCoins = [];
  List<Coin> topGainers = [];
  List<Coin> topLosers = [];
  bool isLoading = true;
  Timer? _refreshTimer;
  
  final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
  final percentFormat = NumberFormat.decimalPattern();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto refresh mỗi 30 giây
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final coinGeckoService = Provider.of<CoinGeckoService>(context, listen: false);
      final coins = await coinGeckoService.getCoinMarkets(perPage: 50);
      
      if (mounted) {
        setState(() {
          // Top 10 coins by market cap
          trendingCoins = coins.take(10).toList();
          
          // Top gainers
          topGainers = coins
              .where((c) => c.priceChangePercentage24h > 0)
              .toList()
            ..sort((a, b) => b.priceChangePercentage24h.compareTo(a.priceChangePercentage24h));
          topGainers = topGainers.take(5).toList();
          
          // Top losers
          topLosers = coins
              .where((c) => c.priceChangePercentage24h < 0)
              .toList()
            ..sort((a, b) => a.priceChangePercentage24h.compareTo(b.priceChangePercentage24h));
          topLosers = topLosers.take(5).toList();
          
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: StreamBuilder<UserModel?>(
                stream: firestoreService.streamUserData(authService.currentUserId!),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  
                  return CustomScrollView(
                    slivers: [
                      // Header
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quick Trade',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Balance: ${currencyFormat.format(user?.balance ?? 0)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildMarketStats(),
                            ],
                          ),
                        ),
                      ),
                      
                      // Trending Coins
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.trending_up, color: Color(0xFF1E88E5)),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Trending',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const MarketPage(),
                                        ),
                                      );
                                    },
                                    child: const Text('See All →'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 140,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: trendingCoins.length,
                                  itemBuilder: (context, index) {
                                    return _buildTrendingCard(trendingCoins[index], user);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Top Gainers
                      SliverToBoxAdapter(
                        child: _buildSection(
                          title: 'Top Gainers 🚀',
                          coins: topGainers,
                          user: user,
                          color: Colors.green,
                        ),
                      ),
                      
                      // Top Losers
                      SliverToBoxAdapter(
                        child: _buildSection(
                          title: 'Top Losers 📉',
                          coins: topLosers,
                          user: user,
                          color: Colors.red,
                        ),
                      ),
                      
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _buildMarketStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Gainers', '${topGainers.length}', Colors.greenAccent),
          Container(width: 1, height: 40, color: Colors.white30),
          _buildStatItem('Losers', '${topLosers.length}', Colors.redAccent),
          Container(width: 1, height: 40, color: Colors.white30),
          _buildStatItem('Trending', '${trendingCoins.length}', Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingCard(Coin coin, UserModel? user) {
    final isUp = coin.priceChangePercentage24h >= 0;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CoinDetailPage(coin: coin),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isUp 
                ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                : [const Color(0xFFEF5350), const Color(0xFFE57373)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isUp ? Colors.green : Colors.red).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CachedNetworkImage(
                  imageUrl: coin.image,
                  width: 28,
                  height: 28,
                  errorWidget: (context, url, error) => 
                      const Icon(Icons.currency_bitcoin, color: Colors.white, size: 28),
                ),
                const Spacer(),
                Icon(
                  isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              coin.symbol.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              currencyFormat.format(coin.currentPrice),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${isUp ? '+' : ''}${coin.priceChangePercentage24h.toStringAsFixed(2)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Coin> coins,
    required UserModel? user,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...coins.map((coin) => _buildCoinListItem(coin, user, color)).toList(),
        ],
      ),
    );
  }

  Widget _buildCoinListItem(Coin coin, UserModel? user, Color accentColor) {
    final isUp = coin.priceChangePercentage24h >= 0;
    final holding = user?.holdings[coin.id] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CachedNetworkImage(
            imageUrl: coin.image,
            width: 40,
            height: 40,
            errorWidget: (context, url, error) => 
                const Icon(Icons.currency_bitcoin, size: 40),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coin.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      currencyFormat.format(coin.currentPrice),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isUp ? Colors.green : Colors.red).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${isUp ? '+' : ''}${coin.priceChangePercentage24h.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: isUp ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (holding > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Holding: ${holding.toStringAsFixed(4)} ${coin.symbol.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: [
              _buildActionButton(
                icon: Icons.add_shopping_cart,
                color: Colors.green,
                onTap: () => _quickBuy(coin, user),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.sell,
                color: Colors.red,
                onTap: holding > 0 ? () => _quickSell(coin, user) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onTap != null ? color.withOpacity(0.1) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: onTap != null ? color : Colors.grey,
          size: 20,
        ),
      ),
    );
  }

  Future<void> _quickBuy(Coin coin, UserModel? user) async {
    if (user == null) return;
    
    final amountController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CachedNetworkImage(
                  imageUrl: coin.image,
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Buy ${coin.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Price: ${currencyFormat.format(coin.currentPrice)}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: 'Enter amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid amount')),
                    );
                    return;
                  }
                  
                  final total = amount * coin.currentPrice;
                  if (total > user.balance) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Insufficient balance')),
                    );
                    return;
                  }
                  
                  try {
                    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                    await firestoreService.buyCoin(
                      uid: user.uid,
                      coinId: coin.id,
                      coinSymbol: coin.symbol,
                      amount: amount,
                      price: coin.currentPrice,
                    );

                    // Gửi thông báo
                    final notificationService = NotificationService();
                    await notificationService.showTradeNotification(
                      type: 'buy',
                      coinSymbol: coin.symbol.toUpperCase(),
                      amount: amount,
                      price: coin.currentPrice,
                    );
                    
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Purchase successful!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Buy Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _quickSell(Coin coin, UserModel? user) async {
    if (user == null) return;
    
    final holding = user.holdings[coin.id] ?? 0;
    final amountController = TextEditingController(text: holding.toStringAsFixed(4));
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CachedNetworkImage(
                  imageUrl: coin.image,
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Sell ${coin.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Holdings: ${holding.toStringAsFixed(4)} ${coin.symbol.toUpperCase()}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Price: ${currencyFormat.format(coin.currentPrice)}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: 'Enter amount',
                border: const OutlineInputBorder(),
                suffixText: 'Max: ${holding.toStringAsFixed(4)}',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0 || amount > holding) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid amount')),
                    );
                    return;
                  }
                  
                  try {
                    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                    await firestoreService.sellCoin(
                      uid: user.uid,
                      coinId: coin.id,
                      coinSymbol: coin.symbol,
                      amount: amount,
                      price: coin.currentPrice,
                    );

                    // Gửi thông báo
                    final notificationService = NotificationService();
                    await notificationService.showTradeNotification(
                      type: 'sell',
                      coinSymbol: coin.symbol.toUpperCase(),
                      amount: amount,
                      price: coin.currentPrice,
                    );
                    
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sold successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sell Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}