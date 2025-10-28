import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart' as model;
import '../models/deposit_transaction.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

// Combined transaction item for display
class _CombinedTransaction {
  final String id;
  final DateTime timestamp;
  final String type;
  final dynamic data; // Either Transaction or DepositTransaction
  
  _CombinedTransaction({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.data,
  });
}

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
        title: const Text('Transaction History'),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<List<model.Transaction>>(
        stream: firestoreService.getUserTransactions(authService.currentUserId!),
        builder: (context, cryptoSnapshot) {
          return StreamBuilder<List<DepositTransaction>>(
            stream: firestoreService.getUserDepositTransactions(authService.currentUserId!),
            builder: (context, depositSnapshot) {
              if (cryptoSnapshot.connectionState == ConnectionState.waiting ||
                  depositSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final cryptoTx = cryptoSnapshot.data ?? [];
              final depositTx = depositSnapshot.data ?? [];

              // Combine and sort all transactions by timestamp
              final List<_CombinedTransaction> allTransactions = [
                ...cryptoTx.map((tx) => _CombinedTransaction(
                  id: tx.id,
                  timestamp: tx.timestamp,
                  type: tx.type,
                  data: tx,
                )),
                ...depositTx.map((tx) => _CombinedTransaction(
                  id: tx.id,
                  timestamp: tx.timestamp,
                  type: tx.type,
                  data: tx,
                )),
              ];

              allTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

              if (allTransactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No transactions yet',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: allTransactions.length,
                itemBuilder: (context, index) {
                  final item = allTransactions[index];
                  
                  // Xác định loại giao dịch
                  final isDeposit = item.type == 'deposit';
                  final isWithdraw = item.type == 'withdraw';
                  final isBuy = item.type == 'buy';

                  // Màu sắc và icon theo loại giao dịch
                  Color backgroundColor;
                  Color iconColor;
                  IconData iconData;
                  String title;

                  if (isDeposit) {
                    backgroundColor = Colors.green[100]!;
                    iconColor = Colors.green;
                    iconData = Icons.add_circle;
                    title = 'Deposit';
                  } else if (isWithdraw) {
                    backgroundColor = Colors.orange[100]!;
                    iconColor = Colors.orange;
                    iconData = Icons.remove_circle;
                    title = 'Withdraw';
                  } else if (isBuy) {
                    final tx = item.data as model.Transaction;
                    backgroundColor = Colors.blue[100]!;
                    iconColor = Colors.blue;
                    iconData = Icons.arrow_downward;
                    title = 'Buy ${tx.coinSymbol}';
                  } else {
                    final tx = item.data as model.Transaction;
                    backgroundColor = Colors.red[100]!;
                    iconColor = Colors.red;
                    iconData = Icons.arrow_upward;
                    title = 'Sell ${tx.coinSymbol}';
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
                            () {
                              final tx = item.data as DepositTransaction;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Amount: ${currencyFormat.format(tx.amount)}'),
                                  Text('Method: ${_getPaymentMethodName(tx.paymentMethod)}'),
                                  Text(
                                    'Status: ${_getStatusText(tx.status)}',
                                    style: TextStyle(
                                      color: _getStatusColor(tx.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            }()
                          ] else ...[
                            () {
                              final tx = item.data as model.Transaction;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Quantity: ${tx.amount} ${tx.coinSymbol}'),
                                  Text('Price: ${currencyFormat.format(tx.price)}'),
                                  Text('Total: ${currencyFormat.format(tx.total)}'),
                                ],
                              );
                            }()
                          ],
                          Text(
                            dateFormat.format(item.timestamp),
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
          );
        },
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'momo':
        return 'MoMo Wallet';
      case 'visa':
        return 'Visa/MasterCard';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return 'Other Method';
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
        return 'Completed';
      case 'pending':
        return 'Processing';
      case 'failed':
        return 'Failed';
      default:
        return 'Unknown';
    }
  }
}