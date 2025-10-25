class PortfolioStats {
  final double totalValue;
  final double totalCost;
  final double totalProfit;
  final double profitPercentage;
  final Map<String, HoldingDetail> holdings;
  final Map<String, double> allocation; // Symbol -> percentage

  PortfolioStats({
    required this.totalValue,
    required this.totalCost,
    required this.totalProfit,
    required this.profitPercentage,
    required this.holdings,
    required this.allocation,
  });

  factory PortfolioStats.empty() {
    return PortfolioStats(
      totalValue: 0,
      totalCost: 0,
      totalProfit: 0,
      profitPercentage: 0,
      holdings: {},
      allocation: {},
    );
  }
}

class HoldingDetail {
  final String coinId;
  final String coinSymbol;
  final double amount;
  final double currentPrice;
  final double currentValue;
  final double averageBuyPrice;
  final double totalCost;
  final double profit;
  final double profitPercentage;

  HoldingDetail({
    required this.coinId,
    required this.coinSymbol,
    required this.amount,
    required this.currentPrice,
    required this.currentValue,
    required this.averageBuyPrice,
    required this.totalCost,
    required this.profit,
    required this.profitPercentage,
  });
}
