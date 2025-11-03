import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/transaction.dart' as AppTransaction;
import 'auth_service.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

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

  // Xóa giao dịch
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