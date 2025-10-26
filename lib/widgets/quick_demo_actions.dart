import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/coingecko_service.dart';

class QuickDemoActions extends StatelessWidget {
  const QuickDemoActions({super.key});

  Future<void> _setDemoPortfolio(BuildContext context, String type) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    if (authService.currentUserId == null) return;

    try {
      // Lấy danh sách coins từ API để tính toán portfolio tự động
      final coinGeckoService = Provider.of<CoinGeckoService>(context, listen: false);
      final coins = await coinGeckoService.getCoinMarkets(perPage: 50);
      
      if (coins.isEmpty) {
        throw Exception('Không thể tải dữ liệu thị trường');
      }

      Map<String, double> holdings = {};
      double balance = 0;
      
      // Tự động phân bổ portfolio dựa trên market cap và giá thực tế
      switch (type) {
        case 'beginner':
          balance = 1000;
          // Chỉ đầu tư vào top 2 coins
          for (int i = 0; i < 2 && i < coins.length; i++) {
            final coin = coins[i];
            final allocation = (balance * (i == 0 ? 0.6 : 0.3)) / coin.currentPrice;
            holdings[coin.id] = double.parse(allocation.toStringAsFixed(8));
          }
          break;
          
        case 'intermediate':
          balance = 5000;
          // Đầu tư vào top 4 coins với phân bổ 40%, 30%, 20%, 10%
          final allocations = [0.35, 0.25, 0.20, 0.15];
          for (int i = 0; i < 4 && i < coins.length; i++) {
            final coin = coins[i];
            final allocation = (balance * allocations[i]) / coin.currentPrice;
            holdings[coin.id] = double.parse(allocation.toStringAsFixed(8));
          }
          break;
          
        case 'advanced':
          balance = 50000;
          // Đầu tư vào top 7 coins với phân bổ đa dạng
          final allocations = [0.30, 0.25, 0.15, 0.12, 0.08, 0.06, 0.04];
          for (int i = 0; i < 7 && i < coins.length; i++) {
            final coin = coins[i];
            final allocation = (balance * allocations[i]) / coin.currentPrice;
            holdings[coin.id] = double.parse(allocation.toStringAsFixed(8));
          }
          break;
          
        case 'whale':
          balance = 1000000;
          // Đầu tư vào top 10 coins
          final allocations = [0.25, 0.20, 0.15, 0.12, 0.10, 0.08, 0.05, 0.03, 0.01, 0.01];
          for (int i = 0; i < 10 && i < coins.length; i++) {
            final coin = coins[i];
            final allocation = (balance * allocations[i]) / coin.currentPrice;
            holdings[coin.id] = double.parse(allocation.toStringAsFixed(8));
          }
          break;
      }

      await firestoreService.updateBalance(authService.currentUserId!, balance);
      await firestoreService.updateHoldings(authService.currentUserId!, holdings);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thiết lập portfolio $type với ${holdings.length} coins theo giá thị trường thực tế'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rocket_launch, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text(
                'Portfolio Demo Nhanh',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Portfolio được tính toán tự động từ giá thị trường thực tế:',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          
          // Portfolio presets
          Row(
            children: [
              Expanded(
                child: _DemoButton(
                  title: 'Người mới',
                  subtitle: '\$1K + 2 coins',
                  color: Colors.green,
                  onPressed: () => _setDemoPortfolio(context, 'beginner'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DemoButton(
                  title: 'Trung cấp',
                  subtitle: '\$5K + 4 coins',
                  color: Colors.orange,
                  onPressed: () => _setDemoPortfolio(context, 'intermediate'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DemoButton(
                  title: 'Cao cấp',
                  subtitle: '\$50K + 7 coins',
                  color: Colors.purple,
                  onPressed: () => _setDemoPortfolio(context, 'advanced'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DemoButton(
                  title: 'Whale 🐋',
                  subtitle: '\$1M + 8 coins',
                  color: Colors.indigo,
                  onPressed: () => _setDemoPortfolio(context, 'whale'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DemoButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;

  const _DemoButton({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}