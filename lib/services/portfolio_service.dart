import '../models/portfolio_stats.dart';
import '../models/coin.dart';
import '../models/user_model.dart';
import '../models/transaction.dart';

class PortfolioService {
  static final PortfolioService _instance = PortfolioService._internal();
  factory PortfolioService() => _instance;
  PortfolioService._internal();

  PortfolioStats calculatePortfolioStats({
    required UserModel user,
    required List<Coin> coins,
    required List<Transaction> transactions,
  }) {
    if (user.holdings.isEmpty) {
      return PortfolioStats.empty();
    }

    final Map<String, HoldingDetail> holdingDetails = {};
    double totalValue = 0;
    double totalCost = 0;

    // Tính toán cho từng holding
    for (var entry in user.holdings.entries) {
      final coinId = entry.key;
      final amount = entry.value;

      // Tìm coin hiện tại
      final coin = coins.firstWhere(
        (c) => c.id == coinId,
        orElse: () => Coin(
          id: coinId,
          symbol: 'UNKNOWN',
          name: 'Unknown',
          image: '',
          currentPrice: 0,
          priceChangePercentage24h: 0,
          marketCap: 0,
          marketCapRank: 0,
          totalVolume: 0,
          high24h: 0,
          low24h: 0,
        ),
      );

      // Tính average buy price từ transactions
      final avgBuyPrice = _calculateAverageBuyPrice(coinId, transactions);
      final currentValue = amount * coin.currentPrice;
      final cost = amount * avgBuyPrice;
      final profit = currentValue - cost;
      final profitPercentage = cost > 0 ? (profit / cost) * 100 : 0;

      holdingDetails[coinId] = HoldingDetail(
        coinId: coinId,
        coinSymbol: coin.symbol,
        amount: amount,
        currentPrice: coin.currentPrice,
        currentValue: currentValue,
        averageBuyPrice: avgBuyPrice,
        totalCost: cost,
        profit: profit,
        profitPercentage: profitPercentage.toDouble(),
      );

      totalValue += currentValue;
      totalCost += cost;
    }

    // Tính allocation (phần trăm phân bổ)
    final Map<String, double> allocation = {};
    if (totalValue > 0) {
      for (var entry in holdingDetails.entries) {
        final percentage = (entry.value.currentValue / totalValue) * 100;
        allocation[entry.value.coinSymbol] = percentage;
      }
    }

    final totalProfit = totalValue - totalCost;
    final profitPercentage = totalCost > 0 ? (totalProfit / totalCost) * 100 : 0;

    return PortfolioStats(
      totalValue: totalValue,
      totalCost: totalCost,
      totalProfit: totalProfit,
      profitPercentage: profitPercentage.toDouble(),
      holdings: holdingDetails,
      allocation: allocation,
    );
  }

  double _calculateAverageBuyPrice(String coinId, List<Transaction> transactions) {
    final buyTransactions = transactions
        .where((t) => t.coinId == coinId && t.type == 'buy')
        .toList();

    if (buyTransactions.isEmpty) return 0;

    double totalCost = 0;
    double totalAmount = 0;

    for (var tx in buyTransactions) {
      totalCost += tx.total;
      totalAmount += tx.amount;
    }

    return totalAmount > 0 ? totalCost / totalAmount : 0;
  }

  Map<String, dynamic> getTopPerformer(PortfolioStats stats) {
    if (stats.holdings.isEmpty) {
      return {'symbol': 'N/A', 'profit': 0.0, 'profitPercentage': 0.0};
    }

    var topPerformer = stats.holdings.values.reduce((a, b) => 
      a.profitPercentage > b.profitPercentage ? a : b
    );

    return {
      'symbol': topPerformer.coinSymbol,
      'profit': topPerformer.profit,
      'profitPercentage': topPerformer.profitPercentage,
    };
  }

  Map<String, dynamic> getWorstPerformer(PortfolioStats stats) {
    if (stats.holdings.isEmpty) {
      return {'symbol': 'N/A', 'profit': 0.0, 'profitPercentage': 0.0};
    }

    var worstPerformer = stats.holdings.values.reduce((a, b) => 
      a.profitPercentage < b.profitPercentage ? a : b
    );

    return {
      'symbol': worstPerformer.coinSymbol,
      'profit': worstPerformer.profit,
      'profitPercentage': worstPerformer.profitPercentage,
    };
  }
}
