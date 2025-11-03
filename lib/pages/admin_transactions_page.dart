import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/transaction.dart' as AppTransaction;

class AdminTransactionsPage extends StatefulWidget {
  const AdminTransactionsPage({super.key});

  @override
  State<AdminTransactionsPage> createState() => _AdminTransactionsPageState();
}

class _AdminTransactionsPageState extends State<AdminTransactionsPage> {
  final AdminService _adminService = AdminService();
  String _searchQuery = '';
  String _selectedType = 'all'; // all, buy, sell

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý giao dịch'),
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateTransactionDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm theo coin hoặc user...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Loại: '),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedType,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                          DropdownMenuItem(value: 'buy', child: Text('Mua')),
                          DropdownMenuItem(value: 'sell', child: Text('Bán')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Transactions list
          Expanded(
            child: StreamBuilder<List<AppTransaction.Transaction>>(
              stream: _adminService.getAllTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Lỗi: ${snapshot.error}'),
                  );
                }

                final transactions = snapshot.data ?? [];
                final filteredTransactions = transactions.where((transaction) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      transaction.coinSymbol.toLowerCase().contains(_searchQuery) ||
                      transaction.coinId.toLowerCase().contains(_searchQuery) ||
                      transaction.userId.toLowerCase().contains(_searchQuery);
                  
                  final matchesType = _selectedType == 'all' || transaction.type == _selectedType;
                  
                  return matchesSearch && matchesType;
                }).toList();

                if (filteredTransactions.isEmpty) {
                  return const Center(
                    child: Text('Không có giao dịch nào'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = filteredTransactions[index];
                    return _buildTransactionCard(transaction);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(AppTransaction.Transaction transaction) {
    final isBuy = transaction.type == 'buy';
    final color = isBuy ? Colors.green : Colors.red;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(
            isBuy ? Icons.arrow_downward : Icons.arrow_upward,
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Text(
              transaction.coinSymbol.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isBuy ? 'MUA' : 'BÁN',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Số lượng: ${transaction.amount}'),
            Text('Giá: \$${transaction.price.toStringAsFixed(2)}'),
            Text('Tổng: \$${transaction.total.toStringAsFixed(2)}'),
            Text('Thời gian: ${_formatDate(transaction.timestamp)}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('ID', transaction.id),
                _buildInfoRow('User ID', transaction.userId),
                _buildInfoRow('Coin ID', transaction.coinId),
                if (transaction.stopLoss != null)
                  _buildInfoRow('Stop Loss', '\$${transaction.stopLoss!.toStringAsFixed(2)}'),
                if (transaction.takeProfit != null)
                  _buildInfoRow('Take Profit', '\$${transaction.takeProfit!.toStringAsFixed(2)}'),
                if (transaction.notes != null)
                  _buildInfoRow('Ghi chú', transaction.notes!),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showEditTransactionDialog(transaction),
                      icon: const Icon(Icons.edit),
                      label: const Text('Sửa'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _confirmDeleteTransaction(transaction),
                      icon: const Icon(Icons.delete),
                      label: const Text('Xóa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showCreateTransactionDialog() {
    final userIdController = TextEditingController();
    final coinIdController = TextEditingController();
    final coinSymbolController = TextEditingController();
    final amountController = TextEditingController();
    final priceController = TextEditingController();
    final notesController = TextEditingController();
    String selectedType = 'buy';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo giao dịch mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userIdController,
                decoration: const InputDecoration(
                  labelText: 'User ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Loại giao dịch',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'buy', child: Text('Mua')),
                  DropdownMenuItem(value: 'sell', child: Text('Bán')),
                ],
                onChanged: (value) {
                  selectedType = value!;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: coinIdController,
                decoration: const InputDecoration(
                  labelText: 'Coin ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: coinSymbolController,
                decoration: const InputDecoration(
                  labelText: 'Coin Symbol',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số lượng',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Giá',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_validateTransactionForm(
                userIdController.text,
                coinIdController.text,
                coinSymbolController.text,
                amountController.text,
                priceController.text,
              )) {
                try {
                  final amount = double.parse(amountController.text);
                  final price = double.parse(priceController.text);
                  final total = amount * price;
                  
                  final transaction = AppTransaction.Transaction(
                    id: '',
                    userId: userIdController.text,
                    coinId: coinIdController.text,
                    coinSymbol: coinSymbolController.text,
                    type: selectedType,
                    amount: amount,
                    price: price,
                    total: total,
                    timestamp: DateTime.now(),
                    notes: notesController.text.isEmpty ? null : notesController.text,
                  );
                  
                  await _adminService.createTransaction(transaction);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã tạo giao dịch')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void _showEditTransactionDialog(AppTransaction.Transaction transaction) {
    final amountController = TextEditingController(text: transaction.amount.toString());
    final priceController = TextEditingController(text: transaction.price.toString());
    final notesController = TextEditingController(text: transaction.notes ?? '');
    String selectedType = transaction.type;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa giao dịch'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${transaction.id}'),
              Text('Coin: ${transaction.coinSymbol}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Loại giao dịch',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'buy', child: Text('Mua')),
                  DropdownMenuItem(value: 'sell', child: Text('Bán')),
                ],
                onChanged: (value) {
                  selectedType = value!;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số lượng',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Giá',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final amount = double.parse(amountController.text);
                final price = double.parse(priceController.text);
                final total = amount * price;
                
                final updatedTransaction = AppTransaction.Transaction(
                  id: transaction.id,
                  userId: transaction.userId,
                  coinId: transaction.coinId,
                  coinSymbol: transaction.coinSymbol,
                  type: selectedType,
                  amount: amount,
                  price: price,
                  total: total,
                  timestamp: transaction.timestamp,
                  notes: notesController.text.isEmpty ? null : notesController.text,
                );
                
                await _adminService.updateTransaction(transaction.id, updatedTransaction);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã cập nhật giao dịch')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTransaction(AppTransaction.Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa giao dịch ${transaction.coinSymbol} này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _adminService.deleteTransaction(transaction.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa giao dịch')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  bool _validateTransactionForm(
    String userId,
    String coinId,
    String coinSymbol,
    String amount,
    String price,
  ) {
    if (userId.isEmpty || coinId.isEmpty || coinSymbol.isEmpty || amount.isEmpty || price.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return false;
    }

    try {
      double.parse(amount);
      double.parse(price);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số lượng và giá phải là số hợp lệ')),
      );
      return false;
    }

    return true;
  }
}