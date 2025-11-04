import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/transaction.dart' as AppTransaction;
import 'auth_service.dart';
import 'notification_service.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  // Kiểm tra quyền admin của user hiện tại
  Future<bool> isCurrentUserAdmin() async {
    try {
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) return false;

      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      return userData['role'] == 'admin';
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Lấy thông tin user hiện tại
  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) return null;

      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return null;

      return UserModel.fromMap(userDoc.data()!);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // QUẢN LÝ NGƯỜI DÙNG

  // Lấy danh sách tất cả người dùng
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList());
  }

  // Cập nhật role của user
  Future<void> updateUserRole(String userId, String role) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': role,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating user role: $e');
      rethrow;
    }
  }

  // Kích hoạt/vô hiệu hóa tài khoản
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Gửi thông báo cho người dùng
      if (!isActive) {
        // Tài khoản bị khóa
        await _notificationService.sendNotificationToUser(
          userId,
          '🔒 Tài khoản đã bị khóa',
          'Tài khoản của bạn đã bị khóa bởi quản trị viên. Vui lòng liên hệ hỗ trợ để biết thêm chi tiết.',
          data: {
            'type': 'account_locked',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      } else {
        // Tài khoản được mở khóa
        await _notificationService.sendNotificationToUser(
          userId,
          '✅ Tài khoản đã được mở khóa',
          'Tài khoản của bạn đã được kích hoạt lại. Bạn có thể đăng nhập và sử dụng bình thường.',
          data: {
            'type': 'account_unlocked',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      print('Error toggling user status: $e');
      rethrow;
    }
  }

  // Cập nhật số dư của user
  Future<void> updateUserBalance(String userId, double balance) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'balance': balance,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating user balance: $e');
      rethrow;
    }
  }

  // Xóa user (soft delete - chuyển thành inactive)
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': false,
        'deletedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // QUẢN LÝ GIAO DỊCH

  // Lấy danh sách tất cả giao dịch
  Stream<List<AppTransaction.Transaction>> getAllTransactions() {
    return _firestore
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppTransaction.Transaction.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Lấy giao dịch theo user
  Stream<List<AppTransaction.Transaction>> getTransactionsByUser(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppTransaction.Transaction.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Tạo giao dịch mới
  Future<void> createTransaction(AppTransaction.Transaction transaction) async {
    try {
      await _firestore.collection('transactions').add(transaction.toMap());
    } catch (e) {
      print('Error creating transaction: $e');
      rethrow;
    }
  }

  // Cập nhật giao dịch
  Future<void> updateTransaction(String transactionId, AppTransaction.Transaction transaction) async {
    try {
      await _firestore
          .collection('transactions')
          .doc(transactionId)
          .update(transaction.toMap());
    } catch (e) {
      print('Error updating transaction: $e');
      rethrow;
    }
  }

  // Xóa giao dịch với tùy chọn hoàn trả/trừ tiền
  Future<void> deleteTransactionWithRefund({
    required String transactionId,
    required AppTransaction.Transaction transaction,
    required String action, // 'refund_money', 'deduct_coin', 'no_action'
    required String reason,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // 1. Xóa giao dịch
      final transactionRef = _firestore.collection('transactions').doc(transactionId);
      batch.delete(transactionRef);

      // 2. Xử lý hoàn trả/trừ tiền
      final userRef = _firestore.collection('users').doc(transaction.userId);
      final userDoc = await userRef.get();
      
      if (userDoc.exists) {
        final userData = UserModel.fromMap(userDoc.data()!);
        UserModel updatedUser = userData;
        String notificationMessage = '';

        switch (action) {
          case 'refund_money':
            // Hoàn trả tiền
            updatedUser = userData.copyWith(
              balance: userData.balance + transaction.total,
              updatedAt: DateTime.now(),
            );
            notificationMessage = 'Giao dịch ${transaction.coinSymbol.toUpperCase()} đã bị hủy. Số tiền \$${transaction.total.toStringAsFixed(2)} đã được hoàn trả vào tài khoản của bạn. Lý do: $reason';
            break;
            
          case 'deduct_coin':
            // Trừ coin khỏi holdings
            final updatedHoldings = Map<String, double>.from(userData.holdings);
            final currentAmount = updatedHoldings[transaction.coinId] ?? 0.0;
            
            if (currentAmount >= transaction.amount) {
              updatedHoldings[transaction.coinId] = currentAmount - transaction.amount;
              if (updatedHoldings[transaction.coinId] == 0) {
                updatedHoldings.remove(transaction.coinId);
              }
            } else {
              // Nếu không đủ coin để trừ, trừ tất cả và trừ thêm tiền
              updatedHoldings.remove(transaction.coinId);
              final remainingValue = (transaction.amount - currentAmount) * transaction.price;
              updatedUser = userData.copyWith(
                balance: userData.balance - remainingValue,
                holdings: updatedHoldings,
                updatedAt: DateTime.now(),
              );
              notificationMessage = 'Giao dịch ${transaction.coinSymbol.toUpperCase()} đã bị hủy. ${transaction.amount} ${transaction.coinSymbol.toUpperCase()} đã bị trừ khỏi tài khoản (bao gồm cả số dư). Lý do: $reason';
              break;
            }
            
            updatedUser = userData.copyWith(
              holdings: updatedHoldings,
              updatedAt: DateTime.now(),
            );
            notificationMessage = 'Giao dịch ${transaction.coinSymbol.toUpperCase()} đã bị hủy. ${transaction.amount} ${transaction.coinSymbol.toUpperCase()} đã bị trừ khỏi tài khoản. Lý do: $reason';
            break;
            
          case 'no_action':
            notificationMessage = 'Giao dịch ${transaction.coinSymbol.toUpperCase()} đã bị hủy. Lý do: $reason';
            break;
        }

        // 3. Cập nhật user data
        if (action != 'no_action') {
          batch.update(userRef, updatedUser.toMap());
        }

        // 4. Tạo thông báo trong Firestore
        final notificationRef = _firestore.collection('notifications').doc();
        final notification = {
          'id': notificationRef.id,
          'userId': transaction.userId,
          'title': 'Giao dịch bị hủy',
          'message': notificationMessage,
          'type': 'transaction_cancelled',
          'isRead': false,
          'timestamp': DateTime.now().toIso8601String(),
          'data': {
            'transactionId': transactionId,
            'coinSymbol': transaction.coinSymbol,
            'action': action,
            'reason': reason,
            'amount': transaction.amount,
            'total': transaction.total,
          },
        };
        batch.set(notificationRef, notification);

        // 5. Commit batch
        await batch.commit();

        // 6. Gửi push notification
        try {
          await _notificationService.sendNotificationToUser(
            transaction.userId,
            'Giao dịch bị hủy',
            notificationMessage,
            data: {
              'type': 'transaction_cancelled',
              'transactionId': transactionId,
              'action': action,
            },
          );
        } catch (e) {
          print('Error sending push notification: $e');
          // Không throw error vì thông báo đã được lưu trong Firestore
        }
      }
    } catch (e) {
      print('Error deleting transaction with refund: $e');
      rethrow;
    }
  }

  // Giữ phương thức deleteTransaction cũ cho compatibility
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).delete();
    } catch (e) {
      print('Error deleting transaction: $e');
      rethrow;
    }
  }

  // Thống kê admin
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      // Đếm tổng số users
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;
      final activeUsers = usersSnapshot.docs.where((doc) => doc.data()['isActive'] == true).length;

      // Đếm tổng số giao dịch
      final transactionsSnapshot = await _firestore.collection('transactions').get();
      final totalTransactions = transactionsSnapshot.docs.length;

      // Tính tổng giá trị giao dịch
      double totalTransactionValue = 0;
      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0).toDouble();
        final price = (data['price'] ?? 0).toDouble();
        totalTransactionValue += amount * price;
      }

      // Giao dịch hôm nay
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final todayTransactions = await _firestore
          .collection('transactions')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .get();

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'totalTransactions': totalTransactions,
        'totalTransactionValue': totalTransactionValue,
        'todayTransactions': todayTransactions.docs.length,
      };
    } catch (e) {
      print('Error getting admin stats: $e');
      return {};
    }
  }

  // Tạo admin đầu tiên (chỉ dùng một lần)
  Future<void> createFirstAdmin(String email) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userId = userQuery.docs.first.id;
        await updateUserRole(userId, 'admin');
        print('Admin role assigned to $email');
      } else {
        print('User with email $email not found');
      }
    } catch (e) {
      print('Error creating first admin: $e');
      rethrow;
    }
  }
}