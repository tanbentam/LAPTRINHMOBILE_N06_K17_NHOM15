import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/coin.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class TradePage extends StatefulWidget {
  final Coin? coin;
  
  const TradePage({super.key, this.coin});

  @override
  State<TradePage> createState() => _TradePageState();
}

class _TradePageState extends State<TradePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isBuy = true;
  
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  
  final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
  final numberFormat = NumberFormat.decimalPattern();
  
  UserModel? currentUser;
  bool isLoading = false;
  
  // Default coin nếu không có coin được truyền vào
  Coin get selectedCoin => widget.coin ?? Coin(
    id: 'bitcoin',
    symbol: 'BTC',
    name: 'Bitcoin',
    image: 'https://assets.coingecko.com/coins/images/1/large/bitcoin.png',
    currentPrice: 67000.0,
    marketCap: 1300000000000.0,
    marketCapRank: 1,
    priceChangePercentage24h: 2.5,
    totalVolume: 25000000000.0,
    high24h: 68500.0,
    low24h: 65200.0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _priceController.text = selectedCoin.currentPrice.toStringAsFixed(2);
    _loadUserData();
    _setupCalculations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _priceController.dispose();
    _amountController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  void _setupCalculations() {
    _priceController.addListener(_calculateTotal);
    _amountController.addListener(_calculateTotal);
    _totalController.addListener(_calculateAmount);
  }

  void _calculateTotal() {
    final price = double.tryParse(_priceController.text) ?? 0;
    final amount = double.tryParse(_amountController.text) ?? 0;
    final total = price * amount;
    
    if (total > 0) {
      _totalController.removeListener(_calculateAmount);
      _totalController.text = total.toStringAsFixed(2);
      _totalController.addListener(_calculateAmount);
    }
  }

  void _calculateAmount() {
    final price = double.tryParse(_priceController.text) ?? 0;
    final total = double.tryParse(_totalController.text) ?? 0;
    
    if (price > 0 && total > 0) {
      final amount = total / price;
      _amountController.removeListener(_calculateTotal);
      _amountController.text = amount.toStringAsFixed(8);
      _amountController.addListener(_calculateTotal);
    }
  }

  Future<void> _loadUserData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      if (authService.currentUserId != null) {
        currentUser = await firestoreService.getUserData(authService.currentUserId!);
        setState(() {});
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _executeTrade() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để giao dịch')),
      );
      return;
    }

    final price = double.tryParse(_priceController.text);
    final amount = double.tryParse(_amountController.text);
    
    if (price == null || amount == null || price <= 0 || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập giá và số lượng hợp lệ')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

      if (isBuy) {
        await firestoreService.buyCoin(
          uid: authService.currentUserId!,
          coinId: selectedCoin.id,
          coinSymbol: selectedCoin.symbol,
          amount: amount,
          price: price,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã mua ${amount.toStringAsFixed(8)} ${selectedCoin.symbol}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await firestoreService.sellCoin(
          uid: authService.currentUserId!,
          coinId: selectedCoin.id,
          coinSymbol: selectedCoin.symbol,
          amount: amount,
          price: price,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã bán ${amount.toStringAsFixed(8)} ${selectedCoin.symbol}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      // Refresh user data
      await _loadUserData();
      
      // Clear form
      _amountController.clear();
      _totalController.clear();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi giao dịch: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          '${selectedCoin.symbol}/USDT',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text(
                  currencyFormat.format(selectedCoin.currentPrice),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.more_vert, color: Colors.black),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFFFD400),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Giao dịch'),
              Tab(text: 'Lịch sử'),
              Tab(text: 'Thông tin'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTradeTab(),
          _buildHistoryTab(),
          _buildInfoTab(),
        ],
      ),
    );
  }

  Widget _buildTradeTab() {
    final userBalance = currentUser?.balance ?? 0.0;
    final userHolding = currentUser?.holdings[selectedCoin.id] ?? 0.0;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User balance info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Số dư tài khoản',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('USDT: ${currencyFormat.format(userBalance)}'),
                    Text('${selectedCoin.symbol}: ${userHolding.toStringAsFixed(8)}'),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Buy/Sell toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isBuy = true),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isBuy ? Colors.green : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Mua ${selectedCoin.symbol}',
                          style: TextStyle(
                            color: isBuy ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isBuy = false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: !isBuy ? Colors.red : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Bán ${selectedCoin.symbol}',
                          style: TextStyle(
                            color: !isBuy ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Trade form
          Expanded(
            child: Column(
              children: [
                _buildInputField(
                  'Giá (USDT)',
                  _priceController,
                  selectedCoin.currentPrice.toStringAsFixed(2),
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  'Số lượng (${selectedCoin.symbol})',
                  _amountController,
                  null,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  'Tổng (USDT)',
                  _totalController,
                  null,
                ),
                
                const SizedBox(height: 20),
                
                // Quick amount buttons
                const Text(
                  'Chọn nhanh',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildQuickButton('25%'),
                    const SizedBox(width: 8),
                    _buildQuickButton('50%'),
                    const SizedBox(width: 8),
                    _buildQuickButton('75%'),
                    const SizedBox(width: 8),
                    _buildQuickButton('100%'),
                  ],
                ),
                
                const Spacer(),
                
                // Execute button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _executeTrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBuy ? Colors.green : Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isBuy ? 'Mua ${selectedCoin.symbol}' : 'Bán ${selectedCoin.symbol}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String? placeholder) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        labelStyle: const TextStyle(color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFD400), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildQuickButton(String percentage) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => _setPercentage(percentage),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(percentage),
      ),
    );
  }

  void _setPercentage(String percentage) {
    if (currentUser == null) return;
    
    final percent = int.parse(percentage.replaceAll('%', '')) / 100.0;
    final price = double.tryParse(_priceController.text) ?? selectedCoin.currentPrice;
    
    if (isBuy) {
      // Calculate amount based on available balance
      final availableBalance = currentUser!.balance * percent;
      final amount = availableBalance / price;
      _amountController.text = amount.toStringAsFixed(8);
    } else {
      // Calculate amount based on available coins
      final availableCoins = (currentUser!.holdings[selectedCoin.id] ?? 0.0) * percent;
      _amountController.text = availableCoins.toStringAsFixed(8);
    }
  }

  Widget _buildHistoryTab() {
    return const Center(
      child: Text('Lịch sử giao dịch sẽ được hiển thị ở đây'),
    );
  }

  Widget _buildInfoTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Tên', selectedCoin.name),
          _buildInfoRow('Symbol', selectedCoin.symbol),
          _buildInfoRow('Giá hiện tại', currencyFormat.format(selectedCoin.currentPrice)),
          _buildInfoRow('Thay đổi 24h', '${selectedCoin.priceChangePercentage24h.toStringAsFixed(2)}%'),
          _buildInfoRow('Cao nhất 24h', currencyFormat.format(selectedCoin.high24h)),
          _buildInfoRow('Thấp nhất 24h', currencyFormat.format(selectedCoin.low24h)),
          _buildInfoRow('Market Cap', currencyFormat.format(selectedCoin.marketCap)),
          _buildInfoRow('Xếp hạng', '#${selectedCoin.marketCapRank}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
