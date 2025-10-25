import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/coin.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/coingecko_service.dart';
import '../widgets/quick_demo_actions.dart';

class SimulateBalancePage extends StatefulWidget {
  const SimulateBalancePage({super.key});

  @override
  State<SimulateBalancePage> createState() => _SimulateBalancePageState();
}

class _SimulateBalancePageState extends State<SimulateBalancePage> {
  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _coinAmountController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
  
  List<Coin> availableCoins = [];
  String? selectedCoinId;
  bool isLoading = false;
  UserModel? currentUser;

  // Preset amounts for quick selection
  final List<double> presetAmounts = [100, 500, 1000, 5000, 10000, 50000, 100000];
  final List<double> presetCoinAmounts = [0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 100.0];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _coinAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final coinGeckoService = Provider.of<CoinGeckoService>(context, listen: false);
      
      // Load current user data
      if (authService.currentUserId != null) {
        currentUser = await firestoreService.getUserData(authService.currentUserId!);
        if (currentUser != null) {
          _balanceController.text = currentUser!.balance.toString();
        }
      }
      
      // Load available coins
      final coins = await coinGeckoService.getCoinMarkets(perPage: 20);
      
      if (mounted) {
        setState(() {
          availableCoins = coins;
          if (coins.isNotEmpty) {
            selectedCoinId = coins.first.id;
          }
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

  Future<void> _updateBalance(double newBalance) async {
    if (currentUser == null) return;
    
    setState(() => isLoading = true);
    
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      await firestoreService.updateBalance(authService.currentUserId!, newBalance);
      
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật số dư: ${currencyFormat.format(newBalance)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
      }
    }
  }

  Future<void> _addCoinHolding(String coinId, double amount) async {
    if (currentUser == null) return;
    
    setState(() => isLoading = true);
    
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final updatedHoldings = Map<String, double>.from(currentUser!.holdings);
      updatedHoldings[coinId] = (updatedHoldings[coinId] ?? 0) + amount;
      
      await firestoreService.updateHoldings(authService.currentUserId!, updatedHoldings);
      
      final coin = availableCoins.firstWhere((c) => c.id == coinId);
      
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm $amount ${coin.symbol}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi thêm coin: $e')),
        );
      }
    }
  }

  Future<void> _resetAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn reset tất cả dữ liệu về 0?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => isLoading = true);
      
      try {
        final firestoreService = Provider.of<FirestoreService>(context, listen: false);
        final authService = Provider.of<AuthService>(context, listen: false);
        
        await firestoreService.updateBalance(authService.currentUserId!, 0.0);
        await firestoreService.updateHoldings(authService.currentUserId!, {});
        
        _balanceController.text = '0';
        
        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã reset tất cả dữ liệu'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi reset: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Giả lập số dư'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.amber[700]),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Đây là chức năng giả lập cho demo.\nDữ liệu sẽ được lưu vào Firestore.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick demo portfolios
                  const QuickDemoActions(),
                  
                  const SizedBox(height: 24),
                  
                  // Current balance section
                  const Text(
                    'Số dư hiện tại',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: _balanceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Số dư USD',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.update),
                        onPressed: () {
                          final amount = double.tryParse(_balanceController.text);
                          if (amount != null) {
                            _updateBalance(amount);
                          }
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Preset amounts
                  const Text('Số tiền có sẵn:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presetAmounts.map((amount) {
                      return ElevatedButton(
                        onPressed: () {
                          _balanceController.text = amount.toString();
                          _updateBalance(amount);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD400),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(currencyFormat.format(amount)),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Add coins section
                  const Text(
                    'Thêm tài sản Crypto',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  // Coin selector
                  DropdownButtonFormField<String>(
                    value: selectedCoinId,
                    decoration: InputDecoration(
                      labelText: 'Chọn coin',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: availableCoins.map((coin) {
                      return DropdownMenuItem(
                        value: coin.id,
                        child: Row(
                          children: [
                            Icon(Icons.currency_bitcoin, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Text('${coin.symbol} - ${coin.name}'),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedCoinId = value);
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _coinAmountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Số lượng',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          final amount = double.tryParse(_coinAmountController.text);
                          if (amount != null && selectedCoinId != null) {
                            _addCoinHolding(selectedCoinId!, amount);
                            _coinAmountController.clear();
                          }
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Preset coin amounts
                  const Text('Số lượng có sẵn:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presetCoinAmounts.map((amount) {
                      return ElevatedButton(
                        onPressed: () {
                          if (selectedCoinId != null) {
                            _addCoinHolding(selectedCoinId!, amount);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[100],
                          foregroundColor: Colors.blue[800],
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(amount.toString()),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Danger zone
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'Danger Zone',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _resetAllData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Reset tất cả dữ liệu'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}