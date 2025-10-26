import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_model.dart';
import '../models/coin.dart';
import '../models/transaction.dart';
import '../models/portfolio_stats.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/coingecko_service.dart';
import '../services/portfolio_service.dart';
import 'history_page.dart';
import 'simulate_balance_page.dart';
import 'coin_detail_page.dart';

class AssetsPage extends StatefulWidget {
  const AssetsPage({super.key});

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
  Map<String, Coin> coinCache = {};
  bool isLoadingCoins = false;
  DateTime? lastUpdate;

  @override
  void initState() {
    super.initState();
    _loadCoins();
    // Auto-refresh mỗi 30 giây
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadCoins(silent: true);
        _startAutoRefresh();
      }
    });
  }

  Future<void> _loadCoins({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoadingCoins = true;
      });
    }

    try {
      final coinGeckoService = Provider.of<CoinGeckoService>(context, listen: false);
      final coins = await coinGeckoService.getCoinMarkets(perPage: 100);
      
      if (mounted) {
        setState(() {
          coinCache.clear();
          for (var coin in coins) {
            coinCache[coin.id] = coin;
          }
          isLoadingCoins = false;
          lastUpdate = DateTime.now();
        });
      }
    } catch (e) {
      print('Error loading coins: $e');
      if (mounted && !silent) {
        setState(() {
          isLoadingCoins = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể cập nhật giá: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tài sản của tôi",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            if (lastUpdate != null)
              Text(
                'Cập nhật: ${_formatTime(lastUpdate!)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
          ],
        ),
        actions: [
          if (isLoadingCoins)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blue),
              tooltip: 'Làm mới giá',
              onPressed: _loadCoins,
            ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.orange),
            tooltip: 'Giả lập số dư',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SimulateBalancePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black54),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: firestoreService.streamUserData(authService.currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Không tìm thấy dữ liệu người dùng'));
          }

          final user = snapshot.data!;

          return StreamBuilder<List<Transaction>>(
            stream: firestoreService.getUserTransactions(user.uid),
            builder: (context, txSnapshot) {
              final transactions = txSnapshot.data ?? [];
              final portfolioService = PortfolioService();
              final coins = coinCache.values.toList();
              
              final stats = portfolioService.calculatePortfolioStats(
                user: user,
                coins: coins,
                transactions: transactions,
              );
              
              final totalValue = user.balance + stats.totalValue;

              return RefreshIndicator(
                onRefresh: () async {
                  await _loadCoins();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // Total balance
                        const Text(
                          "Tổng giá trị tài sản",
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currencyFormat.format(totalValue),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              "Số dư: ${currencyFormat.format(user.balance)}",
                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                            if (stats.totalProfit != 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: stats.totalProfit >= 0 
                                      ? Colors.green.withOpacity(0.1) 
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${stats.totalProfit >= 0 ? '+' : ''}${currencyFormat.format(stats.totalProfit)} (${stats.profitPercentage.toStringAsFixed(2)}%)',
                                  style: TextStyle(
                                    color: stats.totalProfit >= 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Portfolio Analytics
                        if (stats.holdings.isNotEmpty) ...[
                          _buildPortfolioAnalytics(stats),
                          const SizedBox(height: 24),
                        ],

                        // Quick actions for demo
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.settings_applications, color: Colors.amber[700]),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Demo Controls',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const SimulateBalancePage(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.tune, size: 16),
                                      label: const Text('Điều chỉnh số dư'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFFD400),
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                  
                        const Text(
                          "Tài sản đang nắm giữ",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Holdings list
                        if (user.holdings.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: const [
                                  Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'Chưa có tài sản nào',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Hãy bắt đầu giao dịch để xây dựng danh mục đầu tư',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          for (var entry in stats.holdings.entries)
                            _buildEnhancedHoldingCard(
                              entry.value,
                              coinCache[entry.key],
                              user.uid,
                            ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPortfolioAnalytics(PortfolioStats stats) {
    final topPerformer = PortfolioService().getTopPerformer(stats);
    final worstPerformer = PortfolioService().getWorstPerformer(stats);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text(
                'Phân tích Portfolio',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Tổng đầu tư',
                  currencyFormat.format(stats.totalCost),
                  Icons.attach_money,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Giá trị hiện tại',
                  currencyFormat.format(stats.totalValue),
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Top Performer',
                  '${topPerformer['symbol']} (${topPerformer['profitPercentage'].toStringAsFixed(1)}%)',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Worst Performer',
                  '${worstPerformer['symbol']} (${worstPerformer['profitPercentage'].toStringAsFixed(1)}%)',
                  Icons.trending_down,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHoldingCard(HoldingDetail holding, Coin? coin, String userId) {
    final isProfit = holding.profit >= 0;
    final priceChange24h = coin?.priceChangePercentage24h ?? 0.0;
    final isPriceUp = priceChange24h >= 0;

    return InkWell(
      onTap: () => _showHoldingOptions(holding, coin, userId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              isProfit ? Colors.green.shade50 : Colors.red.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isProfit ? Colors.green.shade200 : Colors.red.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isProfit ? Colors.green : Colors.red).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Coin logo từ API
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 24,
                        child: coin?.image != null
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: coin!.image,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.currency_bitcoin,
                                    color: Colors.orange,
                                    size: 28,
                                  ),
                                ),
                              )
                            : const Icon(Icons.currency_bitcoin, color: Colors.orange, size: 28),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              holding.coinSymbol.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isPriceUp ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${isPriceUp ? '↗' : '↘'} ${priceChange24h.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color: isPriceUp ? Colors.green[700] : Colors.red[700],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${holding.amount.toStringAsFixed(6)} ${holding.coinSymbol.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '@ ${currencyFormat.format(holding.currentPrice)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(holding.currentValue),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isProfit ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${isProfit ? '+' : ''}${holding.profitPercentage.toStringAsFixed(2)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Giá mua TB',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currencyFormat.format(holding.averageBuyPrice),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Tổng chi phí',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currencyFormat.format(holding.totalCost),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Lãi/Lỗ',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${isProfit ? '+' : ''}${currencyFormat.format(holding.profit)}',
                        style: TextStyle(
                          color: isProfit ? Colors.green[700] : Colors.red[700],
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToTrade(coin, 'buy'),
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('Mua thêm'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToTrade(coin, 'sell'),
                    icon: const Icon(Icons.remove_circle_outline, size: 16),
                    label: const Text('Bán'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _navigateToCoinDetail(coin),
                  icon: const Icon(Icons.show_chart, size: 20),
                  color: Colors.blue,
                  tooltip: 'Chi tiết',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inSeconds < 60) return '${diff.inSeconds}s trước';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m trước';
    return DateFormat('HH:mm').format(time);
  }

  void _showHoldingOptions(HoldingDetail holding, Coin? coin, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              holding.coinSymbol.toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Số dư: ${holding.amount.toStringAsFixed(6)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.add, color: Colors.white),
              ),
              title: const Text('Mua thêm'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _navigateToTrade(coin, 'buy');
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.remove, color: Colors.white),
              ),
              title: const Text('Bán'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _navigateToTrade(coin, 'sell');
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.show_chart, color: Colors.white),
              ),
              title: const Text('Xem chi tiết'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _navigateToCoinDetail(coin);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToTrade(Coin? coin, String type) {
    if (coin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin coin')),
      );
      return;
    }

    // Navigate to trade page tab
    final mainScreenState = context.findAncestorStateOfType<State>();
    if (mainScreenState != null) {
      // Chuyển sang tab Trade (index = 2)
      Navigator.of(context).popUntil((route) => route.isFirst);
      // Sau đó navigate đến coin detail với trade mode
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CoinDetailPage(coin: coin),
        ),
      );
    }
  }

  void _navigateToCoinDetail(Coin? coin) {
    if (coin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin coin')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoinDetailPage(coin: coin),
      ),
    );
  }
}
