
// Keep existing SellerModel and UserFavoriteModel classes unchanged
import 'package:cloud_firestore/cloud_firestore.dart';

class SellerModel {
  final String id;
  final String name;
  final String type;
  final String email;
  final String phone;
  final String? profileImageUrl;
  final String? companyName;
  final String? address;
  final DateTime memberSince;
  final int totalAds;
  final int activeAds;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool isOnline;
  final DateTime? lastSeen;
  final List<String> verificationDocuments;

  SellerModel({
    required this.id,
    required this.name,
    required this.type,
    required this.email,
    required this.phone,
    this.profileImageUrl,
    this.companyName,
    this.address,
    required this.memberSince,
    this.totalAds = 0,
    this.activeAds = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.isOnline = false,
    this.lastSeen,
    this.verificationDocuments = const [],
  });

  factory SellerModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SellerModel(
      id: doc.id,
      name: data['companyName'] ?? data['name'] ?? 'Unknown',
      type: data['type'] ?? 'individual',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      profileImageUrl: data['profileImage'],
      companyName: data['companyName'],
      address: data['address'],
      memberSince: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalAds: data['totalAds'] ?? 0,
      activeAds: data['activeAds'] ?? 0,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      isOnline: data['isOnline'] ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      verificationDocuments: List<String>.from(data['verificationDocuments'] ?? []),
    );
  }

  String getDisplayName() {
    return companyName ?? name;
  }

  String getMemberSinceFormatted() {
    return '${memberSince.day}/${memberSince.month}/${memberSince.year}';
  }

  String getOnlineStatus() {
    if (isOnline) return 'Online now';
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
    return 'Last seen unknown';
  }
}

class UserFavoriteModel {
  final String id;
  final String userId;
  final String productId;
  final DateTime createdAt;

  UserFavoriteModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.createdAt,
  });

  factory UserFavoriteModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserFavoriteModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'productId': productId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}