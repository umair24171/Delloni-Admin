import 'dart:async';
import 'dart:developer';
import 'dart:html' as html;
import 'package:delloniweb/model/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminIndividualChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // State variables
  bool _isLoading = true;
  String? _error;
  ChatModel? _chat;
  List<MessageModel> _messages = [];
  ChatParticipantModel? _otherParticipant;
  bool _isTyping = false;
  bool _otherUserTyping = false;
  
  // Streams
  StreamSubscription? _chatSubscription;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _typingSubscription;
  Timer? _typingTimer;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  ChatModel? get chat => _chat;
  List<MessageModel> get messages => _messages;
  ChatParticipantModel? get otherParticipant => _otherParticipant;
  bool get isTyping => _isTyping;
  bool get otherUserTyping => _otherUserTyping;

  // Initialize individual chat
  Future<void> initializeChat(String chatId) async {
    try {
      _setLoading(true);
      _setError(null);
      
      _setupChatListener(chatId);
      _setupMessagesListener(chatId);
      await _markChatAsRead(chatId);
      
    } catch (e) {
      _setError('Failed to initialize chat: $e');
      log('AdminIndividualChatProvider initialization error: $e');
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

  // Setup chat info listener
  void _setupChatListener(String chatId) {
    _chatSubscription = _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists) {
        _chat = ChatModel.fromFirestore(snapshot);
        await _loadOtherParticipant();
        _setupTypingListener(chatId);
        _setLoading(false);
      }
    }, onError: (e) {
      _setError('Error loading chat: $e');
      log('Chat stream error: $e');
    });
  }

  // Setup messages listener
  void _setupMessagesListener(String chatId) {
    _messagesSubscription = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _messages = snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
      notifyListeners();
    }, onError: (e) => log('Messages stream error: $e'));
  }

  // Setup typing listener
  void _setupTypingListener(String chatId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _typingSubscription = _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final isTyping = data['isTyping'] as Map<String, dynamic>?;
        
        if (isTyping != null) {
          final otherUserId = _chat?.getOtherParticipantId(currentUser.uid);
          if (otherUserId != null) {
            _otherUserTyping = isTyping[otherUserId] ?? false;
            notifyListeners();
          }
        }
      }
    });
  }

  // Load other participant info
  Future<void> _loadOtherParticipant() async {
    if (_chat == null) return;
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final otherUserId = _chat!.getOtherParticipantId(currentUser.uid);
      final userDoc = await _firestore.collection('users').doc(otherUserId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _otherParticipant = ChatParticipantModel(
          uid: otherUserId,
          name: userData['companyName'] ?? userData['name'] ?? 'Unknown User',
          email: userData['email'] ?? '',
          profileImage: userData['profileImage'],
          isOnline: false, // You can implement online status
        );
        notifyListeners();
      }
    } catch (e) {
      log('Error loading other participant: $e');
    }
  }

  // Send text message
  Future<void> sendMessage(String messageText) async {
    if (_chat == null || messageText.trim().isEmpty) return;
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final messageId = _firestore.collection('chats').doc(_chat!.id).collection('messages').doc().id;
      
      // Create message
      final message = MessageModel(
        id: messageId,
        chatId: _chat!.id,
        senderId: currentUser.uid,
        senderName: 'Admin',
        message: messageText.trim(),
        type: MessageType.text,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
      );

      // Add message to Firestore
      await _firestore
          .collection('chats')
          .doc(_chat!.id)
          .collection('messages')
          .doc(messageId)
          .set(message.toJson());

      // Update chat last message
      final otherUserId = _chat!.getOtherParticipantId(currentUser.uid);
      await _firestore.collection('chats').doc(_chat!.id).update({
        'lastMessage': messageText.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser.uid,
        'unreadCount.$otherUserId': FieldValue.increment(1),
      });

      // Stop typing
      _stopTyping();

    } catch (e) {
      _setError('Failed to send message: $e');
      log('Error sending message: $e');
    }
  }

  // Send image message (for web)
  Future<void> sendImageMessage(html.File imageFile) async {
    if (_chat == null) return;
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Upload image to Firebase Storage
      final imageUrl = await _uploadImageWeb(imageFile);
      if (imageUrl == null) return;

      final messageId = _firestore.collection('chats').doc(_chat!.id).collection('messages').doc().id;
      
      // Create image message
      final message = MessageModel(
        id: messageId,
        chatId: _chat!.id,
        senderId: currentUser.uid,
        senderName: 'Admin',
        message: 'Image',
        type: MessageType.image,
        timestamp: DateTime.now(),
        imageUrls: [imageUrl],
        status: MessageStatus.sending,
      );

      // Add message to Firestore
      await _firestore
          .collection('chats')
          .doc(_chat!.id)
          .collection('messages')
          .doc(messageId)
          .set(message.toJson());

      // Update chat last message
      final otherUserId = _chat!.getOtherParticipantId(currentUser.uid);
      await _firestore.collection('chats').doc(_chat!.id).update({
        'lastMessage': 'Photo',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser.uid,
        'unreadCount.$otherUserId': FieldValue.increment(1),
      });

    } catch (e) {
      _setError('Failed to send image: $e');
      log('Error sending image: $e');
    }
  }

  // Send location message
  Future<void> sendLocationMessage(double latitude, double longitude, String address) async {
    if (_chat == null) return;
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final messageId = _firestore.collection('chats').doc(_chat!.id).collection('messages').doc().id;
      
      // Create location message
      final message = MessageModel(
        id: messageId,
        chatId: _chat!.id,
        senderId: currentUser.uid,
        senderName: 'Admin',
        message: address,
        type: MessageType.location,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
      );

      // Add message to Firestore
      await _firestore
          .collection('chats')
          .doc(_chat!.id)
          .collection('messages')
          .doc(messageId)
          .set(message.toJson());

      // Update chat last message
      final otherUserId = _chat!.getOtherParticipantId(currentUser.uid);
      await _firestore.collection('chats').doc(_chat!.id).update({
        'lastMessage': '📍 Location',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser.uid,
        'unreadCount.$otherUserId': FieldValue.increment(1),
      });

    } catch (e) {
      _setError('Failed to send location: $e');
      log('Error sending location: $e');
    }
  }

  // Upload image for web
  Future<String?> _uploadImageWeb(html.File imageFile) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final Reference ref = _storage.ref().child('admin_chat_images/$fileName');
      
      // Create upload task for web
      final uploadTask = ref.putBlob(imageFile);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      log('Error uploading image: $e');
      return null;
    }
  }

  // Start typing indicator
  void startTyping() {
    if (_chat == null) return;
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    if (!_isTyping) {
      _isTyping = true;
      
      // Update typing status in Firestore
      _firestore.collection('chats').doc(_chat!.id).update({
        'isTyping.${currentUser.uid}': true,
      });
    }

    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _stopTyping();
    });
  }

  // Stop typing indicator
  void _stopTyping() {
    if (_chat == null) return;
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    if (_isTyping) {
      _isTyping = false;
      
      // Update typing status in Firestore
      _firestore.collection('chats').doc(_chat!.id).update({
        'isTyping.${currentUser.uid}': false,
      });
      
      notifyListeners();
    }
    
    _typingTimer?.cancel();
  }

  // Mark chat as read
  Future<void> _markChatAsRead(String chatId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.${currentUser.uid}': 0,
      });
    } catch (e) {
      log('Error marking chat as read: $e');
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    if (_chat == null) return;

    try {
      await _firestore
          .collection('chats')
          .doc(_chat!.id)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      log('Error deleting message: $e');
    }
  }

  // Delete chat
  Future<void> deleteChat(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isActive': false,
      });
      log('Chat deleted: $chatId');
    } catch (e) {
      log('Error deleting chat: $e');
    }
  }

  // Archive chat
  Future<void> archiveChat(String chatId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('chats').doc(chatId).update({
        'archivedBy.${currentUser.uid}': true,
      });
      log('Chat archived: $chatId');
    } catch (e) {
      log('Error archiving chat: $e');
    }
  }

  // Send quick reply
  Future<void> sendQuickReply(String replyText) async {
    await sendMessage(replyText);
  }

  // Send predefined admin responses
  Future<void> sendPredefinedResponse(String responseType) async {
    String message = '';
    
    switch (responseType) {
      case 'welcome':
        message = 'Hello! Welcome to our platform. How can I assist you today?';
        break;
      case 'support':
        message = 'I\'m here to help you with any questions or issues. Please describe your concern.';
        break;
      case 'thank_you':
        message = 'Thank you for contacting us. Is there anything else I can help you with?';
        break;
      case 'resolved':
        message = 'I\'m glad we could resolve your issue. Feel free to reach out if you need further assistance.';
        break;
      default:
        message = 'Thank you for your message.';
    }
    
    await sendMessage(message);
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    
    // Update presence when leaving chat
    if (_chat != null) {
      _updateUserPresence(_chat!.id, isActive: false);
    }
    
    super.dispose();
  }

  // Update user presence when entering/leaving chat
  Future<void> _updateUserPresence(String chatId, {bool isActive = true}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('presence')
          .doc('status')
          .set({
        'lastSeen': FieldValue.serverTimestamp(),
        'currentChat': isActive ? chatId : null,
        'isOnline': isActive,
        'lastActivity': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      log('Admin presence updated for chat: $chatId, active: $isActive');
    } catch (e) {
      log('Error updating admin presence: $e');
    }
  }
}

// Additional model for chat participant
class ChatParticipantModel {
  final String uid;
  final String name;
  final String email;
  final String? profileImage;
  final bool isOnline;

  ChatParticipantModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profileImage,
    required this.isOnline,
  });

  factory ChatParticipantModel.fromUserModel(Map<String, dynamic> userData) {
    return ChatParticipantModel(
      uid: userData['uid'] ?? '',
      name: userData['companyName'] ?? userData['name'] ?? 'Unknown User',
      email: userData['email'] ?? '',
      profileImage: userData['profileImage'],
      isOnline: false, // You can implement real-time online status
    );
  }
}