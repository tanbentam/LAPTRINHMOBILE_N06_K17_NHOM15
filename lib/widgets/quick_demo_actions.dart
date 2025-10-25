import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class QuickDemoActions extends StatelessWidget {
  const QuickDemoActions({super.key});

  Future<void> _setDemoPortfolio(BuildContext context, String type) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    if (authService.currentUserId == null) return;

    try {
      Map<String, double> holdings = {};
      double balance = 0;
      
      switch (type) {
        case 'beginner':
          balance = 1000;
          holdings = {
            'bitcoin': 0.01,
            'ethereum': 0.5,
          };
          break;
        case 'intermediate':
          balance = 5000;
          holdings = {
            'bitcoin': 0.05,
            'ethereum': 2.0,
            'binancecoin': 5.0,
            'cardano': 100.0,
          };
          break;
        case 'advanced':
          balance = 50000;
          holdings = {
            'bitcoin': 0.5,
            'ethereum': 20.0,
            'binancecoin': 50.0,
            'solana': 100.0,
            'cardano': 1000.0,
            'ripple': 5000.0,
            'dogecoin': 10000.0,
          };
          break;
        case 'whale':
          balance = 1000000;
          holdings = {
            'bitcoin': 10.0,
            'ethereum': 500.0,
            'binancecoin': 1000.0,
            'solana': 5000.0,
            'cardano': 50000.0,
            'ripple': 100000.0,
            'avalanche-2': 10000.0,
            'polkadot': 20000.0,
          };
          break;
      }

      await firestoreService.updateBalance(authService.currentUserId!, balance);
      await firestoreService.updateHoldings(authService.currentUserId!, holdings);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thiết lập portfolio $type'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
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
            'Chọn một portfolio mẫu để demo nhanh:',
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