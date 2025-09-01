// chat_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'base_admin_provider.dart';

class ChatProvider extends BaseAdminProvider {
  // Chat data
  List<Map<String, dynamic>> _chatConversations = [];
  
  // Chat statistics
  int _activeChats = 0;
  int _averageResponseTime = 5;
  double _chatGrowthPercentage = 0.0;
  String _chatTrend = 'up';

  // Getters
  List<Map<String, dynamic>> get chatConversations => _chatConversations;
  int get activeChats => _activeChats;
  int get averageResponseTime => _averageResponseTime;
  double get chatGrowthPercentage => _chatGrowthPercentage;
  String get chatTrend => _chatTrend;

  // LOAD CHAT DATA

  Future<void> loadChatConversations() async {
    if (isLoading) return;
    
    setLoading(true);
    try {
      final chatsSnapshot = await firestore
          .collection('chats')
          .orderBy('lastMessageTime', descending: true)
          .limit(50)
          .get();

      _chatConversations = chatsSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      updateLastUpdated();
      notifyListeners();
      
      DebugHelper.logInfo('Loaded ${_chatConversations.length} chat conversations from Firestore');
    } catch (e) {
      DebugHelper.logError('Error loading chat conversations: $e');
      setError('Failed to load chat conversations: $e');
    }
    setLoading(false);
  }

  Future<void> loadChatStats() async {
    try {
      final chatsSnapshot = await firestore
          .collection('chats')
          .where('isActive', isEqualTo: true)
          .get();
      _activeChats = chatsSnapshot.docs.length;

      // Calculate average response time (mock calculation)
      // In real implementation, you'd analyze actual message timestamps
      _averageResponseTime = 5 + Random().nextInt(10);

      // Calculate chat growth (simplified)
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentChatsSnapshot = await firestore
          .collection('chats')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .get();
      
      final weeklyChats = recentChatsSnapshot.docs.length;
      if (_activeChats > weeklyChats) {
        _chatGrowthPercentage = (weeklyChats / (_activeChats - weeklyChats)) * 100;
        _chatTrend = _chatGrowthPercentage > 0 ? 'up' : 'down';
      }

      notifyListeners();
    } catch (e) {
      DebugHelper.logError('Error loading chat stats: $e');
    }
  }

  // CHAT MANAGEMENT OPERATIONS

