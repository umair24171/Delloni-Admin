// user_provider.dart
import 'package:delloniweb/model/seller_model.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'base_admin_provider.dart';

class UserProvider extends BaseAdminProvider {
  // User data
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _recentUsers = [];
  
  // User statistics
  int _totalUsers = 0;
  int _todayNewUsers = 0;
  int _newUsersThisWeek = 0;
  double _userGrowthPercentage = 0.0;
  String _userTrend = 'up';

  // Getters
  List<Map<String, dynamic>> get allUsers => _allUsers;
  List<Map<String, dynamic>> get recentUsers => _recentUsers;
  int get totalUsers => _totalUsers;
  int get todayNewUsers => _todayNewUsers;
  int get newUsersThisWeek => _newUsersThisWeek;
  double get userGrowthPercentage => _userGrowthPercentage;
  String get userTrend => _userTrend;

  User? get currentUser => FirebaseAuth.instance.currentUser;
  SellerModel? currentSeller;

  // LOAD USER DATA

  Future<void> loadAllUsers() async {
    if (isLoading) return;
    
    setLoading(true);
    try {
      final usersSnapshot = await firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      _allUsers = usersSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      _totalUsers = _allUsers.length;
      updateLastUpdated();
      notifyListeners();
    } catch (e) {
      DebugHelper.logError('Error loading users: $e');
      setError('Failed to load users: $e');
    }
    setLoading(false);
  }

  Future<void> loadCurrentUser() async {
    if (currentUser == null) return;
    final userDoc = await firestore.collection('users').doc(currentUser!.uid).get();
    currentSeller = SellerModel.fromFirestore(userDoc);
    notifyListeners();
  }

  Future<void> loadUserStats() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = now.subtract(const Duration(days: 7));
      final monthStart = DateTime(now.year, now.month - 1, now.day);

      // Get all users
      final usersSnapshot = await firestore.collection('users').get();
      _totalUsers = usersSnapshot.docs.length;

      // Calculate today's new users
      final todayUsersQuery = await firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .get();
      _todayNewUsers = todayUsersQuery.docs.length;

      // Calculate weekly new users
      final weeklyUsersQuery = await firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .get();
      _newUsersThisWeek = weeklyUsersQuery.docs.length;

      // Calculate monthly growth
      final monthlyUsersQuery = await firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .get();
      final monthlyNewUsers = monthlyUsersQuery.docs.length;

      // Calculate growth percentage
      final previousMonthUsers = _totalUsers - monthlyNewUsers;
      if (previousMonthUsers > 0) {
        _userGrowthPercentage = (monthlyNewUsers / previousMonthUsers) * 100;
        _userTrend = _userGrowthPercentage > 0 ? 'up' : 'down';
      }

