import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/notification_item.dart';
import '../services/auth_service.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  String _selectedFilter = 'all';
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.currentUserId;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Thông báo'),
          backgroundColor: Colors.black,
        ),
        body: const Center(child: Text('Vui lòng đăng nhập')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Trung tâm thông báo'),
        backgroundColor: Colors.black,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Tất cả')),
              const PopupMenuItem(value: 'trade', child: Text('Giao dịch')),
              const PopupMenuItem(value: 'price_alert', child: Text('Cảnh báo giá')),
              const PopupMenuItem(value: 'volatility', child: Text('Biến động')),
              const PopupMenuItem(value: 'news', child: Text('Tin tức')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Đánh dấu tất cả đã đọc',
            onPressed: () => _markAllAsRead(userId),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Xóa tất cả',
            onPressed: () => _confirmDeleteAll(userId),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getNotificationsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có thông báo nào',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs
              .map((doc) => NotificationItem.fromMap({
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  }))
              .toList();

          final unreadCount = notifications.where((n) => !n.isRead).length;

          return Column(
            children: [
              if (unreadCount > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue[50],
                  child: Text(
                    '📬 Bạn có $unreadCount thông báo chưa đọc',
                    style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationItem(notification, userId);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getNotificationsStream(String userId) {
    Query query = _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true);

    if (_selectedFilter != 'all') {
      query = query.where('type', isEqualTo: _selectedFilter);
    }

    return query.snapshots();
  }

  Widget _buildNotificationItem(NotificationItem notification, String userId) {
    final icon = _getNotificationIcon(notification.type);
    final color = _getNotificationColor(notification.type);
    final timeAgo = _getTimeAgo(notification.timestamp);

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteNotification(userId, notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa thông báo')),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
              fontSize: 15,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.body,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                timeAgo,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          trailing: !notification.isRead
              ? Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () => _markAsRead(userId, notification.id),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'trade':
        return Icons.swap_horiz;
      case 'price_alert':
        return Icons.notifications_active;
      case 'volatility':
        return Icons.trending_up;
      case 'news':
        return Icons.article;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'trade':
        return Colors.green;
      case 'price_alert':
        return Colors.orange;
      case 'volatility':
        return Colors.red;
      case 'news':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
  }

  Future<void> _markAsRead(String userId, String notificationId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> _markAllAsRead(String userId) async {
    final batch = _db.batch();
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đánh dấu tất cả đã đọc')),
      );
    }
  }

  Future<void> _deleteNotification(String userId, String notificationId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  Future<void> _confirmDeleteAll(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả thông báo?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa tất cả thông báo')),
        );
      }
    }
  }
}
