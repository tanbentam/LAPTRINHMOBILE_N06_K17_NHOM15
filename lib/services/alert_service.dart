import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/price_alert.dart';

class AlertService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create price alert
  Future<void> createPriceAlert({
    required String userId,
    required String coinId,
    required String coinSymbol,
    required double targetPrice,
    required bool isAbove,
  }) async {
    try {
      final alertDoc = _db.collection('price_alerts').doc();
      final alert = PriceAlert(
        id: alertDoc.id,
        userId: userId,
        coinId: coinId,
        coinSymbol: coinSymbol,
        targetPrice: targetPrice,
        isAbove: isAbove,
        createdAt: DateTime.now(),
      );
      
      await alertDoc.set(alert.toMap());
      print('✅ Price alert created for $coinSymbol at \$${targetPrice.toStringAsFixed(2)}');
    } catch (e) {
      print('❌ Error creating price alert: $e');
      rethrow;
    }
  }

  // Get user's active alerts
  Stream<List<PriceAlert>> getUserAlerts(String userId) {
    return _db
        .collection('price_alerts')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PriceAlert.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get alerts for a specific coin
  Stream<List<PriceAlert>> getCoinAlerts(String userId, String coinId) {
    return _db
        .collection('price_alerts')
        .where('userId', isEqualTo: userId)
        .where('coinId', isEqualTo: coinId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PriceAlert.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Trigger alert (mark as triggered)
  Future<void> triggerAlert(String alertId) async {
    try {
      await _db.collection('price_alerts').doc(alertId).update({
        'isActive': false,
        'triggeredAt': Timestamp.fromDate(DateTime.now()),
      });
      print('✅ Alert $alertId triggered');
    } catch (e) {
      print('❌ Error triggering alert: $e');
      rethrow;
    }
  }

  // Delete alert
  Future<void> deleteAlert(String alertId) async {
    try {
      await _db.collection('price_alerts').doc(alertId).delete();
      print('✅ Alert deleted');
    } catch (e) {
      print('❌ Error deleting alert: $e');
      rethrow;
    }
  }

  // Check if price alerts should be triggered
  Future<List<PriceAlert>> checkAlerts(String userId, Map<String, double> currentPrices) async {
    try {
      final snapshot = await _db
          .collection('price_alerts')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      final triggeredAlerts = <PriceAlert>[];

      for (var doc in snapshot.docs) {
        final alert = PriceAlert.fromMap(doc.data(), doc.id);
        final currentPrice = currentPrices[alert.coinId];

        if (currentPrice != null) {
          final shouldTrigger = alert.isAbove
              ? currentPrice >= alert.targetPrice
              : currentPrice <= alert.targetPrice;

          if (shouldTrigger) {
            triggeredAlerts.add(alert);
            await triggerAlert(alert.id);
          }
        }
      }

      return triggeredAlerts;
    } catch (e) {
      print('❌ Error checking alerts: $e');
      return [];
    }
  }
}
