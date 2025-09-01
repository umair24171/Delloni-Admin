import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class NotificationsProvider with ChangeNotifier {


  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State variables
  bool _isLoading = true;
  String? _error;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  
  // Streams
  StreamSubscription? _notificationsSubscription;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  List<NotificationModel> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();

  NotificationsProvider() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('Admin not authenticated');
      return;
    }

    try {
      _setLoading(true);
      _setupNotificationsListener(currentUser.uid);
    } catch (e) {
      _setError('Failed to initialize notifications: $e');
      log('NotificationsProvider initialization error: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  // Setup real-time notifications listener
  void _setupNotificationsListener(String adminId) {
    _notificationsSubscription = _firestore
        .collection('admin_notifications')
        .where('recipientId', isEqualTo: adminId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      try {
        _notifications = snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList();

        _calculateUnreadCount();
        _setLoading(false);
        log('Admin notifications loaded: ${_notifications.length}');
      } catch (e) {
        log('Error processing notification snapshots: $e');
      }
    }, onError: (e) {
      _setError('Error loading notifications: $e');
      log('Notifications stream error: $e');
    });

    // Also listen to chat messages for real-time notifications
    _setupChatNotificationsListener(adminId);
  }

  // Listen to chat messages and create notifications
  void _setupChatNotificationsListener(String adminId) {
    _firestore
        .collection('chats')
        .where('participants', arrayContains: adminId)
        .snapshots()
        .listen((chatSnapshot) {
      for (var chatDoc in chatSnapshot.docs) {
        final chatData = chatDoc.data() as Map<String, dynamic>;
        final chatId = chatDoc.id;
        
        // Listen to messages in this chat
        _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .snapshots()
            .listen((messageSnapshot) {
          if (messageSnapshot.docs.isNotEmpty) {
            final latestMessage = messageSnapshot.docs.first;
            final messageData = latestMessage.data();
            
            // Check if message is from another user (not admin)
            if (messageData['senderId'] != adminId) {
              _createChatNotification(chatData, messageData, chatId);
            }
          }
        });
      }
    });
  }

  // Create notification for new chat message
  Future<void> _createChatNotification(
    Map<String, dynamic> chatData,
    Map<String, dynamic> messageData,
    String chatId,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final senderId = messageData['senderId'] as String;
      final senderName = messageData['senderName'] as String? ?? 'Unknown User';
      final messageText = messageData['message'] as String? ?? '';
      final messageType = messageData['type'] as String? ?? 'text';
      final timestamp = messageData['timestamp'] as Timestamp?;

      // Check if notification already exists for this message
      final existingNotification = await _firestore
          .collection('admin_notifications')
          .where('recipientId', isEqualTo: currentUser.uid)
          .where('data.messageId', isEqualTo: messageData['id'])
          .limit(1)
          .get();

      if (existingNotification.docs.isNotEmpty) return;

      String notificationTitle = 'New Message';
      String notificationBody = _getMessagePreview(messageText, messageType);
      
      if (chatData['productTitle'] != null) {
        notificationTitle = 'Message about ${chatData['productTitle']}';
      }

      // Create notification document
      await _firestore.collection('admin_notifications').add({
        'recipientId': currentUser.uid,
        'type': 'chat_message',
        'title': notificationTitle,
        'body': '$senderName: $notificationBody',
        'isRead': false,
        'createdAt': timestamp ?? FieldValue.serverTimestamp(),
        'data': {
          'chatId': chatId,
          'senderId': senderId,
          'senderName': senderName,
          'messageId': messageData['id'],
          'messageType': messageType,
          'productTitle': chatData['productTitle'],
          'productId': chatData['productId'],
        },
        'priority': 'normal',
        'category': 'chat',
      });

      log('Chat notification created for message from $senderName');
    } catch (e) {
      log('Error creating chat notification: $e');
    }
  }

  // Get message preview for notification
  String _getMessagePreview(String message, String messageType) {
    switch (messageType) {
      case 'image':
        return '📸 Photo';
      case 'location':
        return '📍 Location';
      case 'file':
        return '📎 File';
      default:
        if (message.length > 50) {
          return '${message.substring(0, 50)}...';
        }
        return message;
    }
  }

  // Calculate unread count
  void _calculateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('admin_notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _calculateUnreadCount();
      }
    } catch (e) {
      log('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final batch = _firestore.batch();
      
      final unreadNotifications = await _firestore
          .collection('admin_notifications')
          .where('recipientId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      // Update local state
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
      _calculateUnreadCount();
    } catch (e) {
      log('Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('admin_notifications')
          .doc(notificationId)
          .delete();

      // Update local state
      _notifications.removeWhere((n) => n.id == notificationId);
      _calculateUnreadCount();
    } catch (e) {
      log('Error deleting notification: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final batch = _firestore.batch();
      
      final allNotifications = await _firestore
          .collection('admin_notifications')
          .where('recipientId', isEqualTo: currentUser.uid)
          .get();

      for (var doc in allNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Update local state
      _notifications.clear();
      _calculateUnreadCount();
    } catch (e) {
      log('Error clearing all notifications: $e');
    }
  }

  // Refresh notifications
  Future<void> refreshNotifications() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _setupNotificationsListener(currentUser.uid);
    }
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }
}



// Notification Model
class NotificationModel {
  final String id;
  final String recipientId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> data;
  final String priority;
  final String category;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.data,
    required this.priority,
    required this.category,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      recipientId: data['recipientId'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      priority: data['priority'] ?? 'normal',
      category: data['category'] ?? 'general',
    );
  }

  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? type,
    String? title,
    String? body,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
    String? priority,
    String? category,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
      priority: priority ?? this.priority,
      category: category ?? this.category,
    );
  }

  // Get notification icon based on type
  IconData get icon {
    switch (type) {
      case 'chat_message':
        return Icons.chat_bubble_outline;
      case 'user_registered':
        return Icons.person_add_outlined;
      case 'product_created':
        return Icons.inventory_2_outlined;
      case 'support_request':
        return Icons.support_agent_outlined;
      case 'system':
        return Icons.settings_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  // Get notification color based on priority
  Color get priorityColor {
    switch (priority) {
      case 'high':
        return const Color(0xFFF44336); // ArabicTheme.error
      case 'medium':
        return const Color(0xFFFF9800); // ArabicTheme.warning
      case 'low':
        return const Color(0xFF2196F3); // ArabicTheme.info
      default:
        return const Color(0xFF52B788); // ArabicTheme.accentGreen
    }
  }

  // Format time ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}