// models/chat_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantImages;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final String? productId;
  final String? productTitle;
  final String? productImage;
  final double? productPrice;
  final Map<String, int> unreadCount;
  final Map<String, bool> isTyping;
  final DateTime createdAt;
  final bool isActive;
  final String chatType; // 'buying', 'selling', 'general'

  ChatModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantImages,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    this.productId,
    this.productTitle,
    this.productImage,
    this.productPrice,
    required this.unreadCount,
    required this.isTyping,
    required this.createdAt,
    this.isActive = true,
    required this.chatType,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
      participantImages: Map<String, String>.from(data['participantImages'] ?? {}),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      productId: data['productId'],
      productTitle: data['productTitle'],
      productImage: data['productImage'],
      productPrice: data['productPrice']?.toDouble(),
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      isTyping: Map<String, bool>.from(data['isTyping'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      chatType: data['chatType'] ?? 'general',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'participantImages': participantImages,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageSenderId': lastMessageSenderId,
      'productId': productId,
      'productTitle': productTitle,
      'productImage': productImage,
      'productPrice': productPrice,
      'unreadCount': unreadCount,
      'isTyping': isTyping,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'chatType': chatType,
    };
  }

  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  String getOtherParticipantName(String currentUserId) {
    String otherId = getOtherParticipantId(currentUserId);
    return participantNames[otherId] ?? 'Unknown User';
  }

  String getOtherParticipantImage(String currentUserId) {
    String otherId = getOtherParticipantId(currentUserId);
    return participantImages[otherId] ?? '';
  }

  int getUnreadCount(String currentUserId) {
    return unreadCount[currentUserId] ?? 0;
  }

  bool isOtherUserTyping(String currentUserId) {
    String otherId = getOtherParticipantId(currentUserId);
    return isTyping[otherId] ?? false;
  }

  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(lastMessageTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${lastMessageTime.day}/${lastMessageTime.month}/${lastMessageTime.year}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String getFormattedPrice() {
    if (productPrice == null) return '';
    if (productPrice! >= 100000) {
      return 'RS ${(productPrice! / 100000).toStringAsFixed(1)}L';
    } else if (productPrice! >= 1000) {
      return 'RS ${(productPrice! / 1000).toStringAsFixed(0)}K';
    } else {
      return 'RS ${productPrice!.toStringAsFixed(0)}';
    }
  }
}

// models/message_model.dart
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String message;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final List<String>? imageUrls;
  final Map<String, dynamic>? metadata;
  final String? replyToMessageId;
  final MessageStatus status;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.imageUrls,
    this.metadata,
    this.replyToMessageId,
    this.status = MessageStatus.sent,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      message: data['message'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['type']}',
        orElse: () => MessageType.text,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      imageUrls: data['imageUrls'] != null ? List<String>.from(data['imageUrls']) : null,
      metadata: data['metadata'],
      replyToMessageId: data['replyToMessageId'],
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${data['status']}',
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'imageUrls': imageUrls,
      'metadata': metadata,
      'replyToMessageId': replyToMessageId,
      'status': status.toString().split('.').last,
    };
  }

  String getFormattedTime() {
    final now = DateTime.now();
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  bool isToday() {
    final now = DateTime.now();
    return timestamp.year == now.year &&
           timestamp.month == now.month &&
           timestamp.day == now.day;
  }
}

enum MessageType {
  text,
  image,
  file,
  location,
  product,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

// models/chat_participant_model.dart
class ChatParticipantModel {
  final String userId;
  final String name;
  final String? imageUrl;
  final String? phone;
  final String type; // 'individual' or 'company'
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isTyping;

  ChatParticipantModel({
    required this.userId,
    required this.name,
    this.imageUrl,
    this.phone,
    required this.type,
    this.isOnline = false,
    this.lastSeen,
    this.isTyping = false,
  });

  factory ChatParticipantModel.fromUserModel(Map<String, dynamic> userData) {
    return ChatParticipantModel(
      userId: userData['uid'] ?? '',
      name: userData['companyName'] ?? userData['name'] ?? 'Unknown User',
      imageUrl: userData['profileImage'],
      phone: userData['phone'],
      type: userData['type'] ?? 'individual',
      isOnline: userData['isOnline'] ?? false,
      lastSeen: (userData['lastSeen'] as Timestamp?)?.toDate(),
      isTyping: false,
    );
  }

  String getOnlineStatus() {
    if (isOnline) return 'Online';
    if (lastSeen != null) {
      final difference = DateTime.now().difference(lastSeen!);
      if (difference.inMinutes < 60) {
        return 'Active ${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return 'Active ${difference.inHours}h ago';
      } else {
        return 'Active ${difference.inDays}d ago';
      }
    }
    return 'Offline';
  }
}

// models/typing_indicator_model.dart
class TypingIndicatorModel {
  final String chatId;
  final String userId;
  final String userName;
  final DateTime timestamp;

  TypingIndicatorModel({
    required this.chatId,
    required this.userId,
    required this.userName,
    required this.timestamp,
  });

  factory TypingIndicatorModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TypingIndicatorModel(
      chatId: data['chatId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'userId': userId,
      'userName': userName,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  bool isRecent() {
    return DateTime.now().difference(timestamp).inSeconds < 5;
  }
}