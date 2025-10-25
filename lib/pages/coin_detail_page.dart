import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/coin.dart';
import '../models/user_model.dart';
import '../services/coingecko_service.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class CoinDetailPage extends StatefulWidget {
  final Coin coin;

  const CoinDetailPage({super.key, required this.coin});

  @override
  State<CoinDetailPage> createState() => _CoinDetailPageState();
}

class _CoinDetailPageState extends State<CoinDetailPage> {
  List<FlSpot> chartData = [];
  bool isLoadingChart = true;
  int selectedDays = 1;
  double chartMinX = 0;
  double chartMaxX = 0;
  
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _stopLossController = TextEditingController();
  final TextEditingController _takeProfitController = TextEditingController();
  bool _enableStopLoss = false;
  bool _enableTakeProfit = false;
  
  final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _stopLossController.dispose();
    _takeProfitController.dispose();
    super.dispose();
  }

  Future<void> _loadChartData() async {
    setState(() {
      isLoadingChart = true;
    });

    try {
      final coinGeckoService = Provider.of<CoinGeckoService>(context, listen: false);
      final data = await coinGeckoService.getMarketChart(
        id: widget.coin.id,
        days: selectedDays,
      );

      if (mounted) {
        final spots = <FlSpot>[];
        double minX = double.infinity;
        double maxX = double.negativeInfinity;
        
        for (var point in data) {
          final timestamp = (point[0] as num).toDouble();
          final price = (point[1] as num).toDouble();
          spots.add(FlSpot(timestamp, price));
          
          if (timestamp < minX) minX = timestamp;
          if (timestamp > maxX) maxX = timestamp;
        }

        setState(() {
          chartData = spots;
          chartMinX = minX;
          chartMaxX = maxX;
          isLoadingChart = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingChart = false;
        });
      }
    }
  }

  Future<void> _buyCoin(UserModel user) async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số lượng hợp lệ')),
      );
      return;
    }

    final total = amount * widget.coin.currentPrice;
    if (total > user.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số dư không đủ')),
      );
      return;
    }

    // Validate stop loss and take profit
    double? stopLoss;
    double? takeProfit;

    if (_enableStopLoss) {
      stopLoss = double.tryParse(_stopLossController.text);
      if (stopLoss == null || stopLoss >= widget.coin.currentPrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stop Loss phải nhỏ hơn giá hiện tại')),
        );
        return;
      }
    }

    if (_enableTakeProfit) {
      takeProfit = double.tryParse(_takeProfitController.text);
      if (takeProfit == null || takeProfit <= widget.coin.currentPrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Take Profit phải lớn hơn giá hiện tại')),
        );
        return;
      }
    }

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      await firestoreService.buyCoin(
        uid: user.uid,
        coinId: widget.coin.id,
        coinSymbol: widget.coin.symbol,
        amount: amount,
        price: widget.coin.currentPrice,
        stopLoss: stopLoss,
        takeProfit: takeProfit,
      );

      if (mounted) {
        _amountController.clear();
        _stopLossController.clear();
        _takeProfitController.clear();
        setState(() {
          _enableStopLoss = false;
          _enableTakeProfit = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mua thành công!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sellCoin(UserModel user) async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số lượng hợp lệ')),
      );
      return;
    }

    final holding = user.holdings[widget.coin.id] ?? 0;
    if (amount > holding) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số lượng coin không đủ')),
      );
      return;
    }

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      await firestoreService.sellCoin(
        uid: user.uid,
        coinId: widget.coin.id,
        coinSymbol: widget.coin.symbol,
        amount: amount,
        price: widget.coin.currentPrice,
      );

      if (mounted) {
        _amountController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bán thành công!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);
    final isUp = widget.coin.priceChangePercentage24h >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.coin.name),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<UserModel?>(
        stream: firestoreService.streamUserData(authService.currentUserId!),
        builder: (context, snapshot) {
          final user = snapshot.data;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coin header
                  Row(
                    children: [
                      CachedNetworkImage(
                        imageUrl: widget.coin.image,
                        width: 48,
                        height: 48,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const Icon(Icons.currency_bitcoin, size: 48),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.coin.symbol,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.coin.name,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Price info
                  Text(
                    currencyFormat.format(widget.coin.currentPrice),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isUp ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${isUp ? '+' : ''}${widget.coin.priceChangePercentage24h.toStringAsFixed(2)}% (24h)',
                      style: TextStyle(
                        color: isUp ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Chart
                  const Text(
                    'Biểu đồ giá',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  
                  // Time selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTimeButton('1D', 1),
                      _buildTimeButton('7D', 7),
                      _buildTimeButton('30D', 30),
                      _buildTimeButton('1Y', 365),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (isLoadingChart)
                    const Center(child: CircularProgressIndicator())
                  else if (chartData.isEmpty)
                    const Center(child: Text('Không có dữ liệu'))
                  else
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: chartData,
                              isCurved: true,
                              color: isUp ? Colors.green : Colors.red,
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: (isUp ? Colors.green : Colors.red).withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 30),

                  // Stats
                  _buildStatRow('Market Cap', currencyFormat.format(widget.coin.marketCap)),
                  _buildStatRow('24h Volume', currencyFormat.format(widget.coin.totalVolume)),
                  _buildStatRow('24h High', currencyFormat.format(widget.coin.high24h)),
                  _buildStatRow('24h Low', currencyFormat.format(widget.coin.low24h)),
                  
                  if (user != null) ...[
                    const SizedBox(height: 30),
                    _buildStatRow('Số dư của bạn', currencyFormat.format(user.balance)),
                    _buildStatRow(
                      'Đang sở hữu',
                      '${user.holdings[widget.coin.id] ?? 0} ${widget.coin.symbol}',
                    ),
                  ],

                  const SizedBox(height: 30),

                  // Buy/Sell form
                  if (user != null) ...[
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Số lượng',
                        border: const OutlineInputBorder(),
                        suffixText: widget.coin.symbol,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Stop Loss & Take Profit Section
                    ExpansionTile(
                      title: const Text('⚙️ Cài đặt nâng cao', style: TextStyle(fontWeight: FontWeight.bold)),
                      children: [
                        // Stop Loss
                        CheckboxListTile(
                          title: const Text('Kích hoạt Stop Loss'),
                          subtitle: const Text('Tự động bán khi giá giảm xuống'),
                          value: _enableStopLoss,
                          onChanged: (value) {
                            setState(() {
                              _enableStopLoss = value ?? false;
                            });
                          },
                        ),
                        if (_enableStopLoss)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _stopLossController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Giá Stop Loss',
                                border: const OutlineInputBorder(),
                                prefixText: '\$',
                                hintText: 'Nhỏ hơn ${widget.coin.currentPrice.toStringAsFixed(2)}',
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        
                        // Take Profit
                        CheckboxListTile(
                          title: const Text('Kích hoạt Take Profit'),
                          subtitle: const Text('Tự động bán khi giá tăng lên'),
                          value: _enableTakeProfit,
                          onChanged: (value) {
                            setState(() {
                              _enableTakeProfit = value ?? false;
                            });
                          },
                        ),
                        if (_enableTakeProfit)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _takeProfitController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Giá Take Profit',
                                border: const OutlineInputBorder(),
                                prefixText: '\$',
                                hintText: 'Lớn hơn ${widget.coin.currentPrice.toStringAsFixed(2)}',
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _buyCoin(user),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('MUA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _sellCoin(user),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('BÁN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeButton(String label, int days) {
    final isSelected = selectedDays == days;
    return InkWell(
      onTap: () {
        setState(() {
          selectedDays = days;
        });
        _loadChartData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
