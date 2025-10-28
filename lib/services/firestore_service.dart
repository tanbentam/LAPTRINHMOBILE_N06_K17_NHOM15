import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/transaction.dart' as model;
import '../models/deposit_transaction.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create user document with initial balance
  Future<void> createUserDocument(String uid, String email, {String? password}) async {
    try {
      final userDoc = _db.collection('users').doc(uid); // Sửa _firestore thành _db
      final now = DateTime.now();
      
      final userData = UserModel(
        uid: uid,
        email: email,
        password: password, // Lưu password vào UserModel
        createdAt: now,
        updatedAt: now,
      );

      await userDoc.set(userData.toMap()); // toMap() sẽ bao gồm password
      print('User document created successfully for $email with password field');
    } catch (e) {
      print('Error creating user document: $e');
      rethrow;
    }
  }

  // Update FCM Token
  Future<void> updateFCMToken(String uid, String fcmToken) async {
    try {
      await _db.collection('users').doc(uid).update({
        'fcmToken': fcmToken,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      print('✅ FCM Token updated for user: $uid');
    } catch (e) {
      print('❌ Error updating FCM token: $e');
      rethrow;
    }
  }

  // Get user FCM token
  Future<String?> getUserFCMToken(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['fcmToken'] as String?;
      }
      return null;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>); // Sửa fromJson thành fromMap
      }
      return null;
    } catch (e) {
      print('Get user data error: $e');
      return null;
    }
  }

  // Stream user data
  Stream<UserModel?> streamUserData(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>); // Sửa fromJson thành fromMap
      }
      return null;
    });
  }

  // Update user balance
  Future<void> updateBalance(String uid, double newBalance) async {
    try {
      await _db.collection('users').doc(uid).update({'balance': newBalance});
    } catch (e) {
      print('Update balance error: $e');
      rethrow;
    }
  }

  // Update holdings
  Future<void> updateHoldings(String uid, Map<String, double> holdings) async {
    try {
      await _db.collection('users').doc(uid).update({'holdings': holdings});
    } catch (e) {
      print('Update holdings error: $e');
      rethrow;
    }
  }

  // Update favorite coins
  Future<void> updateFavorites(String uid, List<String> favoriteCoins) async {
    try {
      await _db.collection('users').doc(uid).update({
        'favoriteCoins': favoriteCoins,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Update favorites error: $e');
      rethrow;
    }
  }

  // Buy coin
  Future<void> buyCoin({
    required String uid,
    required String coinId,
    required String coinSymbol,
    required double amount,
    required double price,
    double? stopLoss,
    double? takeProfit,
  }) async {
    try {
      final userDoc = _db.collection('users').doc(uid);
      final userData = await getUserData(uid);
      
      if (userData == null) throw Exception('User not found');
      
      final total = amount * price;
      
      if (userData.balance < total) {
        throw Exception('Insufficient balance');
      }

      // Update balance and holdings
      final newBalance = userData.balance - total;
      final newHoldings = Map<String, double>.from(userData.holdings);
      newHoldings[coinId] = (newHoldings[coinId] ?? 0) + amount;

      await userDoc.update({
        'balance': newBalance,
        'holdings': newHoldings,
      });

      // Create transaction record
      await _createTransaction(
        userId: uid,
        coinId: coinId,
        coinSymbol: coinSymbol,
        type: 'buy',
        amount: amount,
        price: price,
        total: total,
        stopLoss: stopLoss,
        takeProfit: takeProfit,
      );

      // 🔔 Gửi thông báo giao dịch thành công
      print('📱 Sending trade notification for BUY $coinSymbol');
    } catch (e) {
      print('Buy coin error: $e');
      rethrow;
    }
  }

  // Sell coin
  Future<void> sellCoin({
    required String uid,
    required String coinId,
    required String coinSymbol,
    required double amount,
    required double price,
  }) async {
    try {
      final userDoc = _db.collection('users').doc(uid);
      final userData = await getUserData(uid);
      
      if (userData == null) throw Exception('User not found');
      
      final currentHolding = userData.holdings[coinId] ?? 0;
      
      if (currentHolding < amount) {
        throw Exception('Insufficient coins');
      }

      // Update balance and holdings
      final total = amount * price;
      final newBalance = userData.balance + total;
      final newHoldings = Map<String, double>.from(userData.holdings);
      newHoldings[coinId] = currentHolding - amount;
      
      if (newHoldings[coinId]! <= 0) {
        newHoldings.remove(coinId);
      }

      await userDoc.update({
        'balance': newBalance,
        'holdings': newHoldings,
      });

      // Create transaction record
      await _createTransaction(
        userId: uid,
        coinId: coinId,
        coinSymbol: coinSymbol,
        type: 'sell',
        amount: amount,
        price: price,
        total: total,
      );

      // 🔔 Gửi thông báo giao dịch thành công
      print('📱 Sending trade notification for SELL $coinSymbol');
    } catch (e) {
      print('Sell coin error: $e');
      rethrow;
    }
  }

  // Create transaction
  Future<void> _createTransaction({
    required String userId,
    required String coinId,
    required String coinSymbol,
    required String type,
    required double amount,
    required double price,
    required double total,
    double? stopLoss,
    double? takeProfit,
  }) async {
    try {
      final transactionDoc = _db.collection('transactions').doc();
      final transaction = model.Transaction(
        id: transactionDoc.id,
        userId: userId,
        coinId: coinId,
        coinSymbol: coinSymbol,
        type: type,
        amount: amount,
        price: price,
        total: total,
        timestamp: DateTime.now(),
        stopLoss: stopLoss,
        takeProfit: takeProfit,
        autoSellEnabled: stopLoss != null || takeProfit != null,
      );
      await transactionDoc.set(transaction.toJson());
    } catch (e) {
      print('Create transaction error: $e');
      rethrow;
    }
  }

  // Get user transactions
  Stream<List<model.Transaction>> getUserTransactions(String uid) {
    return _db
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => model.Transaction.fromJson(doc.data()))
          .toList();
    });
  }

  // Deposit money - Save to separate collection
  Future<void> depositMoney({
    required String uid,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      final userDoc = _db.collection('users').doc(uid);
      final userData = await getUserData(uid);
      
      if (userData == null) throw Exception('User not found');

      // Update balance
      final newBalance = userData.balance + amount;
      await userDoc.update({'balance': newBalance});

      // Create deposit transaction record in separate collection
      final depositDoc = _db.collection('deposit_transactions').doc();
      final deposit = DepositTransaction(
        id: depositDoc.id,
        userId: uid,
        type: 'deposit',
        amount: amount,
        timestamp: DateTime.now(),
        paymentMethod: paymentMethod,
        status: 'completed',
        notes: 'Deposit via $paymentMethod',
      );
      
      await depositDoc.set(deposit.toJson());

      print('✅ Deposit completed: \$${amount} USD via $paymentMethod');
    } catch (e) {
      print('❌ Deposit error: $e');
      rethrow;
    }
  }

  // Withdraw money - Save to separate collection
  Future<void> withdrawMoney({
    required String uid,
    required double amount,
    required String paymentMethod,
    String? accountNumber,
    String? accountName,
  }) async {
    try {
      final userDoc = _db.collection('users').doc(uid);
      final userData = await getUserData(uid);
      
      if (userData == null) throw Exception('User not found');
      
      if (userData.balance < amount) {
        throw Exception('Insufficient balance');
      }

      // Update balance
      final newBalance = userData.balance - amount;
      await userDoc.update({'balance': newBalance});

      // Create withdraw transaction record in separate collection
      final withdrawDoc = _db.collection('deposit_transactions').doc();
      
      final notes = accountNumber != null && accountName != null
          ? 'Withdraw via $paymentMethod to $accountName ($accountNumber)'
          : 'Withdraw via $paymentMethod';
      
      final withdraw = DepositTransaction(
        id: withdrawDoc.id,
        userId: uid,
        type: 'withdraw',
        amount: amount,
        timestamp: DateTime.now(),
        paymentMethod: paymentMethod,
        status: 'pending', // Withdraw starts as pending
        notes: notes,
      );
      
      await withdrawDoc.set(withdraw.toJson());

      print('✅ Withdraw requested: \$${amount} USD via $paymentMethod');
    } catch (e) {
      print('❌ Withdraw error: $e');
      rethrow;
    }
  }

  // Get user deposit/withdraw transactions
  Stream<List<DepositTransaction>> getUserDepositTransactions(String uid) {
    return _db
        .collection('deposit_transactions')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DepositTransaction.fromJson(doc.data()))
          .toList();
    });
  }
}