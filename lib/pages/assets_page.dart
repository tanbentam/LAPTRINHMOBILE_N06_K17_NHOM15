import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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

class AssetsPage extends StatefulWidget {
  const AssetsPage({super.key});

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
  Map<String, Coin> coinCache = {};

  @override
  void initState() {
    super.initState();
    _loadCoins();
  }

  Future<void> _loadCoins() async {
    try {
      final coinGeckoService = Provider.of<CoinGeckoService>(context, listen: false);
      final coins = await coinGeckoService.getCoinMarkets(perPage: 100);
      
      if (mounted) {
        setState(() {
          for (var coin in coins) {
            coinCache[coin.id] = coin;
          }
        });
      }
    } catch (e) {
      print('Error loading coins: $e');
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
        title: const Text(
          "Tài sản của tôi",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
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
                                ],
                              ),
                            ),
                          )
                        else
                          for (var entry in stats.holdings.entries)
                            _buildEnhancedHoldingCard(entry.value),
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

  Widget _buildEnhancedHoldingCard(HoldingDetail holding) {
    final isProfit = holding.profit >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 22,
                    child: Icon(Icons.currency_bitcoin, color: Colors.orange, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        holding.coinSymbol,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${holding.amount.toStringAsFixed(4)} ${holding.coinSymbol}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
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
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isProfit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${isProfit ? '+' : ''}${holding.profitPercentage.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: isProfit ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Avg: ${currencyFormat.format(holding.averageBuyPrice)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                'P/L: ${currencyFormat.format(holding.profit)}',
                style: TextStyle(
                  color: isProfit ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
