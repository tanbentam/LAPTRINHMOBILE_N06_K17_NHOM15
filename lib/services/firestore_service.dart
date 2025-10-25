import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/transaction.dart' as model;

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

  // Buy coin
  Future<void> buyCoin({
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
      );
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
}