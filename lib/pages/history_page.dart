import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart' as model;
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử giao dịch'),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<List<model.Transaction>>(
        stream: firestoreService.getUserTransactions(authService.currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có giao dịch nào',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final transactions = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              
              // Xác định loại giao dịch
              final isDeposit = transaction.type == 'deposit';
              final isWithdraw = transaction.type == 'withdraw';
              final isBuy = transaction.type == 'buy';

              // Màu sắc và icon theo loại giao dịch
              Color backgroundColor;
              Color iconColor;
              IconData iconData;
              String title;

              if (isDeposit) {
                backgroundColor = Colors.green[100]!;
                iconColor = Colors.green;
                iconData = Icons.add_circle;
                title = 'Nạp tiền';
              } else if (isWithdraw) {
                backgroundColor = Colors.orange[100]!;
                iconColor = Colors.orange;
                iconData = Icons.remove_circle;
                title = 'Rút tiền';
              } else if (isBuy) {
                backgroundColor = Colors.blue[100]!;
                iconColor = Colors.blue;
                iconData = Icons.arrow_downward;
                title = 'Mua ${transaction.coinSymbol}';
              } else {
                backgroundColor = Colors.red[100]!;
                iconColor = Colors.red;
                iconData = Icons.arrow_upward;
                title = 'Bán ${transaction.coinSymbol}';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: backgroundColor,
                    child: Icon(iconData, color: iconColor),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      if (isDeposit || isWithdraw) ...[
                        Text('Số tiền: ${currencyFormat.format(transaction.amount)} VNĐ'),
                        if (transaction.paymentMethod != null)
                          Text('Phương thức: ${_getPaymentMethodName(transaction.paymentMethod!)}'),
                        if (transaction.status != null)
                          Text(
                            'Trạng thái: ${_getStatusText(transaction.status!)}',
                            style: TextStyle(
                              color: _getStatusColor(transaction.status!),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ] else ...[
                        Text('Số lượng: ${transaction.amount} ${transaction.coinSymbol}'),
                        Text('Giá: ${currencyFormat.format(transaction.price)}'),
                        Text('Tổng: ${currencyFormat.format(transaction.total)}'),
                      ],
                      Text(
                        dateFormat.format(transaction.timestamp),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: Icon(iconData, color: iconColor),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'momo':
        return 'Ví MoMo';
      case 'visa':
        return 'Thẻ Visa/MasterCard';
      case 'bank_transfer':
        return 'Chuyển khoản ngân hàng';
      default:
        return 'Phương thức khác';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Thành công';
      case 'pending':
        return 'Đang xử lý';
      case 'failed':
        return 'Thất bại';
      default:
        return 'Không xác định';
    }
  }
}