      // Get recent users
      final recentUsersSnapshot = await firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      _recentUsers = recentUsersSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      notifyListeners();
    } catch (e) {
      DebugHelper.logError('Error loading user stats: $e');
    }
  }

  // USER MANAGEMENT OPERATIONS

  Future<void> verifyUserEmail(String userId) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'isEmailVerified': true,
        'emailVerifiedAt': FieldValue.serverTimestamp(),
        'emailVerifiedBy': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update local data
      final userIndex = _allUsers.indexWhere((user) => user['id'] == userId);
      if (userIndex != -1) {
        _allUsers[userIndex]['isEmailVerified'] = true;
        _allUsers[userIndex]['emailVerifiedAt'] = Timestamp.now();
        _allUsers[userIndex]['emailVerifiedBy'] = 'admin';
        updateLastUpdated();
        notifyListeners();
      }
      
      // Log admin action
      await logAdminAction('verify_email', userId, 'Email verified by admin', targetType: 'user');
      
    } catch (e) {
      DebugHelper.logError('Error verifying user email: $e');
      setError('Failed to verify email: $e');
      rethrow;
    }
  }

  Future<void> verifyUserPhone(String userId) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'isPhoneVerified': true,
        'phoneVerifiedAt': FieldValue.serverTimestamp(),
        'phoneVerifiedBy': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update local data
      final userIndex = _allUsers.indexWhere((user) => user['id'] == userId);
      if (userIndex != -1) {
        _allUsers[userIndex]['isPhoneVerified'] = true;
        _allUsers[userIndex]['phoneVerifiedAt'] = Timestamp.now();
        _allUsers[userIndex]['phoneVerifiedBy'] = 'admin';
        updateLastUpdated();
        notifyListeners();
      }
      
      // Log admin action
      await logAdminAction('verify_phone', userId, 'Phone verified by admin', targetType: 'user');
      
    } catch (e) {
      DebugHelper.logError('Error verifying user phone: $e');
      setError('Failed to verify phone: $e');
      rethrow;
    }
  }

  Future<void> resetUserPassword(String userId) async {
    try {
      // Get user email first
      final userDoc = await firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final userEmail = userData['email'] as String?;
      
      if (userEmail == null || userEmail.isEmpty) {
        throw Exception('User email not found');
      }
      
      // Send password reset email using Firebase Auth
      await FirebaseAuth.instance.sendPasswordResetEmail(email: userEmail);
      
      // Update user document to track password reset
      await firestore.collection('users').doc(userId).update({
        'passwordResetSentAt': FieldValue.serverTimestamp(),
        'passwordResetBy': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update local data
      final userIndex = _allUsers.indexWhere((user) => user['id'] == userId);
      if (userIndex != -1) {
        _allUsers[userIndex]['passwordResetSentAt'] = Timestamp.now();
        _allUsers[userIndex]['passwordResetBy'] = 'admin';
        updateLastUpdated();
        notifyListeners();
      }
      
      // Log admin action
      await logAdminAction('reset_password', userId, 'Password reset email sent by admin', targetType: 'user');
      
    } catch (e) {
      DebugHelper.logError('Error resetting user password: $e');
      setError('Failed to reset password: $e');
      rethrow;
    }
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final userIndex = _allUsers.indexWhere((user) => user['id'] == userId);
      if (userIndex != -1) {
        _allUsers[userIndex]['isActive'] = isActive;
        _allUsers[userIndex]['statusUpdatedAt'] = Timestamp.now();
        _allUsers[userIndex]['statusUpdatedBy'] = 'admin';
        updateLastUpdated();
        notifyListeners();
      }
      
      // Log admin action
      await logAdminAction(
        isActive ? 'activate_user' : 'block_user', 
        userId, 
        isActive ? 'User activated by admin' : 'User blocked by admin',
        targetType: 'user'
      );
      
    } catch (e) {
      DebugHelper.logError('Error updating user status: $e');
      setError('Failed to update user status: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Get user data first for logging
      final userDoc = await firestore.collection('users').doc(userId).get();
      final userData = userDoc.exists ? userDoc.data() as Map<String, dynamic> : {};
      
      // Delete user's products first
      final userProductsQuery = await firestore
          .collection('items')
          .where('sellerId', isEqualTo: userId)
          .get();
      
      final batch = firestore.batch();
      
      // Delete all user's products
      for (final doc in userProductsQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete user's chats
      final userChatsQuery = await firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();
      
      for (final doc in userChatsQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete user's location data
      final locationRef = firestore
          .collection('users')
          .doc(userId)
          .collection('location')
          .doc('current');
      
      batch.delete(locationRef);
      
      // Delete user document
      batch.delete(firestore.collection('users').doc(userId));
      
      // Commit all deletions
      await batch.commit();
      
      // Remove from local data
      _allUsers.removeWhere((user) => user['id'] == userId);
      _totalUsers = _allUsers.length;
      updateLastUpdated();
      notifyListeners();
      
      // Log admin action
      await logAdminAction('delete_user', userId, 'User and all associated data deleted by admin', targetType: 'user');
      
    } catch (e) {
      DebugHelper.logError('Error deleting user: $e');
      setError('Failed to delete user: $e');
      rethrow;
    }
  }

  Future<void> sendNotificationToUser(String userId, String title, String message) async {
    try {
      await firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': 'admin_message',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'sentBy': 'admin',
      });
      
      // Log admin action
      await logAdminAction('send_notification', userId, 'Notification sent: $title', targetType: 'user');
      
    } catch (e) {
      DebugHelper.logError('Error sending notification: $e');
      setError('Failed to send notification: $e');
      rethrow;
    }
  }

  // BULK OPERATIONS

  Future<void> bulkUpdateUserStatus(List<String> userIds, bool isActive) async {
    try {
      final batch = firestore.batch();
      
      for (final userId in userIds) {
        final userRef = firestore.collection('users').doc(userId);
        batch.update(userRef, {
          'isActive': isActive,
          'statusUpdatedAt': FieldValue.serverTimestamp(),
          'statusUpdatedBy': 'admin',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      
      // Update local data
      for (final userId in userIds) {
        final userIndex = _allUsers.indexWhere((user) => user['id'] == userId);
        if (userIndex != -1) {
          _allUsers[userIndex]['isActive'] = isActive;
          _allUsers[userIndex]['statusUpdatedAt'] = Timestamp.now();
          _allUsers[userIndex]['statusUpdatedBy'] = 'admin';
        }
      }
      
      updateLastUpdated();
      notifyListeners();
      
      // Log bulk action
      await logAdminAction(
        'bulk_update_status',
        userIds.join(','),
        'Bulk ${isActive ? 'activated' : 'blocked'} ${userIds.length} users',
        targetType: 'user'
      );
      
    } catch (e) {
      DebugHelper.logError('Error bulk updating user status: $e');
      setError('Failed to bulk update user status: $e');
      rethrow;
    }
  }

  // UTILITY METHODS

  Future<int> getUserProductsCount(String userId) async {
    try {
      final snapshot = await firestore
          .collection('items')
          .where('sellerId', isEqualTo: userId)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      DebugHelper.logError('Error getting user products count: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getUserRecentActivity(String userId) async {
    try {
      final activities = <Map<String, dynamic>>[];
      
      // Get recent products
      final recentProducts = await firestore
          .collection('items')
          .where('sellerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      for (final doc in recentProducts.docs) {
        final data = doc.data();
        activities.add({
          'type': 'product_created',
          'title': 'Created product: ${data['itemTitle']}',
          'timestamp': data['createdAt'],
          'data': data,
        });
      }
      
      // Get recent chats
      final recentChats = await firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .limit(5)
          .get();
      
      for (final doc in recentChats.docs) {
        final data = doc.data();
        activities.add({
          'type': 'chat_activity',
          'title': 'Chat activity',
          'timestamp': data['lastMessageTime'],
          'data': data,
        });
      }
      
      // Sort by timestamp
      activities.sort((a, b) {
        final timestampA = a['timestamp'] as Timestamp?;
        final timestampB = b['timestamp'] as Timestamp?;
        
        if (timestampA == null) return 1;
        if (timestampB == null) return -1;
        
        return timestampB.compareTo(timestampA);
      });
      
      return activities.take(10).toList();
      
    } catch (e) {
      DebugHelper.logError('Error getting user recent activity: $e');
      return [];
    }
  }

  // EXPORT AND REPORTING

  Future<String> exportUsersData({
    List<String>? userIds,
    String format = 'csv',
  }) async {
    try {
      final usersToExport = userIds != null 
          ? _allUsers.where((user) => userIds.contains(user['id'])).toList()
          : _allUsers;
      
      if (format == 'csv') {
        final csv = StringBuffer();
        
        // CSV Headers
        csv.writeln('ID,Type,Name/Company,Email,Phone,Status,Email Verified,Phone Verified,Language,Created At');
        
        // CSV Data
        for (final user in usersToExport) {
          final name = user['type'] == 'company' 
              ? (user['companyName'] ?? '')
              : (user['name'] ?? '');
          
          csv.writeln([
            user['id'],
            user['type'],
            name,
            user['email'] ?? '',
            user['phone'] ?? '',
            user['isActive'] == true ? 'Active' : 'Blocked',
            user['isEmailVerified'] == true ? 'Yes' : 'No',
            user['isPhoneVerified'] == true ? 'Yes' : 'No',
            user['language'] ?? 'English',
            formatDate(user['createdAt']),
          ].map((e) => '"${e.toString().replaceAll('"', '""')}"').join(','));
        }
        
        return csv.toString();
      }
      
      return '';
      
    } catch (e) {
      DebugHelper.logError('Error exporting users data: $e');
      rethrow;
    }
  }

  // SEARCH AND FILTER

  List<Map<String, dynamic>> searchUsers(String query) {
    if (query.isEmpty) return _allUsers;
    
    final lowercaseQuery = query.toLowerCase();
    return _allUsers.where((user) {
      final email = (user['email'] as String? ?? '').toLowerCase();
      final companyName = (user['companyName'] as String? ?? '').toLowerCase();
      final phone = (user['phone'] as String? ?? '').toLowerCase();
      
      return email.contains(lowercaseQuery) ||
             companyName.contains(lowercaseQuery) ||
             phone.contains(lowercaseQuery);
    }).toList();
  }

  List<Map<String, dynamic>> filterUsers({
    String? type,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _allUsers.where((user) {
      // Type filter
      if (type != null && user['type'] != type) {
        return false;
      }
      
      // Active filter
      if (isActive != null && user['isActive'] != isActive) {
        return false;
      }
      
      // Date filters
      final createdAt = user['createdAt'] as Timestamp?;
      if (createdAt != null) {
        final date = createdAt.toDate();
        if (startDate != null && date.isBefore(startDate)) return false;
        if (endDate != null && date.isAfter(endDate)) return false;
      }
      
      return true;
    }).toList();
  }

  // STATISTICS

  Map<String, dynamic> getUserStatistics() {
    final individualUsers = _allUsers.where((user) => user['type'] == 'individual').length;
    final companyUsers = _allUsers.where((user) => user['type'] == 'company').length;
    final activeUsers = _allUsers.where((user) => user['isActive'] == true).length;

    return {
      'totalUsers': _totalUsers,
      'individualUsers': individualUsers,
      'companyUsers': companyUsers,
      'activeUsers': activeUsers,
      'inactiveUsers': _totalUsers - activeUsers,
      'companyPercentage': _totalUsers > 0 ? (companyUsers / _totalUsers) * 100 : 0,
    };
  }

  // DATA MANAGEMENT

  void clearAllUserData() {
    _allUsers.clear();
    _recentUsers.clear();
    _totalUsers = 0;
    _todayNewUsers = 0;
    _newUsersThisWeek = 0;
    _userGrowthPercentage = 0.0;
    _userTrend = 'up';
    notifyListeners();
  }
}