  Future<void> updateChatStatus(String chatId, bool isActive) async {
    try {
      await firestore.collection('chats').doc(chatId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final chatIndex = _chatConversations.indexWhere((chat) => chat['id'] == chatId);
      if (chatIndex != -1) {
        _chatConversations[chatIndex]['isActive'] = isActive;
        _chatConversations[chatIndex]['updatedAt'] = Timestamp.now();
        updateLastUpdated();
        notifyListeners();
      }

      // Log admin action
      await logAdminAction(
        isActive ? 'activate_chat' : 'deactivate_chat', 
        chatId, 
        isActive ? 'Chat activated' : 'Chat deactivated',
        targetType: 'chat'
      );
    } catch (e) {
      DebugHelper.logError('Error updating chat status: $e');
      setError('Failed to update chat status: $e');
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      // Delete all messages in the chat first
      final messagesSnapshot = await firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = firestore.batch();
      
      // Delete all messages
      for (final messageDoc in messagesSnapshot.docs) {
        batch.delete(messageDoc.reference);
      }
      
      // Delete the chat document
      batch.delete(firestore.collection('chats').doc(chatId));
      
      await batch.commit();
      
      // Remove from local data
      _chatConversations.removeWhere((chat) => chat['id'] == chatId);
      _activeChats = _chatConversations.where((chat) => chat['isActive'] == true).length;
      updateLastUpdated();
      notifyListeners();

      // Log admin action
      await logAdminAction('delete_chat', chatId, 'Chat and all messages deleted by admin', targetType: 'chat');
    } catch (e) {
      DebugHelper.logError('Error deleting chat: $e');
      setError('Failed to delete chat: $e');
    }
  }

  Future<void> muteChat(String chatId, bool isMuted, {DateTime? muteUntil}) async {
    try {
      Map<String, dynamic> updateData = {
        'isMuted': isMuted,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (isMuted && muteUntil != null) {
        updateData['muteUntil'] = Timestamp.fromDate(muteUntil);
      } else if (!isMuted) {
        updateData['muteUntil'] = null;
      }

      await firestore.collection('chats').doc(chatId).update(updateData);
      
      final chatIndex = _chatConversations.indexWhere((chat) => chat['id'] == chatId);
      if (chatIndex != -1) {
        _chatConversations[chatIndex]['isMuted'] = isMuted;
        _chatConversations[chatIndex]['updatedAt'] = Timestamp.now();
        if (muteUntil != null) {
          _chatConversations[chatIndex]['muteUntil'] = Timestamp.fromDate(muteUntil);
        }
        updateLastUpdated();
        notifyListeners();
      }

      // Log admin action
      await logAdminAction(
        isMuted ? 'mute_chat' : 'unmute_chat', 
        chatId, 
        isMuted ? 'Chat muted' : 'Chat unmuted',
        targetType: 'chat'
      );
    } catch (e) {
      DebugHelper.logError('Error updating chat mute status: $e');
      setError('Failed to update chat mute status: $e');
    }
  }

  Future<void> addChatNote(String chatId, String note) async {
    try {
      final chat = _chatConversations.firstWhere((c) => c['id'] == chatId);
      final currentNotes = List<Map<String, dynamic>>.from(chat['adminNotes'] ?? []);
      
      currentNotes.add({
        'note': note,
        'addedBy': 'admin', // Replace with actual admin ID
        'addedAt': Timestamp.now(),
      });

      await firestore.collection('chats').doc(chatId).update({
        'adminNotes': currentNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final chatIndex = _chatConversations.indexWhere((chat) => chat['id'] == chatId);
      if (chatIndex != -1) {
        _chatConversations[chatIndex]['adminNotes'] = currentNotes;
        _chatConversations[chatIndex]['updatedAt'] = Timestamp.now();
        updateLastUpdated();
        notifyListeners();
      }

      // Log admin action
      await logAdminAction('add_chat_note', chatId, 'Admin note added to chat', targetType: 'chat');
    } catch (e) {
      DebugHelper.logError('Error adding chat note: $e');
      setError('Failed to add chat note: $e');
      rethrow;
    }
  }

  // MESSAGE MANAGEMENT

  Future<List<Map<String, dynamic>>> getChatMessages(String chatId, {int limit = 50}) async {
    try {
      final messagesSnapshot = await firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return messagesSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      DebugHelper.logError('Error getting chat messages: $e');
      return [];
    }
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();

      // Log admin action
      await logAdminAction('delete_message', messageId, 'Message deleted by admin from chat: $chatId', targetType: 'message');
    } catch (e) {
      DebugHelper.logError('Error deleting message: $e');
      setError('Failed to delete message: $e');
    }
  }

  Future<void> flagMessage(String chatId, String messageId, String reason) async {
    try {
      await firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'isFlagged': true,
        'flagReason': reason,
        'flaggedBy': 'admin',
        'flaggedAt': FieldValue.serverTimestamp(),
      });

      // Log admin action
      await logAdminAction('flag_message', messageId, 'Message flagged by admin: $reason', targetType: 'message');
    } catch (e) {
      DebugHelper.logError('Error flagging message: $e');
      setError('Failed to flag message: $e');
    }
  }

  // BULK OPERATIONS

  Future<void> bulkUpdateChatStatus(List<String> chatIds, bool isActive) async {
    try {
      final batch = firestore.batch();
      
      for (final chatId in chatIds) {
        final chatRef = firestore.collection('chats').doc(chatId);
        batch.update(chatRef, {
          'isActive': isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      
      // Update local data
      for (final chatId in chatIds) {
        final chatIndex = _chatConversations.indexWhere((chat) => chat['id'] == chatId);
        if (chatIndex != -1) {
          _chatConversations[chatIndex]['isActive'] = isActive;
          _chatConversations[chatIndex]['updatedAt'] = Timestamp.now();
        }
      }
      
      updateLastUpdated();
      notifyListeners();
      
      // Log bulk action
      await logAdminAction(
        'bulk_update_chat_status',
        chatIds.join(','),
        'Bulk ${isActive ? 'activated' : 'deactivated'} ${chatIds.length} chats',
        targetType: 'chat'
      );
      
    } catch (e) {
      DebugHelper.logError('Error bulk updating chat status: $e');
      setError('Failed to bulk update chat status: $e');
      rethrow;
    }
  }

  Future<void> bulkDeleteChats(List<String> chatIds) async {
    try {
      final batch = firestore.batch();
      
      for (final chatId in chatIds) {
        // Get messages for each chat
        final messagesSnapshot = await firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .get();
        
        // Delete all messages
        for (final messageDoc in messagesSnapshot.docs) {
          batch.delete(messageDoc.reference);
        }
        
        // Delete the chat
        batch.delete(firestore.collection('chats').doc(chatId));
      }
      
      await batch.commit();
      
      // Remove from local data
      _chatConversations.removeWhere((chat) => chatIds.contains(chat['id']));
      _activeChats = _chatConversations.where((chat) => chat['isActive'] == true).length;
      updateLastUpdated();
      notifyListeners();
      
      // Log bulk action
      await logAdminAction(
        'bulk_delete_chats',
        chatIds.join(','),
        'Bulk deleted ${chatIds.length} chats and their messages',
        targetType: 'chat'
      );
      
    } catch (e) {
      DebugHelper.logError('Error bulk deleting chats: $e');
      setError('Failed to bulk delete chats: $e');
      rethrow;
    }
  }

  // SEARCH AND FILTER

  List<Map<String, dynamic>> searchChats(String query) {
    if (query.isEmpty) return _chatConversations;
    
    final lowercaseQuery = query.toLowerCase();
    return _chatConversations.where((chat) {
      final participants = List<String>.from(chat['participants'] ?? []);
      final lastMessage = (chat['lastMessage'] as String? ?? '').toLowerCase();
      final itemTitle = (chat['itemTitle'] as String? ?? '').toLowerCase();
      
      // Search in participants, last message, and item title
      return participants.any((p) => p.toLowerCase().contains(lowercaseQuery)) ||
             lastMessage.contains(lowercaseQuery) ||
             itemTitle.contains(lowercaseQuery);
    }).toList();
  }

  List<Map<String, dynamic>> filterChats({
    bool? isActive,
    bool? isMuted,
    String? itemId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _chatConversations.where((chat) {
      // Active filter
      if (isActive != null && chat['isActive'] != isActive) {
        return false;
      }
      
      // Muted filter
      if (isMuted != null && chat['isMuted'] != isMuted) {
        return false;
      }
      
      // Item filter
      if (itemId != null && chat['itemId'] != itemId) {
        return false;
      }
      
      // Date filters
      final createdAt = chat['createdAt'] as Timestamp?;
      if (createdAt != null) {
        final date = createdAt.toDate();
        if (startDate != null && date.isBefore(startDate)) return false;
        if (endDate != null && date.isAfter(endDate)) return false;
      }
      
      return true;
    }).toList();
  }

  // ANALYTICS

  List<Map<String, dynamic>> getActiveChats() {
    return _chatConversations.where((chat) => chat['isActive'] == true).toList();
  }

  List<Map<String, dynamic>> getMutedChats() {
    final now = Timestamp.now();
    return _chatConversations.where((chat) {
      final isMuted = chat['isMuted'] == true;
      final muteUntil = chat['muteUntil'] as Timestamp?;
      
      if (!isMuted) return false;
      if (muteUntil == null) return true;
      
      return muteUntil.compareTo(now) > 0; // Still muted
    }).toList();
  }

  List<Map<String, dynamic>> getRecentChats() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    return _chatConversations.where((chat) {
      final lastMessageTime = chat['lastMessageTime'] as Timestamp?;
      if (lastMessageTime == null) return false;
      
      return lastMessageTime.toDate().isAfter(yesterday);
    }).toList();
  }

  Map<String, int> getChatCountByDay() {
    final chatsByDay = <String, int>{};
    
    for (final chat in _chatConversations) {
      final createdAt = chat['createdAt'] as Timestamp?;
      if (createdAt != null) {
        final date = createdAt.toDate();
        final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        chatsByDay[dayKey] = (chatsByDay[dayKey] ?? 0) + 1;
      }
    }
    
    return chatsByDay;
  }

  Map<String, dynamic> getChatStatistics() {
    final totalChats = _chatConversations.length;
    final activeChats = getActiveChats().length;
    final mutedChats = getMutedChats().length;
    final recentChats = getRecentChats().length;

    // Calculate average messages per chat (would need actual implementation)
    final averageMessagesPerChat = 15.0; // Mock value

    return {
      'totalChats': totalChats,
      'activeChats': activeChats,
      'inactiveChats': totalChats - activeChats,
      'mutedChats': mutedChats,
      'recentChats': recentChats,
      'averageMessagesPerChat': averageMessagesPerChat,
      'averageResponseTime': _averageResponseTime,
      'chatGrowthPercentage': _chatGrowthPercentage,
      'chatTrend': _chatTrend,
    };
  }

  // EXPORT

  Future<String> exportChatsData({
    List<String>? chatIds,
    String format = 'csv',
  }) async {
    try {
      final chatsToExport = chatIds != null 
          ? _chatConversations.where((chat) => chatIds.contains(chat['id'])).toList()
          : _chatConversations;
      
      if (format == 'csv') {
        final csv = StringBuffer();
        
        // CSV Headers
        csv.writeln('ID,Participants,Item Title,Last Message,Status,Muted,Created At,Last Message Time');
        
        // CSV Data
        for (final chat in chatsToExport) {
          final participants = List<String>.from(chat['participants'] ?? []).join(';');
          
          csv.writeln([
            chat['id'],
            participants,
            chat['itemTitle'] ?? '',
            chat['lastMessage'] ?? '',
            chat['isActive'] == true ? 'Active' : 'Inactive',
            chat['isMuted'] == true ? 'Yes' : 'No',
            formatDate(chat['createdAt']),
            formatDate(chat['lastMessageTime']),
          ].map((e) => '"${e.toString().replaceAll('"', '""')}"').join(','));
        }
        
        return csv.toString();
      }
      
      return '';
      
    } catch (e) {
      DebugHelper.logError('Error exporting chats data: $e');
      rethrow;
    }
  }

  // UTILITY METHODS

  Map<String, dynamic>? getChatById(String chatId) {
    try {
      return _chatConversations.firstWhere(
        (chat) => chat['id'] == chatId,
        orElse: () => <String, dynamic>{},
      );
    } catch (e) {
      DebugHelper.logError('Error getting chat by ID: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getChatDetails(String chatId) async {
    try {
      final chatDoc = await firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        Map<String, dynamic> chatData = chatDoc.data()!;
        chatData['id'] = chatDoc.id;
        return chatData;
      }
      return null;
    } catch (e) {
      DebugHelper.logError('Error getting chat details: $e');
      return null;
    }
  }

  bool isChatMuted(Map<String, dynamic> chat) {
    final isMuted = chat['isMuted'] == true;
    if (!isMuted) return false;
    
    final muteUntil = chat['muteUntil'] as Timestamp?;
    if (muteUntil == null) return true;
    
    return muteUntil.toDate().isAfter(DateTime.now());
  }

  int getDaysSinceLastMessage(Map<String, dynamic> chat) {
    final lastMessageTime = chat['lastMessageTime'] as Timestamp?;
    if (lastMessageTime == null) return 0;
    
    return DateTime.now().difference(lastMessageTime.toDate()).inDays;
  }

  // DATA MANAGEMENT

  void clearAllChatData() {
    _chatConversations.clear();
    _activeChats = 0;
    _averageResponseTime = 5;
    _chatGrowthPercentage = 0.0;
    _chatTrend = 'up';
    notifyListeners();
  }

  // REFRESH DATA

  Future<void> refreshChats() async {
    await loadChatConversations();
    await loadChatStats();
  }
}