import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class DepositPage extends StatefulWidget {
  const DepositPage({super.key});

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
  
  String _selectedMethod = 'momo';
  bool _isProcessing = false;
  
  final Map<String, Map<String, dynamic>> _paymentMethods = {
    'momo': {
      'name': 'MoMo Wallet',
      'icon': Icons.account_balance_wallet,
      'color': Colors.pink,
      'minAmount': 10.0,
      'maxAmount': 50000.0,
    },
    'visa': {
      'name': 'Visa/MasterCard',
      'icon': Icons.credit_card,
      'color': Colors.blue,
      'minAmount': 50.0,
      'maxAmount': 100000.0,
    },
    'bank_transfer': {
      'name': 'Bank Transfer',
      'icon': Icons.account_balance,
      'color': Colors.green,
      'minAmount': 100.0,
      'maxAmount': 500000.0,
    },
  };

  final List<double> _quickAmounts = [
    100,
    500,
    1000,
    2000,
    5000,
    10000,
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setQuickAmount(double amount) {
    _amountController.text = amount.toStringAsFixed(0);
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số tiền';
    }

    final amount = double.tryParse(value.replaceAll(',', ''));
    if (amount == null) {
      return 'Số tiền không hợp lệ';
    }

    final method = _paymentMethods[_selectedMethod]!;
    final minAmount = method['minAmount'] as double;
    final maxAmount = method['maxAmount'] as double;

    if (amount <= 0) {
      return 'Số tiền phải lớn hơn 0';
    }

    if (amount < minAmount) {
      return 'Số tiền tối thiểu: ${currencyFormat.format(minAmount)}';
    }

    if (amount > maxAmount) {
      return 'Số tiền tối đa: ${currencyFormat.format(maxAmount)}';
    }

    return null;
  }

  Future<void> _processDeposit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.parse(_amountController.text.replaceAll(',', ''));
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    setState(() {
      _isProcessing = true;
    });

    try {
      // Mô phỏng xử lý thanh toán (delay 2 giây)
      await Future.delayed(const Duration(seconds: 2));

      // Gọi service để xử lý nạp tiền
      await firestoreService.depositMoney(
        uid: authService.currentUserId!,
        amount: amount,
        paymentMethod: _selectedMethod,
      );

      if (mounted) {
        // Hiển thị dialog thành công
        await _showSuccessDialog(amount);
        
        // Quay lại trang trước
        Navigator.pop(context, true); // true để báo đã nạp tiền thành công
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showSuccessDialog(double amount) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nạp tiền thành công!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              currencyFormat.format(amount),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'đã được thêm vào ví của bạn',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Hoàn tất',
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
  }

  @override
  Widget build(BuildContext context) {
    final selectedMethodData = _paymentMethods[_selectedMethod]!;

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
          'Nạp tiền vào ví',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Payment method selection
            const Text(
              'Chọn phương thức thanh toán',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._paymentMethods.entries.map((entry) {
              final isSelected = _selectedMethod == entry.key;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? entry.value['color'] : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: (entry.value['color'] as Color).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: RadioListTile<String>(
                  value: entry.key,
                  groupValue: _selectedMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedMethod = value!;
                    });
                  },
                  activeColor: entry.value['color'],
                  title: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: (entry.value['color'] as Color).withOpacity(0.1),
                        child: Icon(
                          entry.value['icon'],
                          color: entry.value['color'],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Tối thiểu: ${currencyFormat.format(entry.value['minAmount'])}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // Amount input
            const Text(
              'Nhập số tiền nạp',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  prefixIcon: Icon(
                    Icons.attach_money,
                    color: selectedMethodData['color'],
                  ),
                  suffixText: 'USD',
                  suffixStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: _validateAmount,
                onChanged: (value) {
                  setState(() {}); // Rebuild để cập nhật validation
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hạn mức: ${currencyFormat.format(selectedMethodData['minAmount'])} - ${currencyFormat.format(selectedMethodData['maxAmount'])}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 24),

            // Quick amount buttons
            const Text(
              'Chọn nhanh',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickAmounts.map((amount) {
                return OutlinedButton(
                  onPressed: () => _setQuickAmount(amount),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: selectedMethodData['color'],
                    side: BorderSide(color: selectedMethodData['color']),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _formatQuickAmount(amount),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Information box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Lưu ý',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Tiền sẽ được cộng vào ví ngay lập tức\n'
                    '• Không mất phí giao dịch\n'
                    '• Giao dịch được mã hóa an toàn\n'
                    '• Hỗ trợ 24/7 nếu có vấn đề',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Deposit button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processDeposit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedMethodData['color'],
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'XÁC NHẬN NẠP TIỀN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatQuickAmount(double amount) {
    if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '\$${amount.toStringAsFixed(0)}';
  }
}
