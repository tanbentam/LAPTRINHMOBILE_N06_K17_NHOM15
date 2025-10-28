import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
  
  String _selectedMethod = 'bank_transfer';
  bool _isProcessing = false;
  
  final Map<String, Map<String, dynamic>> _withdrawMethods = {
    'bank_transfer': {
      'name': 'Bank Transfer',
      'icon': Icons.account_balance,
      'color': Colors.blue,
      'minAmount': 50.0,
      'maxAmount': 100000.0,
      'fee': 0.0, // Free
      'processingTime': '1-3 ngày làm việc',
    },
    'momo': {
      'name': 'MoMo Wallet',
      'icon': Icons.account_balance_wallet,
      'color': Colors.pink,
      'minAmount': 20.0,
      'maxAmount': 50000.0,
      'fee': 1.0, // 1% fee
      'processingTime': 'Tức thì - 30 phút',
    },
    'visa': {
      'name': 'Visa/MasterCard',
      'icon': Icons.credit_card,
      'color': Colors.purple,
      'minAmount': 50.0,
      'maxAmount': 50000.0,
      'fee': 2.0, // 2% fee
      'processingTime': '1-5 ngày làm việc',
    },
  };

  @override
  void dispose() {
    _amountController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Rút tiền',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
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
          final availableBalance = user.balance;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance Card
                  _buildBalanceCard(availableBalance),
                  
                  const SizedBox(height: 24),

                  // Withdraw Method Selection
                  const Text(
                    'Chọn phương thức rút tiền',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  ..._withdrawMethods.entries.map((entry) {
                    return _buildMethodCard(
                      entry.key,
                      entry.value,
                    );
                  }),

                  const SizedBox(height: 24),

                  // Account Information
                  _buildAccountInfoSection(),

                  const SizedBox(height: 24),

                  // Amount Input
                  const Text(
                    'Số tiền rút',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Nhập số tiền',
                      prefixIcon: const Icon(Icons.attach_money),
                      suffixText: 'USD',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập số tiền';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null) {
                        return 'Số tiền không hợp lệ';
                      }
                      final method = _withdrawMethods[_selectedMethod]!;
                      if (amount < method['minAmount']) {
                        return 'Số tiền tối thiểu: ${currencyFormat.format(method['minAmount'])}';
                      }
                      if (amount > method['maxAmount']) {
                        return 'Số tiền tối đa: ${currencyFormat.format(method['maxAmount'])}';
                      }
                      if (amount > availableBalance) {
                        return 'Số dư không đủ';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Fee & Total Info
                  _buildFeeInfo(),

                  const SizedBox(height: 24),

                  // Important Notice
                  _buildNoticeCard(),

                  const SizedBox(height: 24),

                  // Withdraw Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () => _handleWithdraw(firestoreService, authService.currentUserId!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Xác nhận rút tiền',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Số dư khả dụng',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(String key, Map<String, dynamic> method) {
    final isSelected = _selectedMethod == key;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMethod = key;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? method['color'] : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: method['color'].withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: method['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  method['icon'],
                  color: method['color'],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phí: ${method['fee']}% • ${method['processingTime']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${currencyFormat.format(method['minAmount'])} - ${currencyFormat.format(method['maxAmount'])}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: method['color'],
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountInfoSection() {
    final method = _withdrawMethods[_selectedMethod]!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin tài khoản nhận',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _accountNumberController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: _selectedMethod == 'bank_transfer' 
                ? 'Số tài khoản ngân hàng'
                : _selectedMethod == 'momo'
                    ? 'Số điện thoại MoMo'
                    : 'Số thẻ',
            prefixIcon: Icon(method['icon']),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập thông tin tài khoản';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _accountNameController,
          decoration: InputDecoration(
            labelText: 'Tên chủ tài khoản',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập tên chủ tài khoản';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildFeeInfo() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final method = _withdrawMethods[_selectedMethod]!;
    final fee = amount * (method['fee'] / 100);
    final totalReceive = amount - fee;

    if (amount <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          _buildInfoRow('Số tiền rút', currencyFormat.format(amount)),
          const Divider(height: 16),
          _buildInfoRow('Phí giao dịch (${method['fee']}%)', currencyFormat.format(fee)),
          const Divider(height: 16),
          _buildInfoRow(
            'Số tiền nhận được',
            currencyFormat.format(totalReceive),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? Colors.orange : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Lưu ý quan trọng',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Kiểm tra kỹ thông tin tài khoản trước khi xác nhận\n'
            '• Thời gian xử lý: ${_withdrawMethods[_selectedMethod]!['processingTime']}\n'
            '• Không thể hoàn tác sau khi xác nhận\n'
            '• Liên hệ hỗ trợ nếu có vấn đề phát sinh',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleWithdraw(FirestoreService service, String userId) async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final method = _withdrawMethods[_selectedMethod]!;
    final accountNumber = _accountNumberController.text;
    final accountName = _accountNameController.text;

    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Xác nhận rút tiền'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phương thức: ${method['name']}'),
            Text('Tài khoản: $accountNumber'),
            Text('Chủ tài khoản: $accountName'),
            const SizedBox(height: 8),
            Text(
              'Số tiền rút: ${currencyFormat.format(amount)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Phí: ${currencyFormat.format(amount * method['fee'] / 100)}',
              style: const TextStyle(color: Colors.red),
            ),
            Text(
              'Nhận được: ${currencyFormat.format(amount - amount * method['fee'] / 100)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulate processing delay
      await Future.delayed(const Duration(seconds: 2));

      await service.withdrawMoney(
        uid: userId,
        amount: amount,
        paymentMethod: _selectedMethod,
        accountNumber: accountNumber,
        accountName: accountName,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return to previous page
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Yêu cầu rút tiền thành công!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(amount),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Thời gian xử lý: ${method['processingTime']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
